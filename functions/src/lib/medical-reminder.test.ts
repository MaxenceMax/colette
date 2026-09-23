import { Timestamp } from 'firebase-admin/firestore';
import { describe, expect, it } from 'vitest';
import { medicalLines } from './medical-reminder';

const stage = (stageId: string, dueFrom: string, dueUntil: string, hasAppointment = false) => ({
  stageId,
  dueFrom: Timestamp.fromDate(new Date(dueFrom)),
  dueUntil: Timestamp.fromDate(new Date(dueUntil)),
  hasAppointment,
});

describe('medicalLines', () => {
  it('rien sans snapshot', () => {
    expect(medicalLines(undefined, new Date('2026-10-20T06:00:00Z'))).toEqual([]);
  });

  it('étape sans RDV à 14 jours ou moins du début', () => {
    const reminder = { stages: [stage('m2', '2026-11-01T00:00:00+01:00', '2026-12-01T00:00:00+01:00')] };
    expect(medicalLines(reminder, new Date('2026-10-17T06:00:00Z'))).toEqual([]);
    expect(medicalLines(reminder, new Date('2026-10-18T06:00:00Z'))).toEqual([
      'RDV à prendre : examen et vaccins des 2 mois',
    ]);
  });

  it('rien pour une étape avec RDV', () => {
    const reminder = { stages: [stage('m2', '2026-11-01T00:00:00+01:00', '2026-12-01T00:00:00+01:00', true)] };
    expect(medicalLines(reminder, new Date('2026-11-10T06:00:00Z'))).toEqual([]);
  });

  it('en retard après la fin de la fenêtre', () => {
    const reminder = { stages: [stage('m2', '2026-11-01T00:00:00+01:00', '2026-12-01T00:00:00+01:00')] };
    expect(medicalLines(reminder, new Date('2026-12-02T06:00:00Z'))).toEqual([
      'En retard : examen et vaccins des 2 mois',
    ]);
  });

  it('ignore une étape inconnue', () => {
    const reminder = { stages: [stage('m99', '2026-10-01T00:00:00Z', '2026-12-01T00:00:00Z')] };
    expect(medicalLines(reminder, new Date('2026-11-10T06:00:00Z'))).toEqual([]);
  });
});
