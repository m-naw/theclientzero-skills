#!/usr/bin/env bash
# log-skill-call.sh — PreToolUse hook for Skill tool invocations.
# Appends one JSON line per Skill tool invocation to .claude/skill-invocations.jsonl.
# Contract: never block the tool call. Exit 0 unconditionally.

set -u
trap 'exit 0' EXIT

MAX_BYTES=4096
TRUNCATE_STRING_TO=200

command -v jq >/dev/null 2>&1 || exit 0
[[ -n "${CLAUDE_PROJECT_DIR:-}" ]] || exit 0

LOG_DIR="$CLAUDE_PROJECT_DIR/.claude"
LOG_FILE="$LOG_DIR/skill-invocations.jsonl"
mkdir -p "$LOG_DIR" 2>/dev/null || exit 0

INPUT="$(cat)" || exit 0
[[ -n "$INPUT" ]] || exit 0

TS="$(date -u +%Y-%m-%dT%H:%M:%SZ)"

build_record() {
  # $1 = truncate flag: "" or "true"
  # Truncation walks only top-level entries of tool_input; nested structures
  # are left untouched. See plan §Task 5 scope note for rationale.
  local truncate_flag="$1"
  printf '%s' "$INPUT" | jq -c \
    --arg ts "$TS" \
    --argjson trunc_to "$TRUNCATE_STRING_TO" \
    --arg truncate "$truncate_flag" '
    def shorten_top_strings:
      if type == "object" then
        with_entries(
          if (.value | type) == "string" and (.value | length) > $trunc_to
          then .value |= .[0:$trunc_to]
          else .
          end
        )
      else . end;
    {
      ts: $ts,
      session_id,
      cwd,
      tool_name,
      tool_input: (if $truncate == "true" then (.tool_input | shorten_top_strings) else .tool_input end),
      tool_use_id,
      transcript_path,
    }
    + (if .agent_id then {agent_id} else {} end)
    + (if .agent_type then {agent_type} else {} end)
    + (if $truncate == "true" then {_truncated: true} else {} end)
  ' 2>/dev/null
}

record_bytes() {
  # Byte count (not character count) of $1, for accurate UTF-8 size checking.
  printf '%s' "$1" | wc -c
}

RECORD="$(build_record "")" || exit 0
[[ -n "$RECORD" ]] || exit 0

if (( $(record_bytes "$RECORD") > MAX_BYTES )); then
  RECORD="$(build_record true)" || exit 0
  [[ -n "$RECORD" ]] || exit 0
  # Defense in depth: jq length/slice work in codepoints, wc -c works in
  # bytes. For multibyte UTF-8 input the truncated record could still
  # exceed MAX_BYTES. If so, drop silently rather than write a record
  # that violates the size contract.
  (( $(record_bytes "$RECORD") <= MAX_BYTES )) || exit 0
fi

printf '%s\n' "$RECORD" >> "$LOG_FILE" 2>/dev/null || true
