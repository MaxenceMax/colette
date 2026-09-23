import { MEDICAL_STAGE_LABELS } from './medical-stages';
import { calendarDaysBetween } from './paris-time';
import type { MedicalReminderDoc, MedicalReminderStageDoc } from './types';

/** Une étape sans RDV entre dans le digest ce nombre de jours avant sa fenêtre (comme l'app). */
export const MEDICAL_REMINDER_LEAD_DAYS = 14;

/** Une étape exploitable a un `dueFrom` et un `dueUntil` qui sont bien des `Timestamp` Firestore. */
function hasValidDueDates(stage: Partial<MedicalReminderStageDoc> | undefined | null): boolean {
  return typeof stage?.dueFrom?.toDate === 'function' && typeof stage?.dueUntil?.toDate === 'function';
}

/**
 * « RDV à prendre : … » ou « En retard : … », pour chaque étape sans RDV dans le délai.
 * Comparaison en jours civils de Paris (pas en millisecondes), insensible au changement d'heure.
 * Un document `medicalReminder` mal formé (stages absents ou invalides) ne produit aucune ligne
 * au lieu de faire échouer l'appelant : les soins du digest restent indépendants du suivi médical.
 * La ligne revient chaque matin tant qu'aucun RDV n'est posé (voulu).
 */
export function medicalLines(reminder: MedicalReminderDoc | undefined, now: Date): string[] {
  const stages = reminder?.stages;
  if (!Array.isArray(stages)) return [];

  const lines: string[] = [];
  for (const stage of stages) {
    const label = MEDICAL_STAGE_LABELS[stage?.stageId];
    if (!label || stage.hasAppointment || !hasValidDueDates(stage)) continue;
    const daysFromDueFrom = calendarDaysBetween(stage.dueFrom.toDate(), now);
    const daysFromDueUntil = calendarDaysBetween(stage.dueUntil.toDate(), now);
    if (daysFromDueUntil >= 0) lines.push(`En retard : ${label}`);
    else if (daysFromDueFrom >= -MEDICAL_REMINDER_LEAD_DAYS) lines.push(`RDV à prendre : ${label}`);
  }
  return lines;
}
