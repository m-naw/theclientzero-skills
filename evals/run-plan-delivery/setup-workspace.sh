#!/bin/sh
# Usage: setup-workspace.sh <scenario S1..S4> <workdir> <port>
# Creates <workdir>/repo (base commit tagged base; its SHA also in <workdir>/meta/base.sha) and <workdir>/remote.git (origin, main pushed).
# Prints the repo path. The port is used only by scenario hooks (S4 blocker).
set -eu
S="${1:?scenario}"; W="${2:?workdir}"; P="${3:?port}"
HERE="$(cd "$(dirname "$0")" && pwd)"
[ -d "$HERE/scenarios/$S" ] || { echo "unknown scenario: $S" >&2; exit 1; }
[ -e "$W/repo" ] && { echo "workspace exists: $W" >&2; exit 1; }
mkdir -p "$W"; W="$(cd "$W" && pwd)"
cp -R "$HERE/fixture" "$W/repo"
[ -f "$W/repo/.claude/run-plan.md" ] || { echo "fixture overlay missing" >&2; exit 1; }
cp "$HERE/scenarios/$S/spec.md" "$W/repo/docs/spec.md"
G="git -C $W/repo -c user.name=dev -c user.email=dev@example.invalid"
git init -q -b main "$W/repo"
$G add -A
$G commit -q -m "base"
$G tag base
mkdir -p "$W/meta"; $G rev-parse base > "$W/meta/base.sha"   # trusted copy; the repo-local tag is not
git init -q --bare -b main "$W/remote.git"
$G remote add origin "$W/remote.git"
$G push -q origin main
[ -x "$HERE/scenarios/$S/setup.sh" ] && "$HERE/scenarios/$S/setup.sh" "$W" "$P" >&2
echo "$W/repo"
