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

  it('compare en jours civils de Paris, insensible au changement d’heure', () => {
    // dueFrom : 12/11/2026 00:00 Paris. 14 jours civils avant : le 29/10/2026 (après le passage à l'heure d'hiver du 25/10).
    const reminder = { stages: [stage('m2', '2026-11-12T00:00:00+01:00', '2026-12-12T00:00:00+01:00')] };
    expect(
      medicalLines(reminder, new Date('2026-10-29T00:30:00+01:00')), // 29/10 00h30 Paris (heure d'hiver, UTC+1)
    ).toEqual(['RDV à prendre : examen et vaccins des 2 mois']);
    expect(
      medicalLines(reminder, new Date('2026-10-28T23:30:00+02:00')), // 28/10 23h30 Paris (heure d'été, UTC+2)
    ).toEqual([]);
  });

  it('ignore un snapshot dont `stages` n’est pas un tableau', () => {
    const reminder = { stages: {} } as unknown as { stages: unknown };
    expect(medicalLines(reminder as never, new Date('2026-11-10T06:00:00Z'))).toEqual([]);
  });

  it('ignore une étape sans `dueFrom` Timestamp exploitable', () => {
    const reminder = {
      stages: [{ stageId: 'm2', dueUntil: Timestamp.fromDate(new Date('2026-12-01T00:00:00Z')), hasAppointment: false }],
    };
    expect(medicalLines(reminder as never, new Date('2026-11-10T06:00:00Z'))).toEqual([]);
  });
});
