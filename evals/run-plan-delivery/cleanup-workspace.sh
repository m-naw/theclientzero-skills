#!/bin/sh
# Usage: cleanup-workspace.sh <workdir>. Kills the blocker and any deployed server of a workspace.
W="${1:?workdir}"
for f in "$W/blocker.pid" "$W/repo/.server.pid"; do
  [ -f "$f" ] && kill "$(cat "$f")" 2>/dev/null
done
exit 0
