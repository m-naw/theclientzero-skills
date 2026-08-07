#!/usr/bin/env bash
# Dispatch one vacuum-fill subject: headless `claude -p`, clean CLAUDE_CONFIG_DIR.
# Usage: run-subject.sh <run_dir> <arm A|B|C> <scenario> <fixture_dir> <clean_config_dir>
# Subject investigates the read-only fixture and writes <run_dir>/decision.md.
set -euo pipefail
HERE="$(cd "$(dirname "$0")" && pwd)"
RUN_DIR_ARG="${1:?run_dir}"; ARM="${2:?arm}"; SCENARIO="${3:?scenario}"; FIX="$(cd "${4:?fixture}" && pwd)"; CFG="${5:?config}"
mkdir -p "$RUN_DIR_ARG/meta"
RUN_DIR="$(cd "$RUN_DIR_ARG" && pwd)"

ARM_BLOCK=""
if [ "$ARM" != "A" ]; then
  ARM_BLOCK="A decision-protocol skill is in force for all recorded decisions on this team.
Its full text is at $RUN_DIR/loaded-skill.md — read it completely before starting, and follow it.
"
fi

PROMPT="You are the platform team's engineering agent, preparing a recorded decision document. You are working unattended.

Repository (read-only) at: $FIX
Write the decision document to: $RUN_DIR/decision.md

$ARM_BLOCK
TASK:
$(cat "$HERE/scenarios/$SCENARIO.md")

When done, reply DONE plus a one-line summary. You are running unattended — if something cannot be resolved from available sources, record that explicitly in the document rather than waiting for an answer."

set +e
( cd "$RUN_DIR" && printf '%s' "$PROMPT" | CLAUDE_CONFIG_DIR="$CFG" "${CLAUDE_BIN:-claude}" -p \
    --model sonnet \
    --allowedTools "Bash,Edit,Write,Read,Grep,Glob" \
    > "$RUN_DIR/meta/subject-reply.md" 2> "$RUN_DIR/meta/subject-stderr.log" )
echo $? > "$RUN_DIR/meta/subject-exit"
exit 0
