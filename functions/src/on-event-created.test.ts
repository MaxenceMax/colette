import { Timestamp } from 'firebase-admin/firestore';
import { beforeEach, describe, expect, it, vi } from 'vitest';
import type { Device, DeviceDoc, EventDoc } from './lib/types';

const { sendToDevices } = vi.hoisted(() => ({ sendToDevices: vi.fn() }));

vi.mock('firebase-functions/v2/firestore', () => ({
  onDocumentCreated: (_path: string, handler: unknown) => handler,
}));

vi.mock('./lib/push', () => ({ sendToDevices }));

const { selectRecipients, onEventCreated } = await import('./on-event-created');

/** Instantané Firestore minimal : données de l'événement et chemin vers le foyer. */
function fakeSnapshot(code: string, data: EventDoc, devices: Array<DeviceDoc & { id: string }>) {
  const householdRef = {
    collection: (name: string) => {
      if (name !== 'devices') throw new Error(`sous-collection inattendue: ${name}`);
      return { get: async () => ({ docs: devices.map(({ id, ...rest }) => ({ id, data: () => rest })) }) };
    },
  };
  return {
    params: { code },
    data: { data: () => data, ref: { parent: { parent: householdRef } } },
  };
}

const handler = onEventCreated as unknown as (event: unknown) => Promise<void>;

describe('selectRecipients', () => {
  it("exclut l'appareil auteur de l'événement", () => {
    const devices: Device[] = [
      { id: 'author', notifyOnOthersEvents: true },
      { id: 'other', notifyOnOthersEvents: true },
    ];

    const recipients = selectRecipients(devices, 'author');

    expect(recipients.map((d) => d.id)).toEqual(['other']);
  });

  it('exclut les appareils ayant désactivé les notifications des autres événements', () => {
    const devices: Device[] = [
      { id: 'other-1', notifyOnOthersEvents: false },
      { id: 'other-2', notifyOnOthersEvents: true },
      { id: 'other-3' },
    ];

    const recipients = selectRecipients(devices, 'author');

    expect(recipients.map((d) => d.id).sort()).toEqual(['other-2', 'other-3']);
  });

  it("renvoie un tableau vide s'il n'y a aucun destinataire", () => {
    const devices: Device[] = [{ id: 'author', notifyOnOthersEvents: true }];

    const recipients = selectRecipients(devices, 'author');

    expect(recipients).toEqual([]);
  });

  it('un événement sans auteur identifié ne notifie personne', () => {
    const devices: Device[] = [
      { id: 'd1', notifyOnOthersEvents: false },
      { id: 'd2', notifyOnOthersEvents: true },
    ];

    expect(selectRecipients(devices, undefined)).toEqual([]);
  });
});

describe('onEventCreated', () => {
  const startAt = Timestamp.fromDate(new Date('2026-09-21T12:32:00Z'));

  beforeEach(() => {
    sendToDevices.mockReset();
    sendToDevices.mockResolvedValue(1);
  });

  it("notifie les autres appareils, avec la route du journal", async () => {
    await handler(
      fakeSnapshot('ABC123', { startAt, bottleMl: 120, createdByDeviceId: 'author' }, [
        { id: 'author', label: 'iPhone de Maxence' },
        { id: 'other', label: 'iPhone de Julie' },
        { id: 'muet', notifyOnOthersEvents: false },
      ]),
    );

    expect(sendToDevices).toHaveBeenCalledTimes(1);
    const [code, devices, payload] = sendToDevices.mock.calls[0];
    expect(code).toBe('ABC123');
    expect(devices.map((d: Device) => d.id)).toEqual(['other']);
    expect(payload).toEqual({
      title: 'iPhone de Maxence a ajouté un événement',
      body: 'Biberon 120 ml à 14h32',
      data: { route: '/journal' },
    });
  });

  it("n'envoie rien quand l'événement n'a pas d'auteur identifié", async () => {
    await handler(
      fakeSnapshot('ABC123', { startAt, bath: true }, [{ id: 'd1' }, { id: 'd2' }]),
    );

    expect(sendToDevices).not.toHaveBeenCalled();
  });
});
