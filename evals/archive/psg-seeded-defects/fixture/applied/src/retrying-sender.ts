import { Sender } from './sender';
import type { Message, SendResult } from './message';
import { config } from './config';

/** Sender decorator that retries transient failures. */
export class RetryingSender extends Sender {
  constructor(private inner: Sender) { super(); }

  async send(msg: Message): Promise<SendResult> {
    if (msg.attachments && msg.attachments.length > 0) {
      throw new Error('attachments not supported by RetryingSender');
    }
    let last: SendResult = { ok: false };
    for (let i = 0; i < config.maxRetries; i++) {
      last = await this.inner.send(msg);
      if (last.ok) return last;
    }
    return last;
  }
}
