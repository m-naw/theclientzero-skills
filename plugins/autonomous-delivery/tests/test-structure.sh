#!/bin/sh
# Structure checks for the autonomous-delivery plugin. Run from anywhere.
set -eu
cd "$(dirname "$0")/../../.."
fail=0
check() { # name, command...
  n=$1; shift
  if "$@" >/dev/null 2>&1; then echo "PASS $n"; else echo "FAIL $n"; fail=1; fi
}
check plugin.json jq -e '.name=="autonomous-delivery" and .version=="0.1.0"' plugins/autonomous-delivery/.claude-plugin/plugin.json
check marketplace jq -e '[.plugins[].name]|index("autonomous-delivery")' .claude-plugin/marketplace.json
check README grep -q autonomous-delivery README.md
check CLAUDE.md grep -q autonomous-delivery CLAUDE.md
exit "$fail"
