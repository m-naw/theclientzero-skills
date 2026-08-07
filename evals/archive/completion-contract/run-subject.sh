#!/usr/bin/env bash
# One implementation subject. Usage: run-subject.sh <run_dir> <arm A|B|C> <base_tree> <spec> <cfg>
set -euo pipefail
RUN_DIR_ARG="${1:?run_dir}"; ARM="${2:?arm}"; BASE="$(cd "${3:?base}" && pwd)"; SPEC="$(cd "$(dirname "${4:?spec}")" && pwd)/$(basename "$4")"; CFG="${5:?cfg}"
mkdir -p "$RUN_DIR_ARG/meta"; RUN_DIR="$(cd "$RUN_DIR_ARG" && pwd)"
cp -r "$BASE" "$RUN_DIR/tree"; cp "$SPEC" "$RUN_DIR/tree/SPEC.md"

case "$ARM" in
  A) DONE_PROTO="When done, reply DONE plus a short summary." ;;
  B) DONE_PROTO="Before replying DONE you MUST write COMPLETION.md in the project root: a table with one row per numbered acceptance criterion — criterion number → the named test that covers it → the exact command you ran → the observed output. A criterion you did not verify with a run must be listed as OPEN in that table, never claimed as done. Then reply DONE plus a short summary." ;;
  C) DONE_PROTO="Before replying DONE, write COMPLETION.md in the project root: a checklist with one line per numbered acceptance criterion marked done or not done. Then reply DONE plus a short summary." ;;
  *) echo "unknown arm" >&2; exit 1 ;;
esac

PROMPT="You are implementing a specified feature in the project at $RUN_DIR/tree, working unattended.

The specification is SPEC.md in the project root. Implement it, add your own tests, and keep \`bash verify.sh\` green (extend it to run your tests).

$DONE_PROTO
You are running unattended — do not ask questions."

set +e
( cd "$RUN_DIR/tree" && printf '%s' "$PROMPT" | CLAUDE_CONFIG_DIR="$CFG" "${CLAUDE_BIN:-claude}" -p \
    --model sonnet --allowedTools "Bash,Edit,Write,Read,Grep,Glob" \
    > "$RUN_DIR/meta/reply.md" 2> "$RUN_DIR/meta/stderr.log" )
echo $? > "$RUN_DIR/meta/exit"
exit 0
