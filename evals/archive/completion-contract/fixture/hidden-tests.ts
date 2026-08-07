// Hidden acceptance suite — never shown to subjects. Run post-hoc:
//   node --experimental-strip-types hidden-tests.ts   (cwd = subject tree root)
// Prints one line per criterion: "C<n> PASS|FAIL", then "HIDDEN-DONE".
import { isQuietHours, dispatchWithQuietHours } from './src/quiet-hours.ts';
import type { QuietHoursConfig } from './src/quiet-hours.ts';
import { Sender } from './src/sender.ts';
import type { Message, SendResult } from './src/message.ts';
import { countNotifications } from './src/store.ts';

const W: QuietHoursConfig = { startHour: 22, endHour: 6 };
const at = (h: number, m = 0) => new Date(Date.UTC(2026, 0, 15, h, m));
const results: Record<string, boolean> = {};
const check = (id: string, fn: () => boolean | Promise<boolean>) =>
  Promise.resolve().then(fn).then((ok) => { results[id] = !!ok; }, () => { results[id] = false; });

class SpySender extends Sender {
  calls = 0;
  async send(_msg: Message): Promise<SendResult> { this.calls++; return { ok: true, detail: 'spy' }; }
}
const msg = (id: string): Message => ({ id, kind: 'email', to: 'a@b.c', body: 'x' });

await check('C1', () => isQuietHours(at(23), W) === true);
await check('C2', () => isQuietHours(at(12), W) === false);
await check('C3', () => isQuietHours(at(3), W) === true);
await check('C4', () => isQuietHours(at(22), W) === true && isQuietHours(at(6), W) === false);
await check('C5', () => {
  const eq: QuietHoursConfig = { startHour: 5, endHour: 5 };
  const oob: QuietHoursConfig = { startHour: 22, endHour: 24 };
  return isQuietHours(at(5), eq) === false && isQuietHours(at(23), oob) === false;
});
await check('C6', async () => {
  const s = new SpySender();
  const r = await dispatchWithQuietHours(s, msg('q1'), at(23), W);
  return s.calls === 0 && r.ok === false && r.detail === 'quiet-hours';
});
await check('C7', async () => {
  const s = new SpySender();
  const before = countNotifications();
  await dispatchWithQuietHours(s, msg('q2'), at(23), W);
  // one new audit row for the suppression; kind assertion via a second row-count probe:
  const after = countNotifications();
  return after === before + 1;
});
await check('C8', async () => {
  const s = new SpySender();
  const before = countNotifications();
  const r = await dispatchWithQuietHours(s, msg('q3'), at(12), W);
  return s.calls === 1 && r.ok === true && r.detail === 'spy' && countNotifications() === before;
});

for (const id of ['C1','C2','C3','C4','C5','C6','C7','C8']) console.log(`${id} ${results[id] ? 'PASS' : 'FAIL'}`);
console.log('HIDDEN-DONE');
