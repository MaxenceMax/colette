import type { Timestamp } from 'firebase-admin/firestore';
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
    const plan = doc.get('feedingPlan') as FeedingPlanDoc | undefined;
    if (!plan) continue;
    const nextBottleAt = plan.nextBottleAt.toDate();
    const lastNotifiedFor = (doc.get('lastBottleNotifiedFor') as Timestamp | undefined)?.toDate() ?? null;
    if (!isReminderDue({ nextBottleAt, lastNotifiedFor, now })) continue;

    const devices = selectBottleRecipients(await loadDevices(doc.ref));
    await sendToDevices(doc.id, devices, {
      title: 'Biberon dans 10 min',
      body: `Environ ${plan.suggestedMl} ml, prévu vers ${formatHourMinute(nextBottleAt)}`,
      data: { route: '/today?bottle=1' },
    });
    await doc.ref.update({ lastBottleNotifiedFor: plan.nextBottleAt });
  }
});
