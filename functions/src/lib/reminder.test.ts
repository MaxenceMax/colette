import { describe, expect, it } from 'vitest';
import { isReminderDue, REMINDER_LEAD_MS, REMINDER_TOLERANCE_MS } from './reminder';

describe('isReminderDue', () => {
  const next = new Date('2026-09-21T12:30:00Z');
  const computedAt = new Date('2026-09-21T09:30:00Z');

  it('pas encore dans la fenêtre de 10 min', () => {
    expect(
      isReminderDue({ nextBottleAt: next, computedAt, lastNotifiedFor: null, now: new Date('2026-09-21T12:15:00Z') }),
    ).toBe(false);
  });

  it('dû dès 10 min avant', () => {
    expect(
      isReminderDue({
        nextBottleAt: next,
        computedAt,
        lastNotifiedFor: null,
        now: new Date(next.getTime() - REMINDER_LEAD_MS),
      }),
    ).toBe(true);
  });

  it('jamais deux fois pour la même échéance', () => {
    expect(
      isReminderDue({ nextBottleAt: next, computedAt, lastNotifiedFor: next, now: new Date('2026-09-21T12:25:00Z') }),
    ).toBe(false);
  });

  it('plan calculé à son échéance (aucun biberon enregistré) : rien à rappeler', () => {
    expect(
      isReminderDue({ nextBottleAt: next, computedAt: next, lastNotifiedFor: null, now: new Date(next) }),
    ).toBe(false);
  });

  it('plan calculé après son échéance (dernier biberon trop ancien) : rien à rappeler', () => {
    expect(
      isReminderDue({
        nextBottleAt: next,
        computedAt: new Date(next.getTime() + 60 * 1000),
        lastNotifiedFor: null,
        now: new Date(next.getTime() + 60 * 1000),
      }),
    ).toBe(false);
  });

  it('plus rien au-delà de la tolérance de 15 min', () => {
    expect(
      isReminderDue({
        nextBottleAt: next,
        computedAt,
        lastNotifiedFor: null,
        now: new Date(next.getTime() + 20 * 60 * 1000),
      }),
    ).toBe(false);
    expect(REMINDER_TOLERANCE_MS).toBe(15 * 60 * 1000);
  });

  it('encore dû 14 min après l’échéance', () => {
    expect(
      isReminderDue({
        nextBottleAt: next,
        computedAt,
        lastNotifiedFor: null,
        now: new Date(next.getTime() + 14 * 60 * 1000),
      }),
    ).toBe(true);
  });

  it('sans computedAt, la fenêtre seule décide', () => {
    expect(
      isReminderDue({
        nextBottleAt: next,
        computedAt: null,
        lastNotifiedFor: null,
        now: new Date('2026-09-21T12:15:00Z'),
      }),
    ).toBe(false);
    expect(
      isReminderDue({ nextBottleAt: next, computedAt: null, lastNotifiedFor: null, now: new Date(next) }),
    ).toBe(true);
  });
});
