#!/usr/bin/env bash
# Regenerate the 32 subject runs registered in preregistration.md (cells SE-A, SE-N, QM-A, CI-A),
# then grade each deterministically. Reuses ../cp-vacuum-fill/run-subject.sh verbatim.
# Usage: run-subjects.sh <runs_root> <fixture_dir> [parallelism=4]
set -euo pipefail
HERE="$(cd "$(dirname "$0")" && pwd)"
PRIOR="$HERE/../cp-vacuum-fill"
SKILL="$HERE/../../plugins/confidence-protocols/skills/confidence-protocol/SKILL.md"
RUNS="${1:?runs_root}"; FIX="$(cd "${2:?fixture}" && pwd)"; PAR="${3:-4}"
mkdir -p "$RUNS"; RUNS="$(cd "$RUNS" && pwd)"

# clean config: no plugins, no user settings; credentials copied fresh (refresh-token rotation
# invalidates stale copies — see cp-vacuum-fill preregistration deviation ledger, 2026-08-07)
# Claude Code 2.1.x pulls the account's claude.ai-synced skills into ANY config dir on login
# (skills/synced/<org>_<user>/…) — the user's synced set includes the retired numeric CP, so a
# "clean" dir still treated arm A. Plain files at skills/ and plugins/ block the sync (verified:
# bare probe answers "NO KNOWN PROTOCOL" only with the block in place).
CFG="$RUNS/.clean-config"; rm -rf "$CFG"; mkdir -p "$CFG"
cp "$HOME/.claude/.credentials.json" "$CFG/"; touch "$CFG/skills" "$CFG/plugins"

export CLAUDE_BIN="$(command -v claude)"; export DISABLE_AUTOUPDATER=1   # absolute path: 27/32 runs hit "claude: command not found" mid-batch on first attempt
"$CLAUDE_BIN" --version > "$RUNS/claude-version.txt" 2>&1 || true

run_one() {
  rd="$1"; arm="$2"; scenario="$3"
  start=$(date +%s)
  bash "$PRIOR/run-subject.sh" "$rd" "$arm" "$scenario" "$FIX" "$CFG"
  echo $(( $(date +%s) - start )) > "$rd/meta/wall-seconds"
  echo "done $(basename "$rd") $(cat "$rd/meta/subject-exit") $(cat "$rd/meta/wall-seconds")s"
}
export -f run_one; export PRIOR FIX CFG CLAUDE_BIN

for pass in 1 2; do   # pass 2 retries runs the binary swap killed (exit 127, no decision.md)
jobs_file="$RUNS/.jobs"; : > "$jobs_file"
for cell in "session-expiry A" "session-expiry N" "queue-mechanism A" "ci-versions A"; do
  set -- $cell; scenario="$1"; arm="$2"
  for i in 1 2 3 4 5 6 7 8; do
    rd="$RUNS/$scenario-$arm-$i"
    [ -f "$rd/decision.md" ] && continue   # resumable
    mkdir -p "$rd"
    [ "$arm" = N ] && cp "$SKILL" "$rd/loaded-skill.md"
    echo "$rd $arm $scenario" >> "$jobs_file"
  done
done

[ -s "$jobs_file" ] || break
xargs -P "$PAR" -L 1 bash -c 'run_one "$@"' _ < "$jobs_file"
done

# deterministic grades
for rd in "$RUNS"/*-[AN]-[1-8]; do
  bash "$PRIOR/grade-deterministic.sh" "$rd" "$FIX" > "$rd/det.json"
done
echo "subjects complete: $(ls -d "$RUNS"/*-[AN]-[1-8] | wc -l) runs, $(ls "$RUNS"/*-[AN]-[1-8]/decision.md 2>/dev/null | wc -l) with decision.md"
