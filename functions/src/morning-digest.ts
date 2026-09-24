import { Timestamp } from 'firebase-admin/firestore';
import { logger } from 'firebase-functions';
import { onSchedule } from 'firebase-functions/v2/scheduler';
import { CARE_WINDOW_DAYS } from './lib/care-frequency';
import { pendingCares } from './lib/care-status';
import { db, loadDevices } from './lib/firestore';
import { medicalLines } from './lib/medical-reminder';
import {
  nearestHourInParis,
  startOfDayInParis,
  startOfTomorrowInParis,
  todayKeyInParis,
  ZONE,
} from './lib/paris-time';
import { sendToDevices } from './lib/push';
import {
  toCareEvent,
  withDefaults,
  type BabyDoc,
  type Device,
  type EventDoc,
  type MedicalReminderDoc,
} from './lib/types';

/**
 * Appareils à notifier : digest activé, heure choisie égale à l'heure courante (8h par défaut),
 * et digest pas déjà reçu aujourd'hui.
 */
export function selectMorningDigestRecipients(devices: Device[], hour: number, todayKey: string): Device[] {
  return devices.filter(
    (d) => d.notifyMorningDigest !== false && (d.morningDigestHour ?? 8) === hour && d.lastDigestSentOn !== todayKey,
  );
}

/** Soins en attente (« Adrigyl, Soin des yeux ») puis une ligne par rappel santé. */
export function buildDigestBody(pending: string[], medical: string[] = []): string {
  return [pending.join(', '), ...medical].filter((line) => line.length > 0).join('\n');
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

      const eventsSnap = await doc.ref
        .collection('events')
        .where('startAt', '>=', Timestamp.fromDate(startOfDayInParis(now, CARE_WINDOW_DAYS - 1)))
        .where('startAt', '<', Timestamp.fromDate(startOfTomorrowInParis(now)))
        .get();

      const pending = pendingCares({
        settings: withDefaults(baby.careSettings),
        events: eventsSnap.docs.map((d) => toCareEvent(d.data() as EventDoc)),
        now,
      });
      let medical: string[] = [];
      try {
        medical = medicalLines(doc.get('medicalReminder') as MedicalReminderDoc | undefined, now);
      } catch (err) {
        logger.warn('Rappels santé ignorés pour un foyer', { household: doc.id, err });
      }
      if (pending.length === 0 && medical.length === 0) continue;

      const sent = await sendToDevices(doc.id, devices, {
        title: baby.name ? `Aujourd'hui pour ${baby.name}` : "Aujourd'hui pour bébé",
        body: buildDigestBody(pending, medical),
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
