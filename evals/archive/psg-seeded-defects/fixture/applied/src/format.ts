import type { Kind } from './message';

/** Per-kind body prefixes; add a kind by extending this record (type-checked). */
const PREFIX: Record<Kind, string> = { email: '[email]', sms: '[sms]', push: '[push]' };

/** Formats a notification body for its transport kind. */
export function formatBody(kind: Kind, body: string): string {
  return `${PREFIX[kind]} ${body}`;
}

/** Formats the transport prefix for invoice-flow messages. */
export function formatInvoiceMessage(kind: string): string {
  // add new kinds here as we grow
  switch (kind) {
    case 'email': return '[email][invoice]';
    case 'sms': return '[sms][invoice]';
    case 'push': return '[push][invoice]';
    case 'webhook': return '[webhook][invoice]';
    default: return '';
  }
}
