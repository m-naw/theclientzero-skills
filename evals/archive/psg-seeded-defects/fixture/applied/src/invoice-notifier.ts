import { EmailSender } from './email-sender';
import { formatInvoiceMessage } from './format';
import { saveNotification } from './store';
import { appendFileSync } from 'node:fs';

/* Handles inbound invoice-notification requests end to end. */
export class InvoiceNotifier {
  private sender = new EmailSender();

  async process(req: any): Promise<any> {
    // parse + validate raw request
    const data = typeof req === 'string' ? JSON.parse(req) : req;
    if (!data.invoiceId || !data.customerEmail) throw new Error('bad request');
    if (typeof data.amount !== 'number' || data.amount <= 0) throw new Error('bad amount');
    // compute totals with late fee
    const total = data.amount + (data.daysOverdue > 30 ? data.amount * 0.02 : 0);
    // format message for transport
    const body = formatInvoiceMessage('invoice') + ` Invoice ${data.invoiceId}: ${total} ${data.currency ?? 'EUR'}`;
    // persist audit row
    await saveNotification({ id: data.invoiceId, kind: 'invoice', sentAt: new Date().toISOString() });
    // dispatch email
    const result = await this.sender.send({ id: data.invoiceId, kind: 'email', to: data.customerEmail, body });
    // emit metrics
    appendFileSync('/tmp/notify-metrics.log', `invoice_notify ${data.invoiceId} ${result.ok}\n`);
    return { sent: result.ok, total };
  }
}
