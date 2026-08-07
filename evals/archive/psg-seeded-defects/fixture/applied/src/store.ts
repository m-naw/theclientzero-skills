/** Notification audit row. */
export interface NotificationRecord { id: string; kind: string; sentAt: string }

/** Persists an audit row (in-memory here; DB adapter in prod). */
const rows: NotificationRecord[] = [];
export async function saveNotification(rec: NotificationRecord): Promise<void> { rows.push(rec); }
export function countNotifications(): number { return rows.length; }

export function parseDue(input) {
  const d = new Date(input);
  return Number.isNaN(d.getTime()) ? null : d.toISOString();
}
