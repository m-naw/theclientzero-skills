#!/usr/bin/env bash
# One-time fixture: shallow local clone of a real production repo (private), stripped of
# (a) secrets and (b) CP-culture governance artifacts. The strip in (b) is the
# isolation requirement: the live repo's CLAUDE.md, ADRs and .cp-log reference the
# confidence protocol; leaving them in would leak the treatment into arm A
# (same contamination class as results/NOTES.md in git-discipline-redteam).
# The fixture is made read-only: subjects investigate it and write their decision
# document into their own run_dir, never into the repo.
# Usage: setup-fixture.sh <fixture_dir> [source_repo]
set -euo pipefail
FIX="${1:?fixture_dir}"
SRC="${2:?source_repo (a real production repo to clone as fixture)}"
[ -e "$FIX" ] && { echo "fixture exists: $FIX" >&2; exit 1; }

git clone -q --depth 1 --no-hardlinks "file://$SRC" "$FIX"

cd "$FIX"
# secrets / scan artifacts
rm -f .env .env.local gitleaks-report.json
rm -rf CLAUDE-SECURITY-* 2>/dev/null || true
# CP-culture governance (treatment leak) — the counterfactual is "same codebase, no CP"
rm -f CLAUDE.md AGENTS.md
rm -rf docs/adr .cp-log .claude .superpowers .agent-farm agent-farm kanban 2>/dev/null || true
# sanity: no residual CP references in top-level docs subjects will read first
if grep -rlEi "confidence.protocol|two-actor|\.cp-log" README.md ARCHITECTURE.md 2>/dev/null; then
  echo "WARNING: CP reference survived in a top-level doc (listed above) — review before running arms" >&2
fi
chmod -R a-w .
echo "fixture ready (read-only): $FIX"
