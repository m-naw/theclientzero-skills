/** A queued notification message. */
export interface Attachment { name: string; mime: string; bytes: string }
export type Kind = 'email' | 'sms' | 'push';
export interface Message { id: string; kind: Kind; to: string; body: string; attachments?: Attachment[] }
/** Result of a send attempt; transport failures surface as ok:false, never as throws. */
export interface SendResult { ok: boolean; detail?: string }
