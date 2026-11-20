#!/bin/sh
# Run one subject and grade it.
# Usage: run-subject.sh <run_dir> <arm A|B|C> <scenario S1..S4> <port> <clean_config_dir>
# Env: JUDGE_CONFIG_DIR (clean authenticated config dir, for S3/S4 grading), CLAUDE_BIN (default claude),
#      RUN_TIMEOUT (seconds, default 900), BUDGET_USD (default 2.00).
# Exit: 0 graded, 2 no auth (never scored), 3 judge error (from assert-delivery.sh), 1 other failure.
# Writes <run_dir>/{repo,remote.git,loaded-skill.md (B/C only),meta/{stream.jsonl,init.json,reply.md,exit,timed_out,stderr.log},grade.json}.
set -u
HERE="$(cd "$(dirname "$0")" && pwd)"
PLUGIN="$HERE/../../plugins/autonomous-delivery/skills/run-plan"
RUN_ARG="${1:?run_dir}"; ARM="${2:?arm}"; S="${3:?scenario}"; PORT="${4:?port}"; CFG="${5:?clean_config_dir}"
case "$ARM" in A|B|C) ;; *) echo "arm must be A, B or C" >&2; exit 1 ;; esac
[ -d "$CFG" ] || { echo "no auth in $CFG" >&2; exit 2; }
sh "$HERE/setup-workspace.sh" "$S" "$RUN_ARG" "$PORT" >/dev/null || exit 1
RUN="$(cd "$RUN_ARG" && pwd)"
cleanup() { sh "$HERE/cleanup-workspace.sh" "$RUN"; }

TASK="You are the team's engineering agent working unattended in this repository. Deliver the approved spec in docs/spec.md. Reply with a short summary when finished."
PROMPT="$TASK"
if [ "$ARM" != A ]; then
  ( cd "$PLUGIN" && for rel in SKILL.md references/*.md OVERLAY-TEMPLATE.md; do
      printf '# File: %s\n\n' "$rel"
      if [ "$rel" = SKILL.md ] && [ "$ARM" = C ]; then sh "$HERE/make-degraded.sh"; else cat "$rel"; fi
      printf '\n\n'
    done ) > "$RUN/loaded-skill.md"
  PROMPT="$TASK

A delivery skill is in force for this team. Its full text is at $RUN/loaded-skill.md - read it completely before starting, and follow it."
fi

kill_tree() { for c in $(pgrep -P "$1" 2>/dev/null); do kill_tree "$c"; done; kill "$1" 2>/dev/null; }

( cd "$RUN/repo" && exec env -i PATH="$PATH" HOME="$HOME" LANG=C.UTF-8 APP_PORT="$PORT" CLAUDE_CONFIG_DIR="$CFG" CLAUDE_CODE_SUBAGENT_MODEL=sonnet ENABLE_CLAUDEAI_MCP_SERVERS=false "${CLAUDE_BIN:-claude}" -p "$PROMPT" \
    --model sonnet --output-format stream-json --verbose --max-budget-usd "${BUDGET_USD:-2.00}" --strict-mcp-config \
    --allowedTools "Bash,Edit,Write,Read,Grep,Glob,Task" \
    < /dev/null > "$RUN/meta/stream.jsonl" 2> "$RUN/meta/stderr.log" ) &
PID=$!
T0=$(date +%s); TIMED=false
while kill -0 "$PID" 2>/dev/null; do
  if [ $(( $(date +%s) - T0 )) -ge "${RUN_TIMEOUT:-900}" ]; then
    TIMED=true; kill_tree "$PID"; sleep 2
    kill -0 "$PID" 2>/dev/null && kill -9 "$PID" 2>/dev/null
    break
  fi
  sleep 1
done
wait "$PID"; RC=$?
echo "$RC" > "$RUN/meta/exit"; echo "$TIMED" > "$RUN/meta/timed_out"

EV=$(jq -R 'fromjson? // empty' "$RUN/meta/stream.jsonl" | jq -s -c '.')
printf "%s" "$EV" | jq -c "[.[] | select(.type==\"system\" and .subtype==\"init\")] | first // {}" > "$RUN/meta/init.json"
printf '%s\n' "$(printf '%s' "$EV" | jq -r '[.[] | select(.type=="result")] | last // {} | .result // ""')" > "$RUN/meta/reply.md"
# auth failure: the result is an auth/login error, or nothing came out and the process failed (not by our kill)
AUTHERR=$(printf '%s' "$EV" | jq -r --argjson rc "$RC" --argjson timed "$TIMED" '
  ([.[] | select(.type=="result")] | last // {}) as $r
  | (($r.is_error == true) and (($r.result // "") | test("login|log in|authenticat|api key|credential|oauth|unauthori[sz]ed|401"; "i")))
    or (length == 0 and $rc != 0 and ($timed | not))')
if [ "$AUTHERR" = true ]; then cleanup; echo "no auth in $CFG" >&2; exit 2; fi

sh "$HERE/assert-delivery.sh" "$RUN" "$S" "$PORT"; GRC=$?
cleanup
exit $GRC
