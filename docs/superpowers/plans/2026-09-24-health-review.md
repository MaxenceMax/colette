# Revue de l'onglet Santé et tuile Rendez-vous — plan d'implémentation

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Mettre les RDV programmés en avant sur l'onglet Santé, reléguer ce qui reste à programmer, et faire revenir sur Aujourd'hui une tuile Rendez-vous toujours visible dont l'emphase monte à l'approche du RDV.

**Architecture:** Le domaine gagne des getters de tri sur `MedicalTimeline` et un use case pur `ComputeAppointmentProximity`. La présentation Santé est découpée en widgets d'un fichier chacun (`NextAppointmentCard`, `ScheduledSection`, `AwaitingConfirmationSection`, `ToScheduleSection`), assemblés par `HealthPage`. Une `AppointmentCard` dans `features/health/presentation/widgets/` est consommée par `DashboardPage`.

**Tech Stack:** Flutter iOS, Riverpod 3 codegen, freezed, intl, `pumpApp` + `FixedClock` pour les tests.

**Spec :** `docs/superpowers/specs/2026-09-24-health-review-design.md`.

---

## Règles du dépôt à respecter à chaque tâche

- Travailler dans le worktree `.claude/worktrees/health-review` (branche `feat/health-review`). Ne jamais `cd` vers la racine.
- Après toute modification d'un fichier annoté (`@freezed`, `@riverpod`) : `dart run build_runner build -d`, puis commiter les `.g.dart` / `.freezed.dart` **des fichiers de la tâche seulement**. Si `build_runner` réécrit `lib/features/documents/presentation/providers/documents_preview_controller.g.dart`, le restaurer avec `git checkout -- lib/features/documents/presentation/providers/documents_preview_controller.g.dart`.
- Après toute modification de `lib/l10n/app_fr.arb` : `flutter gen-l10n` (dossier généré non versionné).
- Couleurs : `context.appColor(AppColors.xxx)`. Espacements : `AppSpacing.md.all`. Textes : `Theme.of(context).coletteTextStyles.xxx`. Strings : `S.of(context).cle`. Jamais de nombre, couleur ou string en dur.
- `switch` sur `AsyncValue`, jamais `.when`. `ref.watch` dans `build`, `ref.read` dans les callbacks.
- Avant chaque commit : `dart format lib test`, `dart analyze` (pas `flutter analyze`), et les tests de la tâche. Le `flutter test` complet est lancé en Tâche 13.
- Commits en français, préfixes `feat:` / `test:` / `docs:` / `chore:`, avec la ligne `Co-Authored-By: Claude Fable 5.1 <noreply@anthropic.com>`.
- Ne jamais pousser. Ne jamais merger : le merge est validé par Maxence.

## Structure des fichiers

| Fichier | Rôle |
| --- | --- |
| `lib/features/health/domain/entities/medical_timeline.dart` (modifié) | `appointmentAt`, `practitioner` sur l'élément ; `scheduled`, `nextAppointment`, `awaitingConfirmation`, `toSchedule`, `upcoming`, `done` sur la frise. |
| `lib/features/health/domain/entities/appointment_proximity.dart` (créé) | Enum `AppointmentProximity`. |
| `lib/features/health/domain/use_cases/compute_appointment_proximity.dart` (créé) | Use case pur. |
| `lib/core/dates/time_format.dart` (modifié) | `formatDayOfMonth`, `formatShortMonth`, `formatDayMonth`. |
| `lib/l10n/app_fr.arb` (modifié) | Nouvelles clés, retrait des clés obsolètes. |
| `lib/features/health/presentation/providers/health_providers.dart` (modifié) | `nextAppointmentProximityProvider`. |
| `lib/features/health/presentation/widgets/timeline_item_ui.dart` (créé) | Helpers partagés : titre d'un élément, phrase de date selon proximité, pastilles, ouverture de la bonne feuille. |
| `lib/features/health/presentation/widgets/next_appointment_card.dart` (créé) | Carte « Prochain rendez-vous » de l'onglet Santé. |
| `lib/features/health/presentation/widgets/dated_appointment_tile.dart` (créé) | Tuile avec bloc date à gauche. |
| `lib/features/health/presentation/widgets/scheduled_section.dart` (créé) | Section « Aussi programmés ». |
| `lib/features/health/presentation/widgets/to_schedule_section.dart` (créé) | Section « À programmer » et `CompactStageRow`. |
| `lib/features/health/presentation/widgets/awaiting_confirmation_section.dart` (créé) | Section « RDV passé, à confirmer ». |
| `lib/features/health/presentation/widgets/medical_stage_tile.dart`, `custom_appointment_tile.dart` (modifiés) | Statut `appointmentPassed` en `warning`. |
| `lib/features/health/presentation/pages/health_page.dart` (réécrit) | Assemblage, alerte calendrier en haut ou pied de page, « À venir (n) » repliée. |
| `lib/features/health/presentation/widgets/appointment_card.dart` (créé) | Tuile Rendez-vous de l'accueil, cinq états. |
| `lib/features/dashboard/presentation/pages/dashboard_page.dart` (modifié) | Insertion de la tuile. |

Tests correspondants sous `test/core/dates/`, `test/features/health/domain/`, `test/features/health/presentation/`, `test/features/dashboard/presentation/`.

---

### Task 1: Getters de tri sur la frise

**Files:**
- Modify: `lib/features/health/domain/entities/medical_timeline.dart`
- Test: `test/features/health/domain/medical_timeline_test.dart` (créer)

- [ ] **Step 1: Écrire les tests qui échouent**

```dart
import 'package:colette/features/health/domain/entities/medical_stage.dart';
import 'package:colette/features/health/domain/entities/medical_stage_status.dart';
import 'package:colette/features/health/domain/entities/medical_timeline.dart';
import 'package:flutter_test/flutter_test.dart';

import '../health_factories.dart';

void main() {
  AppointmentItem custom(
    String id,
    DateTime at,
    MedicalStageStatus status, {
    String? practitioner,
  }) => AppointmentItem(
    makeAppointment(id: id, appointmentAt: at, practitioner: practitioner),
    status,
  );

  group('MedicalTimelineItem', () {
    test('appointmentAt : RDV de la visite ou date du RDV libre', () {
      final stage = MedicalTimelineItem.stage(
        entry(
          MedicalStageId.m2,
          MedicalStageStatus.scheduled,
          appointmentAt: DateTime(2026, 11, 3, 10),
        ),
      );
      final noVisit = MedicalTimelineItem.stage(
        entry(MedicalStageId.m2, MedicalStageStatus.due),
      );
      final rdv = custom('a', DateTime(2026, 10, 15, 9), .scheduled);
      expect(stage.appointmentAt, DateTime(2026, 11, 3, 10));
      expect(noVisit.appointmentAt, isNull);
      expect(rdv.appointmentAt, DateTime(2026, 10, 15, 9));
    });

    test('practitioner : null si absent ou vide', () {
      final withName = MedicalTimelineItem.stage(
        entry(
          MedicalStageId.m2,
          MedicalStageStatus.scheduled,
          appointmentAt: DateTime(2026, 11, 3, 10),
          practitioner: '  Dr Martin ',
        ),
      );
      final blank = custom(
        'a',
        DateTime(2026, 10, 15, 9),
        .scheduled,
        practitioner: '   ',
      );
      expect(withName.practitioner, 'Dr Martin');
      expect(blank.practitioner, isNull);
    });
  });

  group('MedicalTimeline', () {
    final timeline = MedicalTimeline(
      entries: [
        entry(MedicalStageId.day8, MedicalStageStatus.done),
        entry(MedicalStageId.week2, MedicalStageStatus.late),
        entry(
          MedicalStageId.m1,
          MedicalStageStatus.appointmentPassed,
          appointmentAt: DateTime(2026, 9, 18, 9),
        ),
        entry(
          MedicalStageId.m2,
          MedicalStageStatus.scheduled,
          appointmentAt: DateTime(2026, 11, 3, 10),
        ),
        entry(MedicalStageId.m3, MedicalStageStatus.due),
        entry(MedicalStageId.m4, MedicalStageStatus.upcoming),
      ],
      appointments: [
        custom('osteo', DateTime(2026, 10, 15, 9), .scheduled),
        custom('orl', DateTime(2026, 11, 3, 10), .scheduled),
        custom('passe', DateTime(2026, 9, 10, 9), .appointmentPassed),
      ],
    );

    test('scheduled : par date, puis ordre de la frise à date égale', () {
      final ids = [
        for (final i in timeline.scheduled)
          switch (i) {
            StageItem(:final entry) => entry.stage.id.name,
            AppointmentItem(:final appointment) => appointment.id,
          },
      ];
      // Toutes les entrées de la fabrique ont dueFrom = 1er nov. : « osteo »
      // (15 oct.) est inséré avant, « orl » (3 nov.) après les étapes. À date
      // égale (m2 et orl, 3 nov. 10h00), l'ordre de `items` est gardé.
      expect(ids, ['osteo', 'm2', 'orl']);
    });

    test('nextAppointment : le premier programmé, ou null', () {
      expect(timeline.nextAppointment?.appointmentAt, DateTime(2026, 10, 15, 9));
      expect(const MedicalTimeline(entries: []).nextAppointment, isNull);
    });

    test('awaitingConfirmation : RDV passés par date', () {
      expect(
        timeline.awaitingConfirmation.map((i) => i.appointmentAt),
        [DateTime(2026, 9, 10, 9), DateTime(2026, 9, 18, 9)],
      );
    });

    test('toSchedule : retards puis à faire, ordre de la frise', () {
      expect(
        timeline.toSchedule.map((i) => (i as StageItem).entry.stage.id),
        [MedicalStageId.week2, MedicalStageId.m3],
      );
    });

    test('upcoming et done', () {
      expect(
        timeline.upcoming.map((i) => (i as StageItem).entry.stage.id),
        [MedicalStageId.m4],
      );
      expect(
        timeline.done.map((i) => (i as StageItem).entry.stage.id),
        [MedicalStageId.day8],
      );
    });
  });
}
```

- [ ] **Step 2: Vérifier l'échec**

Run: `flutter test test/features/health/domain/medical_timeline_test.dart`
Expected: erreur de compilation, `appointmentAt` et `scheduled` inconnus.

- [ ] **Step 3: Implémenter**

Dans `lib/features/health/domain/entities/medical_timeline.dart`, ajouter aux getters de `MedicalTimelineItem` (après `anchorDate`) :

```dart
  /// Date du RDV pris : celle de la visite d'une étape, ou celle du RDV libre.
  DateTime? get appointmentAt => switch (this) {
    StageItem(:final entry) => entry.visit?.appointmentAt,
    AppointmentItem(:final appointment) => appointment.appointmentAt,
  };

  /// Praticien saisi, `null` s'il est absent ou vide.
  String? get practitioner {
    final raw = switch (this) {
      StageItem(:final entry) => entry.visit?.practitioner,
      AppointmentItem(:final appointment) => appointment.practitioner,
    };
    final trimmed = raw?.trim();
    return trimmed == null || trimmed.isEmpty ? null : trimmed;
  }
```

Et dans `MedicalTimeline`, après le getter `next` :

```dart
  /// RDV programmés, du plus proche au plus lointain ; à date égale, l'ordre
  /// de [items] est conservé.
  List<MedicalTimelineItem> get scheduled =>
      _byAppointment(_withStatus(MedicalStageStatus.scheduled));

  /// Prochain RDV programmé, ou `null`.
  MedicalTimelineItem? get nextAppointment => scheduled.firstOrNull;

  /// RDV passés pas encore marqués faits, du plus ancien au plus récent.
  List<MedicalTimelineItem> get awaitingConfirmation =>
      _byAppointment(_withStatus(MedicalStageStatus.appointmentPassed));

  /// Étapes à caler : en retard d'abord, puis à faire, chacune dans l'ordre
  /// de [items].
  List<MedicalTimelineItem> get toSchedule => [
    ..._withStatus(MedicalStageStatus.late),
    ..._withStatus(MedicalStageStatus.due),
  ];

  /// Étapes à venir, ordre de [items].
  List<MedicalTimelineItem> get upcoming =>
      _withStatus(MedicalStageStatus.upcoming);

  /// Étapes faites, ordre de [items].
  List<MedicalTimelineItem> get done => _withStatus(MedicalStageStatus.done);

  List<MedicalTimelineItem> _withStatus(MedicalStageStatus status) => [
    for (final item in items)
      if (item.status == status) item,
  ];

  /// Tri stable par [MedicalTimelineItem.appointmentAt] ; un élément sans
  /// date (incohérence de données) passe en dernier.
  static List<MedicalTimelineItem> _byAppointment(
    List<MedicalTimelineItem> list,
  ) {
    final indexed = list.indexed.toList()
      ..sort((a, b) {
        final (ia, itemA) = a;
        final (ib, itemB) = b;
        final dateA = itemA.appointmentAt;
        final dateB = itemB.appointmentAt;
        final byDate = switch ((dateA, dateB)) {
          (null, null) => 0,
          (null, _) => 1,
          (_, null) => -1,
          (final da?, final db?) => da.compareTo(db),
        };
        return byDate != 0 ? byDate : ia.compareTo(ib);
      });
    return [for (final (_, item) in indexed) item];
  }
```

- [ ] **Step 4: build_runner puis tests**

Run: `dart run build_runner build -d && flutter test test/features/health/domain/`
Expected: tous verts. Si `documents_preview_controller.g.dart` a changé, le restaurer.

- [ ] **Step 5: Commit**

```bash
dart format lib test && dart analyze
git add lib/features/health/domain/entities/medical_timeline.dart lib/features/health/domain/entities/medical_timeline.freezed.dart test/features/health/domain/medical_timeline_test.dart
git commit -m "feat: getters de tri des RDV programmés et à programmer sur la frise

Co-Authored-By: Claude Fable 5.1 <noreply@anthropic.com>"
```

---

### Task 2: Proximité d'un RDV

**Files:**
- Create: `lib/features/health/domain/entities/appointment_proximity.dart`
- Create: `lib/features/health/domain/use_cases/compute_appointment_proximity.dart`
- Test: `test/features/health/domain/compute_appointment_proximity_test.dart`

- [ ] **Step 1: Test qui échoue**

```dart
import 'package:colette/features/health/domain/entities/appointment_proximity.dart';
import 'package:colette/features/health/domain/use_cases/compute_appointment_proximity.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const compute = ComputeAppointmentProximity();
  final today = DateTime(2026, 10, 20, 8);

  AppointmentProximity at(DateTime appointmentAt) =>
      compute(appointmentAt: appointmentAt, today: today);

  test('le jour même, quelle que soit l\'heure : today', () {
    expect(at(DateTime(2026, 10, 20, 23, 30)), AppointmentProximity.today);
    expect(at(DateTime(2026, 10, 20, 7)), AppointmentProximity.today);
  });

  test('le lendemain : tomorrow', () {
    expect(at(DateTime(2026, 10, 21, 0, 5)), AppointmentProximity.tomorrow);
  });

  test('de 2 à 7 jours : soon', () {
    expect(at(DateTime(2026, 10, 22)), AppointmentProximity.soon);
    expect(at(DateTime(2026, 10, 27, 23, 59)), AppointmentProximity.soon);
  });

  test('8 jours et plus : later', () {
    expect(at(DateTime(2026, 10, 28)), AppointmentProximity.later);
    expect(at(DateTime(2027, 3, 1)), AppointmentProximity.later);
  });

  test('un écart négatif est traité comme today', () {
    expect(at(DateTime(2026, 10, 19)), AppointmentProximity.today);
  });
}
```

- [ ] **Step 2: Vérifier l'échec**

Run: `flutter test test/features/health/domain/compute_appointment_proximity_test.dart`
Expected: erreur de compilation (imports introuvables).

- [ ] **Step 3: Implémenter**

`lib/features/health/domain/entities/appointment_proximity.dart` :

```dart
/// Distance d'un RDV programmé au jour courant, pour graduer son emphase.
enum AppointmentProximity { today, tomorrow, soon, later }
```

`lib/features/health/domain/use_cases/compute_appointment_proximity.dart` :

```dart
import 'package:colette/core/dates/date_extensions.dart';
import 'package:colette/features/health/domain/entities/appointment_proximity.dart';

/// Proximité d'un RDV en jours civils : 0 → `today`, 1 → `tomorrow`,
/// 2 à [soonDays] → `soon`, au-delà → `later`. Un écart négatif (ne devrait
/// pas arriver : un RDV passé a le statut `appointmentPassed`) vaut `today`.
class ComputeAppointmentProximity {
  const ComputeAppointmentProximity();

  static const soonDays = 7;

  AppointmentProximity call({
    required DateTime appointmentAt,
    required DateTime today,
  }) {
    final days = calendarDaysBetween(today.dateOnly, appointmentAt.dateOnly);
    return switch (days) {
      <= 0 => .today,
      1 => .tomorrow,
      <= soonDays => .soon,
      _ => .later,
    };
  }
}
```

- [ ] **Step 4: Tests verts**

Run: `flutter test test/features/health/domain/compute_appointment_proximity_test.dart`
Expected: 5 tests verts.

- [ ] **Step 5: Commit**

```bash
dart format lib test && dart analyze
git add lib/features/health/domain/entities/appointment_proximity.dart lib/features/health/domain/use_cases/compute_appointment_proximity.dart test/features/health/domain/compute_appointment_proximity_test.dart
git commit -m "feat: proximité d'un RDV (aujourd'hui, demain, bientôt, plus tard)

Co-Authored-By: Claude Fable 5.1 <noreply@anthropic.com>"
```

---

### Task 3: Helpers de date

**Files:**
- Modify: `lib/core/dates/time_format.dart`
- Test: `test/core/dates/time_format_test.dart`

- [ ] **Step 1: Ajouter les tests (fin du `main`)**

```dart
  test('formatDayOfMonth et formatShortMonth : « 14 » et « oct. »', () {
    expect(formatDayOfMonth(DateTime(2026, 10, 14)), '14');
    expect(formatShortMonth(DateTime(2026, 10, 14)), 'oct.');
  });

  test('formatDayMonth : « 5 nov. »', () {
    expect(formatDayMonth(DateTime(2026, 11, 5)), '5 nov.');
  });
```

- [ ] **Step 2: Vérifier l'échec**

Run: `flutter test test/core/dates/time_format_test.dart`
Expected: erreur de compilation.

- [ ] **Step 3: Implémenter (fin de `time_format.dart`)**

```dart
/// « 14 ».
String formatDayOfMonth(DateTime day) => DateFormat('d', 'fr').format(day);

/// « oct. ».
String formatShortMonth(DateTime day) => DateFormat('MMM', 'fr').format(day);

/// « 5 nov. ».
String formatDayMonth(DateTime day) => DateFormat('d MMM', 'fr').format(day);
```

- [ ] **Step 4: Tests verts**

Run: `flutter test test/core/dates/time_format_test.dart`
Expected: verts.

- [ ] **Step 5: Commit**

```bash
dart format lib test && dart analyze
git add lib/core/dates/time_format.dart test/core/dates/time_format_test.dart
git commit -m "feat: formats jour du mois, mois abrégé et jour-mois

Co-Authored-By: Claude Fable 5.1 <noreply@anthropic.com>"
```

---

### Task 4: Nouvelles clés de texte

**Files:**
- Modify: `lib/l10n/app_fr.arb` (après la ligne `"healthDeleteAppointmentBody"`)

- [ ] **Step 1: Ajouter les clés**

Insérer juste après `"healthDeleteAppointmentBody": "Il sera aussi retiré du Calendrier.",` :

```json
  "healthNextAppointment": "Prochain rendez-vous",
  "healthNoAppointment": "Pas de rendez-vous programmé",
  "healthSectionScheduled": "Aussi programmés",
  "healthSectionAwaiting": "RDV passé, à confirmer",
  "healthSectionToSchedule": "À programmer",
  "healthSectionUpcomingCount": "À venir ({count})",
  "@healthSectionUpcomingCount": { "placeholders": { "count": { "type": "int" } } },
  "healthTodayAt": "Aujourd'hui à {time}",
  "@healthTodayAt": { "placeholders": { "time": { "type": "String" } } },
  "healthTomorrowAt": "Demain à {time}",
  "@healthTomorrowAt": { "placeholders": { "time": { "type": "String" } } },
  "healthInDays": "{count, plural, =1{dans 1 jour} other{dans {count} jours}}",
  "@healthInDays": { "placeholders": { "count": { "type": "int" } } },
  "healthLateShort": "en retard",
  "healthDueWindowShort": "du {from} au {to}",
  "@healthDueWindowShort": { "placeholders": { "from": { "type": "String" }, "to": { "type": "String" } } },
  "dashboardAppointmentTitle": "Rendez-vous",
  "dashboardAppointmentSoon": "{count, plural, =1{Rendez-vous dans 1 jour} other{Rendez-vous dans {count} jours}}",
  "@dashboardAppointmentSoon": { "placeholders": { "count": { "type": "int" } } },
  "dashboardAppointmentAwaiting": "RDV passé · à marquer comme faite",
```

Vérifier que la ligne précédente se termine bien par une virgule et que la dernière clé du fichier n'en a pas.

- [ ] **Step 2: Générer et vérifier**

Run: `flutter gen-l10n && dart analyze`
Expected: aucune erreur ; `grep -c healthInDays lib/l10n/generated/app_localizations.dart` renvoie au moins 1.

- [ ] **Step 3: Commit**

```bash
git add lib/l10n/app_fr.arb
git commit -m "feat: textes de la revue Santé et de la tuile Rendez-vous

Co-Authored-By: Claude Fable 5.1 <noreply@anthropic.com>"
```

---

### Task 5: Provider de proximité

**Files:**
- Modify: `lib/features/health/presentation/providers/health_providers.dart`
- Test: `test/features/health/presentation/health_providers_test.dart` (ajouter à la fin du `main`)

- [ ] **Step 1: Test qui échoue**

Ajouter les imports en tête du fichier de test s'ils manquent :

```dart
import 'package:colette/features/health/domain/entities/appointment_proximity.dart';
import 'package:colette/features/health/domain/entities/medical_stage_status.dart';
import 'package:colette/features/health/domain/entities/medical_timeline.dart';
```

Puis, en fin de `main` :

```dart
  group('nextAppointmentProximityProvider', () {
    ProviderContainer containerWith(MedicalTimeline? timeline) {
      final container = ProviderContainer(
        overrides: [
          clockProvider.overrideWithValue(FixedClock(DateTime(2026, 10, 20, 9))),
          minuteTickerProvider.overrideWith((ref) => const Stream.empty()),
          medicalTimelineProvider.overrideWithValue(timeline),
        ],
      );
      addTearDown(container.dispose);
      return container;
    }

    test('null sans frise ou sans RDV programmé', () {
      expect(containerWith(null).read(nextAppointmentProximityProvider), isNull);
      final noRdv = MedicalTimeline(
        entries: [entry(MedicalStageId.m2, MedicalStageStatus.due)],
      );
      expect(containerWith(noRdv).read(nextAppointmentProximityProvider), isNull);
    });

    test('proximité du prochain RDV programmé', () {
      final timeline = MedicalTimeline(
        entries: [
          entry(
            MedicalStageId.m2,
            MedicalStageStatus.scheduled,
            appointmentAt: DateTime(2026, 10, 23, 10),
          ),
        ],
      );
      expect(
        containerWith(timeline).read(nextAppointmentProximityProvider),
        AppointmentProximity.soon,
      );
    });
  });
```

- [ ] **Step 2: Vérifier l'échec**

Run: `flutter test test/features/health/presentation/health_providers_test.dart`
Expected: erreur de compilation, `nextAppointmentProximityProvider` inconnu.

- [ ] **Step 3: Implémenter (fin de `health_providers.dart`)**

Ajouter les imports :

```dart
import 'package:colette/features/health/domain/entities/appointment_proximity.dart';
import 'package:colette/features/health/domain/use_cases/compute_appointment_proximity.dart';
```

Puis :

```dart
/// Proximité du prochain RDV programmé ; `null` sans frise ou sans RDV.
/// Suit [todayProvider] : ne change qu'au changement de jour.
@riverpod
AppointmentProximity? nextAppointmentProximity(Ref ref) {
  final at = ref.watch(medicalTimelineProvider)?.nextAppointment?.appointmentAt;
  if (at == null) return null;
  return const ComputeAppointmentProximity()(
    appointmentAt: at,
    today: ref.watch(todayProvider),
  );
}
```

- [ ] **Step 4: build_runner puis tests**

Run: `dart run build_runner build -d && flutter test test/features/health/presentation/health_providers_test.dart`
Expected: verts.

- [ ] **Step 5: Commit**

```bash
dart format lib test && dart analyze
git add lib/features/health/presentation/providers/health_providers.dart lib/features/health/presentation/providers/health_providers.g.dart test/features/health/presentation/health_providers_test.dart
git commit -m "feat: provider de proximité du prochain RDV

Co-Authored-By: Claude Fable 5.1 <noreply@anthropic.com>"
```

---

### Task 6: Helpers d'affichage partagés et carte « Prochain rendez-vous »

**Files:**
- Create: `lib/features/health/presentation/widgets/timeline_item_ui.dart`
- Create: `lib/features/health/presentation/widgets/next_appointment_card.dart`
- Test: `test/features/health/presentation/next_appointment_card_test.dart`

- [ ] **Step 1: Test qui échoue**

```dart
import 'package:colette/core/clock/app_clock.dart';
import 'package:colette/core/clock/now_providers.dart';
import 'package:colette/features/health/domain/entities/medical_stage.dart';
import 'package:colette/features/health/domain/entities/medical_stage_status.dart';
import 'package:colette/features/health/domain/entities/medical_timeline.dart';
import 'package:colette/features/health/presentation/providers/health_providers.dart';
import 'package:colette/features/health/presentation/widgets/next_appointment_card.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../helpers/pump_app.dart';
import '../health_factories.dart';

void main() {
  Future<void> pumpCard(
    WidgetTester tester,
    MedicalTimeline? timeline, {
    DateTime? now,
  }) => pumpApp(
    tester,
    Scaffold(body: ListView(children: const [NextAppointmentCard()])),
    overrides: [
      clockProvider.overrideWithValue(
        FixedClock(now ?? DateTime(2026, 10, 20, 9)),
      ),
      minuteTickerProvider.overrideWith((ref) => const Stream.empty()),
      medicalTimelineProvider.overrideWithValue(timeline),
    ],
  );

  testWidgets('sans RDV : carte grise « Pas de rendez-vous programmé »', (
    tester,
  ) async {
    await pumpCard(
      tester,
      MedicalTimeline(
        entries: [entry(MedicalStageId.m2, MedicalStageStatus.due)],
      ),
    );
    expect(find.text('Prochain rendez-vous'), findsOneWidget);
    expect(find.text('Pas de rendez-vous programmé'), findsOneWidget);
    expect(find.byIcon(Icons.event_busy_outlined), findsOneWidget);
  });

  testWidgets('RDV éloigné : date, libellé, praticien, compte à rebours, pastilles', (
    tester,
  ) async {
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
    expect(find.text('mar. 3 nov., 10h00'), findsOneWidget);
    expect(find.text('Examen et vaccins des 2 mois'), findsOneWidget);
    expect(find.text('Dr Martin · dans 14 jours'), findsOneWidget);
    expect(find.text('Examen'), findsOneWidget);
    expect(find.text('Vaccins'), findsOneWidget);
  });

  testWidgets('RDV aujourd\'hui et demain : phrase dédiée, sans compte à rebours', (
    tester,
  ) async {
    await pumpCard(
      tester,
      MedicalTimeline(
        entries: [],
        appointments: [
          AppointmentItem(
            makeAppointment(appointmentAt: DateTime(2026, 10, 20, 15, 30)),
            MedicalStageStatus.scheduled,
          ),
        ],
      ),
    );
    expect(find.text('Aujourd\'hui à 15h30'), findsOneWidget);
    expect(find.text('Ostéopathe'), findsOneWidget);
    expect(find.text('RDV libre'), findsOneWidget);
    expect(find.textContaining('dans '), findsNothing);

    await pumpCard(
      tester,
      MedicalTimeline(
        entries: [],
        appointments: [
          AppointmentItem(
            makeAppointment(appointmentAt: DateTime(2026, 10, 21, 8)),
            MedicalStageStatus.scheduled,
          ),
        ],
      ),
    );
    expect(find.text('Demain à 08h00'), findsOneWidget);
  });

  testWidgets('tap : ouvre la feuille du RDV libre', (tester) async {
    await pumpCard(
      tester,
      MedicalTimeline(
        entries: [],
        appointments: [
          AppointmentItem(
            makeAppointment(appointmentAt: DateTime(2026, 10, 25, 8)),
            MedicalStageStatus.scheduled,
          ),
        ],
      ),
    );
    await tester.tap(find.text('Ostéopathe'));
    await tester.pumpAndSettle();
    expect(find.text('Titre (ostéopathe, ORL, pédiatre…)'), findsOneWidget);
  });
}
```

Note : la feuille de RDV libre a besoin de `babyProfileProvider` pour activer « Enregistrer », mais s'ouvre sans lui ; si le test de tap échoue sur un provider Firestore non surchargé, ajouter `babyProfileProvider.overrideWith((ref) => Stream.value(null))` (import `package:colette/features/baby/presentation/providers/baby_providers.dart`) aux overrides.

- [ ] **Step 2: Vérifier l'échec**

Run: `flutter test test/features/health/presentation/next_appointment_card_test.dart`
Expected: erreur de compilation.

- [ ] **Step 3: Écrire `timeline_item_ui.dart`**

```dart
import 'package:colette/core/dates/time_format.dart';
import 'package:colette/core/theme/design_tokens.dart';
import 'package:colette/features/health/domain/entities/appointment_proximity.dart';
import 'package:colette/features/health/domain/entities/medical_timeline.dart';
import 'package:colette/features/health/presentation/labels/health_labels.dart';
import 'package:colette/features/health/presentation/widgets/custom_appointment_sheet.dart';
import 'package:colette/features/health/presentation/widgets/medical_stage_sheet.dart';
import 'package:colette/features/health/presentation/widgets/medical_stage_tile.dart';
import 'package:colette/l10n/generated/app_localizations.dart';
import 'package:flutter/material.dart';

/// Libellé d'un élément : nom de l'étape ou titre du RDV libre.
String timelineItemTitle(S s, MedicalTimelineItem item) => switch (item) {
  StageItem(:final entry) => HealthLabels.stage(s, entry.stage.id),
  AppointmentItem(:final appointment) => appointment.title,
};

/// « Aujourd'hui à 10h30 », « Demain à 10h30 » ou « jeu. 2 oct., 10h30 ».
String appointmentDateText(
  S s,
  DateTime appointmentAt,
  AppointmentProximity proximity,
) => switch (proximity) {
  AppointmentProximity.today => s.healthTodayAt(
    formatHourMinute(appointmentAt),
  ),
  AppointmentProximity.tomorrow => s.healthTomorrowAt(
    formatHourMinute(appointmentAt),
  ),
  AppointmentProximity.soon ||
  AppointmentProximity.later => formatDayAndTime(appointmentAt),
};

/// Ouvre la feuille d'étape ou de RDV libre selon [item].
Future<void> showTimelineItemSheet(
  BuildContext context,
  MedicalTimelineItem item,
) => switch (item) {
  StageItem(:final entry) => showMedicalStageSheet(context, entry),
  AppointmentItem(:final appointment) => showCustomAppointmentSheet(
    context,
    initial: appointment,
  ),
};

/// Pastilles d'un élément : Examen / Vaccins / Certificat pour une étape,
/// RDV libre / Vaccins pour un RDV libre.
class TimelineItemChips extends StatelessWidget {
  const TimelineItemChips({super.key, required this.item});

  final MedicalTimelineItem item;

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    final labels = switch (item) {
      StageItem(:final entry) => [
        if (entry.stage.hasExam) s.healthChipExam,
        if (entry.stage.hasVaccines) s.healthChipVaccines,
        if (entry.stage.hasCertificate) s.healthChipCertificate,
      ],
      AppointmentItem(:final appointment) => [
        s.healthChipCustom,
        if (appointment.vaccines.isNotEmpty) s.healthChipVaccines,
      ],
    };
    return Wrap(
      spacing: AppSpacing.xs.value,
      children: [for (final label in labels) MedicalChip(label: label)],
    );
  }
}
```

- [ ] **Step 4: Écrire `next_appointment_card.dart`**

```dart
import 'package:colette/core/clock/now_providers.dart';
import 'package:colette/core/dates/date_extensions.dart';
import 'package:colette/core/theme/app_colors.dart';
import 'package:colette/core/theme/design_tokens.dart';
import 'package:colette/core/theme/text_styles.dart';
import 'package:colette/features/health/domain/entities/appointment_proximity.dart';
import 'package:colette/features/health/domain/entities/medical_timeline.dart';
import 'package:colette/features/health/presentation/providers/health_providers.dart';
import 'package:colette/features/health/presentation/widgets/timeline_item_ui.dart';
import 'package:colette/l10n/generated/app_localizations.dart';
import 'package:colette/shared/ui/widgets/colette_card_surface.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Carte « Prochain rendez-vous » de l'onglet Santé : le RDV programmé le
/// plus proche en évidence, ou « Pas de rendez-vous programmé ».
class NextAppointmentCard extends ConsumerWidget {
  const NextAppointmentCard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final s = S.of(context);
    final styles = Theme.of(context).coletteTextStyles;
    final item = ref.watch(medicalTimelineProvider)?.nextAppointment;
    final proximity = ref.watch(nextAppointmentProximityProvider);
    final appointmentAt = item?.appointmentAt;
    return Column(
      crossAxisAlignment: .stretch,
      spacing: AppSpacing.sm.value,
      children: [
        Padding(
          padding: AppSpacing.md.top,
          child: Text(
            s.healthNextAppointment,
            style: styles.overline.copyWith(
              color: context.appColor(AppColors.primary),
            ),
          ),
        ),
        if (item == null || proximity == null || appointmentAt == null)
          const _EmptyCard()
        else
          _AppointmentBody(
            item: item,
            appointmentAt: appointmentAt,
            proximity: proximity,
          ),
      ],
    );
  }
}

class _EmptyCard extends StatelessWidget {
  const _EmptyCard();

  @override
  Widget build(BuildContext context) {
    final secondary = context.appColor(AppColors.textSecondary);
    return ColetteCardSurface(
      child: Row(
        spacing: AppSpacing.sm.value,
        children: [
          Icon(Icons.event_busy_outlined, color: secondary),
          Expanded(
            child: Text(
              S.of(context).healthNoAppointment,
              style: Theme.of(
                context,
              ).coletteTextStyles.body.copyWith(color: secondary),
            ),
          ),
        ],
      ),
    );
  }
}

class _AppointmentBody extends ConsumerWidget {
  const _AppointmentBody({
    required this.item,
    required this.appointmentAt,
    required this.proximity,
  });

  final MedicalTimelineItem item;
  final DateTime appointmentAt;
  final AppointmentProximity proximity;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final s = S.of(context);
    final styles = Theme.of(context).coletteTextStyles;
    final today = ref.watch(todayProvider);
    final countdown = switch (proximity) {
      AppointmentProximity.today || AppointmentProximity.tomorrow => null,
      AppointmentProximity.soon || AppointmentProximity.later => s.healthInDays(
        calendarDaysBetween(today, appointmentAt.dateOnly),
      ),
    };
    final details = [?item.practitioner, ?countdown].join(' · ');
    return ColetteCardSurface(
      backgroundColor: AppColors.primaryContainer,
      borderColor: AppColors.primaryContainer,
      onTap: () => showTimelineItemSheet(context, item),
      child: Column(
        crossAxisAlignment: .start,
        spacing: AppSpacing.xxs.value,
        children: [
          Text(
            appointmentDateText(s, appointmentAt, proximity),
            style: styles.heading2.copyWith(
              color: context.appColor(AppColors.primary),
            ),
          ),
          Text(timelineItemTitle(s, item), style: styles.bodyMedium),
          if (details.isNotEmpty)
            Text(
              details,
              style: styles.small.copyWith(
                color: context.appColor(AppColors.textSecondary),
              ),
            ),
          Padding(
            padding: AppSpacing.xs.top,
            child: TimelineItemChips(item: item),
          ),
        ],
      ),
    );
  }
}
```

- [ ] **Step 5: Tests verts**

Run: `flutter test test/features/health/presentation/next_appointment_card_test.dart`
Expected: 4 tests verts. Le compte à rebours du test « éloigné » vaut 14 (du 20 oct. au 3 nov.).

- [ ] **Step 6: Commit**

```bash
dart format lib test && dart analyze
git add lib/features/health/presentation/widgets/timeline_item_ui.dart lib/features/health/presentation/widgets/next_appointment_card.dart test/features/health/presentation/next_appointment_card_test.dart
git commit -m "feat: carte Prochain rendez-vous de l'onglet Santé

Co-Authored-By: Claude Fable 5.1 <noreply@anthropic.com>"
```

---

### Task 7: Tuile datée et section « Aussi programmés »

**Files:**
- Create: `lib/features/health/presentation/widgets/dated_appointment_tile.dart`
- Create: `lib/features/health/presentation/widgets/scheduled_section.dart`
- Test: `test/features/health/presentation/scheduled_section_test.dart`

- [ ] **Step 1: Test qui échoue**

```dart
import 'package:colette/features/health/domain/entities/medical_stage.dart';
import 'package:colette/features/health/domain/entities/medical_stage_status.dart';
import 'package:colette/features/health/domain/entities/medical_timeline.dart';
import 'package:colette/features/health/presentation/widgets/scheduled_section.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../helpers/pump_app.dart';
import '../health_factories.dart';

void main() {
  Future<void> pumpSection(
    WidgetTester tester,
    List<MedicalTimelineItem> items,
  ) => pumpApp(
    tester,
    Scaffold(body: ListView(children: [ScheduledSection(items: items)])),
  );

  testWidgets('rien avec moins de deux RDV programmés', (tester) async {
    await pumpSection(tester, [
      MedicalTimelineItem.stage(
        entry(
          MedicalStageId.m2,
          MedicalStageStatus.scheduled,
          appointmentAt: DateTime(2026, 11, 3, 10),
        ),
      ),
    ]);
    expect(find.text('Aussi programmés'), findsNothing);
  });

  testWidgets('liste les RDV sauf le premier, avec bloc date et détail', (
    tester,
  ) async {
    await pumpSection(tester, [
      MedicalTimelineItem.stage(
        entry(
          MedicalStageId.m2,
          MedicalStageStatus.scheduled,
          appointmentAt: DateTime(2026, 11, 3, 10),
        ),
      ),
      AppointmentItem(
        makeAppointment(
          id: 'osteo',
          appointmentAt: DateTime(2026, 11, 14, 15),
        ),
        MedicalStageStatus.scheduled,
      ),
      MedicalTimelineItem.stage(
        entry(
          MedicalStageId.m3,
          MedicalStageStatus.scheduled,
          appointmentAt: DateTime(2026, 12, 2, 9, 30),
          practitioner: 'Dr Martin',
        ),
      ),
    ]);
    expect(find.text('Aussi programmés'), findsOneWidget);
    expect(find.text('Examen et vaccins des 2 mois'), findsNothing);
    expect(find.text('14'), findsOneWidget);
    expect(find.text('nov.'), findsOneWidget);
    expect(find.text('Ostéopathe'), findsOneWidget);
    expect(find.text('15h00 · RDV libre'), findsOneWidget);
    expect(find.text('2'), findsOneWidget);
    expect(find.text('déc.'), findsOneWidget);
    expect(find.text('09h30 · Dr Martin'), findsOneWidget);
    expect(find.byIcon(Icons.chevron_right), findsNWidgets(2));
  });
}
```

- [ ] **Step 2: Vérifier l'échec**

Run: `flutter test test/features/health/presentation/scheduled_section_test.dart`
Expected: erreur de compilation.

- [ ] **Step 3: Écrire `dated_appointment_tile.dart`**

```dart
import 'package:colette/core/dates/time_format.dart';
import 'package:colette/core/theme/app_colors.dart';
import 'package:colette/core/theme/design_tokens.dart';
import 'package:colette/core/theme/text_styles.dart';
import 'package:colette/features/health/domain/entities/medical_timeline.dart';
import 'package:colette/features/health/presentation/widgets/timeline_item_ui.dart';
import 'package:colette/l10n/generated/app_localizations.dart';
import 'package:flutter/material.dart';

/// Ligne d'un RDV programmé : bloc date à gauche, libellé, heure et
/// praticien (ou « RDV libre »), chevron ; [onTap] ouvre la feuille.
class DatedAppointmentTile extends StatelessWidget {
  const DatedAppointmentTile({
    super.key,
    required this.item,
    required this.appointmentAt,
    this.onTap,
  });

  final MedicalTimelineItem item;
  final DateTime appointmentAt;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    final styles = Theme.of(context).coletteTextStyles;
    final secondary = context.appColor(AppColors.textSecondary);
    final detail = switch (item) {
      StageItem() => item.practitioner,
      AppointmentItem() => item.practitioner ?? s.healthChipCustom,
    };
    return ListTile(
      contentPadding: AppSpacing.sm.horizontal,
      onTap: onTap,
      leading: Column(
        mainAxisSize: .min,
        mainAxisAlignment: .center,
        children: [
          Text(formatDayOfMonth(appointmentAt), style: styles.numberMedium),
          Text(
            formatShortMonth(appointmentAt),
            style: styles.small.copyWith(color: secondary),
          ),
        ],
      ),
      title: Text(timelineItemTitle(s, item), style: styles.bodyMedium),
      subtitle: Text(
        [formatHourMinute(appointmentAt), ?detail].join(' · '),
        style: styles.small.copyWith(color: secondary),
      ),
      trailing: Icon(Icons.chevron_right, color: secondary),
    );
  }
}
```

- [ ] **Step 4: Écrire `scheduled_section.dart`**

```dart
import 'package:colette/core/theme/design_tokens.dart';
import 'package:colette/features/health/domain/entities/medical_timeline.dart';
import 'package:colette/features/health/presentation/widgets/dated_appointment_tile.dart';
import 'package:colette/features/health/presentation/widgets/timeline_item_ui.dart';
import 'package:colette/l10n/generated/app_localizations.dart';
import 'package:colette/shared/ui/widgets/colette_card_surface.dart';
import 'package:colette/shared/ui/widgets/section_header.dart';
import 'package:flutter/material.dart';

/// Section « Aussi programmés » : les RDV programmés après le premier
/// (déjà en carte « Prochain rendez-vous »). Rien s'il y en a moins de deux.
class ScheduledSection extends StatelessWidget {
  const ScheduledSection({super.key, required this.items});

  /// RDV programmés, du plus proche au plus lointain.
  final List<MedicalTimelineItem> items;

  @override
  Widget build(BuildContext context) {
    if (items.length < 2) return const SizedBox.shrink();
    final rest = items.skip(1);
    return Column(
      crossAxisAlignment: .stretch,
      children: [
        SectionHeader(title: S.of(context).healthSectionScheduled),
        ColetteCardSurface(
          padding: AppSpacing.xs.all,
          child: Column(
            children: [
              for (final item in rest)
                if (item.appointmentAt case final at?)
                  DatedAppointmentTile(
                    item: item,
                    appointmentAt: at,
                    onTap: () => showTimelineItemSheet(context, item),
                  ),
            ],
          ),
        ),
      ],
    );
  }
}
```

- [ ] **Step 5: Tests verts**

Run: `flutter test test/features/health/presentation/scheduled_section_test.dart`
Expected: 2 tests verts.

- [ ] **Step 6: Commit**

```bash
dart format lib test && dart analyze
git add lib/features/health/presentation/widgets/dated_appointment_tile.dart lib/features/health/presentation/widgets/scheduled_section.dart test/features/health/presentation/scheduled_section_test.dart
git commit -m "feat: section Aussi programmés avec tuiles datées

Co-Authored-By: Claude Fable 5.1 <noreply@anthropic.com>"
```

---

### Task 8: Section « À programmer »

**Files:**
- Create: `lib/features/health/presentation/widgets/to_schedule_section.dart`
- Test: `test/features/health/presentation/to_schedule_section_test.dart`

- [ ] **Step 1: Test qui échoue**

```dart
import 'package:colette/core/theme/app_colors.dart';
import 'package:colette/features/health/domain/entities/medical_stage.dart';
import 'package:colette/features/health/domain/entities/medical_stage_status.dart';
import 'package:colette/features/health/domain/entities/medical_timeline.dart';
import 'package:colette/features/health/presentation/widgets/medical_stage_tile.dart';
import 'package:colette/features/health/presentation/widgets/to_schedule_section.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../helpers/pump_app.dart';
import '../health_factories.dart';

void main() {
  testWidgets('lignes compactes : retard en warning, fenêtre courte, sans pastille', (
    tester,
  ) async {
    await pumpApp(
      tester,
      Scaffold(
        body: ListView(
          children: [
            ToScheduleSection(
              items: [
                MedicalTimelineItem.stage(
                  entry(MedicalStageId.week2, MedicalStageStatus.late),
                ),
                MedicalTimelineItem.stage(
                  entry(MedicalStageId.m2, MedicalStageStatus.due),
                ),
              ],
            ),
          ],
        ),
      ),
    );
    expect(find.text('À programmer'), findsOneWidget);
    expect(find.text('Examen de la 2e semaine'), findsOneWidget);
    expect(find.text('en retard'), findsOneWidget);
    expect(find.text('Examen et vaccins des 2 mois'), findsOneWidget);
    expect(find.text('du 1 nov. au 30 nov.'), findsOneWidget);
    expect(find.byType(MedicalChip), findsNothing);
    expect(find.byIcon(Icons.chevron_right), findsNothing);
    final late = tester.widget<Text>(find.text('en retard'));
    expect(late.style?.color, AppColors.warning.light);
  });

  testWidgets('rien si vide', (tester) async {
    await pumpApp(
      tester,
      const Scaffold(body: ToScheduleSection(items: [])),
    );
    expect(find.text('À programmer'), findsNothing);
  });

  testWidgets('tap : ouvre la feuille de l\'étape', (tester) async {
    await pumpApp(
      tester,
      Scaffold(
        body: ToScheduleSection(
          items: [
            MedicalTimelineItem.stage(
              entry(MedicalStageId.m2, MedicalStageStatus.due),
            ),
          ],
        ),
      ),
    );
    await tester.tap(find.text('Examen et vaccins des 2 mois'));
    await tester.pumpAndSettle();
    expect(find.text('Rendez-vous'), findsWidgets);
  });
}
```

Si le test de tap échoue sur un provider non surchargé (la feuille lit `babyProfileProvider`), ajouter `overrides: [babyProfileProvider.overrideWith((ref) => Stream.value(null))]` avec l'import `package:colette/features/baby/presentation/providers/baby_providers.dart`.

- [ ] **Step 2: Vérifier l'échec**

Run: `flutter test test/features/health/presentation/to_schedule_section_test.dart`
Expected: erreur de compilation.

- [ ] **Step 3: Implémenter**

```dart
import 'package:colette/core/dates/time_format.dart';
import 'package:colette/core/theme/app_colors.dart';
import 'package:colette/core/theme/design_tokens.dart';
import 'package:colette/core/theme/text_styles.dart';
import 'package:colette/features/health/domain/entities/medical_stage_status.dart';
import 'package:colette/features/health/domain/entities/medical_timeline.dart';
import 'package:colette/features/health/presentation/labels/health_labels.dart';
import 'package:colette/features/health/presentation/widgets/medical_stage_sheet.dart';
import 'package:colette/l10n/generated/app_localizations.dart';
import 'package:colette/shared/ui/widgets/section_header.dart';
import 'package:flutter/material.dart';

/// Section « À programmer » : étapes en retard puis à faire, en lignes
/// compactes et discrètes, sans carte ni pastilles. Rien si vide.
class ToScheduleSection extends StatelessWidget {
  const ToScheduleSection({super.key, required this.items});

  final List<MedicalTimelineItem> items;

  @override
  Widget build(BuildContext context) {
    final entries = [
      for (final item in items)
        if (item case StageItem(:final entry)) entry,
    ];
    if (entries.isEmpty) return const SizedBox.shrink();
    return Column(
      crossAxisAlignment: .stretch,
      children: [
        SectionHeader(title: S.of(context).healthSectionToSchedule),
        for (final (index, entry) in entries.indexed) ...[
          if (index > 0)
            Divider(height: AppSpacing.none.value, color: context.appColor(AppColors.border)),
          CompactStageRow(
            entry: entry,
            onTap: () => showMedicalStageSheet(context, entry),
          ),
        ],
      ],
    );
  }
}

/// Ligne compacte d'une étape à caler : libellé à gauche, « en retard » ou
/// fenêtre courte à droite.
class CompactStageRow extends StatelessWidget {
  const CompactStageRow({super.key, required this.entry, this.onTap});

  final MedicalTimelineEntry entry;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    final styles = Theme.of(context).coletteTextStyles;
    final secondary = context.appColor(AppColors.textSecondary);
    final late = entry.status == MedicalStageStatus.late;
    final lastDay = DateTime(
      entry.dueUntil.year,
      entry.dueUntil.month,
      entry.dueUntil.day - 1,
    );
    final trailing = late
        ? s.healthLateShort
        : s.healthDueWindowShort(
            formatDayMonth(entry.dueFrom),
            formatDayMonth(lastDay),
          );
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: AppSpacing.sm.all,
        child: Row(
          spacing: AppSpacing.sm.value,
          children: [
            Expanded(
              child: Text(
                HealthLabels.stage(s, entry.stage.id),
                style: styles.body.copyWith(color: secondary),
              ),
            ),
            Text(
              trailing,
              style: styles.small.copyWith(
                color: late ? context.appColor(AppColors.warning) : secondary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
```

- [ ] **Step 4: Tests verts**

Run: `flutter test test/features/health/presentation/to_schedule_section_test.dart`
Expected: 3 tests verts.

- [ ] **Step 5: Commit**

```bash
dart format lib test && dart analyze
git add lib/features/health/presentation/widgets/to_schedule_section.dart test/features/health/presentation/to_schedule_section_test.dart
git commit -m "feat: section À programmer en lignes compactes

Co-Authored-By: Claude Fable 5.1 <noreply@anthropic.com>"
```

---

### Task 9: Section « RDV passé, à confirmer » et statut en warning sur les tuiles

**Files:**
- Modify: `lib/features/health/presentation/widgets/medical_stage_tile.dart`
- Modify: `lib/features/health/presentation/widgets/custom_appointment_tile.dart`
- Create: `lib/features/health/presentation/widgets/awaiting_confirmation_section.dart`
- Test: `test/features/health/presentation/awaiting_confirmation_section_test.dart`

- [ ] **Step 1: Test qui échoue**

```dart
import 'package:colette/core/theme/app_colors.dart';
import 'package:colette/features/health/domain/entities/medical_stage.dart';
import 'package:colette/features/health/domain/entities/medical_stage_status.dart';
import 'package:colette/features/health/domain/entities/medical_timeline.dart';
import 'package:colette/features/health/presentation/widgets/awaiting_confirmation_section.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../helpers/pump_app.dart';
import '../health_factories.dart';

void main() {
  testWidgets('étape et RDV libre passés, statut en warning', (tester) async {
    await pumpApp(
      tester,
      Scaffold(
        body: ListView(
          children: [
            AwaitingConfirmationSection(
              items: [
                MedicalTimelineItem.stage(
                  entry(
                    MedicalStageId.m1,
                    MedicalStageStatus.appointmentPassed,
                    appointmentAt: DateTime(2026, 9, 18, 9),
                  ),
                ),
                AppointmentItem(
                  makeAppointment(appointmentAt: DateTime(2026, 9, 10, 9)),
                  MedicalStageStatus.appointmentPassed,
                ),
              ],
            ),
          ],
        ),
      ),
    );
    expect(find.text('RDV passé, à confirmer'), findsOneWidget);
    expect(find.text('Examen du 1er mois'), findsOneWidget);
    expect(find.text('Ostéopathe'), findsOneWidget);
    final stageStatus = tester.widget<Text>(
      find.text('RDV du 18 sept. 2026 passé · à marquer comme faite'),
    );
    final rdvStatus = tester.widget<Text>(
      find.text('RDV du 10 sept. 2026 passé · à marquer comme faite'),
    );
    expect(stageStatus.style?.color, AppColors.warning.light);
    expect(rdvStatus.style?.color, AppColors.warning.light);
  });

  testWidgets('rien si vide', (tester) async {
    await pumpApp(
      tester,
      const Scaffold(body: AwaitingConfirmationSection(items: [])),
    );
    expect(find.text('RDV passé, à confirmer'), findsNothing);
  });
}
```

- [ ] **Step 2: Vérifier l'échec**

Run: `flutter test test/features/health/presentation/awaiting_confirmation_section_test.dart`
Expected: erreur de compilation.

- [ ] **Step 3: Colorer le statut `appointmentPassed` dans les deux tuiles**

Dans `medical_stage_tile.dart`, remplacer

```dart
    final late = entry.status == MedicalStageStatus.late;
```

par

```dart
    final highlighted = switch (entry.status) {
      MedicalStageStatus.late || MedicalStageStatus.appointmentPassed => true,
      _ => false,
    };
```

et, dans le `Text` de statut, `late ? AppColors.warning : AppColors.textSecondary` par `highlighted ? AppColors.warning : AppColors.textSecondary`.

Dans `custom_appointment_tile.dart`, ajouter l'import `package:colette/features/health/domain/entities/medical_stage_status.dart`, puis dans `build` avant le `return` :

```dart
    final highlighted = item.status == MedicalStageStatus.appointmentPassed;
```

et remplacer la couleur du `Text` de statut :

```dart
            style: styles.small.copyWith(
              color: context.appColor(
                highlighted ? AppColors.warning : AppColors.textSecondary,
              ),
            ),
```

- [ ] **Step 4: Écrire `awaiting_confirmation_section.dart`**

```dart
import 'package:colette/core/theme/app_colors.dart';
import 'package:colette/core/theme/design_tokens.dart';
import 'package:colette/features/health/domain/entities/medical_timeline.dart';
import 'package:colette/features/health/presentation/widgets/custom_appointment_tile.dart';
import 'package:colette/features/health/presentation/widgets/medical_stage_tile.dart';
import 'package:colette/features/health/presentation/widgets/timeline_item_ui.dart';
import 'package:colette/l10n/generated/app_localizations.dart';
import 'package:colette/shared/ui/widgets/colette_card_surface.dart';
import 'package:colette/shared/ui/widgets/section_header.dart';
import 'package:flutter/material.dart';

/// Section « RDV passé, à confirmer » : visites dont le RDV est passé sans
/// être marquées faites, dans une carte à bordure `warning`. Rien si vide.
class AwaitingConfirmationSection extends StatelessWidget {
  const AwaitingConfirmationSection({super.key, required this.items});

  final List<MedicalTimelineItem> items;

  @override
  Widget build(BuildContext context) {
    if (items.isEmpty) return const SizedBox.shrink();
    return Column(
      crossAxisAlignment: .stretch,
      children: [
        SectionHeader(title: S.of(context).healthSectionAwaiting),
        ColetteCardSurface(
          padding: AppSpacing.xs.all,
          borderColor: AppColors.warning,
          child: Column(
            children: [
              for (final item in items)
                switch (item) {
                  StageItem(:final entry) => MedicalStageTile(
                    entry: entry,
                    onTap: () => showTimelineItemSheet(context, item),
                  ),
                  AppointmentItem() => CustomAppointmentTile(
                    item: item,
                    onTap: () => showTimelineItemSheet(context, item),
                  ),
                },
            ],
          ),
        ),
      ],
    );
  }
}
```

- [ ] **Step 5: Tests verts**

Run: `flutter test test/features/health/presentation/awaiting_confirmation_section_test.dart test/features/health/presentation/`
Expected: verts (les tests existants des tuiles restent verts : le statut `late` reste en warning).

- [ ] **Step 6: Commit**

```bash
dart format lib test && dart analyze
git add lib/features/health/presentation/widgets/medical_stage_tile.dart lib/features/health/presentation/widgets/custom_appointment_tile.dart lib/features/health/presentation/widgets/awaiting_confirmation_section.dart test/features/health/presentation/awaiting_confirmation_section_test.dart
git commit -m "feat: section RDV passé à confirmer, statut passé en warning

Co-Authored-By: Claude Fable 5.1 <noreply@anthropic.com>"
```

---

### Task 10: Réécriture de `HealthPage`

**Files:**
- Rewrite: `lib/features/health/presentation/pages/health_page.dart`
- Rewrite: `test/features/health/presentation/health_page_test.dart`

- [ ] **Step 1: Réécrire le test**

```dart
import 'package:colette/core/clock/app_clock.dart';
import 'package:colette/core/clock/now_providers.dart';
import 'package:colette/core/firebase/firebase_providers.dart';
import 'package:colette/core/result/failure.dart';
import 'package:colette/features/health/domain/entities/medical_stage.dart';
import 'package:colette/features/health/domain/entities/medical_stage_status.dart';
import 'package:colette/features/health/domain/entities/medical_timeline.dart';
import 'package:colette/features/health/presentation/pages/health_page.dart';
import 'package:colette/features/health/presentation/providers/calendar_sync_issue.dart';
import 'package:colette/features/health/presentation/providers/health_providers.dart';
import 'package:colette/features/health/presentation/providers/health_sync.dart';
import 'package:colette/features/health/presentation/providers/selected_calendar.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../helpers/pump_app.dart';
import '../health_factories.dart';

void main() {
  Future<void> pumpPage(
    WidgetTester tester, {
    required MedicalTimeline? timeline,
    Map<String, Object> prefs = const {},
    List<Override> extra = const [],
  }) async {
    SharedPreferences.setMockInitialValues(prefs);
    final sharedPrefs = await SharedPreferences.getInstance();
    await pumpApp(
      tester,
      const HealthPage(),
      // Assez haut pour que la ListView construise tous les blocs.
      viewSize: const Size(390, 1800),
      overrides: [
        sharedPreferencesProvider.overrideWithValue(sharedPrefs),
        healthSyncProvider.overrideWithValue(const NoopHealthSync()),
        clockProvider.overrideWithValue(FixedClock(DateTime(2026, 10, 20, 9))),
        minuteTickerProvider.overrideWith((ref) => const Stream.empty()),
        medicalTimelineProvider.overrideWithValue(timeline),
        ...extra,
      ],
    );
  }

  final fullTimeline = MedicalTimeline(
    entries: [
      entry(MedicalStageId.day8, MedicalStageStatus.done),
      entry(MedicalStageId.week2, MedicalStageStatus.late),
      entry(
        MedicalStageId.m1,
        MedicalStageStatus.appointmentPassed,
        appointmentAt: DateTime(2026, 9, 18, 9),
      ),
      entry(
        MedicalStageId.m2,
        MedicalStageStatus.scheduled,
        appointmentAt: DateTime(2026, 11, 3, 10),
        practitioner: 'Dr Martin',
      ),
      entry(MedicalStageId.m3, MedicalStageStatus.due),
      entry(MedicalStageId.m4, MedicalStageStatus.upcoming),
      entry(MedicalStageId.m5, MedicalStageStatus.upcoming),
    ],
    appointments: [
      AppointmentItem(
        makeAppointment(appointmentAt: DateTime(2026, 10, 25, 15)),
        MedicalStageStatus.scheduled,
      ),
    ],
  );

  testWidgets('ordre des blocs : prochain RDV, programmés, à confirmer, à programmer, repliés', (
    tester,
  ) async {
    await pumpPage(tester, timeline: fullTimeline);
    expect(find.text('Santé'), findsOneWidget);
    expect(find.text('Prochain rendez-vous'), findsOneWidget);
    // Le RDV libre du 25 octobre précède l'étape du 3 novembre.
    expect(find.text('dim. 25 oct., 15h00'), findsOneWidget);
    expect(find.text('Ostéopathe'), findsOneWidget);
    expect(find.text('Aussi programmés'), findsOneWidget);
    expect(find.text('10h00 · Dr Martin'), findsOneWidget);
    expect(find.text('RDV passé, à confirmer'), findsOneWidget);
    expect(find.text('Examen du 1er mois'), findsOneWidget);
    expect(find.text('À programmer'), findsOneWidget);
    expect(find.text('en retard'), findsOneWidget);
    expect(find.text('À venir (2)'), findsOneWidget);
    expect(find.text('Faites (1)'), findsOneWidget);
    expect(find.text('Examen des 8 jours'), findsNothing);
    expect(find.text('Examen et vaccins des 4 mois'), findsNothing);

    double top(String text) => tester.getTopLeft(find.text(text)).dy;
    expect(top('Prochain rendez-vous'), lessThan(top('Aussi programmés')));
    expect(top('Aussi programmés'), lessThan(top('RDV passé, à confirmer')));
    expect(top('RDV passé, à confirmer'), lessThan(top('À programmer')));
    expect(top('À programmer'), lessThan(top('À venir (2)')));
    expect(top('À venir (2)'), lessThan(top('Faites (1)')));

    await tester.scrollUntilVisible(find.text('À venir (2)'), 200);
    await tester.tap(find.text('À venir (2)'));
    await tester.pumpAndSettle();
    expect(find.text('Examen et vaccins des 4 mois'), findsOneWidget);
  });

  testWidgets('sans RDV : carte grise, sections programmés et à confirmer absentes', (
    tester,
  ) async {
    await pumpPage(
      tester,
      timeline: MedicalTimeline(
        entries: [entry(MedicalStageId.m2, MedicalStageStatus.due)],
      ),
    );
    expect(find.text('Pas de rendez-vous programmé'), findsOneWidget);
    expect(find.text('Aussi programmés'), findsNothing);
    expect(find.text('RDV passé, à confirmer'), findsNothing);
    expect(find.text('À programmer'), findsOneWidget);
  });

  testWidgets('calendrier non configuré : ligne en pied de page seulement', (
    tester,
  ) async {
    await pumpPage(
      tester,
      timeline: MedicalTimeline(
        entries: [entry(MedicalStageId.m2, MedicalStageStatus.due)],
      ),
    );
    final footer = find.text(
      'RDV non ajoutés au Calendrier (à régler dans Réglages)',
    );
    await tester.scrollUntilVisible(footer, 200);
    expect(footer, findsOneWidget);
    expect(
      tester.getTopLeft(footer).dy,
      greaterThan(tester.getTopLeft(find.text('À programmer')).dy),
    );
    expect(find.byIcon(Icons.sync_problem), findsNothing);
  });

  testWidgets('calendrier synchronisé : pied de page avec son nom', (
    tester,
  ) async {
    await pumpPage(
      tester,
      timeline: const MedicalTimeline(entries: []),
      prefs: {
        SelectedCalendar.idKey: 'c1',
        SelectedCalendar.titleKey: 'Famille',
      },
    );
    expect(find.text('Synchronisé avec Famille'), findsOneWidget);
  });

  testWidgets('problème de sync : alerte en haut, pas de pied de page', (
    tester,
  ) async {
    await pumpPage(
      tester,
      timeline: null,
      prefs: {
        SelectedCalendar.idKey: 'c1',
        SelectedCalendar.titleKey: 'Famille',
      },
      extra: [
        calendarSyncIssueProvider.overrideWithValue(
          CalendarReason.accessDenied,
        ),
      ],
    );
    final alert = find.text(
      "Colette n'a pas accès au Calendrier. Autorise-le dans Réglages iOS › Colette › Calendriers.",
    );
    expect(alert, findsOneWidget);
    expect(find.byIcon(Icons.sync_problem), findsOneWidget);
    expect(
      tester.getTopLeft(alert).dy,
      lessThan(tester.getTopLeft(find.text('Prochain rendez-vous')).dy),
    );
    expect(find.textContaining('Famille'), findsNothing);
  });

  testWidgets('bouton d\'ajout ouvre la feuille de RDV libre', (tester) async {
    await pumpPage(tester, timeline: const MedicalTimeline(entries: []));
    expect(find.byTooltip('Ajouter un rendez-vous'), findsOneWidget);
    await tester.tap(find.byTooltip('Ajouter un rendez-vous'));
    await tester.pumpAndSettle();
    expect(find.text('Nouveau rendez-vous'), findsOneWidget);
  });
}
```

Si `dart analyze` signale un import inutilisé (`failure.dart` ou `calendar_sync_issue.dart` selon l'endroit où vit `CalendarReason`), retirer celui qui est inutile.

- [ ] **Step 2: Vérifier l'échec**

Run: `flutter test test/features/health/presentation/health_page_test.dart`
Expected: échecs (« Prochain rendez-vous » introuvable, « À faire » encore présent).

- [ ] **Step 3: Réécrire `health_page.dart`**

```dart
import 'package:colette/core/result/failure.dart';
import 'package:colette/core/theme/app_colors.dart';
import 'package:colette/core/theme/design_tokens.dart';
import 'package:colette/core/theme/text_styles.dart';
import 'package:colette/core/ui/failure_message.dart';
import 'package:colette/features/health/domain/entities/calendar_choice.dart';
import 'package:colette/features/health/domain/entities/medical_timeline.dart';
import 'package:colette/features/health/presentation/providers/calendar_sync_issue.dart';
import 'package:colette/features/health/presentation/providers/custom_appointment_controller.dart';
import 'package:colette/features/health/presentation/providers/health_providers.dart';
import 'package:colette/features/health/presentation/providers/health_sync.dart';
import 'package:colette/features/health/presentation/providers/medical_visit_controller.dart';
import 'package:colette/features/health/presentation/providers/selected_calendar.dart';
import 'package:colette/features/health/presentation/widgets/awaiting_confirmation_section.dart';
import 'package:colette/features/health/presentation/widgets/custom_appointment_sheet.dart';
import 'package:colette/features/health/presentation/widgets/custom_appointment_tile.dart';
import 'package:colette/features/health/presentation/widgets/medical_stage_tile.dart';
import 'package:colette/features/health/presentation/widgets/next_appointment_card.dart';
import 'package:colette/features/health/presentation/widgets/scheduled_section.dart';
import 'package:colette/features/health/presentation/widgets/timeline_item_ui.dart';
import 'package:colette/features/health/presentation/widgets/to_schedule_section.dart';
import 'package:colette/l10n/generated/app_localizations.dart';
import 'package:colette/shared/ui/widgets/colette_card_surface.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Page Santé : prochain RDV en évidence, autres RDV programmés, RDV passés
/// à confirmer, étapes à programmer, puis à venir et faites repliées.
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
    // Garde les contrôleurs autoDispose vivants pendant les écritures des feuilles.
    void showError(AsyncValue<void> next) {
      if (next case AsyncError(:final error)) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(failureMessage(error, s))));
      }
    }

    ref.listen(medicalVisitControllerProvider, (_, next) => showError(next));
    ref.listen(
      customAppointmentControllerProvider,
      (_, next) => showError(next),
    );
    final timeline = ref.watch(medicalTimelineProvider);
    final hasIssue = ref.watch(calendarSyncIssueProvider) != null;
    return Scaffold(
      appBar: AppBar(
        title: Text(s.healthTitle),
        actions: [
          IconButton(
            tooltip: s.healthAddAppointment,
            icon: const Icon(Icons.add),
            onPressed: () => showCustomAppointmentSheet(context),
          ),
        ],
      ),
      body: ListView(
        padding: AppSpacing.md.horizontal,
        children: [
          if (hasIssue) const _CalendarStatus(),
          const NextAppointmentCard(),
          if (timeline != null) ...[
            ScheduledSection(items: timeline.scheduled),
            AwaitingConfirmationSection(items: timeline.awaitingConfirmation),
            ToScheduleSection(items: timeline.toSchedule),
            if (timeline.upcoming.isNotEmpty)
              _CollapsedSection(
                title: s.healthSectionUpcomingCount(timeline.upcoming.length),
                items: timeline.upcoming,
              ),
            if (timeline.done.isNotEmpty)
              _CollapsedSection(
                title: s.healthSectionDone(timeline.done.length),
                items: timeline.done,
              ),
          ],
          if (!hasIssue) const _CalendarStatus(),
          AppSpacing.xl.verticalSpace,
        ],
      ),
    );
  }
}

/// Alerte de synchronisation (en haut, `warning`) ou état du calendrier
/// (en pied de page, discret).
class _CalendarStatus extends ConsumerWidget {
  const _CalendarStatus();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final s = S.of(context);
    final choice = ref.watch(selectedCalendarProvider);
    final issue = ref.watch(calendarSyncIssueProvider);
    final (icon, text, color) = switch ((issue, choice)) {
      (final CalendarReason reason, _) => (
        Icons.sync_problem,
        failureMessage(CalendarFailure(reason), s),
        AppColors.warning,
      ),
      (null, null) => (
        Icons.event_busy_outlined,
        s.healthCalendarNotConfigured,
        AppColors.textSecondary,
      ),
      (null, final CalendarChoice choice) => (
        Icons.event_available,
        s.healthCalendarSynced(choice.title),
        AppColors.textSecondary,
      ),
    };
    return Padding(
      padding: AppSpacing.md.vertical,
      child: Row(
        spacing: AppSpacing.sm.value,
        children: [
          Icon(icon, color: context.appColor(color)),
          Expanded(
            child: Text(
              text,
              style: Theme.of(context).coletteTextStyles.small
                  .copyWith(color: context.appColor(color)),
            ),
          ),
        ],
      ),
    );
  }
}

/// Tuile d'un élément de la frise ; tap : feuille d'étape ou de RDV libre.
class _ItemTile extends StatelessWidget {
  const _ItemTile({required this.item});

  final MedicalTimelineItem item;

  @override
  Widget build(BuildContext context) => switch (item) {
    StageItem(:final entry) => MedicalStageTile(
      entry: entry,
      onTap: () => showTimelineItemSheet(context, item),
    ),
    AppointmentItem() => CustomAppointmentTile(
      item: item,
      onTap: () => showTimelineItemSheet(context, item),
    ),
  };
}

/// Section repliée par défaut : « À venir (n) », « Faites (n) ».
class _CollapsedSection extends StatelessWidget {
  const _CollapsedSection({required this.title, required this.items});

  final String title;
  final List<MedicalTimelineItem> items;

  @override
  Widget build(BuildContext context) => Padding(
    padding: AppSpacing.md.top,
    child: ColetteCardSurface(
      padding: AppSpacing.xs.all,
      child: ExpansionTile(
        title: Text(
          title,
          style: Theme.of(context).coletteTextStyles.bodyMedium,
        ),
        shape: const Border(),
        collapsedShape: const Border(),
        children: [for (final item in items) _ItemTile(item: item)],
      ),
    ),
  );
}
```

- [ ] **Step 4: Tests verts**

Run: `flutter test test/features/health/presentation/`
Expected: verts.

- [ ] **Step 5: Commit**

```bash
dart format lib test && dart analyze
git add lib/features/health/presentation/pages/health_page.dart test/features/health/presentation/health_page_test.dart
git commit -m "feat: onglet Santé recentré sur les RDV programmés

Co-Authored-By: Claude Fable 5.1 <noreply@anthropic.com>"
```

---

### Task 11: Tuile Rendez-vous de l'accueil

**Files:**
- Create: `lib/features/health/presentation/widgets/appointment_card.dart`
- Test: `test/features/health/presentation/appointment_card_test.dart`

- [ ] **Step 1: Test qui échoue**

```dart
import 'package:colette/app/router/app_router.dart';
import 'package:colette/core/clock/app_clock.dart';
import 'package:colette/core/clock/now_providers.dart';
import 'package:colette/core/connectivity/connectivity_provider.dart';
import 'package:colette/core/theme/app_colors.dart';
import 'package:colette/core/theme/theme_service.dart';
import 'package:colette/features/health/domain/entities/medical_stage.dart';
import 'package:colette/features/health/domain/entities/medical_stage_status.dart';
import 'package:colette/features/health/domain/entities/medical_timeline.dart';
import 'package:colette/features/health/presentation/providers/health_providers.dart';
import 'package:colette/features/health/presentation/widgets/appointment_card.dart';
import 'package:colette/l10n/generated/app_localizations.dart';
import 'package:colette/shared/ui/widgets/colette_card_surface.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

import '../health_factories.dart';

void main() {
  final now = DateTime(2026, 10, 20, 9);

  Future<void> pumpCard(WidgetTester tester, MedicalTimeline? timeline) async {
    final router = GoRouter(
      initialLocation: AppRoutes.today,
      routes: [
        GoRoute(
          path: AppRoutes.today,
          builder: (_, _) => const Scaffold(body: AppointmentCard()),
        ),
        GoRoute(
          path: AppRoutes.health,
          builder: (_, _) => const Scaffold(body: Text('page santé')),
        ),
      ],
    );
    addTearDown(router.dispose);
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          isOnlineProvider.overrideWith((ref) => Stream.value(true)),
          clockProvider.overrideWithValue(FixedClock(now)),
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

  MedicalTimeline scheduledAt(DateTime at, {String? practitioner}) =>
      MedicalTimeline(
        entries: [
          entry(
            MedicalStageId.m2,
            MedicalStageStatus.scheduled,
            appointmentAt: at,
            practitioner: practitioner,
          ),
        ],
      );

  ColetteCardSurface surface(WidgetTester tester) =>
      tester.widget<ColetteCardSurface>(find.byType(ColetteCardSurface));

  testWidgets('sans frise ni RDV : « Pas de rendez-vous programmé »', (
    tester,
  ) async {
    await pumpCard(tester, null);
    expect(find.text('Rendez-vous'), findsOneWidget);
    expect(find.text('Pas de rendez-vous programmé'), findsOneWidget);
    expect(find.byIcon(Icons.event_busy_outlined), findsOneWidget);

    await pumpCard(
      tester,
      MedicalTimeline(
        entries: [entry(MedicalStageId.m2, MedicalStageStatus.due)],
      ),
    );
    expect(find.text('Pas de rendez-vous programmé'), findsOneWidget);
  });

  testWidgets('éloigné : neutre, date et praticien', (tester) async {
    await pumpCard(
      tester,
      scheduledAt(DateTime(2026, 11, 3, 10), practitioner: 'Dr Martin'),
    );
    expect(find.text('Rendez-vous'), findsOneWidget);
    expect(find.text('Examen et vaccins des 2 mois'), findsOneWidget);
    expect(find.text('mar. 3 nov., 10h00 · Dr Martin'), findsOneWidget);
    expect(surface(tester).borderColor, AppColors.border);
    expect(surface(tester).backgroundColor, AppColors.surface);
  });

  testWidgets('bientôt : bordure primary et « dans N jours »', (tester) async {
    await pumpCard(tester, scheduledAt(DateTime(2026, 10, 23, 10)));
    expect(find.text('Rendez-vous dans 3 jours'), findsOneWidget);
    expect(find.text('ven. 23 oct., 10h00'), findsOneWidget);
    expect(surface(tester).borderColor, AppColors.primary);
    expect(surface(tester).backgroundColor, AppColors.surface);
  });

  testWidgets('aujourd\'hui et demain : fond primaryContainer, heure en gros', (
    tester,
  ) async {
    await pumpCard(tester, scheduledAt(DateTime(2026, 10, 20, 15, 30)));
    expect(find.text('Aujourd\'hui à 15h30'), findsOneWidget);
    expect(surface(tester).backgroundColor, AppColors.primaryContainer);

    await pumpCard(tester, scheduledAt(DateTime(2026, 10, 21, 8)));
    expect(find.text('Demain à 08h00'), findsOneWidget);
    expect(surface(tester).backgroundColor, AppColors.primaryContainer);
  });

  testWidgets('RDV passé non confirmé prime sur le prochain RDV', (
    tester,
  ) async {
    await pumpCard(
      tester,
      MedicalTimeline(
        entries: [
          entry(
            MedicalStageId.m1,
            MedicalStageStatus.appointmentPassed,
            appointmentAt: DateTime(2026, 9, 18, 9),
          ),
          entry(
            MedicalStageId.m2,
            MedicalStageStatus.scheduled,
            appointmentAt: DateTime(2026, 10, 20, 15),
          ),
        ],
      ),
    );
    expect(find.text('RDV passé · à marquer comme faite'), findsOneWidget);
    expect(find.text('Examen du 1er mois'), findsOneWidget);
    expect(find.text('ven. 18 sept., 09h00'), findsOneWidget);
    expect(find.textContaining('Aujourd\'hui'), findsNothing);
    expect(surface(tester).borderColor, AppColors.warning);
  });

  testWidgets('tap : va sur l\'onglet Santé', (tester) async {
    await pumpCard(tester, null);
    await tester.tap(find.byType(AppointmentCard));
    await tester.pumpAndSettle();
    expect(find.text('page santé'), findsOneWidget);
  });
}
```

- [ ] **Step 2: Vérifier l'échec**

Run: `flutter test test/features/health/presentation/appointment_card_test.dart`
Expected: erreur de compilation.

- [ ] **Step 3: Implémenter `appointment_card.dart`**

```dart
import 'package:colette/app/router/app_router.dart';
import 'package:colette/core/clock/now_providers.dart';
import 'package:colette/core/dates/date_extensions.dart';
import 'package:colette/core/dates/time_format.dart';
import 'package:colette/core/theme/app_colors.dart';
import 'package:colette/core/theme/design_tokens.dart';
import 'package:colette/core/theme/text_styles.dart';
import 'package:colette/features/health/domain/entities/appointment_proximity.dart';
import 'package:colette/features/health/domain/entities/medical_timeline.dart';
import 'package:colette/features/health/presentation/providers/health_providers.dart';
import 'package:colette/features/health/presentation/widgets/timeline_item_ui.dart';
import 'package:colette/l10n/generated/app_localizations.dart';
import 'package:colette/shared/ui/widgets/colette_card_surface.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

/// Tuile « Rendez-vous » d'Aujourd'hui : toujours affichée ; RDV passé à
/// confirmer, sinon prochain RDV programmé avec une emphase croissante
/// (éloigné, bientôt, aujourd'hui / demain), sinon « Pas de rendez-vous ».
class AppointmentCard extends ConsumerWidget {
  const AppointmentCard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final timeline = ref.watch(medicalTimelineProvider);
    final proximity = ref.watch(nextAppointmentProximityProvider);
    final today = ref.watch(todayProvider);
    final awaiting = timeline?.awaitingConfirmation.firstOrNull;
    final next = timeline?.nextAppointment;
    final _State state;
    if ((awaiting, awaiting?.appointmentAt) case (final item?, final at?)) {
      state = _Awaiting(item, at);
    } else if ((next, next?.appointmentAt, proximity) case (
      final item?,
      final at?,
      final p?,
    )) {
      state = _Upcoming(item, at, p, calendarDaysBetween(today, at.dateOnly));
    } else {
      state = const _None();
    }
    return Padding(
      padding: AppSpacing.md.top,
      child: ColetteCardSurface(
        backgroundColor: state.background,
        borderColor: state.border,
        onTap: () => context.go(AppRoutes.health),
        child: Row(
          spacing: AppSpacing.sm.value,
          children: [
            Icon(state.icon, color: context.appColor(state.accent)),
            Expanded(child: _Body(state: state)),
            Icon(
              Icons.chevron_right,
              color: context.appColor(
                state.isImminent ? AppColors.primary : AppColors.textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// État d'affichage de la tuile.
sealed class _State {
  const _State();

  AppColors get background => AppColors.surface;
  AppColors get border => AppColors.border;
  AppColors get accent => AppColors.textSecondary;
  IconData get icon => Icons.event_outlined;
  bool get isImminent => false;
}

class _None extends _State {
  const _None();

  @override
  IconData get icon => Icons.event_busy_outlined;
}

class _Awaiting extends _State {
  const _Awaiting(this.item, this.appointmentAt);

  final MedicalTimelineItem item;
  final DateTime appointmentAt;

  @override
  AppColors get border => AppColors.warning;
  @override
  AppColors get accent => AppColors.warning;
  @override
  IconData get icon => Icons.event_busy_outlined;
}

class _Upcoming extends _State {
  const _Upcoming(this.item, this.appointmentAt, this.proximity, this.days);

  final MedicalTimelineItem item;
  final DateTime appointmentAt;
  final AppointmentProximity proximity;
  final int days;

  @override
  bool get isImminent => switch (proximity) {
    AppointmentProximity.today || AppointmentProximity.tomorrow => true,
    AppointmentProximity.soon || AppointmentProximity.later => false,
  };

  @override
  AppColors get background =>
      isImminent ? AppColors.primaryContainer : AppColors.surface;

  @override
  AppColors get border => switch (proximity) {
    AppointmentProximity.today ||
    AppointmentProximity.tomorrow => AppColors.primaryContainer,
    AppointmentProximity.soon => AppColors.primary,
    AppointmentProximity.later => AppColors.border,
  };

  @override
  AppColors get accent => proximity == AppointmentProximity.later
      ? AppColors.textSecondary
      : AppColors.primary;
}

/// En-tête `overline` puis lignes selon l'état.
class _Body extends StatelessWidget {
  const _Body({required this.state});

  final _State state;

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    final styles = Theme.of(context).coletteTextStyles;
    final secondary = styles.small.copyWith(
      color: context.appColor(AppColors.textSecondary),
    );
    final header = switch (state) {
      _None() => s.dashboardAppointmentTitle,
      _Awaiting() => s.dashboardAppointmentAwaiting,
      _Upcoming(:final proximity, :final days) =>
        proximity == AppointmentProximity.soon
            ? s.dashboardAppointmentSoon(days)
            : s.dashboardAppointmentTitle,
    };
    final lines = switch (state) {
      _None() => [
        Text(
          s.healthNoAppointment,
          style: styles.body.copyWith(
            color: context.appColor(AppColors.textSecondary),
          ),
        ),
      ],
      _Awaiting(:final item, :final appointmentAt) => [
        Text(timelineItemTitle(s, item), style: styles.bodyMedium),
        Text(formatDayAndTime(appointmentAt), style: secondary),
      ],
      _Upcoming(:final item, :final appointmentAt, :final proximity) =>
        state.isImminent
            ? [
                Text(
                  appointmentDateText(s, appointmentAt, proximity),
                  style: styles.heading2.copyWith(
                    color: context.appColor(AppColors.primary),
                  ),
                ),
                Text(timelineItemTitle(s, item), style: styles.bodyMedium),
                if (item.practitioner case final name?)
                  Text(name, style: secondary),
              ]
            : [
                Text(timelineItemTitle(s, item), style: styles.bodyMedium),
                Text(
                  [formatDayAndTime(appointmentAt), ?item.practitioner]
                      .join(' · '),
                  style: secondary,
                ),
              ],
    };
    return Column(
      crossAxisAlignment: .start,
      spacing: AppSpacing.xxs.value,
      children: [
        Text(
          header,
          style: styles.overline.copyWith(
            color: context.appColor(state.accent),
          ),
        ),
        ...lines,
      ],
    );
  }
}
```

- [ ] **Step 4: Tests verts**

Run: `flutter test test/features/health/presentation/appointment_card_test.dart`
Expected: 6 tests verts.

- [ ] **Step 5: Commit**

```bash
dart format lib test && dart analyze
git add lib/features/health/presentation/widgets/appointment_card.dart test/features/health/presentation/appointment_card_test.dart
git commit -m "feat: tuile Rendez-vous à emphase graduée

Co-Authored-By: Claude Fable 5.1 <noreply@anthropic.com>"
```

---

### Task 12: Insertion dans Aujourd'hui

**Files:**
- Modify: `lib/features/dashboard/presentation/pages/dashboard_page.dart`
- Modify: `test/features/dashboard/presentation/dashboard_page_test.dart`

- [ ] **Step 1: Test qui échoue**

Dans `dashboard_page_test.dart`, ajouter l'import :

```dart
import 'package:colette/features/health/presentation/providers/health_providers.dart';
```

Ajouter dans la liste renvoyée par `overridesFor` (après `sleepRepositoryProvider.overrideWithValue(FakeSleepRepository()),`) :

```dart
    medicalTimelineProvider.overrideWithValue(null),
```

Puis ajouter le test, après « affiche la carte Sommeil sous le prochain biberon » :

```dart
  testWidgets('affiche la tuile Rendez-vous même sans frise médicale', (
    tester,
  ) async {
    final repo = MockEventsRepository();
    await pumpApp(tester, const DashboardPage(), overrides: overridesFor(repo));
    await tester.scrollUntilVisible(find.text('Rendez-vous'), 200);
    expect(find.text('Rendez-vous'), findsOneWidget);
    expect(find.text('Pas de rendez-vous programmé'), findsOneWidget);
  });
```

- [ ] **Step 2: Vérifier l'échec**

Run: `flutter test test/features/dashboard/presentation/dashboard_page_test.dart`
Expected: le nouveau test échoue (« Rendez-vous » introuvable).

- [ ] **Step 3: Insérer la tuile**

Dans `dashboard_page.dart`, ajouter l'import :

```dart
import 'package:colette/features/health/presentation/widgets/appointment_card.dart';
```

Et dans `children`, remplacer

```dart
            const SleepCard(),
            SectionHeader(title: s.todoTitle),
```

par

```dart
            const SleepCard(),
            const AppointmentCard(),
            SectionHeader(title: s.todoTitle),
```

Mettre à jour le commentaire de classe : `/// Onglet Aujourd'hui : âge, prochain biberon, sommeil, rendez-vous, reste à faire, compteurs, poids, documents.`

- [ ] **Step 4: Tests verts**

Run: `flutter test test/features/dashboard/`
Expected: verts. Si un autre test du dashboard échoue sur « Reste à faire » désormais plus bas, utiliser `scrollUntilVisible` comme les tests voisins.

- [ ] **Step 5: Commit**

```bash
dart format lib test && dart analyze
git add lib/features/dashboard/presentation/pages/dashboard_page.dart test/features/dashboard/presentation/dashboard_page_test.dart
git commit -m "feat: tuile Rendez-vous sur Aujourd'hui

Co-Authored-By: Claude Fable 5.1 <noreply@anthropic.com>"
```

---

### Task 13: Nettoyage, vérification complète, simulateur

**Files:**
- Modify: `lib/l10n/app_fr.arb`
- Modify: `README.md` (ligne « Santé (onglet dédié) »)

- [ ] **Step 1: Retirer les clés obsolètes**

Vérifier qu'elles ne sont plus référencées :

Run: `grep -rnwE 'healthSectionToDo|healthSectionUpcoming|healthNextFar|healthAllDone' lib test`
Expected: seules des lignes de `lib/l10n/app_fr.arb` et de `lib/l10n/generated/`.

Supprimer de `app_fr.arb` les lignes :

```
  "healthNextFar": "Prochaine étape : {stage}, à partir du {date}",
  "@healthNextFar": { "placeholders": { "stage": { "type": "String" }, "date": { "type": "String" } } },
  "healthAllDone": "Toutes les étapes du suivi sont faites.",
  "healthSectionToDo": "À faire",
  "healthSectionUpcoming": "À venir",
```

Run: `flutter gen-l10n && dart analyze`
Expected: aucune erreur.

- [ ] **Step 2: README**

Remplacer la ligne 9 par :

```
- Santé (onglet dédié) : prochain rendez-vous en évidence, autres RDV programmés, RDV passés à confirmer, examens à programmer ; examens obligatoires et vaccins, RDV libres (ostéopathe, ORL, vaccin de saison…) avec vaccins connus ou à nom libre, RDV synchronisés avec un calendrier iCloud partagé, rappels des étapes dans le digest du matin. Une tuile Rendez-vous sur Aujourd'hui suit le prochain RDV.
```

- [ ] **Step 3: Vérification complète**

Run: `dart format lib test && dart analyze && flutter test`
Expected: `No issues found!` et tous les tests verts. Corriger tout échec avant de continuer.

- [ ] **Step 4: Vérification sur simulateur**

Lancer l'app sur un simulateur iPhone (`flutter run -d <simulateur>` ou l'outil simulateur de la session) avec un foyer de test, et contrôler en thème clair **et** sombre :

- l'onglet Santé avec au moins un RDV programmé, un RDV passé non confirmé et une étape en retard ;
- l'onglet Santé sans aucun RDV ;
- la tuile Rendez-vous sur Aujourd'hui dans les états « aucun », « éloigné », « bientôt » et « aujourd'hui » (changer la date du RDV via la feuille d'étape).

Ne pas créer de foyer sur la production Firestore : utiliser le foyer de test existant du simulateur.

- [ ] **Step 5: Commit**

```bash
git add lib/l10n/app_fr.arb README.md
git commit -m "chore: retrait des textes Santé obsolètes, README

Co-Authored-By: Claude Fable 5.1 <noreply@anthropic.com>"
```

- [ ] **Step 6: Remise à Maxence**

Ne pas merger ni pousser. Présenter le résumé des commits de `feat/health-review` et demander la validation du merge `--no-ff` vers `main` (message « merge: revue de l'onglet Santé et tuile Rendez-vous (feat/health-review) »).
