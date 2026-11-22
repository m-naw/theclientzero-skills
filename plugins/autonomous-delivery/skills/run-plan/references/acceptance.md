# Acceptance — run-plan checks and how to run them

Part 1 is the brief for the acceptance author. Part 2 is how the orchestrator, or a haiku subagent it
sends, runs the steps of the definition of done; the orchestrator reads the output and decides.

## Part 1 — author brief

Send this to a fresh subagent that implements no unit, with the spec path, the plan path, the overlay
path, and the branch to commit on.

You write the acceptance checks for this spec before anyone implements it. Nobody will answer
questions. Write from the spec, not from the code or the plan's design: a check encodes what the spec
promises a user, never how the implementer will build it.

1. List the spec's acceptance scenarios with their ids. If the spec names none, derive one scenario
   per behaviour the spec states, give each an id, and cite the spec line it comes from.
2. Write one check per scenario, named by its id, in the files the overlay's `acceptance` command
   runs. Each check prints its id and `pass` or `fail`. Without `deploy_test` and `acceptance` in the
   overlay, write them as tests `verify` runs.
3. Run them against the base, deployed with `deploy_test`. Every new check must fail, and fail on the
   behaviour it checks, not on a typo or a missing import. A check that passes on the base checks
   nothing: rewrite it.
4. Commit only the checks. Do not touch application code, the overlay or the scripts it runs.

Report: the scenario ids with file and check name, the spec line each cites, the command you ran, and
its red output.

## Part 2 — running a step

Give each step an explicit timeout and run long waits in the background. For each step, write the
exact command, its exit code and its full output to `.run-plan/evidence/<unit>-<step>.log`, and cite
that path beside the status.

1. `deploy_test`. If it fails, stop here: `acceptance` against a stale or missing deploy proves nothing.
2. `acceptance`, against the environment `deploy_test` just produced.
3. `monitor`, for the overlay's window, starting after the deploy. New errors since the deploy fail it.

A step passed only when it ran, exited 0, and its output shows what it checked. "0 tests" or "no
scenarios" is a failure.
