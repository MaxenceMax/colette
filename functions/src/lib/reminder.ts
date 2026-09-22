export const REMINDER_LEAD_MS = 10 * 60 * 1000;
export const REMINDER_TOLERANCE_MS = 15 * 60 * 1000;

type Input = { nextBottleAt: Date; computedAt: Date | null; lastNotifiedFor: Date | null; now: Date };

/**
 * Dû entre 10 min avant l'échéance et 15 min après, une seule fois par échéance.
 * Un plan calculé à ou après son échéance (aucun biberon encore enregistré, ou
 * dernier biberon trop ancien) ne déclenche rien : le parent sait déjà.
 */
export function isReminderDue({ nextBottleAt, computedAt, lastNotifiedFor, now }: Input): boolean {
  if (lastNotifiedFor && lastNotifiedFor.getTime() === nextBottleAt.getTime()) return false;
  if (computedAt && computedAt.getTime() >= nextBottleAt.getTime()) return false;
  if (now.getTime() > nextBottleAt.getTime() + REMINDER_TOLERANCE_MS) return false;
  return nextBottleAt.getTime() - REMINDER_LEAD_MS <= now.getTime();
}
