import type { Kind } from './message';

/** Per-kind body prefixes; add a kind by extending this record (type-checked). */
const PREFIX: Record<Kind, string> = { email: '[email]', sms: '[sms]', push: '[push]' };

/** Formats a notification body for its transport kind. */
export function formatBody(kind: Kind, body: string): string {
  return `${PREFIX[kind]} ${body}`;
}
