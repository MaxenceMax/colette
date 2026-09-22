import { Timestamp } from 'firebase-admin/firestore';
import { logger } from 'firebase-functions';
import { onSchedule } from 'firebase-functions/v2/scheduler';
import { pendingCares } from './lib/care-status';
import { db, loadDevices } from './lib/firestore';
import {
  nearestHourInParis,
  startOfTodayInParis,
  startOfTomorrowInParis,
  todayKeyInParis,
  ZONE,
} from './lib/paris-time';
import { sendToDevices } from './lib/push';
import { toCareEvent, withDefaults, type BabyDoc, type Device, type EventDoc } from './lib/types';

/**
 * Appareils à notifier : digest activé, heure choisie égale à l'heure courante (8h par défaut),
 * et digest pas déjà reçu aujourd'hui.
 */
export function selectMorningDigestRecipients(devices: Device[], hour: number, todayKey: string): Device[] {
  return devices.filter(
    (d) => d.notifyMorningDigest !== false && (d.morningDigestHour ?? 8) === hour && d.lastDigestSentOn !== todayKey,
  );
}

/** « Adrigyl, Soin des yeux, Bain » */
export function buildDigestBody(pending: string[]): string {
  return pending.join(', ');
}

export const morningDigest = onSchedule({ schedule: '0 * * * *', timeZone: ZONE, maxInstances: 1 }, async () => {
  const now = new Date();
  const hour = nearestHourInParis(now);
  const todayKey = todayKeyInParis(now);
  const households = await db().collection('households').get();

  for (const doc of households.docs) {
    try {
      const devices = selectMorningDigestRecipients(await loadDevices(doc.ref), hour, todayKey);
      if (devices.length === 0) continue;
      const baby = doc.get('baby') as BabyDoc | undefined;
      if (!baby) continue;

      const events = doc.ref.collection('events');
      const todaySnap = await events
        .where('startAt', '>=', Timestamp.fromDate(startOfTodayInParis(now)))
        .where('startAt', '<', Timestamp.fromDate(startOfTomorrowInParis(now)))
        .get();
      const lastBathSnap = await events.where('bath', '==', true).orderBy('startAt', 'desc').limit(1).get();

      const pending = pendingCares({
        settings: withDefaults(baby.careSettings),
        todayEvents: todaySnap.docs.map((d) => toCareEvent(d.data() as EventDoc)),
        lastBathAt: lastBathSnap.empty ? null : (lastBathSnap.docs[0].data() as EventDoc).startAt.toDate(),
        now,
      });
      if (pending.length === 0) continue;

      const sent = await sendToDevices(doc.id, devices, {
        title: baby.name ? `Aujourd'hui pour ${baby.name}` : "Aujourd'hui pour bébé",
        body: buildDigestBody(pending),
        data: { route: '/today' },
      });
      if (sent === 0) continue;

      // Marque la journée pour ne pas renvoyer le même digest au tick suivant.
      await Promise.all(
        devices.map((d) =>
          doc.ref
            .collection('devices')
            .doc(d.id)
            .update({ lastDigestSentOn: todayKey })
            .catch((err: unknown) =>
              logger.warn('Digest non marqué pour un appareil', { household: doc.id, deviceId: d.id, err }),
            ),
        ),
      );
    } catch (err) {
      logger.error('Digest matinal en échec pour un foyer', { household: doc.id, err });
    }
  }
});
