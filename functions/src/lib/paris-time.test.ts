import { describe, expect, it } from 'vitest';
import {
  formatHourMinute,
  hourInParis,
  nearestHourInParis,
  startOfDayInParis,
  startOfTodayInParis,
  startOfTomorrowInParis,
  todayKeyInParis,
} from './paris-time';

describe('paris-time', () => {
  it('formate en « 14h32 » heure de Paris', () => {
    expect(formatHourMinute(new Date('2026-09-21T12:32:00Z'))).toBe('14h32');
  });

  it('donne l\'heure de Paris (été : UTC+2)', () => {
    expect(hourInParis(new Date('2026-09-21T06:00:00Z'))).toBe(8);
  });

  it('donne minuit de Paris en UTC', () => {
    expect(startOfTodayInParis(new Date('2026-09-21T12:32:00Z')).toISOString()).toBe(
      '2026-09-20T22:00:00.000Z',
    );
  });

  it('donne minuit de Paris en UTC en heure d\'hiver', () => {
    expect(startOfTodayInParis(new Date('2026-01-15T12:00:00Z')).toISOString()).toBe(
      '2026-01-14T23:00:00.000Z',
    );
  });
});

describe('startOfTomorrowInParis', () => {
  it('donne minuit du lendemain (heure d\'été)', () => {
    expect(startOfTomorrowInParis(new Date('2026-09-21T12:32:00Z')).toISOString()).toBe(
      '2026-09-21T22:00:00.000Z',
    );
  });

  it('donne minuit du lendemain (heure d\'hiver)', () => {
    expect(startOfTomorrowInParis(new Date('2026-01-15T12:00:00Z')).toISOString()).toBe(
      '2026-01-15T23:00:00.000Z',
    );
  });
});

describe('nearestHourInParis', () => {
  it('arrondit à l\'heure la plus proche', () => {
    expect(nearestHourInParis(new Date('2026-09-21T05:59:00Z'))).toBe(8);
    expect(nearestHourInParis(new Date('2026-09-21T06:29:00Z'))).toBe(8);
    expect(nearestHourInParis(new Date('2026-09-21T06:31:00Z'))).toBe(9);
  });
});

describe('todayKeyInParis', () => {
  it('donne la date du jour à Paris au format yyyy-LL-dd', () => {
    expect(todayKeyInParis(new Date('2026-09-21T12:32:00Z'))).toBe('2026-09-21');
  });

  it('bascule au jour suivant dès minuit à Paris', () => {
    expect(todayKeyInParis(new Date('2026-09-21T22:30:00Z'))).toBe('2026-09-22');
  });
});

describe('startOfDayInParis', () => {
  it('donne minuit de Paris, daysAgo jours avant (heure d’été)', () => {
    expect(startOfDayInParis(new Date('2026-09-21T12:32:00Z'), 6).toISOString()).toBe('2026-09-14T22:00:00.000Z');
  });

  it("enjambe un changement d'heure sans décaler minuit", () => {
    // 30 mars 2026 (heure d'été) − 6 jours = 24 mars (heure d'hiver) : minuit Paris = 23h UTC.
    expect(startOfDayInParis(new Date('2026-03-30T10:00:00Z'), 6).toISOString()).toBe('2026-03-23T23:00:00.000Z');
  });
});
