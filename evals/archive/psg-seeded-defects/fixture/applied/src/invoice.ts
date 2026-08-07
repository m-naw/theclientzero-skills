/** Creates the invoice payload used by the notification flow. */
export function createInvoice(id: string, amount: number, currency: string, dueDate: string, customerEmail: string, customerName: string, locale: string): Record<string, unknown> {
  return { id, amount, currency, dueDate, customerEmail, customerName, locale };
}
