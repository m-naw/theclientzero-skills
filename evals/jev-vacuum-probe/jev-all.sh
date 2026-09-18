#!/usr/bin/env bash
# Probe every run with Jev. Writes <run>/jev.json. Refuses to run before judge.json exists for
# every run (pre-registration: judge overrides are recorded before Jev output is read).
# Usage: jev-all.sh <runs_root>
set -euo pipefail
HERE="$(cd "$(dirname "$0")" && pwd)"
RUNS="$(cd "${1:?runs_root}" && pwd)"
: "${TYPESAFE_API_KEY:?TYPESAFE_API_KEY not set}"
missing=$(for rd in "$RUNS"/*-[AN]-[1-8]; do [ -f "$rd/judge.json" ] || basename "$rd"; done)
[ -z "$missing" ] || { echo "judge.json missing for:"; echo "$missing"; exit 1; }
for rd in "$RUNS"/*-[AN]-[1-8]; do
  [ -s "$rd/jev.json" ] && continue
  sc="$(basename "$rd" | sed -E 's/-[AN]-[0-9]+$//')"
  bash "$HERE/jev-one.sh" "$rd" "$sc" > "$rd/jev.json"
  echo "jev $(basename "$rd") $(jq -r '.error // .model' "$rd/jev.json") $(jq -r '.wall_ms // ""' "$rd/jev.json")ms"
done
echo "probed: $(ls "$RUNS"/*-[AN]-[1-8]/jev.json | wc -l)"
