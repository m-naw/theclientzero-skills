#!/usr/bin/env bash
# One reviewer dispatch for the PSG eval. Headless claude -p, clean config.
# Usage:
#   run-reviewer.sh single <run_dir> <model sonnet|opus> <applied_dir> <diff_file> <cfg>   # arms A/A2
#   run-reviewer.sh principle <run_dir> <principle> <applied_dir> <diff_file> <cfg>       # arms B/C (sonnet)
set -euo pipefail
MODE="${1:?mode}"; RUN_DIR_ARG="${2:?run_dir}"; ARG3="${3:?}"; APPLIED="$(cd "${4:?applied}" && pwd)"; DIFF="$(cd "$(dirname "${5:?diff}")" && pwd)/$(basename "$5")"; CFG="${6:?cfg}"
mkdir -p "$RUN_DIR_ARG/meta"; RUN_DIR="$(cd "$RUN_DIR_ARG" && pwd)"

principle_brief() {
  case "$1" in
    srp) echo "Single Responsibility — classes/functions doing more than one thing" ;;
    ocp) echo "Open/Closed — type-switching that should be polymorphism or a type-checked extension point" ;;
    lsp) echo "Liskov Substitution — subtypes violating the parent's documented contract" ;;
    yagni) echo "YAGNI — code paths, classes, or config with no current consumer" ;;
    typing) echo "Typing — untyped public surfaces, any leaks, missing parameter/return types" ;;
    verification) echo "Verification — run the project's verify script (bash verify.sh in the checkout) and gate on it passing; report the exact failing output if red" ;;
    standards) echo "Project standards — read README conventions and check the change against every declared convention" ;;
    isp) echo "Interface Segregation — interfaces forcing consumers to depend on methods they do not use" ;;
    dip) echo "Dependency Inversion — high-level modules constructing/depending on concrete low-level classes" ;;
    anti-patterns) echo "Named anti-patterns — god class (>500 LOC or >15 public methods), primitive obsession (>=3 raw primitives in domain logic where a named type fits), feature envy, anemic domain, shotgun surgery" ;;
    *) echo "unknown"; return 1 ;;
  esac
}

if [ "$MODE" = single ]; then
  MODEL="$ARG3"; OUT="$RUN_DIR/findings.md"
  PROMPT="You are reviewing a pull request before merge, working unattended.

Post-change checkout (read-only): $APPLIED
The change under review (unified diff, base -> head): $DIFF

Review the change for code-quality principles: SOLID, YAGNI, typing, build/test verification (the project verifies with \`bash verify.sh\`), and the project's declared standards (README).

Write every finding to $OUT, one per line:
FILE:LINE — PRINCIPLE — concrete failure scenario

Reply DONE when finished. You are running unattended — do not ask questions."
else
  P="$ARG3"; MODEL=sonnet; OUT="$RUN_DIR/$P.md"
  BRIEF="$(principle_brief "$P")"
  PROMPT="You are the \`$P\` reviewer in a pre-merge principles gate, working unattended.

Scope: the change in $DIFF (unified diff, base -> head) plus its immediate dependencies in the read-only checkout at $APPLIED.

Check ONLY this principle: $BRIEF. Do not report findings outside this principle.

Binding contract — emit AT MOST 3 findings total, each in exactly one of these shapes:
VIOLATION: <file>:<line> — <concrete failure scenario reproducible from current code> — <named rule>
CONCERN: <file>:<line> — <code smell without a concrete reproducible failure>

Write your findings (or 'NO FINDINGS') to $OUT.
Reply DONE when finished. You are running unattended — do not ask questions."
fi

set +e
( cd "$RUN_DIR" && printf '%s' "$PROMPT" | CLAUDE_CONFIG_DIR="$CFG" "${CLAUDE_BIN:-claude}" -p \
    --model "$MODEL" \
    --allowedTools "Bash,Read,Grep,Glob,Write" \
    > "$RUN_DIR/meta/reviewer-$(basename "$OUT" .md)-reply.md" 2>> "$RUN_DIR/meta/stderr.log" )
echo $? >> "$RUN_DIR/meta/exit-codes"
exit 0
