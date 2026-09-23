import { MEDICAL_STAGE_LABELS } from './medical-stages';
import type { MedicalReminderDoc } from './types';

/** Une étape sans RDV entre dans le digest ce nombre de jours avant sa fenêtre (comme l'app). */
export const MEDICAL_REMINDER_LEAD_DAYS = 14;

const DAY_MS = 24 * 60 * 60 * 1000;

/** « RDV à prendre : … » ou « En retard : … », pour chaque étape sans RDV dans le délai. */
export function medicalLines(reminder: MedicalReminderDoc | undefined, now: Date): string[] {
  const lines: string[] = [];
  for (const stage of reminder?.stages ?? []) {
    const label = MEDICAL_STAGE_LABELS[stage.stageId];
    if (!label || stage.hasAppointment) continue;
    const from = stage.dueFrom.toDate().getTime();
    const until = stage.dueUntil.toDate().getTime();
    const at = now.getTime();
    if (at >= until) lines.push(`En retard : ${label}`);
    else if (at >= from - MEDICAL_REMINDER_LEAD_DAYS * DAY_MS) lines.push(`RDV à prendre : ${label}`);
  }
  return lines;
}
