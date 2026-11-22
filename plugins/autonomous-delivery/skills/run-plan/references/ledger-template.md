# Ledger — <spec name>

Copy to `.run-plan/ledger.md`. Keep exactly these three sections. Print "Waiting on you" at the top
of every message to the operator; write "none" when it is empty. The final message lists the
PROVISIONAL rows of "Decided" right after it.

## Waiting on you

| # | Item | Why it is yours | Recommendation | Exact step that clears it | Since |
|---|---|---|---|---|---|
| W1 | <one line> | <operator-only class or unpinned preference> | <recommendation, with evidence> | <command, or the answer to give> | <date, unit> |

## Decided

| # | Decision | Citing source | CP state | How verified | PROVISIONAL: how to reverse |
|---|---|---|---|---|---|
| D1 | <decision> | <`file:line`, test, or command and output> | <REVIEWED or LANDED; PROPOSED only if PROVISIONAL> | <subagent angle, test run, or command> | <alternative and exact step, or "-"> |

## Follow-ups

| # | Follow-up | Value | Cost | Risk | Verdict |
|---|---|---|---|---|---|
| F1 | <follow-up> | <high, medium or low> | <high, medium or low> | <high, medium or low> | <do now, ledger, or drop: reason> |
