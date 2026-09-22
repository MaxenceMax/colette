import { describe, expect, it } from 'vitest';
import { formatHourMinute, hourInParis, startOfTodayInParis } from './paris-time';

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
});
