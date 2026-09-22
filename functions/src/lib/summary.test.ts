import { describe, expect, it } from 'vitest';
import { summarizeEvent } from './summary';

describe('summarizeEvent', () => {
  const at = new Date('2026-09-21T12:32:00Z');

  it("liste biberon puis soins, avec l'heure de Paris", () => {
    expect(summarizeEvent({ startAt: at, bottleMl: 120, diaperChange: true, adrigyl: true })).toBe(
      'Biberon 120 ml · Couche · Adrigyl à 14h32',
    );
  });

  it('gère un événement à un seul soin', () => {
    expect(summarizeEvent({ startAt: at, bath: true })).toBe('Bain à 14h32');
  });
});
