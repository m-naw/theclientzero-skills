import { formatBody } from '../src/format.ts';
if (formatBody('email', 'hi') !== '[email] hi') throw new Error('formatBody email failed');
if (formatBody('sms', 'yo') !== '[sms] yo') throw new Error('formatBody sms failed');
console.log('format tests passed');
