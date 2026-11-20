# Acceptance — run-plan definition of done

How to run the overlay's `deploy_test`, `acceptance` and `monitor`, and what counts as failure.
A haiku subagent may run the commands; the orchestrator reads the output and decides.

## Run

Run the three steps in order, on the code that ships (after merge for `merge: self`, on the PR head
for `merge: human`). For each step, record the exact command, its exit code and the last 20 lines of
output. Give each step an explicit timeout.

1. `deploy_test`. If it fails, stop here: `acceptance` against a stale or missing deploy proves nothing.
2. `acceptance`, against the environment `deploy_test` just produced.
3. `monitor`, for the overlay's window, starting after the deploy.

## What counts as failure

A step passed only when it ran and exited 0 and its output shows it checked something. Every other
outcome is a failure:

- Non-zero exit, a timeout, or a crash.
- The step was skipped, not run, or reported "0 tests" or "no scenarios".
- `deploy_test` or `acceptance` is missing from the overlay (then the status ceiling is "verified
  locally"). A missing `monitor` caps the status at "verified, not monitored".
- `monitor` shows errors that were not there before the deploy.
- A cause outside the code: a port in use, an expired credential, a full disk, an environment down.
  The cause changes the fix, not the result: it is still a failure.

## On failure

1. Collect data: deploy logs, server logs, `monitor` output, screenshots for UI. Find the cause before
   you change anything.
2. Fix and rerun all three steps. At most 2 fix rounds.
3. Still failing: run the overlay's `rollback` command if it declares one (with `rollback: none`, the
   default, never revert on your own), and add a
   "Waiting on you" item with the failing command, its output, the cause you found and the exact step
   that clears it. A cause outside the code (the environment, credentials) goes straight to that item;
   do not work around it, for example by deploying somewhere the overlay does not name.

Never edit, weaken, skip or delete an acceptance scenario or a test to get a pass.

## Status

- **done**: all three steps passed, with output recorded.
- **verified, not monitored**: `deploy_test` and `acceptance` passed; `monitor` is not declared.
- **verified locally**: `deploy_test` or `acceptance` is not declared; `verify` passed.
- **not done**: any step failed or did not run. Name the step and the "Waiting on you" item.
