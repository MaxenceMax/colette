export const REMINDER_LEAD_MS = 10 * 60 * 1000;
export const REMINDER_TOLERANCE_MS = 15 * 60 * 1000;

type Input = {
  nextBottleAt: Date;
  windowStartAt?: Date | null;
  windowEndAt?: Date | null;
  computedAt: Date | null;
  lastNotifiedFor: Date | null;
  now: Date;
};

/**
 * Une seule fois par échéance (`nextBottleAt`).
 * Avec fourchette : dû de son ouverture à sa fermeture ; un plan calculé fourchette
 * déjà ouverte (aucun biberon encore enregistré, ou dernier biberon trop ancien)
 * ne déclenche rien : le parent sait déjà.
 * Sans fourchette (snapshot d'une ancienne version de l'app) : dû entre 10 min avant
 * l'échéance et 15 min après ; un plan calculé à ou après son échéance ne déclenche rien.
 */
export function isReminderDue({
  nextBottleAt,
  windowStartAt,
  windowEndAt,
  computedAt,
  lastNotifiedFor,
  now,
}: Input): boolean {
  if (lastNotifiedFor && lastNotifiedFor.getTime() === nextBottleAt.getTime()) return false;
  if (windowStartAt && windowEndAt) {
    if (computedAt && computedAt.getTime() >= windowStartAt.getTime()) return false;
    return windowStartAt.getTime() <= now.getTime() && now.getTime() <= windowEndAt.getTime();
  }
  if (computedAt && computedAt.getTime() >= nextBottleAt.getTime()) return false;
  if (now.getTime() > nextBottleAt.getTime() + REMINDER_TOLERANCE_MS) return false;
  return nextBottleAt.getTime() - REMINDER_LEAD_MS <= now.getTime();
}
