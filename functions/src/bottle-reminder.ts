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

/** Texte du rappel : « possible dès maintenant » si le snapshot porte une fourchette (ancienne version de l'app), sinon rappel 10 min avant. */
export function bottleMessage(suggestedMl: number, nextBottleAt: Date, windowEndAt: Date | null) {
  return windowEndAt
    ? { title: 'Biberon possible dès maintenant', body: `Environ ${suggestedMl} ml, d'ici ${formatHourMinute(windowEndAt)}` }
    : { title: 'Biberon dans 10 min', body: `Environ ${suggestedMl} ml, prévu vers ${formatHourMinute(nextBottleAt)}` };
}

type Deadline = {
  key: Timestamp;
  nextBottleAt: Date;
  windowStartAt: Date | null;
  windowEndAt: Date | null;
  suggestedMl: number;
};

/** Échéances à rappeler : chaque créneau de la grille, sinon (ancienne app) le prochain biberon puis le premier du matin en secours. */
export function deadlinesOf(plan: FeedingPlanDoc): Deadline[] {
  if (plan.upcomingBottles && plan.upcomingBottles.length > 0) {
    return [...plan.upcomingBottles]
      .sort((a, b) => a.at.toMillis() - b.at.toMillis())
      .map((b) => ({
        key: b.at,
        nextBottleAt: b.at.toDate(),
        windowStartAt: null,
        windowEndAt: null,
        suggestedMl: b.suggestedMl,
      }));
  }
  const deadlines: Deadline[] = [
    {
      key: plan.nextBottleAt,
      nextBottleAt: plan.nextBottleAt.toDate(),
      windowStartAt: plan.windowStartAt?.toDate() ?? null,
      windowEndAt: plan.windowEndAt?.toDate() ?? null,
      suggestedMl: plan.suggestedMl,
    },
  ];
  // L'app calcule toujours le matin strictement après nextBottleAt : s'il le précède, ce sont des
  // champs périmés laissés par une ancienne version de l'app qui a réécrit nextBottleAt (écriture merge).
  if (plan.morningBottleAt && plan.morningBottleAt.toMillis() > plan.nextBottleAt.toMillis()) {
    deadlines.push({
      key: plan.morningBottleAt,
      nextBottleAt: plan.morningBottleAt.toDate(),
      windowStartAt: plan.morningWindowStartAt?.toDate() ?? null,
      windowEndAt: plan.morningWindowEndAt?.toDate() ?? null,
      suggestedMl: plan.suggestedMl,
    });
  }
  return deadlines;
}

export const bottleReminder = onSchedule({ schedule: 'every 5 minutes', timeZone: ZONE, maxInstances: 1 }, async () => {
  const now = new Date();
  const households = await db().collection('households').get();

  for (const doc of households.docs) {
    try {
      const plan = doc.get('feedingPlan') as FeedingPlanDoc | undefined;
      if (!plan?.nextBottleAt) continue;
      const lastNotifiedFor = (doc.get('lastBottleNotifiedFor') as Timestamp | undefined)?.toDate() ?? null;
      const computedAt = plan.computedAt?.toDate() ?? null;
      // Avec la grille, on n'écarte que les créneaux antérieurs ou égaux au dernier rappelé.
      const fromGrid = Boolean(plan.upcomingBottles?.length);
      const deadline = deadlinesOf(plan)
        .filter((d) => !fromGrid || !lastNotifiedFor || d.nextBottleAt.getTime() > lastNotifiedFor.getTime())
        .find((d) =>
          isReminderDue({
            nextBottleAt: d.nextBottleAt,
            windowStartAt: d.windowStartAt,
            windowEndAt: d.windowEndAt,
            computedAt,
            lastNotifiedFor,
            now,
          }),
        );
      if (!deadline) continue;

      const recipients = selectBottleRecipients(await loadDevices(doc.ref));
      const sent = await sendToDevices(doc.id, recipients, {
        ...bottleMessage(deadline.suggestedMl, deadline.nextBottleAt, deadline.windowStartAt ? deadline.windowEndAt : null),
        data: { route: '/today?bottle=1' },
      });

      // L'échéance n'est consommée que si le rappel est parti, ou si personne ne l'attend :
      // sinon le tick suivant réessaie, dans la limite de la tolérance de 15 min.
      if (sent > 0 || recipients.length === 0) {
        await doc.ref.update({ lastBottleNotifiedFor: deadline.key });
      }
    } catch (err) {
      logger.error('Rappel biberon en échec pour un foyer', { household: doc.id, err });
    }
  }
});
