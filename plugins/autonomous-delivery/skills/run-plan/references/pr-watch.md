# PR watch — owning a unit's pull request until it merges

The orchestrator owns every unit PR until it is merged or ledgered, without spending its own context
on logs.

## Preflight: does a merge into the default branch deploy production?

Answer this before the first unit, and record the answer and its source in `state.md`.

- **Yes:** the overlay says `merge_deploys_prod: yes`; a workflow triggered by a push to the
  default branch deploys, releases or publishes; the default branch's commits carry deployment
  records or a deploy platform's status (`gh api repos/{owner}/{repo}/deployments`, the checks on
  its head); or the repository's documents say so.
- **No:** only from a source that pins it: the overlay says `merge_deploys_prod: no`; the
  repository's documents state how production is deployed and that a merge does not do it; or the
  remote is a local path, or there is none, so no platform is behind it.
- **Cannot be determined:** everything else, including "I looked and found nothing". Never find out
  by pushing.

On yes or cannot be determined, the run is `merge: human`: units merge into `run-plan/<plan-slug>`
and the one final PR is the operator's. Add a "Decided" row that says why, with the source, and
names the overlay line that would settle it.

## No pull-request tool

When pull requests cannot be opened (no `gh` or equivalent, or no hosted remote), the unit's branch
stands in for the PR, pushed when a remote exists, and `verify` on its head stands in for the
checks. The merge is a fast-forward of the local target to the verified hash
(`git merge --ff-only <hash>`), then pushed. One exception: a hosted remote's default branch is
never pushed this way. There the run is `merge: human`, the integration branch is pushed, and the
final pull request is a "Waiting on you" item with the exact command or URL.

## The unit's turn

The gates (review, checks, definition of done) and the merge run for one unit at a time, in
dependency order and otherwise in the order the implementers finish.

At the start of its turn, if the target moved since the unit branched (another unit merged, or
someone pushed), rebase the unit branch onto the target's tip in its worktree and resolve conflicts
there; a sonnet subagent resolves conflicts that need code changes. A commit the target already
holds (the checks commit, once a unit has merged) drops out of the rebase: that is expected. Push
the unit branch only (`git push --force-with-lease` on that branch, never on the target). The three
gates run on the rebased head, so the review also covers the conflict resolution.

If the target moves again during the turn (someone else pushed), rebase and run the three gates
again at the new head. A conflict that cannot be resolved without changing what another merged unit
delivered, or a third rebase in one turn, makes the unit **not done**. A conflict between units the
plan marked parallel-safe goes to `## Lessons`: that claim was wrong.

## Waiting for checks

Never poll in the orchestrator's own context. Wait with one cheap background mechanism: a haiku
subagent or a background command running `gh pr checks <n> --required --watch` (without `--required`
when the repository marks no check required). It reports only `pass` or `fail`, the head hash it
watched (`gh pr view <n> --json headRefOid`), and the names of the failing checks.

An empty answer is not a pass. Right after a push the checks are not registered yet: "no checks
reported" means wait and ask again, for up to 10 minutes. A result for another hash than the unit's
head is not a result. `verify` on the unit's head stands in for the checks only when nothing
reported after that wait and no pull request into this target has shown checks before (preflight
records whether they report on the default branch; record the first PR that shows them). Where
checks have reported before and none arrive now, the step did not run: it is a "Waiting on you" item
with a cause outside the code, and the unit is **not done**.

## Red check

1. Decide whose failure it is. A check that is also red on the target's current head, or fails in
   setup or infrastructure before any of the unit's code runs, has a cause outside the PR. Rerun it
   once unchanged (`gh run rerun <run-id> --failed`). If it is still red, it is a "Waiting on you"
   item with the check name and the log lines, and the unit is **not done**. Never "fix" it by
   weakening, skipping or deleting a test, or by editing CI configuration.
2. A failure caused by the PR goes to one sonnet subagent. Give it the PR number, its branch and
   worktree, the failing check names, and only the tail of the failing job's log
   (`gh run view <run-id> --log-failed | tail -n 150`), never the whole log. It fixes the code on the
   PR branch, runs `verify`, pushes, and reports the new head hash. It never edits frozen files or CI
   configuration, and never weakens, skips or deletes a test. If it finds that the cause is not the
   PR's code (a flaky test, the environment), it changes nothing and says so: then step 1 applies.
3. At most 2 fix attempts per PR. Then the unit is **not done**: ledger it with the failing check and
   the log tail, and continue with independent units.

A pushed fix is a new head: review, checks and the definition of done run again at that hash.

## Merge

Merge only when the review, the required checks and the definition of done all passed on the same
head hash, and pin that hash: `gh pr merge <n> --squash --match-head-commit <hash>` (the
repository's usual merge method when one is evident). Never use `--admin`, and never `--auto`: a
merge that waits on checks alone skips the definition of done. Never bypass branch protection, never
merge a PR whose checks are pending. Never auto-merge, and ledger instead, a PR that touches a path
on the overlay's `protected_paths`, whose diff takes an operator-only action that no operator answer
approves, or whose merge would deploy production on its own (preflight should have caught that).
Such a unit is held: its status stands, and its dependents are skipped.

After a merge: update the local target (`git fetch`, then `git merge --ff-only` where it is checked
out), remove the unit's worktree (`git worktree remove`), and update both `## Delivered` sections.

The progress line carries the PR's last state. In it `k` counts the units that have ended, whatever
their status, and `p` is `k/N`. Send no message per state change.
