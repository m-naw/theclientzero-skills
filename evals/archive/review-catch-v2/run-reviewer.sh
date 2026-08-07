#!/usr/bin/env bash
# One reviewer dispatch. Usage: run-reviewer.sh <run_dir> <arm R|L|NT> <applied_dir> <adr_file> <cfg>
set -euo pipefail
RUN_DIR_ARG="${1:?run_dir}"; ARM="${2:?arm}"; APPLIED="$(cd "${3:?applied}" && pwd)"; ADR="$(cd "$(dirname "${4:?adr}")" && pwd)/$(basename "$4")"; CFG="${5:?cfg}"
mkdir -p "$RUN_DIR_ARG/meta"; RUN_DIR="$(cd "$RUN_DIR_ARG" && pwd)"

COMMON="Document under review (an inventory audit awaiting sign-off): $ADR
Project checkout (read-only): $APPLIED

Write your review to $RUN_DIR/review.md as: verdict LAND or RETURN on the first line, then one line per finding (claim number — what is wrong — evidence).
Reply DONE when finished. You are working unattended — do not ask questions."

case "$ARM" in
  R) PROMPT="You are an independent reviewer for a decision about to be recorded. You have no prior involvement with this document. Verify its cited proofs against the checkout before your verdict — a claim is only sound if its evidence holds.

$COMMON" ;;
  L) PROMPT="Read the decision document below and give your review verdict with any concerns.

$COMMON" ;;
  NT) PROMPT="Read the document below and give your review verdict with any concerns.

Document under review (an inventory audit awaiting sign-off): the full text follows.
$(cat "$ADR")

Reply with: verdict LAND or RETURN on the first line, then one line per finding (claim number — what is wrong). You are working unattended — do not ask questions." ;;
  *) echo "unknown arm" >&2; exit 1 ;;
esac

set +e
if [ "$ARM" = NT ]; then
  # No tools: cannot open files or count; must review from prose. Reply IS the review.
  ( printf '%s' "$PROMPT" | CLAUDE_CONFIG_DIR="$CFG" "${CLAUDE_BIN:-claude}" -p \
      --model sonnet --disallowedTools "Bash,Read,Grep,Glob,Write,Edit,Task,WebFetch,WebSearch" \
      > "$RUN_DIR/meta/reply.md" 2> "$RUN_DIR/meta/stderr.log" )
  cp "$RUN_DIR/meta/reply.md" "$RUN_DIR/review.md"
else
  ( cd "$RUN_DIR" && printf '%s' "$PROMPT" | CLAUDE_CONFIG_DIR="$CFG" "${CLAUDE_BIN:-claude}" -p \
      --model sonnet --allowedTools "Bash,Read,Grep,Glob,Write" \
      > "$RUN_DIR/meta/reply.md" 2> "$RUN_DIR/meta/stderr.log" )
fi
echo $? > "$RUN_DIR/meta/exit"
exit 0
