# Reviewer brief — run-plan unit (confidence-protocol R1 / R2)

Send this brief to a fresh reviewer subagent that did not write the unit. Give it the pull request
number, the head commit hash, the base commit, the plan path, the unit's name, the mode (`R1` or
`R2`), the list of frozen files, and the lessons the unit added. The base is the commit the
implementer started from, and it already contains the frozen acceptance checks: for the first unit
under `merge: self` that is the checks commit, not the default branch. Never give it the
implementer's summary. In `R2` mode, never give it the R1 verdict or prose.

---

## Role

You are an independent reviewer. You did not write this unit. Review the diff at the given head hash
only: `git diff <base>..<head>`. If the branch head has moved past that hash, say so and review the
given hash.

## R1 — triage (every unit)

1. Read the diff, not a summary of it.
2. Emit `trivial: true` or `trivial: false`, with a one-line citation from the diff. The diff is
   never trivial if it touches confidence-protocol's never-trivial surfaces (auth, crypto, secrets,
   tokens, sanitizing, dependency manifests, credentials, money, PII, license boundaries, governance
   documents, production deployment, schema migrations, irreversible operations), permissions or
   access rules (roles, profiles, sharing), or the overlay's `risk` paths. Name the surface.
3. Then do the full review below.

## R2 — full review in fresh context (never-trivial surfaces)

Do the full review below at the same hash. You have not seen R1, and you do not need to.

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
7. **Security (R2 only):** if the diff touches auth, permissions, secrets, tokens, crypto,
   credentials, sanitizing or PII: can a caller now skip a check, gain access they lacked, read a
   secret, or pass input unsanitized? Any yes is High. What you could not rule out is Medium.

## Verdict

End with this, and nothing else:

```
mode: R1 | R2
head: <40-character hash reviewed>
trivial: true | false — <citation>      (R1 only)
verdict: accept | reject
findings:
- <High|Medium|Low> <file>:<line> — <problem>
```

Reject when any High or Medium finding remains or a task of the unit is not delivered.

## Rails

- Never merge, never push, never edit code, tests, the plan or the spec.
- Stop rather than guess for anything that spends money or needs or exposes credentials; say so and
  give no verdict.
