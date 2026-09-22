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
      umbilicalCareEnabled: null,
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
      umbilicalCareEnabled: true,
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
        umbilicalCareEnabled: false,
      }),
    ).toEqual({
      adrigylPerDay: 2,
      eyeCarePerDay: 0,
      noseCarePerDay: 3,
      bathEveryDays: 7,
      feedsPerDay: 6,
      umbilicalCareEnabled: false,
    });
  });

  it('valeurs non numériques : repli sur les valeurs par défaut', () => {
    expect(withDefaults({ adrigylPerDay: 'deux', feedsPerDay: Number.NaN } as never)).toMatchObject({
      adrigylPerDay: 1,
      feedsPerDay: 8,
    });
  });

  it('nombril : activé sauf refus explicite', () => {
    expect(withDefaults({ umbilicalCareEnabled: false }).umbilicalCareEnabled).toBe(false);
    expect(withDefaults({ umbilicalCareEnabled: undefined }).umbilicalCareEnabled).toBe(true);
  });
});
