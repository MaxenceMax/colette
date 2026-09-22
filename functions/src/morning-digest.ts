import { Timestamp } from 'firebase-admin/firestore';
import { onSchedule } from 'firebase-functions/v2/scheduler';
import { pendingCares } from './lib/care-status';
import { db, loadDevices } from './lib/firestore';
import { hourInParis, startOfTodayInParis, ZONE } from './lib/paris-time';
import { sendToDevices } from './lib/push';
import { toCareEvent, withDefaults, type BabyDoc, type Device, type EventDoc } from './lib/types';

/** Appareils à notifier : digest activé et heure choisie égale à l'heure courante (8h par défaut). */
export function selectMorningDigestRecipients(devices: Device[], hour: number): Device[] {
  return devices.filter((d) => d.notifyMorningDigest !== false && (d.morningDigestHour ?? 8) === hour);
}

/** « Adrigyl, Soin des yeux, Bain » */
export function buildDigestBody(pending: string[]): string {
  return pending.join(', ');
}

export const morningDigest = onSchedule({ schedule: '0 * * * *', timeZone: ZONE }, async () => {
  const now = new Date();
  const hour = hourInParis(now);
  const households = await db().collection('households').get();

  for (const doc of households.docs) {
    const devices = selectMorningDigestRecipients(await loadDevices(doc.ref), hour);
    if (devices.length === 0) continue;
    const baby = doc.get('baby') as BabyDoc | undefined;
    if (!baby) continue;

    const events = doc.ref.collection('events');
    const todaySnap = await events.where('startAt', '>=', Timestamp.fromDate(startOfTodayInParis(now))).get();
    const lastBathSnap = await events.where('bath', '==', true).orderBy('startAt', 'desc').limit(1).get();

    const pending = pendingCares({
      settings: withDefaults(baby.careSettings),
      todayEvents: todaySnap.docs.map((d) => toCareEvent(d.data() as EventDoc)),
      lastBathAt: lastBathSnap.empty ? null : (lastBathSnap.docs[0].data() as EventDoc).startAt.toDate(),
      now,
    });
    if (pending.length === 0) continue;

    await sendToDevices(doc.id, devices, {
      title: `Aujourd'hui pour ${baby.name}`,
      body: buildDigestBody(pending),
      data: { route: '/today' },
    });
  }
});
