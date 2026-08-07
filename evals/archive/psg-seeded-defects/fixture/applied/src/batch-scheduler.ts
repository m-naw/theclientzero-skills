/** Schedules notification batches for future delivery windows. */
export class BatchScheduler {
  private queue: { at: string; ids: string[] }[] = [];

  schedule(at: string, ids: string[]): void { this.queue.push({ at, ids }); }
  due(now: string): string[] { return this.queue.filter((b) => b.at <= now).flatMap((b) => b.ids); }
  clear(): void { this.queue = []; }
}
