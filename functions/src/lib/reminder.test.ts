import { describe, expect, it } from 'vitest';
import { isReminderDue, REMINDER_LEAD_MS } from './reminder';

describe('isReminderDue', () => {
  const next = new Date('2026-09-21T12:30:00Z');

  it('pas encore dans la fenêtre de 10 min', () => {
    expect(isReminderDue({ nextBottleAt: next, lastNotifiedFor: null, now: new Date('2026-09-21T12:15:00Z') })).toBe(
      false,
    );
  });

  it('dû dès 10 min avant', () => {
    expect(
      isReminderDue({ nextBottleAt: next, lastNotifiedFor: null, now: new Date(next.getTime() - REMINDER_LEAD_MS) }),
    ).toBe(true);
  });

  it('jamais deux fois pour la même échéance', () => {
    expect(isReminderDue({ nextBottleAt: next, lastNotifiedFor: next, now: new Date('2026-09-21T12:25:00Z') })).toBe(
      false,
    );
  });
});
