# Reviewer briefs — run-plan (spec and plan, unit, milestone)

Every reviewer is a fresh subagent that wrote nothing it reviews. This replaces confidence-protocol's
R1/R2 chain inside a run: one opus review per unit, a second only by exception, and the security
review once per milestone instead of per unit.

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
5. **Parallel-safe claims:** for each pair of units the plan runs at once, do they share a file,
   module, schema or the test environment? Any yes is High.

Classify each finding: `derivable` (a cited source settles it), `preference` (reversible, no source
settles it) or `operator-only`. End with `verdict: accept | findings` and the list.

## Unit review (opus, exactly one per unit PR)

Give it the pull request number, the head commit hash, the base commit, the plan path, the unit's
name, the list of frozen files, and the lessons the unit added. The base is the commit the
implementer started from, and it already contains the frozen acceptance checks: for a unit that
started on the checks branch, that is the checks commit, not the default branch. Never give it the
implementer's summary.

A second, independent unit review (`fable`) runs only by exception: the problem is genuinely hard,
the change is complex and touches many areas, or the session is not confident. The session records
the reason under "Decided". The second reviewer gets the same brief and never sees the first
verdict or prose.

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
   action on the overlay's `protected` list? Any yes is High.
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

Two reviewers, each fresh, on the milestone diff (`git diff <milestone base>..<target head>`), never
per unit:

- **Capstone:** does the milestone, as merged, deliver its part of the spec and plan; do units
  conflict, duplicate or leave a scenario uncovered? Use the full review's checks 1 to 5 on the
  whole diff.
- **Security:** `/security-review` when available, else check 7 of the full review on the whole
  diff. A High finding in code this run wrote becomes one more unit.

Both end with the verdict block above, `mode: capstone` or `mode: security`.

## Rails

- Never merge, never push, never edit code, tests, the plan or the spec.
- Stop rather than guess for anything that spends money or needs or exposes credentials; say so and
  give no verdict.
