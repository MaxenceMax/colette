import { Timestamp } from 'firebase-admin/firestore';
import { beforeEach, describe, expect, it, vi } from 'vitest';
import { formatHourMinute } from './lib/paris-time';
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

const { selectBottleRecipients, deadlinesOf, bottleReminder } = await import('./bottle-reminder');

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

describe('deadlinesOf', () => {
  const at = (iso: string) => Timestamp.fromDate(new Date(iso));

  function planWithMorning(morningBottleAt: Timestamp | null): FeedingPlanDoc {
    return {
      nextBottleAt: at('2026-09-30T21:30:00Z'),
      windowStartAt: at('2026-09-30T21:00:00Z'),
      windowEndAt: at('2026-09-30T22:00:00Z'),
      suggestedMl: 120,
      morningBottleAt,
      morningWindowStartAt: morningBottleAt && at('2026-10-01T04:30:00Z'),
      morningWindowEndAt: morningBottleAt && at('2026-10-01T05:30:00Z'),
    };
  }

  it('ajoute le rappel du matin après le prochain biberon, principal en premier', () => {
    const plan = planWithMorning(at('2026-10-01T05:00:00Z'));

    const deadlines = deadlinesOf(plan);

    expect(deadlines.map((d) => d.key)).toEqual([plan.nextBottleAt, plan.morningBottleAt]);
  });

  it('ignore un rappel du matin qui précède le prochain biberon (champs périmés)', () => {
    const plan = planWithMorning(at('2026-09-30T20:00:00Z'));

    expect(deadlinesOf(plan).map((d) => d.key)).toEqual([plan.nextBottleAt]);
  });

  it('ignore un rappel du matin égal au prochain biberon', () => {
    const plan = planWithMorning(at('2026-09-30T21:30:00Z'));

    expect(deadlinesOf(plan)).toHaveLength(1);
  });

  it('ignore les champs du matin explicitement nuls', () => {
    const plan = planWithMorning(null);

    expect(deadlinesOf(plan).map((d) => d.key)).toEqual([plan.nextBottleAt]);
  });

  it('garde le rappel du matin sans fourchette (app sans fourchette)', () => {
    const plan: FeedingPlanDoc = {
      nextBottleAt: at('2026-09-30T21:30:00Z'),
      windowStartAt: null,
      windowEndAt: null,
      suggestedMl: 120,
      morningBottleAt: at('2026-10-01T05:00:00Z'),
      morningWindowStartAt: null,
      morningWindowEndAt: null,
    };

    const deadlines = deadlinesOf(plan);

    expect(deadlines.map((d) => d.key)).toEqual([plan.nextBottleAt, plan.morningBottleAt]);
    expect(deadlines.map((d) => [d.windowStartAt, d.windowEndAt])).toEqual([
      [null, null],
      [null, null],
    ]);
  });

  it('garde les fourchettes du matin écrites par une ancienne version', () => {
    const plan = planWithMorning(at('2026-10-01T05:00:00Z'));

    const morning = deadlinesOf(plan)[1];

    expect(morning.windowStartAt).toEqual(new Date('2026-10-01T04:30:00Z'));
    expect(morning.windowEndAt).toEqual(new Date('2026-10-01T05:30:00Z'));
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

  it('sans fourchette (ancienne app) : ancienne formulation', async () => {
    households.push({ id: 'ABC123', fields: { feedingPlan: duePlan() }, devices: [{ id: 'd1' }] });

    await handler();

    const [, , payload] = sendToDevices.mock.calls[0];
    expect(payload.title).toBe('Biberon dans 10 min');
  });

  it('avec fourchette : notifie à son ouverture avec la borne de fin', async () => {
    const start = new Date(Date.now() - 60 * 1000);
    const end = new Date(start.getTime() + 50 * 60 * 1000);
    const plan: FeedingPlanDoc = {
      nextBottleAt: Timestamp.fromDate(new Date(start.getTime() + 25 * 60 * 1000)),
      windowStartAt: Timestamp.fromDate(start),
      windowEndAt: Timestamp.fromDate(end),
      suggestedMl: 120,
      computedAt: Timestamp.fromDate(new Date(start.getTime() - 3 * 60 * 60 * 1000)),
    };
    households.push({ id: 'ABC123', fields: { feedingPlan: plan }, devices: [{ id: 'd1' }] });

    await handler();

    const [, , payload] = sendToDevices.mock.calls[0];
    expect(payload.title).toBe('Biberon possible dès maintenant');
    expect(payload.body).toBe(`Environ 120 ml, d'ici ${formatHourMinute(end)}`);
    expect(updates).toEqual([{ household: 'ABC123', data: { lastBottleNotifiedFor: plan.nextBottleAt } }]);
  });

  it('avec fourchette pas encore ouverte : rien', async () => {
    const start = new Date(Date.now() + 5 * 60 * 1000);
    const plan: FeedingPlanDoc = {
      nextBottleAt: Timestamp.fromDate(new Date(start.getTime() + 25 * 60 * 1000)),
      windowStartAt: Timestamp.fromDate(start),
      windowEndAt: Timestamp.fromDate(new Date(start.getTime() + 50 * 60 * 1000)),
      suggestedMl: 120,
      computedAt: Timestamp.fromDate(new Date(start.getTime() - 3 * 60 * 60 * 1000)),
    };
    households.push({ id: 'ABC123', fields: { feedingPlan: plan }, devices: [{ id: 'd1' }] });

    await handler();

    expect(sendToDevices).not.toHaveBeenCalled();
    expect(updates).toEqual([]);
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

  /** Plan dont la fourchette principale est finie depuis des heures, déjà notifiée. */
  function expiredPlanWithMorning(morningStart: Date): FeedingPlanDoc {
    const primaryEnd = new Date(morningStart.getTime() - 6 * 60 * 60 * 1000);
    return {
      nextBottleAt: Timestamp.fromDate(new Date(primaryEnd.getTime() - 30 * 60 * 1000)),
      windowStartAt: Timestamp.fromDate(new Date(primaryEnd.getTime() - 60 * 60 * 1000)),
      windowEndAt: Timestamp.fromDate(primaryEnd),
      suggestedMl: 120,
      computedAt: Timestamp.fromDate(new Date(primaryEnd.getTime() - 3 * 60 * 60 * 1000)),
      morningBottleAt: Timestamp.fromDate(new Date(morningStart.getTime() + 30 * 60 * 1000)),
      morningWindowStartAt: Timestamp.fromDate(morningStart),
      morningWindowEndAt: Timestamp.fromDate(new Date(morningStart.getTime() + 60 * 60 * 1000)),
    };
  }

  it('biberon manqué : rappel de secours à l\'ouverture de la fourchette du matin', async () => {
    const morningStart = new Date(Date.now() - 60 * 1000);
    const plan = expiredPlanWithMorning(morningStart);
    households.push({
      id: 'ABC123',
      fields: { feedingPlan: plan, lastBottleNotifiedFor: plan.nextBottleAt },
      devices: [{ id: 'd1' }],
    });

    await handler();

    const [, , payload] = sendToDevices.mock.calls[0];
    expect(payload.title).toBe('Biberon possible dès maintenant');
    expect(payload.body).toBe(
      `Environ 120 ml, d'ici ${formatHourMinute(plan.morningWindowEndAt!.toDate())}`,
    );
    expect(updates).toEqual([
      { household: 'ABC123', data: { lastBottleNotifiedFor: plan.morningBottleAt } },
    ]);
  });

  it('biberon manqué sans fourchette : rappel de secours 10 min avant le matin', async () => {
    const morning = new Date(Date.now() + 5 * 60 * 1000);
    const nextBottleAt = Timestamp.fromDate(new Date(morning.getTime() - 6 * 60 * 60 * 1000));
    const plan: FeedingPlanDoc = {
      nextBottleAt,
      windowStartAt: null,
      windowEndAt: null,
      suggestedMl: 120,
      computedAt: Timestamp.fromDate(new Date(nextBottleAt.toMillis() - 3 * 60 * 60 * 1000)),
      morningBottleAt: Timestamp.fromDate(morning),
      morningWindowStartAt: null,
      morningWindowEndAt: null,
    };
    households.push({
      id: 'ABC123',
      fields: { feedingPlan: plan, lastBottleNotifiedFor: plan.nextBottleAt },
      devices: [{ id: 'd1' }],
    });

    await handler();

    expect(sendToDevices).toHaveBeenCalledTimes(1);
    const [, , payload] = sendToDevices.mock.calls[0];
    expect(payload.title).toBe('Biberon dans 10 min');
    expect(payload.body).toBe(`Environ 120 ml, prévu vers ${formatHourMinute(morning)}`);
    expect(updates).toEqual([
      { household: 'ABC123', data: { lastBottleNotifiedFor: plan.morningBottleAt } },
    ]);
  });

  it('fourchette du matin pas encore ouverte : rien', async () => {
    const plan = expiredPlanWithMorning(new Date(Date.now() + 5 * 60 * 1000));
    households.push({
      id: 'ABC123',
      fields: { feedingPlan: plan, lastBottleNotifiedFor: plan.nextBottleAt },
      devices: [{ id: 'd1' }],
    });

    await handler();

    expect(sendToDevices).not.toHaveBeenCalled();
    expect(updates).toEqual([]);
  });

  it('rappel du matin déjà envoyé : rien', async () => {
    const plan = expiredPlanWithMorning(new Date(Date.now() - 60 * 1000));
    households.push({
      id: 'ABC123',
      fields: { feedingPlan: plan, lastBottleNotifiedFor: plan.morningBottleAt },
      devices: [{ id: 'd1' }],
    });

    await handler();

    expect(sendToDevices).not.toHaveBeenCalled();
  });

  it('fourchette du matin périmée (avant le prochain biberon, ancienne app) : rien', async () => {
    const now = Date.now();
    const next = new Date(now + 60 * 60 * 1000);
    const plan: FeedingPlanDoc = {
      nextBottleAt: Timestamp.fromDate(next),
      windowStartAt: Timestamp.fromDate(new Date(now + 30 * 60 * 1000)),
      windowEndAt: Timestamp.fromDate(new Date(now + 90 * 60 * 1000)),
      suggestedMl: 120,
      computedAt: Timestamp.fromDate(new Date(now - 10 * 60 * 1000)),
      morningBottleAt: Timestamp.fromDate(new Date(now + 30 * 60 * 1000)),
      morningWindowStartAt: Timestamp.fromDate(new Date(now - 60 * 1000)),
      morningWindowEndAt: Timestamp.fromDate(new Date(now + 60 * 60 * 1000)),
    };
    households.push({ id: 'ABC123', fields: { feedingPlan: plan }, devices: [{ id: 'd1' }] });

    await handler();

    expect(sendToDevices).not.toHaveBeenCalled();
    expect(updates).toEqual([]);
  });
});
