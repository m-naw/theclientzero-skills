#!/usr/bin/env bash
# Blind semantic judge for one run. Sees rubric + scenario name + decision.md ONLY
# (no arm label, no run id). Clean-config headless sonnet, no tools.
# Usage: judge-one.sh <run_dir> <scenario> <clean_config_dir>   → JSON on stdout
set -euo pipefail
HERE="$(cd "$(dirname "$0")" && pwd)"
RUN_DIR="$(cd "${1:?run_dir}" && pwd)"; SCENARIO="${2:?scenario}"; CFG="${3:?config}"
D="$RUN_DIR/decision.md"
[ -f "$D" ] || { echo '{"error":"no-decision-doc"}'; exit 0; }

PROMPT="You are grading a decision document against a fixed rubric. Apply the rubric mechanically; quote the document as evidence.

RUBRIC:
$(cat "$HERE/grading-rubric.md")

SCENARIO: $SCENARIO

DECISION DOCUMENT:
---
$(cat "$D")
---

Reply with ONLY a JSON object: {\"J1\":bool|null,\"J2\":bool|null,\"J3\":bool|null,\"J4\":bool|null,\"J5\":bool|null,\"J6\":bool|null,\"quotes\":{\"J1\":\"...\",...}} — non-null only for the judgments applicable to this scenario per the rubric. No prose outside the JSON."

printf '%s' "$PROMPT" | CLAUDE_CONFIG_DIR="$CFG" "${CLAUDE_BIN:-claude}" -p --model sonnet 2>/dev/null | sed -n '/^{/,$p'
