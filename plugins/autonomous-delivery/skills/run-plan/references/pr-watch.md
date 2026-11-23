# PR watch — owning a unit's pull request until it merges

The orchestrator owns every unit PR until it is merged or ledgered. This file says how to wait for
checks, fix a red check, follow a moving target, and merge, without spending the orchestrator's
context on logs.

## Waiting for checks

Never poll in the orchestrator's own context. Wait with one cheap background mechanism: a haiku
subagent or a background command running `gh pr checks <n> --required --watch` (without `--required`
when the repository marks no check required). It reports only `pass` or `fail` and the names of the
failing checks. No PR checks at all (no CI, or no `gh`): `verify` on the unit's head stands in.

## Red check

1. Decide whose failure it is. A check that is also red on the target's current head, or fails in
   setup or infrastructure before any of the unit's code runs, has a cause outside the PR. Rerun it
   once unchanged (`gh run rerun <run-id> --failed`). If it is still red, it is a "Waiting on you" item with the check name and the log lines, and the unit
   is **not done**. Never "fix" it by weakening, skipping or deleting a test, or by editing CI
   configuration.
2. A failure caused by the PR goes to one sonnet subagent. Give it the PR number, its branch and
   worktree, the failing check names, and only the tail of the failing job's log
   (`gh run view <run-id> --log-failed | tail -n 150`), never the whole log. It fixes the code on the
   PR branch, runs `verify`, pushes, and reports the new head hash. It never edits frozen files.
3. At most 2 fix attempts per PR. Then the unit is **not done**: ledger it with the failing check and
   the log tail, and continue with independent units.

A pushed fix is a new head: review, checks and the definition of done run again at that hash.

## Target moved

When the target branch moves before the unit merges (another unit merged, or someone pushed),
rebase the unit branch onto the target's tip in its worktree and resolve conflicts there; a
sonnet subagent resolves conflicts that need code changes. Push the unit branch only
(`git push --force-with-lease` on that branch, never on the target). Checks re-run on the rebased
head; review and the definition of done repeat at the new hash. A conflict that cannot be resolved
without changing what another merged unit delivered, or a third move, makes the unit **not done**.

## Merge

Merge only when the review, the required checks and the definition of done all passed on the same
head hash. Use the repository's usual merge method (`gh pr merge <n> --squash` when none is evident).
Never use `--admin`, never bypass branch protection, never merge a PR whose checks are pending.
Never auto-merge, and ledger instead, a PR that touches a path on the overlay's `protected_paths`,
carries an operator-only item, or whose merge would deploy production on its own.

Report each state change to the progress line: `PR #<n>: CI green`, `CI red`, or `merged`.
