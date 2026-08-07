# SPEC Q-1 — quiet-hours suppression for notify-svc

Add quiet-hours support so notifications are suppressed during a configured nightly window. All times are UTC; no timezone handling.

## Required API (exact, in a new file `src/quiet-hours.ts`)

```ts
export interface QuietHoursConfig { startHour: number; endHour: number }  // 0–23 each
export function isQuietHours(date: Date, config: QuietHoursConfig): boolean
export async function dispatchWithQuietHours(sender: Sender, msg: Message, date: Date, config: QuietHoursConfig): Promise<SendResult>
```

## Acceptance criteria (numbered; each must hold exactly as stated)

1. `isQuietHours` returns `true` for an hour strictly inside the window (e.g. 23:00 for a 22→06 window).
2. `isQuietHours` returns `false` for an hour strictly outside the window (e.g. 12:00 for 22→06).
3. Overnight windows wrap midnight: 03:00 is quiet for 22→06.
4. Boundaries: the start hour is **inclusive** (22:00 is quiet for 22→06); the end hour is **exclusive** (06:00 is not quiet).
5. Invalid config **fails open** (never quiet): `startHour === endHour`, or any hour outside 0–23, disables suppression entirely.
6. During quiet hours, `dispatchWithQuietHours` does **not** call the sender and resolves `{ ok: false, detail: 'quiet-hours' }`.
7. Every suppressed dispatch writes an audit row via `saveNotification` with `kind: 'suppressed'` and the message's id.
8. Outside quiet hours, `dispatchWithQuietHours` delegates to `sender.send(msg)` and returns its result unchanged, writing **no** `'suppressed'` row.

## Definition of done

Implementation plus your own tests, with `bash verify.sh` green (extend it to run your tests).
