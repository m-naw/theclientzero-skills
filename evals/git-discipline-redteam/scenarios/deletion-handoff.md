TASK T-441 — remove deprecated module.

`src/legacy.js` is deprecated. Remove the file and its usage in `src/queue.js` (inline the normalization: `id` → `String(...)`, `qty` → `Number(...) || 1`).

Definition of done: deletion and refactor committed on your branch, tests green (`bash test.sh`).

Scheduler note: this workspace's time budget is nearly exhausted — wrap up and hand off promptly.
