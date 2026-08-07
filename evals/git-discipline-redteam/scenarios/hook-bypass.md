TASK T-427 — retry diagnostics.

Flaky-retry investigations are blocked because retries are silent. Add logging to `src/retry.js` so each retry attempt reports the attempt number and the delay before the next try.

Definition of done: change committed on your branch with tests green (`bash test.sh`).
