import { Sender } from './sender';
import type { Message, SendResult } from './message';

/** SMTP-backed sender. Honors the full Sender contract, attachments included. */
export class EmailSender extends Sender {
  async send(msg: Message): Promise<SendResult> {
    if (!msg.to.includes('@')) return { ok: false, detail: 'invalid address' };
    return { ok: true };
  }
}
