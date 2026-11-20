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
S=plugins/autonomous-delivery/skills/run-plan
SK=$S/SKILL.md
# frontmatter: exactly two keys, name then description
check skill-frontmatter sh -c "awk 'NR==1&&\$0!=\"---\"{exit 1} NR>1&&\$0==\"---\"{exit} NR>1{print}' $SK | sed 's/:.*//' | tr '\n' ' ' | grep -qx 'name description '"
check skill-name grep -qx 'name: run-plan' "$SK"
check skill-description grep -q '^description: "\{0,1\}Use when' "$SK"
for h in 'Definition of done' Ledger Decisions Flow Resume 'Red flags'; do
  check "heading-$h" grep -qx "## $h" "$SK"
done
check resume-line grep -qF '/run-plan continue' "$SK"
check cp-reference grep -q confidence-protocol "$SK"
check no-askuserquestion sh -c "[ \"\$(grep -c AskUserQuestion $SK)\" -le 1 ]"
check skill-length sh -c "[ \"\$(wc -l < $SK)\" -le 200 ]"
for k in verify deploy_test acceptance monitor merge prod risk protected; do
  check "overlay-$k" grep -q "^$k:" "$S/OVERLAY-TEMPLATE.md"
done
for r in implementer reviewer acceptance ledger-template; do
  check "reference-$r" test -s "$S/references/$r.md"
done
check ledger-sections sh -c "[ \"\$(grep '^## ' $S/references/ledger-template.md | tr '\n' '|')\" = '## Waiting on you|## Decided|## Follow-ups|' ]"
exit "$fail"
