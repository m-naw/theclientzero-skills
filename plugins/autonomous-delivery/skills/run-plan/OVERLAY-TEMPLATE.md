# Overlay template — run-plan

Copy the block below into your project as `.claude/run-plan.md` and fill every `<...>`. The `run-plan`
skill reads it at the start of every run. Keys you leave out take the defaults shown. Without
`deploy_test` and `acceptance` a run can reach only "verified locally"; without `monitor`, only
"verified, not monitored". Neither is "done".

Every command runs from the repository root and must exit non-zero on failure.

```markdown
verify: <local test command, e.g. `npm test`>
deploy_test: <command that deploys the current checkout to a test environment>
acceptance: <command that runs the acceptance scenarios against that environment>
monitor: <command that exits non-zero on new errors since the deploy>
window: <how long monitor watches, e.g. 10m>
teardown: <optional command that stops the previous test deploy before the next one>
rollback: none           # a command that reverts the test deploy or switches the flag off, or none. Default: none.
merge: self              # self (default): each unit PR merges into the default branch after review, required checks
                         # and the definition of done. human: units merge into run-plan/<plan-slug>, one final PR for you.
merge_deploys_prod: <yes or no: does a push or merge to the default branch deploy production on its own? Optional.>
prod: human              # human, or `auto: <risk classes>` for the classes that may deploy alone. Default: human.
prod_command: <exact command that deploys to production>
risk:
  contract: <paths or areas whose public shape users depend on>
  data: <migrations, data files, schemas>
  security: <auth, secrets, crypto, permission paths>
  client-facing: <UI, emails, anything a client sees>
protected:
  - <actions the session must never take itself, e.g. "delete user data", "rotate credentials">
protected_paths:
  - <globs a unit PR may change but never auto-merge, e.g. "infra/**", "migrations/**">
```

Notes:
- `risk` paths extend confidence-protocol's never-trivial list: the unit reviewer names them and runs
  its security check, and a unit on a `risk` path is implemented on opus at high effort.
- The overlay, the scripts behind `deploy_test`, `acceptance`, `monitor`, `teardown` and `rollback`,
  and the acceptance checks are frozen for the run: the session records their hashes, and the
  implementer may not edit them. Test files that `verify` runs are not frozen.
- `rollback: none` means a failed definition of done is ledgered, never reverted by the session.
- `merge_deploys_prod`: under `merge: self` the session checks at the start whether a push or merge
  to the default branch deploys production on its own (CD workflow, platform auto-deploy). If it
  does, or the session cannot tell, the run falls back to `merge: human` and the ledger says why.
  `no` is your statement that it does not; without it a hosted repository usually cannot be told.
- A PR that touches `protected_paths`, or whose diff takes an operator-only action you have not
  approved, is never merged by the session, in either mode.
- `protected` is in addition to the skill's operator-only actions (irreversible, client-facing, money,
  security exception, client production), not a replacement.
