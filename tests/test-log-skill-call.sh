#!/usr/bin/env bash
# Test driver for plugins/skill-observability/hooks/log-skill-call.sh. Plain bash, no framework.
set -u

HOOK="$(cd "$(dirname "$0")/.." && pwd)/plugins/skill-observability/hooks/log-skill-call.sh"
FIXTURES="$(cd "$(dirname "$0")" && pwd)/fixtures"
FAILED=0

fail() { echo "FAIL: $1" >&2; FAILED=$((FAILED + 1)); }
pass() { echo "PASS: $1"; }

run_hook() {
  local fixture="$1"
  local proj="${2:-$(mktemp -d)}"
  CLAUDE_PROJECT_DIR="$proj" bash "$HOOK" < "$FIXTURES/$fixture" >/dev/null
  printf '%s' "$proj"
}

test_happy_path() {
  local name="happy_path: writes one valid JSONL record for a normal Skill call"
  local proj
  proj="$(run_hook skill-call-normal.json)"
  local log="$proj/.claude/skill-invocations.jsonl"
  [[ -f "$log" ]] || { fail "$name (log not created)"; return; }
  [[ "$(wc -l < "$log")" -eq 1 ]] || { fail "$name (expected 1 line, got $(wc -l < "$log"))"; return; }
  jq -e '
    .ts and (.ts | test("^[0-9]{4}-[0-9]{2}-[0-9]{2}T[0-9]{2}:[0-9]{2}:[0-9]{2}Z$"))
    and .session_id == "sess-abc"
    and .cwd == "/home/user/project"
    and .tool_name == "Skill"
    and (.tool_input | type == "object")
    and .tool_use_id == "toolu_001"
    and .transcript_path == "/tmp/transcript.jsonl"
  ' "$log" >/dev/null || { fail "$name (record schema mismatch: $(cat "$log"))"; return; }
  pass "$name"
}

test_unset_project_dir() {
  local name="unset_project_dir: silent exit 0, no file written anywhere"
  local cwd
  cwd="$(mktemp -d)"
  (
    cd "$cwd"
    unset CLAUDE_PROJECT_DIR
    bash "$HOOK" < "$FIXTURES/skill-call-normal.json"
    echo "exit=$?"
  ) > "$cwd/out.txt" 2>&1
  grep -q '^exit=0$' "$cwd/out.txt" || { fail "$name (non-zero exit: $(cat "$cwd/out.txt"))"; return; }
  [[ ! -e "$cwd/.claude/skill-invocations.jsonl" ]] || { fail "$name (wrote to \$PWD/.claude)"; return; }
  pass "$name"
}

test_truncation() {
  local name="truncation: oversized record is truncated and marked"
  local proj
  proj="$(run_hook skill-call-oversized.json)"
  local log="$proj/.claude/skill-invocations.jsonl"
  [[ -f "$log" ]] || { fail "$name (log not created)"; return; }
  local line bytes
  line="$(tail -n 1 "$log")"
  bytes=$(printf '%s' "$line" | wc -c)
  [[ "$bytes" -le 4096 ]] || { fail "$name (line is $bytes bytes, expected <= 4096)"; return; }
  jq -e '._truncated == true' <<< "$line" >/dev/null || { fail "$name (missing _truncated marker)"; return; }
  jq -e '.tool_input | type == "object"' <<< "$line" >/dev/null || { fail "$name (tool_input shape lost)"; return; }
  jq -e '.tool_input | to_entries | map(select(.value | type == "string")) | all(.value | length <= 200)' <<< "$line" >/dev/null || { fail "$name (some top-level tool_input string exceeds 200 chars after truncation)"; return; }
  pass "$name"
}

test_agent_fields_present() {
  local name="agent_fields_present: subagent stdin produces agent_id/agent_type in record"
  local proj
  proj="$(run_hook skill-call-with-agent.json)"
  local log="$proj/.claude/skill-invocations.jsonl"
  jq -e '.agent_id == "agent-xyz" and .agent_type == "general-purpose"' "$log" >/dev/null \
    || { fail "$name (missing or wrong agent fields: $(cat "$log"))"; return; }
  pass "$name"
}

test_agent_fields_absent() {
  local name="agent_fields_absent: parent-session stdin produces no agent_id/agent_type"
  local proj
  proj="$(run_hook skill-call-normal.json)"
  local log="$proj/.claude/skill-invocations.jsonl"
  jq -e 'has("agent_id") or has("agent_type")' "$log" >/dev/null \
    && { fail "$name (agent fields present when stdin had none: $(cat "$log"))"; return; }
  pass "$name"
}

test_concurrent_appends() {
  local name="concurrent_appends: 10 parallel invocations produce 10 valid JSONL lines"
  local proj
  proj="$(mktemp -d)"
  local pids=()
  local i p
  for i in $(seq 1 10); do
    CLAUDE_PROJECT_DIR="$proj" bash "$HOOK" < "$FIXTURES/skill-call-normal.json" >/dev/null &
    pids+=($!)
  done
  for p in "${pids[@]}"; do wait "$p"; done
  local log="$proj/.claude/skill-invocations.jsonl"
  local count
  count="$(wc -l < "$log")"
  [[ "$count" -eq 10 ]] || { fail "$name (expected 10 lines, got $count)"; return; }
  while IFS= read -r line; do
    jq -e . <<< "$line" >/dev/null || { fail "$name (invalid JSON line: $line)"; return; }
  done < "$log"
  pass "$name"
}

test_happy_path
test_unset_project_dir
test_truncation
test_agent_fields_present
test_agent_fields_absent
test_concurrent_appends

exit "$FAILED"
