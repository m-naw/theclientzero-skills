# Reviewer briefs — run-plan (spec and plan, unit, milestone)

Every reviewer is a fresh subagent that wrote nothing it reviews. This replaces confidence-protocol's
R1/R2 chain inside a run: one opus review per unit, a second only by exception, and the security
review once per milestone instead of per unit.

Send each reviewer only its own part of this file: the spec-and-plan reviewer and the acceptance
checks reviewer each get their own section and Rails; a unit reviewer gets Role, Full review, Verdict and Rails; a milestone reviewer gets the
Milestone section, the Full review checks it names, Verdict and Rails.

## Spec and plan review (once, opus, before the acceptance checks)

Give it the spec path, the plan path and the overlay path. Never give it the session's reasoning.
Up to 2 rounds: after the plan is fixed, the same brief runs once more on the new plan.

Read the spec and the plan together and report, each with the spec or plan line it rests on:

1. **Consistency:** a spec requirement no unit delivers, a unit the spec does not ask for, an
   acceptance scenario no unit makes pass, or a dependency the plan gets wrong.
2. **Spec gaps:** behaviour the spec states without an acceptance scenario, scenarios that
   contradict each other, and steps that would break an existing contract (API shape, schema, CLI
   output) or change or delete existing data.
3. **Operator-only actions** the spec implies but does not name (irreversible, client-facing,
   money, security exception, production).
4. **Security:** anything in the spec or plan that would let a caller skip a check, gain access, read
   a secret or pass input unsanitized.
5. **Parallel-safe claims:** for each pair of units the plan runs at once: do they share a file,
   module, schema or migration, does either need the test environment while it is implemented, or
   can `verify` not run in two worktrees at once (a fixed address, a shared database)? Any yes is
   High. The definition of done does not count: the orchestrator runs it one unit at a time.

Classify each finding: `derivable` (a cited source settles it), `preference` (reversible, no source
settles it) or `operator-only`. End with `verdict: accept | findings` and the list.

## Acceptance checks review (once, opus, before the checks are frozen)

Give it the spec path, the plan path, the checks commit and the author's report with its red output.
Never give it the author's reasoning or the session's. The reviewer did not write the checks.

For each scenario id, with the spec line it rests on, report:

1. **Coverage:** does the check assert everything the scenario requires (every field, status, error,
   edge the spec line names)? A requirement with no assertion is High.
2. **Vacuous pass:** would a trivial or wrong implementation pass it (a hard-coded response, an
   empty list, any 200, a check that only looks for a key)? Name the implementation. Any yes is High.
3. **Behaviour, not structure:** does it test what a user or client observes, through the deployed
   interface, rather than internal names, files or call order? A check that a correct
   implementation could fail is High.
4. **Red for the right reason:** does the red output show the behaviour missing, not a broken check
   (wrong path or address, typo, missing tool)? A `guard` must pass on the base and protect an existing
   shape the spec keeps.
5. **Missing scenarios and rail breaks:** a spec behaviour with no check, or a check that could pass
   only by deleting data, touching production or breaking a contract.

Classify each finding `derivable` or `preference`. End with `verdict: accept | findings` and the list.

## Unit review (opus, exactly one per unit PR)

Give it the pull request number, the head commit hash, the base commit, the plan path, the unit's
name, the list of frozen files, the lessons the unit added, and any operator answer that approves an
operator-only action in this unit. The base is the commit just below the unit's own commits (after a
rebase, the commit it was rebased onto), and it already contains the frozen acceptance checks: for a
unit that still stands on the checks branch, that is the checks commit, not the default branch.
Never give it the implementer's summary.

A new head (after a fix or a rebase) gets a fresh reviewer and the same brief: the review that
counts is the one at the hash that merges.

A second, independent unit review (`fable`; opus in a fresh context where that model is not offered)
runs only by exception: the problem is genuinely hard, the change is complex and touches many areas,
or the session is not confident. The session records the reason under "Decided". The second reviewer
gets the same brief and never sees the first verdict or prose.

### Role

You are an independent reviewer. You did not write this unit. Review the diff at the given head hash
only: `git diff <base>..<head>`. If the branch head has moved past that hash, say so and review the
given hash. Read the diff, not a summary of it. Name every surface it touches from
confidence-protocol's never-trivial list (auth, crypto, secrets, tokens, sanitizing, dependency
manifests, credentials, money, PII, license boundaries, governance documents, production deployment,
schema migrations, irreversible operations), permissions or access rules, or the overlay's `risk`
paths. Then do the full review.

## Full review

1. **Plan conformance:** is every task of the unit delivered as the plan says? A missing task is High.
2. **Tests:** does each new behaviour have a test that fails without the change? Compare every
   changed test file with its base: a weakened, skipped or deleted assertion is High.
3. **Contracts:** does any existing response shape, schema, CLI output or file format change in a way
   current users would notice? Unless the spec states in words that existing clients will break, it
   is High.
4. **Operator-only actions:** does the diff delete data, spend money, touch production, or take an
   action on the overlay's `protected` list? Any yes is High. One exception: a deletion, spend or
   production step that is exactly the action, in exactly the scope, of an operator answer you were
   given. An action on the `protected` list is never excepted.
5. **Frozen files:** does the diff add, change or delete a file on the frozen list you were given, or
   any other file in the acceptance checks' directory? Any yes is High. Test files that `verify` runs
   are not frozen: check 2 covers them.
6. **Lessons:** for each lesson the unit added, ask "does this weaken a gate?". Each yes is High.
7. **Security:** if the diff touches auth, permissions, secrets, tokens, crypto,
   credentials, sanitizing or PII: can a caller now skip a check, gain access they lacked, read a
   secret, or pass input unsanitized? Any yes is High. What you could not rule out is Medium.

## Verdict

End with this, and nothing else:

```
mode: first | second
head: <40-character hash reviewed>
surfaces: <never-trivial surfaces and `risk` paths touched, or none>
verdict: accept | reject
findings:
- <High|Medium|Low> <file>:<line> — <problem>
```

Reject when any High or Medium finding remains or a task of the unit is not delivered.

## Milestone review (opus, at each milestone end)

A milestone of exactly one unit gets one opus review instead: the unit review plus the capstone
and security criteria below on that unit's diff, ending with the verdict block; no separate capstone or
security reviewer. Otherwise two reviewers, each fresh, on the milestone diff (`git diff <milestone base>..<target head>`), once
per milestone and never per unit. The milestone base is the commit its first unit started from (for
the first milestone the checks commit, so the frozen checks are not in the diff); the orchestrator
records it in `state.md` when that unit starts.

- **Capstone:** does the milestone, as merged, deliver its part of the spec and plan; do units
  conflict, duplicate or leave a scenario uncovered? Use the full review's checks 1 to 5 on the
  whole diff.
- **Security:** `/security-review` when available, else check 7 of the full review on the whole
  diff. A High finding in code this run wrote becomes one more unit; that unit gets the unit
  review, and the milestone reviews do not run again for it.

Both end with the verdict block above, `mode: capstone` or `mode: security`.

## Rails

- Never merge, never push, never edit code, tests, the plan or the spec.
- Stop rather than guess for anything that spends money or needs or exposes credentials; say so and
  give no verdict.
