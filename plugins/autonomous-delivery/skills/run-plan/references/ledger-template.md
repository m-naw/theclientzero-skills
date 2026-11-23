# Ledger — <spec name>

Copy to `.run-plan/ledger.md`. Keep exactly these four sections. Print "Waiting on you" at the top
of every message to the operator; write "none" when it is empty. The final message lists the
PROVISIONAL rows of "Decided" right after it.

The operator answers an item by writing in its "Operator answer" cell. On resume, the run fills
"Checks affected" with the acceptance check ids whose required behavior the answer changes ("-" when
none), re-freezes only those checks, and moves the item to "Decided" citing the answer (`W<n> answer`).

## Waiting on you

| # | Item | Why it is yours | Recommendation | Exact step that clears it | Since | Operator answer | Checks affected |
|---|---|---|---|---|---|---|---|
| W1 | <one line> | <operator-only class or unpinned preference> | <recommendation, with evidence> | <command, or the answer to give> | <date, unit> | <empty until the operator writes it> | <check ids, or "-"> |

## Decided

| # | Decision | Citing source | CP state | How verified | PROVISIONAL: how to reverse |
|---|---|---|---|---|---|
| D1 | <decision> | <`file:line`, test, or command and output> | <REVIEWED or LANDED; PROPOSED only if PROVISIONAL> | <subagent angle, test run, or command> | <alternative and exact step, or "-"> |

## Follow-ups

| # | Follow-up | Value | Cost | Risk | Verdict |
|---|---|---|---|---|---|
| F1 | <follow-up> | <high, medium or low> | <high, medium or low> | <high, medium or low> | <do now, ledger, or drop: reason> |

## Delivered

One row per unit and exactly one `run` row, kept identical in `.run-plan/state.md`. The `run` row names
the branch that holds all delivered work (integration branch under `merge: human`, default branch
under `merge: self`) and its head commit; the working tree is left checked out on it, or the Note
says why not.

| Scope | Branch | PR | Head commit | Status | Note |
|---|---|---|---|---|---|
| unit <name> | <unit branch> | <PR URL, or -> | <full or short hash> | <unit status> | <"-", or why not merged> |
| run | <branch with all delivered work> | <final PR URL, or -> | <full or short hash> | <plan status> | <"-", or why the tree is not on it> |
