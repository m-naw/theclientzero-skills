#!/usr/bin/env bash
# Blind judge every run (reuses ../cp-vacuum-fill/judge-one.sh). Writes <run>/judge.json.
# Usage: judge-all.sh <runs_root> [parallelism=4]
set -euo pipefail
HERE="$(cd "$(dirname "$0")" && pwd)"
RUNS="$(cd "${1:?runs_root}" && pwd)"; PAR="${2:-4}"
CFG="$RUNS/.clean-config"; mkdir -p "$CFG"; cp "$HOME/.claude/.credentials.json" "$CFG/"   # fresh copy per batch

judge_one() {
  rd="$1"; sc="$(basename "$rd" | sed -E 's/-[AN]-[0-9]+$//')"
  [ -s "$rd/judge.json" ] && jq -e 'has("J1")' "$rd/judge.json" >/dev/null 2>&1 && return 0
  out="$(bash "$HERE/../cp-vacuum-fill/judge-one.sh" "$rd" "$sc" "$CFG")"
  if printf '%s' "$out" | jq -e 'has("J1")' >/dev/null 2>&1; then
    printf '%s' "$out" | jq -c 'del(.quotes)' > "$rd/judge.json"
    printf '%s' "$out" | jq -c '.quotes // {}' > "$rd/judge-quotes.json"
    echo "judged $(basename "$rd")"
  else
    echo "EMPTY/INVALID judge for $(basename "$rd") (rerun)"; printf '%s' "$out" > "$rd/judge-raw.txt"
  fi
}
export -f judge_one; export HERE CFG
ls -d "$RUNS"/*-[AN]-[1-8] | xargs -P "$PAR" -I{} bash -c 'judge_one "$@"' _ {}
echo "judged: $(ls "$RUNS"/*-[AN]-[1-8]/judge.json 2>/dev/null | wc -l)/$(ls -d "$RUNS"/*-[AN]-[1-8] | wc -l)"
