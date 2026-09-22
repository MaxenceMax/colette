import { describe, expect, it, vi } from 'vitest';
import type { Device } from './lib/types';

vi.mock('firebase-functions/v2/scheduler', () => ({
  onSchedule: (_options: unknown, handler: unknown) => handler,
}));

const { buildDigestBody, selectMorningDigestRecipients } = await import('./morning-digest');

describe('selectMorningDigestRecipients', () => {
  it("inclut un appareil sans préférence dont l'heure par défaut (8h) correspond", () => {
    const devices: Device[] = [{ id: 'd1' }];

    expect(selectMorningDigestRecipients(devices, 8).map((d) => d.id)).toEqual(['d1']);
  });

  it("exclut un appareil sans préférence si l'heure courante n'est pas 8h", () => {
    const devices: Device[] = [{ id: 'd1' }];

    expect(selectMorningDigestRecipients(devices, 9)).toEqual([]);
  });

  it('inclut un appareil ayant explicitement choisi cette heure', () => {
    const devices: Device[] = [{ id: 'd1', morningDigestHour: 9 }];

    expect(selectMorningDigestRecipients(devices, 9).map((d) => d.id)).toEqual(['d1']);
  });

  it('exclut les appareils ayant désactivé le digest matinal, même à leur heure', () => {
    const devices: Device[] = [
      { id: 'd1', notifyMorningDigest: false, morningDigestHour: 8 },
      { id: 'd2', notifyMorningDigest: true, morningDigestHour: 8 },
      { id: 'd3', morningDigestHour: 8 },
    ];

    expect(
      selectMorningDigestRecipients(devices, 8)
        .map((d) => d.id)
        .sort(),
    ).toEqual(['d2', 'd3']);
  });

  it("renvoie un tableau vide si aucun appareil n'est dû à cette heure", () => {
    const devices: Device[] = [{ id: 'd1', morningDigestHour: 20 }];

    expect(selectMorningDigestRecipients(devices, 8)).toEqual([]);
  });
});

describe('buildDigestBody', () => {
  it('joint les soins en attente avec une virgule', () => {
    expect(buildDigestBody(['Adrigyl', 'Soin des yeux', 'Bain'])).toBe('Adrigyl, Soin des yeux, Bain');
  });

  it('renvoie une chaîne vide sans soin en attente', () => {
    expect(buildDigestBody([])).toBe('');
  });

  it('renvoie le libellé seul pour un unique soin en attente', () => {
    expect(buildDigestBody(['Bain'])).toBe('Bain');
  });
});
