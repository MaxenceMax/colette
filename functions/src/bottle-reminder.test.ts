import { Timestamp } from 'firebase-admin/firestore';
import { beforeEach, describe, expect, it, vi } from 'vitest';
import type { Device, DeviceDoc, FeedingPlanDoc } from './lib/types';

const { sendToDevices, loggerError, households, updates } = vi.hoisted(() => ({
  sendToDevices: vi.fn(),
  loggerError: vi.fn(),
  households: [] as FakeHousehold[],
  updates: [] as Array<{ household: string; data: Record<string, unknown> }>,
}));

type FakeHousehold = {
  id: string;
  fields: Record<string, unknown>;
  devices?: Array<DeviceDoc & { id: string }>;
  fails?: boolean;
};

vi.mock('firebase-functions/v2/scheduler', () => ({
  onSchedule: (_options: unknown, handler: unknown) => handler,
}));

vi.mock('firebase-functions', () => ({
  logger: { info: vi.fn(), warn: vi.fn(), error: loggerError },
}));

vi.mock('./lib/push', () => ({ sendToDevices }));

vi.mock('./lib/firestore', async (importOriginal) => ({
  ...(await importOriginal<typeof import('./lib/firestore')>()),
  db: () => ({
    collection: (name: string) => {
      if (name !== 'households') throw new Error(`collection inattendue: ${name}`);
      return {
        get: async () => ({
          docs: households.map((h) => ({
            id: h.id,
            get: (field: string) => h.fields[field],
            ref: {
              update: async (data: Record<string, unknown>) => {
                updates.push({ household: h.id, data });
              },
              collection: (sub: string) => {
                if (sub !== 'devices') throw new Error(`sous-collection inattendue: ${sub}`);
                return {
                  get: async () => {
                    if (h.fails) throw new Error('Firestore indisponible');
                    return {
                      docs: (h.devices ?? []).map(({ id, ...rest }) => ({ id, data: () => rest })),
                    };
                  },
                };
              },
            },
          })),
        }),
      };
    },
  }),
}));

const { selectBottleRecipients, bottleReminder } = await import('./bottle-reminder');

const handler = bottleReminder as unknown as () => Promise<void>;

/** Plan dû : échéance dans 5 min, calculé bien avant (un biberon a donc été enregistré). */
function duePlan(): FeedingPlanDoc {
  const next = new Date(Date.now() + 5 * 60 * 1000);
  return {
    nextBottleAt: Timestamp.fromDate(next),
    suggestedMl: 120,
    computedAt: Timestamp.fromDate(new Date(next.getTime() - 3 * 60 * 60 * 1000)),
  };
}

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

describe('bottleReminder', () => {
  beforeEach(() => {
    sendToDevices.mockReset();
    sendToDevices.mockResolvedValue(1);
    loggerError.mockReset();
    households.length = 0;
    updates.length = 0;
  });

  it("notifie une fois et consomme l'échéance", async () => {
    const plan = duePlan();
    households.push({ id: 'ABC123', fields: { feedingPlan: plan }, devices: [{ id: 'd1' }] });

    await handler();

    expect(sendToDevices).toHaveBeenCalledTimes(1);
    const [code, devices, payload] = sendToDevices.mock.calls[0];
    expect(code).toBe('ABC123');
    expect(devices.map((d: Device) => d.id)).toEqual(['d1']);
    expect(payload.data).toEqual({ route: '/today?bottle=1' });
    expect(payload.body).toContain('120 ml');
    expect(updates).toEqual([{ household: 'ABC123', data: { lastBottleNotifiedFor: plan.nextBottleAt } }]);
  });

  it("ne renotifie pas une échéance déjà notifiée", async () => {
    const plan = duePlan();
    households.push({
      id: 'ABC123',
      fields: { feedingPlan: plan, lastBottleNotifiedFor: plan.nextBottleAt },
      devices: [{ id: 'd1' }],
    });

    await handler();

    expect(sendToDevices).not.toHaveBeenCalled();
    expect(updates).toEqual([]);
  });

  it("ne consomme pas l'échéance quand rien n'a pu être envoyé", async () => {
    sendToDevices.mockResolvedValue(0);
    households.push({ id: 'ABC123', fields: { feedingPlan: duePlan() }, devices: [{ id: 'd1' }] });

    await handler();

    expect(sendToDevices).toHaveBeenCalledTimes(1);
    expect(updates).toEqual([]);
  });

  it("consomme l'échéance quand personne n'attend le rappel", async () => {
    sendToDevices.mockResolvedValue(0);
    const plan = duePlan();
    households.push({
      id: 'ABC123',
      fields: { feedingPlan: plan },
      devices: [{ id: 'd1', notifyBottleReminder: false }],
    });

    await handler();

    expect(updates).toEqual([{ household: 'ABC123', data: { lastBottleNotifiedFor: plan.nextBottleAt } }]);
  });

  it('ignore un plan incomplet sans bloquer les foyers suivants', async () => {
    households.push(
      { id: 'SANS', fields: { feedingPlan: { suggestedMl: 120 } }, devices: [{ id: 'd0' }] },
      { id: 'ABC123', fields: { feedingPlan: duePlan() }, devices: [{ id: 'd1' }] },
    );

    await handler();

    expect(sendToDevices).toHaveBeenCalledTimes(1);
    expect(sendToDevices.mock.calls[0][0]).toBe('ABC123');
  });

  it("journalise l'échec d'un foyer et poursuit la boucle", async () => {
    households.push(
      { id: 'KO', fields: { feedingPlan: duePlan() }, fails: true },
      { id: 'ABC123', fields: { feedingPlan: duePlan() }, devices: [{ id: 'd1' }] },
    );

    await handler();

    expect(loggerError).toHaveBeenCalledTimes(1);
    expect(loggerError.mock.calls[0][1]).toMatchObject({ household: 'KO' });
    expect(sendToDevices).toHaveBeenCalledTimes(1);
    expect(sendToDevices.mock.calls[0][0]).toBe('ABC123');
  });
});
