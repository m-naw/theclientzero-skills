# Acceptance — run-plan checks and how to run them

Part 1 is the brief for the acceptance author. Part 2 is how the orchestrator, or a haiku subagent it
sends, runs the steps of the definition of done; the orchestrator reads the output and decides.

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
   must fail because the behaviour is absent (a 404, a missing field), not because the check is
   broken (a typo, a wrong path). A `guard` check passes on the base. So does a scenario the base
   already satisfies (an unknown id already answers 404): keep it as a `guard` and say so. Never bend
   a check to force a failure.
5. If `deploy_test` fails, stop and report its output. Never retry it with other settings, free a
   port, stop a process you did not start, or deploy anywhere else.
6. Commit only the checks. Do not touch application code, the overlay or the scripts it runs.

Report: the scenario ids with file and check name, the spec line each cites, which checks are
`guard`, each `operator-only, no check` step, the command you ran, and its red output.

## Part 2 — running a step

Give each step an explicit timeout and run long waits in the background. For each step, write the
exact command, its exit code and its full output to `.run-plan/evidence/<unit>-<step>.log`, and cite
that path beside the status. Run each command exactly as the overlay gives it. If one fails, report
its output and stop: never retry it with other settings, free a port, stop a process you were not
told to stop, or deploy anywhere else.

1. `deploy_test`. If it fails, stop here: `acceptance` against a stale or missing deploy proves nothing.
2. `acceptance`, against the environment `deploy_test` just produced.
3. `monitor`, for the overlay's window, starting after the deploy. New errors since the deploy fail it.

A step passed only when it ran, exited 0, and its output shows what it checked. "0 tests" or "no
scenarios" is a failure. One exception: before the last unit, `acceptance` may exit non-zero only
because checks owned by later units fail. Judge it by scenario id, and name those ids.
