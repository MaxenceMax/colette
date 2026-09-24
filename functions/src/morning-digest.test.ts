import { Timestamp } from 'firebase-admin/firestore';
import { afterEach, beforeEach, describe, expect, it, vi } from 'vitest';
import type { BabyDoc, Device, DeviceDoc, EventDoc, MedicalReminderDoc } from './lib/types';

const { sendToDevices, loggerError, loggerWarn, households, deviceUpdates } = vi.hoisted(() => ({
  sendToDevices: vi.fn(),
  loggerError: vi.fn(),
  loggerWarn: vi.fn(),
  households: [] as FakeHousehold[],
  deviceUpdates: [] as Array<{ household: string; deviceId: string; data: Record<string, unknown> }>,
}));

type FakeHousehold = {
  id: string;
  baby?: BabyDoc;
  devices?: Array<DeviceDoc & { id: string }>;
  events?: EventDoc[];
  medicalReminder?: MedicalReminderDoc;
  fails?: boolean;
};

vi.mock('firebase-functions/v2/scheduler', () => ({
  onSchedule: (_options: unknown, handler: unknown) => handler,
}));

vi.mock('firebase-functions', () => ({
  logger: { info: vi.fn(), warn: loggerWarn, error: loggerError },
}));

vi.mock('./lib/push', () => ({ sendToDevices }));

type Filter = [field: string, op: string, value: unknown];

/** Requête Firestore en mémoire : filtres sur `startAt`, tri et limite. */
function fakeQuery(events: EventDoc[], filters: Filter[] = [], desc = false, max?: number) {
  const matches = (event: EventDoc) =>
    filters.every(([field, op, value]) => {
      if (field !== 'startAt') throw new Error(`filtre inattendu: ${field}`);
      const at = event.startAt.toMillis();
      const bound = (value as Timestamp).toMillis();
      if (op === '>=') return at >= bound;
      if (op === '<') return at < bound;
      throw new Error(`opérateur inattendu: ${op}`);
    });

  return {
    where: (field: string, op: string, value: unknown) => fakeQuery(events, [...filters, [field, op, value]], desc, max),
    orderBy: (_field: string, direction?: string) => fakeQuery(events, filters, direction === 'desc', max),
    limit: (n: number) => fakeQuery(events, filters, desc, n),
    get: async () => {
      const found = events
        .filter(matches)
        .sort((a, b) => (desc ? b.startAt.toMillis() - a.startAt.toMillis() : a.startAt.toMillis() - b.startAt.toMillis()))
        .slice(0, max ?? Number.MAX_SAFE_INTEGER);
      return { docs: found.map((e) => ({ data: () => e })), empty: found.length === 0 };
    },
  };
}

vi.mock('./lib/firestore', async (importOriginal) => ({
  ...(await importOriginal<typeof import('./lib/firestore')>()),
  db: () => ({
    collection: (name: string) => {
      if (name !== 'households') throw new Error(`collection inattendue: ${name}`);
      return {
        get: async () => ({
          docs: households.map((h) => ({
            id: h.id,
            get: (field: string) =>
              field === 'baby' ? h.baby : field === 'medicalReminder' ? h.medicalReminder : undefined,
            ref: {
              collection: (sub: string) => {
                if (sub === 'events') return fakeQuery(h.events ?? []);
                if (sub !== 'devices') throw new Error(`sous-collection inattendue: ${sub}`);
                return {
                  get: async () => {
                    if (h.fails) throw new Error('Firestore indisponible');
                    return { docs: (h.devices ?? []).map(({ id, ...rest }) => ({ id, data: () => rest })) };
                  },
                  doc: (deviceId: string) => ({
                    update: async (data: Record<string, unknown>) => {
                      if (deviceId === 'disparu') throw new Error('NOT_FOUND: appareil supprimé');
                      deviceUpdates.push({ household: h.id, deviceId, data });
                    },
                  }),
                };
              },
            },
          })),
        }),
      };
    },
  }),
}));

const { buildDigestBody, selectMorningDigestRecipients, morningDigest } = await import('./morning-digest');

const handler = morningDigest as unknown as () => Promise<void>;

const NOW = new Date('2026-09-21T06:00:00Z'); // 8h, heure de Paris
const TODAY_KEY = '2026-09-21';
const at = (iso: string) => Timestamp.fromDate(new Date(iso));

describe('selectMorningDigestRecipients', () => {
  it("inclut un appareil sans préférence dont l'heure par défaut (8h) correspond", () => {
    const devices: Device[] = [{ id: 'd1' }];

    expect(selectMorningDigestRecipients(devices, 8, TODAY_KEY).map((d) => d.id)).toEqual(['d1']);
  });

  it("exclut un appareil sans préférence si l'heure courante n'est pas 8h", () => {
    const devices: Device[] = [{ id: 'd1' }];

    expect(selectMorningDigestRecipients(devices, 9, TODAY_KEY)).toEqual([]);
  });

  it('inclut un appareil ayant explicitement choisi cette heure', () => {
    const devices: Device[] = [{ id: 'd1', morningDigestHour: 9 }];

    expect(selectMorningDigestRecipients(devices, 9, TODAY_KEY).map((d) => d.id)).toEqual(['d1']);
  });

  it('exclut les appareils ayant désactivé le digest matinal, même à leur heure', () => {
    const devices: Device[] = [
      { id: 'd1', notifyMorningDigest: false, morningDigestHour: 8 },
      { id: 'd2', notifyMorningDigest: true, morningDigestHour: 8 },
      { id: 'd3', morningDigestHour: 8 },
    ];

    expect(
      selectMorningDigestRecipients(devices, 8, TODAY_KEY)
        .map((d) => d.id)
        .sort(),
    ).toEqual(['d2', 'd3']);
  });

  it("renvoie un tableau vide si aucun appareil n'est dû à cette heure", () => {
    const devices: Device[] = [{ id: 'd1', morningDigestHour: 20 }];

    expect(selectMorningDigestRecipients(devices, 8, TODAY_KEY)).toEqual([]);
  });

  it('exclut un appareil déjà servi aujourd’hui', () => {
    const devices: Device[] = [
      { id: 'servi', lastDigestSentOn: TODAY_KEY },
      { id: 'hier', lastDigestSentOn: '2026-09-20' },
    ];

    expect(selectMorningDigestRecipients(devices, 8, TODAY_KEY).map((d) => d.id)).toEqual(['hier']);
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

  it('ajoute une ligne par rappel santé après les soins', () => {
    expect(buildDigestBody(['Bain'], ['RDV à prendre : examen des 8 mois'])).toBe(
      'Bain\nRDV à prendre : examen des 8 mois',
    );
    expect(buildDigestBody([], ['En retard : examen des 8 mois'])).toBe('En retard : examen des 8 mois');
  });
});

describe('morningDigest', () => {
  beforeEach(() => {
    vi.useFakeTimers({ toFake: ['Date'] });
    vi.setSystemTime(NOW);
    sendToDevices.mockReset();
    sendToDevices.mockResolvedValue(1);
    loggerError.mockReset();
    loggerWarn.mockReset();
    households.length = 0;
    deviceUpdates.length = 0;
  });

  afterEach(() => {
    vi.useRealTimers();
  });

  it('envoie les soins en attente et marque les appareils servis', async () => {
    households.push({
      id: 'ABC123',
      baby: { name: 'Colette' },
      devices: [{ id: 'd1' }, { id: 'd2', morningDigestHour: 8 }, { id: 'd3', morningDigestHour: 20 }],
      events: [{ startAt: at('2026-09-21T05:00:00Z'), adrigyl: true }],
    });

    await handler();

    expect(sendToDevices).toHaveBeenCalledTimes(1);
    const [code, devices, payload] = sendToDevices.mock.calls[0];
    expect(code).toBe('ABC123');
    expect(devices.map((d: Device) => d.id)).toEqual(['d1', 'd2']);
    expect(payload).toEqual({
      title: "Aujourd'hui pour Colette",
      body: buildDigestBody(['Soin des yeux', 'Soin du nez', 'Soin du nombril', 'Bain']),
      data: { route: '/today' },
    });
    expect(deviceUpdates).toEqual([
      { household: 'ABC123', deviceId: 'd1', data: { lastDigestSentOn: TODAY_KEY } },
      { household: 'ABC123', deviceId: 'd2', data: { lastDigestSentOn: TODAY_KEY } },
    ]);
  });

  it("n'envoie rien pour un foyer sans bébé", async () => {
    households.push({ id: 'ABC123', devices: [{ id: 'd1' }] });

    await handler();

    expect(sendToDevices).not.toHaveBeenCalled();
    expect(deviceUpdates).toEqual([]);
  });

  it("n'envoie rien quand tous les soins sont faits", async () => {
    households.push({
      id: 'ABC123',
      baby: { name: 'Colette' },
      devices: [{ id: 'd1' }],
      events: [
        { startAt: at('2026-09-21T05:00:00Z'), adrigyl: true, eyeCare: true, noseCare: true },
        { startAt: at('2026-09-21T05:30:00Z'), umbilicalCare: true, bath: true },
        { startAt: at('2026-09-21T09:00:00Z'), umbilicalCare: true },
        { startAt: at('2026-09-21T15:00:00Z'), umbilicalCare: true },
      ],
    });

    await handler();

    expect(sendToDevices).not.toHaveBeenCalled();
  });

  it('exclut un appareil déjà servi aujourd’hui', async () => {
    households.push({
      id: 'ABC123',
      baby: { name: 'Colette' },
      devices: [{ id: 'd1', lastDigestSentOn: TODAY_KEY }],
      events: [],
    });

    await handler();

    expect(sendToDevices).not.toHaveBeenCalled();
  });

  it("ne compte pas les événements datés de demain", async () => {
    households.push({
      id: 'ABC123',
      baby: { name: 'Colette' },
      devices: [{ id: 'd1' }],
      events: [{ startAt: at('2026-09-21T23:00:00Z'), adrigyl: true }],
    });

    await handler();

    expect(sendToDevices.mock.calls[0][2].body).toContain('Adrigyl');
  });

  it("un bain d'hier (tous les 2 jours) n'est pas en attente", async () => {
    households.push({
      id: 'ABC123',
      baby: { name: 'Colette' },
      devices: [{ id: 'd1' }],
      events: [{ startAt: at('2026-09-20T16:00:00Z'), bath: true }],
    });

    await handler();

    expect(sendToDevices.mock.calls[0][2].body).toBe(
      buildDigestBody(['Adrigyl', 'Soin des yeux', 'Soin du nez', 'Soin du nombril']),
    );
  });

  it('un Adrigyl tous les 2 jours fait hier reste absent, fait il y a 8 jours est en attente', async () => {
    const everyTwoDays = { timesPerDay: 1, everyDays: 2, enabled: true };
    households.push({
      id: 'ABC123',
      baby: { name: 'Colette', careSettings: { adrigyl: everyTwoDays } },
      devices: [{ id: 'd1' }],
      events: [{ startAt: at('2026-09-20T05:00:00Z'), adrigyl: true }],
    });
    households.push({
      id: 'DEF456',
      baby: { name: 'Léon', careSettings: { adrigyl: everyTwoDays } },
      devices: [{ id: 'd2' }],
      events: [{ startAt: at('2026-09-13T05:00:00Z'), adrigyl: true }],
    });

    await handler();

    expect(sendToDevices).toHaveBeenCalledTimes(2);
    expect(sendToDevices.mock.calls[0][2].body).not.toContain('Adrigyl');
    expect(sendToDevices.mock.calls[1][2].body).toContain('Adrigyl');
  });

  it('se rabat sur « bébé » quand le prénom manque', async () => {
    households.push({ id: 'ABC123', baby: { name: '' }, devices: [{ id: 'd1' }], events: [] });

    await handler();

    expect(sendToDevices.mock.calls[0][2].title).toBe("Aujourd'hui pour bébé");
  });

  it("journalise l'échec d'un foyer et poursuit la boucle", async () => {
    households.push(
      { id: 'KO', baby: { name: 'Colette' }, fails: true },
      { id: 'ABC123', baby: { name: 'Colette' }, devices: [{ id: 'd1' }], events: [] },
    );

    await handler();

    expect(loggerError).toHaveBeenCalledTimes(1);
    expect(loggerError.mock.calls[0][1]).toMatchObject({ household: 'KO' });
    expect(sendToDevices).toHaveBeenCalledTimes(1);
    expect(sendToDevices.mock.calls[0][0]).toBe('ABC123');
  });

  it("n'échoue pas si un appareil a disparu avant le marquage", async () => {
    households.push({
      id: 'ABC123',
      baby: { name: 'Colette' },
      devices: [{ id: 'disparu' }, { id: 'd2' }],
      events: [],
    });

    await handler();

    expect(deviceUpdates.map((u) => u.deviceId)).toEqual(['d2']);
    expect(loggerWarn).toHaveBeenCalledTimes(1);
  });

  it('ne marque aucun appareil quand rien n’a pu être envoyé', async () => {
    sendToDevices.mockResolvedValue(0);
    households.push({ id: 'ABC123', baby: { name: 'Colette' }, devices: [{ id: 'd1' }], events: [] });

    await handler();

    expect(deviceUpdates).toEqual([]);
  });

  const m2Due = {
    stages: [
      { stageId: 'm2', dueFrom: at('2026-09-20T22:00:00Z'), dueUntil: at('2026-10-20T22:00:00Z'), hasAppointment: false },
    ],
  };

  it('envoie une seule ligne santé quand tous les soins sont faits', async () => {
    households.push({
      id: 'ABC123',
      baby: { name: 'Colette' },
      devices: [{ id: 'd1' }],
      events: [
        { startAt: at('2026-09-21T05:00:00Z'), adrigyl: true, eyeCare: true, noseCare: true },
        { startAt: at('2026-09-21T05:30:00Z'), umbilicalCare: true, bath: true },
        { startAt: at('2026-09-21T09:00:00Z'), umbilicalCare: true },
        { startAt: at('2026-09-21T15:00:00Z'), umbilicalCare: true },
      ],
      medicalReminder: m2Due,
    });

    await handler();

    expect(sendToDevices).toHaveBeenCalledTimes(1);
    expect(sendToDevices.mock.calls[0][2]).toEqual({
      title: "Aujourd'hui pour Colette",
      body: 'RDV à prendre : examen et vaccins des 2 mois',
      data: { route: '/today' },
    });
    expect(deviceUpdates).toEqual([{ household: 'ABC123', deviceId: 'd1', data: { lastDigestSentOn: TODAY_KEY } }]);
  });

  it("digest des soins conservé malgré un `medicalReminder` corrompu", async () => {
    households.push({
      id: 'ABC123',
      baby: { name: 'Colette' },
      devices: [{ id: 'd1' }],
      events: [{ startAt: at('2026-09-21T05:00:00Z'), adrigyl: true }],
      medicalReminder: { stages: {} } as unknown as MedicalReminderDoc,
    });

    await handler();

    expect(sendToDevices).toHaveBeenCalledTimes(1);
    expect(sendToDevices.mock.calls[0][2].body).toBe(
      buildDigestBody(['Soin des yeux', 'Soin du nez', 'Soin du nombril', 'Bain']),
    );
  });

  it('concatène soins et lignes santé', async () => {
    households.push({
      id: 'ABC123',
      baby: { name: 'Colette' },
      devices: [{ id: 'd1' }],
      events: [],
      medicalReminder: m2Due,
    });

    await handler();

    expect(sendToDevices.mock.calls[0][2].body).toBe(
      buildDigestBody(
        ['Adrigyl', 'Soin des yeux', 'Soin du nez', 'Soin du nombril', 'Bain'],
        ['RDV à prendre : examen et vaccins des 2 mois'],
      ),
    );
  });

  it('pas de ligne santé pour une étape avec RDV', async () => {
    households.push({
      id: 'ABC123',
      baby: { name: 'Colette' },
      devices: [{ id: 'd1' }],
      events: [],
      medicalReminder: { stages: [{ ...m2Due.stages[0], hasAppointment: true }] },
    });

    await handler();

    expect(sendToDevices.mock.calls[0][2].body).not.toContain('RDV à prendre');
  });
});
