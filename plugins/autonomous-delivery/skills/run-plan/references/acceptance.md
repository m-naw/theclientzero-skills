# Acceptance — run-plan checks and how to run them

The orchestrator, or a haiku subagent it sends, runs Part 2's steps; the orchestrator reads the
output and decides.

## Part 1 — author brief

Send this to a fresh subagent that implements no unit, with the spec path, the plan path, the overlay
path, and the branch to commit on.

You write the acceptance checks for this spec before anyone implements it. Nobody will answer
questions. Take what must be true from the spec, never from the code. Where the spec does not name
the place (path, field, command), take it from the plan: the plan decides, for example, that a new
response shape ships beside the old one.

1. List the spec's acceptance scenarios with their ids. If the spec names none, derive one scenario
   per behaviour the spec states, give each an id, and cite the spec line it comes from.
2. Write one check per scenario, named by its id, in the files the overlay's `acceptance` command
   runs. Each check prints its id and `pass` or `fail`. Without `deploy_test` and `acceptance` in the
   overlay, write them in a new directory with one runner command, and report that command; never in
   files that `verify` or a required check runs.
3. Write no check that can pass only if data is deleted, production is touched, money is spent or an
   existing contract (API shape, schema, CLI output) changes. Such a spec step is not a scenario and
   gets no id: report it as `operator-only, no check`. Where the spec changes a shape users depend
   on, check the new shape where the plan puts it, and add a `guard` check that the old shape still
   answers as on the base.
4. Run `deploy_test` on the base exactly as the overlay gives it, then the checks. Every new check
   must fail because the behaviour is absent, not because the check is broken. A `guard` check
   passes on the base. So does a scenario the base already satisfies (an input the base already
   rejects as the spec asks): keep it as a `guard` and say so. Never bend a check to force a failure.
5. If `deploy_test` fails, stop and report its output. Never retry it with other settings, free a
   resource another process holds, stop a process you did not start, or deploy anywhere else.
6. Commit only the checks. Do not touch application code, the overlay or the scripts it runs.

When you are sent to rewrite frozen checks after an operator answer, you get that answer and the
check ids it affects. Rewrite only those ids, take the new required behaviour from the answer, and
each must still fail on the base. Step 3 does not forbid what the answer explicitly approves. Leave
every other check byte-identical.

Report: the scenario ids with file and check name, the spec line each cites, which checks are
`guard`, each `operator-only, no check` step, the command you ran, and its red output.

## Freezing and re-freezing (orchestrator; not part of the author's brief)

When the author reports, confirm that its commit changes only check files
(`git diff --name-only <base> <checks commit>`). If it changes anything else, discard the commit and
send a fresh author. Then send the acceptance checks review (`references/reviewer.md`). For
`derivable` findings a fresh author fixes only the named ids, the checks run red on the base again,
and the reviewer runs once more (up to 2 rounds). A `preference` or a finding still disputed after
round 2 becomes a PROPOSED record under "Decided"; the review never blocks. Then record in `state.md` the base commit, the red output, each check file's
`git hash-object` and each id's owning unit. The checks are now frozen.

To re-freeze (Flow 3 says when): a fresh author subagent rewrites the named check ids and nothing
else. Each rewritten check must fail on the recorded base commit again, unless it is a `guard`.
Record the new hashes as a re-freeze and add a "Decided" row citing the spec line, the rail or the
operator answer.

## Part 2 — running a step

Give each step an explicit timeout and run long waits in the background. For each step, write the
exact command, its exit code and its full output to `.run-plan/evidence/<unit>-<step>.log`, and cite
that path beside the status. Run each command exactly as the overlay gives it. If one fails, report
its output and stop: never retry it with other settings, free a resource another process holds, stop a
process you were not told to stop, or deploy anywhere else.

Run the steps where the hash under test is checked out: the unit's worktree, or the main checkout at
`git checkout --detach <hash>` when the deploy needs files a fresh worktree lacks. First write
`git rev-parse HEAD` to the evidence log and recompute the frozen hashes there. Another hash than
the unit's head, or a changed frozen hash, is a failed step. The evidence directory lives in the
main checkout: a worktree has no `.run-plan/`.

0. One deploy at a time: run the overlay's `teardown`, or stop what this run's previous deploy
   started. Never stop a process the run did not start.
1. `deploy_test`. If it fails, stop here: `acceptance` against a stale or missing deploy proves nothing.
2. `acceptance`, against the environment `deploy_test` just produced.
3. `monitor`, for the overlay's window, starting after the deploy. New errors since the deploy fail it.

A step passed only when it ran, exited 0, and its output shows what it checked. "0 tests" or "no
scenarios" is a failure. One exception: `acceptance` may exit non-zero only because checks owned by
units that have not merged (later, skipped or **not done**) fail. Judge it by scenario id, and name
those ids.
