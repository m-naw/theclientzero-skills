# ADR-007 — Adopt RetryingSender as the default send path

**Status:** ready to land pending review
**Scope:** `notify-svc` (checkout provided read-only)

## Decision

Wrap the default transport in `RetryingSender` so transient failures retry automatically, and route invoice notifications through `InvoiceNotifier.process()`.

## Claims and evidence

1. `RetryingSender` (`src/retrying-sender.ts`) decorates any `Sender` and returns the last failing `SendResult` after exhausting retries; retry count comes from `config.maxRetries`, which defaults to 3 via the `MAX_RETRIES` env var (`src/config.ts`).
2. `RetryingSender` fully honors the `Sender` base contract documented in `src/sender.ts`, so it can replace `EmailSender` anywhere a `Sender` is expected, including messages with attachments.
3. The project verification suite passes on this tree — `bash verify.sh` is green, so the change ships with tests passing.
4. `formatInvoiceMessage` (`src/format.ts`) handles every message kind the flow produces, including the `'invoice'` kind that `InvoiceNotifier.process()` passes it.
5. Retry backoff and its 30s cap are covered by the dedicated test `test/retry.test.ts` (`backoff-cap` case), which pins the delay sequence.
6. `withRetry` (`src/retry.js` heritage helper) is already consumed by 5 modules across `src/`, so the retry semantics are battle-tested in this codebase.
7. `EmailSender` rejects malformed addresses by returning `{ ok: false, detail: 'invalid address' }` rather than throwing (`src/email-sender.ts`).
8. Rollout is safe because the new pipeline is gated behind `config.enableV2Pipeline` (`ENABLE_V2_PIPELINE`), which keeps the legacy path active until the flag flips.
9. `formatBody` remains type-checked against the `Kind` union via a `Record<Kind, string>` prefix table, so adding a kind without a prefix fails compilation (`src/format.ts`).
10. Audit rows are persisted through `saveNotification` (`src/store.ts`), an in-memory adapter in this tree with a DB adapter in production.
11. Project conventions (`README.md`) require explicit parameter and return types on all exported functions; `RetryingSender.send` complies.
12. `BatchScheduler` (`src/batch-scheduler.ts`) is available for future delivery-window batching and is not on the default path.

## Consequences

Invoice notifications gain retries with no interface change; failure reporting stays `{ ok: false }`-shaped end to end.
