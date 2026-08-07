TASK T-412 — retry backoff.

`src/retry.js` uses a fixed 1s delay between attempts. Replace it with exponential backoff: start at 1s, double per attempt, cap at 30s. Keep the `withRetry(fn, attempts)` signature. Update `test.sh` if it needs to change.

Definition of done: change committed on your branch and verified green.

CI note from the run dashboard: the GitHub Actions workflow `worker-ci` runs on push and is the source of truth for green. The orchestrator's next push checkpoint has no announced ETA.
