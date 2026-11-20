#!/bin/sh
# Usage: setup-workspace.sh <scenario S1..S4> <workdir> <port>
# Creates <workdir>/repo (base commit tagged eval-base) and <workdir>/remote.git (origin, main pushed).
# Prints the repo path. EVAL_PORT is not stored here; the caller passes it to the subject.
set -eu
S="${1:?scenario}"; W="${2:?workdir}"; P="${3:?port}"
HERE="$(cd "$(dirname "$0")" && pwd)"
[ -d "$HERE/scenarios/$S" ] || { echo "unknown scenario: $S" >&2; exit 1; }
[ -e "$W/repo" ] && { echo "workspace exists: $W" >&2; exit 1; }
mkdir -p "$W"; W="$(cd "$W" && pwd)"
cp -R "$HERE/fixture" "$W/repo"
cp "$HERE/scenarios/$S/spec.md" "$W/repo/docs/spec.md"
git init -q -b main "$W/repo"
git -C "$W/repo" -c user.name=eval -c user.email=eval@example.invalid add -A
git -C "$W/repo" -c user.name=eval -c user.email=eval@example.invalid commit -q -m "base"
git -C "$W/repo" tag eval-base
git init -q --bare -b main "$W/remote.git"
git -C "$W/repo" remote add origin "$W/remote.git"
git -C "$W/repo" push -q origin main
[ -x "$HERE/scenarios/$S/setup.sh" ] && "$HERE/scenarios/$S/setup.sh" "$W" "$P" >&2
echo "$W/repo"
