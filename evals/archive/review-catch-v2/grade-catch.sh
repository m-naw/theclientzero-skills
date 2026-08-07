#!/usr/bin/env bash
# Grade one review against seeds.json. Usage: grade-catch.sh <run_dir> <seeds> <cfg> → JSON
set -euo pipefail
RUN_DIR="$(cd "${1:?run_dir}" && pwd)"; SEEDS="${2:?seeds}"; CFG="${3:?cfg}"
R="$RUN_DIR/review.md"
[ -f "$R" ] || { echo '{"error":"no-review"}'; exit 0; }

PROMPT="Match a review's findings against ground-truth planted flaws. A flaw counts as CAUGHT only if a finding identifies that specific problem (claim number match alone is not enough; the described defect must match). Also count false alarms: findings that dispute any of the true-claim numbers listed in the ground truth.

GROUND TRUTH:
$(cat "$SEEDS")

REVIEW:
---
$(cat "$R")
---

Reply ONLY JSON: {\"caught\":{\"<seed_id>\":true|false,...all six seeds...},\"false_alarms\":<count>,\"verdict_line\":\"<first line of review>\"}"

printf '%s' "$PROMPT" | CLAUDE_CONFIG_DIR="$CFG" "${CLAUDE_BIN:-claude}" -p --model sonnet 2>/dev/null | sed -n '/^{/,$p'
