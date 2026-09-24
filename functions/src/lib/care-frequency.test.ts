import { describe, expect, it } from 'vitest';
import { CARE_WINDOW_DAYS, isExpected } from './care-frequency';

const now = new Date('2026-09-21T12:00:00Z'); // 14h à Paris
const daily = { timesPerDay: 1, everyDays: 1, enabled: true };
const everyTwoDays = { timesPerDay: 1, everyDays: 2, enabled: true };

describe('isExpected', () => {
  it('désactivé : jamais attendu', () => {
    expect(isExpected({ ...daily, enabled: false }, null, now)).toBe(false);
  });

  it("quotidien : toujours attendu, même fait aujourd'hui", () => {
    expect(isExpected(daily, null, now)).toBe(true);
    expect(isExpected(daily, new Date('2026-09-21T06:00:00Z'), now)).toBe(true);
  });

  it('tous les 2 jours : attendu sans historique ou après 2 jours civils', () => {
    expect(isExpected(everyTwoDays, null, now)).toBe(true);
    expect(isExpected(everyTwoDays, new Date('2026-09-20T16:00:00Z'), now)).toBe(false);
    expect(isExpected(everyTwoDays, new Date('2026-09-19T16:00:00Z'), now)).toBe(true);
  });

  it('jours civils de Paris : 23h30 UTC la veille est déjà « hier »', () => {
    // 2026-09-19T23:30Z = 20 septembre 01h30 à Paris → un seul jour civil avant le 21.
    expect(isExpected(everyTwoDays, new Date('2026-09-19T23:30:00Z'), now)).toBe(false);
  });

  it('la fenêtre couvre 7 jours', () => {
    expect(CARE_WINDOW_DAYS).toBe(7);
  });
});
