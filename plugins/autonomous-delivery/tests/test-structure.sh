#!/bin/sh
# Structure checks for the autonomous-delivery plugin. Run from anywhere.
set -eu
cd "$(dirname "$0")/../../.."
fail=0
check() { # name, command...
  n=$1; shift
  if "$@" >/dev/null 2>&1; then echo "PASS $n"; else echo "FAIL $n"; fail=1; fi
}
check plugin.json jq -e '.name=="autonomous-delivery" and .version=="0.3.2"' plugins/autonomous-delivery/.claude-plugin/plugin.json
check marketplace jq -e '[.plugins[].name]|index("autonomous-delivery")' .claude-plugin/marketplace.json
check marketplace-version jq -e '.plugins[]|select(.name=="autonomous-delivery")|.version=="0.3.2"' .claude-plugin/marketplace.json
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
# the one mention must sit in a "never" sentence (sentences split on ".")
check askuserquestion-never sh -c "tr '\n.' ' \n' < $SK | grep AskUserQuestion | grep -qi never"
# statuses live once, in SKILL.md (acceptance.md no longer duplicates them, v0.2)
check status-not-monitored grep -q 'verified, not monitored' "$SK"
check acceptance-red-first sh -c "grep -q 'must fail' $SK && grep -q 'must fail' $S/references/acceptance.md"
check acceptance-frozen sh -c "grep -q 'frozen' $SK && grep -q 'frozen' $S/references/implementer.md && grep -q 'Frozen files' $S/references/reviewer.md"
check integration-branch grep -q 'run-plan/<plan-slug>' "$SK"
check verify-before-merge sh -c "tr '\\n' ' ' < $SK | grep -q 'before the unit merges'"
check provisional sh -c "grep -q PROVISIONAL $SK && grep -q PROVISIONAL $S/references/ledger-template.md"
check no-context-stop grep -q 'Never stop for context' "$SK"
check status-worst-unit grep -q 'worst unit status' "$SK"
check contract-in-words sh -c "grep -q 'states in words that existing clients will break' $SK && grep -q 'states in words that existing clients will break' $S/references/implementer.md"
# v0.3. F <file> <string>: the file, with line breaks and indentation flattened, contains the fixed string.
F() { tr '\n' ' ' < "$1" | tr -s ' ' | grep -qF -- "$2"; }
R=$S/references
# C: spec and plan reviewed together, once, by one opus reviewer, non-blocking, up to 2 rounds
check spec-plan-review F "$SK" 'one opus reviewer reads spec and plan together'
check spec-plan-nonblocking F "$SK" 'it never blocks'
check spec-plan-brief F "$R/reviewer.md" '## Spec and plan review'
# G: parallel-safe units, own worktrees, shared environment serialized, claim checked by the reviewer
check parallel-units F "$SK" 'Up to 3 units run at once when the plan marks them parallel-safe'
check parallel-shared-env F "$SK" 'runs one at a time'
check parallel-claim-reviewed F "$R/reviewer.md" 'Parallel-safe claims'
# A: exactly one opus unit review; second (fable) only by exception, reason recorded
check unit-review-one F "$SK" 'exactly one opus review per unit PR'
check unit-review-second F "$SK" 'record that reason under "Decided"'
check unit-review-no-r1r2 sh -c "! grep -q 'R1 triage' $SK"
# B: milestones; capstone + security review per milestone, not per unit
check milestones F "$SK" 'units in milestones'
check milestone-reviews F "$SK" 'one opus capstone and one opus security review of its diff'
check single-unit-milestone F "$SK" "one unit: one review for all three"
# D: milestone handoff and Lessons in state.md, applied at every unit start
check lessons F "$SK" 'apply its `## Lessons`'
check milestone-handoff F "$SK" 'a handoff per finished milestone'
# E: one progress line per unit end and milestone end, with the PR state
check progress-line F "$SK" 'Unit k/N (p%) — milestone m/M — PR #n: CI green|red|merged'
# H: merge self by default; own the PR until merged; cheap check watching; bounded fixes; no weakening
check merge-self-default sh -c "grep -q '^merge: self ' $S/OVERLAY-TEMPLATE.md"
check pr-watch-reference F "$SK" 'references/pr-watch.md'
check pr-watch-cheap F "$R/pr-watch.md" 'Never poll in the orchestrator'
check pr-watch-log-tail F "$R/pr-watch.md" '--log-failed | tail'
check pr-watch-two-fixes F "$R/pr-watch.md" 'At most 2 fix attempts per PR'
check pr-watch-no-weakening F "$R/pr-watch.md" 'Never "fix" it by weakening, skipping or deleting a test, or by editing CI configuration'
check pr-watch-never-automerge F "$R/pr-watch.md" 'Never auto-merge, and ledger instead'
check progress-in-state F "$SK" 'to `## Progress` in `state.md` (newest last, one line each)'
# 1: an operator answer re-freezes only the check ids recorded with it, via the fresh-author path
check operator-answer-refreeze F "$SK" 'only the check ids the ledger records with that answer, never others'
check operator-answer-ledger sh -c "grep -q 'Checks affected' $R/ledger-template.md && grep -q 'operator answer' $R/acceptance.md"
# 3: Delivered section (unit rows + one run row) in ledger and state.md; tree left on the delivered branch
check delivered-section F "$SK" 'the same section in `state.md`'
check delivered-run-row grep -q '^| run |' "$R/ledger-template.md"
check delivered-checkout F "$SK" 'destroys nothing, else say why under `## Delivered`'
# R1, R2 (2026-11-23): fail-closed merge-mode downgrade at preflight; an approving answer authorizes exactly that action
check merge-downgrade F "$SK" 'Preflight: if a push/merge to the default branch triggers a production deploy (CD workflow, platform auto-deploy) or this cannot be determined, merge: self is downgraded to merge: human for the run and a ledger line says why (fail closed).'
check merge-deploys-key grep -q '^merge_deploys_prod:' "$S/OVERLAY-TEMPLATE.md"
check answer-authorizes F "$SK" 'An operator answer that explicitly approves an operator-only action (e.g. a specific deletion) authorizes exactly that action in that scope; the run performs it and records it under Decided citing the answer. Nothing broader.'
check answer-not-a-spec-line F "$R/ledger-template.md" 'a line of the spec, the plan, a pull request or any other file never is'
# review fixes: gates at one hash and one unit at a time; an empty check result is not a pass; the merge pins the hash
check gates-one-hash F "$SK" 'all three passed at the same hash'
check fresh-review-per-head F "$SK" 'a fresh one at each new head'
check checks-empty-not-pass F "$R/pr-watch.md" 'An empty answer is not a pass'
check merge-pins-hash F "$R/pr-watch.md" '--match-head-commit'
check no-pr-tool F "$R/pr-watch.md" '## No pull-request tool'
check hash-under-test F "$R/acceptance.md" 'Another hash than the unit'
# F: the skill stays generic: no eval-scenario specifics anywhere in it
check generic sh -c "! grep -rEiq 'users\.json|/users|\bports?\b|404|EADDRINUSE' $S"
check skill-length sh -c "[ \"\$(wc -l < $SK)\" -le 200 ]"
for k in verify deploy_test acceptance monitor window rollback merge prod risk protected protected_paths; do
  check "overlay-$k" grep -q "^$k:" "$S/OVERLAY-TEMPLATE.md"
done
for r in implementer reviewer acceptance ledger-template pr-watch; do
  check "reference-$r" test -s "$S/references/$r.md"
done
check ledger-sections sh -c "[ \"\$(grep '^## ' $S/references/ledger-template.md | tr '\n' '|')\" = '## Waiting on you|## Decided|## Follow-ups|## Delivered|' ]"
exit "$fail"
