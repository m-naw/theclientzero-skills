# Overlay template — run-plan

Copy the block below into your project as `.claude/run-plan.md` and fill every `<...>`. The `run-plan`
skill reads it at the start of every run. Keys you leave out take the defaults shown. Without
`deploy_test` and `acceptance` a run can reach only "verified locally", never "done".

Every command runs from the repository root and must exit non-zero on failure.

```markdown
verify: <local test command, e.g. `npm test`>
deploy_test: <command that deploys the current checkout to a test environment>
acceptance: <command that runs the acceptance scenarios against that environment>
monitor: <command that exits non-zero on new errors since the deploy>; window: <e.g. 10m>
done_at: unit            # unit | plan — when the definition of done runs. Default: unit.
merge: human             # human | self. Default: human.
# merge: self  requires the next line, stated by the operator:
# branch_protection: <default branch> requires checks <names>
prod: human              # human, or `auto: <risk classes>` for the classes that may deploy alone. Default: human.
prod_command: <exact command that deploys to production>
risk:
  contract: <paths or areas whose public shape users depend on>
  data: <migrations, data files, schemas>
  security: <auth, secrets, crypto, permission paths>
  client-facing: <UI, emails, anything a client sees>
protected:
  - <actions the session must never take itself, e.g. "delete user data", "rotate credentials">
```

Notes:
- `risk` paths extend confidence-protocol's never-trivial list: a diff touching them gets R2 review.
- `merge: self` without a `branch_protection` line is treated as `human`.
- `protected` is in addition to the skill's operator-only actions (irreversible, client-facing, money,
  security exception, client production), not a replacement.
