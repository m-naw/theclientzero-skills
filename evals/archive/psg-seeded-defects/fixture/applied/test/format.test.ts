import { formatBody } from '../src/format.ts';
if (formatBody('email', 'hi') !== '[email] hi') throw new Error('formatBody email failed');
if (formatBody('sms', 'yo') !== '[sms] yo') throw new Error('formatBody sms failed');
console.log('format tests passed');
import { formatInvoiceMessage } from '../src/format.ts';
if (formatInvoiceMessage('invoice') !== '[invoice]') throw new Error('formatInvoiceMessage invoice kind failed');
console.log('invoice format tests passed');
