import { describe, expect, it } from 'vitest';
import { DEFAULT_CARE_SETTINGS, withDefaults } from './types';

describe('withDefaults', () => {
  it('sans réglages : les valeurs par défaut du client', () => {
    expect(withDefaults(undefined)).toEqual(DEFAULT_CARE_SETTINGS);
    expect(withDefaults({})).toEqual(DEFAULT_CARE_SETTINGS);
  });

  it('valeurs nulles ou absentes : repli sur les valeurs par défaut', () => {
    const settings = withDefaults({
      adrigylPerDay: null,
      eyeCarePerDay: undefined,
      noseCarePerDay: null,
      bathEveryDays: null,
      feedsPerDay: undefined,
      umbilicalCarePerDay: null,
    } as never);

    expect(settings).toEqual(DEFAULT_CARE_SETTINGS);
  });

  it('valeurs hors bornes : ramenées dans les bornes du client', () => {
    expect(
      withDefaults({
        adrigylPerDay: 42,
        eyeCarePerDay: -3,
        noseCarePerDay: 10,
        bathEveryDays: 0,
        feedsPerDay: 99,
      }),
    ).toEqual({
      adrigylPerDay: 10,
      eyeCarePerDay: 0,
      noseCarePerDay: 10,
      bathEveryDays: 1,
      feedsPerDay: 24,
      umbilicalCarePerDay: 3,
    });

    expect(withDefaults({ bathEveryDays: 60, feedsPerDay: 0 })).toMatchObject({
      bathEveryDays: 30,
      feedsPerDay: 1,
    });
  });

  it('valeurs normales : conservées telles quelles', () => {
    expect(
      withDefaults({
        adrigylPerDay: 2,
        eyeCarePerDay: 0,
        noseCarePerDay: 3,
        bathEveryDays: 7,
        feedsPerDay: 6,
        umbilicalCarePerDay: 2,
      }),
    ).toEqual({
      adrigylPerDay: 2,
      eyeCarePerDay: 0,
      noseCarePerDay: 3,
      bathEveryDays: 7,
      feedsPerDay: 6,
      umbilicalCarePerDay: 2,
    });
  });

  it('valeurs non numériques : repli sur les valeurs par défaut', () => {
    expect(withDefaults({ adrigylPerDay: 'deux', feedsPerDay: Number.NaN } as never)).toMatchObject({
      adrigylPerDay: 1,
      feedsPerDay: 8,
    });
  });

  it("nombril : repli sur l'ancien booléen umbilicalCareEnabled", () => {
    expect(withDefaults({ umbilicalCareEnabled: false }).umbilicalCarePerDay).toBe(0);
    expect(withDefaults({ umbilicalCareEnabled: true }).umbilicalCarePerDay).toBe(3);
    expect(withDefaults({ umbilicalCarePerDay: 0, umbilicalCareEnabled: true }).umbilicalCarePerDay).toBe(0);
    expect(withDefaults({ umbilicalCarePerDay: 42 }).umbilicalCarePerDay).toBe(10);
    expect(withDefaults({ umbilicalCarePerDay: Number.NaN }).umbilicalCarePerDay).toBe(3);
  });
});
