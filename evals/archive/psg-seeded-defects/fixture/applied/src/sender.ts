import type { Message, SendResult } from './message';

/**
 * Transport contract. `send` accepts ANY valid Message — including messages
 * with attachments — and must never throw for a valid Message; failures are
 * reported as `{ ok: false }`.
 */
export abstract class Sender {
  abstract send(msg: Message): Promise<SendResult>;
}
