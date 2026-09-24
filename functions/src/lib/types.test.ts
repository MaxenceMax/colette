import { describe, expect, it } from 'vitest';
import { DEFAULT_CARE_SETTINGS, withDefaults } from './types';

const daily = { timesPerDay: 1, everyDays: 1, enabled: true };

describe('withDefaults', () => {
  it('sans réglages : les valeurs par défaut du client', () => {
    expect(withDefaults(undefined)).toEqual(DEFAULT_CARE_SETTINGS);
    expect(withDefaults({})).toEqual(DEFAULT_CARE_SETTINGS);
    expect(DEFAULT_CARE_SETTINGS.umbilicalCare).toEqual({ timesPerDay: 3, everyDays: 1, enabled: true });
    expect(DEFAULT_CARE_SETTINGS.bath).toEqual({ timesPerDay: 1, everyDays: 2, enabled: true });
  });

  it('map de soin : bornes 1..10 et 1..30, enabled vrai par défaut', () => {
    const settings = withDefaults({
      adrigyl: { timesPerDay: 99 },
      bath: { everyDays: 60, enabled: 'oui' },
      eyeCare: { timesPerDay: 0, everyDays: -1 },
    } as never);
    expect(settings.adrigyl).toEqual({ timesPerDay: 10, everyDays: 1, enabled: true });
    expect(settings.bath).toEqual({ timesPerDay: 1, everyDays: 30, enabled: true });
    expect(settings.eyeCare).toEqual(daily);
  });

  it('map de soin : deux entiers > 1 → timesPerDay ramené à 1', () => {
    expect(withDefaults({ noseCare: { timesPerDay: 3, everyDays: 2 } }).noseCare).toEqual({
      timesPerDay: 1,
      everyDays: 2,
      enabled: true,
    });
  });

  it('map de soin : enabled faux conservé', () => {
    expect(withDefaults({ adrigyl: { everyDays: 3, enabled: false } }).adrigyl).toEqual({
      timesPerDay: 1,
      everyDays: 3,
      enabled: false,
    });
  });

  it('ancien entier xPerDay : n > 0 → n/jour, 0 → désactivé avec la fréquence par défaut', () => {
    const settings = withDefaults({ adrigylPerDay: 2, eyeCarePerDay: 0, noseCarePerDay: 99, umbilicalCarePerDay: 0 });
    expect(settings.adrigyl).toEqual({ timesPerDay: 2, everyDays: 1, enabled: true });
    expect(settings.eyeCare).toEqual({ ...daily, enabled: false });
    expect(settings.noseCare).toEqual({ timesPerDay: 10, everyDays: 1, enabled: true });
    expect(settings.umbilicalCare).toEqual({ timesPerDay: 3, everyDays: 1, enabled: false });
  });

  it('ancien entier non numérique, nul ou non fini : défaut', () => {
    expect(withDefaults({ adrigylPerDay: 'deux', bathEveryDays: null, umbilicalCarePerDay: Number.NaN } as never)).toEqual(
      DEFAULT_CARE_SETTINGS,
    );
  });

  it('ancien bathEveryDays : tous les n jours, borné 1..30', () => {
    expect(withDefaults({ bathEveryDays: 3 }).bath).toEqual({ timesPerDay: 1, everyDays: 3, enabled: true });
    expect(withDefaults({ bathEveryDays: 0 }).bath).toEqual(daily);
    expect(withDefaults({ bathEveryDays: 60 }).bath).toEqual({ timesPerDay: 1, everyDays: 30, enabled: true });
  });

  it("nombril : repli sur l'ancien booléen umbilicalCareEnabled", () => {
    expect(withDefaults({ umbilicalCareEnabled: false }).umbilicalCare).toEqual({
      timesPerDay: 3,
      everyDays: 1,
      enabled: false,
    });
    expect(withDefaults({ umbilicalCareEnabled: true }).umbilicalCare).toEqual(DEFAULT_CARE_SETTINGS.umbilicalCare);
    expect(withDefaults({ umbilicalCarePerDay: 0, umbilicalCareEnabled: true }).umbilicalCare.enabled).toBe(false);
    expect(
      withDefaults({ umbilicalCarePerDay: Number.NaN, umbilicalCareEnabled: false }).umbilicalCare.enabled,
    ).toBe(false);
  });

  it("la map de soin prime sur l'ancien entier", () => {
    expect(withDefaults({ adrigyl: { everyDays: 2 }, adrigylPerDay: 0 }).adrigyl).toEqual({
      timesPerDay: 1,
      everyDays: 2,
      enabled: true,
    });
  });

  it('feedsPerDay : borné 1..24, défaut 8', () => {
    expect(withDefaults({ feedsPerDay: 99 }).feedsPerDay).toBe(24);
    expect(withDefaults({ feedsPerDay: 0 }).feedsPerDay).toBe(1);
    expect(withDefaults({ feedsPerDay: Number.NaN }).feedsPerDay).toBe(8);
  });
});
