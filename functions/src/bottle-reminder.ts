import type { Timestamp } from 'firebase-admin/firestore';
import { logger } from 'firebase-functions';
import { onSchedule } from 'firebase-functions/v2/scheduler';
import { db, loadDevices } from './lib/firestore';
import { formatHourMinute, ZONE } from './lib/paris-time';
import { sendToDevices } from './lib/push';
import { isReminderDue } from './lib/reminder';
import type { Device, FeedingPlanDoc } from './lib/types';

/** Appareils à notifier : ceux n'ayant pas désactivé le rappel biberon. */
export function selectBottleRecipients(devices: Device[]): Device[] {
  return devices.filter((d) => d.notifyBottleReminder !== false);
}

export const bottleReminder = onSchedule({ schedule: 'every 5 minutes', timeZone: ZONE }, async () => {
  const now = new Date();
  const households = await db().collection('households').get();

  for (const doc of households.docs) {
    try {
      const plan = doc.get('feedingPlan') as FeedingPlanDoc | undefined;
      if (!plan?.nextBottleAt) continue;
      const nextBottleAt = plan.nextBottleAt.toDate();
      const lastNotifiedFor = (doc.get('lastBottleNotifiedFor') as Timestamp | undefined)?.toDate() ?? null;
      const due = isReminderDue({
        nextBottleAt,
        computedAt: plan.computedAt?.toDate() ?? null,
        lastNotifiedFor,
        now,
      });
      if (!due) continue;

      const recipients = selectBottleRecipients(await loadDevices(doc.ref));
      const sent = await sendToDevices(doc.id, recipients, {
        title: 'Biberon dans 10 min',
        body: `Environ ${plan.suggestedMl} ml, prévu vers ${formatHourMinute(nextBottleAt)}`,
        data: { route: '/today?bottle=1' },
      });

      // L'échéance n'est consommée que si le rappel est parti, ou si personne ne l'attend :
      // sinon le tick suivant réessaie, dans la limite de la tolérance de 15 min.
      if (sent > 0 || recipients.length === 0) {
        await doc.ref.update({ lastBottleNotifiedFor: plan.nextBottleAt });
      }
    } catch (err) {
      logger.error('Rappel biberon en échec pour un foyer', { household: doc.id, err });
    }
  }
});
