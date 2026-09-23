# Suivi médical : plan d'implémentation

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Suivre les examens obligatoires et les vaccins du calendrier français, noter les RDV et les injections, synchroniser les RDV avec un calendrier iCloud partagé du Calendrier iOS, et rappeler les étapes sans RDV (carte d'accueil, digest du matin).

**Architecture:** Nouvelle feature `lib/features/health/`. Le calendrier officiel est une table Dart embarquée ; Firestore ne stocke que les visites saisies (`medicalVisits/{stageId}`) et un snapshot `medicalReminder` lu par la Cloud Function du digest. Le Calendrier iOS passe par un pont Swift EventKit (`colette/calendar`) ; une réconciliation pure calcule les créations, mises à jour et suppressions d'événements, dédoublonnés par leur URL `colette://rdv/{stageId}`.

**Tech Stack:** Flutter (iOS 15+), Riverpod 3 codegen, freezed, fpdart, cloud_firestore + fake_cloud_firestore, mocktail, Swift/EventKit, Cloud Functions TypeScript + vitest.

**Spec:** `docs/superpowers/specs/2026-09-23-health-follow-up-design.md`.

---

## Conventions pour chaque tâche

- Worktree : `/Users/maxencemontet/Documents/colette/.claude/worktrees/health-follow-up` (branche `feat/health-follow-up`). Ne jamais travailler dans le checkout principal. Jamais de `git stash` nu. Ne rien pousser.
- Après toute modification d'un fichier annoté (`@freezed`, `@riverpod`) : `dart run build_runner build -d`, et commiter les `.g.dart` / `.freezed.dart` produits **pour les fichiers de la tâche seulement**. `build_runner` réécrit parfois `lib/features/documents/presentation/providers/documents_preview_controller.g.dart` (hash périmé sur `main`) : ne jamais le commiter, le restaurer avec `git checkout -- <fichier>`.
- Après toute modification de `lib/l10n/app_fr.arb` : `flutter gen-l10n` (dossier généré non versionné).
- Avant chaque commit : `dart format lib test integration_test`, `dart analyze` (0 problème ; `dart analyze`, pas `flutter analyze`), tests de la tâche ; `flutter test` complet en fin de tâche.
- Commits : `git add` de fichiers ciblés, message en français (`feat:`, `test:`, `fix:`, `docs:`, `chore:`), ligne `Co-Authored-By` selon la consigne d'attribution de la session.
- Règles : `CLAUDE.md` (tokens `AppSpacing`/`AppSize`/`AppRadius`, couleurs `context.appColor(AppColors.x)`, textes `S.of(context)`, `switch` sur `AsyncValue`, doc `///` sur chaque classe publique, fichiers < 300 lignes, contrôleur autoDispose écouté par le widget appelant).
- Formats de date existants (`lib/core/dates/time_format.dart`) : `formatShortDate` (« 22 sept. 2026 »), `formatHourMinute` (« 14h32 »), `formatDayAndTime`.

## Carte des fichiers

Domaine (`lib/features/health/domain/`) :

| Fichier | Rôle |
| --- | --- |
| `entities/age_offset.dart` | Âge en jours ou en mois, date correspondante depuis la naissance. |
| `entities/vaccine_code.dart` | Enum des vaccins. |
| `entities/medical_stage.dart` | `MedicalStageId`, `ScheduledVaccine`, `MedicalStage`. |
| `reference/medical_schedule.dart` | Table du calendrier officiel. |
| `entities/given_vaccine.dart`, `entities/medical_visit.dart` | Saisie d'une étape. |
| `entities/medical_stage_status.dart`, `entities/medical_timeline.dart` | Statuts et frise calculée. |
| `entities/medical_reminder_snapshot.dart` | Snapshot pour le digest. |
| `entities/calendar_event.dart`, `entities/calendar_action.dart`, `entities/device_calendar.dart`, `entities/calendar_choice.dart` | Calendrier iOS. |
| `use_cases/compute_medical_stage_status.dart`, `use_cases/compute_medical_timeline.dart`, `use_cases/compute_medical_reminder_snapshot.dart`, `use_cases/validate_medical_visit.dart`, `use_cases/reconcile_calendar.dart` | Logique pure. |
| `repositories/medical_repository.dart`, `repositories/calendar_repository.dart` | Interfaces. |

Données : `data/dtos/medical_visit_dto.dart`, `data/dtos/medical_reminder_snapshot_dto.dart`, `data/repositories/firestore_medical_repository.dart`, `data/native_calendar_repository.dart`.

Présentation : `presentation/providers/health_providers.dart`, `selected_calendar.dart`, `health_sync.dart`, `medical_visit_controller.dart`, `calendar_settings_controller.dart` ; `presentation/widgets/health_labels.dart`, `health_sync_gate.dart`, `health_card.dart`, `medical_stage_tile.dart`, `medical_stage_sheet.dart`, `stage_appointment_fields.dart`, `stage_vaccine_row.dart`, `stage_visit_fields.dart`, `calendar_settings_section.dart`, `calendar_picker_sheet.dart` ; `presentation/pages/health_page.dart`.

iOS : `ios/Runner/Calendar/CalendarError.swift`, `ios/Runner/Calendar/CalendarPlugin.swift`, `ios/Runner/AppDelegate.swift`, `ios/Runner/Info.plist`, `ios/Runner.xcodeproj/project.pbxproj`.

Cloud Functions : `functions/src/lib/medical-stages.ts`, `functions/src/lib/types.ts`, `functions/src/morning-digest.ts`, tests.

---

### Task 1 : âges, vaccins et table du calendrier

**Files:**
- Create: `lib/features/health/domain/entities/age_offset.dart`, `lib/features/health/domain/entities/vaccine_code.dart`, `lib/features/health/domain/entities/medical_stage.dart`, `lib/features/health/domain/reference/medical_schedule.dart`
- Test: `test/features/health/domain/age_offset_test.dart`, `test/features/health/domain/medical_schedule_test.dart`

- [ ] **Step 1: Write the failing tests**

```dart
// test/features/health/domain/age_offset_test.dart
import 'package:colette/features/health/domain/entities/age_offset.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('jours : date civile, minuit', () {
    expect(
      const AgeOffset.days(8).from(DateTime(2026, 9, 28, 14, 30)),
      DateTime(2026, 10, 6),
    );
  });

  test('mois : même jour du mois', () {
    expect(
      const AgeOffset.months(2).from(DateTime(2026, 9, 1)),
      DateTime(2026, 11, 1),
    );
    expect(
      const AgeOffset.months(12).from(DateTime(2026, 9, 15)),
      DateTime(2027, 9, 15),
    );
  });

  test('mois : jour borné à la fin du mois', () {
    expect(
      const AgeOffset.months(1).from(DateTime(2027, 1, 31)),
      DateTime(2027, 2, 28),
    );
    expect(
      const AgeOffset.months(1).from(DateTime(2028, 1, 31)),
      DateTime(2028, 2, 29),
    );
    expect(
      const AgeOffset.months(3).from(DateTime(2026, 11, 30)),
      DateTime(2027, 2, 28),
    );
  });
}
```

```dart
// test/features/health/domain/medical_schedule_test.dart
import 'package:colette/features/health/domain/entities/medical_stage.dart';
import 'package:colette/features/health/domain/entities/vaccine_code.dart';
import 'package:colette/features/health/domain/reference/medical_schedule.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  final birth = DateTime(2026, 9, 1);

  test('une étape par identifiant, dans l\'ordre de l\'enum', () {
    expect(medicalSchedule.map((s) => s.id), MedicalStageId.values);
  });

  test('fenêtres non vides et débuts croissants', () {
    for (final stage in medicalSchedule) {
      expect(
        stage.until.from(birth).isAfter(stage.from.from(birth)),
        isTrue,
        reason: stage.id.name,
      );
    }
    for (var i = 1; i < medicalSchedule.length; i++) {
      expect(
        medicalSchedule[i].from.from(birth).isBefore(
          medicalSchedule[i - 1].from.from(birth),
        ),
        isFalse,
        reason: medicalSchedule[i].id.name,
      );
    }
  });

  List<MedicalStageId> mandatory(VaccineCode code) => [
    for (final stage in medicalSchedule)
      if (stage.vaccines.any((v) => v.code == code && !v.recommended)) stage.id,
  ];

  test('vaccins obligatoires aux âges du calendrier 2026', () {
    expect(mandatory(VaccineCode.hexavalent), [
      MedicalStageId.m2,
      MedicalStageId.m4,
      MedicalStageId.m11,
    ]);
    expect(mandatory(VaccineCode.pneumococcal), [
      MedicalStageId.m2,
      MedicalStageId.m4,
      MedicalStageId.m11,
    ]);
    expect(mandatory(VaccineCode.menB), [
      MedicalStageId.m3,
      MedicalStageId.m5,
      MedicalStageId.m12,
    ]);
    expect(mandatory(VaccineCode.menACWY), [
      MedicalStageId.m6,
      MedicalStageId.m12,
    ]);
    expect(mandatory(VaccineCode.mmr), [
      MedicalStageId.m12,
      MedicalStageId.m16,
    ]);
    expect(mandatory(VaccineCode.rotavirus), isEmpty);
  });

  test('rotavirus recommandé à 2, 3 et 4 mois', () {
    expect(
      [
        for (final stage in medicalSchedule)
          if (stage.vaccines.any(
            (v) => v.code == VaccineCode.rotavirus && v.recommended,
          ))
            stage.id,
      ],
      [MedicalStageId.m2, MedicalStageId.m3, MedicalStageId.m4],
    );
  });

  test('certificats à 8 jours, 8 mois et 23-24 mois ; 6 mois sans examen', () {
    expect(
      [
        for (final stage in medicalSchedule)
          if (stage.hasCertificate) stage.id,
      ],
      [MedicalStageId.day8, MedicalStageId.m8, MedicalStageId.m23],
    );
    expect(stageById(MedicalStageId.m6).hasExam, isFalse);
    expect(stageById(MedicalStageId.m11).hasExam, isTrue);
  });

  test('fenêtres de quelques étapes', () {
    final m2 = stageById(MedicalStageId.m2);
    expect(m2.from.from(birth), DateTime(2026, 11, 1));
    expect(m2.until.from(birth), DateTime(2026, 12, 1));
    final day8 = stageById(MedicalStageId.day8);
    expect(day8.from.from(birth), birth);
    expect(day8.until.from(birth), DateTime(2026, 9, 9));
  });
}
```

- [ ] **Step 2: Run tests to verify they fail**

Run: `flutter test test/features/health/domain`
Expected: FAIL (fichiers introuvables).

- [ ] **Step 3: Implement**

```dart
// lib/features/health/domain/entities/age_offset.dart
import 'dart:math' as math;

/// Unité d'un [AgeOffset].
enum AgeUnit { days, months }

/// Âge depuis la naissance, en jours civils ou en mois calendaires.
final class AgeOffset {
  const AgeOffset.days(this.value) : unit = AgeUnit.days;
  const AgeOffset.months(this.value) : unit = AgeUnit.months;

  final int value;
  final AgeUnit unit;

  /// Minuit du jour où l'enfant né le [birthDate] atteint cet âge. En mois,
  /// le jour est borné à la fin du mois (31 janvier + 1 mois = 28 ou 29 février).
  DateTime from(DateTime birthDate) => switch (unit) {
    AgeUnit.days => DateTime(
      birthDate.year,
      birthDate.month,
      birthDate.day + value,
    ),
    AgeUnit.months => _addMonths(birthDate, value),
  };

  static DateTime _addMonths(DateTime birth, int months) {
    final lastDay = DateTime(birth.year, birth.month + months + 1, 0).day;
    return DateTime(
      birth.year,
      birth.month + months,
      math.min(birth.day, lastDay),
    );
  }

  @override
  bool operator ==(Object other) =>
      other is AgeOffset && other.value == value && other.unit == unit;

  @override
  int get hashCode => Object.hash(value, unit);
}
```

```dart
// lib/features/health/domain/entities/vaccine_code.dart
/// Vaccins du calendrier ; `name` sert de clé Firestore.
enum VaccineCode {
  /// DTCaP-Hib-HépB (diphtérie, tétanos, coqueluche, polio, Haemophilus, hépatite B).
  hexavalent,
  pneumococcal,
  menB,
  menACWY,

  /// ROR (rougeole, oreillons, rubéole).
  mmr,
  rotavirus,
}
```

```dart
// lib/features/health/domain/entities/medical_stage.dart
import 'package:colette/features/health/domain/entities/age_offset.dart';
import 'package:colette/features/health/domain/entities/vaccine_code.dart';

/// Identifiant stable d'une étape ; `name` sert d'identifiant Firestore.
enum MedicalStageId {
  day8,
  week2,
  m1,
  m2,
  m3,
  m4,
  m5,
  m6,
  m8,
  m11,
  m12,
  m16,
  m23,
  y2,
  y3,
}

/// Vaccin attendu à une étape ; [recommended] : recommandé, non obligatoire.
final class ScheduledVaccine {
  const ScheduledVaccine(this.code, {this.recommended = false});

  final VaccineCode code;
  final bool recommended;
}

/// Étape du calendrier : visite attendue entre les âges [from] (inclus) et
/// [until] (exclu).
final class MedicalStage {
  const MedicalStage({
    required this.id,
    required this.from,
    required this.until,
    this.hasExam = true,
    this.hasCertificate = false,
    this.vaccines = const [],
  });

  final MedicalStageId id;
  final AgeOffset from;
  final AgeOffset until;
  final bool hasExam;
  final bool hasCertificate;
  final List<ScheduledVaccine> vaccines;

  bool get hasVaccines => vaccines.isNotEmpty;
}
```

```dart
// lib/features/health/domain/reference/medical_schedule.dart
// Examens : service-public.gouv.fr F35490 (vérifié le 29 juillet 2026) et ameli.fr
// « 20 examens de suivi médical de l'enfant et de l'adolescent » (11 août 2025).
// Vaccins : ameli.fr « Les vaccins obligatoires chez le nourrisson » (21 mai 2026),
// calendrier des vaccinations 2026. « À N mois » = fenêtre [N mois, N+1 mois).

import 'package:colette/features/health/domain/entities/age_offset.dart';
import 'package:colette/features/health/domain/entities/medical_stage.dart';
import 'package:colette/features/health/domain/entities/vaccine_code.dart';

/// Étapes de la naissance à 3 ans, dans l'ordre de [MedicalStageId].
const medicalSchedule = <MedicalStage>[
  MedicalStage(
    id: MedicalStageId.day8,
    from: AgeOffset.days(0),
    until: AgeOffset.days(8),
    hasCertificate: true,
  ),
  MedicalStage(
    id: MedicalStageId.week2,
    from: AgeOffset.days(8),
    until: AgeOffset.days(15),
  ),
  MedicalStage(
    id: MedicalStageId.m1,
    from: AgeOffset.months(1),
    until: AgeOffset.months(2),
  ),
  MedicalStage(
    id: MedicalStageId.m2,
    from: AgeOffset.months(2),
    until: AgeOffset.months(3),
    vaccines: [
      ScheduledVaccine(VaccineCode.hexavalent),
      ScheduledVaccine(VaccineCode.pneumococcal),
      ScheduledVaccine(VaccineCode.rotavirus, recommended: true),
    ],
  ),
  MedicalStage(
    id: MedicalStageId.m3,
    from: AgeOffset.months(3),
    until: AgeOffset.months(4),
    vaccines: [
      ScheduledVaccine(VaccineCode.menB),
      ScheduledVaccine(VaccineCode.rotavirus, recommended: true),
    ],
  ),
  MedicalStage(
    id: MedicalStageId.m4,
    from: AgeOffset.months(4),
    until: AgeOffset.months(5),
    vaccines: [
      ScheduledVaccine(VaccineCode.hexavalent),
      ScheduledVaccine(VaccineCode.pneumococcal),
      ScheduledVaccine(VaccineCode.rotavirus, recommended: true),
    ],
  ),
  MedicalStage(
    id: MedicalStageId.m5,
    from: AgeOffset.months(5),
    until: AgeOffset.months(6),
    vaccines: [ScheduledVaccine(VaccineCode.menB)],
  ),
  MedicalStage(
    id: MedicalStageId.m6,
    from: AgeOffset.months(6),
    until: AgeOffset.months(7),
    hasExam: false,
    vaccines: [ScheduledVaccine(VaccineCode.menACWY)],
  ),
  MedicalStage(
    id: MedicalStageId.m8,
    from: AgeOffset.months(8),
    until: AgeOffset.months(9),
    hasCertificate: true,
  ),
  MedicalStage(
    id: MedicalStageId.m11,
    from: AgeOffset.months(11),
    until: AgeOffset.months(12),
    vaccines: [
      ScheduledVaccine(VaccineCode.hexavalent),
      ScheduledVaccine(VaccineCode.pneumococcal),
    ],
  ),
  MedicalStage(
    id: MedicalStageId.m12,
    from: AgeOffset.months(12),
    until: AgeOffset.months(13),
    vaccines: [
      ScheduledVaccine(VaccineCode.mmr),
      ScheduledVaccine(VaccineCode.menACWY),
      ScheduledVaccine(VaccineCode.menB),
    ],
  ),
  MedicalStage(
    id: MedicalStageId.m16,
    from: AgeOffset.months(16),
    until: AgeOffset.months(19),
    vaccines: [ScheduledVaccine(VaccineCode.mmr)],
  ),
  MedicalStage(
    id: MedicalStageId.m23,
    from: AgeOffset.months(23),
    until: AgeOffset.months(25),
    hasCertificate: true,
  ),
  MedicalStage(
    id: MedicalStageId.y2,
    from: AgeOffset.months(25),
    until: AgeOffset.months(36),
  ),
  MedicalStage(
    id: MedicalStageId.y3,
    from: AgeOffset.months(36),
    until: AgeOffset.months(48),
  ),
];

/// Étape de [id].
MedicalStage stageById(MedicalStageId id) => medicalSchedule[id.index];
```

- [ ] **Step 4: Sources vérifiées**

Vérification faite par le contrôleur dans un navigateur, le 2026-09-23 :
- service-public.gouv.fr F35490 (« vérifié le 29 juillet 2026 ») : 8 jours (1er certificat), 2e semaine, 5 examens entre 1 et 5 mois, 8 mois (2e certificat), 11 mois, 12 mois, 16-18 mois, 23-24 mois (3e certificat), puis 1 par an de 2 à 5 ans ;
- ameli.fr, examens (11 août 2025) : « à 1 mois, 2 mois, 3 mois, 4 mois, 5 mois, 8 mois, 11 mois, 12 mois, entre le 16e et le 18e mois, entre le 23e et le 24e mois, à 2 ans, 3 ans » ;
- ameli.fr, vaccins (21 mai 2026) : hexavalent et pneumocoque à 2, 4 et 11 mois ; méningocoque B à 3, 5 et 12 mois ; ACWY à 6 et 12 mois ; ROR à 12 mois et entre 16 et 18 mois.

Rien à refaire à cette étape.

- [ ] **Step 5: Run tests to verify they pass**

Run: `flutter test test/features/health/domain`
Expected: PASS.

- [ ] **Step 6: Commit**

```bash
dart format lib test && dart analyze
git add lib/features/health/domain test/features/health/domain
git commit -m "feat: calendrier des examens obligatoires et des vaccins du nourrisson"
```

---

### Task 2 : visites, statuts et frise

**Files:**
- Create: `lib/features/health/domain/entities/given_vaccine.dart`, `lib/features/health/domain/entities/medical_visit.dart`, `lib/features/health/domain/entities/medical_stage_status.dart`, `lib/features/health/domain/entities/medical_timeline.dart`, `lib/features/health/domain/use_cases/compute_medical_stage_status.dart`, `lib/features/health/domain/use_cases/compute_medical_timeline.dart`
- Test: `test/features/health/domain/compute_medical_stage_status_test.dart`, `test/features/health/domain/compute_medical_timeline_test.dart`, `test/features/health/health_factories.dart`

- [ ] **Step 1: Test helper**

```dart
// test/features/health/health_factories.dart
import 'package:colette/features/health/domain/entities/given_vaccine.dart';
import 'package:colette/features/health/domain/entities/medical_stage.dart';
import 'package:colette/features/health/domain/entities/medical_visit.dart';
import 'package:colette/features/health/domain/entities/vaccine_code.dart';

/// Visite de test, horodatée au 1er septembre 2026 par `device-a`.
MedicalVisit makeVisit(
  MedicalStageId stageId, {
  DateTime? appointmentAt,
  String? practitioner,
  DateTime? doneAt,
  String? note,
  Map<VaccineCode, GivenVaccine> vaccines = const {},
}) => MedicalVisit(
  stageId: stageId,
  appointmentAt: appointmentAt,
  practitioner: practitioner,
  doneAt: doneAt,
  note: note,
  vaccines: vaccines,
  updatedAt: DateTime(2026, 9, 1),
  updatedByDeviceId: 'device-a',
);
```

- [ ] **Step 2: Write the failing tests**

```dart
// test/features/health/domain/compute_medical_stage_status_test.dart
import 'package:colette/features/health/domain/entities/medical_stage.dart';
import 'package:colette/features/health/domain/entities/medical_stage_status.dart';
import 'package:colette/features/health/domain/entities/medical_visit.dart';
import 'package:colette/features/health/domain/reference/medical_schedule.dart';
import 'package:colette/features/health/domain/use_cases/compute_medical_stage_status.dart';
import 'package:flutter_test/flutter_test.dart';

import '../health_factories.dart';

void main() {
  const compute = ComputeMedicalStageStatus();
  final birth = DateTime(2026, 9, 1);
  final m2 = stageById(MedicalStageId.m2); // [1er nov., 1er déc.)

  MedicalStageStatus status(DateTime now, [MedicalVisit? visit]) =>
      compute(stage: m2, visit: visit, birthDate: birth, now: now);

  test('upcoming jusqu\'à 14 jours avant le début', () {
    expect(status(DateTime(2026, 10, 17, 23, 59)), MedicalStageStatus.upcoming);
  });

  test('due à partir de 14 jours avant le début et pendant la fenêtre', () {
    expect(status(DateTime(2026, 10, 18)), MedicalStageStatus.due);
    expect(status(DateTime(2026, 11, 30, 23)), MedicalStageStatus.due);
  });

  test('late dès la fin de la fenêtre', () {
    expect(status(DateTime(2026, 12, 1)), MedicalStageStatus.late);
  });

  test('scheduled avec un RDV futur, même en retard', () {
    final visit = makeVisit(
      MedicalStageId.m2,
      appointmentAt: DateTime(2026, 12, 3, 10),
    );
    expect(status(DateTime(2026, 12, 2), visit), MedicalStageStatus.scheduled);
  });

  test('appointmentPassed quand le RDV est passé sans visite marquée', () {
    final visit = makeVisit(
      MedicalStageId.m2,
      appointmentAt: DateTime(2026, 11, 3, 10),
    );
    expect(
      status(DateTime(2026, 11, 3, 10, 1), visit),
      MedicalStageStatus.appointmentPassed,
    );
  });

  test('done dès que la visite est marquée faite', () {
    final visit = makeVisit(
      MedicalStageId.m2,
      appointmentAt: DateTime(2026, 11, 3, 10),
      doneAt: DateTime(2026, 11, 3, 10),
    );
    expect(status(DateTime(2027), visit), MedicalStageStatus.done);
  });
}
```

```dart
// test/features/health/domain/compute_medical_timeline_test.dart
import 'package:colette/features/health/domain/entities/medical_stage.dart';
import 'package:colette/features/health/domain/entities/medical_stage_status.dart';
import 'package:colette/features/health/domain/use_cases/compute_medical_timeline.dart';
import 'package:flutter_test/flutter_test.dart';

import '../health_factories.dart';

void main() {
  const compute = ComputeMedicalTimeline();
  final birth = DateTime(2026, 9, 1);

  test('une entrée par étape, avec dates absolues et visite', () {
    final visit = makeVisit(
      MedicalStageId.day8,
      doneAt: DateTime(2026, 9, 4),
    );
    final timeline = compute(
      birthDate: birth,
      visits: [visit],
      now: DateTime(2026, 9, 10),
    );
    expect(timeline.entries, hasLength(MedicalStageId.values.length));
    final day8 = timeline.entries.first;
    expect(day8.stage.id, MedicalStageId.day8);
    expect(day8.visit, visit);
    expect(day8.status, MedicalStageStatus.done);
    final week2 = timeline.entries[1];
    expect(week2.dueFrom, DateTime(2026, 9, 9));
    expect(week2.dueUntil, DateTime(2026, 9, 16));
    expect(week2.status, MedicalStageStatus.due);
  });

  test('next : première étape non faite', () {
    final timeline = compute(
      birthDate: birth,
      visits: [
        makeVisit(MedicalStageId.day8, doneAt: DateTime(2026, 9, 4)),
        makeVisit(MedicalStageId.week2, doneAt: DateTime(2026, 9, 12)),
      ],
      now: DateTime(2026, 9, 20),
    );
    expect(timeline.next!.stage.id, MedicalStageId.m1);
    expect(timeline.next!.status, MedicalStageStatus.due);
  });

  test('next : null quand tout est fait', () {
    final timeline = compute(
      birthDate: birth,
      visits: [
        for (final id in MedicalStageId.values)
          makeVisit(id, doneAt: DateTime(2026, 9, 2)),
      ],
      now: DateTime(2030),
    );
    expect(timeline.next, isNull);
  });
}
```

- [ ] **Step 3: Run tests to verify they fail**

Run: `flutter test test/features/health/domain`
Expected: FAIL (fichiers introuvables).

- [ ] **Step 4: Implement**

```dart
// lib/features/health/domain/entities/given_vaccine.dart
import 'package:freezed_annotation/freezed_annotation.dart';

part 'given_vaccine.freezed.dart';

/// Injection reçue : date, nom commercial et numéro de lot facultatifs.
@freezed
abstract class GivenVaccine with _$GivenVaccine {
  const factory GivenVaccine({
    required DateTime givenAt,
    String? brand,
    String? lot,
  }) = _GivenVaccine;
}
```

```dart
// lib/features/health/domain/entities/medical_visit.dart
import 'package:colette/features/health/domain/entities/given_vaccine.dart';
import 'package:colette/features/health/domain/entities/medical_stage.dart';
import 'package:colette/features/health/domain/entities/vaccine_code.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

part 'medical_visit.freezed.dart';

/// Ce que les parents ont saisi pour une étape : RDV, injections, visite faite.
@freezed
abstract class MedicalVisit with _$MedicalVisit {
  const MedicalVisit._();

  const factory MedicalVisit({
    required MedicalStageId stageId,
    DateTime? appointmentAt,
    String? practitioner,
    DateTime? doneAt,
    String? note,
    @Default(<VaccineCode, GivenVaccine>{})
    Map<VaccineCode, GivenVaccine> vaccines,
    required DateTime updatedAt,
    required String updatedByDeviceId,
  }) = _MedicalVisit;

  /// Rien de saisi : ni RDV, ni visite faite, ni injection, ni note.
  bool get isEmpty =>
      appointmentAt == null &&
      doneAt == null &&
      vaccines.isEmpty &&
      (note?.trim().isEmpty ?? true);
}
```

```dart
// lib/features/health/domain/entities/medical_stage_status.dart
/// Où en est une étape du calendrier.
enum MedicalStageStatus {
  done,

  /// RDV passé, visite pas encore marquée faite.
  appointmentPassed,
  scheduled,
  late,
  due,
  upcoming,
}
```

```dart
// lib/features/health/domain/entities/medical_timeline.dart
import 'package:colette/features/health/domain/entities/medical_stage.dart';
import 'package:colette/features/health/domain/entities/medical_stage_status.dart';
import 'package:colette/features/health/domain/entities/medical_visit.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

part 'medical_timeline.freezed.dart';

/// Une étape datée pour ce bébé, avec son statut et sa visite éventuelle.
@freezed
abstract class MedicalTimelineEntry with _$MedicalTimelineEntry {
  const factory MedicalTimelineEntry({
    required MedicalStage stage,
    required DateTime dueFrom,
    required DateTime dueUntil,
    required MedicalStageStatus status,
    MedicalVisit? visit,
  }) = _MedicalTimelineEntry;
}

/// Toutes les étapes du calendrier, dans l'ordre des âges.
@freezed
abstract class MedicalTimeline with _$MedicalTimeline {
  const MedicalTimeline._();

  const factory MedicalTimeline({
    required List<MedicalTimelineEntry> entries,
  }) = _MedicalTimeline;

  /// Première étape non faite, ou `null`.
  MedicalTimelineEntry? get next => entries
      .where((e) => e.status != MedicalStageStatus.done)
      .firstOrNull;
}
```

```dart
// lib/features/health/domain/use_cases/compute_medical_stage_status.dart
import 'package:colette/features/health/domain/entities/medical_stage.dart';
import 'package:colette/features/health/domain/entities/medical_stage_status.dart';
import 'package:colette/features/health/domain/entities/medical_visit.dart';

/// Statut d'une étape à [now] : faite, RDV passé, programmée, en retard, à faire, à venir.
class ComputeMedicalStageStatus {
  const ComputeMedicalStageStatus();

  /// Une étape passe « à faire » ce nombre de jours avant le début de sa fenêtre.
  static const reminderLeadDays = 14;

  MedicalStageStatus call({
    required MedicalStage stage,
    required MedicalVisit? visit,
    required DateTime birthDate,
    required DateTime now,
  }) {
    if (visit?.doneAt != null) return MedicalStageStatus.done;
    if (visit?.appointmentAt case final appointmentAt?) {
      return appointmentAt.isBefore(now)
          ? MedicalStageStatus.appointmentPassed
          : MedicalStageStatus.scheduled;
    }
    if (!now.isBefore(stage.until.from(birthDate))) {
      return MedicalStageStatus.late;
    }
    final dueFrom = stage.from.from(birthDate);
    final remindFrom = DateTime(
      dueFrom.year,
      dueFrom.month,
      dueFrom.day - reminderLeadDays,
    );
    return now.isBefore(remindFrom)
        ? MedicalStageStatus.upcoming
        : MedicalStageStatus.due;
  }
}
```

```dart
// lib/features/health/domain/use_cases/compute_medical_timeline.dart
import 'package:colette/features/health/domain/entities/medical_stage.dart';
import 'package:colette/features/health/domain/entities/medical_timeline.dart';
import 'package:colette/features/health/domain/entities/medical_visit.dart';
import 'package:colette/features/health/domain/reference/medical_schedule.dart';
import 'package:colette/features/health/domain/use_cases/compute_medical_stage_status.dart';

/// Date et statut de chaque étape du calendrier pour un bébé.
class ComputeMedicalTimeline {
  const ComputeMedicalTimeline();

  MedicalTimeline call({
    required DateTime birthDate,
    required List<MedicalVisit> visits,
    required DateTime now,
    List<MedicalStage> schedule = medicalSchedule,
  }) {
    final byStage = {for (final visit in visits) visit.stageId: visit};
    return MedicalTimeline(
      entries: [
        for (final stage in schedule)
          MedicalTimelineEntry(
            stage: stage,
            dueFrom: stage.from.from(birthDate),
            dueUntil: stage.until.from(birthDate),
            status: const ComputeMedicalStageStatus()(
              stage: stage,
              visit: byStage[stage.id],
              birthDate: birthDate,
              now: now,
            ),
            visit: byStage[stage.id],
          ),
      ],
    );
  }
}
```

- [ ] **Step 5: Generate and run tests**

```bash
dart run build_runner build -d
flutter test test/features/health/domain
```
Expected: PASS.

- [ ] **Step 6: Commit**

```bash
dart format lib test && dart analyze
git add lib/features/health/domain test/features/health
git commit -m "feat: visites médicales, statut des étapes et frise du suivi"
```

---

### Task 3 : validation d'une visite et snapshot des rappels

**Files:**
- Create: `lib/features/health/domain/use_cases/validate_medical_visit.dart`, `lib/features/health/domain/entities/medical_reminder_snapshot.dart`, `lib/features/health/domain/use_cases/compute_medical_reminder_snapshot.dart`
- Modify: `lib/core/result/failure.dart` (enum `ValidationReason`), `lib/core/ui/failure_message.dart`, `lib/l10n/app_fr.arb`
- Test: `test/features/health/domain/validate_medical_visit_test.dart`, `test/features/health/domain/compute_medical_reminder_snapshot_test.dart`

- [ ] **Step 1: Write the failing tests**

```dart
// test/features/health/domain/validate_medical_visit_test.dart
import 'package:colette/core/result/either_extensions.dart';
import 'package:colette/core/result/failure.dart';
import 'package:colette/features/health/domain/entities/given_vaccine.dart';
import 'package:colette/features/health/domain/entities/medical_stage.dart';
import 'package:colette/features/health/domain/entities/medical_visit.dart';
import 'package:colette/features/health/domain/entities/vaccine_code.dart';
import 'package:colette/features/health/domain/use_cases/validate_medical_visit.dart';
import 'package:flutter_test/flutter_test.dart';

import '../health_factories.dart';

void main() {
  const validate = ValidateMedicalVisit();
  final birth = DateTime(2026, 9, 1);
  final now = DateTime(2026, 11, 10, 12);

  ValidationReason? reasonOf(MedicalVisit visit) =>
      validate(visit, birthDate: birth, now: now).leftOrNull?.reason;

  test('accepte un RDV futur', () {
    expect(
      reasonOf(
        makeVisit(MedicalStageId.m2, appointmentAt: DateTime(2026, 12, 1, 9)),
      ),
      isNull,
    );
  });

  test('refuse un RDV avant la naissance', () {
    expect(
      reasonOf(
        makeVisit(MedicalStageId.day8, appointmentAt: DateTime(2026, 8, 31)),
      ),
      ValidationReason.medicalDateBeforeBirth,
    );
  });

  test('refuse une visite faite dans le futur, tolère 5 min', () {
    expect(
      reasonOf(
        makeVisit(MedicalStageId.m2, doneAt: now.add(const Duration(minutes: 5))),
      ),
      isNull,
    );
    expect(
      reasonOf(makeVisit(MedicalStageId.m2, doneAt: DateTime(2026, 11, 11))),
      ValidationReason.medicalDateInFuture,
    );
  });

  test('refuse une injection datée dans le futur ou avant la naissance', () {
    expect(
      reasonOf(
        makeVisit(
          MedicalStageId.m2,
          vaccines: {
            VaccineCode.hexavalent: GivenVaccine(givenAt: DateTime(2026, 11, 12)),
          },
        ),
      ),
      ValidationReason.medicalDateInFuture,
    );
    expect(
      reasonOf(
        makeVisit(
          MedicalStageId.m2,
          vaccines: {
            VaccineCode.hexavalent: GivenVaccine(givenAt: DateTime(2026, 8, 1)),
          },
        ),
      ),
      ValidationReason.medicalDateBeforeBirth,
    );
  });
}
```

```dart
// test/features/health/domain/compute_medical_reminder_snapshot_test.dart
import 'package:colette/features/health/domain/entities/medical_stage.dart';
import 'package:colette/features/health/domain/use_cases/compute_medical_reminder_snapshot.dart';
import 'package:colette/features/health/domain/use_cases/compute_medical_timeline.dart';
import 'package:flutter_test/flutter_test.dart';

import '../health_factories.dart';

void main() {
  final birth = DateTime(2026, 9, 1);
  final now = DateTime(2026, 10, 20);

  test('les 3 premières étapes non faites, avec leurs dates et le RDV', () {
    final timeline = const ComputeMedicalTimeline()(
      birthDate: birth,
      visits: [
        makeVisit(MedicalStageId.day8, doneAt: DateTime(2026, 9, 4)),
        makeVisit(MedicalStageId.week2, doneAt: DateTime(2026, 9, 12)),
        makeVisit(MedicalStageId.m2, appointmentAt: DateTime(2026, 11, 3, 10)),
      ],
      now: now,
    );
    final snapshot = const ComputeMedicalReminderSnapshot()(
      timeline: timeline,
      now: now,
    );
    expect(snapshot.computedAt, now);
    expect(snapshot.stages.map((s) => s.stageId), [
      MedicalStageId.m1,
      MedicalStageId.m2,
      MedicalStageId.m3,
    ]);
    expect(snapshot.stages[0].hasAppointment, isFalse);
    expect(snapshot.stages[1].hasAppointment, isTrue);
    expect(snapshot.stages[2].dueFrom, DateTime(2026, 12, 1));
    expect(snapshot.stages[2].dueUntil, DateTime(2027, 1, 1));
  });
}
```

- [ ] **Step 2: Run tests to verify they fail**

Run: `flutter test test/features/health/domain`
Expected: FAIL.

- [ ] **Step 3: Raisons de validation et messages**

Dans `lib/core/result/failure.dart`, ajouter à la fin de l'enum `ValidationReason` (après la dernière valeur existante) :

```dart
  medicalDateBeforeBirth,
  medicalDateInFuture,
```

Dans `lib/l10n/app_fr.arb`, avant l'accolade finale (ajouter une virgule après la dernière entrée existante) :

```json
  "errorMedicalDateBeforeBirth": "Cette date précède la naissance.",
  "errorMedicalDateInFuture": "Une visite ou une injection ne peut pas être datée dans le futur."
```

Dans `lib/core/ui/failure_message.dart`, dans le `switch (reason)` de `ValidationFailure`, ajouter :

```dart
    ValidationReason.medicalDateBeforeBirth => s.errorMedicalDateBeforeBirth,
    ValidationReason.medicalDateInFuture => s.errorMedicalDateInFuture,
```

Puis `flutter gen-l10n`.

- [ ] **Step 4: Implement**

```dart
// lib/features/health/domain/use_cases/validate_medical_visit.dart
import 'package:colette/core/dates/date_extensions.dart';
import 'package:colette/core/result/failure.dart';
import 'package:colette/features/health/domain/entities/medical_visit.dart';
import 'package:fpdart/fpdart.dart';

/// Règles de validité d'une visite avant enregistrement.
class ValidateMedicalVisit {
  const ValidateMedicalVisit();

  static const futureTolerance = Duration(minutes: 5);

  Either<ValidationFailure, MedicalVisit> call(
    MedicalVisit visit, {
    required DateTime birthDate,
    required DateTime now,
  }) {
    final birthDay = birthDate.dateOnly;
    final latest = now.add(futureTolerance);
    final past = [visit.doneAt, for (final v in visit.vaccines.values) v.givenAt]
        .nonNulls;
    final all = [visit.appointmentAt, ...past].nonNulls;
    if (all.any((date) => date.isBefore(birthDay))) {
      return left(
        const ValidationFailure(ValidationReason.medicalDateBeforeBirth),
      );
    }
    if (past.any((date) => date.isAfter(latest))) {
      return left(
        const ValidationFailure(ValidationReason.medicalDateInFuture),
      );
    }
    return right(visit);
  }
}
```

```dart
// lib/features/health/domain/entities/medical_reminder_snapshot.dart
import 'package:colette/features/health/domain/entities/medical_stage.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

part 'medical_reminder_snapshot.freezed.dart';

/// Étape à rappeler par le digest du matin.
@freezed
abstract class MedicalReminderStage with _$MedicalReminderStage {
  const factory MedicalReminderStage({
    required MedicalStageId stageId,
    required DateTime dueFrom,
    required DateTime dueUntil,
    required bool hasAppointment,
  }) = _MedicalReminderStage;
}

/// Prochaines étapes non faites, écrites dans le foyer pour la Cloud Function.
@freezed
abstract class MedicalReminderSnapshot with _$MedicalReminderSnapshot {
  const factory MedicalReminderSnapshot({
    required List<MedicalReminderStage> stages,
    required DateTime computedAt,
  }) = _MedicalReminderSnapshot;
}
```

```dart
// lib/features/health/domain/use_cases/compute_medical_reminder_snapshot.dart
import 'package:colette/features/health/domain/entities/medical_reminder_snapshot.dart';
import 'package:colette/features/health/domain/entities/medical_stage_status.dart';
import 'package:colette/features/health/domain/entities/medical_timeline.dart';

/// Les [count] premières étapes non faites de la frise.
class ComputeMedicalReminderSnapshot {
  const ComputeMedicalReminderSnapshot();

  static const count = 3;

  MedicalReminderSnapshot call({
    required MedicalTimeline timeline,
    required DateTime now,
  }) => MedicalReminderSnapshot(
    stages: [
      for (final entry in timeline.entries
          .where((e) => e.status != MedicalStageStatus.done)
          .take(count))
        MedicalReminderStage(
          stageId: entry.stage.id,
          dueFrom: entry.dueFrom,
          dueUntil: entry.dueUntil,
          hasAppointment: entry.visit?.appointmentAt != null,
        ),
    ],
    computedAt: now,
  );
}
```

- [ ] **Step 5: Generate and run tests**

```bash
dart run build_runner build -d
flutter test test/features/health test/core
```
Expected: PASS (dont `failure_message_test`, qui parcourt toutes les raisons).

- [ ] **Step 6: Commit**

```bash
dart format lib test && dart analyze && flutter test
git add lib/features/health/domain lib/core/result/failure.dart lib/core/ui/failure_message.dart lib/l10n/app_fr.arb test/features/health
git commit -m "feat: validation des visites médicales et snapshot des rappels"
```

---

### Task 4 : réconciliation avec le Calendrier iOS

**Files:**
- Create: `lib/features/health/domain/entities/calendar_event.dart`, `lib/features/health/domain/entities/calendar_action.dart`, `lib/features/health/domain/use_cases/reconcile_calendar.dart`
- Test: `test/features/health/domain/reconcile_calendar_test.dart`

- [ ] **Step 1: Write the failing test**

```dart
// test/features/health/domain/reconcile_calendar_test.dart
import 'package:colette/features/health/domain/entities/calendar_action.dart';
import 'package:colette/features/health/domain/entities/calendar_event.dart';
import 'package:colette/features/health/domain/entities/medical_stage.dart';
import 'package:colette/features/health/domain/entities/medical_visit.dart';
import 'package:colette/features/health/domain/use_cases/reconcile_calendar.dart';
import 'package:flutter_test/flutter_test.dart';

import '../health_factories.dart';

void main() {
  const reconcile = ReconcileCalendar();
  final now = DateTime(2026, 10, 20, 12);
  final at = DateTime(2026, 11, 3, 10);
  String titleOf(MedicalStageId id) => 'Titre ${id.name}';

  CalendarEvent event(
    String eventId,
    MedicalStageId stageId, {
    DateTime? start,
    String? title,
    String? notes,
  }) {
    final begin = start ?? at;
    return CalendarEvent(
      eventId: eventId,
      url: ReconcileCalendar.urlOf(stageId),
      title: title ?? titleOf(stageId),
      start: begin,
      end: begin.add(ReconcileCalendar.eventDuration),
      notes: notes,
    );
  }

  List<CalendarAction> run(
    List<MedicalVisit> visits,
    List<CalendarEvent> events,
  ) => reconcile(visits: visits, events: events, titleOf: titleOf, now: now);

  test('crée l\'événement d\'un RDV sans événement', () {
    final actions = run([
      makeVisit(MedicalStageId.m2, appointmentAt: at, practitioner: 'Dr Martin'),
    ], []);
    expect(actions, [
      CalendarAction.create(
        CalendarEventDraft(
          url: 'colette://rdv/m2',
          title: 'Titre m2',
          start: at,
          end: at.add(const Duration(minutes: 30)),
          notes: 'Dr Martin',
          alarms: [DateTime(2026, 11, 2, 18), DateTime(2026, 11, 3, 9)],
        ),
      ),
    ]);
  });

  test('rien à faire si l\'événement est déjà à jour', () {
    expect(
      run(
        [makeVisit(MedicalStageId.m2, appointmentAt: at)],
        [event('e1', MedicalStageId.m2)],
      ),
      isEmpty,
    );
  });

  test('met à jour un événement dont l\'heure, le titre ou les notes diffèrent', () {
    final moved = run(
      [makeVisit(MedicalStageId.m2, appointmentAt: at)],
      [event('e1', MedicalStageId.m2, start: DateTime(2026, 11, 2, 9))],
    );
    expect(moved.single, isA<UpdateCalendarEvent>());
    expect((moved.single as UpdateCalendarEvent).eventId, 'e1');
    final renamed = run(
      [makeVisit(MedicalStageId.m2, appointmentAt: at)],
      [event('e1', MedicalStageId.m2, title: 'Ancien')],
    );
    expect(renamed.single, isA<UpdateCalendarEvent>());
    final newDoctor = run(
      [makeVisit(MedicalStageId.m2, appointmentAt: at, practitioner: 'Dr B')],
      [event('e1', MedicalStageId.m2, notes: 'Dr A')],
    );
    expect(newDoctor.single, isA<UpdateCalendarEvent>());
  });

  test('supprime les doublons en gardant le premier', () {
    expect(
      run(
        [makeVisit(MedicalStageId.m2, appointmentAt: at)],
        [event('e1', MedicalStageId.m2), event('e2', MedicalStageId.m2)],
      ),
      [const CalendarAction.delete('e2')],
    );
  });

  test('supprime l\'événement d\'un RDV retiré ou d\'une visite faite', () {
    expect(run([], [event('e1', MedicalStageId.m2)]), [
      const CalendarAction.delete('e1'),
    ]);
    expect(
      run(
        [makeVisit(MedicalStageId.m2, appointmentAt: at, doneAt: now)],
        [event('e1', MedicalStageId.m2)],
      ),
      [const CalendarAction.delete('e1')],
    );
  });

  test('garde un RDV d\'hier, ignore un RDV plus ancien', () {
    final yesterday = DateTime(2026, 10, 19, 9);
    expect(
      run(
        [makeVisit(MedicalStageId.week2, appointmentAt: yesterday)],
        [event('e1', MedicalStageId.week2, start: yesterday)],
      ),
      isEmpty,
    );
    expect(
      run([makeVisit(MedicalStageId.day8, appointmentAt: DateTime(2026, 9, 3))], []),
      isEmpty,
    );
  });

  test('fenêtre de lecture : minuit d\'hier à deux ans', () {
    expect(ReconcileCalendar.windowStart(now), DateTime(2026, 10, 19));
    expect(ReconcileCalendar.windowEnd(now), DateTime(2028, 10, 20));
  });
}
```

- [ ] **Step 2: Run test to verify it fails**

Run: `flutter test test/features/health/domain/reconcile_calendar_test.dart`
Expected: FAIL.

- [ ] **Step 3: Implement**

```dart
// lib/features/health/domain/entities/calendar_event.dart
import 'package:freezed_annotation/freezed_annotation.dart';

part 'calendar_event.freezed.dart';

/// Événement Colette lu dans le Calendrier iOS (URL `colette://rdv/…`).
@freezed
abstract class CalendarEvent with _$CalendarEvent {
  const factory CalendarEvent({
    required String eventId,
    required String url,
    required String title,
    required DateTime start,
    required DateTime end,
    String? notes,
  }) = _CalendarEvent;
}

/// Contenu voulu d'un événement ; [alarms] : instants des alertes.
@freezed
abstract class CalendarEventDraft with _$CalendarEventDraft {
  const factory CalendarEventDraft({
    required String url,
    required String title,
    required DateTime start,
    required DateTime end,
    String? notes,
    @Default(<DateTime>[]) List<DateTime> alarms,
  }) = _CalendarEventDraft;
}
```

```dart
// lib/features/health/domain/entities/calendar_action.dart
import 'package:colette/features/health/domain/entities/calendar_event.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

part 'calendar_action.freezed.dart';

/// Opération à exécuter sur le Calendrier iOS.
@freezed
sealed class CalendarAction with _$CalendarAction {
  const factory CalendarAction.create(CalendarEventDraft draft) =
      CreateCalendarEvent;
  const factory CalendarAction.update(
    String eventId,
    CalendarEventDraft draft,
  ) = UpdateCalendarEvent;
  const factory CalendarAction.delete(String eventId) = DeleteCalendarEvent;
}
```

```dart
// lib/features/health/domain/use_cases/reconcile_calendar.dart
import 'package:colette/features/health/domain/entities/calendar_action.dart';
import 'package:colette/features/health/domain/entities/calendar_event.dart';
import 'package:colette/features/health/domain/entities/medical_stage.dart';
import 'package:colette/features/health/domain/entities/medical_visit.dart';

/// Actions pour qu'un calendrier contienne exactement un événement par RDV à venir.
class ReconcileCalendar {
  const ReconcileCalendar();

  static const urlPrefix = 'colette://rdv/';
  static const eventDuration = Duration(minutes: 30);

  /// Heure de l'alerte de la veille.
  static const eveAlarmHour = 18;
  static const lastAlarmBefore = Duration(hours: 1);

  static String urlOf(MedicalStageId id) => '$urlPrefix${id.name}';

  /// Début de la fenêtre lue et gérée : minuit d'hier.
  static DateTime windowStart(DateTime now) =>
      DateTime(now.year, now.month, now.day - 1);

  /// Fin de la fenêtre lue : deux ans plus tard.
  static DateTime windowEnd(DateTime now) =>
      DateTime(now.year + 2, now.month, now.day);

  List<CalendarAction> call({
    required List<MedicalVisit> visits,
    required List<CalendarEvent> events,
    required String Function(MedicalStageId id) titleOf,
    required DateTime now,
  }) {
    final from = windowStart(now);
    final wanted = <String, CalendarEventDraft>{
      for (final visit in visits)
        if (visit.appointmentAt case final at?
            when visit.doneAt == null && !at.isBefore(from))
          urlOf(visit.stageId): _draft(visit, at, titleOf(visit.stageId)),
    };
    final byUrl = <String, List<CalendarEvent>>{};
    for (final event in events) {
      (byUrl[event.url] ??= []).add(event);
    }
    final actions = <CalendarAction>[];
    for (final MapEntry(key: url, value: draft) in wanted.entries) {
      final existing = byUrl.remove(url) ?? const <CalendarEvent>[];
      if (existing.isEmpty) {
        actions.add(CalendarAction.create(draft));
        continue;
      }
      final kept = existing.first;
      if (_differs(kept, draft)) {
        actions.add(CalendarAction.update(kept.eventId, draft));
      }
      for (final extra in existing.skip(1)) {
        actions.add(CalendarAction.delete(extra.eventId));
      }
    }
    for (final orphan in byUrl.values.expand((e) => e)) {
      actions.add(CalendarAction.delete(orphan.eventId));
    }
    return actions;
  }

  static CalendarEventDraft _draft(
    MedicalVisit visit,
    DateTime at,
    String title,
  ) => CalendarEventDraft(
    url: urlOf(visit.stageId),
    title: title,
    start: at,
    end: at.add(eventDuration),
    notes: visit.practitioner,
    alarms: [
      DateTime(at.year, at.month, at.day - 1, eveAlarmHour),
      at.subtract(lastAlarmBefore),
    ],
  );

  /// Comparaison à la milliseconde : Firestore et EventKit n'ont pas la même précision.
  static bool _differs(CalendarEvent event, CalendarEventDraft draft) =>
      event.title != draft.title ||
      (event.notes ?? '') != (draft.notes ?? '') ||
      event.start.millisecondsSinceEpoch != draft.start.millisecondsSinceEpoch ||
      event.end.millisecondsSinceEpoch != draft.end.millisecondsSinceEpoch;
}
```

- [ ] **Step 4: Generate and run test**

```bash
dart run build_runner build -d
flutter test test/features/health/domain/reconcile_calendar_test.dart
```
Expected: PASS.

- [ ] **Step 5: Commit**

```bash
dart format lib test && dart analyze
git add lib/features/health/domain test/features/health/domain/reconcile_calendar_test.dart
git commit -m "feat: réconciliation des RDV médicaux avec le Calendrier iOS"
```

---

### Task 5 : persistance Firestore des visites et du snapshot

**Files:**
- Create: `lib/features/health/domain/repositories/medical_repository.dart`, `lib/features/health/data/dtos/medical_visit_dto.dart`, `lib/features/health/data/dtos/medical_reminder_snapshot_dto.dart`, `lib/features/health/data/repositories/firestore_medical_repository.dart`
- Modify: `lib/core/firebase/firestore_paths.dart`
- Test: `test/features/health/data/firestore_medical_repository_test.dart`

- [ ] **Step 1: Write the failing test**

```dart
// test/features/health/data/firestore_medical_repository_test.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:colette/features/health/data/repositories/firestore_medical_repository.dart';
import 'package:colette/features/health/domain/entities/given_vaccine.dart';
import 'package:colette/features/health/domain/entities/medical_reminder_snapshot.dart';
import 'package:colette/features/health/domain/entities/medical_stage.dart';
import 'package:colette/features/health/domain/entities/vaccine_code.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';

import '../health_factories.dart';

void main() {
  const code = 'ABCDEFGH';
  late FakeFirebaseFirestore db;
  late FirestoreMedicalRepository repo;

  setUp(() {
    db = FakeFirebaseFirestore();
    repo = FirestoreMedicalRepository(db);
  });

  CollectionReference<Map<String, dynamic>> visits() =>
      db.collection('households').doc(code).collection('medicalVisits');

  test('aller-retour d\'une visite complète, triée par étape', () async {
    final m2 = makeVisit(
      MedicalStageId.m2,
      appointmentAt: DateTime(2026, 11, 3, 10),
      practitioner: 'Dr Martin',
      doneAt: DateTime(2026, 11, 3, 10, 30),
      note: 'RAS',
      vaccines: {
        VaccineCode.hexavalent: GivenVaccine(
          givenAt: DateTime(2026, 11, 3, 10, 30),
          brand: 'Hexyon',
          lot: 'A123',
        ),
        VaccineCode.pneumococcal: GivenVaccine(
          givenAt: DateTime(2026, 11, 3, 10, 30),
        ),
      },
    );
    final day8 = makeVisit(MedicalStageId.day8, doneAt: DateTime(2026, 9, 4));
    await repo.saveVisit(code, m2);
    await repo.saveVisit(code, day8);
    expect(await repo.watchVisits(code).first, [day8, m2]);
  });

  test('n\'écrit pas les clés absentes', () async {
    await repo.saveVisit(
      code,
      makeVisit(MedicalStageId.m2, appointmentAt: DateTime(2026, 11, 3, 10)),
    );
    final data = (await visits().doc('m2').get()).data()!;
    expect(
      data.keys,
      unorderedEquals(['appointmentAt', 'updatedAt', 'updatedByDeviceId']),
    );
  });

  test('ignore un document d\'étape inconnue et un vaccin inconnu', () async {
    await visits().doc('m99').set({
      'updatedAt': Timestamp.fromDate(DateTime(2026, 9, 1)),
      'updatedByDeviceId': 'x',
    });
    await visits().doc('m3').set({
      'vaccines': {
        'menB': {'givenAt': Timestamp.fromDate(DateTime(2026, 12, 2))},
        'bcg': {'givenAt': Timestamp.fromDate(DateTime(2026, 12, 2))},
      },
      'updatedAt': Timestamp.fromDate(DateTime(2026, 9, 1)),
      'updatedByDeviceId': 'x',
    });
    final read = await repo.watchVisits(code).first;
    expect(read.single.stageId, MedicalStageId.m3);
    expect(read.single.vaccines.keys, [VaccineCode.menB]);
  });

  test('deleteVisit retire la visite', () async {
    await repo.saveVisit(code, makeVisit(MedicalStageId.m2, note: 'x'));
    await repo.deleteVisit(code, MedicalStageId.m2);
    expect(await repo.watchVisits(code).first, isEmpty);
  });

  test('saveReminderSnapshot écrit medicalReminder sans effacer baby', () async {
    await db.collection('households').doc(code).set({
      'baby': {'name': 'Colette'},
    });
    await repo.saveReminderSnapshot(
      code,
      MedicalReminderSnapshot(
        stages: [
          MedicalReminderStage(
            stageId: MedicalStageId.m2,
            dueFrom: DateTime(2026, 11, 1),
            dueUntil: DateTime(2026, 12, 1),
            hasAppointment: false,
          ),
        ],
        computedAt: DateTime(2026, 10, 20),
      ),
    );
    final data = (await db.collection('households').doc(code).get()).data()!;
    expect(data['baby'], isNotNull);
    final reminder = data['medicalReminder'] as Map<String, dynamic>;
    final stage = (reminder['stages'] as List).single as Map<String, dynamic>;
    expect(stage['stageId'], 'm2');
    expect(stage['hasAppointment'], isFalse);
    expect((stage['dueFrom'] as Timestamp).toDate(), DateTime(2026, 11, 1));
  });
}
```

- [ ] **Step 2: Run test to verify it fails**

Run: `flutter test test/features/health/data`
Expected: FAIL.

- [ ] **Step 3: Implement**

Dans `lib/core/firebase/firestore_paths.dart`, ajouter :

```dart
  /// Visites médicales, une par étape du calendrier (identifiant = `MedicalStageId.name`).
  static const medicalVisits = 'medicalVisits';
```

```dart
// lib/features/health/domain/repositories/medical_repository.dart
import 'package:colette/core/result/failure.dart';
import 'package:colette/features/health/domain/entities/medical_reminder_snapshot.dart';
import 'package:colette/features/health/domain/entities/medical_stage.dart';
import 'package:colette/features/health/domain/entities/medical_visit.dart';
import 'package:fpdart/fpdart.dart';

/// Visites médicales du foyer et snapshot des rappels.
abstract interface class MedicalRepository {
  /// Visites saisies, dans l'ordre du calendrier.
  Stream<List<MedicalVisit>> watchVisits(String householdCode);

  /// Remplace entièrement la visite de son étape.
  Future<Either<Failure, void>> saveVisit(
    String householdCode,
    MedicalVisit visit,
  );

  Future<Either<Failure, void>> deleteVisit(
    String householdCode,
    MedicalStageId stageId,
  );

  /// Écrit `medicalReminder` dans le document du foyer.
  Future<Either<Failure, void>> saveReminderSnapshot(
    String householdCode,
    MedicalReminderSnapshot snapshot,
  );
}
```

```dart
// lib/features/health/data/dtos/medical_visit_dto.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:colette/features/health/domain/entities/given_vaccine.dart';
import 'package:colette/features/health/domain/entities/medical_stage.dart';
import 'package:colette/features/health/domain/entities/medical_visit.dart';
import 'package:colette/features/health/domain/entities/vaccine_code.dart';

/// Conversion `MedicalVisit` ↔ document `medicalVisits/{stageId}` ; clés absentes plutôt que nulles.
abstract final class MedicalVisitDto {
  static final _stages = MedicalStageId.values.asNameMap();
  static final _vaccines = VaccineCode.values.asNameMap();

  static Map<String, dynamic> toMap(MedicalVisit v) => {
    if (v.appointmentAt case final at?) 'appointmentAt': Timestamp.fromDate(at),
    'practitioner': ?v.practitioner,
    if (v.doneAt case final at?) 'doneAt': Timestamp.fromDate(at),
    'note': ?v.note,
    if (v.vaccines.isNotEmpty)
      'vaccines': {
        for (final MapEntry(:key, :value) in v.vaccines.entries)
          key.name: {
            'givenAt': Timestamp.fromDate(value.givenAt),
            'brand': ?value.brand,
            'lot': ?value.lot,
          },
      },
    'updatedAt': Timestamp.fromDate(v.updatedAt),
    'updatedByDeviceId': v.updatedByDeviceId,
  };

  /// `null` pour un document d'étape inconnue (version plus récente de l'app).
  static MedicalVisit? fromDoc(DocumentSnapshot<Map<String, dynamic>> doc) {
    final stageId = _stages[doc.id];
    final data = doc.data();
    if (stageId == null || data == null) return null;
    final rawVaccines = data['vaccines'] as Map<String, dynamic>? ?? const {};
    return MedicalVisit(
      stageId: stageId,
      appointmentAt: (data['appointmentAt'] as Timestamp?)?.toDate(),
      practitioner: data['practitioner'] as String?,
      doneAt: (data['doneAt'] as Timestamp?)?.toDate(),
      note: data['note'] as String?,
      vaccines: {
        for (final MapEntry(:key, :value) in rawVaccines.entries)
          if (_vaccines[key] case final code?)
            code: _vaccine(value as Map<String, dynamic>),
      },
      updatedAt: (data['updatedAt'] as Timestamp).toDate(),
      updatedByDeviceId: data['updatedByDeviceId'] as String,
    );
  }

  static GivenVaccine _vaccine(Map<String, dynamic> map) => GivenVaccine(
    givenAt: (map['givenAt'] as Timestamp).toDate(),
    brand: map['brand'] as String?,
    lot: map['lot'] as String?,
  );
}
```

```dart
// lib/features/health/data/dtos/medical_reminder_snapshot_dto.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:colette/features/health/domain/entities/medical_reminder_snapshot.dart';

/// Conversion du snapshot vers le champ `medicalReminder` du foyer.
abstract final class MedicalReminderSnapshotDto {
  static Map<String, dynamic> toMap(MedicalReminderSnapshot snapshot) => {
    'stages': [
      for (final stage in snapshot.stages)
        {
          'stageId': stage.stageId.name,
          'dueFrom': Timestamp.fromDate(stage.dueFrom),
          'dueUntil': Timestamp.fromDate(stage.dueUntil),
          'hasAppointment': stage.hasAppointment,
        },
    ],
    'computedAt': Timestamp.fromDate(snapshot.computedAt),
  };
}
```

```dart
// lib/features/health/data/repositories/firestore_medical_repository.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:colette/core/firebase/firestore_paths.dart';
import 'package:colette/core/result/failure.dart';
import 'package:colette/core/result/failure_mapper.dart';
import 'package:colette/features/health/data/dtos/medical_reminder_snapshot_dto.dart';
import 'package:colette/features/health/data/dtos/medical_visit_dto.dart';
import 'package:colette/features/health/domain/entities/medical_reminder_snapshot.dart';
import 'package:colette/features/health/domain/entities/medical_stage.dart';
import 'package:colette/features/health/domain/entities/medical_visit.dart';
import 'package:colette/features/health/domain/repositories/medical_repository.dart';
import 'package:fpdart/fpdart.dart';

/// Visites dans `households/{code}/medicalVisits`, snapshot dans `households/{code}.medicalReminder`.
class FirestoreMedicalRepository implements MedicalRepository {
  FirestoreMedicalRepository(this._db);

  final FirebaseFirestore _db;

  DocumentReference<Map<String, dynamic>> _household(String code) =>
      _db.collection(FirestorePaths.households).doc(code);

  CollectionReference<Map<String, dynamic>> _visits(String code) =>
      _household(code).collection(FirestorePaths.medicalVisits);

  @override
  Stream<List<MedicalVisit>> watchVisits(String householdCode) =>
      _visits(householdCode).snapshots().map(
        (snap) =>
            snap.docs.map(MedicalVisitDto.fromDoc).nonNulls.toList()
              ..sort((a, b) => a.stageId.index.compareTo(b.stageId.index)),
      );

  @override
  Future<Either<Failure, void>> saveVisit(
    String householdCode,
    MedicalVisit visit,
  ) => guard(
    () => _visits(
      householdCode,
    ).doc(visit.stageId.name).set(MedicalVisitDto.toMap(visit)),
  );

  @override
  Future<Either<Failure, void>> deleteVisit(
    String householdCode,
    MedicalStageId stageId,
  ) => guard(() => _visits(householdCode).doc(stageId.name).delete());

  @override
  Future<Either<Failure, void>> saveReminderSnapshot(
    String householdCode,
    MedicalReminderSnapshot snapshot,
  ) => guard(
    () => _household(householdCode).set({
      'medicalReminder': MedicalReminderSnapshotDto.toMap(snapshot),
    }, SetOptions(merge: true)),
  );
}
```

Note : avec `SetOptions(merge: true)`, la liste `stages` est remplacée en bloc (les tableaux ne sont jamais fusionnés).

- [ ] **Step 4: Run test to verify it passes**

Run: `flutter test test/features/health/data`
Expected: PASS. Si `dart analyze` signale `use_null_aware_elements` sur une ligne `if (x case final y?)`, appliquer `dart fix --apply --code=use_null_aware_elements`.

- [ ] **Step 5: Commit**

```bash
dart format lib test && dart analyze
git add lib/features/health lib/core/firebase/firestore_paths.dart test/features/health/data
git commit -m "feat: visites médicales et snapshot des rappels dans Firestore"
```

---

### Task 6 : pont Calendrier côté Dart

**Files:**
- Create: `lib/features/health/domain/entities/device_calendar.dart`, `lib/features/health/domain/repositories/calendar_repository.dart`, `lib/features/health/data/native_calendar_repository.dart`
- Modify: `lib/core/result/failure.dart`, `lib/core/ui/failure_message.dart`, `lib/l10n/app_fr.arb`
- Test: `test/features/health/data/native_calendar_repository_test.dart`

- [ ] **Step 1: Write the failing test**

```dart
// test/features/health/data/native_calendar_repository_test.dart
import 'package:colette/core/result/either_extensions.dart';
import 'package:colette/core/result/failure.dart';
import 'package:colette/features/health/data/native_calendar_repository.dart';
import 'package:colette/features/health/domain/entities/calendar_event.dart';
import 'package:colette/features/health/domain/entities/device_calendar.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  const channel = MethodChannel(NativeCalendarRepository.channelName);
  late List<MethodCall> calls;
  const repo = NativeCalendarRepository(channel);

  void mock(Object? Function(MethodCall call) handler) {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, (call) async {
          calls.add(call);
          return handler(call);
        });
  }

  setUp(() => calls = []);

  tearDown(
    () => TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, null),
  );

  test('requestAccess renvoie le booléen natif', () async {
    mock((_) => true);
    expect((await repo.requestAccess()).getRight().toNullable(), isTrue);
    expect(calls.single.method, 'requestAccess');
  });

  test('listCalendars décode les calendriers', () async {
    mock(
      (_) => [
        {'id': 'c1', 'title': 'Famille', 'colorHex': '#FF8800', 'source': 'iCloud'},
      ],
    );
    expect((await repo.listCalendars()).getRight().toNullable(), [
      const DeviceCalendar(
        id: 'c1',
        title: 'Famille',
        colorHex: '#FF8800',
        source: 'iCloud',
      ),
    ]);
  });

  test('findEvents envoie la fenêtre en millisecondes et décode', () async {
    final start = DateTime(2026, 11, 3, 10);
    mock(
      (_) => [
        {
          'eventId': 'e1',
          'url': 'colette://rdv/m2',
          'title': 'Examen',
          'start': start.millisecondsSinceEpoch,
          'end': start.add(const Duration(minutes: 30)).millisecondsSinceEpoch,
          'notes': 'Dr Martin',
          'externalId': 'uid-1',
        },
      ],
    );
    final from = DateTime(2026, 10, 19);
    final to = DateTime(2028, 10, 20);
    final events = (await repo.findEvents('c1', from: from, to: to))
        .getRight()
        .toNullable()!;
    expect(calls.single.arguments, {
      'calendarId': 'c1',
      'from': from.millisecondsSinceEpoch,
      'to': to.millisecondsSinceEpoch,
    });
    expect(
      events.single,
      CalendarEvent(
        eventId: 'e1',
        url: 'colette://rdv/m2',
        title: 'Examen',
        start: start,
        end: start.add(const Duration(minutes: 30)),
        notes: 'Dr Martin',
        externalId: 'uid-1',
      ),
    );
  });

  test('upsertEvent envoie le brouillon et renvoie l\'identifiant', () async {
    mock((_) => 'e9');
    final start = DateTime(2026, 11, 3, 10);
    final result = await repo.upsertEvent(
      'c1',
      eventId: 'e1',
      draft: CalendarEventDraft(
        url: 'colette://rdv/m2',
        title: 'Examen',
        start: start,
        end: start.add(const Duration(minutes: 30)),
        alarms: [DateTime(2026, 11, 2, 18)],
      ),
    );
    expect(result.getRight().toNullable(), 'e9');
    expect(calls.single.arguments, {
      'calendarId': 'c1',
      'eventId': 'e1',
      'url': 'colette://rdv/m2',
      'title': 'Examen',
      'start': start.millisecondsSinceEpoch,
      'end': start.add(const Duration(minutes: 30)).millisecondsSinceEpoch,
      'alarms': [DateTime(2026, 11, 2, 18).millisecondsSinceEpoch],
    });
  });

  test('codes d\'erreur natifs traduits en CalendarFailure', () async {
    for (final (code, reason) in [
      ('accessDenied', CalendarReason.accessDenied),
      ('calendarNotFound', CalendarReason.calendarNotFound),
      ('io', CalendarReason.io),
    ]) {
      mock((_) => throw PlatformException(code: code));
      expect(
        (await repo.deleteEvent('c1', 'e1')).leftOrNull,
        CalendarFailure(reason),
      );
    }
  });
}
```

- [ ] **Step 2: Run test to verify it fails**

Run: `flutter test test/features/health/data/native_calendar_repository_test.dart`
Expected: FAIL.

- [ ] **Step 3: Failure dédiée et messages**

Dans `lib/core/result/failure.dart`, après `DocumentsFailure` :

```dart
/// Raison d'une [CalendarFailure].
enum CalendarReason { accessDenied, calendarNotFound, io }

/// Erreur du pont natif Calendrier (EventKit).
final class CalendarFailure extends Failure {
  const CalendarFailure(this.reason);

  final CalendarReason reason;

  @override
  bool operator ==(Object other) =>
      other is CalendarFailure && other.reason == reason;

  @override
  int get hashCode => reason.hashCode;
}
```

Dans `app_fr.arb` (avant l'accolade finale, virgule après la dernière entrée) :

```json
  "calendarErrorAccessDenied": "Colette n'a pas accès au Calendrier. Autorise-le dans Réglages iOS › Colette › Calendriers.",
  "calendarErrorNotFound": "Calendrier introuvable, choisis-en un autre.",
  "calendarErrorIo": "Le Calendrier n'a pas pu être mis à jour."
```

Dans `failure_message.dart`, avant le `_ => s.errorUnknown` final :

```dart
  CalendarFailure(:final reason) => switch (reason) {
    CalendarReason.accessDenied => s.calendarErrorAccessDenied,
    CalendarReason.calendarNotFound => s.calendarErrorNotFound,
    CalendarReason.io => s.calendarErrorIo,
  },
```

Puis `flutter gen-l10n`.

- [ ] **Step 4: Implement**

```dart
// lib/features/health/domain/entities/device_calendar.dart
import 'package:freezed_annotation/freezed_annotation.dart';

part 'device_calendar.freezed.dart';

/// Calendrier modifiable de cet iPhone ; [source] : compte (iCloud, Gmail…).
@freezed
abstract class DeviceCalendar with _$DeviceCalendar {
  const factory DeviceCalendar({
    required String id,
    required String title,
    String? colorHex,
    required String source,
  }) = _DeviceCalendar;
}
```

```dart
// lib/features/health/domain/repositories/calendar_repository.dart
import 'package:colette/core/result/failure.dart';
import 'package:colette/features/health/domain/entities/calendar_event.dart';
import 'package:colette/features/health/domain/entities/device_calendar.dart';
import 'package:fpdart/fpdart.dart';

/// Accès au Calendrier iOS de cet iPhone.
abstract interface class CalendarRepository {
  /// Demande l'accès complet ; `false` si refusé.
  Future<Either<Failure, bool>> requestAccess();

  Future<Either<Failure, List<DeviceCalendar>>> listCalendars();

  /// Événements Colette (URL `colette://rdv/…`) du calendrier entre [from] et [to].
  Future<Either<Failure, List<CalendarEvent>>> findEvents(
    String calendarId, {
    required DateTime from,
    required DateTime to,
  });

  /// Crée l'événement, ou remplace celui de [eventId] ; renvoie son identifiant.
  Future<Either<Failure, String>> upsertEvent(
    String calendarId, {
    String? eventId,
    required CalendarEventDraft draft,
  });

  /// Supprime l'événement ; sans erreur s'il n'existe plus.
  Future<Either<Failure, void>> deleteEvent(String calendarId, String eventId);
}
```

```dart
// lib/features/health/data/native_calendar_repository.dart
import 'dart:developer' as developer;

import 'package:colette/core/result/failure.dart';
import 'package:colette/features/health/domain/entities/calendar_event.dart';
import 'package:colette/features/health/domain/entities/device_calendar.dart';
import 'package:colette/features/health/domain/repositories/calendar_repository.dart';
import 'package:flutter/services.dart';
import 'package:fpdart/fpdart.dart';

const _reasons = {
  'accessDenied': CalendarReason.accessDenied,
  'calendarNotFound': CalendarReason.calendarNotFound,
  'io': CalendarReason.io,
};

/// Calendrier iOS via le pont Swift `CalendarPlugin` ; dates en millisecondes.
class NativeCalendarRepository implements CalendarRepository {
  const NativeCalendarRepository(this._channel);

  /// Nom du canal, partagé avec `CalendarPlugin.swift`.
  static const channelName = 'colette/calendar';

  final MethodChannel _channel;

  Future<Either<Failure, T>> _call<T>(Future<T> Function() action) async {
    try {
      return right(await action());
    } catch (e, stackTrace) {
      if (e is PlatformException) {
        if (_reasons[e.code] case final reason?) {
          return left(CalendarFailure(reason));
        }
      }
      developer.log(
        'Calendrier natif',
        error: e,
        stackTrace: stackTrace,
        name: 'colette',
      );
      return left(UnknownFailure(e, stackTrace));
    }
  }

  static DateTime _date(Object? millis) =>
      DateTime.fromMillisecondsSinceEpoch(millis! as int);

  @override
  Future<Either<Failure, bool>> requestAccess() => _call(
    () async => await _channel.invokeMethod<bool>('requestAccess') ?? false,
  );

  @override
  Future<Either<Failure, List<DeviceCalendar>>> listCalendars() =>
      _call(() async {
        final raw = await _channel.invokeListMethod<Object?>('listCalendars');
        return [
          for (final item in raw ?? const <Object?>[])
            if (item case final Map<Object?, Object?> map)
              DeviceCalendar(
                id: map['id']! as String,
                title: map['title']! as String,
                colorHex: map['colorHex'] as String?,
                source: map['source']! as String,
              ),
        ];
      });

  @override
  Future<Either<Failure, List<CalendarEvent>>> findEvents(
    String calendarId, {
    required DateTime from,
    required DateTime to,
  }) => _call(() async {
    final raw = await _channel.invokeListMethod<Object?>('findEvents', {
      'calendarId': calendarId,
      'from': from.millisecondsSinceEpoch,
      'to': to.millisecondsSinceEpoch,
    });
    return [
      for (final item in raw ?? const <Object?>[])
        if (item case final Map<Object?, Object?> map)
          CalendarEvent(
            eventId: map['eventId']! as String,
            url: map['url']! as String,
            title: map['title']! as String,
            start: _date(map['start']),
            end: _date(map['end']),
            notes: map['notes'] as String?,
            externalId: map['externalId'] as String?,
          ),
    ];
  });

  @override
  Future<Either<Failure, String>> upsertEvent(
    String calendarId, {
    String? eventId,
    required CalendarEventDraft draft,
  }) => _call(() async {
    final id = await _channel.invokeMethod<String>('upsertEvent', {
      'calendarId': calendarId,
      'eventId': ?eventId,
      'url': draft.url,
      'title': draft.title,
      'start': draft.start.millisecondsSinceEpoch,
      'end': draft.end.millisecondsSinceEpoch,
      'notes': ?draft.notes,
      'alarms': [for (final alarm in draft.alarms) alarm.millisecondsSinceEpoch],
    });
    return id!;
  });

  @override
  Future<Either<Failure, void>> deleteEvent(String calendarId, String eventId) =>
      _call(
        () => _channel.invokeMethod<void>('deleteEvent', {
          'calendarId': calendarId,
          'eventId': eventId,
        }),
      );
}
```

- [ ] **Step 5: Generate and run tests**

```bash
dart run build_runner build -d
flutter gen-l10n
flutter test test/features/health test/core
```
Expected: PASS.

- [ ] **Step 6: Commit**

```bash
dart format lib test && dart analyze && flutter test
git add lib/features/health lib/core/result/failure.dart lib/core/ui/failure_message.dart lib/l10n/app_fr.arb test/features/health/data/native_calendar_repository_test.dart
git commit -m "feat: pont Calendrier côté Dart, erreurs dédiées"
```

---

### Task 7 : pont Calendrier côté Swift (EventKit)

**Files:**
- Create: `ios/Runner/Calendar/CalendarError.swift`, `ios/Runner/Calendar/CalendarPlugin.swift`
- Modify: `ios/Runner/AppDelegate.swift`, `ios/Runner/Info.plist`, `ios/Runner.xcodeproj/project.pbxproj` (via script)

- [ ] **Step 1: Erreurs**

```swift
// ios/Runner/Calendar/CalendarError.swift
import Flutter

/// Erreurs du pont Calendrier, mappées sur les codes attendus par Flutter.
enum CalendarError: Error {
  case accessDenied
  case calendarNotFound
  case io(String)

  var flutterError: FlutterError {
    switch self {
    case .accessDenied:
      return FlutterError(code: "accessDenied", message: nil, details: nil)
    case .calendarNotFound:
      return FlutterError(code: "calendarNotFound", message: nil, details: nil)
    case .io(let message):
      return FlutterError(code: "io", message: message, details: nil)
    }
  }
}
```

- [ ] **Step 2: Plugin**

```swift
// ios/Runner/Calendar/CalendarPlugin.swift
import EventKit
import Flutter
import UIKit
import os.log

/// Canal `colette/calendar` : accès, calendriers modifiables, et événements Colette
/// (URL `colette://rdv/…`) d'un calendrier choisi. Dates en millisecondes depuis l'epoch.
final class CalendarPlugin: NSObject {
  static let channelName = "colette/calendar"
  static let urlPrefix = "colette://rdv/"

  private let store = EKEventStore()

  static func register(with registry: FlutterPluginRegistry) {
    guard let messenger = registry.registrar(forPlugin: "CalendarPlugin")?.messenger() else {
      os_log("CalendarPlugin : registrar indisponible, canal non enregistré", type: .error)
      return
    }
    let channel = FlutterMethodChannel(name: channelName, binaryMessenger: messenger)
    let plugin = CalendarPlugin()
    channel.setMethodCallHandler { call, result in plugin.handle(call, result: result) }
  }

  private func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
    let args = call.arguments as? [String: Any] ?? [:]
    switch call.method {
    case "requestAccess": requestAccess(result)
    case "listCalendars": respond(result) { try self.listCalendars() }
    case "findEvents": respond(result) { try self.findEvents(args) }
    case "upsertEvent": respond(result) { try self.upsertEvent(args) }
    case "deleteEvent": respond(result) { try self.deleteEvent(args) }
    default: result(FlutterMethodNotImplemented)
    }
  }

  private func respond(_ result: FlutterResult, _ body: () throws -> Any?) {
    do {
      result(try body())
    } catch let error as CalendarError {
      result(error.flutterError)
    } catch {
      result(CalendarError.io(error.localizedDescription).flutterError)
    }
  }

  private func requestAccess(_ result: @escaping FlutterResult) {
    let completion: (Bool, Error?) -> Void = { granted, _ in
      DispatchQueue.main.async { result(granted) }
    }
    if #available(iOS 17.0, *) {
      store.requestFullAccessToEvents(completion: completion)
    } else {
      store.requestAccess(to: .event, completion: completion)
    }
  }

  private func ensureAccess() throws {
    let status = EKEventStore.authorizationStatus(for: .event)
    if #available(iOS 17.0, *) {
      guard status == .fullAccess else { throw CalendarError.accessDenied }
    } else {
      guard status == .authorized else { throw CalendarError.accessDenied }
    }
  }

  private func calendar(_ args: [String: Any]) throws -> EKCalendar {
    guard let id = args["calendarId"] as? String,
      let calendar = store.calendar(withIdentifier: id)
    else { throw CalendarError.calendarNotFound }
    return calendar
  }

  private func date(_ args: [String: Any], _ key: String) throws -> Date {
    guard let millis = (args[key] as? NSNumber)?.doubleValue else {
      throw CalendarError.io("argument \(key) manquant")
    }
    return Date(timeIntervalSince1970: millis / 1000)
  }

  private func millis(_ date: Date) -> Int64 {
    Int64((date.timeIntervalSince1970 * 1000).rounded())
  }

  private func listCalendars() throws -> [[String: Any]] {
    try ensureAccess()
    return store.calendars(for: .event)
      .filter { $0.allowsContentModifications }
      .map { calendar in
        [
          "id": calendar.calendarIdentifier,
          "title": calendar.title,
          "colorHex": hex(calendar.cgColor),
          "source": calendar.source.title,
        ]
      }
  }

  private func findEvents(_ args: [String: Any]) throws -> [[String: Any]] {
    try ensureAccess()
    let calendar = try calendar(args)
    let predicate = store.predicateForEvents(
      withStart: try date(args, "from"), end: try date(args, "to"), calendars: [calendar])
    return store.events(matching: predicate).compactMap { event in
      guard let url = event.url?.absoluteString, url.hasPrefix(Self.urlPrefix) else { return nil }
      var map: [String: Any] = [
        "eventId": event.eventIdentifier ?? "",
        "url": url,
        "title": event.title ?? "",
        "start": millis(event.startDate),
        "end": millis(event.endDate),
      ]
      if let notes = event.notes { map["notes"] = notes }
      // Identique sur tous les appareils (UID iCloud) : départage les doublons.
      if let externalId = event.calendarItemExternalIdentifier { map["externalId"] = externalId }
      return map
    }
  }

  private func upsertEvent(_ args: [String: Any]) throws -> String {
    try ensureAccess()
    let calendar = try calendar(args)
    guard let urlString = args["url"] as? String, let url = URL(string: urlString) else {
      throw CalendarError.io("argument url manquant")
    }
    let existing = (args["eventId"] as? String).flatMap { store.event(withIdentifier: $0) }
    let event = existing ?? EKEvent(eventStore: store)
    event.calendar = calendar
    event.title = args["title"] as? String
    event.startDate = try date(args, "start")
    event.endDate = try date(args, "end")
    event.notes = args["notes"] as? String
    event.url = url
    event.alarms = ((args["alarms"] as? [NSNumber]) ?? []).map {
      EKAlarm(absoluteDate: Date(timeIntervalSince1970: $0.doubleValue / 1000))
    }
    do {
      try store.save(event, span: .thisEvent, commit: true)
    } catch {
      throw CalendarError.io(error.localizedDescription)
    }
    return event.eventIdentifier ?? ""
  }

  private func deleteEvent(_ args: [String: Any]) throws -> Any? {
    try ensureAccess()
    guard let id = args["eventId"] as? String else {
      throw CalendarError.io("argument eventId manquant")
    }
    guard let event = store.event(withIdentifier: id) else { return nil }
    do {
      try store.remove(event, span: .thisEvent, commit: true)
    } catch {
      throw CalendarError.io(error.localizedDescription)
    }
    return nil
  }

  private func hex(_ color: CGColor) -> String {
    var red: CGFloat = 0, green: CGFloat = 0, blue: CGFloat = 0, alpha: CGFloat = 0
    UIColor(cgColor: color).getRed(&red, green: &green, blue: &blue, alpha: &alpha)
    func byte(_ value: CGFloat) -> Int { Int((min(max(value, 0), 1) * 255).rounded()) }
    return String(format: "#%02X%02X%02X", byte(red), byte(green), byte(blue))
  }
}
```

- [ ] **Step 3: Enregistrement, Info.plist, projet Xcode**

Dans `AppDelegate.swift`, après `DocumentsPlugin.register(with: engineBridge.pluginRegistry)` :

```swift
    CalendarPlugin.register(with: engineBridge.pluginRegistry)
```

Dans `ios/Runner/Info.plist`, à côté de `NSCameraUsageDescription` :

```xml
	<key>NSCalendarsFullAccessUsageDescription</key>
	<string>Colette ajoute les rendez-vous médicaux de votre bébé au calendrier que vous choisissez.</string>
	<key>NSCalendarsUsageDescription</key>
	<string>Colette ajoute les rendez-vous médicaux de votre bébé au calendrier que vous choisissez.</string>
```

Ajouter les deux fichiers à la cible Runner (le gem `xcodeproj` est installé avec CocoaPods) :

```bash
ruby -e '
require "xcodeproj"
project = Xcodeproj::Project.open("ios/Runner.xcodeproj")
target = project.targets.find { |t| t.name == "Runner" }
runner = project.main_group["Runner"]
group = runner["Calendar"] || runner.new_group("Calendar", "Calendar")
%w[CalendarError.swift CalendarPlugin.swift].each do |name|
  next if group.files.any? { |f| f.path == name }
  target.source_build_phase.add_file_reference(group.new_reference(name))
end
project.save
'
git diff --stat ios/Runner.xcodeproj/project.pbxproj
```
Expected: `project.pbxproj` modifié (deux fichiers, un groupe `Calendar`).

- [ ] **Step 4: Compiler**

Run: `flutter build ios --simulator --debug`
Expected: `✓ Built build/ios/iphonesimulator/Runner.app`. En cas d'erreur Swift, corriger et recompiler.

- [ ] **Step 5: Commit**

```bash
git add ios/Runner/Calendar ios/Runner/AppDelegate.swift ios/Runner/Info.plist ios/Runner.xcodeproj/project.pbxproj
git commit -m "feat: pont Swift EventKit pour les RDV médicaux"
```

---

### Task 8 : providers, synchronisation et contrôleurs

**Files:**
- Create: `lib/features/health/domain/entities/calendar_choice.dart`, `lib/features/health/presentation/providers/health_providers.dart`, `lib/features/health/presentation/providers/selected_calendar.dart`, `lib/features/health/presentation/providers/health_sync.dart`, `lib/features/health/presentation/providers/medical_visit_controller.dart`, `lib/features/health/presentation/providers/calendar_settings_controller.dart`, `lib/features/health/presentation/widgets/health_labels.dart`, `lib/features/health/presentation/widgets/health_sync_gate.dart`
- Modify: `lib/app/colette_app.dart`, `lib/l10n/app_fr.arb`, `test/helpers/colette_app_overrides.dart`
- Test: `test/features/health/presentation/health_sync_test.dart`, `test/features/health/presentation/medical_visit_controller_test.dart`, `test/features/health/presentation/selected_calendar_test.dart`

- [ ] **Step 1: Libellés (arb) et `HealthLabels`**

Dans `app_fr.arb` (avant l'accolade finale) :

```json
  "healthTitle": "Santé",
  "healthStageDay8": "Examen des 8 jours",
  "healthStageWeek2": "Examen de la 2e semaine",
  "healthStageM1": "Examen du 1er mois",
  "healthStageM2": "Examen et vaccins des 2 mois",
  "healthStageM3": "Examen et vaccins des 3 mois",
  "healthStageM4": "Examen et vaccins des 4 mois",
  "healthStageM5": "Examen et vaccins des 5 mois",
  "healthStageM6": "Vaccin des 6 mois",
  "healthStageM8": "Examen des 8 mois",
  "healthStageM11": "Examen et vaccins des 11 mois",
  "healthStageM12": "Examen et vaccins des 12 mois",
  "healthStageM16": "Examen et vaccin des 16-18 mois",
  "healthStageM23": "Examen des 23-24 mois",
  "healthStageY2": "Examen des 2 ans",
  "healthStageY3": "Examen des 3 ans",
  "healthEventTitle": "{stage} · {name}",
  "@healthEventTitle": { "placeholders": { "stage": { "type": "String" }, "name": { "type": "String" } } },
  "vaccineHexavalent": "Hexavalent (DTCaP-Hib-HépB)",
  "vaccinePneumococcal": "Pneumocoque",
  "vaccineMenB": "Méningocoque B",
  "vaccineMenACWY": "Méningocoques ACWY",
  "vaccineMmr": "ROR (rougeole, oreillons, rubéole)",
  "vaccineRotavirus": "Rotavirus"
```

```dart
// lib/features/health/presentation/widgets/health_labels.dart
import 'package:colette/features/health/domain/entities/medical_stage.dart';
import 'package:colette/features/health/domain/entities/vaccine_code.dart';
import 'package:colette/l10n/generated/app_localizations.dart';

/// Libellés des étapes et des vaccins.
abstract final class HealthLabels {
  static String stage(S s, MedicalStageId id) => switch (id) {
    MedicalStageId.day8 => s.healthStageDay8,
    MedicalStageId.week2 => s.healthStageWeek2,
    MedicalStageId.m1 => s.healthStageM1,
    MedicalStageId.m2 => s.healthStageM2,
    MedicalStageId.m3 => s.healthStageM3,
    MedicalStageId.m4 => s.healthStageM4,
    MedicalStageId.m5 => s.healthStageM5,
    MedicalStageId.m6 => s.healthStageM6,
    MedicalStageId.m8 => s.healthStageM8,
    MedicalStageId.m11 => s.healthStageM11,
    MedicalStageId.m12 => s.healthStageM12,
    MedicalStageId.m16 => s.healthStageM16,
    MedicalStageId.m23 => s.healthStageM23,
    MedicalStageId.y2 => s.healthStageY2,
    MedicalStageId.y3 => s.healthStageY3,
  };

  /// Titre de l'événement de calendrier : « Examen et vaccins des 2 mois · Colette ».
  static String eventTitle(S s, MedicalStageId id, String babyName) =>
      s.healthEventTitle(stage(s, id), babyName);

  static String vaccine(S s, VaccineCode code) => switch (code) {
    VaccineCode.hexavalent => s.vaccineHexavalent,
    VaccineCode.pneumococcal => s.vaccinePneumococcal,
    VaccineCode.menB => s.vaccineMenB,
    VaccineCode.menACWY => s.vaccineMenACWY,
    VaccineCode.mmr => s.vaccineMmr,
    VaccineCode.rotavirus => s.vaccineRotavirus,
  };
}
```

- [ ] **Step 2: Write the failing tests**

```dart
// test/features/health/presentation/selected_calendar_test.dart
import 'package:colette/core/firebase/firebase_providers.dart';
import 'package:colette/features/health/domain/entities/calendar_choice.dart';
import 'package:colette/features/health/presentation/providers/selected_calendar.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  test('choix mémorisé dans les préférences puis effacé', () async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    final container = ProviderContainer(
      overrides: [sharedPreferencesProvider.overrideWithValue(prefs)],
    );
    addTearDown(container.dispose);
    expect(container.read(selectedCalendarProvider), isNull);

    await container
        .read(selectedCalendarProvider.notifier)
        .choose(const CalendarChoice(id: 'c1', title: 'Famille'));
    expect(
      container.read(selectedCalendarProvider),
      const CalendarChoice(id: 'c1', title: 'Famille'),
    );
    expect(prefs.getString(SelectedCalendar.idKey), 'c1');

    await container.read(selectedCalendarProvider.notifier).clear();
    expect(container.read(selectedCalendarProvider), isNull);
    expect(prefs.getString(SelectedCalendar.idKey), isNull);
  });
}
```

```dart
// test/features/health/presentation/health_sync_test.dart
import 'package:colette/core/clock/app_clock.dart';
import 'package:colette/core/firebase/firebase_providers.dart';
import 'package:colette/core/result/failure.dart';
import 'package:colette/features/baby/domain/entities/baby_profile.dart';
import 'package:colette/features/baby/presentation/providers/baby_providers.dart';
import 'package:colette/features/health/domain/entities/calendar_choice.dart';
import 'package:colette/features/health/domain/entities/calendar_event.dart';
import 'package:colette/features/health/domain/entities/medical_stage.dart';
import 'package:colette/features/health/domain/repositories/calendar_repository.dart';
import 'package:colette/features/health/presentation/providers/health_providers.dart';
import 'package:colette/features/health/presentation/providers/health_sync.dart';
import 'package:colette/features/health/presentation/providers/selected_calendar.dart';
import 'package:colette/features/household/presentation/providers/household_providers.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:mocktail/mocktail.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../helpers/in_memory_household_local_store.dart';
import '../health_factories.dart';

class MockCalendarRepository extends Mock implements CalendarRepository {}

void main() {
  const code = 'ABCDEFGH';
  final now = DateTime(2026, 10, 20, 12);
  late FakeFirebaseFirestore db;
  late MockCalendarRepository calendar;

  setUpAll(() {
    registerFallbackValue(
      CalendarEventDraft(url: '', title: '', start: now, end: now),
    );
  });

  Future<ProviderContainer> container({String? calendarId}) async {
    SharedPreferences.setMockInitialValues({
      if (calendarId != null) SelectedCalendar.idKey: calendarId,
      if (calendarId != null) SelectedCalendar.titleKey: 'Famille',
    });
    final prefs = await SharedPreferences.getInstance();
    final c = ProviderContainer(
      overrides: [
        firestoreProvider.overrideWithValue(db),
        sharedPreferencesProvider.overrideWithValue(prefs),
        clockProvider.overrideWithValue(FixedClock(now)),
        householdLocalStoreProvider.overrideWithValue(
          InMemoryHouseholdLocalStore(householdCode: code),
        ),
        calendarRepositoryProvider.overrideWithValue(calendar),
      ],
    );
    addTearDown(c.dispose);
    await c
        .read(babyRepositoryProvider)
        .saveProfile(
          code,
          BabyProfile(name: 'Colette', birthDate: DateTime(2026, 9, 1)),
        );
    return c;
  }

  setUp(() {
    db = FakeFirebaseFirestore();
    calendar = MockCalendarRepository();
  });

  test('écrit le snapshot des rappels, sans calendrier choisi', () async {
    final c = await container();
    await c.read(healthSyncProvider).sync();
    final data = (await db.collection('households').doc(code).get()).data()!;
    final stages =
        (data['medicalReminder'] as Map<String, dynamic>)['stages'] as List;
    expect((stages.first as Map)['stageId'], 'day8');
    verifyZeroInteractions(calendar);
  });

  test('crée l\'événement d\'un RDV dans le calendrier choisi', () async {
    final c = await container(calendarId: 'c1');
    await c
        .read(medicalRepositoryProvider)
        .saveVisit(
          code,
          makeVisit(MedicalStageId.m2, appointmentAt: DateTime(2026, 11, 3, 10)),
        );
    when(
      () => calendar.findEvents(
        'c1',
        from: any(named: 'from'),
        to: any(named: 'to'),
      ),
    ).thenAnswer((_) async => right(const <CalendarEvent>[]));
    when(
      () => calendar.upsertEvent(
        'c1',
        eventId: any(named: 'eventId'),
        draft: any(named: 'draft'),
      ),
    ).thenAnswer((_) async => right('e1'));

    await c.read(healthSyncProvider).sync();

    final draft =
        verify(
              () => calendar.upsertEvent(
                'c1',
                eventId: null,
                draft: captureAny(named: 'draft'),
              ),
            ).captured.single
            as CalendarEventDraft;
    expect(draft.title, 'Examen et vaccins des 2 mois · Colette');
    expect(draft.url, 'colette://rdv/m2');
  });

  test('calendrier introuvable : choix local effacé', () async {
    final c = await container(calendarId: 'gone');
    when(
      () => calendar.findEvents(
        'gone',
        from: any(named: 'from'),
        to: any(named: 'to'),
      ),
    ).thenAnswer(
      (_) async => left(const CalendarFailure(CalendarReason.calendarNotFound)),
    );
    await c.read(healthSyncProvider).sync();
    expect(c.read(selectedCalendarProvider), isNull);
  });

  test('medicalVisitsProvider lit les visites du foyer', () async {
    final c = await container();
    await c
        .read(medicalRepositoryProvider)
        .saveVisit(code, makeVisit(MedicalStageId.m2, note: 'x'));
    final sub = c.listen(medicalVisitsProvider, (_, _) {});
    addTearDown(sub.close);
    expect(
      (await c.read(medicalVisitsProvider.future)).single.stageId,
      MedicalStageId.m2,
    );
  });

  test('CalendarChoice est une valeur', () {
    expect(
      const CalendarChoice(id: 'a', title: 'b'),
      const CalendarChoice(id: 'a', title: 'b'),
    );
  });
}
```

```dart
// test/features/health/presentation/medical_visit_controller_test.dart
import 'dart:async';

import 'package:colette/core/clock/app_clock.dart';
import 'package:colette/core/result/failure.dart';
import 'package:colette/features/health/domain/entities/medical_stage.dart';
import 'package:colette/features/health/domain/entities/medical_visit.dart';
import 'package:colette/features/health/domain/repositories/medical_repository.dart';
import 'package:colette/features/health/presentation/providers/health_providers.dart';
import 'package:colette/features/health/presentation/providers/health_sync.dart';
import 'package:colette/features/health/presentation/providers/medical_visit_controller.dart';
import 'package:colette/features/household/presentation/providers/household_providers.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:mocktail/mocktail.dart';

import '../../../helpers/in_memory_household_local_store.dart';
import '../health_factories.dart';

class MockMedicalRepository extends Mock implements MedicalRepository {}

class MockHealthSync extends Mock implements HealthSync {}

void main() {
  late MockMedicalRepository repo;
  late MockHealthSync sync;
  late ProviderContainer container;
  final birth = DateTime(2026, 9, 1);
  final now = DateTime(2026, 11, 10, 12);

  setUpAll(() {
    registerFallbackValue(makeVisit(MedicalStageId.day8));
    registerFallbackValue(MedicalStageId.day8);
  });

  setUp(() {
    repo = MockMedicalRepository();
    sync = MockHealthSync();
    when(() => sync.sync()).thenAnswer((_) async {});
    container = ProviderContainer(
      overrides: [
        medicalRepositoryProvider.overrideWithValue(repo),
        healthSyncProvider.overrideWithValue(sync),
        clockProvider.overrideWithValue(FixedClock(now)),
        householdLocalStoreProvider.overrideWithValue(
          InMemoryHouseholdLocalStore(
            householdCode: 'ABCDEFGH',
            deviceId: 'device-b',
          ),
        ),
      ],
    );
    addTearDown(container.dispose);
  });

  MedicalVisitController controller() =>
      container.read(medicalVisitControllerProvider.notifier);

  test('enregistre la visite horodatée par cet iPhone puis synchronise', () async {
    when(() => repo.saveVisit(any(), any())).thenAnswer((_) async => right(null));
    final ok = await controller().save(
      makeVisit(MedicalStageId.m2, appointmentAt: DateTime(2026, 12, 1, 9)),
      birthDate: birth,
    );
    expect(ok, isTrue);
    final saved =
        verify(() => repo.saveVisit('ABCDEFGH', captureAny())).captured.single
            as MedicalVisit;
    expect(saved.updatedAt, now);
    expect(saved.updatedByDeviceId, 'device-b');
    verify(() => sync.sync()).called(1);
  });

  test('une visite vide est supprimée', () async {
    when(() => repo.deleteVisit(any(), any())).thenAnswer((_) async => right(null));
    expect(
      await controller().save(makeVisit(MedicalStageId.m2), birthDate: birth),
      isTrue,
    );
    verify(() => repo.deleteVisit('ABCDEFGH', MedicalStageId.m2)).called(1);
  });

  test('refuse une visite invalide sans écrire ni synchroniser', () async {
    final ok = await controller().save(
      makeVisit(MedicalStageId.m2, doneAt: DateTime(2026, 12, 1)),
      birthDate: birth,
    );
    expect(ok, isFalse);
    expect(
      (container.read(medicalVisitControllerProvider).error! as ValidationFailure)
          .reason,
      ValidationReason.medicalDateInFuture,
    );
    verifyNever(() => repo.saveVisit(any(), any()));
    verifyNever(() => sync.sync());
  });

  test('la sync part même si le contrôleur est détruit pendant l\'écriture', () async {
    final completer = Completer<Either<Failure, void>>();
    when(() => repo.saveVisit(any(), any())).thenAnswer((_) => completer.future);
    final sub = container.listen(medicalVisitControllerProvider, (_, _) {});
    final future = controller().save(makeVisit(MedicalStageId.m2, note: 'x'), birthDate: birth);
    sub.close();
    await Future<void>.delayed(Duration.zero);
    completer.complete(right(null));
    expect(await future, isTrue);
    verify(() => sync.sync()).called(1);
  });
}
```

- [ ] **Step 3: Run tests to verify they fail**

Run: `flutter test test/features/health/presentation`
Expected: FAIL.

- [ ] **Step 4: Implement**

```dart
// lib/features/health/domain/entities/calendar_choice.dart
import 'package:freezed_annotation/freezed_annotation.dart';

part 'calendar_choice.freezed.dart';

/// Calendrier choisi sur cet iPhone pour les RDV santé.
@freezed
abstract class CalendarChoice with _$CalendarChoice {
  const factory CalendarChoice({required String id, required String title}) =
      _CalendarChoice;
}
```

```dart
// lib/features/health/presentation/providers/selected_calendar.dart
import 'package:colette/core/firebase/firebase_providers.dart';
import 'package:colette/features/health/domain/entities/calendar_choice.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'selected_calendar.g.dart';

/// Calendrier des RDV santé de cet iPhone (identifiants EventKit propres à l'appareil).
@Riverpod(keepAlive: true)
class SelectedCalendar extends _$SelectedCalendar {
  static const idKey = 'health_calendar_id';
  static const titleKey = 'health_calendar_title';

  @override
  CalendarChoice? build() {
    final prefs = ref.watch(sharedPreferencesProvider);
    final id = prefs.getString(idKey);
    final title = prefs.getString(titleKey);
    return id == null || title == null
        ? null
        : CalendarChoice(id: id, title: title);
  }

  Future<void> choose(CalendarChoice choice) async {
    state = choice;
    final prefs = ref.read(sharedPreferencesProvider);
    await prefs.setString(idKey, choice.id);
    await prefs.setString(titleKey, choice.title);
  }

  Future<void> clear() async {
    state = null;
    final prefs = ref.read(sharedPreferencesProvider);
    await prefs.remove(idKey);
    await prefs.remove(titleKey);
  }
}
```

```dart
// lib/features/health/presentation/providers/health_providers.dart
import 'package:colette/core/clock/now_providers.dart';
import 'package:colette/core/firebase/firebase_providers.dart';
import 'package:colette/core/result/no_retry.dart';
import 'package:colette/features/baby/presentation/providers/baby_providers.dart';
import 'package:colette/features/health/data/native_calendar_repository.dart';
import 'package:colette/features/health/data/repositories/firestore_medical_repository.dart';
import 'package:colette/features/health/domain/entities/medical_timeline.dart';
import 'package:colette/features/health/domain/entities/medical_visit.dart';
import 'package:colette/features/health/domain/repositories/calendar_repository.dart';
import 'package:colette/features/health/domain/repositories/medical_repository.dart';
import 'package:colette/features/health/domain/use_cases/compute_medical_timeline.dart';
import 'package:colette/features/household/presentation/providers/household_providers.dart';
import 'package:flutter/services.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'health_providers.g.dart';

/// Sans état : `keepAlive` car lu par `healthSyncProvider` (keepAlive).
@Riverpod(keepAlive: true)
MedicalRepository medicalRepository(Ref ref) =>
    FirestoreMedicalRepository(ref.watch(firestoreProvider));

/// Pont Swift du Calendrier iOS.
@Riverpod(keepAlive: true)
CalendarRepository calendarRepository(Ref ref) => const NativeCalendarRepository(
  MethodChannel(NativeCalendarRepository.channelName),
);

/// Visites médicales du foyer courant.
@Riverpod(retry: noRetry)
Stream<List<MedicalVisit>> medicalVisits(Ref ref) {
  final code = ref.watch(currentHouseholdCodeProvider);
  if (code == null) return Stream.value(const []);
  return ref.watch(medicalRepositoryProvider).watchVisits(code);
}

/// Frise du suivi médical ; `null` sans profil.
@riverpod
MedicalTimeline? medicalTimeline(Ref ref) {
  final profile = ref.watch(babyProfileProvider).value;
  if (profile == null) return null;
  return const ComputeMedicalTimeline()(
    birthDate: profile.birthDate,
    visits: ref.watch(medicalVisitsProvider).value ?? const [],
    now: ref.watch(currentMinuteProvider),
  );
}
```

```dart
// lib/features/health/presentation/providers/health_sync.dart
import 'dart:developer' as developer;

import 'package:colette/core/clock/app_clock.dart';
import 'package:colette/core/result/failure.dart';
import 'package:colette/features/baby/presentation/providers/baby_providers.dart';
import 'package:colette/features/health/domain/entities/calendar_action.dart';
import 'package:colette/features/health/domain/entities/medical_visit.dart';
import 'package:colette/features/health/domain/use_cases/compute_medical_reminder_snapshot.dart';
import 'package:colette/features/health/domain/use_cases/compute_medical_timeline.dart';
import 'package:colette/features/health/domain/use_cases/reconcile_calendar.dart';
import 'package:colette/features/health/presentation/providers/health_providers.dart';
import 'package:colette/features/health/presentation/providers/selected_calendar.dart';
import 'package:colette/features/health/presentation/widgets/health_labels.dart';
import 'package:colette/features/household/presentation/providers/household_providers.dart';
import 'package:colette/l10n/generated/app_localizations.dart';
import 'package:flutter/widgets.dart';
import 'package:fpdart/fpdart.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'health_sync.g.dart';

/// Réécrit le snapshot des rappels santé et réconcilie le calendrier de cet iPhone.
abstract interface class HealthSync {
  Future<void> sync();
}

/// Ne fait rien ; pour les tests.
final class NoopHealthSync implements HealthSync {
  const NoopHealthSync();

  @override
  Future<void> sync() async {}
}

/// Relit Firestore (pas les providers, qui peuvent être détruits pendant l'attente).
/// Best-effort : une erreur est journalisée, jamais propagée.
final class FirestoreHealthSync implements HealthSync {
  const FirestoreHealthSync(this._ref);

  final Ref _ref;

  @override
  Future<void> sync() async {
    final code = _ref.read(currentHouseholdCodeProvider);
    if (code == null) return;
    try {
      final profile = await _ref
          .read(babyRepositoryProvider)
          .watchProfile(code)
          .first;
      if (profile == null) return;
      final medical = _ref.read(medicalRepositoryProvider);
      final visits = await medical.watchVisits(code).first;
      final now = _ref.read(clockProvider).now();
      final timeline = const ComputeMedicalTimeline()(
        birthDate: profile.birthDate,
        visits: visits,
        now: now,
      );
      await medical.saveReminderSnapshot(
        code,
        const ComputeMedicalReminderSnapshot()(timeline: timeline, now: now),
      );
      await _syncCalendar(visits, profile.name, now);
    } catch (e, stackTrace) {
      developer.log(
        'Health sync failed',
        error: e,
        stackTrace: stackTrace,
        name: 'colette',
      );
    }
  }

  Future<void> _syncCalendar(
    List<MedicalVisit> visits,
    String babyName,
    DateTime now,
  ) async {
    final choice = _ref.read(selectedCalendarProvider);
    if (choice == null) return;
    final calendar = _ref.read(calendarRepositoryProvider);
    final found = await calendar.findEvents(
      choice.id,
      from: ReconcileCalendar.windowStart(now),
      to: ReconcileCalendar.windowEnd(now),
    );
    if (found case Left(:final value)) {
      await _failed(value);
      return;
    }
    final events = found.getOrElse((_) => const []);
    final s = lookupS(const Locale('fr'));
    final actions = const ReconcileCalendar()(
      visits: visits,
      events: events,
      titleOf: (id) => HealthLabels.eventTitle(s, id, babyName),
      now: now,
    );
    for (final action in actions) {
      final Future<Either<Failure, Object?>> pending = switch (action) {
        CreateCalendarEvent(:final draft) => calendar.upsertEvent(
          choice.id,
          draft: draft,
        ),
        UpdateCalendarEvent(:final eventId, :final draft) =>
          calendar.upsertEvent(choice.id, eventId: eventId, draft: draft),
        DeleteCalendarEvent(:final eventId) => calendar.deleteEvent(
          choice.id,
          eventId,
        ),
      };
      if ((await pending) case Left(:final value)) {
        await _failed(value);
        return;
      }
    }
  }

  /// Calendrier disparu : on oublie le choix. Autre échec : journalisé.
  Future<void> _failed(Failure failure) async {
    if (failure == const CalendarFailure(CalendarReason.calendarNotFound)) {
      await _ref.read(selectedCalendarProvider.notifier).clear();
    } else {
      developer.log('Calendar sync failed: $failure', name: 'colette');
    }
  }
}

/// `keepAlive` : lu avant un `await` par des contrôleurs autoDispose.
@Riverpod(keepAlive: true)
HealthSync healthSync(Ref ref) => FirestoreHealthSync(ref);
```

```dart
// lib/features/health/presentation/providers/medical_visit_controller.dart
import 'dart:async';

import 'package:colette/core/clock/app_clock.dart';
import 'package:colette/core/result/failure.dart';
import 'package:colette/features/health/domain/entities/medical_visit.dart';
import 'package:colette/features/health/domain/use_cases/validate_medical_visit.dart';
import 'package:colette/features/health/presentation/providers/health_providers.dart';
import 'package:colette/features/health/presentation/providers/health_sync.dart';
import 'package:colette/features/household/presentation/providers/household_providers.dart';
import 'package:fpdart/fpdart.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'medical_visit_controller.g.dart';

/// Enregistre une visite (ou la supprime si elle est vide) puis resynchronise.
@riverpod
class MedicalVisitController extends _$MedicalVisitController {
  @override
  FutureOr<void> build() {}

  Future<bool> save(MedicalVisit visit, {required DateTime birthDate}) async {
    final code = ref.read(currentHouseholdCodeProvider);
    if (code == null) return false;
    // Lu avant l'await : le contrôleur autoDispose peut être détruit pendant l'écriture.
    final sync = ref.read(healthSyncProvider);
    final repo = ref.read(medicalRepositoryProvider);
    final now = ref.read(clockProvider).now();
    final stamped = visit.copyWith(
      updatedAt: now,
      updatedByDeviceId: ref.read(deviceIdProvider),
    );
    state = const AsyncLoading();
    final result =
        await const ValidateMedicalVisit()(
          stamped,
          birthDate: birthDate,
          now: now,
        ).fold<Future<Either<Failure, void>>>(
          (failure) async => left(failure),
          (valid) => valid.isEmpty
              ? repo.deleteVisit(code, valid.stageId)
              : repo.saveVisit(code, valid),
        );
    if (ref.mounted) {
      state = result.fold(
        (failure) => AsyncError(failure, StackTrace.current),
        (_) => const AsyncData(null),
      );
    }
    if (result.isRight()) await sync.sync();
    return result.isRight();
  }
}
```

```dart
// lib/features/health/presentation/providers/calendar_settings_controller.dart
import 'dart:async';

import 'package:colette/core/result/failure.dart';
import 'package:colette/features/health/domain/entities/calendar_choice.dart';
import 'package:colette/features/health/domain/entities/device_calendar.dart';
import 'package:colette/features/health/presentation/providers/health_providers.dart';
import 'package:colette/features/health/presentation/providers/health_sync.dart';
import 'package:colette/features/health/presentation/providers/selected_calendar.dart';
import 'package:fpdart/fpdart.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'calendar_settings_controller.g.dart';

/// Accès au Calendrier et choix du calendrier des RDV santé sur cet iPhone.
@riverpod
class CalendarSettingsController extends _$CalendarSettingsController {
  @override
  FutureOr<void> build() {}

  /// Demande l'accès puis liste les calendriers modifiables ; `null` en cas d'échec.
  Future<List<DeviceCalendar>?> loadCalendars() async {
    final repo = ref.read(calendarRepositoryProvider);
    state = const AsyncLoading();
    final access = await repo.requestAccess();
    final result = await access
        .fold<Future<Either<Failure, List<DeviceCalendar>>>>(
          (failure) async => left(failure),
          (granted) async => granted
              ? repo.listCalendars()
              : left(const CalendarFailure(CalendarReason.accessDenied)),
        );
    if (ref.mounted) {
      state = result.fold(
        (failure) => AsyncError(failure, StackTrace.current),
        (_) => const AsyncData(null),
      );
    }
    return result.getRight().toNullable();
  }

  /// Retient [calendar] pour cet iPhone puis synchronise les RDV.
  Future<void> choose(DeviceCalendar calendar) async {
    final sync = ref.read(healthSyncProvider);
    await ref
        .read(selectedCalendarProvider.notifier)
        .choose(CalendarChoice(id: calendar.id, title: calendar.title));
    await sync.sync();
  }

  /// Arrête la synchronisation, sans toucher aux événements existants.
  Future<void> clear() => ref.read(selectedCalendarProvider.notifier).clear();
}
```

```dart
// lib/features/health/presentation/widgets/health_sync_gate.dart
import 'package:colette/features/health/presentation/providers/health_sync.dart';
import 'package:colette/features/household/presentation/providers/household_providers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Rafraîchit rappels santé et calendrier au lancement, dès qu'un foyer existe.
class HealthSyncGate extends ConsumerStatefulWidget {
  const HealthSyncGate({super.key, required this.child});

  final Widget child;

  @override
  ConsumerState<HealthSyncGate> createState() => _HealthSyncGateState();
}

class _HealthSyncGateState extends ConsumerState<HealthSyncGate> {
  @override
  void initState() {
    super.initState();
    ref.listenManual(currentHouseholdCodeProvider, fireImmediately: true, (
      _,
      code,
    ) {
      if (code == null) return;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) ref.read(healthSyncProvider).sync();
      });
    });
  }

  @override
  Widget build(BuildContext context) => widget.child;
}
```

Dans `lib/app/colette_app.dart`, importer `health_sync_gate.dart` et remplacer le `builder` par :

```dart
      builder: (context, child) => SplashIntro(
        child: NotificationsGate(
          child: HealthSyncGate(child: child ?? const SizedBox.shrink()),
        ),
      ),
```

Dans `test/helpers/colette_app_overrides.dart`, importer `health_sync.dart` et ajouter à la liste renvoyée :

```dart
    healthSyncProvider.overrideWithValue(const NoopHealthSync()),
```

- [ ] **Step 5: Generate and run tests**

```bash
dart run build_runner build -d
flutter gen-l10n
flutter test test/features/health test/app
```
Expected: PASS.

- [ ] **Step 6: Commit**

```bash
dart format lib test && dart analyze && flutter test
git add lib/features/health lib/app/colette_app.dart lib/l10n/app_fr.arb test/helpers/colette_app_overrides.dart test/features/health
git commit -m "feat: synchronisation santé, contrôleurs des visites et du calendrier"
```

---

### Task 9 : carte d'accueil, route et page Santé

**Files:**
- Create: `lib/features/health/presentation/widgets/health_status_text.dart`, `lib/features/health/presentation/widgets/health_card.dart`, `lib/features/health/presentation/widgets/medical_stage_tile.dart`, `lib/features/health/presentation/pages/health_page.dart`
- Modify: `lib/app/router/app_router.dart`, `lib/features/dashboard/presentation/pages/dashboard_page.dart`, `lib/l10n/app_fr.arb`
- Test: `test/features/health/presentation/health_card_test.dart`, `test/features/health/presentation/health_page_test.dart`

- [ ] **Step 1: Chaînes**

Dans `app_fr.arb` :

```json
  "healthDueWindow": "À faire du {from} au {to}",
  "@healthDueWindow": { "placeholders": { "from": { "type": "String" }, "to": { "type": "String" } } },
  "healthScheduled": "RDV le {date}",
  "@healthScheduled": { "placeholders": { "date": { "type": "String" } } },
  "healthScheduledWith": "RDV le {date} · {practitioner}",
  "@healthScheduledWith": { "placeholders": { "date": { "type": "String" }, "practitioner": { "type": "String" } } },
  "healthAppointmentPassed": "RDV du {date} passé · à marquer comme faite",
  "@healthAppointmentPassed": { "placeholders": { "date": { "type": "String" } } },
  "healthLateSince": "En retard depuis le {date}",
  "@healthLateSince": { "placeholders": { "date": { "type": "String" } } },
  "healthDoneOn": "Faite le {date}",
  "@healthDoneOn": { "placeholders": { "date": { "type": "String" } } },
  "healthNextFar": "Prochaine étape : {stage}, à partir du {date}",
  "@healthNextFar": { "placeholders": { "stage": { "type": "String" }, "date": { "type": "String" } } },
  "healthAllDone": "Toutes les étapes jusqu'à 3 ans sont faites.",
  "healthSectionLate": "En retard",
  "healthSectionToDo": "À faire",
  "healthSectionUpcoming": "À venir",
  "healthSectionDone": "Faites ({count})",
  "@healthSectionDone": { "placeholders": { "count": { "type": "int" } } },
  "healthChipExam": "Examen",
  "healthChipVaccines": "Vaccins",
  "healthChipCertificate": "Certificat",
  "healthCalendarSynced": "Synchronisé avec {calendar}",
  "@healthCalendarSynced": { "placeholders": { "calendar": { "type": "String" } } },
  "healthCalendarNotConfigured": "RDV non ajoutés au Calendrier (à régler dans Réglages)"
```

- [ ] **Step 2: Write the failing tests**

```dart
// test/features/health/presentation/health_card_test.dart
import 'package:colette/app/router/app_router.dart';
import 'package:colette/core/clock/app_clock.dart';
import 'package:colette/core/clock/now_providers.dart';
import 'package:colette/core/connectivity/connectivity_provider.dart';
import 'package:colette/core/theme/theme_service.dart';
import 'package:colette/features/health/domain/entities/medical_stage.dart';
import 'package:colette/features/health/domain/entities/medical_stage_status.dart';
import 'package:colette/features/health/domain/entities/medical_timeline.dart';
import 'package:colette/features/health/domain/reference/medical_schedule.dart';
import 'package:colette/features/health/presentation/providers/health_providers.dart';
import 'package:colette/features/health/presentation/widgets/health_card.dart';
import 'package:colette/l10n/generated/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

import '../health_factories.dart';

MedicalTimelineEntry entry(
  MedicalStageId id,
  MedicalStageStatus status, {
  DateTime? appointmentAt,
  String? practitioner,
}) => MedicalTimelineEntry(
  stage: stageById(id),
  dueFrom: DateTime(2026, 11, 1),
  dueUntil: DateTime(2026, 12, 1),
  status: status,
  visit: switch (status) {
    MedicalStageStatus.done => makeVisit(id, doneAt: DateTime(2026, 9, 4)),
    _ when appointmentAt != null => makeVisit(
      id,
      appointmentAt: appointmentAt,
      practitioner: practitioner,
    ),
    _ => null,
  },
);

void main() {
  Future<void> pumpCard(WidgetTester tester, MedicalTimeline? timeline) async {
    final router = GoRouter(
      initialLocation: AppRoutes.today,
      routes: [
        GoRoute(
          path: AppRoutes.today,
          builder: (_, _) => const Scaffold(body: HealthCard()),
          routes: [
            GoRoute(
              path: 'health',
              builder: (_, _) => const Scaffold(body: Text('page santé')),
            ),
          ],
        ),
      ],
    );
    addTearDown(router.dispose);
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          isOnlineProvider.overrideWith((ref) => Stream.value(true)),
          clockProvider.overrideWithValue(FixedClock(DateTime(2026, 10, 20))),
          minuteTickerProvider.overrideWith((ref) => const Stream.empty()),
          medicalTimelineProvider.overrideWithValue(timeline),
        ],
        child: MaterialApp.router(
          theme: const ThemeService().light(),
          locale: const Locale('fr'),
          localizationsDelegates: S.localizationsDelegates,
          supportedLocales: S.supportedLocales,
          routerConfig: router,
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  testWidgets('étape à faire : libellé et fenêtre', (tester) async {
    await pumpCard(
      tester,
      MedicalTimeline(entries: [entry(MedicalStageId.m2, MedicalStageStatus.due)]),
    );
    expect(find.text('Examen et vaccins des 2 mois'), findsOneWidget);
    expect(
      find.text('À faire du 1 nov. 2026 au 30 nov. 2026'),
      findsOneWidget,
    );
  });

  testWidgets('RDV pris : date, heure et praticien', (tester) async {
    await pumpCard(
      tester,
      MedicalTimeline(
        entries: [
          entry(
            MedicalStageId.m2,
            MedicalStageStatus.scheduled,
            appointmentAt: DateTime(2026, 11, 3, 10),
            practitioner: 'Dr Martin',
          ),
        ],
      ),
    );
    expect(
      find.text('RDV le mar. 3 nov., 10h00 · Dr Martin'),
      findsOneWidget,
    );
  });

  testWidgets('en retard', (tester) async {
    await pumpCard(
      tester,
      MedicalTimeline(entries: [entry(MedicalStageId.m2, MedicalStageStatus.late)]),
    );
    expect(find.text('En retard depuis le 1 déc. 2026'), findsOneWidget);
  });

  testWidgets('tap : ouvre la page Santé', (tester) async {
    await pumpCard(
      tester,
      MedicalTimeline(entries: [entry(MedicalStageId.m2, MedicalStageStatus.due)]),
    );
    await tester.tap(find.byType(HealthCard));
    await tester.pumpAndSettle();
    expect(find.text('page santé'), findsOneWidget);
  });

  testWidgets('sans profil : rien', (tester) async {
    await pumpCard(tester, null);
    expect(find.text('Santé'), findsNothing);
  });
}
```

```dart
// test/features/health/presentation/health_page_test.dart
import 'package:colette/core/firebase/firebase_providers.dart';
import 'package:colette/features/health/domain/entities/medical_stage.dart';
import 'package:colette/features/health/domain/entities/medical_stage_status.dart';
import 'package:colette/features/health/domain/entities/medical_timeline.dart';
import 'package:colette/features/health/presentation/pages/health_page.dart';
import 'package:colette/features/health/presentation/providers/health_providers.dart';
import 'package:colette/features/health/presentation/providers/health_sync.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../helpers/pump_app.dart';
import 'health_card_test.dart' show entry;

void main() {
  testWidgets('sections par statut, faites repliées', (tester) async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    await pumpApp(
      tester,
      const HealthPage(),
      overrides: [
        sharedPreferencesProvider.overrideWithValue(prefs),
        healthSyncProvider.overrideWithValue(const NoopHealthSync()),
        medicalTimelineProvider.overrideWithValue(
          MedicalTimeline(
            entries: [
              entry(MedicalStageId.day8, MedicalStageStatus.done),
              entry(MedicalStageId.week2, MedicalStageStatus.late),
              entry(MedicalStageId.m2, MedicalStageStatus.due),
              entry(MedicalStageId.m3, MedicalStageStatus.upcoming),
            ],
          ),
        ),
      ],
    );
    expect(find.text('Santé'), findsOneWidget);
    expect(find.text('En retard'), findsOneWidget);
    expect(find.text('Examen de la 2e semaine'), findsOneWidget);
    expect(find.text('À faire'), findsOneWidget);
    expect(find.text('À venir'), findsOneWidget);
    expect(find.text('Faites (1)'), findsOneWidget);
    expect(find.text('Examen des 8 jours'), findsNothing);
    expect(
      find.text('RDV non ajoutés au Calendrier (à régler dans Réglages)'),
      findsOneWidget,
    );

    await tester.tap(find.text('Faites (1)'));
    await tester.pumpAndSettle();
    expect(find.text('Examen des 8 jours'), findsOneWidget);
  });
}
```

- [ ] **Step 3: Run tests to verify they fail**

Run: `flutter test test/features/health/presentation`
Expected: FAIL.

- [ ] **Step 4: Implement**

```dart
// lib/features/health/presentation/widgets/health_status_text.dart
import 'package:colette/core/dates/time_format.dart';
import 'package:colette/features/health/domain/entities/medical_stage_status.dart';
import 'package:colette/features/health/domain/entities/medical_timeline.dart';
import 'package:colette/l10n/generated/app_localizations.dart';

/// Phrase de statut d'une étape : fenêtre, RDV, retard, date de visite.
String healthStatusText(S s, MedicalTimelineEntry entry) {
  final visit = entry.visit;
  final lastDay = DateTime(
    entry.dueUntil.year,
    entry.dueUntil.month,
    entry.dueUntil.day - 1,
  );
  return switch (entry.status) {
    MedicalStageStatus.done => s.healthDoneOn(formatShortDate(visit!.doneAt!)),
    MedicalStageStatus.appointmentPassed => s.healthAppointmentPassed(
      formatShortDate(visit!.appointmentAt!),
    ),
    MedicalStageStatus.scheduled => switch (visit!.practitioner) {
      final name? when name.trim().isNotEmpty => s.healthScheduledWith(
        formatDayAndTime(visit.appointmentAt!),
        name,
      ),
      _ => s.healthScheduled(formatDayAndTime(visit.appointmentAt!)),
    },
    MedicalStageStatus.late => s.healthLateSince(
      formatShortDate(entry.dueUntil),
    ),
    MedicalStageStatus.due || MedicalStageStatus.upcoming => s.healthDueWindow(
      formatShortDate(entry.dueFrom),
      formatShortDate(lastDay),
    ),
  };
}
```

```dart
// lib/features/health/presentation/widgets/health_card.dart
import 'package:colette/app/router/app_router.dart';
import 'package:colette/core/clock/now_providers.dart';
import 'package:colette/core/dates/time_format.dart';
import 'package:colette/core/theme/app_colors.dart';
import 'package:colette/core/theme/design_tokens.dart';
import 'package:colette/core/theme/text_styles.dart';
import 'package:colette/features/health/domain/entities/medical_stage_status.dart';
import 'package:colette/features/health/domain/entities/medical_timeline.dart';
import 'package:colette/features/health/presentation/providers/health_providers.dart';
import 'package:colette/features/health/presentation/widgets/health_labels.dart';
import 'package:colette/features/health/presentation/widgets/health_status_text.dart';
import 'package:colette/l10n/generated/app_localizations.dart';
import 'package:colette/shared/ui/widgets/colette_card_surface.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

/// Carte « Santé » d'Aujourd'hui : prochaine étape du suivi médical.
class HealthCard extends ConsumerWidget {
  const HealthCard({super.key});

  /// Au-delà, une étape à venir s'affiche en une ligne discrète.
  static const farDays = 30;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final timeline = ref.watch(medicalTimelineProvider);
    if (timeline == null) return const SizedBox.shrink();
    final s = S.of(context);
    final styles = Theme.of(context).coletteTextStyles;
    final secondary = context.appColor(AppColors.textSecondary);
    final next = timeline.next;
    final now = ref.watch(currentMinuteProvider);
    return ColetteCardSurface(
      onTap: () => context.push(AppRoutes.health),
      child: Row(
        spacing: AppSpacing.sm.value,
        children: [
          Icon(
            Icons.medical_services_outlined,
            color: context.appColor(AppColors.primary),
          ),
          Expanded(
            child: Column(
              crossAxisAlignment: .start,
              spacing: AppSpacing.xxs.value,
              children: [
                Text(s.healthTitle, style: styles.bodyMedium),
                ..._lines(context, s, next, now),
              ],
            ),
          ),
          Icon(Icons.chevron_right, color: secondary),
        ],
      ),
    );
  }

  List<Widget> _lines(
    BuildContext context,
    S s,
    MedicalTimelineEntry? next,
    DateTime now,
  ) {
    final styles = Theme.of(context).coletteTextStyles;
    final secondary = styles.small.copyWith(
      color: context.appColor(AppColors.textSecondary),
    );
    if (next == null) return [Text(s.healthAllDone, style: secondary)];
    final label = HealthLabels.stage(s, next.stage.id);
    final far =
        next.status == MedicalStageStatus.upcoming &&
        next.dueFrom.difference(now).inDays > farDays;
    if (far) {
      return [
        Text(
          s.healthNextFar(label, formatShortDate(next.dueFrom)),
          style: secondary,
        ),
      ];
    }
    final late = next.status == MedicalStageStatus.late;
    return [
      Text(label, style: styles.body),
      Text(
        healthStatusText(s, next),
        style: late
            ? styles.small.copyWith(color: context.appColor(AppColors.warning))
            : secondary,
      ),
    ];
  }
}
```

```dart
// lib/features/health/presentation/widgets/medical_stage_tile.dart
import 'package:colette/core/theme/app_colors.dart';
import 'package:colette/core/theme/design_tokens.dart';
import 'package:colette/core/theme/text_styles.dart';
import 'package:colette/features/health/domain/entities/medical_stage_status.dart';
import 'package:colette/features/health/domain/entities/medical_timeline.dart';
import 'package:colette/features/health/presentation/widgets/health_labels.dart';
import 'package:colette/features/health/presentation/widgets/health_status_text.dart';
import 'package:colette/l10n/generated/app_localizations.dart';
import 'package:flutter/material.dart';

/// Ligne d'une étape : libellé, pastilles, statut ; [onTap] ouvre la feuille.
class MedicalStageTile extends StatelessWidget {
  const MedicalStageTile({super.key, required this.entry, this.onTap});

  final MedicalTimelineEntry entry;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    final styles = Theme.of(context).coletteTextStyles;
    final stage = entry.stage;
    final late = entry.status == MedicalStageStatus.late;
    return ListTile(
      contentPadding: AppSpacing.sm.horizontal,
      onTap: onTap,
      title: Text(HealthLabels.stage(s, stage.id), style: styles.bodyMedium),
      subtitle: Column(
        crossAxisAlignment: .start,
        spacing: AppSpacing.xxs.value,
        children: [
          Wrap(
            spacing: AppSpacing.xs.value,
            children: [
              if (stage.hasExam) _Chip(label: s.healthChipExam),
              if (stage.hasVaccines) _Chip(label: s.healthChipVaccines),
              if (stage.hasCertificate) _Chip(label: s.healthChipCertificate),
            ],
          ),
          Text(
            healthStatusText(s, entry),
            style: styles.small.copyWith(
              color: context.appColor(
                late ? AppColors.warning : AppColors.textSecondary,
              ),
            ),
          ),
        ],
      ),
      trailing: Icon(
        Icons.chevron_right,
        color: context.appColor(AppColors.textSecondary),
      ),
    );
  }
}

class _Chip extends StatelessWidget {
  const _Chip({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) => Container(
    padding: AppSpacing.symmetric(
      horizontal: AppSpacing.xs,
      vertical: AppSpacing.xxs,
    ),
    decoration: BoxDecoration(
      color: context.appColor(AppColors.surfaceContainer),
      borderRadius: AppRadius.sm.circular,
    ),
    child: Text(label, style: Theme.of(context).coletteTextStyles.small),
  );
}
```

```dart
// lib/features/health/presentation/pages/health_page.dart
import 'package:colette/core/theme/app_colors.dart';
import 'package:colette/core/theme/design_tokens.dart';
import 'package:colette/core/theme/text_styles.dart';
import 'package:colette/core/ui/failure_message.dart';
import 'package:colette/features/health/domain/entities/medical_stage_status.dart';
import 'package:colette/features/health/domain/entities/medical_timeline.dart';
import 'package:colette/features/health/presentation/providers/health_providers.dart';
import 'package:colette/features/health/presentation/providers/health_sync.dart';
import 'package:colette/features/health/presentation/providers/medical_visit_controller.dart';
import 'package:colette/features/health/presentation/providers/selected_calendar.dart';
import 'package:colette/features/health/presentation/widgets/medical_stage_tile.dart';
import 'package:colette/l10n/generated/app_localizations.dart';
import 'package:colette/shared/ui/widgets/colette_card_surface.dart';
import 'package:colette/shared/ui/widgets/section_header.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Page Santé : étapes en retard, à faire, à venir et faites.
class HealthPage extends ConsumerStatefulWidget {
  const HealthPage({super.key});

  @override
  ConsumerState<HealthPage> createState() => _HealthPageState();
}

class _HealthPageState extends ConsumerState<HealthPage> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) ref.read(healthSyncProvider).sync();
    });
  }

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    // Garde le contrôleur autoDispose vivant pendant les écritures de la feuille.
    ref.listen(medicalVisitControllerProvider, (_, next) {
      if (next case AsyncError(:final error)) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(failureMessage(error, s))));
      }
    });
    final timeline = ref.watch(medicalTimelineProvider);
    final entries = timeline?.entries ?? const <MedicalTimelineEntry>[];
    List<MedicalTimelineEntry> where(Set<MedicalStageStatus> statuses) =>
        [for (final e in entries) if (statuses.contains(e.status)) e];
    final late = where({MedicalStageStatus.late});
    final toDo = where({
      MedicalStageStatus.appointmentPassed,
      MedicalStageStatus.scheduled,
      MedicalStageStatus.due,
    });
    final upcoming = where({MedicalStageStatus.upcoming});
    final done = where({MedicalStageStatus.done});
    return Scaffold(
      appBar: AppBar(title: Text(s.healthTitle)),
      body: ListView(
        padding: AppSpacing.md.horizontal,
        children: [
          const _CalendarStatus(),
          if (late.isNotEmpty) _Section(title: s.healthSectionLate, entries: late),
          if (toDo.isNotEmpty) _Section(title: s.healthSectionToDo, entries: toDo),
          if (upcoming.isNotEmpty)
            _Section(title: s.healthSectionUpcoming, entries: upcoming),
          if (done.isNotEmpty) _DoneSection(entries: done),
          AppSpacing.xl.verticalSpace,
        ],
      ),
    );
  }
}

/// Calendrier synchronisé sur cet iPhone, ou invitation à le régler.
class _CalendarStatus extends ConsumerWidget {
  const _CalendarStatus();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final s = S.of(context);
    final choice = ref.watch(selectedCalendarProvider);
    return Padding(
      padding: AppSpacing.md.vertical,
      child: Row(
        spacing: AppSpacing.sm.value,
        children: [
          Icon(
            choice == null ? Icons.event_busy_outlined : Icons.event_available,
            color: context.appColor(AppColors.textSecondary),
          ),
          Expanded(
            child: Text(
              choice == null
                  ? s.healthCalendarNotConfigured
                  : s.healthCalendarSynced(choice.title),
              style: Theme.of(context).coletteTextStyles.small.copyWith(
                color: context.appColor(AppColors.textSecondary),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _Section extends StatelessWidget {
  const _Section({required this.title, required this.entries});

  final String title;
  final List<MedicalTimelineEntry> entries;

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: .stretch,
    children: [
      SectionHeader(title: title),
      ColetteCardSurface(
        padding: AppSpacing.xs.all,
        child: Column(
          children: [
            for (final entry in entries)
              MedicalStageTile(
                entry: entry,
                onTap: () => showMedicalStageSheet(context, entry),
              ),
          ],
        ),
      ),
    ],
  );
}

/// Étapes faites, repliées par défaut.
class _DoneSection extends StatelessWidget {
  const _DoneSection({required this.entries});

  final List<MedicalTimelineEntry> entries;

  @override
  Widget build(BuildContext context) => Padding(
    padding: AppSpacing.md.top,
    child: ColetteCardSurface(
      padding: AppSpacing.xs.all,
      child: ExpansionTile(
        title: Text(
          S.of(context).healthSectionDone(entries.length),
          style: Theme.of(context).coletteTextStyles.bodyMedium,
        ),
        shape: const Border(),
        collapsedShape: const Border(),
        children: [
          for (final entry in entries)
            MedicalStageTile(
              entry: entry,
              onTap: () => showMedicalStageSheet(context, entry),
            ),
        ],
      ),
    ),
  );
}
```

`showMedicalStageSheet` est créé à la tâche 10. Pour cette tâche, ajouter temporairement dans `health_page.dart` :

```dart
/// Remplacée par la feuille d'étape à la tâche 10.
Future<void> showMedicalStageSheet(
  BuildContext context,
  MedicalTimelineEntry entry,
) async {}
```

Route, dans `app_router.dart` : importer `health_page.dart`, ajouter dans `AppRoutes`

```dart
  /// Page Santé, imbriquée sous Aujourd'hui pour garder la barre d'onglets.
  static const health = '/today/health';
```

et, sous la route `AppRoutes.today`, à côté de `growth` :

```dart
                  GoRoute(
                    path: 'health',
                    builder: (_, _) => const HealthPage(),
                  ),
```

Accueil, dans `dashboard_page.dart` : importer `health_card.dart` et insérer après `const WeightCard(),` :

```dart
            AppSpacing.md.verticalSpace,
            const HealthCard(),
```

Mettre à jour la doc de classe (« …poids, santé, documents. »). Les tests de `dashboard_page_test.dart` qui montent la page doivent surcharger `medicalTimelineProvider.overrideWithValue(null)` s'ils échouent faute de Firestore.

- [ ] **Step 5: Generate and run tests**

```bash
dart run build_runner build -d
flutter gen-l10n
flutter test test/features/health test/features/dashboard test/app
```
Expected: PASS.

- [ ] **Step 6: Commit**

```bash
dart format lib test && dart analyze && flutter test
git add lib/features/health lib/app/router lib/features/dashboard/presentation/pages/dashboard_page.dart lib/l10n/app_fr.arb test/features/health test/features/dashboard
git commit -m "feat: carte Santé sur l'accueil et page du suivi médical"
```

---

### Task 10 : feuille d'étape (RDV, vaccins, visite)

**Files:**
- Create: `lib/features/health/presentation/widgets/medical_stage_sheet.dart`, `lib/features/health/presentation/widgets/stage_appointment_fields.dart`, `lib/features/health/presentation/widgets/stage_vaccine_row.dart`, `lib/features/health/presentation/widgets/stage_visit_fields.dart`
- Modify: `lib/features/health/presentation/pages/health_page.dart` (retirer la fonction provisoire, importer la feuille), `lib/l10n/app_fr.arb`
- Test: `test/features/health/presentation/medical_stage_sheet_test.dart`

- [ ] **Step 1: Chaînes**

```json
  "healthSheetAppointment": "Rendez-vous",
  "healthSheetPickAppointment": "Choisir la date du RDV",
  "healthSheetRemoveAppointment": "Retirer le RDV",
  "healthSheetPractitioner": "Praticien (facultatif)",
  "healthSheetVaccines": "Vaccins",
  "healthSheetRecommended": "recommandé",
  "healthSheetGivenOn": "Date de l'injection",
  "healthSheetBrand": "Nom commercial (facultatif)",
  "healthSheetLot": "N° de lot (facultatif)",
  "healthSheetVisit": "Visite",
  "healthSheetMarkDone": "Marquer comme faite",
  "healthSheetCancelDone": "Annuler la visite",
  "healthSheetDoneOn": "Date de la visite",
  "healthSheetNote": "Note (facultatif)"
```

- [ ] **Step 2: Write the failing test**

```dart
// test/features/health/presentation/medical_stage_sheet_test.dart
import 'dart:async';

import 'package:colette/core/clock/app_clock.dart';
import 'package:colette/core/result/failure.dart';
import 'package:colette/features/baby/domain/entities/baby_profile.dart';
import 'package:colette/features/baby/presentation/providers/baby_providers.dart';
import 'package:colette/features/health/domain/entities/medical_stage.dart';
import 'package:colette/features/health/domain/entities/medical_stage_status.dart';
import 'package:colette/features/health/domain/entities/medical_timeline.dart';
import 'package:colette/features/health/domain/entities/medical_visit.dart';
import 'package:colette/features/health/domain/entities/vaccine_code.dart';
import 'package:colette/features/health/domain/reference/medical_schedule.dart';
import 'package:colette/features/health/domain/repositories/medical_repository.dart';
import 'package:colette/features/health/presentation/providers/health_providers.dart';
import 'package:colette/features/health/presentation/providers/health_sync.dart';
import 'package:colette/features/health/presentation/widgets/medical_stage_sheet.dart';
import 'package:colette/features/household/presentation/providers/household_providers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:mocktail/mocktail.dart';

import '../../../helpers/in_memory_household_local_store.dart';
import '../../../helpers/pump_app.dart';
import '../health_factories.dart';

class MockMedicalRepository extends Mock implements MedicalRepository {}

void main() {
  late MockMedicalRepository repo;
  final now = DateTime(2026, 11, 10, 12);

  setUpAll(() {
    registerFallbackValue(makeVisit(MedicalStageId.day8));
    registerFallbackValue(MedicalStageId.day8);
  });

  setUp(() {
    repo = MockMedicalRepository();
    when(() => repo.saveVisit(any(), any())).thenAnswer((_) async => right(null));
  });

  List<Override> overrides() => [
    clockProvider.overrideWithValue(FixedClock(now)),
    babyProfileProvider.overrideWith(
      (ref) => Stream.value(
        BabyProfile(name: 'Colette', birthDate: DateTime(2026, 9, 1)),
      ),
    ),
    medicalRepositoryProvider.overrideWithValue(repo),
    healthSyncProvider.overrideWithValue(const NoopHealthSync()),
    householdLocalStoreProvider.overrideWithValue(
      InMemoryHouseholdLocalStore(householdCode: 'ABCDEFGH'),
    ),
  ];

  MedicalTimelineEntry m2Entry([MedicalVisit? visit]) => MedicalTimelineEntry(
    stage: stageById(MedicalStageId.m2),
    dueFrom: DateTime(2026, 11, 1),
    dueUntil: DateTime(2026, 12, 1),
    status: MedicalStageStatus.due,
    visit: visit,
  );

  MedicalVisit saved() =>
      verify(() => repo.saveVisit('ABCDEFGH', captureAny())).captured.single
          as MedicalVisit;

  testWidgets('affiche les vaccins attendus, recommandés signalés', (tester) async {
    await pumpApp(
      tester,
      Scaffold(body: MedicalStageSheet(entry: m2Entry())),
      overrides: overrides(),
    );
    expect(find.text('Examen et vaccins des 2 mois'), findsOneWidget);
    expect(find.text('Hexavalent (DTCaP-Hib-HépB)'), findsOneWidget);
    expect(find.text('Pneumocoque'), findsOneWidget);
    expect(find.textContaining('recommandé'), findsOneWidget);
  });

  testWidgets('cocher un vaccin avec son lot puis marquer faite', (tester) async {
    await pumpApp(
      tester,
      Scaffold(body: MedicalStageSheet(entry: m2Entry())),
      overrides: overrides(),
    );
    await tester.tap(find.text('Hexavalent (DTCaP-Hib-HépB)'));
    await tester.pumpAndSettle();
    await tester.enterText(
      find.widgetWithText(TextField, 'N° de lot (facultatif)'),
      'A123',
    );
    await tester.ensureVisible(find.text('Marquer comme faite'));
    await tester.tap(find.text('Marquer comme faite'));
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.text('Enregistrer'));
    await tester.tap(find.text('Enregistrer'));
    await tester.pumpAndSettle();
    final visit = saved();
    expect(visit.doneAt, now);
    expect(visit.vaccines[VaccineCode.hexavalent]!.lot, 'A123');
    expect(visit.vaccines[VaccineCode.hexavalent]!.givenAt, now);
    expect(visit.vaccines.containsKey(VaccineCode.pneumococcal), isFalse);
  });

  testWidgets('préremplit le praticien et retire le RDV', (tester) async {
    await pumpApp(
      tester,
      Scaffold(
        body: MedicalStageSheet(
          entry: m2Entry(
            makeVisit(
              MedicalStageId.m2,
              appointmentAt: DateTime(2026, 11, 20, 10),
              practitioner: 'Dr Martin',
            ),
          ),
        ),
      ),
      overrides: overrides(),
    );
    expect(find.text('Dr Martin'), findsOneWidget);
    await tester.tap(find.text('Retirer le RDV'));
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.text('Enregistrer'));
    await tester.tap(find.text('Enregistrer'));
    await tester.pumpAndSettle();
    expect(saved().appointmentAt, isNull);
  });

  testWidgets('bouton inactif pendant l\'écriture', (tester) async {
    final completer = Completer<Either<Failure, void>>();
    when(() => repo.saveVisit(any(), any())).thenAnswer((_) => completer.future);
    await pumpApp(
      tester,
      Scaffold(
        body: MedicalStageSheet(
          entry: m2Entry(makeVisit(MedicalStageId.m2, note: 'x')),
        ),
      ),
      overrides: overrides(),
    );
    await tester.ensureVisible(find.text('Enregistrer'));
    await tester.tap(find.text('Enregistrer'));
    await tester.pump();
    expect(
      tester.widget<FilledButton>(find.widgetWithText(FilledButton, 'Enregistrer')).onPressed,
      isNull,
    );
    completer.complete(right(null));
    await tester.pumpAndSettle();
  });
}
```

- [ ] **Step 3: Run test to verify it fails**

Run: `flutter test test/features/health/presentation/medical_stage_sheet_test.dart`
Expected: FAIL.

- [ ] **Step 4: Implement**

```dart
// lib/features/health/presentation/widgets/stage_appointment_fields.dart
import 'package:colette/core/dates/time_format.dart';
import 'package:colette/core/theme/design_tokens.dart';
import 'package:colette/core/ui/date_time_picker.dart';
import 'package:colette/l10n/generated/app_localizations.dart';
import 'package:colette/shared/ui/widgets/date_field.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

/// Date et heure du RDV, praticien, et bouton pour retirer le RDV.
class StageAppointmentFields extends StatelessWidget {
  const StageAppointmentFields({
    super.key,
    required this.appointmentAt,
    required this.practitioner,
    required this.minimum,
    required this.initialPick,
    required this.onChanged,
  });

  final DateTime? appointmentAt;
  final TextEditingController practitioner;

  /// Borne basse du sélecteur (naissance).
  final DateTime minimum;

  /// Date proposée quand aucun RDV n'est posé.
  final DateTime initialPick;
  final ValueChanged<DateTime?> onChanged;

  Future<void> _pick(BuildContext context) async {
    final picked = await showColetteDateTimePicker(
      context,
      initial: appointmentAt ?? initialPick,
      mode: CupertinoDatePickerMode.dateAndTime,
      minimum: minimum,
    );
    if (picked != null) onChanged(picked);
  }

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    return Column(
      crossAxisAlignment: .stretch,
      spacing: AppSpacing.sm.value,
      children: [
        DateField(
          label: s.healthSheetAppointment,
          value: appointmentAt == null
              ? s.healthSheetPickAppointment
              : formatDayAndTime(appointmentAt!),
          onTap: () => _pick(context),
        ),
        if (appointmentAt != null) ...[
          TextField(
            controller: practitioner,
            decoration: InputDecoration(labelText: s.healthSheetPractitioner),
            textCapitalization: .words,
          ),
          Align(
            alignment: .centerLeft,
            child: TextButton.icon(
              onPressed: () => onChanged(null),
              icon: const Icon(Icons.event_busy_outlined),
              label: Text(s.healthSheetRemoveAppointment),
            ),
          ),
        ],
      ],
    );
  }
}
```

```dart
// lib/features/health/presentation/widgets/stage_vaccine_row.dart
import 'package:colette/core/dates/time_format.dart';
import 'package:colette/core/theme/design_tokens.dart';
import 'package:colette/core/theme/text_styles.dart';
import 'package:colette/core/ui/date_time_picker.dart';
import 'package:colette/features/health/domain/entities/given_vaccine.dart';
import 'package:colette/features/health/domain/entities/medical_stage.dart';
import 'package:colette/features/health/presentation/widgets/health_labels.dart';
import 'package:colette/l10n/generated/app_localizations.dart';
import 'package:colette/shared/ui/widgets/date_field.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

/// Un vaccin attendu : case à cocher puis date, nom commercial et lot.
class StageVaccineRow extends StatefulWidget {
  const StageVaccineRow({
    super.key,
    required this.vaccine,
    required this.given,
    required this.defaultDate,
    required this.minimum,
    required this.maximum,
    required this.onChanged,
  });

  final ScheduledVaccine vaccine;
  final GivenVaccine? given;

  /// Date proposée à la coche (visite, sinon RDV, sinon aujourd'hui).
  final DateTime defaultDate;
  final DateTime minimum;
  final DateTime maximum;
  final ValueChanged<GivenVaccine?> onChanged;

  @override
  State<StageVaccineRow> createState() => _StageVaccineRowState();
}

class _StageVaccineRowState extends State<StageVaccineRow> {
  late final _brand = TextEditingController(text: widget.given?.brand ?? '');
  late final _lot = TextEditingController(text: widget.given?.lot ?? '');

  @override
  void dispose() {
    _brand.dispose();
    _lot.dispose();
    super.dispose();
  }

  static String? _clean(String text) =>
      text.trim().isEmpty ? null : text.trim();

  void _emit({DateTime? givenAt}) => widget.onChanged(
    GivenVaccine(
      givenAt: givenAt ?? widget.given?.givenAt ?? widget.defaultDate,
      brand: _clean(_brand.text),
      lot: _clean(_lot.text),
    ),
  );

  Future<void> _pickDate() async {
    final picked = await showColetteDateTimePicker(
      context,
      initial: widget.given?.givenAt ?? widget.defaultDate,
      mode: CupertinoDatePickerMode.date,
      minimum: widget.minimum,
      maximum: widget.maximum,
    );
    if (picked != null) _emit(givenAt: picked);
  }

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    final given = widget.given;
    final name = HealthLabels.vaccine(s, widget.vaccine.code);
    return Column(
      crossAxisAlignment: .stretch,
      children: [
        CheckboxListTile(
          contentPadding: EdgeInsets.zero,
          value: given != null,
          title: Text(
            widget.vaccine.recommended
                ? '$name · ${s.healthSheetRecommended}'
                : name,
            style: Theme.of(context).coletteTextStyles.body,
          ),
          onChanged: (checked) =>
              checked ?? false ? _emit() : widget.onChanged(null),
        ),
        if (given != null)
          Padding(
            padding: AppSpacing.md.left,
            child: Column(
              crossAxisAlignment: .stretch,
              spacing: AppSpacing.sm.value,
              children: [
                DateField(
                  label: s.healthSheetGivenOn,
                  value: formatShortDate(given.givenAt),
                  onTap: _pickDate,
                ),
                TextField(
                  controller: _brand,
                  decoration: InputDecoration(labelText: s.healthSheetBrand),
                  onChanged: (_) => _emit(),
                ),
                TextField(
                  controller: _lot,
                  decoration: InputDecoration(labelText: s.healthSheetLot),
                  onChanged: (_) => _emit(),
                ),
              ],
            ),
          ),
      ],
    );
  }
}
```

```dart
// lib/features/health/presentation/widgets/stage_visit_fields.dart
import 'package:colette/core/dates/time_format.dart';
import 'package:colette/core/theme/design_tokens.dart';
import 'package:colette/core/ui/date_time_picker.dart';
import 'package:colette/l10n/generated/app_localizations.dart';
import 'package:colette/shared/ui/widgets/date_field.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

/// Visite faite : bouton, date et note.
class StageVisitFields extends StatelessWidget {
  const StageVisitFields({
    super.key,
    required this.doneAt,
    required this.note,
    required this.defaultDate,
    required this.minimum,
    required this.maximum,
    required this.onDoneChanged,
  });

  final DateTime? doneAt;
  final TextEditingController note;
  final DateTime defaultDate;
  final DateTime minimum;
  final DateTime maximum;
  final ValueChanged<DateTime?> onDoneChanged;

  Future<void> _pick(BuildContext context) async {
    final picked = await showColetteDateTimePicker(
      context,
      initial: doneAt ?? defaultDate,
      mode: CupertinoDatePickerMode.date,
      minimum: minimum,
      maximum: maximum,
    );
    if (picked != null) onDoneChanged(picked);
  }

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    final done = doneAt;
    return Column(
      crossAxisAlignment: .stretch,
      spacing: AppSpacing.sm.value,
      children: [
        if (done == null)
          OutlinedButton.icon(
            onPressed: () => onDoneChanged(defaultDate),
            icon: const Icon(Icons.check_circle_outline),
            label: Text(s.healthSheetMarkDone),
          )
        else ...[
          DateField(
            label: s.healthSheetDoneOn,
            value: formatShortDate(done),
            onTap: () => _pick(context),
          ),
          TextButton.icon(
            onPressed: () => onDoneChanged(null),
            icon: const Icon(Icons.undo),
            label: Text(s.healthSheetCancelDone),
          ),
        ],
        TextField(
          controller: note,
          decoration: InputDecoration(labelText: s.healthSheetNote),
          maxLines: null,
        ),
      ],
    );
  }
}
```

```dart
// lib/features/health/presentation/widgets/medical_stage_sheet.dart
import 'package:colette/core/clock/app_clock.dart';
import 'package:colette/core/theme/design_tokens.dart';
import 'package:colette/core/theme/text_styles.dart';
import 'package:colette/features/baby/presentation/providers/baby_providers.dart';
import 'package:colette/features/health/domain/entities/given_vaccine.dart';
import 'package:colette/features/health/domain/entities/medical_timeline.dart';
import 'package:colette/features/health/domain/entities/medical_visit.dart';
import 'package:colette/features/health/domain/entities/vaccine_code.dart';
import 'package:colette/features/health/presentation/providers/medical_visit_controller.dart';
import 'package:colette/features/health/presentation/widgets/health_labels.dart';
import 'package:colette/features/health/presentation/widgets/stage_appointment_fields.dart';
import 'package:colette/features/health/presentation/widgets/stage_vaccine_row.dart';
import 'package:colette/features/health/presentation/widgets/stage_visit_fields.dart';
import 'package:colette/l10n/generated/app_localizations.dart';
import 'package:colette/shared/ui/widgets/section_header.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Ouvre la feuille de l'étape [entry].
Future<void> showMedicalStageSheet(
  BuildContext context,
  MedicalTimelineEntry entry,
) => showModalBottomSheet<void>(
  context: context,
  isScrollControlled: true,
  useSafeArea: true,
  builder: (_) => MedicalStageSheet(entry: entry),
);

/// Feuille d'une étape : RDV, vaccins attendus, visite faite.
class MedicalStageSheet extends ConsumerStatefulWidget {
  const MedicalStageSheet({super.key, required this.entry});

  final MedicalTimelineEntry entry;

  @override
  ConsumerState<MedicalStageSheet> createState() => _MedicalStageSheetState();
}

class _MedicalStageSheetState extends ConsumerState<MedicalStageSheet> {
  late final _practitioner = TextEditingController(
    text: widget.entry.visit?.practitioner ?? '',
  );
  late final _note = TextEditingController(text: widget.entry.visit?.note ?? '');
  late DateTime? _appointmentAt = widget.entry.visit?.appointmentAt;
  late DateTime? _doneAt = widget.entry.visit?.doneAt;
  late Map<VaccineCode, GivenVaccine> _vaccines = {
    ...?widget.entry.visit?.vaccines,
  };

  @override
  void dispose() {
    _practitioner.dispose();
    _note.dispose();
    super.dispose();
  }

  static String? _clean(String text) =>
      text.trim().isEmpty ? null : text.trim();

  Future<void> _save(DateTime birthDate) async {
    final now = ref.read(clockProvider).now();
    final visit = MedicalVisit(
      stageId: widget.entry.stage.id,
      appointmentAt: _appointmentAt,
      practitioner: _appointmentAt == null ? null : _clean(_practitioner.text),
      doneAt: _doneAt,
      note: _clean(_note.text),
      vaccines: _vaccines,
      updatedAt: now,
      updatedByDeviceId: '',
    );
    final ok = await ref
        .read(medicalVisitControllerProvider.notifier)
        .save(visit, birthDate: birthDate);
    if (ok && mounted) await Navigator.of(context).maybePop();
  }

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    final stage = widget.entry.stage;
    final birthDate = ref.watch(babyProfileProvider).value?.birthDate;
    final isSaving = ref.watch(medicalVisitControllerProvider) is AsyncLoading;
    final now = ref.watch(clockProvider).now();
    final minimum = birthDate ?? widget.entry.dueFrom;
    final defaultDate = _doneAt ?? _appointmentAt ?? now;
    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(context).bottom),
      child: ListView(
        shrinkWrap: true,
        padding: AppSpacing.lg.all,
        children: [
          Text(
            HealthLabels.stage(s, stage.id),
            style: Theme.of(context).coletteTextStyles.heading2,
          ),
          SectionHeader(title: s.healthSheetAppointment),
          StageAppointmentFields(
            appointmentAt: _appointmentAt,
            practitioner: _practitioner,
            minimum: minimum,
            initialPick: widget.entry.dueFrom.isAfter(now)
                ? widget.entry.dueFrom
                : now,
            onChanged: (value) => setState(() => _appointmentAt = value),
          ),
          if (stage.hasVaccines) ...[
            SectionHeader(title: s.healthSheetVaccines),
            for (final vaccine in stage.vaccines)
              StageVaccineRow(
                key: ValueKey(vaccine.code),
                vaccine: vaccine,
                given: _vaccines[vaccine.code],
                defaultDate: defaultDate.isAfter(now) ? now : defaultDate,
                minimum: minimum,
                maximum: now,
                onChanged: (given) => setState(
                  () => _vaccines = {
                    for (final e in _vaccines.entries)
                      if (e.key != vaccine.code) e.key: e.value,
                    if (given != null) vaccine.code: given,
                  },
                ),
              ),
          ],
          SectionHeader(title: s.healthSheetVisit),
          StageVisitFields(
            doneAt: _doneAt,
            note: _note,
            defaultDate: defaultDate.isAfter(now) ? now : defaultDate,
            minimum: minimum,
            maximum: now,
            onDoneChanged: (value) => setState(() => _doneAt = value),
          ),
          AppSpacing.lg.verticalSpace,
          FilledButton(
            onPressed: isSaving || birthDate == null
                ? null
                : () => _save(birthDate),
            child: Text(s.actionSave),
          ),
        ],
      ),
    );
  }
}
```

Dans `health_page.dart` : supprimer la fonction provisoire `showMedicalStageSheet` et importer `medical_stage_sheet.dart`.

Contrôler la taille : `medical_stage_sheet.dart` doit rester sous 300 lignes (≈ 170).

- [ ] **Step 5: Run tests**

```bash
flutter gen-l10n
flutter test test/features/health
```
Expected: PASS. Si un `tap` échoue parce que la cible est hors écran, utiliser `tester.ensureVisible` puis `pumpAndSettle` avant le `tap` (la `ListView` ne construit pas ce qui est loin sous la ligne de flottaison : `scrollUntilVisible` d'abord si besoin).

- [ ] **Step 6: Commit**

```bash
dart format lib test && dart analyze && flutter test
git add lib/features/health lib/l10n/app_fr.arb test/features/health
git commit -m "feat: feuille d'étape médicale, RDV, injections et visite"
```

---

### Task 11 : section « Calendrier » des Réglages

**Files:**
- Create: `lib/features/health/presentation/widgets/calendar_settings_section.dart`, `lib/features/health/presentation/widgets/calendar_picker_sheet.dart`
- Modify: `lib/features/baby/presentation/pages/settings_page.dart`, `lib/l10n/app_fr.arb`
- Test: `test/features/health/presentation/calendar_settings_section_test.dart`

- [ ] **Step 1: Chaînes**

```json
  "settingsCalendarSection": "Calendrier",
  "calendarSyncedTo": "RDV santé ajoutés à : {calendar}",
  "@calendarSyncedTo": { "placeholders": { "calendar": { "type": "String" } } },
  "calendarNotSynced": "Les RDV santé ne sont pas ajoutés au Calendrier de cet iPhone.",
  "calendarChoose": "Choisir un calendrier",
  "calendarChange": "Changer de calendrier",
  "calendarStop": "Ne plus synchroniser",
  "calendarPickerTitle": "Calendrier des RDV santé",
  "calendarPickerHint": "Choisis le calendrier iCloud partagé du foyer : un seul événement par RDV, quel que soit l'iPhone qui le saisit.",
  "calendarPickerEmpty": "Aucun calendrier modifiable sur cet iPhone."
```

- [ ] **Step 2: Write the failing test**

```dart
// test/features/health/presentation/calendar_settings_section_test.dart
import 'package:colette/core/firebase/firebase_providers.dart';
import 'package:colette/features/health/domain/entities/device_calendar.dart';
import 'package:colette/features/health/domain/repositories/calendar_repository.dart';
import 'package:colette/features/health/presentation/providers/health_providers.dart';
import 'package:colette/features/health/presentation/providers/health_sync.dart';
import 'package:colette/features/health/presentation/providers/selected_calendar.dart';
import 'package:colette/features/health/presentation/widgets/calendar_settings_section.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:mocktail/mocktail.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../helpers/pump_app.dart';

class MockCalendarRepository extends Mock implements CalendarRepository {}

void main() {
  late MockCalendarRepository calendar;
  late SharedPreferences prefs;

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    prefs = await SharedPreferences.getInstance();
    calendar = MockCalendarRepository();
  });

  List<Override> overrides() => [
    sharedPreferencesProvider.overrideWithValue(prefs),
    calendarRepositoryProvider.overrideWithValue(calendar),
    healthSyncProvider.overrideWithValue(const NoopHealthSync()),
  ];

  testWidgets('choisir un calendrier le mémorise', (tester) async {
    when(() => calendar.requestAccess()).thenAnswer((_) async => right(true));
    when(() => calendar.listCalendars()).thenAnswer(
      (_) async => right(const [
        DeviceCalendar(id: 'c1', title: 'Famille', source: 'iCloud'),
      ]),
    );
    await pumpApp(
      tester,
      const Scaffold(body: CalendarSettingsSection()),
      overrides: overrides(),
    );
    expect(
      find.text('Les RDV santé ne sont pas ajoutés au Calendrier de cet iPhone.'),
      findsOneWidget,
    );
    await tester.tap(find.text('Choisir un calendrier'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Famille'));
    await tester.pumpAndSettle();
    expect(find.text('RDV santé ajoutés à : Famille'), findsOneWidget);
    expect(prefs.getString(SelectedCalendar.idKey), 'c1');
  });

  testWidgets('accès refusé : message d\'erreur', (tester) async {
    when(() => calendar.requestAccess()).thenAnswer((_) async => right(false));
    await pumpApp(
      tester,
      const Scaffold(body: CalendarSettingsSection()),
      overrides: overrides(),
    );
    await tester.tap(find.text('Choisir un calendrier'));
    await tester.pumpAndSettle();
    expect(
      find.text(
        "Colette n'a pas accès au Calendrier. Autorise-le dans Réglages iOS › Colette › Calendriers.",
      ),
      findsOneWidget,
    );
    verifyNever(() => calendar.listCalendars());
  });

  testWidgets('ne plus synchroniser efface le choix', (tester) async {
    await prefs.setString(SelectedCalendar.idKey, 'c1');
    await prefs.setString(SelectedCalendar.titleKey, 'Famille');
    await pumpApp(
      tester,
      const Scaffold(body: CalendarSettingsSection()),
      overrides: overrides(),
    );
    await tester.tap(find.text('Ne plus synchroniser'));
    await tester.pumpAndSettle();
    expect(find.text('Choisir un calendrier'), findsOneWidget);
    expect(prefs.getString(SelectedCalendar.idKey), isNull);
  });
}
```

- [ ] **Step 3: Run test to verify it fails**

Run: `flutter test test/features/health/presentation/calendar_settings_section_test.dart`
Expected: FAIL.

- [ ] **Step 4: Implement**

```dart
// lib/features/health/presentation/widgets/calendar_picker_sheet.dart
import 'package:colette/core/theme/app_colors.dart';
import 'package:colette/core/theme/design_tokens.dart';
import 'package:colette/core/theme/text_styles.dart';
import 'package:colette/features/health/domain/entities/device_calendar.dart';
import 'package:colette/l10n/generated/app_localizations.dart';
import 'package:flutter/material.dart';

/// Liste des calendriers modifiables ; renvoie celui choisi, ou `null`.
Future<DeviceCalendar?> showCalendarPickerSheet(
  BuildContext context,
  List<DeviceCalendar> calendars,
) => showModalBottomSheet<DeviceCalendar>(
  context: context,
  isScrollControlled: true,
  useSafeArea: true,
  builder: (_) => CalendarPickerSheet(calendars: calendars),
);

/// Choix du calendrier des RDV santé.
class CalendarPickerSheet extends StatelessWidget {
  const CalendarPickerSheet({super.key, required this.calendars});

  final List<DeviceCalendar> calendars;

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    final styles = Theme.of(context).coletteTextStyles;
    final secondary = context.appColor(AppColors.textSecondary);
    return Padding(
      padding: AppSpacing.lg.all,
      child: Column(
        mainAxisSize: .min,
        crossAxisAlignment: .stretch,
        spacing: AppSpacing.sm.value,
        children: [
          Text(s.calendarPickerTitle, style: styles.heading2),
          Text(
            s.calendarPickerHint,
            style: styles.small.copyWith(color: secondary),
          ),
          if (calendars.isEmpty)
            Text(s.calendarPickerEmpty, style: styles.body)
          else
            Flexible(
              child: ListView.builder(
                shrinkWrap: true,
                itemCount: calendars.length,
                itemBuilder: (context, index) {
                  final calendar = calendars[index];
                  return ListTile(
                    leading: Icon(
                      Icons.circle,
                      size: AppSize.xxs.value,
                      color: context.appColor(AppColors.primary),
                    ),
                    title: Text(calendar.title, style: styles.bodyMedium),
                    subtitle: Text(
                      calendar.source,
                      style: styles.small.copyWith(color: secondary),
                    ),
                    onTap: () => Navigator.of(context).pop(calendar),
                  );
                },
              ),
            ),
        ],
      ),
    );
  }
}
```

La couleur réelle du calendrier (`colorHex`) n'est pas affichée : `Color(0x…)` est interdit hors `app_colors.dart`. La pastille prend la couleur primaire.

```dart
// lib/features/health/presentation/widgets/calendar_settings_section.dart
import 'package:colette/core/theme/app_colors.dart';
import 'package:colette/core/theme/design_tokens.dart';
import 'package:colette/core/theme/text_styles.dart';
import 'package:colette/core/ui/failure_message.dart';
import 'package:colette/features/health/presentation/providers/calendar_settings_controller.dart';
import 'package:colette/features/health/presentation/providers/selected_calendar.dart';
import 'package:colette/features/health/presentation/widgets/calendar_picker_sheet.dart';
import 'package:colette/l10n/generated/app_localizations.dart';
import 'package:colette/shared/ui/widgets/colette_card_surface.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Calendrier iOS où cet iPhone ajoute les RDV santé.
class CalendarSettingsSection extends ConsumerWidget {
  const CalendarSettingsSection({super.key});

  Future<void> _choose(BuildContext context, WidgetRef ref) async {
    final controller = ref.read(calendarSettingsControllerProvider.notifier);
    final calendars = await controller.loadCalendars();
    if (calendars == null || !context.mounted) return;
    final picked = await showCalendarPickerSheet(context, calendars);
    if (picked != null) await controller.choose(picked);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final s = S.of(context);
    final styles = Theme.of(context).coletteTextStyles;
    ref.listen(calendarSettingsControllerProvider, (_, next) {
      if (next case AsyncError(:final error)) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(failureMessage(error, s))));
      }
    });
    final loading =
        ref.watch(calendarSettingsControllerProvider) is AsyncLoading;
    final choice = ref.watch(selectedCalendarProvider);
    return ColetteCardSurface(
      child: Column(
        crossAxisAlignment: .stretch,
        spacing: AppSpacing.sm.value,
        children: [
          Text(
            choice == null
                ? s.calendarNotSynced
                : s.calendarSyncedTo(choice.title),
            style: styles.body.copyWith(
              color: context.appColor(
                choice == null ? AppColors.textSecondary : AppColors.onSurface,
              ),
            ),
          ),
          Wrap(
            spacing: AppSpacing.sm.value,
            children: [
              TextButton.icon(
                onPressed: loading ? null : () => _choose(context, ref),
                icon: const Icon(Icons.calendar_month_outlined),
                label: Text(
                  choice == null ? s.calendarChoose : s.calendarChange,
                ),
              ),
              if (choice != null)
                TextButton(
                  onPressed: () => ref
                      .read(calendarSettingsControllerProvider.notifier)
                      .clear(),
                  child: Text(s.calendarStop),
                ),
            ],
          ),
        ],
      ),
    );
  }
}
```

Dans `settings_page.dart` : importer `calendar_settings_section.dart` et insérer, entre le bloc Notifications et `SectionHeader(title: s.settingsAppearanceSection)` :

```dart
          SectionHeader(title: s.settingsCalendarSection),
          const CalendarSettingsSection(),
```

Mettre à jour la doc de classe (« …notifications, calendrier, apparence, foyer. »). Si `settings_page_test.dart` échoue, y ajouter `calendarRepositoryProvider` n'est pas nécessaire (aucun appel au montage) ; vérifier seulement le défilement vers les sections basses.

- [ ] **Step 5: Run tests**

```bash
flutter gen-l10n
flutter test test/features/health test/features/baby/presentation/settings_page_test.dart
```
Expected: PASS.

- [ ] **Step 6: Commit**

```bash
dart format lib test && dart analyze && flutter test
git add lib/features/health lib/features/baby/presentation/pages/settings_page.dart lib/l10n/app_fr.arb test/features/health
git commit -m "feat: réglage du calendrier des RDV santé sur chaque iPhone"
```

---

### Task 12 : digest du matin, lignes santé

**Files:**
- Create: `functions/src/lib/medical-stages.ts`, `functions/src/lib/medical-reminder.ts`, `functions/src/lib/medical-reminder.test.ts`, `test/features/health/domain/medical_stages_functions_alignment_test.dart`
- Modify: `functions/src/lib/types.ts`, `functions/src/morning-digest.ts`, `functions/src/morning-digest.test.ts`

- [ ] **Step 1: Write the failing tests**

```ts
// functions/src/lib/medical-reminder.test.ts
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
```

Dans `functions/src/morning-digest.test.ts` :

- importer le type `MedicalReminderDoc` avec les autres types (`import type { BabyDoc, Device, DeviceDoc, EventDoc, MedicalReminderDoc } from './lib/types';`) ;
- ajouter `medicalReminder?: MedicalReminderDoc;` au type `FakeHousehold` ;
- dans le faux `db()`, remplacer `get: (field: string) => (field === 'baby' ? h.baby : undefined),` par

```ts
            get: (field: string) =>
              field === 'baby' ? h.baby : field === 'medicalReminder' ? h.medicalReminder : undefined,
```

- dans `describe('buildDigestBody')`, ajouter :

```ts
  it('ajoute une ligne par rappel santé après les soins', () => {
    expect(buildDigestBody(['Bain'], ['RDV à prendre : examen des 8 mois'])).toBe(
      'Bain\nRDV à prendre : examen des 8 mois',
    );
    expect(buildDigestBody([], ['En retard : examen des 8 mois'])).toBe('En retard : examen des 8 mois');
  });
```

- dans `describe('morningDigest')`, ajouter :

```ts
  const m2Due = {
    stages: [
      { stageId: 'm2', dueFrom: at('2026-09-20T22:00:00Z'), dueUntil: at('2026-10-20T22:00:00Z'), hasAppointment: false },
    ],
  };

  it('envoie une seule ligne santé quand tous les soins sont faits', async () => {
    households.push({
      id: 'ABC123',
      baby: { name: 'Colette' },
      devices: [{ id: 'd1' }],
      events: [
        { startAt: at('2026-09-21T05:00:00Z'), adrigyl: true, eyeCare: true, noseCare: true },
        { startAt: at('2026-09-21T05:30:00Z'), umbilicalCare: true, bath: true },
        { startAt: at('2026-09-21T09:00:00Z'), umbilicalCare: true },
        { startAt: at('2026-09-21T15:00:00Z'), umbilicalCare: true },
      ],
      medicalReminder: m2Due,
    });

    await handler();

    expect(sendToDevices).toHaveBeenCalledTimes(1);
    expect(sendToDevices.mock.calls[0][2].body).toBe('RDV à prendre : examen et vaccins des 2 mois');
  });

  it('concatène soins et lignes santé', async () => {
    households.push({
      id: 'ABC123',
      baby: { name: 'Colette' },
      devices: [{ id: 'd1' }],
      events: [],
      medicalReminder: m2Due,
    });

    await handler();

    expect(sendToDevices.mock.calls[0][2].body).toBe(
      buildDigestBody(
        ['Adrigyl', 'Soin des yeux', 'Soin du nez', 'Soin du nombril', 'Bain'],
        ['RDV à prendre : examen et vaccins des 2 mois'],
      ),
    );
  });

  it('pas de ligne santé pour une étape avec RDV', async () => {
    households.push({
      id: 'ABC123',
      baby: { name: 'Colette' },
      devices: [{ id: 'd1' }],
      events: [],
      medicalReminder: { stages: [{ ...m2Due.stages[0], hasAppointment: true }] },
    });

    await handler();

    expect(sendToDevices.mock.calls[0][2].body).not.toContain('RDV à prendre');
  });
```

```dart
// test/features/health/domain/medical_stages_functions_alignment_test.dart
import 'dart:io';

import 'package:colette/features/health/domain/entities/medical_stage.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('les libellés des Cloud Functions couvrent tous les stageId', () {
    final source = File('functions/src/lib/medical-stages.ts').readAsStringSync();
    final keys = RegExp(r"^\s+(\w+): '", multiLine: true)
        .allMatches(source)
        .map((m) => m.group(1))
        .toList();
    expect(keys, MedicalStageId.values.map((id) => id.name).toList());
  });
}
```

- [ ] **Step 2: Run tests to verify they fail**

```bash
(cd functions && npm test)
flutter test test/features/health/domain/medical_stages_functions_alignment_test.dart
```
Expected: FAIL (modules introuvables).

- [ ] **Step 3: Implement**

```ts
// functions/src/lib/medical-stages.ts
/** Libellés des étapes du suivi médical, alignés sur `MedicalStageId` côté app (test Dart). */
export const MEDICAL_STAGE_LABELS: Record<string, string> = {
  day8: 'examen des 8 jours',
  week2: 'examen de la 2e semaine',
  m1: 'examen du 1er mois',
  m2: 'examen et vaccins des 2 mois',
  m3: 'examen et vaccins des 3 mois',
  m4: 'examen et vaccins des 4 mois',
  m5: 'examen et vaccins des 5 mois',
  m6: 'vaccin des 6 mois',
  m8: 'examen des 8 mois',
  m11: 'examen et vaccins des 11 mois',
  m12: 'examen et vaccins des 12 mois',
  m16: 'examen et vaccin des 16-18 mois',
  m23: 'examen des 23-24 mois',
  y2: 'examen des 2 ans',
  y3: 'examen des 3 ans',
};
```

Dans `functions/src/lib/types.ts` :

```ts
export type MedicalReminderStageDoc = {
  stageId: string;
  dueFrom: Timestamp;
  dueUntil: Timestamp;
  hasAppointment: boolean;
};

/** Snapshot écrit par l'app : prochaines étapes non faites du suivi médical. */
export type MedicalReminderDoc = {
  stages?: MedicalReminderStageDoc[];
  computedAt?: Timestamp;
};
```

```ts
// functions/src/lib/medical-reminder.ts
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
```

Dans `morning-digest.ts` :
- importer `medicalLines` et le type `MedicalReminderDoc` ;
- remplacer `buildDigestBody` par

```ts
/** Soins en attente (« Adrigyl, Soin des yeux ») puis une ligne par rappel santé. */
export function buildDigestBody(pending: string[], medical: string[] = []): string {
  return [pending.join(', '), ...medical].filter((line) => line.length > 0).join('\n');
}
```

- après le calcul de `pending`, remplacer `if (pending.length === 0) continue;` par

```ts
      const medical = medicalLines(doc.get('medicalReminder') as MedicalReminderDoc | undefined, now);
      if (pending.length === 0 && medical.length === 0) continue;
```

- et `body: buildDigestBody(pending),` par `body: buildDigestBody(pending, medical),`.

- [ ] **Step 4: Run tests to verify they pass**

```bash
(cd functions && npm test && npm run build)
flutter test test/features/health/domain/medical_stages_functions_alignment_test.dart
```
Expected: PASS, `tsc` sans erreur. `functions/lib` (sortie de `tsc`) n'est pas versionné : ne pas l'ajouter.

- [ ] **Step 5: Commit**

```bash
git add functions/src test/features/health/domain/medical_stages_functions_alignment_test.dart
git commit -m "feat: rappels santé dans le digest du matin"
```

---

### Task 13 : test d'intégration du pont Calendrier et vérification finale

**Files:**
- Create: `integration_test/calendar_bridge_test.dart`
- Modify: `pubspec.yaml` (dev_dependency `integration_test`), `docs/superpowers/specs/2026-09-23-health-follow-up-design.md` (écarts retenus)

- [ ] **Step 1: Dépendance**

Dans `pubspec.yaml`, sous `dev_dependencies:` :

```yaml
  integration_test:
    sdk: flutter
```

Puis `flutter pub get`.

- [ ] **Step 2: Test d'intégration**

```dart
// integration_test/calendar_bridge_test.dart
import 'package:colette/features/health/data/native_calendar_repository.dart';
import 'package:colette/features/health/domain/entities/calendar_event.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

/// À lancer sur simulateur après avoir accordé l'accès au Calendrier :
/// `xcrun simctl privacy booted grant calendar fr.montet.colette`.
void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  const repo = NativeCalendarRepository(
    MethodChannel(NativeCalendarRepository.channelName),
  );

  testWidgets('créer, retrouver, modifier puis supprimer un événement', (_) async {
    expect((await repo.requestAccess()).getRight().toNullable(), isTrue);
    final calendars = (await repo.listCalendars()).getRight().toNullable()!;
    expect(calendars, isNotEmpty);
    final calendarId = calendars.first.id;
    final start = DateTime.now().add(const Duration(days: 3));
    final draft = CalendarEventDraft(
      url: 'colette://rdv/m2',
      title: 'Test Colette',
      start: start,
      end: start.add(const Duration(minutes: 30)),
      notes: 'Dr Test',
      alarms: [start.subtract(const Duration(hours: 1))],
    );
    final from = DateTime.now().subtract(const Duration(days: 1));
    final to = DateTime.now().add(const Duration(days: 30));

    final eventId = (await repo.upsertEvent(calendarId, draft: draft))
        .getRight()
        .toNullable()!;
    var found = (await repo.findEvents(calendarId, from: from, to: to))
        .getRight()
        .toNullable()!;
    expect(found.where((e) => e.eventId == eventId).single.notes, 'Dr Test');

    await repo.upsertEvent(
      calendarId,
      eventId: eventId,
      draft: draft.copyWith(title: 'Test Colette modifié'),
    );
    found = (await repo.findEvents(calendarId, from: from, to: to))
        .getRight()
        .toNullable()!;
    expect(
      found.where((e) => e.eventId == eventId).single.title,
      'Test Colette modifié',
    );

    expect((await repo.deleteEvent(calendarId, eventId)).isRight(), isTrue);
    found = (await repo.findEvents(calendarId, from: from, to: to))
        .getRight()
        .toNullable()!;
    expect(found.where((e) => e.eventId == eventId), isEmpty);
  });
}
```

- [ ] **Step 3: Lancer sur simulateur**

```bash
xcrun simctl boot "iPhone 17 Pro" 2>/dev/null || true
xcrun simctl privacy booted grant calendar fr.montet.colette
flutter test integration_test/calendar_bridge_test.dart -d "iPhone 17 Pro"
```
Expected: `All tests passed!`. Si l'accès n'est pas accordé avant installation (l'app n'existe pas encore sur le simulateur), lancer une première fois, relancer la commande `privacy grant`, puis relancer le test.

- [ ] **Step 4: Vérifications automatiques**

```bash
dart format --set-exit-if-changed lib test integration_test
dart analyze
flutter test
(cd functions && npm test && npm run build)
grep -nE "Color\(0x|TextStyle\(|fontSize|DateTime\.now\(\)" -r lib/features/health
```
Expected : tout vert ; le dernier grep ne renvoie rien (le `DateTime.now()` du test d'intégration est hors `lib/`).

- [ ] **Step 5: Spec à jour**

Dans la spec, section 3 : remplacer `appointmentBeforeBirth` / `doneInFuture` par `medicalDateBeforeBirth` / `medicalDateInFuture` et `stageId` (texte) par l'enum `MedicalStageId`. Ajouter en fin de section 5.4 : « Les notes (praticien) font partie de la comparaison ; un doublon est résolu en gardant le premier événement renvoyé par EventKit. »

- [ ] **Step 6: Commit**

```bash
git add pubspec.yaml pubspec.lock integration_test docs/superpowers/specs/2026-09-23-health-follow-up-design.md
git commit -m "test: pont Calendrier sur simulateur, spec du suivi médical à jour"
```

- [ ] **Step 7: Rapport**

Lister les commits (`git log --oneline main..HEAD`), la divergence avec `main` et les conflits simulés (`git merge-tree --write-tree main HEAD`), puis demander à Maxence la validation du merge `--no-ff` « merge: suivi médical, examens, vaccins et Calendrier iOS (feat/health-follow-up) ». Rappeler : redéployer `morningDigest` après le merge (`firebase deploy --only functions:morningDigest`), et installer la nouvelle version sur les deux iPhones (`devicectl`, par-dessus l'app) puis choisir le calendrier partagé dans Réglages sur chacun.
