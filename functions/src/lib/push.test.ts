import { beforeEach, describe, expect, it, vi } from 'vitest';
import type { Device } from './types';

const { sendEachForMulticast, updateCalls, loggerInfo } = vi.hoisted(() => ({
  sendEachForMulticast: vi.fn(),
  updateCalls: [] as Array<{ code: string; deviceId: string; data: unknown }>,
  loggerInfo: vi.fn(),
}));

vi.mock('firebase-admin/messaging', () => ({
  getMessaging: () => ({ sendEachForMulticast }),
}));

vi.mock('firebase-functions', () => ({
  logger: { info: loggerInfo },
}));

vi.mock('./firestore', () => ({
  db: () => ({
    collection: (name: string) => {
      if (name !== 'households') throw new Error(`collection inattendue: ${name}`);
      return {
        doc: (code: string) => ({
          collection: (sub: string) => {
            if (sub !== 'devices') throw new Error(`sous-collection inattendue: ${sub}`);
            return {
              doc: (deviceId: string) => ({
                update: (data: unknown) => {
                  updateCalls.push({ code, deviceId, data });
                  return Promise.resolve();
                },
              }),
            };
          },
        }),
      };
    },
  }),
}));

const { sendToDevices } = await import('./push');

describe('sendToDevices', () => {
  beforeEach(() => {
    sendEachForMulticast.mockReset();
    loggerInfo.mockReset();
    updateCalls.length = 0;
  });

  it("ne fait aucun appel FCM si aucun appareil n'a de token", async () => {
    const devices: Device[] = [{ id: 'd1' }, { id: 'd2', fcmToken: null }];

    const count = await sendToDevices('ABC123', devices, { title: 'Titre', body: 'Corps' });

    expect(count).toBe(0);
    expect(sendEachForMulticast).not.toHaveBeenCalled();
  });

  it('envoie un multicast aux appareils munis d’un token et renvoie le nombre de succès', async () => {
    sendEachForMulticast.mockResolvedValue({
      responses: [{ success: true }, { success: true }],
      successCount: 2,
      failureCount: 0,
    });
    const devices: Device[] = [
      { id: 'd1', fcmToken: 'token-1' },
      { id: 'd2', fcmToken: 'token-2' },
    ];

    const count = await sendToDevices('ABC123', devices, {
      title: 'Titre',
      body: 'Corps',
      data: { type: 'reminder' },
    });

    expect(count).toBe(2);
    expect(sendEachForMulticast).toHaveBeenCalledWith({
      tokens: ['token-1', 'token-2'],
      notification: { title: 'Titre', body: 'Corps' },
      data: { type: 'reminder' },
      apns: { payload: { aps: { sound: 'default' } } },
    });
    expect(updateCalls).toEqual([]);
  });

  it('efface uniquement les tokens signalés comme non enregistrés ou invalides', async () => {
    sendEachForMulticast.mockResolvedValue({
      responses: [
        { success: true },
        { success: false, error: { code: 'messaging/registration-token-not-registered' } },
        { success: false, error: { code: 'messaging/invalid-registration-token' } },
        { success: false, error: { code: 'messaging/internal-error' } },
      ],
      successCount: 1,
      failureCount: 3,
    });
    const devices: Device[] = [
      { id: 'ok', fcmToken: 'token-ok' },
      { id: 'stale-1', fcmToken: 'token-stale-1' },
      { id: 'stale-2', fcmToken: 'token-stale-2' },
      { id: 'other-error', fcmToken: 'token-other' },
    ];

    const count = await sendToDevices('ABC123', devices, { title: 'Titre', body: 'Corps' });

    expect(count).toBe(1);
    expect(updateCalls).toHaveLength(2);
    expect(updateCalls.map((c) => c.deviceId).sort()).toEqual(['stale-1', 'stale-2']);
    for (const call of updateCalls) {
      expect(call.code).toBe('ABC123');
    }
  });
});
