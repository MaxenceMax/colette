import { describe, expect, it } from 'vitest';
import { pendingCares } from './care-status';
import { DEFAULT_CARE_SETTINGS } from './types';

const now = new Date('2026-09-21T06:00:00Z'); // 8h à Paris
const everyTwoDays = { timesPerDay: 1, everyDays: 2, enabled: true };

describe('pendingCares', () => {
  it('sans événement : tous les soins par défaut sont en attente, dans l’ordre', () => {
    expect(pendingCares({ settings: DEFAULT_CARE_SETTINGS, events: [], now })).toEqual([
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
      events: [{ startAt: new Date('2026-09-21T05:00:00Z'), adrigyl: true }],
      now,
    });
    expect(pending).not.toContain('Adrigyl');
  });

  it("un soin quotidien fait hier reste en attente aujourd'hui", () => {
    const pending = pendingCares({
      settings: DEFAULT_CARE_SETTINGS,
      events: [{ startAt: new Date('2026-09-20T05:00:00Z'), adrigyl: true }],
      now,
    });
    expect(pending).toContain('Adrigyl');
  });

  it("soin désactivé : jamais en attente, même fait aujourd'hui", () => {
    const pending = pendingCares({
      settings: { ...DEFAULT_CARE_SETTINGS, umbilicalCare: { ...DEFAULT_CARE_SETTINGS.umbilicalCare, enabled: false } },
      events: [{ startAt: new Date('2026-09-21T05:00:00Z'), umbilicalCare: true }],
      now,
    });
    expect(pending).toEqual(['Adrigyl', 'Soin des yeux', 'Soin du nez', 'Bain']);
  });

  it('nombril 3 par jour : deux soins faits encore en attente, trois faits absent', () => {
    const care = (hour: string) => ({ startAt: new Date(`2026-09-21T${hour}:00:00Z`), umbilicalCare: true });
    expect(pendingCares({ settings: DEFAULT_CARE_SETTINGS, events: [care('03'), care('05')], now })).toContain(
      'Soin du nombril',
    );
    expect(
      pendingCares({ settings: DEFAULT_CARE_SETTINGS, events: [care('03'), care('04'), care('05')], now }),
    ).not.toContain('Soin du nombril');
  });

  it('2 par jour avec une prise faite : encore en attente', () => {
    const pending = pendingCares({
      settings: { ...DEFAULT_CARE_SETTINGS, adrigyl: { timesPerDay: 2, everyDays: 1, enabled: true } },
      events: [{ startAt: new Date('2026-09-21T05:00:00Z'), adrigyl: true }],
      now,
    });
    expect(pending).toContain('Adrigyl');
  });

  it('tous les 2 jours : fait hier absent, fait avant-hier ou jamais en attente', () => {
    const settings = { ...DEFAULT_CARE_SETTINGS, adrigyl: everyTwoDays };
    expect(
      pendingCares({ settings, events: [{ startAt: new Date('2026-09-20T05:00:00Z'), adrigyl: true }], now }),
    ).not.toContain('Adrigyl');
    expect(
      pendingCares({ settings, events: [{ startAt: new Date('2026-09-19T05:00:00Z'), adrigyl: true }], now }),
    ).toContain('Adrigyl');
    expect(pendingCares({ settings, events: [], now })).toContain('Adrigyl');
  });

  it("tous les 2 jours, fait hier et aujourd'hui : absent (fait)", () => {
    const pending = pendingCares({
      settings: { ...DEFAULT_CARE_SETTINGS, adrigyl: everyTwoDays },
      events: [
        { startAt: new Date('2026-09-20T05:00:00Z'), adrigyl: true },
        { startAt: new Date('2026-09-21T05:00:00Z'), adrigyl: true },
      ],
      now,
    });
    expect(pending).not.toContain('Adrigyl');
  });

  it('bain : hier absent, avant-hier en attente (tous les 2 jours par défaut)', () => {
    expect(
      pendingCares({
        settings: DEFAULT_CARE_SETTINGS,
        events: [{ startAt: new Date('2026-09-20T16:00:00Z'), bath: true }],
        now,
      }),
    ).not.toContain('Bain');
    expect(
      pendingCares({
        settings: DEFAULT_CARE_SETTINGS,
        events: [{ startAt: new Date('2026-09-19T16:00:00Z'), bath: true }],
        now,
      }),
    ).toContain('Bain');
  });
});
