#!/usr/bin/env bash
# Recall grader for one run: matches the run's findings against seeds.json.
# Delegated to a clean-config sonnet judge (no tools); dispatching session
# spot-checks per the pre-registration ledger.
# Usage: grade-recall.sh <run_dir> <seeds_json> <cfg>   → JSON on stdout
set -euo pipefail
RUN_DIR="$(cd "${1:?run_dir}" && pwd)"; SEEDS="${2:?seeds}"; CFG="${3:?cfg}"

FINDINGS="$(find "$RUN_DIR" -maxdepth 1 -name '*.md' -exec sh -c 'echo "== $(basename "$1") =="; cat "$1"; echo' _ {} \;)"
[ -n "$FINDINGS" ] || { echo '{"error":"no-findings-files"}'; exit 0; }

PROMPT="You are matching code-review findings against a ground-truth list of seeded defects. Be strict: a seed counts as FOUND only if some finding cites its file and describes the same defect (line numbers may differ slightly; the defect identity must match).

GROUND TRUTH SEEDS:
$(cat "$SEEDS")

REVIEW FINDINGS (all files from one review run):
---
$FINDINGS
---

Reply with ONLY JSON:
{\"found\":{\"<seed_id>\":true|false,...for every seed id...},\"false_positives\":<count of distinct findings that match no seed>,\"notes\":\"<=2 sentences\"}"

printf '%s' "$PROMPT" | CLAUDE_CONFIG_DIR="$CFG" "${CLAUDE_BIN:-claude}" -p --model sonnet 2>/dev/null | sed -n '/^{/,$p'
