#!/bin/sh
# Run a grid of subjects sequentially (or 2 at a time with -j 2).
# Usage: run-batch.sh [-j 1|2] [-p base_port] <arms A,B,C> <scenarios S1,S2,..> <n> <out_dir>
# Env: SUBJECT_CONFIG_DIR and JUDGE_CONFIG_DIR (both required, clean and authenticated), plus run-subject.sh's env.
# Run i gets port base_port+i (default base 18400). Run dirs: <out_dir>/<scenario>-<arm>-<n>/ (skipped if graded already).
# One line per graded run is appended to <out_dir>/summary.jsonl: grade.json plus arm, n, timed_out.
# Stops the batch on exit 2 (no auth) or 3 (judge error) of any run. Exit 0 if all runs graded, else the stop code or 1.
set -u
HERE="$(cd "$(dirname "$0")" && pwd)"
J=1; BASE=18400
while getopts j:p: o; do case $o in j) J=$OPTARG ;; p) BASE=$OPTARG ;; *) exit 1 ;; esac; done
shift $((OPTIND-1))
ARMS=$(printf '%s' "${1:?arms}" | tr ',' ' '); SCENS=$(printf '%s' "${2:?scenarios}" | tr ',' ' '); N="${3:?n}"; OUT_ARG="${4:?out_dir}"
[ "$J" = 1 ] || [ "$J" = 2 ] || { echo "-j must be 1 or 2" >&2; exit 1; }
for v in SUBJECT_CONFIG_DIR JUDGE_CONFIG_DIR; do
  eval "d=\${$v:-}"; [ -n "$d" ] && [ -d "$d" ] || { echo "no auth in ${d:-<$v unset>}" >&2; exit 2; }
done
mkdir -p "$OUT_ARG"; OUT="$(cd "$OUT_ARG" && pwd)"

run_one() { # idx scenario arm rep
  d="$OUT/$2-$3-$4"
  [ -f "$d/grade.json" ] && { echo "skip $d"; return 0; }
  sh "$HERE/run-subject.sh" "$d" "$3" "$2" "$((BASE+$1))" "$SUBJECT_CONFIG_DIR" </dev/null > "$d.log" 2>&1; rc=$?
  if [ $rc -eq 0 ]; then
    jq -c --arg arm "$3" --argjson n "$4" --argjson t "$(cat "$d/meta/timed_out")" '. + {arm:$arm,n:$n,timed_out:$t}' "$d/grade.json" >> "$OUT/summary.jsonl"
    echo "done $d correct=$(jq -r .correct "$d/grade.json")"
  else echo "FAILED rc=$rc $d (see $d.log)"; tail -n 3 "$d.log"; fi
  return $rc
}

IDX=0; STOP=0; ANYFAIL=0; PIDS=""
flush() { for p in $PIDS; do wait "$p"; rc=$?; [ $rc -eq 0 ] || ANYFAIL=1; { [ $rc -eq 2 ] || [ $rc -eq 3 ]; } && STOP=$rc; done; PIDS=""; }
rep=1
while [ "$rep" -le "$N" ] && [ $STOP -eq 0 ]; do
  for s in $SCENS; do for a in $ARMS; do
    [ $STOP -eq 0 ] || break
    IDX=$((IDX+1))
    run_one "$IDX" "$s" "$a" "$rep" & PIDS="$PIDS $!"
    [ "$(echo $PIDS | wc -w)" -lt "$J" ] || flush
  done; done
  flush
  rep=$((rep+1))
done
flush
[ $STOP -ne 0 ] && exit $STOP
exit $ANYFAIL
