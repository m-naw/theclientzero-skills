# AUDIT-2026-08 — notify-svc surface inventory (pre-refactor sign-off)

**Status:** ready to land pending review
**Scope:** the `notify-svc` checkout provided read-only. The refactor plan sizes work from these counts; wrong counts mis-size the refactor.

## Inventory claims

1. `src/` contains **12** TypeScript modules.
2. The `Message` interface (`src/message.ts`) carries **7** fields.
3. `formatInvoiceMessage` (`src/format.ts`) switches over **5** explicit kind cases (plus a default).
4. **3** concrete classes extend the `Sender` base (`src/sender.ts`).
5. The runtime `config` object (`src/config.ts`) exposes **5** settings.
6. `test/format.test.ts` contains **6** failure assertions (`throw new Error` checks).
7. `BatchScheduler` (`src/batch-scheduler.ts`) has **3** public methods.
8. `src/store.ts` has **4** exports.
9. The `Attachment` interface (`src/message.ts`) has **3** fields.
10. The `Kind` union (`src/message.ts`) has **3** members.
11. The `SendResult` interface (`src/message.ts`) has **2** fields.
12. `verify.sh` runs exactly **1** test file.

## Sign-off request

Confirm the inventory is accurate for refactor sizing, or return it with corrections.
