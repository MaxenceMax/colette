import { describe, expect, it, vi } from 'vitest';
import type { Device } from './lib/types';

vi.mock('firebase-functions/v2/firestore', () => ({
  onDocumentCreated: (_path: string, handler: unknown) => handler,
}));

const { selectRecipients } = await import('./on-event-created');

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

  it('gère un événement sans auteur connu en ne notifiant que selon la préférence', () => {
    const devices: Device[] = [
      { id: 'd1', notifyOnOthersEvents: false },
      { id: 'd2', notifyOnOthersEvents: true },
    ];

    const recipients = selectRecipients(devices, undefined);

    expect(recipients.map((d) => d.id)).toEqual(['d2']);
  });
});
