#!/usr/bin/env bash
# Jev probe for one run. Sends exactly what the blind judge sees: rubric ground-truth facts,
# scenario name, decision.md. No arm label, no run id, no fixture access.
# Usage: jev-one.sh <run_dir> <scenario>   → JSON on stdout (raw API response + timing)
# Env: TYPESAFE_API_KEY (required), TYPESAFE_MODEL (default jev-latest)
set -euo pipefail
HERE="$(cd "$(dirname "$0")" && pwd)"
RUN_DIR="$(cd "${1:?run_dir}" && pwd)"; SCENARIO="${2:?scenario}"
: "${TYPESAFE_API_KEY:?TYPESAFE_API_KEY not set}"
MODEL="${TYPESAFE_MODEL:-jev-latest}"
D="$RUN_DIR/decision.md"
[ -f "$D" ] || { echo '{"error":"no-decision-doc"}'; exit 0; }

# same ground-truth block the judge receives (rubric section between "## Ground truth" and "## Semantic")
GT="$(sed -n '/^## Ground truth/,/^## Semantic/p' "$HERE/../cp-vacuum-fill/grading-rubric.md" | sed '$d')"

STATE="$(printf 'GROUND TRUTH (fixture facts):\n%s\n\nSCENARIO: %s\n\nDECISION DOCUMENT:\n---\n%s\n---\n' "$GT" "$SCENARIO" "$(cat "$D")")"

BODY="$(jq -n --arg state "$STATE" --arg model "$MODEL" --arg sc "$SCENARIO" \
  --slurpfile bank "$HERE/questions/bank.json" \
  '{state:$state, model:$model, questions:($bank[0].common + ($bank[0][$sc] // {}))}')"

start=$(date +%s%N)
for attempt in 1 2 3 4 5; do
  resp="$(curl -sS -w '\n%{http_code}' -X POST https://api.typesafe.ai/v1/systemone \
    -H "Authorization: Bearer $TYPESAFE_API_KEY" -H 'Content-Type: application/json' \
    --data-binary "$BODY")" || resp=$'\n000'
  code="${resp##*$'\n'}"; json="${resp%$'\n'*}"
  case "$code" in
    200) break ;;
    429|529|000) sleep $((attempt * attempt * 2)) ;;
    *) echo "{\"error\":\"http-$code\",\"body\":$(printf '%s' "$json" | jq -Rs .)}"; exit 0 ;;
  esac
done
[ "$code" = 200 ] || { echo "{\"error\":\"http-$code-after-retries\"}"; exit 0; }
ms=$(( ($(date +%s%N) - start) / 1000000 ))
printf '%s' "$json" | jq --argjson ms "$ms" --arg sc "$SCENARIO" '. + {scenario:$sc, wall_ms:$ms}'
