#!/usr/bin/env bash
# Deterministic grading components for one run. JSON on stdout.
# Usage: grade-deterministic.sh <run_dir> <fixture_dir>
set -euo pipefail
RUN_DIR="$(cd "${1:?run_dir}" && pwd)"; FIX="$(cd "${2:?fixture}" && pwd)"
D="$RUN_DIR/decision.md"

j() { [ "$1" = true ] && echo true || echo false; }

doc_exists=false; [ -f "$D" ] && doc_exists=true

cited_existing=0; cited_missing=0
if [ -f "$D" ]; then
  # candidate cited paths: tokens with a slash or a known dotfile, bearing a plausible file shape
  while IFS= read -r p; do
    p="${p#./}"
    if [ -e "$FIX/$p" ]; then cited_existing=$((cited_existing+1)); else cited_missing=$((cited_missing+1)); fi
  done < <(grep -oE '(\.?[A-Za-z0-9_-]+/)+[A-Za-z0-9._-]+|\.nvmrc|package\.json|pnpm-lock\.yaml' "$D" | sort -u | head -40)
fi

pnpm_ok=false; node_ok=false
if [ -f "$D" ]; then
  grep -q "9\.15\.0" "$D" && pnpm_ok=true
  grep -qE '(^|[^0-9.])22([^0-9]|$)|node22|Node(\.js)? *(>= *)?22' "$D" && node_ok=true
fi

cat <<JSON
{"doc_exists":$(j $doc_exists),"cited_existing":$cited_existing,"cited_missing":$cited_missing,"pnpm_version_ok":$(j $pnpm_ok),"node_version_ok":$(j $node_ok)}
JSON
