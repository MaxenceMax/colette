import { describe, expect, it, vi } from 'vitest';
import type { Device } from './lib/types';

vi.mock('firebase-functions/v2/scheduler', () => ({
  onSchedule: (_options: unknown, handler: unknown) => handler,
}));

const { selectBottleRecipients } = await import('./bottle-reminder');

describe('selectBottleRecipients', () => {
  it('inclut les appareils sans préférence définie', () => {
    const devices: Device[] = [{ id: 'd1' }];

    expect(selectBottleRecipients(devices).map((d) => d.id)).toEqual(['d1']);
  });

  it('inclut les appareils ayant explicitement activé le rappel', () => {
    const devices: Device[] = [{ id: 'd1', notifyBottleReminder: true }];

    expect(selectBottleRecipients(devices).map((d) => d.id)).toEqual(['d1']);
  });

  it('exclut les appareils ayant désactivé le rappel biberon', () => {
    const devices: Device[] = [
      { id: 'd1', notifyBottleReminder: false },
      { id: 'd2', notifyBottleReminder: true },
      { id: 'd3' },
    ];

    expect(selectBottleRecipients(devices).map((d) => d.id).sort()).toEqual(['d2', 'd3']);
  });

  it('renvoie un tableau vide si tous les appareils ont désactivé le rappel', () => {
    const devices: Device[] = [{ id: 'd1', notifyBottleReminder: false }];

    expect(selectBottleRecipients(devices)).toEqual([]);
  });
});
