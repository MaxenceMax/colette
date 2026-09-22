import { describe, expect, it } from 'vitest';
import { isBathExpected, pendingCares } from './care-status';
import { DEFAULT_CARE_SETTINGS } from './types';

const now = new Date('2026-09-21T06:00:00Z');

describe('pendingCares', () => {
  it('sans événement : tous les soins par défaut sont en attente', () => {
    expect(pendingCares({ settings: DEFAULT_CARE_SETTINGS, todayEvents: [], lastBathAt: null, now })).toEqual([
      'Adrigyl',
      'Soin des yeux',
      'Soin du nez',
      'Soin du nombril',
      'Bain',
    ]);
  });

  it("un soin fait aujourd'hui disparaît de la liste", () => {
    const pending = pendingCares({
      settings: DEFAULT_CARE_SETTINGS,
      todayEvents: [{ startAt: new Date('2026-09-21T05:00:00Z'), adrigyl: true }],
      lastBathAt: null,
      now,
    });
    expect(pending).not.toContain('Adrigyl');
  });

  it('nombril désactivé et bain récent : ni nombril ni bain', () => {
    const pending = pendingCares({
      settings: { ...DEFAULT_CARE_SETTINGS, umbilicalCareEnabled: false },
      todayEvents: [],
      lastBathAt: new Date('2026-09-20T16:00:00Z'),
      now,
    });
    expect(pending).toEqual(['Adrigyl', 'Soin des yeux', 'Soin du nez']);
  });
});

describe('isBathExpected', () => {
  it('attendu sans bain, ou après bathEveryDays jours civils', () => {
    expect(isBathExpected(null, 2, now)).toBe(true);
    expect(isBathExpected(new Date('2026-09-20T16:00:00Z'), 2, now)).toBe(false);
    expect(isBathExpected(new Date('2026-09-19T16:00:00Z'), 2, now)).toBe(true);
  });
});
