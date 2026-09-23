# Suivi du sommeil — plan d'implémentation

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** suivre le sommeil du bébé (chrono partagé, saisie après coup, sieste ou nuit), l'afficher sur l'accueil, dans le Journal et sur une page 7 jours, avec le repère OMS 2019.

**Architecture:** nouvelle feature `lib/features/sleep/` (domain pur, data Firestore `households/{code}/sleeps/{id}`, presentation Riverpod codegen). Le Journal (`events/presentation`) consomme les providers publics de `sleep` via une union `TimelineEntry`. Horaires de nuit dans `CareSettings`. Aucune Cloud Function touchée.

**Tech Stack:** Flutter iOS, Riverpod 3 codegen, freezed, fpdart, cloud_firestore, fake_cloud_firestore, mocktail, intl.

**Spec :** `docs/superpowers/specs/2026-09-23-sleep-tracking-design.md`.

**Règles transverses (CLAUDE.md) :** tokens `AppSpacing` / `AppSize` / `AppRadius` / `context.appColor(AppColors.x)` / `Theme.of(context).coletteTextStyles.x`, chaînes via `S.of(context)`, `///` d'une ligne sur chaque classe publique, `switch` sur `AsyncValue` (jamais `.when`), `ref.watch` dans `build`, contrôleur auto-dispose `ref.watch`é dans le `build` qui l'appelle. Après toute modification d'un fichier annoté : `dart run build_runner build -d`. Après toute modification de `app_fr.arb` : `flutter gen-l10n`. Commits en français, `git add` de chemins explicites uniquement, pied `Co-Authored-By: Claude Opus 5.5 <noreply@anthropic.com>`.

Toutes les commandes se lancent depuis la racine du worktree `/Users/maxencemontet/Documents/colette/.claude/worktrees/sleep-tracking`.

---

## Carte des fichiers

| Fichier | Rôle |
| --- | --- |
| `lib/core/dates/date_extensions.dart` | + `completedMonthsBetween` (mois révolus), réutilisé par `ComputeBabyAge` et `SleepAgeBand`. |
| `lib/core/dates/time_format.dart` | + `formatShortWeekday` (« mer. 23 »). |
| `lib/core/result/failure.dart` | + raisons `sleepInFuture`, `sleepTooLong`, `sleepBeforeBirth` ; + `SleepOverlapFailure`. |
| `lib/core/ui/failure_message.dart` | Textes des nouvelles erreurs. |
| `lib/core/firebase/firestore_paths.dart` | + `sleeps`. |
| `lib/core/theme/app_colors.dart` | + `sleepNight`, `sleepNap`. |
| `lib/l10n/app_fr.arb` | Toutes les chaînes du sommeil. |
| `lib/features/sleep/domain/entities/sleep_kind.dart` | enum `SleepKind`. |
| `lib/features/sleep/domain/entities/sleep_session.dart` | entité freezed `SleepSession`. |
| `lib/features/sleep/domain/entities/sleep_age_band.dart` | repères OMS par âge. |
| `lib/features/sleep/domain/entities/sleep_status.dart` | union freezed `SleepStatus` + `SleepSummary`. |
| `lib/features/sleep/domain/entities/sleep_day.dart` | freezed `SleepSegment`, `SleepDay`. |
| `lib/features/sleep/domain/use_cases/classify_sleep_kind.dart` | sieste ou nuit selon l'heure. |
| `lib/features/sleep/domain/use_cases/validate_sleep_session.dart` | validation avant écriture. |
| `lib/features/sleep/domain/use_cases/compute_sleep_summary.dart` | état courant + total 24 h, `mergeSleeps`. |
| `lib/features/sleep/domain/use_cases/compute_sleep_days.dart` | 7 jours de la page + moyenne. |
| `lib/features/sleep/domain/use_cases/plan_wake_up.dart` | sommeil à fermer, doublons à supprimer. |
| `lib/features/sleep/domain/repositories/sleep_repository.dart` | interface. |
| `lib/features/sleep/data/dtos/sleep_session_dto.dart` | mapper Firestore. |
| `lib/features/sleep/data/repositories/firestore_sleep_repository.dart` | implémentation. |
| `lib/features/sleep/presentation/providers/sleep_providers.dart` | providers publics. |
| `lib/features/sleep/presentation/providers/sleep_controller.dart` | actions. |
| `lib/features/sleep/presentation/sleep_ui.dart` | libellé / couleur d'un `SleepKind`, format des durées. |
| `lib/features/sleep/presentation/widgets/sleep_form_sheet.dart` | formulaire. |
| `lib/features/sleep/presentation/widgets/sleep_card.dart` | carte d'accueil. |
| `lib/features/sleep/presentation/widgets/sleep_tile.dart` | ligne du Journal. |
| `lib/features/sleep/presentation/widgets/sleep_week_chart.dart` | frise 7 jours. |
| `lib/features/sleep/presentation/widgets/sleep_day_details.dart` | détail du jour sélectionné. |
| `lib/features/sleep/presentation/widgets/sleep_settings_section.dart` | horaires de nuit. |
| `lib/features/sleep/presentation/pages/sleep_page.dart` | page `/today/sleep`. |
| `lib/features/baby/domain/entities/care_settings.dart`, `lib/features/baby/data/dtos/baby_profile_dto.dart` | horaires de nuit. |
| `lib/features/events/presentation/timeline_entry.dart` | union `TimelineEntry`. |
| `lib/features/events/presentation/timeline_grouping.dart` | `groupEntriesByDay`. |
| `lib/features/events/presentation/pages/timeline_page.dart` | Journal mixte. |
| `lib/features/dashboard/presentation/pages/dashboard_page.dart` | `SleepCard`. |
| `lib/features/baby/presentation/pages/settings_page.dart` | section Sommeil. |
| `lib/app/router/app_router.dart` | route `sleep`. |
| `test/helpers/sleep_session_factory.dart`, `test/helpers/fake_sleep_repository.dart` | aides de test. |

---

### Task 0: Préparer le worktree

- [ ] **Step 1: Dépendances et génération**

```bash
flutter pub get
flutter gen-l10n
dart run build_runner build -d
```

Expected : aucune erreur (le dossier `lib/l10n/generated` n'est pas versionné).

- [ ] **Step 2: Ligne de base**

```bash
dart analyze
flutter test
```

Expected : `No issues found!` et tous les tests verts. Noter le nombre de tests.

---

### Task 1: Chaînes l10n, couleurs, chemin Firestore

**Files:**
- Modify: `lib/l10n/app_fr.arb`
- Modify: `lib/core/theme/app_colors.dart`
- Modify: `lib/core/firebase/firestore_paths.dart`

- [ ] **Step 1: Ajouter les chaînes** à la fin de `lib/l10n/app_fr.arb` (avant l'accolade finale, virgule sur la ligne précédente) :

```json
  "sleepCardTitle": "Sommeil",
  "sleepAddPast": "Ajouter un sommeil passé",
  "sleepAsleepFor": "Dort depuis {duration}",
  "@sleepAsleepFor": { "placeholders": { "duration": { "type": "String" } } },
  "sleepAsleepSince": "{kind} · depuis {time}",
  "@sleepAsleepSince": { "placeholders": { "kind": { "type": "String" }, "time": { "type": "String" } } },
  "sleepAwakeFor": "Éveillé·e depuis {duration}",
  "@sleepAwakeFor": { "placeholders": { "duration": { "type": "String" } } },
  "sleepNoneYet": "Aucun sommeil noté",
  "sleepFallAsleepAction": "Endormi·e",
  "sleepWakeUpAction": "Réveillé·e",
  "sleepForgottenWake": "Réveil oublié ?",
  "sleepEnterWakeAction": "Saisir le réveil",
  "sleepLast24h": "Sur 24 h : {duration}",
  "@sleepLast24h": { "placeholders": { "duration": { "type": "String" } } },
  "sleepLast24hWithReference": "Sur 24 h : {duration} · repère OMS {min} à {max} h",
  "@sleepLast24hWithReference": { "placeholders": { "duration": { "type": "String" }, "min": { "type": "int" }, "max": { "type": "int" } } },
  "sleepReference": "Repère OMS à son âge : {min} à {max} h sur 24 h",
  "@sleepReference": { "placeholders": { "min": { "type": "int" }, "max": { "type": "int" } } },
  "sleepAverage": "Moyenne des jours précédents : {duration}",
  "@sleepAverage": { "placeholders": { "duration": { "type": "String" } } },
  "sleepKindNap": "Sieste",
  "sleepKindNight": "Nuit",
  "sleepFormNewTitle": "Nouveau sommeil",
  "sleepFormEditTitle": "Modifier le sommeil",
  "sleepOngoing": "En cours",
  "sleepOngoingFor": "en cours · {duration}",
  "@sleepOngoingFor": { "placeholders": { "duration": { "type": "String" } } },
  "sleepPageTitle": "Sommeil",
  "sleepDayTotal": "Total",
  "sleepDayNaps": "Siestes",
  "sleepDayLongest": "Plus longue période",
  "deleteSleepTitle": "Supprimer ce sommeil ?",
  "settingsSleepSection": "Sommeil",
  "settingsNightStart": "Début de la nuit",
  "settingsNightEnd": "Fin de la nuit",
  "hourSuffix": "h",
  "durationMinutes": "{minutes} min",
  "@durationMinutes": { "placeholders": { "minutes": { "type": "int" } } },
  "durationHours": "{hours} h",
  "@durationHours": { "placeholders": { "hours": { "type": "int" } } },
  "durationHoursMinutes": "{hours} h {minutes}",
  "@durationHoursMinutes": { "placeholders": { "hours": { "type": "int" }, "minutes": { "type": "String" } } },
  "errorSleepOverlap": "Chevauche le sommeil de {start} à {end}.",
  "@errorSleepOverlap": { "placeholders": { "start": { "type": "String" }, "end": { "type": "String" } } },
  "errorSleepOverlapOngoing": "Chevauche le sommeil en cours depuis {start}.",
  "@errorSleepOverlapOngoing": { "placeholders": { "start": { "type": "String" } } },
  "errorSleepInFuture": "Le début et la fin ne peuvent pas être dans le futur.",
  "errorSleepTooLong": "Un sommeil ne peut pas dépasser 24 h.",
  "errorSleepBeforeBirth": "Ce sommeil commence avant la naissance."
```

- [ ] **Step 2: Couleurs.** Dans `lib/core/theme/app_colors.dart`, après `growthReference(...)`, ajouter :

```dart
  /// Prune : nuits sur la frise du sommeil, icône lune.
  sleepNight(light: Color(0xFF6B5B7B), dark: Color(0xFFB7A6C9)),

  /// Lilas pâle : siestes sur la frise du sommeil (fond uniquement, jamais en texte).
  sleepNap(light: Color(0xFFD6C8E0), dark: Color(0xFF5E4F70)),
```

- [ ] **Step 3: Chemin.** Dans `lib/core/firebase/firestore_paths.dart`, ajouter `static const sleeps = 'sleeps';` après `devices`.

- [ ] **Step 4: Générer et vérifier**

```bash
flutter gen-l10n
dart analyze
flutter test test/core/theme
```

Expected : aucune erreur ; les tests de thème passent (s'ils énumèrent toutes les couleurs, ils couvrent les deux nouvelles automatiquement).

- [ ] **Step 5: Commit**

```bash
git add lib/l10n/app_fr.arb lib/core/theme/app_colors.dart lib/core/firebase/firestore_paths.dart
git commit -m "feat: chaînes, couleurs et chemin Firestore du sommeil"
```

---

### Task 2: `completedMonthsBetween` et `formatShortWeekday`

**Files:**
- Modify: `lib/core/dates/date_extensions.dart`
- Modify: `lib/core/dates/time_format.dart`
- Modify: `lib/features/dashboard/domain/use_cases/compute_baby_age.dart`
- Test: `test/core/dates/date_extensions_test.dart`, `test/core/dates/time_format_test.dart`

- [ ] **Step 1: Tests rouges.** Ajouter dans `test/core/dates/date_extensions_test.dart` (dans `main`) :

```dart
  group('completedMonthsBetween', () {
    test('compte les mois révolus', () {
      expect(completedMonthsBetween(DateTime(2026, 1, 15), DateTime(2026, 5, 14)), 3);
      expect(completedMonthsBetween(DateTime(2026, 1, 15), DateTime(2026, 5, 15)), 4);
    });

    test('0 avant la naissance ou le jour même', () {
      expect(completedMonthsBetween(DateTime(2026, 1, 15), DateTime(2026, 1, 15)), 0);
      expect(completedMonthsBetween(DateTime(2026, 1, 15), DateTime(2026, 1, 1)), 0);
    });
  });
```

Et dans `test/core/dates/time_format_test.dart` :

```dart
  test('formatShortWeekday donne le jour abrégé et son numéro', () {
    expect(formatShortWeekday(DateTime(2026, 9, 23)), 'mer. 23');
  });
```

- [ ] **Step 2: Vérifier l'échec**

Run: `flutter test test/core/dates`
Expected: FAIL (`completedMonthsBetween` et `formatShortWeekday` non définis).

- [ ] **Step 3: Implémenter.** Dans `lib/core/dates/date_extensions.dart`, ajouter à la fin :

```dart
/// Mois civils révolus entre [from] et [to] ; `0` si [to] précède [from].
int completedMonthsBetween(DateTime from, DateTime to) {
  final months = (to.year - from.year) * 12 + to.month - from.month;
  final completed = to.day < from.day ? months - 1 : months;
  return completed < 0 ? 0 : completed;
}
```

Dans `lib/core/dates/time_format.dart` :

```dart
/// « mer. 23 ».
String formatShortWeekday(DateTime day) =>
    DateFormat('EEE d', 'fr').format(day);
```

Dans `compute_baby_age.dart`, supprimer `_monthsBetween` et remplacer son appel par `completedMonthsBetween(birthDate, now)` (import déjà présent de `date_extensions.dart`).

- [ ] **Step 4: Vérifier**

Run: `flutter test test/core/dates test/features/dashboard/domain/compute_baby_age_test.dart`
Expected: PASS.

- [ ] **Step 5: Commit**

```bash
git add lib/core/dates/date_extensions.dart lib/core/dates/time_format.dart lib/features/dashboard/domain/use_cases/compute_baby_age.dart test/core/dates/date_extensions_test.dart test/core/dates/time_format_test.dart
git commit -m "feat: mois révolus et jour abrégé partagés dans core/dates"
```

---

### Task 3: `SleepKind`, `SleepSession`, `classifySleepKind`

**Files:**
- Create: `lib/features/sleep/domain/entities/sleep_kind.dart`
- Create: `lib/features/sleep/domain/entities/sleep_session.dart`
- Create: `lib/features/sleep/domain/use_cases/classify_sleep_kind.dart`
- Create: `test/helpers/sleep_session_factory.dart`
- Test: `test/features/sleep/domain/classify_sleep_kind_test.dart`, `test/features/sleep/domain/sleep_session_test.dart`

- [ ] **Step 1: Entités**

`lib/features/sleep/domain/entities/sleep_kind.dart` :

```dart
/// Sieste ou nuit.
enum SleepKind { nap, night }
```

`lib/features/sleep/domain/entities/sleep_session.dart` :

```dart
import 'package:colette/features/sleep/domain/entities/sleep_kind.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

part 'sleep_session.freezed.dart';

/// Une période de sommeil ; `endAt` vaut `null` tant qu'elle est en cours.
@freezed
abstract class SleepSession with _$SleepSession {
  const SleepSession._();

  const factory SleepSession({
    required String id,
    required DateTime startAt,
    DateTime? endAt,
    required SleepKind kind,
    required String createdByDeviceId,
    required DateTime createdAt,
    required DateTime updatedAt,
  }) = _SleepSession;

  bool get isOngoing => endAt == null;

  /// Fin effective : `endAt`, ou [now] si le sommeil est en cours.
  DateTime endOr(DateTime now) => endAt ?? now;

  /// Durée complète, arrêtée à [now] si le sommeil est en cours.
  Duration durationUntil(DateTime now) => endOr(now).difference(startAt);
}
```

`test/helpers/sleep_session_factory.dart` :

```dart
import 'package:colette/features/sleep/domain/entities/sleep_kind.dart';
import 'package:colette/features/sleep/domain/entities/sleep_session.dart';

/// Construit un `SleepSession` de test avec des valeurs par défaut.
SleepSession makeSleep({
  String id = 's1',
  required DateTime startAt,
  DateTime? endAt,
  SleepKind kind = SleepKind.nap,
  String createdByDeviceId = 'device-test',
}) => SleepSession(
  id: id,
  startAt: startAt,
  endAt: endAt,
  kind: kind,
  createdByDeviceId: createdByDeviceId,
  createdAt: startAt,
  updatedAt: endAt ?? startAt,
);
```

- [ ] **Step 2: Tests rouges**

`test/features/sleep/domain/sleep_session_test.dart` :

```dart
import 'package:flutter_test/flutter_test.dart';

import '../../../helpers/sleep_session_factory.dart';

void main() {
  final start = DateTime(2026, 9, 23, 14);

  test('un sommeil sans fin est en cours et dure jusqu\'à maintenant', () {
    final sleep = makeSleep(startAt: start);
    expect(sleep.isOngoing, isTrue);
    expect(
      sleep.durationUntil(DateTime(2026, 9, 23, 14, 42)),
      const Duration(minutes: 42),
    );
  });

  test('un sommeil terminé garde sa durée', () {
    final sleep = makeSleep(startAt: start, endAt: DateTime(2026, 9, 23, 15, 30));
    expect(sleep.isOngoing, isFalse);
    expect(
      sleep.durationUntil(DateTime(2026, 9, 23, 20)),
      const Duration(minutes: 90),
    );
  });
}
```

`test/features/sleep/domain/classify_sleep_kind_test.dart` :

```dart
import 'package:colette/features/sleep/domain/entities/sleep_kind.dart';
import 'package:colette/features/sleep/domain/use_cases/classify_sleep_kind.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  SleepKind at(int hour, int minute, {int start = 20, int end = 7}) =>
      classifySleepKind(
        DateTime(2026, 9, 23, hour, minute),
        nightStartHour: start,
        nightEndHour: end,
      );

  test('fenêtre qui passe minuit (20 → 7)', () {
    expect(at(19, 59), SleepKind.nap);
    expect(at(20, 0), SleepKind.night);
    expect(at(2, 30), SleepKind.night);
    expect(at(6, 59), SleepKind.night);
    expect(at(7, 0), SleepKind.nap);
    expect(at(14, 0), SleepKind.nap);
  });

  test('fenêtre dans la même journée (1 → 9)', () {
    expect(at(0, 59, start: 1, end: 9), SleepKind.nap);
    expect(at(1, 0, start: 1, end: 9), SleepKind.night);
    expect(at(8, 59, start: 1, end: 9), SleepKind.night);
    expect(at(9, 0, start: 1, end: 9), SleepKind.nap);
  });

  test('début égal à la fin : toujours sieste', () {
    expect(at(20, 0, start: 20, end: 20), SleepKind.nap);
    expect(at(3, 0, start: 20, end: 20), SleepKind.nap);
  });
}
```

- [ ] **Step 3: Vérifier l'échec**

Run: `dart run build_runner build -d && flutter test test/features/sleep/domain`
Expected: FAIL sur `classifySleepKind` non défini (le test d'entité passe après génération).

- [ ] **Step 4: Implémenter** `lib/features/sleep/domain/use_cases/classify_sleep_kind.dart` :

```dart
import 'package:colette/features/sleep/domain/entities/sleep_kind.dart';

/// Nuit si l'heure de [startAt] tombe dans `[nightStartHour, nightEndHour[`
/// (fenêtre qui peut passer minuit), sinon sieste. Bornes égales : sieste.
SleepKind classifySleepKind(
  DateTime startAt, {
  required int nightStartHour,
  required int nightEndHour,
}) {
  if (nightStartHour == nightEndHour) return SleepKind.nap;
  final hour = startAt.hour;
  final isNight = nightStartHour < nightEndHour
      ? hour >= nightStartHour && hour < nightEndHour
      : hour >= nightStartHour || hour < nightEndHour;
  return isNight ? SleepKind.night : SleepKind.nap;
}
```

- [ ] **Step 5: Vérifier**

Run: `flutter test test/features/sleep/domain`
Expected: PASS.

- [ ] **Step 6: Commit**

```bash
git add lib/features/sleep/domain/entities/sleep_kind.dart lib/features/sleep/domain/entities/sleep_session.dart lib/features/sleep/domain/entities/sleep_session.freezed.dart lib/features/sleep/domain/use_cases/classify_sleep_kind.dart test/helpers/sleep_session_factory.dart test/features/sleep/domain/sleep_session_test.dart test/features/sleep/domain/classify_sleep_kind_test.dart
git commit -m "feat: entité SleepSession et classement sieste ou nuit"
```

(Si `*.freezed.dart` est ignoré par git, retirer ce chemin de la commande : vérifier avec `git check-ignore lib/features/sleep/domain/entities/sleep_session.freezed.dart`.)

---

### Task 4: `SleepAgeBand` (repères OMS)

**Files:**
- Create: `lib/features/sleep/domain/entities/sleep_age_band.dart`
- Test: `test/features/sleep/domain/sleep_age_band_test.dart`

- [ ] **Step 1: Test rouge**

```dart
import 'package:colette/features/sleep/domain/entities/sleep_age_band.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  final birth = DateTime(2026, 1, 15);
  SleepAgeBand? at(DateTime now) => SleepAgeBand.forAge(birthDate: birth, now: now);

  test('moins de 4 mois : 14 à 17 h', () {
    expect(at(DateTime(2026, 1, 15)), SleepAgeBand.under4Months);
    expect(at(DateTime(2026, 5, 14)), SleepAgeBand.under4Months);
    expect(SleepAgeBand.under4Months.minHours, 14);
    expect(SleepAgeBand.under4Months.maxHours, 17);
  });

  test('4 à 11 mois : 12 à 16 h', () {
    expect(at(DateTime(2026, 5, 15)), SleepAgeBand.months4To11);
    expect(at(DateTime(2027, 1, 14)), SleepAgeBand.months4To11);
    expect(SleepAgeBand.months4To11.minHours, 12);
    expect(SleepAgeBand.months4To11.maxHours, 16);
  });

  test('12 à 23 mois : 11 à 14 h', () {
    expect(at(DateTime(2027, 1, 15)), SleepAgeBand.months12To23);
    expect(at(DateTime(2028, 1, 14)), SleepAgeBand.months12To23);
    expect(SleepAgeBand.months12To23.minHours, 11);
    expect(SleepAgeBand.months12To23.maxHours, 14);
  });

  test('24 mois et plus : aucun repère', () {
    expect(at(DateTime(2028, 1, 15)), isNull);
  });
}
```

- [ ] **Step 2: Vérifier l'échec**

Run: `flutter test test/features/sleep/domain/sleep_age_band_test.dart`
Expected: FAIL (fichier absent).

- [ ] **Step 3: Implémenter**

```dart
import 'package:colette/core/dates/date_extensions.dart';

/// Durée de sommeil recommandée sur 24 h, siestes comprises (OMS 2019).
enum SleepAgeBand {
  under4Months(minHours: 14, maxHours: 17),
  months4To11(minHours: 12, maxHours: 16),
  months12To23(minHours: 11, maxHours: 14);

  const SleepAgeBand({required this.minHours, required this.maxHours});

  final int minHours;
  final int maxHours;

  /// Tranche selon l'âge en mois révolus ; `null` à partir de 24 mois.
  static SleepAgeBand? forAge({
    required DateTime birthDate,
    required DateTime now,
  }) {
    final months = completedMonthsBetween(birthDate, now);
    if (months < 4) return under4Months;
    if (months < 12) return months4To11;
    if (months < 24) return months12To23;
    return null;
  }
}
```

- [ ] **Step 4: Vérifier** — Run: `flutter test test/features/sleep/domain/sleep_age_band_test.dart` → PASS.

- [ ] **Step 5: Commit**

```bash
git add lib/features/sleep/domain/entities/sleep_age_band.dart test/features/sleep/domain/sleep_age_band_test.dart
git commit -m "feat: repères OMS 2019 de sommeil par âge"
```

---

### Task 5: Erreurs du sommeil et `ValidateSleepSession`

**Files:**
- Modify: `lib/core/result/failure.dart`
- Modify: `lib/core/ui/failure_message.dart`
- Create: `lib/features/sleep/domain/use_cases/validate_sleep_session.dart`
- Test: `test/features/sleep/domain/validate_sleep_session_test.dart`, `test/core/ui/failure_message_test.dart`

- [ ] **Step 1: Types d'erreur.** Dans `lib/core/result/failure.dart`, ajouter à `ValidationReason` (après `invalidDiaperCount`) : `sleepInFuture, sleepTooLong, sleepBeforeBirth,`. Ajouter à la fin du fichier (même bibliothèque, `Failure` est `sealed`) :

```dart
/// Sommeil qui chevauche un autre sommeil déjà enregistré.
final class SleepOverlapFailure extends Failure {
  const SleepOverlapFailure({required this.startAt, this.endAt});

  /// Début du sommeil en conflit.
  final DateTime startAt;

  /// Fin du sommeil en conflit ; `null` s'il est en cours.
  final DateTime? endAt;

  @override
  bool operator ==(Object other) =>
      other is SleepOverlapFailure &&
      other.startAt == startAt &&
      other.endAt == endAt;

  @override
  int get hashCode => Object.hash(startAt, endAt);
}
```

- [ ] **Step 2: Test rouge de validation** `test/features/sleep/domain/validate_sleep_session_test.dart` :

```dart
import 'package:colette/core/result/failure.dart';
import 'package:colette/features/sleep/domain/entities/sleep_session.dart';
import 'package:colette/features/sleep/domain/use_cases/validate_sleep_session.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../helpers/sleep_session_factory.dart';

void main() {
  const validate = ValidateSleepSession();
  final now = DateTime(2026, 9, 23, 16);
  final birth = DateTime(2026, 9, 1);

  Object? failureOf(
    SleepSession sleep, {
    List<SleepSession> others = const [],
  }) => validate(
    sleep,
    now: now,
    birthDate: birth,
    others: others,
  ).getLeft().toNullable();

  test('accepte un sommeil terminé valide', () {
    final sleep = makeSleep(startAt: DateTime(2026, 9, 23, 13), endAt: DateTime(2026, 9, 23, 14));
    expect(validate(sleep, now: now, birthDate: birth, others: const []).isRight(), isTrue);
  });

  test('refuse une fin avant ou égale au début', () {
    final at = DateTime(2026, 9, 23, 13);
    expect(failureOf(makeSleep(startAt: at, endAt: at)),
        isA<ValidationFailure>().having((f) => f.reason, 'reason', ValidationReason.endBeforeStart));
  });

  test('refuse un début ou une fin dans le futur, tolère 1 min', () {
    expect(failureOf(makeSleep(startAt: DateTime(2026, 9, 23, 15), endAt: now.add(const Duration(minutes: 1)))), isNull);
    expect(failureOf(makeSleep(startAt: DateTime(2026, 9, 23, 15), endAt: now.add(const Duration(minutes: 2)))),
        isA<ValidationFailure>().having((f) => f.reason, 'reason', ValidationReason.sleepInFuture));
    expect(failureOf(makeSleep(startAt: now.add(const Duration(minutes: 5)))),
        isA<ValidationFailure>().having((f) => f.reason, 'reason', ValidationReason.sleepInFuture));
  });

  test('refuse plus de 24 h, y compris un sommeil en cours', () {
    expect(failureOf(makeSleep(startAt: DateTime(2026, 9, 22, 15), endAt: DateTime(2026, 9, 23, 15, 1))),
        isA<ValidationFailure>().having((f) => f.reason, 'reason', ValidationReason.sleepTooLong));
    expect(failureOf(makeSleep(startAt: DateTime(2026, 9, 22, 15))),
        isA<ValidationFailure>().having((f) => f.reason, 'reason', ValidationReason.sleepTooLong));
  });

  test('refuse un début avant la naissance', () {
    expect(failureOf(makeSleep(startAt: DateTime(2026, 8, 31, 23), endAt: DateTime(2026, 9, 1, 1))),
        isA<ValidationFailure>().having((f) => f.reason, 'reason', ValidationReason.sleepBeforeBirth));
  });

  test('refuse un chevauchement et porte les heures du conflit', () {
    final other = makeSleep(id: 'o', startAt: DateTime(2026, 9, 23, 14, 10), endAt: DateTime(2026, 9, 23, 15, 30));
    final sleep = makeSleep(startAt: DateTime(2026, 9, 23, 15), endAt: DateTime(2026, 9, 23, 15, 45));
    expect(failureOf(sleep, others: [other]),
        SleepOverlapFailure(startAt: other.startAt, endAt: other.endAt));
  });

  test('accepte deux sommeils bord à bord et ignore le sommeil lui-même', () {
    final other = makeSleep(id: 'o', startAt: DateTime(2026, 9, 23, 13), endAt: DateTime(2026, 9, 23, 14));
    final sleep = makeSleep(id: 's', startAt: DateTime(2026, 9, 23, 14), endAt: DateTime(2026, 9, 23, 15));
    expect(failureOf(sleep, others: [other, sleep]), isNull);
  });

  test('un sommeil en cours chevauche tout sommeil qui commence après lui', () {
    final ongoing = makeSleep(id: 'o', startAt: DateTime(2026, 9, 23, 12));
    final sleep = makeSleep(startAt: DateTime(2026, 9, 23, 14), endAt: DateTime(2026, 9, 23, 15));
    expect(failureOf(sleep, others: [ongoing]), SleepOverlapFailure(startAt: ongoing.startAt));
  });
}
```

- [ ] **Step 3: Vérifier l'échec** — Run: `flutter test test/features/sleep/domain/validate_sleep_session_test.dart` → FAIL (use case absent).

- [ ] **Step 4: Implémenter** `lib/features/sleep/domain/use_cases/validate_sleep_session.dart` :

```dart
import 'package:colette/core/dates/date_extensions.dart';
import 'package:colette/core/result/failure.dart';
import 'package:colette/features/sleep/domain/entities/sleep_session.dart';
import 'package:fpdart/fpdart.dart';

/// Règles de validité d'un sommeil avant enregistrement.
class ValidateSleepSession {
  const ValidateSleepSession();

  static const futureTolerance = Duration(minutes: 1);
  static const maxDuration = Duration(hours: 24);

  /// Fin utilisée pour un sommeil en cours dans le test de chevauchement.
  static final _openEnd = DateTime(9999);

  Either<Failure, SleepSession> call(
    SleepSession session, {
    required DateTime now,
    required DateTime birthDate,
    required List<SleepSession> others,
  }) {
    final end = session.endAt;
    if (end != null && !end.isAfter(session.startAt)) {
      return left(const ValidationFailure(ValidationReason.endBeforeStart));
    }
    final limit = now.add(futureTolerance);
    if (session.startAt.isAfter(limit) || (end != null && end.isAfter(limit))) {
      return left(const ValidationFailure(ValidationReason.sleepInFuture));
    }
    if (session.durationUntil(now) > maxDuration) {
      return left(const ValidationFailure(ValidationReason.sleepTooLong));
    }
    if (session.startAt.isBefore(birthDate.dateOnly)) {
      return left(const ValidationFailure(ValidationReason.sleepBeforeBirth));
    }
    final sessionEnd = end ?? _openEnd;
    for (final other in others) {
      if (other.id == session.id) continue;
      final otherEnd = other.endAt ?? _openEnd;
      if (session.startAt.isBefore(otherEnd) &&
          other.startAt.isBefore(sessionEnd)) {
        return left(
          SleepOverlapFailure(startAt: other.startAt, endAt: other.endAt),
        );
      }
    }
    return right(session);
  }
}
```

- [ ] **Step 5: Messages.** Dans `lib/core/ui/failure_message.dart`, importer `package:colette/core/dates/time_format.dart`, ajouter au `switch (reason)` :

```dart
    ValidationReason.sleepInFuture => s.errorSleepInFuture,
    ValidationReason.sleepTooLong => s.errorSleepTooLong,
    ValidationReason.sleepBeforeBirth => s.errorSleepBeforeBirth,
```

et avant `DocumentsFailure(...)` :

```dart
  SleepOverlapFailure(:final startAt, :final endAt) => switch (endAt) {
    null => s.errorSleepOverlapOngoing(formatHourMinute(startAt)),
    final end => s.errorSleepOverlap(
      formatHourMinute(startAt),
      formatHourMinute(end),
    ),
  },
```

Ajouter dans `test/core/ui/failure_message_test.dart` (en suivant la façon dont le fichier obtient `S`, par exemple `lookupS(const Locale('fr'))` ou un `testWidgets` existant) :

```dart
  test('chevauchement de sommeil', () {
    final s = lookupS(const Locale('fr'));
    expect(
      failureMessage(SleepOverlapFailure(startAt: DateTime(2026, 9, 23, 14, 10), endAt: DateTime(2026, 9, 23, 15, 30)), s),
      'Chevauche le sommeil de 14h10 à 15h30.',
    );
    expect(
      failureMessage(SleepOverlapFailure(startAt: DateTime(2026, 9, 23, 14, 10)), s),
      'Chevauche le sommeil en cours depuis 14h10.',
    );
    expect(failureMessage(const ValidationFailure(ValidationReason.sleepTooLong), s), 'Un sommeil ne peut pas dépasser 24 h.');
  });
```

- [ ] **Step 6: Vérifier** — Run: `flutter test test/features/sleep/domain test/core/ui` → PASS.

- [ ] **Step 7: Commit**

```bash
git add lib/core/result/failure.dart lib/core/ui/failure_message.dart lib/features/sleep/domain/use_cases/validate_sleep_session.dart test/features/sleep/domain/validate_sleep_session_test.dart test/core/ui/failure_message_test.dart
git commit -m "feat: validation d'un sommeil (futur, 24 h, naissance, chevauchement)"
```

---

### Task 6: `SleepStatus`, `SleepSummary`, `computeSleepSummary`, `planWakeUp`

**Files:**
- Create: `lib/features/sleep/domain/entities/sleep_status.dart`
- Create: `lib/features/sleep/domain/use_cases/compute_sleep_summary.dart`
- Create: `lib/features/sleep/domain/use_cases/plan_wake_up.dart`
- Test: `test/features/sleep/domain/compute_sleep_summary_test.dart`, `test/features/sleep/domain/plan_wake_up_test.dart`

- [ ] **Step 1: Entités**

```dart
import 'package:colette/features/sleep/domain/entities/sleep_session.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

part 'sleep_status.freezed.dart';

/// État de sommeil actuel du bébé.
@freezed
sealed class SleepStatus with _$SleepStatus {
  /// Endormi·e depuis `session.startAt`.
  const factory SleepStatus.asleep(SleepSession session) = Asleep;

  /// Éveillé·e depuis [since] ; `null` sans aucun sommeil terminé.
  const factory SleepStatus.awake({DateTime? since}) = Awake;

  /// Sommeil en cours depuis trop longtemps : réveil probablement oublié.
  const factory SleepStatus.forgottenWake(SleepSession session) = ForgottenWake;
}

/// État actuel et total de sommeil sur les 24 dernières heures.
@freezed
abstract class SleepSummary with _$SleepSummary {
  const factory SleepSummary({
    required SleepStatus status,
    required Duration last24h,
  }) = _SleepSummary;
}
```

- [ ] **Step 2: Tests rouges** `test/features/sleep/domain/compute_sleep_summary_test.dart` :

```dart
import 'package:colette/features/sleep/domain/entities/sleep_status.dart';
import 'package:colette/features/sleep/domain/use_cases/compute_sleep_summary.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../helpers/sleep_session_factory.dart';

void main() {
  final now = DateTime(2026, 9, 23, 16);

  test('aucun sommeil : éveillé·e sans date, total nul', () {
    final summary = computeSleepSummary(recent: const [], latest: null, now: now);
    expect(summary.status, const SleepStatus.awake());
    expect(summary.last24h, Duration.zero);
  });

  test('sommeil en cours : endormi·e, compté jusqu\'à maintenant', () {
    final ongoing = makeSleep(id: 'o', startAt: DateTime(2026, 9, 23, 15, 18));
    final summary = computeSleepSummary(recent: [ongoing], latest: ongoing, now: now);
    expect(summary.status, SleepStatus.asleep(ongoing));
    expect(summary.last24h, const Duration(minutes: 42));
  });

  test('éveillé·e depuis la fin du dernier sommeil terminé', () {
    final a = makeSleep(id: 'a', startAt: DateTime(2026, 9, 23, 13), endAt: DateTime(2026, 9, 23, 14, 50));
    final summary = computeSleepSummary(recent: [a], latest: a, now: now);
    expect(summary.status, SleepStatus.awake(since: DateTime(2026, 9, 23, 14, 50)));
  });

  test('un sommeil à cheval sur la fenêtre ne compte que sa partie dedans', () {
    final night = makeSleep(id: 'n', startAt: DateTime(2026, 9, 22, 14), endAt: DateTime(2026, 9, 22, 18));
    final summary = computeSleepSummary(recent: [night], latest: night, now: now);
    expect(summary.last24h, const Duration(hours: 2));
  });

  test('au-delà de 16 h, le sommeil en cours devient un réveil oublié', () {
    final old = makeSleep(id: 'o', startAt: DateTime(2026, 9, 22, 23, 59));
    final summary = computeSleepSummary(recent: [old], latest: old, now: now);
    expect(summary.status, SleepStatus.forgottenWake(old));
  });

  test('deux sommeils ouverts : le plus ancien fait foi', () {
    final first = makeSleep(id: 'a', startAt: DateTime(2026, 9, 23, 15));
    final dup = makeSleep(id: 'b', startAt: DateTime(2026, 9, 23, 15, 1));
    final summary = computeSleepSummary(recent: [dup, first], latest: dup, now: now);
    expect(summary.status, SleepStatus.asleep(first));
    expect(summary.last24h, const Duration(minutes: 60));
  });

  test('le dernier sommeil hors fenêtre sert à « éveillé·e depuis »', () {
    final old = makeSleep(id: 'x', startAt: DateTime(2026, 9, 20, 10), endAt: DateTime(2026, 9, 20, 11));
    final summary = computeSleepSummary(recent: const [], latest: old, now: now);
    expect(summary.status, SleepStatus.awake(since: DateTime(2026, 9, 20, 11)));
    expect(summary.last24h, Duration.zero);
  });
}
```

Note : dans le test « deux sommeils ouverts », le total compte seulement le plus ancien (les doublons se chevauchent) : `mergeSleeps` ne garde qu'un sommeil ouvert.

`test/features/sleep/domain/plan_wake_up_test.dart` :

```dart
import 'package:colette/features/sleep/domain/use_cases/plan_wake_up.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../helpers/sleep_session_factory.dart';

void main() {
  final now = DateTime(2026, 9, 23, 16);

  test('aucun sommeil ouvert : rien à faire', () {
    expect(planWakeUp(const [], now), isNull);
  });

  test('ferme le plus ancien et supprime les doublons', () {
    final first = makeSleep(id: 'a', startAt: DateTime(2026, 9, 23, 15));
    final dup = makeSleep(id: 'b', startAt: DateTime(2026, 9, 23, 15, 1));
    final plan = planWakeUp([dup, first], now)!;
    expect(plan.close, first.copyWith(endAt: now, updatedAt: now));
    expect(plan.deleteIds, ['b']);
  });

  test('un seul ouvert : aucune suppression', () {
    final only = makeSleep(id: 'a', startAt: DateTime(2026, 9, 23, 15));
    expect(planWakeUp([only], now)!.deleteIds, isEmpty);
  });
}
```

- [ ] **Step 3: Vérifier l'échec** — Run: `dart run build_runner build -d && flutter test test/features/sleep/domain` → FAIL (use cases absents).

- [ ] **Step 4: Implémenter** `lib/features/sleep/domain/use_cases/plan_wake_up.dart` :

```dart
import 'package:colette/features/sleep/domain/entities/sleep_session.dart';

/// Écritures du réveil : le sommeil à fermer et les doublons à supprimer.
typedef WakeUpPlan = ({SleepSession close, List<String> deleteIds});

/// Ferme le plus ancien des sommeils ouverts [open] à [now] ; les autres sont
/// des doublons (deux appuis simultanés) à supprimer. `null` si aucun.
WakeUpPlan? planWakeUp(List<SleepSession> open, DateTime now) {
  if (open.isEmpty) return null;
  final sorted = [...open]..sort((a, b) => a.startAt.compareTo(b.startAt));
  return (
    close: sorted.first.copyWith(endAt: now, updatedAt: now),
    deleteIds: [for (final s in sorted.skip(1)) s.id],
  );
}
```

`lib/features/sleep/domain/use_cases/compute_sleep_summary.dart` :

```dart
import 'package:colette/features/sleep/domain/entities/sleep_session.dart';
import 'package:colette/features/sleep/domain/entities/sleep_status.dart';

/// Fenêtre du total glissant.
const sleepSummaryWindow = Duration(hours: 24);

/// Au-delà, un sommeil en cours est signalé comme réveil oublié.
const forgottenWakeAfter = Duration(hours: 16);

/// Réunit [recent] et [latest] sans doublon d'identifiant, en ne gardant que le
/// plus ancien sommeil ouvert (les autres sont des doublons d'appuis simultanés).
List<SleepSession> mergeSleeps(
  List<SleepSession> recent,
  SleepSession? latest,
) {
  final byId = {for (final s in recent) s.id: s};
  if (latest != null) byId[latest.id] = latest;
  final open = byId.values.where((s) => s.isOngoing).toList()
    ..sort((a, b) => a.startAt.compareTo(b.startAt));
  final duplicates = open.skip(1).map((s) => s.id).toSet();
  return byId.values.where((s) => !duplicates.contains(s.id)).toList();
}

/// Sommeils ouverts, du plus ancien au plus récent, doublons compris.
List<SleepSession> openSleeps(
  List<SleepSession> recent,
  SleepSession? latest,
) {
  final byId = {for (final s in recent) s.id: s};
  if (latest != null) byId[latest.id] = latest;
  return byId.values.where((s) => s.isOngoing).toList()
    ..sort((a, b) => a.startAt.compareTo(b.startAt));
}

/// État actuel et total sur les dernières 24 h.
SleepSummary computeSleepSummary({
  required List<SleepSession> recent,
  required SleepSession? latest,
  required DateTime now,
}) {
  final sleeps = mergeSleeps(recent, latest);
  final windowStart = now.subtract(sleepSummaryWindow);
  var total = Duration.zero;
  for (final sleep in sleeps) {
    final start = sleep.startAt.isAfter(windowStart) ? sleep.startAt : windowStart;
    final rawEnd = sleep.endOr(now);
    final end = rawEnd.isBefore(now) ? rawEnd : now;
    if (end.isAfter(start)) total += end.difference(start);
  }
  final ongoing = sleeps.where((s) => s.isOngoing).firstOrNull;
  final SleepStatus status;
  if (ongoing != null) {
    status = now.difference(ongoing.startAt) > forgottenWakeAfter
        ? SleepStatus.forgottenWake(ongoing)
        : SleepStatus.asleep(ongoing);
  } else {
    final ends = sleeps.map((s) => s.endAt).nonNulls.toList()..sort();
    status = SleepStatus.awake(since: ends.lastOrNull);
  }
  return SleepSummary(status: status, last24h: total);
}
```

- [ ] **Step 5: Vérifier** — Run: `flutter test test/features/sleep/domain` → PASS.

- [ ] **Step 6: Commit**

```bash
git add lib/features/sleep/domain/entities/sleep_status.dart lib/features/sleep/domain/entities/sleep_status.freezed.dart lib/features/sleep/domain/use_cases/compute_sleep_summary.dart lib/features/sleep/domain/use_cases/plan_wake_up.dart test/features/sleep/domain/compute_sleep_summary_test.dart test/features/sleep/domain/plan_wake_up_test.dart
git commit -m "feat: état du sommeil, total sur 24 h et plan du réveil"
```

---

### Task 7: `SleepDay` et `computeSleepDays`

**Files:**
- Create: `lib/features/sleep/domain/entities/sleep_day.dart`
- Create: `lib/features/sleep/domain/use_cases/compute_sleep_days.dart`
- Test: `test/features/sleep/domain/compute_sleep_days_test.dart`

- [ ] **Step 1: Entités**

```dart
import 'package:colette/features/sleep/domain/entities/sleep_kind.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

part 'sleep_day.freezed.dart';

/// Portion d'un sommeil comprise dans un jour civil.
@freezed
abstract class SleepSegment with _$SleepSegment {
  const factory SleepSegment({
    required DateTime start,
    required DateTime end,
    required SleepKind kind,
  }) = _SleepSegment;
}

/// Sommeil d'un jour civil : segments, total, siestes, plus longue période.
@freezed
abstract class SleepDay with _$SleepDay {
  const factory SleepDay({
    required DateTime day,
    required List<SleepSegment> segments,
    required Duration total,
    required int napCount,
    required Duration longest,
  }) = _SleepDay;
}
```

- [ ] **Step 2: Tests rouges**

```dart
import 'package:colette/features/sleep/domain/entities/sleep_kind.dart';
import 'package:colette/features/sleep/domain/use_cases/compute_sleep_days.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../helpers/sleep_session_factory.dart';

void main() {
  final today = DateTime(2026, 9, 23);
  final now = DateTime(2026, 9, 23, 16);

  test('sept jours, du plus ancien à aujourd\'hui', () {
    final days = computeSleepDays(const [], today: today, now: now);
    expect(days.map((d) => d.day), [
      for (var i = 6; i >= 0; i--) DateTime(2026, 9, 23 - i),
    ]);
    expect(days.every((d) => d.total == Duration.zero && d.segments.isEmpty), isTrue);
  });

  test('une nuit qui passe minuit est découpée sur deux jours', () {
    final night = makeSleep(id: 'n', kind: SleepKind.night, startAt: DateTime(2026, 9, 22, 22), endAt: DateTime(2026, 9, 23, 6));
    final days = computeSleepDays([night], today: today, now: now);
    final yesterday = days[5];
    final todayDay = days[6];
    expect(yesterday.total, const Duration(hours: 2));
    expect(todayDay.total, const Duration(hours: 6));
    expect(todayDay.segments.single.start, DateTime(2026, 9, 23));
    expect(yesterday.longest, const Duration(hours: 8));
    expect(todayDay.longest, Duration.zero);
  });

  test('siestes comptées au jour de début, sommeil en cours jusqu\'à maintenant', () {
    final nap1 = makeSleep(id: 'a', startAt: DateTime(2026, 9, 23, 9), endAt: DateTime(2026, 9, 23, 10, 30));
    final nap2 = makeSleep(id: 'b', startAt: DateTime(2026, 9, 23, 15));
    final days = computeSleepDays([nap1, nap2], today: today, now: now);
    expect(days.last.napCount, 2);
    expect(days.last.total, const Duration(hours: 2, minutes: 30));
    expect(days.last.longest, const Duration(minutes: 90));
  });

  test('moyenne des jours précédents ayant du sommeil, sans aujourd\'hui', () {
    final a = makeSleep(id: 'a', startAt: DateTime(2026, 9, 21, 9), endAt: DateTime(2026, 9, 21, 23));
    final b = makeSleep(id: 'b', startAt: DateTime(2026, 9, 22, 9), endAt: DateTime(2026, 9, 22, 21));
    final c = makeSleep(id: 'c', startAt: DateTime(2026, 9, 23, 9), endAt: DateTime(2026, 9, 23, 10));
    final days = computeSleepDays([a, b, c], today: today, now: now);
    expect(averageOfPreviousDays(days), const Duration(hours: 13));
  });

  test('moyenne nulle sans jour précédent noté', () {
    final days = computeSleepDays(const [], today: today, now: now);
    expect(averageOfPreviousDays(days), isNull);
  });
}
```

- [ ] **Step 3: Vérifier l'échec** — Run: `dart run build_runner build -d && flutter test test/features/sleep/domain/compute_sleep_days_test.dart` → FAIL.

- [ ] **Step 4: Implémenter** `lib/features/sleep/domain/use_cases/compute_sleep_days.dart` :

```dart
import 'package:colette/features/sleep/domain/entities/sleep_day.dart';
import 'package:colette/features/sleep/domain/entities/sleep_kind.dart';
import 'package:colette/features/sleep/domain/entities/sleep_session.dart';

/// Nombre de jours affichés par la page Sommeil.
const sleepWeekDayCount = 7;

/// Les [sleepWeekDayCount] jours civils se terminant par [today], du plus ancien
/// au plus récent. Un sommeil qui passe minuit est découpé ; siestes et plus
/// longue période sont rattachées au jour de début.
List<SleepDay> computeSleepDays(
  List<SleepSession> sleeps, {
  required DateTime today,
  required DateTime now,
}) => [
  for (var offset = sleepWeekDayCount - 1; offset >= 0; offset--)
    _day(sleeps, DateTime(today.year, today.month, today.day - offset), now),
];

SleepDay _day(List<SleepSession> sleeps, DateTime dayStart, DateTime now) {
  final dayEnd = DateTime(dayStart.year, dayStart.month, dayStart.day + 1);
  final segments = <SleepSegment>[];
  var total = Duration.zero;
  var napCount = 0;
  var longest = Duration.zero;
  for (final sleep in sleeps) {
    final start = sleep.startAt.isAfter(dayStart) ? sleep.startAt : dayStart;
    final rawEnd = sleep.endOr(now);
    final end = rawEnd.isBefore(dayEnd) ? rawEnd : dayEnd;
    if (end.isAfter(start)) {
      segments.add(SleepSegment(start: start, end: end, kind: sleep.kind));
      total += end.difference(start);
    }
    final startsToday =
        !sleep.startAt.isBefore(dayStart) && sleep.startAt.isBefore(dayEnd);
    if (!startsToday) continue;
    if (sleep.kind == SleepKind.nap) napCount++;
    final duration = sleep.durationUntil(now);
    if (duration > longest) longest = duration;
  }
  segments.sort((a, b) => a.start.compareTo(b.start));
  return SleepDay(
    day: dayStart,
    segments: segments,
    total: total,
    napCount: napCount,
    longest: longest,
  );
}

/// Moyenne des totaux des jours précédant le dernier, parmi ceux qui ont du
/// sommeil noté ; `null` s'il n'y en a aucun.
Duration? averageOfPreviousDays(List<SleepDay> days) {
  final noted = days
      .take(days.length - 1)
      .where((d) => d.total > Duration.zero)
      .toList();
  if (noted.isEmpty) return null;
  final minutes = noted.fold(0, (sum, d) => sum + d.total.inMinutes);
  return Duration(minutes: (minutes / noted.length).round());
}
```

- [ ] **Step 5: Vérifier** — Run: `flutter test test/features/sleep/domain` → PASS.

- [ ] **Step 6: Commit**

```bash
git add lib/features/sleep/domain/entities/sleep_day.dart lib/features/sleep/domain/entities/sleep_day.freezed.dart lib/features/sleep/domain/use_cases/compute_sleep_days.dart test/features/sleep/domain/compute_sleep_days_test.dart
git commit -m "feat: sommeil par jour civil et moyenne des jours précédents"
```

---

### Task 8: Repository, DTO et implémentation Firestore

**Files:**
- Create: `lib/features/sleep/domain/repositories/sleep_repository.dart`
- Create: `lib/features/sleep/data/dtos/sleep_session_dto.dart`
- Create: `lib/features/sleep/data/repositories/firestore_sleep_repository.dart`
- Test: `test/features/sleep/data/sleep_session_dto_test.dart`, `test/features/sleep/data/firestore_sleep_repository_test.dart`

- [ ] **Step 1: Interface**

```dart
import 'package:colette/core/result/failure.dart';
import 'package:colette/features/sleep/domain/entities/sleep_session.dart';
import 'package:fpdart/fpdart.dart';

/// Sommeils d'un foyer.
abstract interface class SleepRepository {
  /// Sommeils dont `startAt` ≥ [from], du plus récent au plus ancien.
  Stream<List<SleepSession>> watchStartedSince(
    String householdCode,
    DateTime from,
  );

  /// Dernier sommeil par `startAt`, toutes dates confondues.
  Stream<SleepSession?> watchLatest(String householdCode);

  /// Sommeils dont `startAt` est dans `[from, to[`.
  Future<Either<Failure, List<SleepSession>>> getStartedBetween(
    String householdCode, {
    required DateTime from,
    required DateTime to,
  });

  /// Crée ou remplace le sommeil (clé : `session.id`).
  Future<Either<Failure, void>> save(String householdCode, SleepSession session);

  Future<Either<Failure, void>> delete(String householdCode, String sessionId);

  /// Écrit [close] et supprime [deleteIds] en un seul lot.
  Future<Either<Failure, void>> wakeUp(
    String householdCode, {
    required SleepSession close,
    required List<String> deleteIds,
  });
}
```

- [ ] **Step 2: Tests rouges du DTO** `test/features/sleep/data/sleep_session_dto_test.dart` :

```dart
import 'package:colette/features/sleep/data/dtos/sleep_session_dto.dart';
import 'package:colette/features/sleep/domain/entities/sleep_kind.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../helpers/sleep_session_factory.dart';

void main() {
  Future<dynamic> roundTrip(Map<String, dynamic> map) async {
    final db = FakeFirebaseFirestore();
    final ref = db.collection('sleeps').doc('s1');
    await ref.set(map);
    return SleepSessionDto.fromDoc(await ref.get());
  }

  test('aller-retour d\'un sommeil terminé', () async {
    final sleep = makeSleep(startAt: DateTime(2026, 9, 23, 13), endAt: DateTime(2026, 9, 23, 14), kind: SleepKind.night);
    expect(await roundTrip(SleepSessionDto.toMap(sleep)), sleep);
  });

  test('aller-retour d\'un sommeil en cours : endAt écrit à null', () async {
    final sleep = makeSleep(startAt: DateTime(2026, 9, 23, 13));
    final map = SleepSessionDto.toMap(sleep);
    expect(map.containsKey('endAt'), isTrue);
    expect(map['endAt'], isNull);
    expect(await roundTrip(map), sleep);
  });

  test('kind inconnu lu comme sieste', () async {
    final map = SleepSessionDto.toMap(makeSleep(startAt: DateTime(2026, 9, 23, 13)))..['kind'] = 'autre';
    expect((await roundTrip(map)).kind, SleepKind.nap);
  });
}
```

- [ ] **Step 3: Tests rouges du repository** `test/features/sleep/data/firestore_sleep_repository_test.dart` :

```dart
import 'package:colette/features/sleep/data/repositories/firestore_sleep_repository.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../helpers/sleep_session_factory.dart';

void main() {
  const code = 'ABCDEFGH';
  final a = makeSleep(id: 'a', startAt: DateTime(2026, 9, 22, 13), endAt: DateTime(2026, 9, 22, 14));
  final b = makeSleep(id: 'b', startAt: DateTime(2026, 9, 23, 9), endAt: DateTime(2026, 9, 23, 10));
  final c = makeSleep(id: 'c', startAt: DateTime(2026, 9, 23, 15));

  Future<FirestoreSleepRepository> seeded() async {
    final repo = FirestoreSleepRepository(FakeFirebaseFirestore());
    for (final s in [a, b, c]) {
      await repo.save(code, s);
    }
    return repo;
  }

  test('watchStartedSince filtre et trie du plus récent au plus ancien', () async {
    final repo = await seeded();
    final list = await repo.watchStartedSince(code, DateTime(2026, 9, 23)).first;
    expect(list.map((s) => s.id), ['c', 'b']);
  });

  test('watchLatest renvoie le dernier par startAt, null sans sommeil', () async {
    expect(await FirestoreSleepRepository(FakeFirebaseFirestore()).watchLatest(code).first, isNull);
    final repo = await seeded();
    expect(await repo.watchLatest(code).first, c);
  });

  test('getStartedBetween borne [from, to[', () async {
    final repo = await seeded();
    final result = await repo.getStartedBetween(code, from: DateTime(2026, 9, 22, 13), to: DateTime(2026, 9, 23, 15));
    expect(result.getRight().toNullable()!.map((s) => s.id), ['b', 'a']);
  });

  test('wakeUp ferme un sommeil et supprime les doublons en lot', () async {
    final repo = await seeded();
    final dup = makeSleep(id: 'd', startAt: DateTime(2026, 9, 23, 15, 1));
    await repo.save(code, dup);
    final closed = c.copyWith(endAt: DateTime(2026, 9, 23, 16));
    final result = await repo.wakeUp(code, close: closed, deleteIds: ['d']);
    expect(result.isRight(), isTrue);
    final list = await repo.watchStartedSince(code, DateTime(2026, 9, 23)).first;
    expect(list, [closed, b]);
  });

  test('delete retire le sommeil', () async {
    final repo = await seeded();
    await repo.delete(code, 'b');
    final list = await repo.watchStartedSince(code, DateTime(2026, 9, 1)).first;
    expect(list.map((s) => s.id), ['c', 'a']);
  });
}
```

- [ ] **Step 4: Vérifier l'échec** — Run: `flutter test test/features/sleep/data` → FAIL.

- [ ] **Step 5: Implémenter le DTO**

```dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:colette/features/sleep/domain/entities/sleep_kind.dart';
import 'package:colette/features/sleep/domain/entities/sleep_session.dart';

/// Conversion `SleepSession` ↔ document `sleeps/{id}`.
abstract final class SleepSessionDto {
  /// `endAt` est toujours écrit, à `null` pour un sommeil en cours.
  static Map<String, dynamic> toMap(SleepSession session) => {
    'startAt': Timestamp.fromDate(session.startAt),
    'endAt': switch (session.endAt) {
      null => null,
      final end => Timestamp.fromDate(end),
    },
    'kind': session.kind.name,
    'createdByDeviceId': session.createdByDeviceId,
    'createdAt': Timestamp.fromDate(session.createdAt),
    'updatedAt': Timestamp.fromDate(session.updatedAt),
  };

  /// `kind` inconnu → sieste.
  static SleepSession fromDoc(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data()!;
    return SleepSession(
      id: doc.id,
      startAt: (data['startAt'] as Timestamp).toDate(),
      endAt: (data['endAt'] as Timestamp?)?.toDate(),
      kind:
          SleepKind.values.where((k) => k.name == data['kind']).firstOrNull ??
          SleepKind.nap,
      createdByDeviceId: data['createdByDeviceId'] as String? ?? '',
      createdAt: (data['createdAt'] as Timestamp).toDate(),
      updatedAt: (data['updatedAt'] as Timestamp).toDate(),
    );
  }
}
```

- [ ] **Step 6: Implémenter le repository**

```dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:colette/core/firebase/firestore_paths.dart';
import 'package:colette/core/result/failure.dart';
import 'package:colette/core/result/failure_mapper.dart';
import 'package:colette/features/sleep/data/dtos/sleep_session_dto.dart';
import 'package:colette/features/sleep/domain/entities/sleep_session.dart';
import 'package:colette/features/sleep/domain/repositories/sleep_repository.dart';
import 'package:fpdart/fpdart.dart';

/// Sommeils dans `households/{code}/sleeps/{id}`.
class FirestoreSleepRepository implements SleepRepository {
  FirestoreSleepRepository(this._db);

  final FirebaseFirestore _db;

  CollectionReference<Map<String, dynamic>> _sleeps(String code) => _db
      .collection(FirestorePaths.households)
      .doc(code)
      .collection(FirestorePaths.sleeps);

  List<SleepSession> _toList(QuerySnapshot<Map<String, dynamic>> snap) =>
      snap.docs.map(SleepSessionDto.fromDoc).toList();

  @override
  Stream<List<SleepSession>> watchStartedSince(
    String householdCode,
    DateTime from,
  ) => _sleeps(householdCode)
      .where('startAt', isGreaterThanOrEqualTo: Timestamp.fromDate(from))
      .orderBy('startAt', descending: true)
      .snapshots()
      .map(_toList);

  @override
  Stream<SleepSession?> watchLatest(String householdCode) =>
      _sleeps(householdCode)
          .orderBy('startAt', descending: true)
          .limit(1)
          .snapshots()
          .map((snap) => _toList(snap).firstOrNull);

  @override
  Future<Either<Failure, List<SleepSession>>> getStartedBetween(
    String householdCode, {
    required DateTime from,
    required DateTime to,
  }) => guard(
    () async => _toList(
      await _sleeps(householdCode)
          .where('startAt', isGreaterThanOrEqualTo: Timestamp.fromDate(from))
          .where('startAt', isLessThan: Timestamp.fromDate(to))
          .orderBy('startAt', descending: true)
          .get(),
    ),
  );

  @override
  Future<Either<Failure, void>> save(
    String householdCode,
    SleepSession session,
  ) => guard(
    () => _sleeps(householdCode)
        .doc(session.id)
        .set(SleepSessionDto.toMap(session)),
  );

  @override
  Future<Either<Failure, void>> delete(String householdCode, String sessionId) =>
      guard(() => _sleeps(householdCode).doc(sessionId).delete());

  @override
  Future<Either<Failure, void>> wakeUp(
    String householdCode, {
    required SleepSession close,
    required List<String> deleteIds,
  }) => guard(() {
    final sleeps = _sleeps(householdCode);
    final batch = _db.batch()
      ..set(sleeps.doc(close.id), SleepSessionDto.toMap(close));
    for (final id in deleteIds) {
      batch.delete(sleeps.doc(id));
    }
    return batch.commit();
  });
}
```

- [ ] **Step 7: Vérifier** — Run: `flutter test test/features/sleep/data` → PASS.

- [ ] **Step 8: Commit**

```bash
git add lib/features/sleep/domain/repositories/sleep_repository.dart lib/features/sleep/data test/features/sleep/data
git commit -m "feat: dépôt Firestore des sommeils avec réveil en lot"
```

---

### Task 9: Horaires de nuit dans `CareSettings`

**Files:**
- Modify: `lib/features/baby/domain/entities/care_settings.dart`
- Modify: `lib/features/baby/data/dtos/baby_profile_dto.dart`
- Test: `test/features/baby/data/baby_profile_dto_test.dart`

- [ ] **Step 1: Test rouge.** Ajouter dans `baby_profile_dto_test.dart` :

```dart
  group('horaires de nuit', () {
    test('valeurs par défaut 20 h et 7 h sans champ', () {
      final settings = CareSettingsDto.fromMap(const {});
      expect(settings.nightStartHour, 20);
      expect(settings.nightEndHour, 7);
    });

    test('aller-retour et bornes 0 à 23', () {
      const settings = CareSettings(nightStartHour: 21, nightEndHour: 6);
      expect(CareSettingsDto.fromMap(CareSettingsDto.toMap(settings)), settings);
      final clamped = CareSettingsDto.fromMap(const {'nightStartHour': 30, 'nightEndHour': -2});
      expect(clamped.nightStartHour, 23);
      expect(clamped.nightEndHour, 0);
    });
  });
```

- [ ] **Step 2: Vérifier l'échec** — Run: `flutter test test/features/baby/data/baby_profile_dto_test.dart` → FAIL.

- [ ] **Step 3: Implémenter.** Dans `CareSettings`, après `@Default(8) int feedsPerDay,` :

```dart
    /// Heure (0-23) à partir de laquelle un endormissement est une nuit.
    @Default(20) int nightStartHour,

    /// Heure (0-23) à partir de laquelle un endormissement redevient une sieste.
    @Default(7) int nightEndHour,
```

et mettre à jour le commentaire de classe : `/// Fréquences des soins attendus, cible de lait ajustée et horaires de nuit.`

Dans `CareSettingsDto.toMap`, ajouter `'nightStartHour': settings.nightStartHour, 'nightEndHour': settings.nightEndHour,` ; dans `fromMap` :

```dart
    nightStartHour: _readInt(map, 'nightStartHour', 20, min: 0, max: 23),
    nightEndHour: _readInt(map, 'nightEndHour', 7, min: 0, max: 23),
```

- [ ] **Step 4: Vérifier**

```bash
dart run build_runner build -d
flutter test test/features/baby
```

Expected : PASS.

- [ ] **Step 5: Commit**

```bash
git add lib/features/baby/domain/entities/care_settings.dart lib/features/baby/domain/entities/care_settings.freezed.dart lib/features/baby/data/dtos/baby_profile_dto.dart test/features/baby/data/baby_profile_dto_test.dart
git commit -m "feat: horaires de nuit dans les réglages de soins"
```

---

### Task 10: Providers et `SleepController`

**Files:**
- Create: `lib/features/sleep/presentation/providers/sleep_providers.dart`
- Create: `lib/features/sleep/presentation/providers/sleep_controller.dart`
- Create: `test/helpers/fake_sleep_repository.dart`
- Test: `test/features/sleep/presentation/sleep_controller_test.dart`, `test/features/sleep/presentation/sleep_providers_test.dart`

- [ ] **Step 1: Aide de test** `test/helpers/fake_sleep_repository.dart` :

```dart
import 'package:colette/core/result/failure.dart';
import 'package:colette/features/sleep/domain/entities/sleep_session.dart';
import 'package:colette/features/sleep/domain/repositories/sleep_repository.dart';
import 'package:fpdart/fpdart.dart';

/// Dépôt de sommeils en mémoire ; enregistre les écritures pour les assertions.
class FakeSleepRepository implements SleepRepository {
  FakeSleepRepository([List<SleepSession> sessions = const []])
    : sessions = [...sessions];

  final List<SleepSession> sessions;
  final saved = <SleepSession>[];
  final deleted = <String>[];
  ({SleepSession close, List<String> deleteIds})? lastWakeUp;

  /// Échec renvoyé par toutes les écritures, si renseigné.
  Failure? failure;

  List<SleepSession> _sorted(Iterable<SleepSession> list) =>
      [...list]..sort((a, b) => b.startAt.compareTo(a.startAt));

  @override
  Stream<List<SleepSession>> watchStartedSince(String code, DateTime from) =>
      Stream.value(_sorted(sessions.where((s) => !s.startAt.isBefore(from))));

  @override
  Stream<SleepSession?> watchLatest(String code) =>
      Stream.value(_sorted(sessions).firstOrNull);

  @override
  Future<Either<Failure, List<SleepSession>>> getStartedBetween(
    String code, {
    required DateTime from,
    required DateTime to,
  }) async => right(
    _sorted(
      sessions.where((s) => !s.startAt.isBefore(from) && s.startAt.isBefore(to)),
    ),
  );

  Either<Failure, void> _write(void Function() action) {
    if (failure case final f?) return left(f);
    action();
    return right(null);
  }

  @override
  Future<Either<Failure, void>> save(String code, SleepSession session) async =>
      _write(() {
        saved.add(session);
        sessions
          ..removeWhere((s) => s.id == session.id)
          ..add(session);
      });

  @override
  Future<Either<Failure, void>> delete(String code, String sessionId) async =>
      _write(() {
        deleted.add(sessionId);
        sessions.removeWhere((s) => s.id == sessionId);
      });

  @override
  Future<Either<Failure, void>> wakeUp(
    String code, {
    required SleepSession close,
    required List<String> deleteIds,
  }) async => _write(() {
    lastWakeUp = (close: close, deleteIds: deleteIds);
    sessions
      ..removeWhere((s) => s.id == close.id || deleteIds.contains(s.id))
      ..add(close);
  });
}
```

- [ ] **Step 2: Providers** `lib/features/sleep/presentation/providers/sleep_providers.dart` :

```dart
import 'package:colette/core/clock/now_providers.dart';
import 'package:colette/core/firebase/firebase_providers.dart';
import 'package:colette/core/result/no_retry.dart';
import 'package:colette/features/baby/presentation/providers/baby_providers.dart';
import 'package:colette/features/household/presentation/providers/household_providers.dart';
import 'package:colette/features/sleep/data/repositories/firestore_sleep_repository.dart';
import 'package:colette/features/sleep/domain/entities/sleep_age_band.dart';
import 'package:colette/features/sleep/domain/entities/sleep_day.dart';
import 'package:colette/features/sleep/domain/entities/sleep_session.dart';
import 'package:colette/features/sleep/domain/entities/sleep_status.dart';
import 'package:colette/features/sleep/domain/repositories/sleep_repository.dart';
import 'package:colette/features/sleep/domain/use_cases/compute_sleep_days.dart';
import 'package:colette/features/sleep/domain/use_cases/compute_sleep_summary.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'sleep_providers.g.dart';

/// Dépôt des sommeils du foyer.
@riverpod
SleepRepository sleepRepository(Ref ref) =>
    FirestoreSleepRepository(ref.watch(firestoreProvider));

/// Sommeils commencés depuis minuit il y a deux jours (couvre les 24 h
/// glissantes, un sommeil durant au plus 24 h). Borne stable sur la journée.
@Riverpod(retry: noRetry)
Stream<List<SleepSession>> recentSleeps(Ref ref) {
  final code = ref.watch(currentHouseholdCodeProvider);
  if (code == null) return Stream.value(const []);
  final today = ref.watch(todayProvider);
  return ref
      .watch(sleepRepositoryProvider)
      .watchStartedSince(code, DateTime(today.year, today.month, today.day - 2));
}

/// Dernier sommeil, toutes dates confondues.
@Riverpod(retry: noRetry)
Stream<SleepSession?> latestSleep(Ref ref) {
  final code = ref.watch(currentHouseholdCodeProvider);
  if (code == null) return Stream.value(null);
  return ref.watch(sleepRepositoryProvider).watchLatest(code);
}

/// État actuel et total sur 24 h ; `null` tant que les flux chargent.
@riverpod
SleepSummary? sleepSummary(Ref ref) {
  final recent = ref.watch(recentSleepsProvider);
  final latest = ref.watch(latestSleepProvider);
  if (!recent.hasValue || !latest.hasValue) return null;
  return computeSleepSummary(
    recent: recent.requireValue,
    latest: latest.requireValue,
    now: ref.watch(currentMinuteProvider),
  );
}

/// Repère OMS selon l'âge ; `null` sans profil ou à partir de 2 ans.
@riverpod
SleepAgeBand? sleepAgeBand(Ref ref) {
  final profile = ref.watch(babyProfileProvider).value;
  if (profile == null) return null;
  return SleepAgeBand.forAge(
    birthDate: profile.birthDate,
    now: ref.watch(todayProvider),
  );
}

/// Sommeils commencés depuis J−7 (la veille du premier jour affiché couvre les
/// nuits qui débordent sur J−6).
@Riverpod(retry: noRetry)
Stream<List<SleepSession>> weekSleeps(Ref ref) {
  final code = ref.watch(currentHouseholdCodeProvider);
  if (code == null) return Stream.value(const []);
  final today = ref.watch(todayProvider);
  return ref.watch(sleepRepositoryProvider).watchStartedSince(
    code,
    DateTime(today.year, today.month, today.day - sleepWeekDayCount),
  );
}

/// Les 7 jours de la page Sommeil ; `null` tant que le flux charge.
@riverpod
List<SleepDay>? sleepWeek(Ref ref) {
  final sleeps = ref.watch(weekSleepsProvider).value;
  if (sleeps == null) return null;
  return computeSleepDays(
    sleeps,
    today: ref.watch(todayProvider),
    now: ref.watch(currentMinuteProvider),
  );
}

/// Sommeils du Journal depuis [from] ; [from] doit être stable (minuit d'un jour).
@Riverpod(retry: noRetry)
Stream<List<SleepSession>> timelineSleeps(Ref ref, DateTime from) {
  final code = ref.watch(currentHouseholdCodeProvider);
  if (code == null) return Stream.value(const []);
  return ref.watch(sleepRepositoryProvider).watchStartedSince(code, from);
}
```

- [ ] **Step 3: Tests rouges du contrôleur** `test/features/sleep/presentation/sleep_controller_test.dart` :

```dart
import 'package:colette/core/clock/app_clock.dart';
import 'package:colette/core/clock/now_providers.dart';
import 'package:colette/core/ids/id_generator.dart';
import 'package:colette/core/result/failure.dart';
import 'package:colette/features/baby/domain/entities/baby_profile.dart';
import 'package:colette/features/baby/presentation/providers/baby_providers.dart';
import 'package:colette/features/household/presentation/providers/household_providers.dart';
import 'package:colette/features/sleep/domain/entities/sleep_kind.dart';
import 'package:colette/features/sleep/presentation/providers/sleep_controller.dart';
import 'package:colette/features/sleep/presentation/providers/sleep_providers.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../helpers/fake_sleep_repository.dart';
import '../../../helpers/in_memory_household_local_store.dart';
import '../../../helpers/sleep_session_factory.dart';

void main() {
  final now = DateTime(2026, 9, 23, 21);

  ProviderContainer containerWith(FakeSleepRepository repo) {
    final container = ProviderContainer(
      overrides: [
        sleepRepositoryProvider.overrideWithValue(repo),
        clockProvider.overrideWithValue(FixedClock(now)),
        minuteTickerProvider.overrideWith((ref) => const Stream.empty()),
        idGeneratorProvider.overrideWithValue(const FixedIdGenerator('new')),
        householdLocalStoreProvider.overrideWithValue(
          InMemoryHouseholdLocalStore(householdCode: 'ABCDEFGH', deviceId: 'dev'),
        ),
        babyProfileProvider.overrideWith(
          (ref) => Stream.value(BabyProfile(name: 'Colette', birthDate: DateTime(2026, 9, 1))),
        ),
      ],
    );
    addTearDown(container.dispose);
    // Garde le contrôleur et les flux en vie, comme le ferait la carte.
    container.listen(sleepControllerProvider, (_, _) {});
    container.listen(sleepSummaryProvider, (_, _) {});
    return container;
  }

  Future<void> settle(ProviderContainer c) async {
    await c.read(recentSleepsProvider.future);
    await c.read(latestSleepProvider.future);
    await c.read(babyProfileProvider.future);
  }

  test('fallAsleep crée un sommeil en cours classé selon l\'heure', () async {
    final repo = FakeSleepRepository();
    final c = containerWith(repo);
    await settle(c);
    expect(await c.read(sleepControllerProvider.notifier).fallAsleep(), isTrue);
    final saved = repo.saved.single;
    expect(saved.id, 'new');
    expect(saved.startAt, now);
    expect(saved.endAt, isNull);
    expect(saved.kind, SleepKind.night);
    expect(saved.createdByDeviceId, 'dev');
  });

  test('fallAsleep ne fait rien si un sommeil est déjà en cours', () async {
    final repo = FakeSleepRepository([makeSleep(id: 'o', startAt: DateTime(2026, 9, 23, 20))]);
    final c = containerWith(repo);
    await settle(c);
    expect(await c.read(sleepControllerProvider.notifier).fallAsleep(), isFalse);
    expect(repo.saved, isEmpty);
  });

  test('wakeUp ferme le plus ancien et supprime les doublons', () async {
    final first = makeSleep(id: 'a', startAt: DateTime(2026, 9, 23, 20));
    final dup = makeSleep(id: 'b', startAt: DateTime(2026, 9, 23, 20, 1));
    final repo = FakeSleepRepository([first, dup]);
    final c = containerWith(repo);
    await settle(c);
    expect(await c.read(sleepControllerProvider.notifier).wakeUp(), isTrue);
    expect(repo.lastWakeUp!.close.endAt, now);
    expect(repo.lastWakeUp!.close.id, 'a');
    expect(repo.lastWakeUp!.deleteIds, ['b']);
  });

  test('save refuse un chevauchement et expose l\'échec', () async {
    final other = makeSleep(id: 'o', startAt: DateTime(2026, 9, 23, 14), endAt: DateTime(2026, 9, 23, 15));
    final repo = FakeSleepRepository([other]);
    final c = containerWith(repo);
    await settle(c);
    final draft = makeSleep(id: 'n', startAt: DateTime(2026, 9, 23, 14, 30), endAt: DateTime(2026, 9, 23, 16));
    expect(await c.read(sleepControllerProvider.notifier).save(draft), isNull);
    expect(c.read(sleepControllerProvider).error, isA<SleepOverlapFailure>());
    expect(repo.saved, isEmpty);
  });

  test('save enregistre un sommeil valide avec updatedAt = maintenant', () async {
    final repo = FakeSleepRepository();
    final c = containerWith(repo);
    await settle(c);
    final draft = makeSleep(id: 'n', startAt: DateTime(2026, 9, 23, 14), endAt: DateTime(2026, 9, 23, 15));
    final saved = await c.read(sleepControllerProvider.notifier).save(draft);
    expect(saved, draft.copyWith(updatedAt: now));
    expect(repo.saved.single, draft.copyWith(updatedAt: now));
  });

  test('delete supprime et renvoie true', () async {
    final repo = FakeSleepRepository([makeSleep(id: 'x', startAt: DateTime(2026, 9, 23, 14), endAt: DateTime(2026, 9, 23, 15))]);
    final c = containerWith(repo);
    await settle(c);
    expect(await c.read(sleepControllerProvider.notifier).delete('x'), isTrue);
    expect(repo.deleted, ['x']);
  });
}
```

- [ ] **Step 4: Vérifier l'échec** — Run: `dart run build_runner build -d && flutter test test/features/sleep/presentation/sleep_controller_test.dart` → FAIL (contrôleur absent).

- [ ] **Step 5: Implémenter** `lib/features/sleep/presentation/providers/sleep_controller.dart` :

```dart
import 'dart:async';

import 'package:colette/core/clock/app_clock.dart';
import 'package:colette/core/ids/id_generator.dart';
import 'package:colette/core/result/failure.dart';
import 'package:colette/features/baby/domain/entities/care_settings.dart';
import 'package:colette/features/baby/presentation/providers/baby_providers.dart';
import 'package:colette/features/household/presentation/providers/household_providers.dart';
import 'package:colette/features/sleep/domain/entities/sleep_session.dart';
import 'package:colette/features/sleep/domain/entities/sleep_status.dart';
import 'package:colette/features/sleep/domain/use_cases/classify_sleep_kind.dart';
import 'package:colette/features/sleep/domain/use_cases/compute_sleep_summary.dart';
import 'package:colette/features/sleep/domain/use_cases/plan_wake_up.dart';
import 'package:colette/features/sleep/domain/use_cases/validate_sleep_session.dart';
import 'package:colette/features/sleep/presentation/providers/sleep_providers.dart';
import 'package:fpdart/fpdart.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'sleep_controller.g.dart';

/// Endormissement, réveil, saisie et suppression d'un sommeil.
@riverpod
class SleepController extends _$SleepController {
  /// Marge au-delà de `now` pour la recherche des sommeils voisins.
  static const _neighbourMargin = Duration(minutes: 2);

  @override
  FutureOr<void> build() {}

  /// Lance un sommeil maintenant ; `false` si un sommeil est déjà en cours.
  Future<bool> fallAsleep() async {
    final status = ref.read(sleepSummaryProvider)?.status;
    if (status is! Awake) return false;
    final now = ref.read(clockProvider).now();
    final settings =
        ref.read(babyProfileProvider).value?.careSettings ??
        const CareSettings();
    final session = SleepSession(
      id: ref.read(idGeneratorProvider).newId(),
      startAt: now,
      kind: classifySleepKind(
        now,
        nightStartHour: settings.nightStartHour,
        nightEndHour: settings.nightEndHour,
      ),
      createdByDeviceId: ref.read(deviceIdProvider),
      createdAt: now,
      updatedAt: now,
    );
    return _run((code) => ref.read(sleepRepositoryProvider).save(code, session));
  }

  /// Termine le sommeil en cours maintenant et supprime les doublons ouverts.
  Future<bool> wakeUp() async {
    final open = openSleeps(
      ref.read(recentSleepsProvider).value ?? const [],
      ref.read(latestSleepProvider).value,
    );
    final plan = planWakeUp(open, ref.read(clockProvider).now());
    if (plan == null) return false;
    return _run(
      (code) => ref
          .read(sleepRepositoryProvider)
          .wakeUp(code, close: plan.close, deleteIds: plan.deleteIds),
    );
  }

  /// Valide puis enregistre [draft]. Renvoie le sommeil enregistré, ou `null`.
  Future<SleepSession?> save(SleepSession draft) async {
    final code = ref.read(currentHouseholdCodeProvider);
    final profile = ref.read(babyProfileProvider).value;
    if (code == null || profile == null) return null;
    final repo = ref.read(sleepRepositoryProvider);
    final now = ref.read(clockProvider).now();
    final session = draft.copyWith(updatedAt: now);
    state = const AsyncLoading();
    final neighbours = await repo.getStartedBetween(
      code,
      from: session.startAt.subtract(ValidateSleepSession.maxDuration),
      to: now.add(_neighbourMargin),
    );
    final result = await neighbours
        .flatMap(
          (others) => const ValidateSleepSession()(
            session,
            now: now,
            birthDate: profile.birthDate,
            others: others,
          ),
        )
        .match<Future<Either<Failure, SleepSession>>>(
          (failure) async => left(failure),
          (valid) async => (await repo.save(code, valid)).map((_) => valid),
        );
    if (ref.mounted) {
      state = result.fold(
        (failure) => AsyncError(failure, StackTrace.current),
        (_) => const AsyncData(null),
      );
    }
    return result.getRight().toNullable();
  }

  Future<bool> delete(String sessionId) => _run(
    (code) => ref.read(sleepRepositoryProvider).delete(code, sessionId),
  );

  Future<bool> _run(
    Future<Either<Failure, void>> Function(String code) action,
  ) async {
    final code = ref.read(currentHouseholdCodeProvider);
    if (code == null) return false;
    state = const AsyncLoading();
    final result = await action(code);
    if (ref.mounted) {
      state = result.fold(
        (failure) => AsyncError(failure, StackTrace.current),
        (_) => const AsyncData(null),
      );
    }
    return result.isRight();
  }
}
```

(Si `Either.flatMap` refuse le type `Either<ValidationFailure…>` renvoyé, `ValidateSleepSession` renvoie déjà `Either<Failure, SleepSession>` : aucune conversion nécessaire.)

- [ ] **Step 6: Test rouge des providers** `test/features/sleep/presentation/sleep_providers_test.dart` :

```dart
import 'package:colette/core/clock/app_clock.dart';
import 'package:colette/core/clock/now_providers.dart';
import 'package:colette/features/baby/domain/entities/baby_profile.dart';
import 'package:colette/features/baby/presentation/providers/baby_providers.dart';
import 'package:colette/features/household/presentation/providers/household_providers.dart';
import 'package:colette/features/sleep/domain/entities/sleep_age_band.dart';
import 'package:colette/features/sleep/domain/entities/sleep_status.dart';
import 'package:colette/features/sleep/presentation/providers/sleep_providers.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../helpers/fake_sleep_repository.dart';
import '../../../helpers/in_memory_household_local_store.dart';
import '../../../helpers/sleep_session_factory.dart';

void main() {
  final now = DateTime(2026, 9, 23, 16);

  test('sleepSummary et sleepAgeBand combinent flux, horloge et profil', () async {
    final ongoing = makeSleep(id: 'o', startAt: DateTime(2026, 9, 23, 15));
    final container = ProviderContainer(
      overrides: [
        sleepRepositoryProvider.overrideWithValue(FakeSleepRepository([ongoing])),
        clockProvider.overrideWithValue(FixedClock(now)),
        minuteTickerProvider.overrideWith((ref) => const Stream.empty()),
        householdLocalStoreProvider.overrideWithValue(InMemoryHouseholdLocalStore(householdCode: 'ABCDEFGH')),
        babyProfileProvider.overrideWith((ref) => Stream.value(BabyProfile(name: 'C', birthDate: DateTime(2026, 9, 1)))),
      ],
    );
    addTearDown(container.dispose);
    container.listen(sleepSummaryProvider, (_, _) {});
    container.listen(sleepAgeBandProvider, (_, _) {});
    await container.read(recentSleepsProvider.future);
    await container.read(latestSleepProvider.future);
    await container.read(babyProfileProvider.future);
    final summary = container.read(sleepSummaryProvider)!;
    expect(summary.status, SleepStatus.asleep(ongoing));
    expect(summary.last24h, const Duration(hours: 1));
    expect(container.read(sleepAgeBandProvider), SleepAgeBand.under4Months);
  });
}
```

- [ ] **Step 7: Vérifier** — Run: `flutter test test/features/sleep/presentation` → PASS ; `dart analyze` → aucun problème (riverpod_lint compris).

- [ ] **Step 8: Commit**

```bash
git add lib/features/sleep/presentation/providers test/helpers/fake_sleep_repository.dart test/features/sleep/presentation/sleep_controller_test.dart test/features/sleep/presentation/sleep_providers_test.dart
git commit -m "feat: providers et contrôleur du sommeil"
```

---

### Task 11: `sleep_ui.dart` et `SleepFormSheet`

**Files:**
- Create: `lib/features/sleep/presentation/sleep_ui.dart`
- Create: `lib/features/sleep/presentation/widgets/sleep_form_sheet.dart`
- Test: `test/features/sleep/presentation/sleep_ui_test.dart`, `test/features/sleep/presentation/sleep_form_sheet_test.dart`

- [ ] **Step 1: Test rouge du format** `test/features/sleep/presentation/sleep_ui_test.dart` :

```dart
import 'package:colette/features/sleep/presentation/sleep_ui.dart';
import 'package:colette/l10n/generated/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  final s = lookupS(const Locale('fr'));

  test('formatSleepDuration', () {
    expect(formatSleepDuration(const Duration(minutes: 42), s), '42 min');
    expect(formatSleepDuration(const Duration(hours: 2), s), '2 h');
    expect(formatSleepDuration(const Duration(hours: 1, minutes: 5), s), '1 h 05');
    expect(formatSleepDuration(const Duration(hours: 13, minutes: 40), s), '13 h 40');
    expect(formatSleepDuration(const Duration(seconds: 30), s), '0 min');
  });
}
```

- [ ] **Step 2: Implémenter** `lib/features/sleep/presentation/sleep_ui.dart` :

```dart
import 'package:colette/core/theme/app_colors.dart';
import 'package:colette/features/sleep/domain/entities/sleep_kind.dart';
import 'package:colette/l10n/generated/app_localizations.dart';

/// Libellé et couleur d'un [SleepKind].
extension SleepKindUi on SleepKind {
  String label(S s) => switch (this) {
    SleepKind.nap => s.sleepKindNap,
    SleepKind.night => s.sleepKindNight,
  };

  /// Couleur de remplissage sur la frise.
  AppColors get fill => switch (this) {
    SleepKind.nap => AppColors.sleepNap,
    SleepKind.night => AppColors.sleepNight,
  };
}

/// « 42 min », « 2 h », « 1 h 05 ».
String formatSleepDuration(Duration duration, S s) {
  final minutes = duration.inMinutes;
  if (minutes < Duration.minutesPerHour) return s.durationMinutes(minutes);
  final hours = minutes ~/ Duration.minutesPerHour;
  final rest = minutes % Duration.minutesPerHour;
  if (rest == 0) return s.durationHours(hours);
  return s.durationHoursMinutes(hours, rest.toString().padLeft(2, '0'));
}
```

Run: `flutter test test/features/sleep/presentation/sleep_ui_test.dart` → PASS.

- [ ] **Step 3: Test rouge du formulaire** `test/features/sleep/presentation/sleep_form_sheet_test.dart` :

```dart
import 'package:colette/core/clock/app_clock.dart';
import 'package:colette/core/clock/now_providers.dart';
import 'package:colette/core/ids/id_generator.dart';
import 'package:colette/features/baby/domain/entities/baby_profile.dart';
import 'package:colette/features/baby/presentation/providers/baby_providers.dart';
import 'package:colette/features/household/presentation/providers/household_providers.dart';
import 'package:colette/features/sleep/domain/entities/sleep_kind.dart';
import 'package:colette/features/sleep/presentation/providers/sleep_providers.dart';
import 'package:colette/features/sleep/presentation/widgets/sleep_form_sheet.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:flutter_test/flutter_test.dart';

import '../../../helpers/fake_sleep_repository.dart';
import '../../../helpers/in_memory_household_local_store.dart';
import '../../../helpers/pump_app.dart';
import '../../../helpers/sleep_session_factory.dart';

void main() {
  final now = DateTime(2026, 9, 23, 16);

  List<Override> overrides(FakeSleepRepository repo) => [
    sleepRepositoryProvider.overrideWithValue(repo),
    clockProvider.overrideWithValue(FixedClock(now)),
    minuteTickerProvider.overrideWith((ref) => const Stream.empty()),
    idGeneratorProvider.overrideWithValue(const FixedIdGenerator('new')),
    householdLocalStoreProvider.overrideWithValue(InMemoryHouseholdLocalStore(householdCode: 'ABCDEFGH')),
    babyProfileProvider.overrideWith((ref) => Stream.value(BabyProfile(name: 'C', birthDate: DateTime(2026, 9, 1)))),
  ];

  Future<void> open(WidgetTester tester, FakeSleepRepository repo, {initial}) async {
    await pumpApp(
      tester,
      Builder(
        builder: (context) => TextButton(
          onPressed: () => showSleepFormSheet(context, initial: initial),
          child: const Text('ouvrir'),
        ),
      ),
      overrides: overrides(repo),
    );
    await tester.tap(find.text('ouvrir'));
    await tester.pumpAndSettle();
  }

  testWidgets('nouveau sommeil : 15h00 → 16h00, sieste, enregistré', (tester) async {
    final repo = FakeSleepRepository();
    await open(tester, repo);
    expect(find.text('Nouveau sommeil'), findsOneWidget);
    expect(find.text('15h00'), findsOneWidget);
    expect(find.text('16h00'), findsOneWidget);
    await tester.tap(find.text('Enregistrer'));
    await tester.pumpAndSettle();
    final saved = repo.saved.single;
    expect(saved.id, 'new');
    expect(saved.kind, SleepKind.nap);
    expect(find.text('Nouveau sommeil'), findsNothing);
  });

  testWidgets('chevauchement : message dans le formulaire, rien d\'écrit', (tester) async {
    final repo = FakeSleepRepository([
      makeSleep(id: 'o', startAt: DateTime(2026, 9, 23, 14, 10), endAt: DateTime(2026, 9, 23, 15, 30)),
    ]);
    await open(tester, repo);
    await tester.tap(find.text('Enregistrer'));
    await tester.pumpAndSettle();
    expect(find.text('Chevauche le sommeil de 14h10 à 15h30.'), findsOneWidget);
    expect(repo.saved, isEmpty);
  });

  testWidgets('édition : Nuit sélectionnée et suppression confirmée', (tester) async {
    final existing = makeSleep(id: 'x', kind: SleepKind.night, startAt: DateTime(2026, 9, 23, 2), endAt: DateTime(2026, 9, 23, 5));
    final repo = FakeSleepRepository([existing]);
    await open(tester, repo, initial: existing);
    expect(find.text('Modifier le sommeil'), findsOneWidget);
    await tester.tap(find.text('Supprimer'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Supprimer').last);
    await tester.pumpAndSettle();
    expect(repo.deleted, ['x']);
  });

  testWidgets('sommeil en cours : fin affichée « En cours »', (tester) async {
    final ongoing = makeSleep(id: 'o', startAt: DateTime(2026, 9, 23, 15));
    await open(tester, FakeSleepRepository([ongoing]), initial: ongoing);
    expect(find.text('En cours'), findsOneWidget);
  });
}
```

- [ ] **Step 4: Vérifier l'échec** — Run: `flutter test test/features/sleep/presentation/sleep_form_sheet_test.dart` → FAIL.

- [ ] **Step 5: Implémenter** `lib/features/sleep/presentation/widgets/sleep_form_sheet.dart` :

```dart
import 'package:colette/core/clock/app_clock.dart';
import 'package:colette/core/dates/time_format.dart';
import 'package:colette/core/ids/id_generator.dart';
import 'package:colette/core/theme/app_colors.dart';
import 'package:colette/core/theme/design_tokens.dart';
import 'package:colette/core/theme/text_styles.dart';
import 'package:colette/core/ui/date_time_picker.dart';
import 'package:colette/core/ui/failure_message.dart';
import 'package:colette/features/baby/domain/entities/care_settings.dart';
import 'package:colette/features/baby/presentation/providers/baby_providers.dart';
import 'package:colette/features/household/presentation/providers/household_providers.dart';
import 'package:colette/features/sleep/domain/entities/sleep_kind.dart';
import 'package:colette/features/sleep/domain/entities/sleep_session.dart';
import 'package:colette/features/sleep/domain/use_cases/classify_sleep_kind.dart';
import 'package:colette/features/sleep/presentation/providers/sleep_controller.dart';
import 'package:colette/features/sleep/presentation/sleep_ui.dart';
import 'package:colette/l10n/generated/app_localizations.dart';
import 'package:colette/shared/ui/widgets/date_field.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Ouvre le formulaire du sommeil. Renvoie `true` après enregistrement ou suppression.
Future<bool?> showSleepFormSheet(
  BuildContext context, {
  SleepSession? initial,
}) => showModalBottomSheet<bool>(
  context: context,
  isScrollControlled: true,
  useSafeArea: true,
  builder: (_) => SleepFormSheet(initial: initial),
);

/// Formulaire de création ou d'édition d'un sommeil.
class SleepFormSheet extends ConsumerStatefulWidget {
  const SleepFormSheet({super.key, this.initial});

  final SleepSession? initial;

  @override
  ConsumerState<SleepFormSheet> createState() => _SleepFormSheetState();
}

class _SleepFormSheetState extends ConsumerState<SleepFormSheet> {
  /// Durée pré-remplie d'un nouveau sommeil.
  static const _defaultLength = Duration(hours: 1);

  late DateTime _startAt;
  DateTime? _endAt;
  late SleepKind _kind;
  bool _kindTouched = false;

  bool get _isEditing => widget.initial != null;

  CareSettings get _settings =>
      ref.read(babyProfileProvider).value?.careSettings ?? const CareSettings();

  SleepKind _classify(DateTime start) => classifySleepKind(
    start,
    nightStartHour: _settings.nightStartHour,
    nightEndHour: _settings.nightEndHour,
  );

  @override
  void initState() {
    super.initState();
    final now = ref.read(clockProvider).now();
    final initial = widget.initial;
    _startAt = initial?.startAt ?? now.subtract(_defaultLength);
    _endAt = initial == null ? now : initial.endAt;
    _kind = initial?.kind ?? _classify(_startAt);
    _kindTouched = initial != null;
  }

  Future<void> _pickStart() async {
    final picked = await showColetteDateTimePicker(
      context,
      initial: _startAt,
      mode: CupertinoDatePickerMode.dateAndTime,
      maximum: ref.read(clockProvider).now(),
    );
    if (picked == null) return;
    setState(() {
      _startAt = picked;
      if (!_kindTouched) _kind = _classify(picked);
    });
  }

  Future<void> _pickEnd() async {
    final picked = await showColetteDateTimePicker(
      context,
      initial: _endAt ?? ref.read(clockProvider).now(),
      mode: CupertinoDatePickerMode.dateAndTime,
      minimum: _startAt,
      maximum: ref.read(clockProvider).now(),
    );
    if (picked == null) return;
    setState(() => _endAt = picked);
  }

  Future<void> _save() async {
    final now = ref.read(clockProvider).now();
    final initial = widget.initial;
    final draft = SleepSession(
      id: initial?.id ?? ref.read(idGeneratorProvider).newId(),
      startAt: _startAt,
      endAt: _endAt,
      kind: _kind,
      createdByDeviceId: initial?.createdByDeviceId ?? ref.read(deviceIdProvider),
      createdAt: initial?.createdAt ?? now,
      updatedAt: now,
    );
    final saved = await ref.read(sleepControllerProvider.notifier).save(draft);
    if (saved != null && mounted) await Navigator.of(context).maybePop(true);
  }

  Future<void> _delete() async {
    final s = S.of(context);
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(s.deleteSleepTitle),
        content: Text(s.deleteEventBody),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: Text(s.actionCancel),
          ),
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: Text(s.actionDelete),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    final deleted = await ref
        .read(sleepControllerProvider.notifier)
        .delete(widget.initial!.id);
    if (deleted && mounted) await Navigator.of(context).maybePop(true);
  }

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    final styles = Theme.of(context).coletteTextStyles;
    final controller = ref.watch(sleepControllerProvider);
    final isLoading = controller is AsyncLoading;
    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(context).bottom),
      child: ListView(
        shrinkWrap: true,
        padding: AppSpacing.lg.all,
        children: [
          Text(
            _isEditing ? s.sleepFormEditTitle : s.sleepFormNewTitle,
            style: styles.heading2,
          ),
          AppSpacing.md.verticalSpace,
          Row(
            spacing: AppSpacing.sm.value,
            children: [
              Expanded(
                child: DateField(
                  label: s.fieldStartAt,
                  value: formatHourMinute(_startAt),
                  onTap: _pickStart,
                ),
              ),
              Expanded(
                child: DateField(
                  label: s.fieldEndAt,
                  value: switch (_endAt) {
                    null => s.sleepOngoing,
                    final end => formatHourMinute(end),
                  },
                  onTap: _pickEnd,
                ),
              ),
            ],
          ),
          AppSpacing.md.verticalSpace,
          SegmentedButton<SleepKind>(
            segments: [
              for (final kind in SleepKind.values)
                ButtonSegment(value: kind, label: Text(kind.label(s))),
            ],
            selected: {_kind},
            onSelectionChanged: (selection) => setState(() {
              _kind = selection.single;
              _kindTouched = true;
            }),
          ),
          if (controller case AsyncError(:final error)) ...[
            AppSpacing.md.verticalSpace,
            Text(
              failureMessage(error, s),
              style: styles.small.copyWith(
                color: context.appColor(AppColors.error),
              ),
            ),
          ],
          AppSpacing.lg.verticalSpace,
          FilledButton(
            onPressed: isLoading ? null : _save,
            child: Text(s.actionSave),
          ),
          if (_isEditing) ...[
            AppSpacing.sm.verticalSpace,
            TextButton(
              onPressed: isLoading ? null : _delete,
              style: TextButton.styleFrom(
                foregroundColor: context.appColor(AppColors.error),
              ),
              child: Text(s.actionDelete),
            ),
          ],
        ],
      ),
    );
  }
}
```

- [ ] **Step 6: Vérifier** — Run: `flutter test test/features/sleep/presentation` → PASS ; `dart analyze` → propre.

- [ ] **Step 7: Commit**

```bash
git add lib/features/sleep/presentation/sleep_ui.dart lib/features/sleep/presentation/widgets/sleep_form_sheet.dart test/features/sleep/presentation/sleep_ui_test.dart test/features/sleep/presentation/sleep_form_sheet_test.dart
git commit -m "feat: formulaire du sommeil (début, fin, sieste ou nuit, suppression)"
```

---

### Task 12: `SleepCard` sur l'accueil, route `/today/sleep`

**Files:**
- Create: `lib/features/sleep/presentation/widgets/sleep_card.dart`
- Create: `lib/features/sleep/presentation/pages/sleep_page.dart` (squelette, complété en Task 13)
- Modify: `lib/app/router/app_router.dart`
- Modify: `lib/features/dashboard/presentation/pages/dashboard_page.dart`
- Modify: `test/features/dashboard/presentation/dashboard_page_test.dart`
- Test: `test/features/sleep/presentation/sleep_card_test.dart`

- [ ] **Step 1: Route et page squelette.** Créer `sleep_page.dart` :

```dart
import 'package:colette/l10n/generated/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Page Sommeil : frise des 7 derniers jours et détail du jour choisi.
class SleepPage extends ConsumerStatefulWidget {
  const SleepPage({super.key});

  @override
  ConsumerState<SleepPage> createState() => _SleepPageState();
}

class _SleepPageState extends ConsumerState<SleepPage> {
  @override
  Widget build(BuildContext context) =>
      Scaffold(appBar: AppBar(title: Text(S.of(context).sleepPageTitle)));
}
```

Dans `AppRoutes`, après `weights` :

```dart
  /// Page Sommeil, imbriquée sous Aujourd'hui pour garder la barre d'onglets.
  static const sleep = '/today/sleep';
```

Dans les `routes` de `/today`, après `weights` : `GoRoute(path: 'sleep', builder: (_, _) => const SleepPage()),` et l'import de `sleep_page.dart`. Puis `dart run build_runner build -d`.

- [ ] **Step 2: Test rouge de la carte** `test/features/sleep/presentation/sleep_card_test.dart` :

```dart
import 'package:colette/core/clock/app_clock.dart';
import 'package:colette/core/clock/now_providers.dart';
import 'package:colette/core/ids/id_generator.dart';
import 'package:colette/features/baby/domain/entities/baby_profile.dart';
import 'package:colette/features/baby/presentation/providers/baby_providers.dart';
import 'package:colette/features/household/presentation/providers/household_providers.dart';
import 'package:colette/features/sleep/domain/entities/sleep_kind.dart';
import 'package:colette/features/sleep/presentation/providers/sleep_providers.dart';
import 'package:colette/features/sleep/presentation/widgets/sleep_card.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:flutter_test/flutter_test.dart';

import '../../../helpers/fake_sleep_repository.dart';
import '../../../helpers/in_memory_household_local_store.dart';
import '../../../helpers/pump_app.dart';
import '../../../helpers/sleep_session_factory.dart';

void main() {
  final now = DateTime(2026, 9, 23, 14, 47);

  List<Override> overrides(FakeSleepRepository repo, {DateTime? birth}) => [
    sleepRepositoryProvider.overrideWithValue(repo),
    clockProvider.overrideWithValue(FixedClock(now)),
    minuteTickerProvider.overrideWith((ref) => const Stream.empty()),
    idGeneratorProvider.overrideWithValue(const FixedIdGenerator('new')),
    householdLocalStoreProvider.overrideWithValue(InMemoryHouseholdLocalStore(householdCode: 'ABCDEFGH')),
    babyProfileProvider.overrideWith((ref) => Stream.value(BabyProfile(name: 'C', birthDate: birth ?? DateTime(2026, 9, 1)))),
  ];

  Future<void> pump(WidgetTester tester, FakeSleepRepository repo, {DateTime? birth}) =>
      pumpApp(tester, const Scaffold(body: SleepCard()), overrides: overrides(repo, birth: birth));

  testWidgets('endormi·e : durée, type, heure, bouton Réveillé·e', (tester) async {
    final repo = FakeSleepRepository([makeSleep(id: 'o', startAt: DateTime(2026, 9, 23, 14, 5))]);
    await pump(tester, repo);
    expect(find.text('Dort depuis 42 min'), findsOneWidget);
    expect(find.text('Sieste · depuis 14h05'), findsOneWidget);
    expect(find.text('Sur 24 h : 42 min · repère OMS 14 à 17 h'), findsOneWidget);
    await tester.tap(find.text('Réveillé·e'));
    await tester.pumpAndSettle();
    expect(repo.lastWakeUp!.close.endAt, now);
  });

  testWidgets('éveillé·e : depuis la fin du dernier sommeil, bouton Endormi·e', (tester) async {
    final repo = FakeSleepRepository([
      makeSleep(id: 'a', startAt: DateTime(2026, 9, 23, 12), endAt: DateTime(2026, 9, 23, 13, 37)),
    ]);
    await pump(tester, repo);
    expect(find.text('Éveillé·e depuis 1 h 10'), findsOneWidget);
    await tester.tap(find.text('Endormi·e'));
    await tester.pumpAndSettle();
    expect(repo.saved.single.endAt, isNull);
  });

  testWidgets('aucun sommeil : invitation', (tester) async {
    await pump(tester, FakeSleepRepository());
    expect(find.text('Aucun sommeil noté'), findsOneWidget);
    expect(find.text('Endormi·e'), findsOneWidget);
  });

  testWidgets('réveil oublié au-delà de 16 h', (tester) async {
    final repo = FakeSleepRepository([makeSleep(id: 'o', kind: SleepKind.night, startAt: DateTime(2026, 9, 22, 21))]);
    await pump(tester, repo);
    expect(find.text('Réveil oublié ?'), findsOneWidget);
    await tester.tap(find.text('Saisir le réveil'));
    await tester.pumpAndSettle();
    expect(find.text('Modifier le sommeil'), findsOneWidget);
  });

  testWidgets('au-delà de 2 ans : total sans repère OMS', (tester) async {
    await pump(tester, FakeSleepRepository(), birth: DateTime(2024, 1, 1));
    expect(find.text('Sur 24 h : 0 min'), findsOneWidget);
  });
}
```

- [ ] **Step 3: Vérifier l'échec** — Run: `flutter test test/features/sleep/presentation/sleep_card_test.dart` → FAIL.

- [ ] **Step 4: Implémenter** `lib/features/sleep/presentation/widgets/sleep_card.dart` :

```dart
import 'package:colette/app/router/app_router.dart';
import 'package:colette/core/clock/now_providers.dart';
import 'package:colette/core/dates/time_format.dart';
import 'package:colette/core/theme/app_colors.dart';
import 'package:colette/core/theme/design_tokens.dart';
import 'package:colette/core/theme/text_styles.dart';
import 'package:colette/core/ui/failure_message.dart';
import 'package:colette/features/sleep/domain/entities/sleep_status.dart';
import 'package:colette/features/sleep/presentation/providers/sleep_controller.dart';
import 'package:colette/features/sleep/presentation/providers/sleep_providers.dart';
import 'package:colette/features/sleep/presentation/sleep_ui.dart';
import 'package:colette/features/sleep/presentation/widgets/sleep_form_sheet.dart';
import 'package:colette/l10n/generated/app_localizations.dart';
import 'package:colette/shared/ui/widgets/colette_card_surface.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

/// Carte « Sommeil » de l'accueil : état actuel, chrono, total sur 24 h.
class SleepCard extends ConsumerWidget {
  const SleepCard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final s = S.of(context);
    ref.listen(sleepControllerProvider, (_, next) {
      if (next case AsyncError(:final error)) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(failureMessage(error, s))));
      }
    });
    // Garde le contrôleur autoDispose vivant pendant l'await des boutons.
    final isLoading = ref.watch(sleepControllerProvider) is AsyncLoading;
    final summary = ref.watch(sleepSummaryProvider);
    if (summary == null) return const SizedBox.shrink();
    return Padding(
      padding: AppSpacing.md.top,
      child: ColetteCardSurface(
        onTap: () => context.push(AppRoutes.sleep),
        child: Column(
          crossAxisAlignment: .stretch,
          spacing: AppSpacing.sm.value,
          children: [
            const _Header(),
            _StatusSection(status: summary.status, isLoading: isLoading),
            _TotalLine(last24h: summary.last24h),
          ],
        ),
      ),
    );
  }
}

class _Header extends StatelessWidget {
  const _Header();

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    final primary = context.appColor(AppColors.primary);
    return Row(
      spacing: AppSpacing.xs.value,
      children: [
        Icon(Icons.bedtime_outlined, size: AppSize.xs.value, color: primary),
        Expanded(
          child: Text(
            s.sleepCardTitle,
            style: Theme.of(context).coletteTextStyles.overline
                .copyWith(color: primary),
          ),
        ),
        IconButton(
          onPressed: () => showSleepFormSheet(context),
          icon: const Icon(Icons.add),
          color: primary,
          tooltip: s.sleepAddPast,
        ),
        Icon(
          Icons.chevron_right,
          color: context.appColor(AppColors.textSecondary),
        ),
      ],
    );
  }
}

class _StatusSection extends ConsumerWidget {
  const _StatusSection({required this.status, required this.isLoading});

  final SleepStatus status;
  final bool isLoading;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final s = S.of(context);
    final styles = Theme.of(context).coletteTextStyles;
    final secondary = context.appColor(AppColors.textSecondary);
    final now = ref.watch(currentMinuteProvider);
    return Column(
      crossAxisAlignment: .stretch,
      spacing: AppSpacing.xs.value,
      children: switch (status) {
        Asleep(:final session) => [
          Text(
            s.sleepAsleepFor(formatSleepDuration(now.difference(session.startAt), s)),
            style: styles.heading2,
          ),
          Text(
            s.sleepAsleepSince(session.kind.label(s), formatHourMinute(session.startAt)),
            style: styles.small.copyWith(color: secondary),
          ),
          FilledButton(
            onPressed: isLoading
                ? null
                : () => ref.read(sleepControllerProvider.notifier).wakeUp(),
            child: Text(s.sleepWakeUpAction),
          ),
        ],
        ForgottenWake(:final session) => [
          Text(
            s.sleepAsleepFor(formatSleepDuration(now.difference(session.startAt), s)),
            style: styles.heading2,
          ),
          Text(
            s.sleepForgottenWake,
            style: styles.small.copyWith(color: context.appColor(AppColors.warning)),
          ),
          FilledButton(
            onPressed: () => showSleepFormSheet(context, initial: session),
            child: Text(s.sleepEnterWakeAction),
          ),
        ],
        Awake(:final since) => [
          Text(
            switch (since) {
              null => s.sleepNoneYet,
              final since => s.sleepAwakeFor(formatSleepDuration(now.difference(since), s)),
            },
            style: styles.heading2,
          ),
          OutlinedButton(
            onPressed: isLoading
                ? null
                : () => ref.read(sleepControllerProvider.notifier).fallAsleep(),
            child: Text(s.sleepFallAsleepAction),
          ),
        ],
      },
    );
  }
}

class _TotalLine extends ConsumerWidget {
  const _TotalLine({required this.last24h});

  final Duration last24h;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final s = S.of(context);
    final band = ref.watch(sleepAgeBandProvider);
    final total = formatSleepDuration(last24h, s);
    return Text(
      band == null
          ? s.sleepLast24h(total)
          : s.sleepLast24hWithReference(total, band.minHours, band.maxHours),
      style: Theme.of(context).coletteTextStyles.small
          .copyWith(color: context.appColor(AppColors.textSecondary)),
    );
  }
}
```

Note : `SleepCard` fait `ref.watch(sleepControllerProvider)` ; `_StatusSection` est un descendant, donc le contrôleur auto-dispose reste en vie pendant l'`await` des boutons.

- [ ] **Step 5: Accueil.** Dans `dashboard_page.dart`, importer `sleep_card.dart` et insérer `const SleepCard(),` juste après `const NextBottleCard(),`. Mettre à jour le `///` de la classe : `/// Onglet Aujourd'hui : âge, prochain biberon, sommeil, reste à faire, compteurs, poids, documents.`

- [ ] **Step 6: Test existant de l'accueil.** Dans `test/features/dashboard/presentation/dashboard_page_test.dart`, importer `sleep_providers.dart` et `../../../helpers/fake_sleep_repository.dart`, puis ajouter à la liste `overridesFor` : `sleepRepositoryProvider.overrideWithValue(FakeSleepRepository()),`. Ajouter un test :

```dart
  testWidgets('affiche la carte Sommeil sous le prochain biberon', (tester) async {
    final repo = MockEventsRepository();
    await pumpApp(tester, const DashboardPage(), overrides: overridesFor(repo));
    expect(find.text('Sommeil'), findsOneWidget);
    expect(find.text('Aucun sommeil noté'), findsOneWidget);
  });
```

La carte ajoute de la hauteur sous « Prochain biberon » : si un test existant de `dashboard_page_test.dart` ne trouve plus un élément situé plus bas (compteurs, tâches), le faire défiler avec `await tester.scrollUntilVisible(find.text('…'), 200);` avant l'`expect`, comme le test fait déjà pour « Poids ».

- [ ] **Step 7: Vérifier**

```bash
dart run build_runner build -d
flutter test test/features/sleep test/features/dashboard test/app
dart analyze
```

Expected : PASS, aucun problème. (Les tests de `test/app` montent l'app avec `FakeFirebaseFirestore` : le dépôt Firestore réel du sommeil y fonctionne sans override.)

- [ ] **Step 8: Commit**

```bash
git add lib/features/sleep/presentation/widgets/sleep_card.dart lib/features/sleep/presentation/pages/sleep_page.dart lib/app/router/app_router.dart lib/app/router/app_router.g.dart lib/features/dashboard/presentation/pages/dashboard_page.dart test/features/sleep/presentation/sleep_card_test.dart test/features/dashboard/presentation/dashboard_page_test.dart
git commit -m "feat: carte Sommeil sur l'accueil avec chrono partagé"
```

---

### Task 13: Page Sommeil (frise 7 jours, détail du jour)

**Files:**
- Create: `lib/features/sleep/presentation/widgets/sleep_week_chart.dart`
- Create: `lib/features/sleep/presentation/widgets/sleep_day_details.dart`
- Modify: `lib/features/sleep/presentation/pages/sleep_page.dart`
- Test: `test/features/sleep/presentation/sleep_page_test.dart`, `test/features/sleep/presentation/sleep_week_chart_test.dart`

- [ ] **Step 1: Tests rouges**

`test/features/sleep/presentation/sleep_week_chart_test.dart` :

```dart
import 'package:colette/features/sleep/presentation/widgets/sleep_week_chart.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('dayFraction place une heure sur la journée', () {
    final day = DateTime(2026, 9, 23);
    final next = DateTime(2026, 9, 24);
    expect(SleepRowPainter.dayFraction(day, day, next), 0);
    expect(SleepRowPainter.dayFraction(DateTime(2026, 9, 23, 6), day, next), 0.25);
    expect(SleepRowPainter.dayFraction(next, day, next), 1);
  });
}
```

`test/features/sleep/presentation/sleep_page_test.dart` :

```dart
import 'package:colette/core/clock/app_clock.dart';
import 'package:colette/core/clock/now_providers.dart';
import 'package:colette/features/baby/domain/entities/baby_profile.dart';
import 'package:colette/features/baby/presentation/providers/baby_providers.dart';
import 'package:colette/features/household/presentation/providers/household_providers.dart';
import 'package:colette/features/sleep/domain/entities/sleep_kind.dart';
import 'package:colette/features/sleep/presentation/pages/sleep_page.dart';
import 'package:colette/features/sleep/presentation/providers/sleep_providers.dart';
import 'package:colette/features/sleep/presentation/widgets/sleep_week_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../helpers/fake_sleep_repository.dart';
import '../../../helpers/in_memory_household_local_store.dart';
import '../../../helpers/pump_app.dart';
import '../../../helpers/sleep_session_factory.dart';

void main() {
  final now = DateTime(2026, 9, 23, 16);

  Future<void> pump(WidgetTester tester, FakeSleepRepository repo) => pumpApp(
    tester,
    const SleepPage(),
    overrides: [
      sleepRepositoryProvider.overrideWithValue(repo),
      clockProvider.overrideWithValue(FixedClock(now)),
      minuteTickerProvider.overrideWith((ref) => const Stream.empty()),
      householdLocalStoreProvider.overrideWithValue(InMemoryHouseholdLocalStore(householdCode: 'ABCDEFGH')),
      babyProfileProvider.overrideWith((ref) => Stream.value(BabyProfile(name: 'C', birthDate: DateTime(2026, 9, 1)))),
    ],
  );

  testWidgets('sept lignes, moyenne, repère et détail d\'aujourd\'hui', (tester) async {
    final repo = FakeSleepRepository([
      makeSleep(id: 'n', kind: SleepKind.night, startAt: DateTime(2026, 9, 22, 1), endAt: DateTime(2026, 9, 22, 15)),
      makeSleep(id: 'a', startAt: DateTime(2026, 9, 23, 9), endAt: DateTime(2026, 9, 23, 10, 30)),
    ]);
    await pump(tester, repo);
    expect(find.byType(SleepWeekRow), findsNWidgets(7));
    expect(find.text('Moyenne des jours précédents : 14 h'), findsOneWidget);
    expect(find.text('Repère OMS à son âge : 14 à 17 h sur 24 h'), findsOneWidget);
    expect(find.text('Mercredi 23 septembre'), findsOneWidget);
    expect(find.text('1 h 30'), findsWidgets);
  });

  testWidgets('toucher une ligne sélectionne le jour', (tester) async {
    await pump(tester, FakeSleepRepository([
      makeSleep(id: 'n', kind: SleepKind.night, startAt: DateTime(2026, 9, 22, 1), endAt: DateTime(2026, 9, 22, 15)),
    ]));
    await tester.tap(find.text('mar. 22'));
    await tester.pumpAndSettle();
    expect(find.text('Mardi 22 septembre'), findsOneWidget);
  });

  testWidgets('sans historique : pas de moyenne', (tester) async {
    await pump(tester, FakeSleepRepository());
    expect(find.textContaining('Moyenne'), findsNothing);
  });
}
```

- [ ] **Step 2: Vérifier l'échec** — Run: `flutter test test/features/sleep/presentation/sleep_page_test.dart test/features/sleep/presentation/sleep_week_chart_test.dart` → FAIL.

- [ ] **Step 3: Implémenter la frise** `lib/features/sleep/presentation/widgets/sleep_week_chart.dart` :

```dart
import 'package:colette/core/dates/time_format.dart';
import 'package:colette/core/theme/app_colors.dart';
import 'package:colette/core/theme/design_tokens.dart';
import 'package:colette/core/theme/text_styles.dart';
import 'package:colette/features/sleep/domain/entities/sleep_day.dart';
import 'package:colette/features/sleep/presentation/sleep_ui.dart';
import 'package:colette/l10n/generated/app_localizations.dart';
import 'package:flutter/material.dart';

/// Frise 0 h → 24 h : une ligne par jour, nuits et siestes colorées.
class SleepWeekChart extends StatelessWidget {
  const SleepWeekChart({
    super.key,
    required this.days,
    required this.selectedIndex,
    required this.onSelect,
  });

  final List<SleepDay> days;
  final int selectedIndex;
  final ValueChanged<int> onSelect;

  static const _axisHours = [0, 6, 12, 18, 24];

  @override
  Widget build(BuildContext context) {
    final muted = Theme.of(context).coletteTextStyles.label
        .copyWith(color: context.appColor(AppColors.textSecondary));
    return Column(
      crossAxisAlignment: .stretch,
      children: [
        Row(
          children: [
            SizedBox(width: AppSize.huge.value),
            Expanded(
              child: Row(
                mainAxisAlignment: .spaceBetween,
                children: [
                  for (final hour in _axisHours) Text('$hour', style: muted),
                ],
              ),
            ),
            SizedBox(width: AppSize.huge.value),
          ],
        ),
        for (var i = 0; i < days.length; i++)
          SleepWeekRow(
            day: days[i],
            selected: i == selectedIndex,
            onTap: () => onSelect(i),
          ),
      ],
    );
  }
}

/// Ligne d'un jour : libellé, segments, total.
class SleepWeekRow extends StatelessWidget {
  const SleepWeekRow({
    super.key,
    required this.day,
    required this.selected,
    required this.onTap,
  });

  final SleepDay day;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    final styles = Theme.of(context).coletteTextStyles;
    return Material(
      color: selected
          ? context.appColor(AppColors.primaryContainer)
          : Colors.transparent,
      borderRadius: AppRadius.sm.circular,
      child: InkWell(
        onTap: onTap,
        borderRadius: AppRadius.sm.circular,
        child: Padding(
          padding: AppSpacing.xs.vertical,
          child: Row(
            children: [
              SizedBox(
                width: AppSize.huge.value,
                child: Text(formatShortWeekday(day.day), style: styles.label),
              ),
              Expanded(
                child: SizedBox(
                  height: AppSize.xs.value,
                  child: CustomPaint(
                    painter: SleepRowPainter(
                      day: day,
                      track: context.appColor(AppColors.surfaceContainer),
                      night: context.appColor(AppColors.sleepNight),
                      nap: context.appColor(AppColors.sleepNap),
                    ),
                  ),
                ),
              ),
              SizedBox(
                width: AppSize.huge.value,
                child: Text(
                  formatSleepDuration(day.total, s),
                  textAlign: .end,
                  style: styles.label,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Dessine la piste d'un jour et ses segments de sommeil.
class SleepRowPainter extends CustomPainter {
  SleepRowPainter({
    required this.day,
    required this.track,
    required this.night,
    required this.nap,
  });

  final SleepDay day;
  final Color track;
  final Color night;
  final Color nap;

  /// Position de [time] dans `[dayStart, dayEnd]`, entre 0 et 1.
  static double dayFraction(DateTime time, DateTime dayStart, DateTime dayEnd) =>
      time.difference(dayStart).inMinutes / dayEnd.difference(dayStart).inMinutes;

  @override
  void paint(Canvas canvas, Size size) {
    final radius = AppRadius.xs.radius;
    canvas.drawRRect(
      RRect.fromRectAndRadius(Offset.zero & size, radius),
      Paint()..color = track,
    );
    final dayEnd = DateTime(day.day.year, day.day.month, day.day.day + 1);
    for (final segment in day.segments) {
      final left = dayFraction(segment.start, day.day, dayEnd) * size.width;
      final right = dayFraction(segment.end, day.day, dayEnd) * size.width;
      canvas.drawRRect(
        RRect.fromLTRBR(left, 0, right, size.height, radius),
        Paint()..color = segment.kind.fill == AppColors.sleepNight ? night : nap,
      );
    }
  }

  @override
  bool shouldRepaint(SleepRowPainter oldDelegate) =>
      oldDelegate.day != day ||
      oldDelegate.track != track ||
      oldDelegate.night != night ||
      oldDelegate.nap != nap;
}
```

(`Colors.transparent` est la seule exception tolérée ; si la règle de design la refuse, ajouter `AppColors.transparent(light: Color(0x00000000), dark: Color(0x00000000))` et l'utiliser.)

- [ ] **Step 4: Détail du jour** `lib/features/sleep/presentation/widgets/sleep_day_details.dart` :

```dart
import 'package:colette/core/dates/time_format.dart';
import 'package:colette/core/theme/app_colors.dart';
import 'package:colette/core/theme/design_tokens.dart';
import 'package:colette/core/theme/text_styles.dart';
import 'package:colette/features/sleep/domain/entities/sleep_day.dart';
import 'package:colette/features/sleep/presentation/sleep_ui.dart';
import 'package:colette/l10n/generated/app_localizations.dart';
import 'package:colette/shared/ui/widgets/colette_card_surface.dart';
import 'package:flutter/material.dart';

/// Total, siestes et plus longue période du jour sélectionné.
class SleepDayDetails extends StatelessWidget {
  const SleepDayDetails({super.key, required this.day});

  final SleepDay day;

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    final styles = Theme.of(context).coletteTextStyles;
    return ColetteCardSurface(
      child: Column(
        crossAxisAlignment: .stretch,
        spacing: AppSpacing.sm.value,
        children: [
          Text(formatLongDate(day.day), style: styles.heading3),
          _StatRow(label: s.sleepDayTotal, value: formatSleepDuration(day.total, s)),
          _StatRow(label: s.sleepDayNaps, value: '${day.napCount}'),
          _StatRow(label: s.sleepDayLongest, value: formatSleepDuration(day.longest, s)),
        ],
      ),
    );
  }
}

class _StatRow extends StatelessWidget {
  const _StatRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final styles = Theme.of(context).coletteTextStyles;
    return Row(
      children: [
        Expanded(
          child: Text(
            label,
            style: styles.body.copyWith(color: context.appColor(AppColors.textSecondary)),
          ),
        ),
        Text(value, style: styles.bodyMedium),
      ],
    );
  }
}
```

(Si `styles.heading3` n'existe pas dans `text_styles.dart`, utiliser le style de titre de section le plus proche, par exemple `heading2`.)

- [ ] **Step 5: Page complète** — remplacer `sleep_page.dart` :

```dart
import 'package:colette/core/theme/app_colors.dart';
import 'package:colette/core/theme/design_tokens.dart';
import 'package:colette/core/theme/text_styles.dart';
import 'package:colette/features/sleep/domain/entities/sleep_day.dart';
import 'package:colette/features/sleep/domain/use_cases/compute_sleep_days.dart';
import 'package:colette/features/sleep/presentation/providers/sleep_providers.dart';
import 'package:colette/features/sleep/presentation/sleep_ui.dart';
import 'package:colette/features/sleep/presentation/widgets/sleep_day_details.dart';
import 'package:colette/features/sleep/presentation/widgets/sleep_form_sheet.dart';
import 'package:colette/features/sleep/presentation/widgets/sleep_week_chart.dart';
import 'package:colette/l10n/generated/app_localizations.dart';
import 'package:colette/shared/ui/widgets/colette_card_surface.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Page Sommeil : frise des 7 derniers jours et détail du jour choisi.
class SleepPage extends ConsumerStatefulWidget {
  const SleepPage({super.key});

  @override
  ConsumerState<SleepPage> createState() => _SleepPageState();
}

class _SleepPageState extends ConsumerState<SleepPage> {
  /// Jour sélectionné ; aujourd'hui (dernière ligne) par défaut.
  int _selected = sleepWeekDayCount - 1;

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    final days = ref.watch(sleepWeekProvider);
    return Scaffold(
      appBar: AppBar(title: Text(s.sleepPageTitle)),
      floatingActionButton: FloatingActionButton(
        onPressed: () => showSleepFormSheet(context),
        tooltip: s.sleepAddPast,
        child: const Icon(Icons.add),
      ),
      body: switch (days) {
        null => const Center(child: CircularProgressIndicator()),
        final days => ListView(
          padding: AppSpacing.md.all,
          children: [
            _SummarySection(days: days),
            AppSpacing.md.verticalSpace,
            ColetteCardSurface(
              child: SleepWeekChart(
                days: days,
                selectedIndex: _selected,
                onSelect: (index) => setState(() => _selected = index),
              ),
            ),
            AppSpacing.md.verticalSpace,
            SleepDayDetails(day: days[_selected]),
            AppSpacing.xxl.verticalSpace,
          ],
        ),
      },
    );
  }
}

class _SummarySection extends ConsumerWidget {
  const _SummarySection({required this.days});

  final List<SleepDay> days;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final s = S.of(context);
    final styles = Theme.of(context).coletteTextStyles;
    final band = ref.watch(sleepAgeBandProvider);
    final average = averageOfPreviousDays(days);
    return Column(
      crossAxisAlignment: .start,
      spacing: AppSpacing.xs.value,
      children: [
        if (average != null)
          Text(s.sleepAverage(formatSleepDuration(average, s)), style: styles.bodyMedium),
        if (band != null)
          Text(
            s.sleepReference(band.minHours, band.maxHours),
            style: styles.small.copyWith(color: context.appColor(AppColors.textSecondary)),
          ),
      ],
    );
  }
}
```

- [ ] **Step 6: Vérifier** — Run: `flutter test test/features/sleep` → PASS ; `dart analyze` → propre.

- [ ] **Step 7: Commit**

```bash
git add lib/features/sleep/presentation/widgets/sleep_week_chart.dart lib/features/sleep/presentation/widgets/sleep_day_details.dart lib/features/sleep/presentation/pages/sleep_page.dart test/features/sleep/presentation/sleep_page_test.dart test/features/sleep/presentation/sleep_week_chart_test.dart
git commit -m "feat: page Sommeil avec frise des 7 derniers jours"
```

---

### Task 14: Journal mixte soins et sommeils

**Files:**
- Create: `lib/features/events/presentation/timeline_entry.dart`
- Create: `lib/features/sleep/presentation/widgets/sleep_tile.dart`
- Modify: `lib/features/events/presentation/timeline_grouping.dart`
- Modify: `lib/features/events/presentation/pages/timeline_page.dart`
- Modify: `test/features/events/presentation/timeline_grouping_test.dart`, `test/features/events/presentation/timeline_page_test.dart`, `test/features/events/presentation/timeline_page_theme_test.dart`

- [ ] **Step 1: Tests rouges du regroupement.** Remplacer le contenu de `timeline_grouping_test.dart` :

```dart
import 'package:colette/features/events/presentation/timeline_entry.dart';
import 'package:colette/features/events/presentation/timeline_grouping.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../helpers/care_event_factory.dart';
import '../../../helpers/sleep_session_factory.dart';

void main() {
  test('fusionne soins et sommeils du plus récent au plus ancien', () {
    final entries = mergeTimelineEntries(
      [
        makeEvent(id: 'c', startAt: DateTime(2026, 9, 21, 14), pee: true),
        makeEvent(id: 'a', startAt: DateTime(2026, 9, 20, 23), pee: true),
      ],
      [makeSleep(id: 's', startAt: DateTime(2026, 9, 21, 8), endAt: DateTime(2026, 9, 21, 9))],
    );
    expect(entries.map((e) => e.id), ['c', 's', 'a']);
    expect(entries[1], isA<SleepEntry>());
  });

  test('groupe par jour civil en conservant l\'ordre', () {
    final entries = mergeTimelineEntries(
      [
        makeEvent(id: 'c', startAt: DateTime(2026, 9, 21, 14), pee: true),
        makeEvent(id: 'b', startAt: DateTime(2026, 9, 21, 8), pee: true),
        makeEvent(id: 'a', startAt: DateTime(2026, 9, 20, 23), pee: true),
      ],
      const [],
    );
    final groups = groupEntriesByDay(entries);
    expect(groups.map((g) => g.day), [DateTime(2026, 9, 21), DateTime(2026, 9, 20)]);
    expect(groups.first.entries.map((e) => e.id), ['c', 'b']);
    expect(groups.last.entries.map((e) => e.id), ['a']);
  });

  test('liste vide donne aucun groupe', () {
    expect(groupEntriesByDay(const []), isEmpty);
  });
}
```

- [ ] **Step 2: Vérifier l'échec** — Run: `flutter test test/features/events/presentation/timeline_grouping_test.dart` → FAIL.

- [ ] **Step 3: Implémenter** `lib/features/events/presentation/timeline_entry.dart` :

```dart
import 'package:colette/features/events/domain/entities/care_event.dart';
import 'package:colette/features/sleep/domain/entities/sleep_session.dart';

/// Ligne du Journal : un soin ou un sommeil.
sealed class TimelineEntry {
  const TimelineEntry();

  String get id;
  DateTime get startAt;
}

/// Ligne de soin.
final class CareEntry extends TimelineEntry {
  const CareEntry(this.event);

  final CareEvent event;

  @override
  String get id => event.id;

  @override
  DateTime get startAt => event.startAt;
}

/// Ligne de sommeil.
final class SleepEntry extends TimelineEntry {
  const SleepEntry(this.session);

  final SleepSession session;

  @override
  String get id => session.id;

  @override
  DateTime get startAt => session.startAt;
}

/// Soins et sommeils mêlés, du plus récent au plus ancien.
List<TimelineEntry> mergeTimelineEntries(
  List<CareEvent> events,
  List<SleepSession> sleeps,
) => [
  for (final e in events) CareEntry(e),
  for (final s in sleeps) SleepEntry(s),
]..sort((a, b) => b.startAt.compareTo(a.startAt));
```

Remplacer `timeline_grouping.dart` :

```dart
import 'package:colette/core/dates/date_extensions.dart';
import 'package:colette/features/events/presentation/timeline_entry.dart';

/// Un jour du journal et ses lignes, dans l'ordre reçu.
typedef TimelineDay = ({DateTime day, List<TimelineEntry> entries});

/// Regroupe des lignes déjà triées par jour civil.
List<TimelineDay> groupEntriesByDay(List<TimelineEntry> entries) {
  final groups = <TimelineDay>[];
  for (final entry in entries) {
    final day = entry.startAt.dateOnly;
    if (groups.isNotEmpty && groups.last.day == day) {
      groups.last.entries.add(entry);
    } else {
      groups.add((day: day, entries: [entry]));
    }
  }
  return groups;
}
```

Run: `flutter test test/features/events/presentation/timeline_grouping_test.dart` → PASS.

- [ ] **Step 4: Tuile de sommeil** `lib/features/sleep/presentation/widgets/sleep_tile.dart` :

```dart
import 'package:colette/core/dates/time_format.dart';
import 'package:colette/core/theme/app_colors.dart';
import 'package:colette/core/theme/design_tokens.dart';
import 'package:colette/core/theme/text_styles.dart';
import 'package:colette/features/sleep/domain/entities/sleep_session.dart';
import 'package:colette/features/sleep/presentation/sleep_ui.dart';
import 'package:colette/l10n/generated/app_localizations.dart';
import 'package:colette/shared/ui/widgets/colette_card_surface.dart';
import 'package:flutter/material.dart';

/// Ligne du Journal pour un sommeil : heures, type, durée. Glisser pour supprimer.
class SleepTile extends StatelessWidget {
  const SleepTile({
    super.key,
    required this.session,
    required this.now,
    required this.onTap,
    required this.onConfirmDelete,
  });

  final SleepSession session;
  final DateTime now;
  final VoidCallback onTap;

  /// Doit renvoyer `true` pour confirmer la suppression, puis la réaliser.
  final Future<bool> Function() onConfirmDelete;

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    final styles = Theme.of(context).coletteTextStyles;
    final secondary = context.appColor(AppColors.textSecondary);
    final duration = formatSleepDuration(session.durationUntil(now), s);
    return Padding(
      padding: AppSpacing.only(
        left: AppSpacing.md,
        right: AppSpacing.md,
        bottom: AppSpacing.sm,
      ),
      child: Dismissible(
        key: ValueKey(session.id),
        direction: DismissDirection.endToStart,
        confirmDismiss: (_) => onConfirmDelete(),
        background: Container(
          alignment: .centerRight,
          padding: AppSpacing.md.horizontal,
          decoration: BoxDecoration(
            color: context.appColor(AppColors.error),
            borderRadius: AppRadius.lg.circular,
          ),
          child: Icon(
            Icons.delete_outline,
            color: context.appColor(AppColors.onPrimary),
          ),
        ),
        child: ColetteCardSurface(
          onTap: onTap,
          child: Row(
            crossAxisAlignment: .start,
            children: [
              Column(
                crossAxisAlignment: .start,
                children: [
                  Text(formatHourMinute(session.startAt), style: styles.bodyMedium),
                  if (session.endAt case final end?)
                    Text(
                      formatHourMinute(end),
                      style: styles.small.copyWith(color: secondary),
                    ),
                ],
              ),
              AppSpacing.md.horizontalSpace,
              Expanded(
                child: Column(
                  crossAxisAlignment: .start,
                  spacing: AppSpacing.xs.value,
                  children: [
                    Row(
                      spacing: AppSpacing.xs.value,
                      children: [
                        Icon(
                          Icons.bedtime_outlined,
                          size: AppSize.xs.value,
                          color: context.appColor(AppColors.sleepNight),
                        ),
                        Text(session.kind.label(s), style: styles.bodyMedium),
                      ],
                    ),
                    Text(
                      session.isOngoing ? s.sleepOngoingFor(duration) : duration,
                      style: styles.small.copyWith(color: secondary),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
```

- [ ] **Step 5: Test rouge du Journal.** Dans `timeline_page_test.dart` (et `timeline_page_theme_test.dart`), importer `sleep_providers.dart` et `../../../helpers/fake_sleep_repository.dart`, et ajouter à chaque liste d'overrides `sleepRepositoryProvider.overrideWithValue(FakeSleepRepository()),`. Ajouter le test :

```dart
  testWidgets('mêle les sommeils aux soins dans le bon jour', (tester) async {
    final repo = MockEventsRepository();
    when(() => repo.watchLatest(any(), limit: any(named: 'limit'))).thenAnswer(
      (_) => Stream.value([
        makeEvent(id: 'today', startAt: DateTime(2026, 9, 21, 9, 5), pee: true),
        makeEvent(id: 'yesterday', startAt: DateTime(2026, 9, 20, 22), bath: true),
      ]),
    );
    await pumpApp(
      tester,
      const TimelinePage(),
      overrides: [
        eventsRepositoryProvider.overrideWithValue(repo),
        sleepRepositoryProvider.overrideWithValue(FakeSleepRepository([
          makeSleep(id: 's', startAt: DateTime(2026, 9, 21, 10, 20), endAt: DateTime(2026, 9, 21, 12)),
        ])),
        clockProvider.overrideWithValue(FixedClock(now)),
        householdLocalStoreProvider.overrideWithValue(InMemoryHouseholdLocalStore(householdCode: 'ABCDEFGH')),
      ],
    );
    expect(find.text('Sieste'), findsOneWidget);
    expect(find.text('1 h 40'), findsOneWidget);
    final sleepY = tester.getTopLeft(find.text('Sieste')).dy;
    final careY = tester.getTopLeft(find.text('09h05')).dy;
    expect(sleepY, lessThan(careY));
  });
```

(importer aussi `../../../helpers/sleep_session_factory.dart`).

- [ ] **Step 6: Vérifier l'échec** — Run: `flutter test test/features/events/presentation/timeline_page_test.dart` → FAIL (pas de sommeil affiché).

- [ ] **Step 7: Page Journal.** Dans `timeline_page.dart` :

1. Imports : `core/clock/now_providers.dart`, `core/dates/date_extensions.dart`, `features/events/presentation/timeline_entry.dart`, `features/sleep/domain/entities/sleep_session.dart`, `features/sleep/presentation/providers/sleep_controller.dart`, `features/sleep/presentation/providers/sleep_providers.dart`, `features/sleep/presentation/widgets/sleep_form_sheet.dart`, `features/sleep/presentation/widgets/sleep_tile.dart`.
2. `TimelinePage.build` : après `final events = ref.watch(timelineEventsProvider);`, calculer la fenêtre et les sommeils, et fusionner :

```dart
    final loaded = events.value;
    final today = ref.watch(todayProvider);
    final from = switch (loaded) {
      final list? when list.isNotEmpty => list.last.startAt.dateOnly,
      _ => DateTime(today.year, today.month, today.day - 7),
    };
    final sleeps =
        ref.watch(timelineSleepsProvider(from)).value ?? const <SleepSession>[];
```

puis remplacer le `switch (events)` du `body` par :

```dart
      body: switch (events) {
        AsyncValue(hasValue: true, value: final List<CareEvent> value)
            when value.isEmpty && sleeps.isEmpty =>
          EmptyState(
            icon: Icons.view_timeline_outlined,
            message: s.journalEmpty,
          ),
        AsyncValue(hasValue: true, value: final List<CareEvent> value) =>
          _TimelineList(events: value, sleeps: sleeps),
        AsyncError() => EmptyState(
          icon: Icons.error_outline,
          message: s.errorUnknown,
        ),
        _ => const Center(child: CircularProgressIndicator()),
      },
```

3. `_TimelineList` : ajouter `required this.sleeps` / `final List<SleepSession> sleeps;`. Ajouter la méthode :

```dart
  Future<bool> _confirmDeleteSleep(
    BuildContext context,
    WidgetRef ref,
    SleepSession session,
  ) async {
    final s = S.of(context);
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(s.deleteSleepTitle),
        content: Text(s.deleteEventBody),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: Text(s.actionCancel),
          ),
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: Text(s.actionDelete),
          ),
        ],
      ),
    );
    if (confirmed != true) return false;
    final deleted = await ref
        .read(sleepControllerProvider.notifier)
        .delete(session.id);
    if (!deleted && context.mounted) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(s.errorUnknown)));
    }
    return deleted;
  }
```

4. Dans `_TimelineList.build` : ajouter `ref.watch(sleepControllerProvider);` sous le `ref.watch(eventFormControllerProvider);` (même commentaire), remplacer `final groups = groupEventsByDay(events);` par `final groups = groupEntriesByDay(mergeTimelineEntries(events, sleeps));`, et le `SliverList.builder` par :

```dart
                SliverList.builder(
                  itemCount: group.entries.length,
                  itemBuilder: (context, index) => switch (group.entries[index]) {
                    CareEntry(:final event) => EventTile(
                      key: ValueKey(event.id),
                      event: event,
                      onTap: () => showEventFormSheet(context, initial: event),
                      onConfirmDelete: () => _confirmDelete(context, ref, event),
                    ),
                    SleepEntry(:final session) => SleepTile(
                      key: ValueKey(session.id),
                      session: session,
                      now: now,
                      onTap: () => showSleepFormSheet(context, initial: session),
                      onConfirmDelete: () =>
                          _confirmDeleteSleep(context, ref, session),
                    ),
                  },
                ),
```

5. Mettre à jour le `///` de `TimelinePage` : `/// Onglet Journal : soins et sommeils groupés par jour, pagination par défilement.`

Si le fichier dépasse 300 lignes, extraire `_confirmDelete` et `_confirmDeleteSleep` dans `lib/features/events/presentation/widgets/timeline_delete_dialog.dart` (fonction `Future<bool> confirmTimelineDelete(BuildContext context, {required String title})` qui affiche le dialogue et renvoie le choix).

- [ ] **Step 8: Vérifier**

```bash
flutter test test/features/events test/features/sleep
dart analyze
```

Expected : PASS, aucun problème.

- [ ] **Step 9: Commit**

```bash
git add lib/features/events/presentation/timeline_entry.dart lib/features/events/presentation/timeline_grouping.dart lib/features/events/presentation/pages/timeline_page.dart lib/features/sleep/presentation/widgets/sleep_tile.dart test/features/events/presentation/timeline_grouping_test.dart test/features/events/presentation/timeline_page_test.dart test/features/events/presentation/timeline_page_theme_test.dart
git commit -m "feat: sommeils mêlés aux soins dans le Journal"
```

(ajouter `lib/features/events/presentation/widgets/timeline_delete_dialog.dart` s'il a été créé.)

---

### Task 15: Horaires de nuit dans Réglages

**Files:**
- Create: `lib/features/sleep/presentation/widgets/sleep_settings_section.dart`
- Modify: `lib/features/baby/presentation/pages/settings_page.dart`
- Test: `test/features/sleep/presentation/sleep_settings_section_test.dart`

- [ ] **Step 1: Test rouge** `test/features/sleep/presentation/sleep_settings_section_test.dart` (même mécanique que `care_settings_section_test.dart`) :

```dart
import 'package:colette/features/baby/domain/entities/baby_profile.dart';
import 'package:colette/features/baby/domain/repositories/baby_repository.dart';
import 'package:colette/features/baby/presentation/providers/baby_providers.dart';
import 'package:colette/features/dashboard/presentation/providers/feeding_plan_sync.dart';
import 'package:colette/features/household/presentation/providers/household_providers.dart';
import 'package:colette/features/sleep/presentation/widgets/sleep_settings_section.dart';
import 'package:colette/shared/ui/widgets/int_stepper_row.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:mocktail/mocktail.dart';

import '../../../helpers/in_memory_household_local_store.dart';
import '../../../helpers/pump_app.dart';

class MockBabyRepository extends Mock implements BabyRepository {}

void main() {
  final profile = BabyProfile(name: 'Colette', birthDate: DateTime(2026, 9, 1));

  setUpAll(() => registerFallbackValue(profile));

  testWidgets('affiche 20 h et 7 h, le + du début de nuit écrit 21', (
    tester,
  ) async {
    final repo = MockBabyRepository();
    when(() => repo.saveProfile(any(), any()))
        .thenAnswer((_) async => right(null));
    await pumpApp(
      tester,
      Scaffold(
        body: SingleChildScrollView(
          child: SleepSettingsSection(profile: profile),
        ),
      ),
      overrides: [
        babyRepositoryProvider.overrideWithValue(repo),
        feedingPlanSyncProvider.overrideWithValue(const NoopFeedingPlanSync()),
        householdLocalStoreProvider.overrideWithValue(
          InMemoryHouseholdLocalStore(householdCode: 'ABCDEFGH'),
        ),
      ],
    );
    expect(find.text('Début de la nuit'), findsOneWidget);
    expect(find.text('Fin de la nuit'), findsOneWidget);
    expect(find.text('20 h'), findsOneWidget);
    expect(find.text('7 h'), findsOneWidget);
    await tester.tap(find.widgetWithIcon(IconButton, Icons.add).first);
    await tester.pumpAndSettle();
    final saved = verify(() => repo.saveProfile('ABCDEFGH', captureAny()))
        .captured
        .cast<BabyProfile>();
    expect(saved.last.careSettings.nightStartHour, 21);
    expect(
      find.descendant(
        of: find.byType(IntStepperRow).first,
        matching: find.text('21 h'),
      ),
      findsOneWidget,
    );
  });
}
```

- [ ] **Step 2: Vérifier l'échec** — Run: `flutter test test/features/sleep/presentation/sleep_settings_section_test.dart` → FAIL.

- [ ] **Step 3: Implémenter**

```dart
import 'package:colette/core/theme/design_tokens.dart';
import 'package:colette/features/baby/domain/entities/baby_profile.dart';
import 'package:colette/features/baby/domain/entities/care_settings.dart';
import 'package:colette/features/baby/presentation/providers/baby_settings_controller.dart';
import 'package:colette/l10n/generated/app_localizations.dart';
import 'package:colette/shared/ui/widgets/colette_card_surface.dart';
import 'package:colette/shared/ui/widgets/int_stepper_row.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Horaires de nuit qui classent un endormissement en sieste ou en nuit.
/// Tient une copie locale optimiste, comme `CareSettingsSection`.
class SleepSettingsSection extends ConsumerStatefulWidget {
  const SleepSettingsSection({super.key, required this.profile});

  final BabyProfile profile;

  @override
  ConsumerState<SleepSettingsSection> createState() =>
      _SleepSettingsSectionState();
}

class _SleepSettingsSectionState extends ConsumerState<SleepSettingsSection> {
  late CareSettings _settings = widget.profile.careSettings;

  @override
  void didUpdateWidget(covariant SleepSettingsSection oldWidget) {
    super.didUpdateWidget(oldWidget);
    final incoming = widget.profile.careSettings;
    final writing = ref.read(babySettingsControllerProvider).isLoading;
    if (incoming != oldWidget.profile.careSettings && !writing) {
      _settings = incoming;
    }
  }

  void _update(CareSettings next) {
    setState(() => _settings = next);
    ref
        .read(babySettingsControllerProvider.notifier)
        .updateCareSettings(widget.profile, next);
  }

  @override
  Widget build(BuildContext context) {
    // Garde le contrôleur autoDispose vivant pendant l'await de updateCareSettings.
    ref.watch(babySettingsControllerProvider);
    final s = S.of(context);
    return ColetteCardSurface(
      padding: AppSpacing.sm.all,
      child: Column(
        children: [
          IntStepperRow(
            label: s.settingsNightStart,
            value: _settings.nightStartHour,
            min: 0,
            max: 23,
            suffix: s.hourSuffix,
            onChanged: (v) => _update(_settings.copyWith(nightStartHour: v)),
          ),
          IntStepperRow(
            label: s.settingsNightEnd,
            value: _settings.nightEndHour,
            min: 0,
            max: 23,
            suffix: s.hourSuffix,
            onChanged: (v) => _update(_settings.copyWith(nightEndHour: v)),
          ),
        ],
      ),
    );
  }
}
```

Dans `settings_page.dart`, après `CareSettingsSection(profile: profile),` :

```dart
            SectionHeader(title: s.settingsSleepSection),
            SleepSettingsSection(profile: profile),
```

(avec l'import), et le `///` de la classe : `/// Onglet Réglages : bébé, pesées, soins attendus, sommeil, notifications, apparence, foyer.`

- [ ] **Step 4: Vérifier** — Run: `flutter test test/features/sleep test/features/baby` → PASS ; `dart analyze` → propre.

- [ ] **Step 5: Commit**

```bash
git add lib/features/sleep/presentation/widgets/sleep_settings_section.dart lib/features/baby/presentation/pages/settings_page.dart test/features/sleep/presentation/sleep_settings_section_test.dart
git commit -m "feat: horaires de nuit réglables dans Réglages"
```

---

### Task 16: Rendu clair et sombre, vérification complète

**Files:**
- Test: `test/features/sleep/presentation/sleep_theme_test.dart`

- [ ] **Step 1: Test de rendu dans les deux thèmes** : monter `SleepCard` (état endormi) puis `SleepPage` (avec une nuit et deux siestes) dans une `MaterialApp` avec `theme: const ThemeService().light()`, `darkTheme: const ThemeService().dark()` et `themeMode` à `ThemeMode.light` puis `ThemeMode.dark` (modèle : `timeline_page_theme_test.dart`). Vérifier dans chaque thème qu'aucune exception n'est levée (`expect(tester.takeException(), isNull)`) et que la couleur de la piste de `SleepRowPainter` vaut `AppColors.surfaceContainer.dark` en sombre :

```dart
    final painter = tester.widget<CustomPaint>(
      find.descendant(of: find.byType(SleepWeekRow).first, matching: find.byType(CustomPaint)),
    ).painter! as SleepRowPainter;
    expect(painter.track, AppColors.surfaceContainer.dark);
```

- [ ] **Step 2: Vérification visuelle par PNG** (non committée) : dans un test temporaire, envelopper la carte et la page dans un `RepaintBoundary`, appeler `await expectLater(find.byType(RepaintBoundary).first, matchesGoldenFile('/tmp/sleep_light.png'))` avec `--update-goldens`, en clair et en sombre, puis ouvrir les PNG avec l'outil Read. Contrôler : lisibilité des textes, contraste des segments nuit et sieste sur la piste, alignement de l'axe 0/6/12/18/24 avec les segments. Supprimer le test temporaire ensuite.

- [ ] **Step 3: Vérification complète**

```bash
dart format lib test
dart run build_runner build -d
dart analyze
flutter test
```

Expected : `No issues found!` ; tous les tests verts (ligne de base de la Task 0 + nouveaux).

- [ ] **Step 4: Simulateur iPhone.** `flutter build ios --simulator --debug`, installer et lancer sur l'iPhone simulé, vérifier que l'app démarre, que la carte Sommeil apparaît sur l'accueil (si le simulateur a un foyer) et que la page `/today/sleep` s'ouvre. Ne pas créer de foyer de test dans le Firestore de production sans l'accord de Maxence : si le simulateur n'a pas de foyer, s'arrêter au lancement et le signaler.

- [ ] **Step 5: Commit**

```bash
git add test/features/sleep/presentation/sleep_theme_test.dart
git commit -m "test: rendu clair et sombre de la carte et de la page Sommeil"
```

(Ajouter au même commit les fichiers reformatés par `dart format` s'il y en a, en les listant explicitement.)
