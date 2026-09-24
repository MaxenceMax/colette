# Fréquence des soins — plan d'implémentation

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Remplacer les entiers « N par jour » et « bain tous les N jours » par une entité `CareFrequency` unique (N par jour ↔ tous les N jours, interrupteur de suivi), et n'afficher sur l'accueil que les soins dus aujourd'hui.

**Architecture:** Nouvelle entité de domaine `CareFrequency` portée par `CareSettings` pour les cinq soins programmés (`CareType.scheduled`). L'accueil et le digest du matin lisent une fenêtre de 7 jours d'événements et appliquent la même règle `isExpected`. Firestore stocke une map par soin, avec lecture de repli des anciens champs plats côté app (`CareSettingsDto`) et côté Cloud Functions (`withDefaults`).

**Tech Stack:** Flutter 3 / Dart 3 (freezed, Riverpod 3 codegen, fpdart, mocktail, fake_cloud_firestore), Cloud Functions TypeScript (vitest, luxon).

**Spec :** `docs/superpowers/specs/2026-09-24-care-frequency-design.md`.

**Contexte de travail :** worktree `.claude/worktrees/care-frequency`, branche `feat/care-frequency` depuis `main`. Toutes les commandes se lancent depuis cette racine. Après chaque modification d'un fichier annoté freezed / riverpod : `dart run build_runner build -d`. Avant chaque commit : `dart format lib test`.

---

## Structure des fichiers

| Fichier | Rôle |
| --- | --- |
| `lib/shared/domain/care_type.dart` | + `CareType.scheduled` (ordre des cinq soins) et `isScheduled`. |
| `lib/features/baby/domain/entities/care_frequency.dart` (nouveau) | Entité `CareFrequency` : échelle, butées, `isExpected`. |
| `lib/features/baby/domain/entities/care_settings.dart` | Cinq `CareFrequency` à la place des entiers ; `frequencyOf`, `withFrequency`. |
| `lib/features/baby/data/dtos/baby_profile_dto.dart` | `CareFrequencyDto` + repli des champs plats. |
| `lib/features/baby/presentation/widgets/care_frequency_row.dart` (nouveau) | Ligne de réglage : libellé, switch, − fréquence +. |
| `lib/features/baby/presentation/widgets/care_settings_section.dart` | Cinq `CareFrequencyRow` + stepper biberons. |
| `lib/features/baby/presentation/providers/baby_settings_controller.dart` | `setCordFallenAt` bascule `umbilicalCare.enabled`. |
| `lib/features/dashboard/domain/use_cases/compute_daily_care_status.dart` | Règle unique sur la fenêtre de 7 jours. |
| `lib/features/dashboard/presentation/providers/dashboard_providers.dart` | `dailyCareTasks` consomme `weekEventsProvider`. |
| `lib/features/events/presentation/providers/events_providers.dart` | + `weekEventsProvider`, − `latestBathProvider`. |
| `lib/features/events/domain/repositories/events_repository.dart`, `data/repositories/firestore_events_repository.dart` | − `watchLatestBath`. |
| `lib/features/events/presentation/widgets/event_form_sheet.dart` | Puce nombril masquée si `umbilicalCare.enabled` faux. |
| `lib/l10n/app_fr.arb` | + `careFrequencyPerDay`, `careFrequencyEveryDays`, `settingsCareTracked` ; − cinq clés `settingsXxxPerDay` / `settingsBathEveryDays`. |
| `firestore.indexes.json` | − index `bath + startAt`. |
| `functions/src/lib/types.ts` | `CareFrequency`, `CareSettings`, `withDefaults` avec repli. |
| `functions/src/lib/care-frequency.ts` (nouveau) | `isExpected`, `CARE_WINDOW_DAYS`. |
| `functions/src/lib/care-status.ts` | `pendingCares({ settings, events, now })`. |
| `functions/src/lib/paris-time.ts` | + `startOfDayInParis(date, daysAgo)`. |
| `functions/src/morning-digest.ts` | Une requête sur 7 jours. |
| `docs/superpowers/specs/2026-09-21-colette-v1-design.md` | Sections 5, 6.2, 6.6, 7. |

---

### Task 1 : `CareType.scheduled`

**Files:**
- Modify: `lib/shared/domain/care_type.dart`
- Test: `test/shared/domain/care_type_test.dart` (nouveau)

- [ ] **Step 1 : test rouge**

```dart
import 'package:colette/shared/domain/care_type.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('scheduled liste les cinq soins programmés dans l\'ordre de l\'accueil', () {
    expect(CareType.scheduled, [
      CareType.adrigyl,
      CareType.eyeCare,
      CareType.noseCare,
      CareType.umbilicalCare,
      CareType.bath,
    ]);
  });

  test('isScheduled est faux pour pipi, caca et change', () {
    expect(CareType.pee.isScheduled, isFalse);
    expect(CareType.poop.isScheduled, isFalse);
    expect(CareType.diaperChange.isScheduled, isFalse);
    expect(CareType.bath.isScheduled, isTrue);
  });
}
```

- [ ] **Step 2 : vérifier l'échec**

Run: `flutter test test/shared/domain/care_type_test.dart`
Expected: échec de compilation, `scheduled` et `isScheduled` inconnus.

- [ ] **Step 3 : implémentation**

Remplacer le corps de l'enum dans `lib/shared/domain/care_type.dart` :

```dart
/// Soins cochables dans un événement.
enum CareType {
  pee(CareCategory.diaper),
  poop(CareCategory.diaper),
  diaperChange(CareCategory.diaper),
  adrigyl(CareCategory.care),
  bath(CareCategory.bath),
  eyeCare(CareCategory.care),
  noseCare(CareCategory.care),
  umbilicalCare(CareCategory.care);

  const CareType(this.category);

  final CareCategory category;

  /// Soins avec une fréquence attendue, dans l'ordre de l'accueil, des réglages et du digest.
  static const List<CareType> scheduled = [
    adrigyl,
    eyeCare,
    noseCare,
    umbilicalCare,
    bath,
  ];

  /// `true` si ce soin a une fréquence attendue.
  bool get isScheduled => scheduled.contains(this);
}
```

- [ ] **Step 4 : test vert**

Run: `flutter test test/shared/domain/care_type_test.dart`
Expected: 2 tests passent.

- [ ] **Step 5 : commit**

```bash
dart format lib test
git add lib/shared/domain/care_type.dart test/shared/domain/care_type_test.dart
git commit -m "feat: liste ordonnée des soins programmés CareType.scheduled"
```

---

### Task 2 : entité `CareFrequency`

**Files:**
- Create: `lib/features/baby/domain/entities/care_frequency.dart`
- Test: `test/features/baby/domain/care_frequency_test.dart` (nouveau)

- [ ] **Step 1 : test rouge**

```dart
import 'package:colette/features/baby/domain/entities/care_frequency.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const daily = CareFrequency();
  final now = DateTime(2026, 9, 21, 14);

  group('previous (bouton −)', () {
    test('3/jour → 2/jour', () {
      expect(
        const CareFrequency(timesPerDay: 3).previous(),
        const CareFrequency(timesPerDay: 2),
      );
    });

    test('1/jour → tous les 2 jours', () {
      expect(daily.previous(), const CareFrequency(everyDays: 2));
    });

    test('tous les 2 jours → tous les 3 jours', () {
      expect(
        const CareFrequency(everyDays: 2).previous(),
        const CareFrequency(everyDays: 3),
      );
    });

    test('tous les 7 jours : butée', () {
      expect(const CareFrequency(everyDays: 7).previous(), isNull);
    });

    test('conserve enabled', () {
      expect(
        const CareFrequency(enabled: false).previous(),
        const CareFrequency(everyDays: 2, enabled: false),
      );
    });
  });

  group('next (bouton +)', () {
    test('tous les 3 jours → tous les 2 jours', () {
      expect(
        const CareFrequency(everyDays: 3).next(4),
        const CareFrequency(everyDays: 2),
      );
    });

    test('tous les 2 jours → 1/jour', () {
      expect(const CareFrequency(everyDays: 2).next(4), daily);
    });

    test('1/jour → 2/jour', () {
      expect(daily.next(4), const CareFrequency(timesPerDay: 2));
    });

    test('butée à maxTimesPerDay', () {
      expect(const CareFrequency(timesPerDay: 3).next(3), isNull);
    });
  });

  group('isExpected', () {
    test('désactivé : jamais attendu', () {
      expect(
        const CareFrequency(enabled: false).isExpected(
          lastDoneAt: null,
          now: now,
        ),
        isFalse,
      );
    });

    test('1/jour : toujours attendu, même fait aujourd\'hui', () {
      expect(daily.isExpected(lastDoneAt: null, now: now), isTrue);
      expect(
        daily.isExpected(lastDoneAt: DateTime(2026, 9, 21, 8), now: now),
        isTrue,
      );
    });

    test('tous les 2 jours : attendu sans historique', () {
      expect(
        const CareFrequency(everyDays: 2).isExpected(lastDoneAt: null, now: now),
        isTrue,
      );
    });

    test('tous les 2 jours, fait hier : pas attendu', () {
      expect(
        const CareFrequency(everyDays: 2).isExpected(
          lastDoneAt: DateTime(2026, 9, 20, 18),
          now: now,
        ),
        isFalse,
      );
    });

    test('tous les 2 jours, fait avant-hier : attendu', () {
      expect(
        const CareFrequency(everyDays: 2).isExpected(
          lastDoneAt: DateTime(2026, 9, 19, 18),
          now: now,
        ),
        isTrue,
      );
    });

    test('DST : deux jours civils malgré le changement d\'heure', () {
      // Passage à l'heure d'été le 29 mars 2026 entre les deux instants.
      expect(
        const CareFrequency(everyDays: 2).isExpected(
          lastDoneAt: DateTime(2026, 3, 28, 20),
          now: DateTime(2026, 3, 30, 8),
        ),
        isTrue,
      );
    });
  });
}
```

- [ ] **Step 2 : vérifier l'échec**

Run: `flutter test test/features/baby/domain/care_frequency_test.dart`
Expected: échec de compilation, fichier `care_frequency.dart` introuvable.

- [ ] **Step 3 : implémentation**

Créer `lib/features/baby/domain/entities/care_frequency.dart` :

```dart
import 'package:colette/core/dates/date_extensions.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

part 'care_frequency.freezed.dart';

/// Fréquence attendue d'un soin : `timesPerDay` fois par jour, ou une fois tous les `everyDays` jours.
/// Invariant : l'un des deux vaut 1. `enabled` faux = soin plus suivi, fréquence conservée.
@freezed
abstract class CareFrequency with _$CareFrequency {
  const CareFrequency._();

  const factory CareFrequency({
    @Default(1) int timesPerDay,
    @Default(1) int everyDays,
    @Default(true) bool enabled,
  }) = _CareFrequency;

  /// Espacement maximal réglable ; au-delà, on coupe le suivi.
  static const maxEveryDays = 7;

  /// Cran suivant vers « plus souvent » (bouton +) ; `null` en butée.
  CareFrequency? next(int maxTimesPerDay) {
    if (everyDays > 1) return copyWith(everyDays: everyDays - 1);
    if (timesPerDay < maxTimesPerDay) {
      return copyWith(timesPerDay: timesPerDay + 1);
    }
    return null;
  }

  /// Cran suivant vers « moins souvent » (bouton −) ; `null` en butée.
  CareFrequency? previous() {
    if (timesPerDay > 1) return copyWith(timesPerDay: timesPerDay - 1);
    if (everyDays < maxEveryDays) return copyWith(everyDays: everyDays + 1);
    return null;
  }

  /// Soin dû aujourd'hui : suivi actif, et quotidien, jamais fait,
  /// ou dernier fait il y a au moins [everyDays] jours civils.
  bool isExpected({required DateTime? lastDoneAt, required DateTime now}) {
    if (!enabled) return false;
    if (everyDays == 1 || lastDoneAt == null) return true;
    return calendarDaysBetween(lastDoneAt, now) >= everyDays;
  }
}
```

Run: `dart run build_runner build -d`

- [ ] **Step 4 : test vert**

Run: `flutter test test/features/baby/domain/care_frequency_test.dart`
Expected: 15 tests passent.

- [ ] **Step 5 : commit**

```bash
dart format lib test
git add lib/features/baby/domain/entities/care_frequency.dart lib/features/baby/domain/entities/care_frequency.freezed.dart test/features/baby/domain/care_frequency_test.dart
git commit -m "feat: entité CareFrequency, échelle N par jour / tous les N jours"
```

---

### Task 3 : `weekEventsProvider`

**Files:**
- Modify: `lib/features/events/presentation/providers/events_providers.dart`
- Test: `test/features/events/presentation/events_providers_retry_test.dart`

- [ ] **Step 1 : test rouge**

Dans `test/features/events/presentation/events_providers_retry_test.dart`, ajouter après le test `recentEvents remonte la failure…` :

```dart
  test('weekEvents remonte la failure en AsyncError sans relance', () async {
    final state = await failedState(containerWith(repo), weekEventsProvider);
    expect(state, isA<AsyncError<List<CareEvent>>>());
    expect(state.retrying, isFalse);
  });
```

- [ ] **Step 2 : vérifier l'échec**

Run: `flutter test test/features/events/presentation/events_providers_retry_test.dart`
Expected: échec de compilation, `weekEventsProvider` inconnu.

- [ ] **Step 3 : implémentation**

Dans `lib/features/events/presentation/providers/events_providers.dart`, ajouter l'import `package:colette/features/baby/domain/entities/care_frequency.dart` puis, après `recentEvents` :

```dart
/// Événements des 7 derniers jours civils, aujourd'hui inclus : suffisant pour savoir
/// si un soin espacé d'au plus [CareFrequency.maxEveryDays] jours est dû.
@Riverpod(retry: noRetry)
Stream<List<CareEvent>> weekEvents(Ref ref) {
  final code = ref.watch(currentHouseholdCodeProvider);
  if (code == null) return Stream.value(const []);
  final today = ref.watch(todayProvider);
  return ref
      .watch(eventsRepositoryProvider)
      .watchBetween(
        code,
        from: DateTime(
          today.year,
          today.month,
          today.day - (CareFrequency.maxEveryDays - 1),
        ),
        to: today.startOfNextDay,
      );
}
```

Run: `dart run build_runner build -d`

- [ ] **Step 4 : test vert**

Run: `flutter test test/features/events/presentation/events_providers_retry_test.dart`
Expected: tous les tests passent.

- [ ] **Step 5 : commit**

```bash
dart format lib test
git add lib/features/events/presentation/providers/events_providers.dart lib/features/events/presentation/providers/events_providers.g.dart test/features/events/presentation/events_providers_retry_test.dart
git commit -m "feat: weekEventsProvider, fenêtre de 7 jours pour les soins espacés"
```

---

### Task 4 : chaînes et widget `CareFrequencyRow`

**Files:**
- Modify: `lib/l10n/app_fr.arb`
- Create: `lib/features/baby/presentation/widgets/care_frequency_row.dart`
- Test: `test/features/baby/presentation/care_frequency_row_test.dart` (nouveau)

- [ ] **Step 1 : chaînes**

Dans `lib/l10n/app_fr.arb`, à la suite de `"settingsFeedsPerDay": "Biberons par jour",` ajouter :

```json
  "careFrequencyPerDay": "{n, plural, =1{1 fois par jour} other{{n} fois par jour}}",
  "@careFrequencyPerDay": { "placeholders": { "n": { "type": "int" } } },
  "careFrequencyEveryDays": "tous les {n} jours",
  "@careFrequencyEveryDays": { "placeholders": { "n": { "type": "int" } } },
  "settingsCareTracked": "Suivi",
```

Ne pas encore supprimer les anciennes clés `settingsAdrigylPerDay`, `settingsEyeCarePerDay`, `settingsNoseCarePerDay`, `settingsUmbilicalCarePerDay`, `settingsBathEveryDays` (elles sont retirées en Task 5 avec leur dernier usage).

Run: `flutter gen-l10n`
Expected: `lib/l10n/generated/app_localizations.dart` expose `careFrequencyPerDay(int n)`, `careFrequencyEveryDays(int n)`, `settingsCareTracked`.

- [ ] **Step 2 : test rouge**

```dart
import 'package:colette/features/baby/domain/entities/care_frequency.dart';
import 'package:colette/features/baby/presentation/widgets/care_frequency_row.dart';
import 'package:colette/shared/domain/care_type.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../helpers/pump_app.dart';

void main() {
  Future<List<CareFrequency>> pumpRow(
    WidgetTester tester,
    CareFrequency frequency, {
    int maxTimesPerDay = 3,
  }) async {
    final changes = <CareFrequency>[];
    await pumpApp(
      tester,
      Scaffold(
        body: CareFrequencyRow(
          type: CareType.adrigyl,
          frequency: frequency,
          maxTimesPerDay: maxTimesPerDay,
          onChanged: changes.add,
        ),
      ),
    );
    return changes;
  }

  final minus = find.widgetWithIcon(IconButton, Icons.remove);
  final plus = find.widgetWithIcon(IconButton, Icons.add);

  testWidgets('affiche le libellé du soin et « 1 fois par jour »', (
    tester,
  ) async {
    await pumpRow(tester, const CareFrequency());
    expect(find.text('Adrigyl'), findsOneWidget);
    expect(find.text('1 fois par jour'), findsOneWidget);
    expect(find.byType(Switch), findsOneWidget);
  });

  testWidgets('− depuis 1/jour passe à tous les 2 jours', (tester) async {
    final changes = await pumpRow(tester, const CareFrequency());
    await tester.tap(minus);
    await tester.pump();
    expect(changes, [const CareFrequency(everyDays: 2)]);
  });

  testWidgets('+ depuis tous les 2 jours revient à 1/jour', (tester) async {
    final changes = await pumpRow(tester, const CareFrequency(everyDays: 2));
    expect(find.text('tous les 2 jours'), findsOneWidget);
    await tester.tap(plus);
    await tester.pump();
    expect(changes, [const CareFrequency()]);
  });

  testWidgets('3 fois par jour au pluriel, + inactif en butée', (
    tester,
  ) async {
    await pumpRow(tester, const CareFrequency(timesPerDay: 3));
    expect(find.text('3 fois par jour'), findsOneWidget);
    expect(tester.widget<IconButton>(plus).onPressed, isNull);
    expect(tester.widget<IconButton>(minus).onPressed, isNotNull);
  });

  testWidgets('− inactif à tous les 7 jours', (tester) async {
    await pumpRow(tester, const CareFrequency(everyDays: 7));
    expect(tester.widget<IconButton>(minus).onPressed, isNull);
  });

  testWidgets('suivi coupé : fréquence visible, boutons inactifs', (
    tester,
  ) async {
    final changes = await pumpRow(
      tester,
      const CareFrequency(everyDays: 2, enabled: false),
    );
    expect(find.text('tous les 2 jours'), findsOneWidget);
    expect(tester.widget<IconButton>(minus).onPressed, isNull);
    expect(tester.widget<IconButton>(plus).onPressed, isNull);
    expect(tester.widget<Switch>(find.byType(Switch)).value, isFalse);
    await tester.tap(find.byType(Switch));
    await tester.pump();
    expect(changes, [const CareFrequency(everyDays: 2)]);
  });

  testWidgets('le switch coupe le suivi sans toucher à la fréquence', (
    tester,
  ) async {
    final changes = await pumpRow(tester, const CareFrequency(timesPerDay: 2));
    await tester.tap(find.byType(Switch));
    await tester.pump();
    expect(changes, [const CareFrequency(timesPerDay: 2, enabled: false)]);
  });
}
```

- [ ] **Step 3 : vérifier l'échec**

Run: `flutter test test/features/baby/presentation/care_frequency_row_test.dart`
Expected: échec de compilation, `care_frequency_row.dart` introuvable.

- [ ] **Step 4 : implémentation**

Créer `lib/features/baby/presentation/widgets/care_frequency_row.dart` :

```dart
import 'package:colette/core/theme/app_colors.dart';
import 'package:colette/core/theme/design_tokens.dart';
import 'package:colette/core/theme/text_styles.dart';
import 'package:colette/features/baby/domain/entities/care_frequency.dart';
import 'package:colette/l10n/generated/app_localizations.dart';
import 'package:colette/shared/domain/care_type.dart';
import 'package:colette/shared/ui/care_type_ui.dart';
import 'package:flutter/material.dart';

/// Réglage d'un soin : libellé et interrupteur de suivi, puis « [−] fréquence [+] ».
/// Suivi coupé : la fréquence reste lisible, grisée, boutons inactifs.
class CareFrequencyRow extends StatelessWidget {
  const CareFrequencyRow({
    super.key,
    required this.type,
    required this.frequency,
    required this.maxTimesPerDay,
    required this.onChanged,
  });

  final CareType type;
  final CareFrequency frequency;
  final int maxTimesPerDay;
  final ValueChanged<CareFrequency> onChanged;

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    final styles = Theme.of(context).coletteTextStyles;
    final enabled = frequency.enabled;
    final muted = context.appColor(AppColors.textSecondary);
    final onSurface = context.appColor(AppColors.onSurface);
    final previous = enabled ? frequency.previous() : null;
    final next = enabled ? frequency.next(maxTimesPerDay) : null;
    final label = frequency.everyDays > 1
        ? s.careFrequencyEveryDays(frequency.everyDays)
        : s.careFrequencyPerDay(frequency.timesPerDay);
    return Column(
      children: [
        Row(
          spacing: AppSpacing.sm.value,
          children: [
            Icon(
              type.icon,
              color: enabled ? context.appColor(type.color) : muted,
            ),
            Expanded(
              child: Text(
                type.label(s),
                style: styles.body.copyWith(color: enabled ? onSurface : muted),
              ),
            ),
            Semantics(
              label: s.settingsCareTracked,
              child: Switch(
                value: enabled,
                onChanged: (value) =>
                    onChanged(frequency.copyWith(enabled: value)),
              ),
            ),
          ],
        ),
        Row(
          children: [
            IconButton(
              onPressed: previous == null ? null : () => onChanged(previous),
              icon: const Icon(Icons.remove),
              color: context.appColor(AppColors.primary),
              tooltip: s.actionDecrease,
            ),
            Expanded(
              child: Text(
                label,
                textAlign: .center,
                style: styles.bodyMedium.copyWith(
                  color: enabled ? onSurface : muted,
                ),
              ),
            ),
            IconButton(
              onPressed: next == null ? null : () => onChanged(next),
              icon: const Icon(Icons.add),
              color: context.appColor(AppColors.primary),
              tooltip: s.actionIncrease,
            ),
          ],
        ),
      ],
    );
  }
}
```

- [ ] **Step 5 : test vert**

Run: `flutter test test/features/baby/presentation/care_frequency_row_test.dart`
Expected: 7 tests passent.

- [ ] **Step 6 : commit**

```bash
dart format lib test
git add lib/l10n lib/features/baby/presentation/widgets/care_frequency_row.dart test/features/baby/presentation/care_frequency_row_test.dart
git commit -m "feat: widget CareFrequencyRow, switch de suivi et fréquence"
```

---

### Task 5 : basculement de `CareSettings` sur `CareFrequency`

Cette tâche remplace les entiers par des `CareFrequency` et adapte tous les consommateurs en une fois (le projet ne compile pas entre les étapes ; vérifier avec `dart analyze` à la fin de l'étape 4, puis les tests).

**Files:**
- Modify: `lib/features/baby/domain/entities/care_settings.dart`
- Modify: `lib/features/baby/data/dtos/baby_profile_dto.dart`
- Modify: `lib/features/baby/presentation/providers/baby_settings_controller.dart`
- Modify: `lib/features/baby/presentation/widgets/care_settings_section.dart`
- Modify: `lib/features/dashboard/domain/use_cases/compute_daily_care_status.dart`
- Modify: `lib/features/dashboard/presentation/providers/dashboard_providers.dart`
- Modify: `lib/features/events/presentation/widgets/event_form_sheet.dart`
- Modify: `lib/l10n/app_fr.arb`
- Test: `test/features/baby/data/baby_profile_dto_test.dart`, `test/features/baby/data/firestore_baby_repository_test.dart`, `test/features/baby/presentation/baby_settings_controller_test.dart`, `test/features/baby/presentation/care_settings_section_test.dart`, `test/features/baby/presentation/settings_sections_merge_test.dart`, `test/features/dashboard/domain/compute_daily_care_status_test.dart`, `test/features/dashboard/presentation/dashboard_page_test.dart`, `test/features/dashboard/presentation/dashboard_providers_test.dart`, `test/features/dashboard/presentation/todo_section_test.dart`, `test/features/events/presentation/event_form_sheet_test.dart`

- [ ] **Step 1 : tests rouges du domaine et du DTO**

Remplacer intégralement `test/features/dashboard/domain/compute_daily_care_status_test.dart` :

```dart
import 'package:colette/features/baby/domain/entities/care_frequency.dart';
import 'package:colette/features/baby/domain/entities/care_settings.dart';
import 'package:colette/features/dashboard/domain/use_cases/compute_daily_care_status.dart';
import 'package:colette/shared/domain/care_type.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../helpers/care_event_factory.dart';

void main() {
  const compute = ComputeDailyCareStatus();
  final now = DateTime(2026, 9, 21, 14);
  const everyTwoDays = CareSettings(adrigyl: CareFrequency(everyDays: 2));

  test('réglages par défaut sans événement : 5 tâches, aucune faite', () {
    final tasks = compute(settings: const CareSettings(), events: const [], now: now);
    expect(tasks.map((t) => t.type), [
      CareType.adrigyl,
      CareType.eyeCare,
      CareType.noseCare,
      CareType.umbilicalCare,
      CareType.bath,
    ]);
    expect(tasks.every((t) => !t.isDone), isTrue);
  });

  test('un Adrigyl aujourd\'hui marque la tâche faite avec son heure', () {
    final event = makeEvent(startAt: DateTime(2026, 9, 21, 8), adrigyl: true);
    final tasks = compute(settings: const CareSettings(), events: [event], now: now);
    final adrigyl = tasks.firstWhere((t) => t.type == CareType.adrigyl);
    expect(adrigyl.isDone, isTrue);
    expect(adrigyl.lastDoneAt, event.startAt);
  });

  test('un Adrigyl d\'hier ne compte pas pour aujourd\'hui (1/jour)', () {
    final event = makeEvent(startAt: DateTime(2026, 9, 20, 8), adrigyl: true);
    final tasks = compute(settings: const CareSettings(), events: [event], now: now);
    final adrigyl = tasks.firstWhere((t) => t.type == CareType.adrigyl);
    expect(adrigyl.isDone, isFalse);
    expect(adrigyl.lastDoneAt, isNull);
  });

  test('2/jour avec une prise reste à faire', () {
    final event = makeEvent(startAt: DateTime(2026, 9, 21, 8), adrigyl: true);
    final tasks = compute(
      settings: const CareSettings(adrigyl: CareFrequency(timesPerDay: 2)),
      events: [event],
      now: now,
    );
    final adrigyl = tasks.firstWhere((t) => t.type == CareType.adrigyl);
    expect(adrigyl.target, 2);
    expect(adrigyl.done, 1);
    expect(adrigyl.isDone, isFalse);
  });

  test('nombril 3 par jour par défaut : deux soins faits, reste à faire', () {
    final tasks = compute(
      settings: const CareSettings(),
      events: [
        makeEvent(id: 'u1', startAt: DateTime(2026, 9, 21, 8), umbilicalCare: true),
        makeEvent(id: 'u2', startAt: DateTime(2026, 9, 21, 12), umbilicalCare: true),
      ],
      now: now,
    );
    final umbilical = tasks.firstWhere((t) => t.type == CareType.umbilicalCare);
    expect(umbilical.target, 3);
    expect(umbilical.done, 2);
    expect(umbilical.isDone, isFalse);
    expect(umbilical.lastDoneAt, DateTime(2026, 9, 21, 12));
  });

  test('soin désactivé : absent, même fait aujourd\'hui', () {
    final tasks = compute(
      settings: const CareSettings(umbilicalCare: CareFrequency(timesPerDay: 3, enabled: false)),
      events: [makeEvent(startAt: DateTime(2026, 9, 21, 8), umbilicalCare: true)],
      now: now,
    );
    expect(tasks.any((t) => t.type == CareType.umbilicalCare), isFalse);
  });

  test('tous les 2 jours, fait hier : absent', () {
    final tasks = compute(
      settings: everyTwoDays,
      events: [makeEvent(startAt: DateTime(2026, 9, 20, 18), adrigyl: true)],
      now: now,
    );
    expect(tasks.any((t) => t.type == CareType.adrigyl), isFalse);
  });

  test('tous les 2 jours, fait avant-hier : listé, à faire', () {
    final tasks = compute(
      settings: everyTwoDays,
      events: [makeEvent(startAt: DateTime(2026, 9, 19, 18), adrigyl: true)],
      now: now,
    );
    final adrigyl = tasks.firstWhere((t) => t.type == CareType.adrigyl);
    expect(adrigyl.isDone, isFalse);
    expect(adrigyl.target, 1);
  });

  test('tous les 2 jours, jamais fait : listé, à faire', () {
    final tasks = compute(settings: everyTwoDays, events: const [], now: now);
    expect(tasks.any((t) => t.type == CareType.adrigyl && !t.isDone), isTrue);
  });

  test('tous les 2 jours, fait hier et aujourd\'hui : listé, fait', () {
    final today = makeEvent(id: 'a2', startAt: DateTime(2026, 9, 21, 9), adrigyl: true);
    final tasks = compute(
      settings: everyTwoDays,
      events: [
        makeEvent(id: 'a1', startAt: DateTime(2026, 9, 20, 9), adrigyl: true),
        today,
      ],
      now: now,
    );
    final adrigyl = tasks.firstWhere((t) => t.type == CareType.adrigyl);
    expect(adrigyl.isDone, isTrue);
    expect(adrigyl.lastDoneAt, today.startAt);
  });

  test('bain hier (tous les 2 jours par défaut) : pas attendu aujourd\'hui', () {
    final tasks = compute(
      settings: const CareSettings(),
      events: [makeEvent(startAt: DateTime(2026, 9, 20, 18), bath: true)],
      now: now,
    );
    expect(tasks.any((t) => t.type == CareType.bath), isFalse);
  });

  test('DST : bain de 2 jours civils reste attendu malgré le changement d\'heure', () {
    final tasks = compute(
      settings: const CareSettings(),
      events: [makeEvent(startAt: DateTime(2026, 3, 28, 20), bath: true)],
      now: DateTime(2026, 3, 30, 8),
    );
    expect(tasks.any((t) => t.type == CareType.bath && !t.isDone), isTrue);
  });
}
```

Dans `test/features/baby/data/baby_profile_dto_test.dart`, remplacer les six tests avant `group('dailyTargetMl'` (de `CareSettingsDto.fromMap ignore une valeur non numérique` à `CareSettingsDto.toMap écrit umbilicalCarePerDay…`) par :

```dart
  group('CareFrequency', () {
    test('toMap écrit une map par soin et plus aucun champ plat', () {
      final map = CareSettingsDto.toMap(const CareSettings());
      expect(map['adrigyl'], {'timesPerDay': 1, 'everyDays': 1, 'enabled': true});
      expect(map['umbilicalCare'], {'timesPerDay': 3, 'everyDays': 1, 'enabled': true});
      expect(map['bath'], {'timesPerDay': 1, 'everyDays': 2, 'enabled': true});
      for (final legacy in [
        'adrigylPerDay',
        'eyeCarePerDay',
        'noseCarePerDay',
        'umbilicalCarePerDay',
        'umbilicalCareEnabled',
        'bathEveryDays',
      ]) {
        expect(map.containsKey(legacy), isFalse, reason: legacy);
      }
    });

    test('aller-retour', () {
      const settings = CareSettings(
        adrigyl: CareFrequency(everyDays: 3, enabled: false),
        bath: CareFrequency(timesPerDay: 2),
      );
      expect(CareSettingsDto.fromMap(CareSettingsDto.toMap(settings)), settings);
    });

    test('map vide : défauts', () {
      expect(CareSettingsDto.fromMap(const {}), const CareSettings());
    });

    test('map de soin : bornes 1..10 et 1..30, enabled vrai par défaut', () {
      final settings = CareSettingsDto.fromMap(const {
        'adrigyl': {'timesPerDay': 99},
        'bath': {'everyDays': 60, 'enabled': 'oui'},
        'eyeCare': {'timesPerDay': 0, 'everyDays': -1},
      });
      expect(settings.adrigyl, const CareFrequency(timesPerDay: 10));
      expect(settings.bath, const CareFrequency(everyDays: 30));
      expect(settings.eyeCare, const CareFrequency());
    });

    test('map de soin : deux entiers > 1 → timesPerDay ramené à 1', () {
      expect(
        CareSettingsDto.fromMap(const {
          'noseCare': {'timesPerDay': 3, 'everyDays': 2},
        }).noseCare,
        const CareFrequency(everyDays: 2),
      );
    });

    test('ancien entier xPerDay : n > 0 → n/jour, 0 → désactivé avec la fréquence par défaut', () {
      final settings = CareSettingsDto.fromMap(const {
        'adrigylPerDay': 2,
        'eyeCarePerDay': 0,
        'noseCarePerDay': 99,
        'umbilicalCarePerDay': 0,
      });
      expect(settings.adrigyl, const CareFrequency(timesPerDay: 2));
      expect(settings.eyeCare, const CareFrequency(enabled: false));
      expect(settings.noseCare, const CareFrequency(timesPerDay: 10));
      expect(settings.umbilicalCare, const CareFrequency(timesPerDay: 3, enabled: false));
    });

    test('ancien entier non numérique ou non fini : défaut', () {
      expect(CareSettingsDto.fromMap(const {'bathEveryDays': '5'}).bath, const CareFrequency(everyDays: 2));
      expect(CareSettingsDto.fromMap(const {'adrigylPerDay': double.nan}).adrigyl, const CareFrequency());
    });

    test('ancien bathEveryDays : tous les n jours, borné 1..30', () {
      expect(CareSettingsDto.fromMap(const {'bathEveryDays': 3}).bath, const CareFrequency(everyDays: 3));
      expect(CareSettingsDto.fromMap(const {'bathEveryDays': 0}).bath, const CareFrequency());
      expect(CareSettingsDto.fromMap(const {'bathEveryDays': 60}).bath, const CareFrequency(everyDays: 30));
    });

    test('nombril : repli sur l\'ancien booléen umbilicalCareEnabled', () {
      expect(
        CareSettingsDto.fromMap(const {'umbilicalCareEnabled': false}).umbilicalCare,
        const CareFrequency(timesPerDay: 3, enabled: false),
      );
      expect(
        CareSettingsDto.fromMap(const {'umbilicalCareEnabled': true}).umbilicalCare,
        const CareFrequency(timesPerDay: 3),
      );
      expect(
        CareSettingsDto.fromMap(const {'umbilicalCarePerDay': 0, 'umbilicalCareEnabled': true}).umbilicalCare,
        const CareFrequency(timesPerDay: 3, enabled: false),
      );
    });

    test('la map de soin prime sur l\'ancien entier', () {
      expect(
        CareSettingsDto.fromMap(const {
          'adrigyl': {'everyDays': 2},
          'adrigylPerDay': 0,
        }).adrigyl,
        const CareFrequency(everyDays: 2),
      );
    });
  });

  test('CareSettingsDto.fromMap borne feedsPerDay', () {
    expect(CareSettingsDto.fromMap(const {'feedsPerDay': 0}).feedsPerDay, 1);
    expect(CareSettingsDto.fromMap(const {'feedsPerDay': double.infinity}).feedsPerDay, 8);
  });
```

Ajouter l'import `package:colette/features/baby/domain/entities/care_frequency.dart` en tête du fichier.

Dans `test/features/baby/data/firestore_baby_repository_test.dart` ligne 15, remplacer `careSettings: const CareSettings(bathEveryDays: 3),` par `careSettings: const CareSettings(bath: CareFrequency(everyDays: 3)),` et ajouter l'import `care_frequency.dart`.

- [ ] **Step 2 : tests rouges du contrôleur, du formulaire, de la section et des providers**

`test/features/baby/presentation/baby_settings_controller_test.dart` : remplacer les deux tests `setCordFallenAt…` par :

```dart
  test('setCordFallenAt coupe le suivi du nombril, fréquence conservée', () async {
    when(() => repo.saveProfile(any(), any()))
        .thenAnswer((_) async => right(null));
    final twoPerDay = profile.copyWith(
      careSettings: const CareSettings(
        umbilicalCare: CareFrequency(timesPerDay: 2),
      ),
    );
    final ok = await controller().setCordFallenAt(twoPerDay, DateTime(2026, 9, 12));
    expect(ok, isTrue);
    final saved =
        verify(() => repo.saveProfile('ABCDEFGH', captureAny())).captured.single
            as BabyProfile;
    expect(saved.cordFallenAt, DateTime(2026, 9, 12));
    expect(
      saved.careSettings.umbilicalCare,
      const CareFrequency(timesPerDay: 2, enabled: false),
    );
  });

  test('setCordFallenAt null rallume le suivi du nombril', () async {
    when(() => repo.saveProfile(any(), any()))
        .thenAnswer((_) async => right(null));
    final disabled = profile.copyWith(
      cordFallenAt: DateTime(2026, 9, 12),
      careSettings: const CareSettings(
        umbilicalCare: CareFrequency(timesPerDay: 2, enabled: false),
      ),
    );
    final ok = await controller().setCordFallenAt(disabled, null);
    expect(ok, isTrue);
    final saved =
        verify(() => repo.saveProfile('ABCDEFGH', captureAny())).captured.single
            as BabyProfile;
    expect(saved.cordFallenAt, isNull);
    expect(saved.careSettings.umbilicalCare, const CareFrequency(timesPerDay: 2));
  });
```

Ajouter l'import `care_frequency.dart`.

`test/features/events/presentation/event_form_sheet_test.dart` : dans le test `la puce nombril est masquée quand le soin est désactivé`, remplacer `careSettings: const CareSettings(umbilicalCarePerDay: 0),` par `careSettings: const CareSettings(umbilicalCare: CareFrequency(timesPerDay: 3, enabled: false)),` ; ajouter l'import `care_frequency.dart`.

`test/features/baby/presentation/care_settings_section_test.dart` : remplacer intégralement par :

```dart
import 'package:colette/features/baby/domain/entities/baby_profile.dart';
import 'package:colette/features/baby/domain/entities/care_frequency.dart';
import 'package:colette/features/baby/domain/repositories/baby_repository.dart';
import 'package:colette/features/baby/presentation/providers/baby_providers.dart';
import 'package:colette/features/baby/presentation/widgets/care_frequency_row.dart';
import 'package:colette/features/baby/presentation/widgets/care_settings_section.dart';
import 'package:colette/features/dashboard/presentation/providers/feeding_plan_sync.dart';
import 'package:colette/features/household/presentation/providers/household_providers.dart';
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

  late MockBabyRepository repo;

  Future<void> pumpSection(WidgetTester tester) async {
    repo = MockBabyRepository();
    when(() => repo.saveProfile(any(), any()))
        .thenAnswer((_) async => right(null));
    await pumpApp(
      tester,
      Scaffold(
        body: SingleChildScrollView(
          child: CareSettingsSection(profile: profile),
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
  }

  List<BabyProfile> savedProfiles() =>
      verify(() => repo.saveProfile('ABCDEFGH', captureAny()))
          .captured
          .cast<BabyProfile>();

  // Ordre des lignes : Adrigyl, yeux, nez, nombril, bain, puis le stepper biberons.
  final plusButtons = find.widgetWithIcon(IconButton, Icons.add);
  final minusButtons = find.widgetWithIcon(IconButton, Icons.remove);

  testWidgets('cinq lignes de soin avec switch, puis le stepper biberons', (
    tester,
  ) async {
    await pumpSection(tester);
    expect(find.byType(CareFrequencyRow), findsNWidgets(5));
    expect(find.byType(Switch), findsNWidgets(5));
    expect(find.text('Soin du nombril'), findsOneWidget);
    expect(find.text('Biberons par jour'), findsOneWidget);
    expect(find.text('tous les 2 jours'), findsOneWidget); // bain
  });

  testWidgets('deux taps rapides sur + s\'additionnent', (tester) async {
    await pumpSection(tester);
    await tester.tap(plusButtons.first);
    await tester.pump();
    await tester.tap(plusButtons.first);
    await tester.pumpAndSettle();
    expect(savedProfiles().last.careSettings.adrigyl.timesPerDay, 3);
    expect(
      find.descendant(
        of: find.byType(CareFrequencyRow).first,
        matching: find.text('3 fois par jour'),
      ),
      findsOneWidget,
    );
  });

  testWidgets('− depuis 1/jour passe Adrigyl à tous les 2 jours', (
    tester,
  ) async {
    await pumpSection(tester);
    await tester.tap(minusButtons.first);
    await tester.pumpAndSettle();
    expect(
      savedProfiles().last.careSettings.adrigyl,
      const CareFrequency(everyDays: 2),
    );
    expect(find.text('tous les 2 jours'), findsNWidgets(2)); // Adrigyl + bain
  });

  testWidgets('le + du nombril sauvegarde 4 fois par jour', (tester) async {
    await pumpSection(tester);
    await tester.tap(plusButtons.at(3));
    await tester.pumpAndSettle();
    expect(savedProfiles().last.careSettings.umbilicalCare.timesPerDay, 4);
  });

  testWidgets('le switch coupe le suivi du bain, fréquence conservée', (
    tester,
  ) async {
    await pumpSection(tester);
    await tester.tap(find.byType(Switch).at(4));
    await tester.pumpAndSettle();
    expect(
      savedProfiles().last.careSettings.bath,
      const CareFrequency(everyDays: 2, enabled: false),
    );
  });
}
```

`test/features/baby/presentation/settings_sections_merge_test.dart` : ligne 96, remplacer `expect(savedProfiles.last.careSettings.adrigylPerDay, 2);` par `expect(savedProfiles.last.careSettings.adrigyl.timesPerDay, 2);` et mettre à jour le commentaire des lignes 90-91 en `// Tape + sur la ligne Adrigyl (première ligne de CareSettingsSection, troisième bouton + après les deux de SleepSettingsSection).`

`test/features/dashboard/presentation/dashboard_page_test.dart` : remplacer `latestBathProvider.overrideWith((ref) => Stream.value(null)),` par

```dart
    weekEventsProvider.overrideWith(
      (ref) => Stream.value(recent ?? [adrigyl, bottle, lateBottle]),
    ),
```

`test/features/dashboard/presentation/dashboard_providers_test.dart` : remplacer `latestBathProvider.overrideWith((ref) => Stream.value(null)),` par `weekEventsProvider.overrideWith((ref) => const Stream.empty()),`.

`test/features/dashboard/presentation/todo_section_test.dart` : remplacer `latestBathProvider.overrideWith((ref) => Stream.value(null)),` par `weekEventsProvider.overrideWith((ref) => Stream.value(const [])),`.

- [ ] **Step 3 : vérifier l'échec**

Run: `dart analyze`
Expected: erreurs sur `CareFrequency`, `adrigyl`, `events:` etc. dans les tests.

- [ ] **Step 4 : implémentation**

`lib/features/baby/domain/entities/care_settings.dart`, remplacer intégralement :

```dart
import 'package:colette/features/baby/domain/entities/care_frequency.dart';
import 'package:colette/shared/domain/care_type.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

part 'care_settings.freezed.dart';

/// Fréquences des soins attendus, cible de lait ajustée et horaires de nuit.
@freezed
abstract class CareSettings with _$CareSettings {
  const CareSettings._();

  const factory CareSettings({
    @Default(CareFrequency()) CareFrequency adrigyl,
    @Default(CareFrequency()) CareFrequency eyeCare,
    @Default(CareFrequency()) CareFrequency noseCare,
    @Default(CareFrequency(timesPerDay: 3)) CareFrequency umbilicalCare,
    @Default(CareFrequency(everyDays: 2)) CareFrequency bath,
    @Default(8) int feedsPerDay,

    /// Heure (0-23) à partir de laquelle un endormissement est une nuit.
    @Default(20) int nightStartHour,

    /// Heure (0-23) à partir de laquelle un endormissement redevient une sieste.
    @Default(7) int nightEndHour,

    /// Cible journalière forcée en ml ; `null` = calcul OMS.
    int? dailyTargetMl,
  }) = _CareSettings;

  static const minDailyTargetMl = 100;
  static const maxDailyTargetMl = 1500;
  static const dailyTargetStepMl = 10;

  /// Fréquence d'un soin programmé ([CareType.isScheduled]).
  CareFrequency frequencyOf(CareType type) => switch (type) {
    CareType.adrigyl => adrigyl,
    CareType.eyeCare => eyeCare,
    CareType.noseCare => noseCare,
    CareType.umbilicalCare => umbilicalCare,
    CareType.bath => bath,
    CareType.pee ||
    CareType.poop ||
    CareType.diaperChange => throw ArgumentError.value(
      type,
      'type',
      'sans fréquence attendue',
    ),
  };

  /// Copie avec la fréquence d'un soin programmé remplacée.
  CareSettings withFrequency(CareType type, CareFrequency frequency) =>
      switch (type) {
        CareType.adrigyl => copyWith(adrigyl: frequency),
        CareType.eyeCare => copyWith(eyeCare: frequency),
        CareType.noseCare => copyWith(noseCare: frequency),
        CareType.umbilicalCare => copyWith(umbilicalCare: frequency),
        CareType.bath => copyWith(bath: frequency),
        CareType.pee ||
        CareType.poop ||
        CareType.diaperChange => throw ArgumentError.value(
          type,
          'type',
          'sans fréquence attendue',
        ),
      };
}
```

`lib/features/baby/data/dtos/baby_profile_dto.dart`, remplacer la classe `CareSettingsDto` (et ajouter `CareFrequencyDto` avant elle) :

```dart
/// Conversion `CareFrequency` ↔ map Firestore `{timesPerDay, everyDays, enabled}`.
abstract final class CareFrequencyDto {
  static const maxTimesPerDay = 10;
  static const maxEveryDays = 30;

  static Map<String, dynamic> toMap(CareFrequency frequency) => {
    'timesPerDay': frequency.timesPerDay,
    'everyDays': frequency.everyDays,
    'enabled': frequency.enabled,
  };

  /// Bornes 1..10 et 1..30, `enabled` vrai par défaut ; si les deux entiers
  /// dépassent 1, `timesPerDay` est ramené à 1 (invariant de l'entité).
  static CareFrequency fromMap(Map<String, dynamic> map) {
    final everyDays = _readInt(map, 'everyDays', 1, min: 1, max: maxEveryDays);
    final timesPerDay = everyDays > 1
        ? 1
        : _readInt(map, 'timesPerDay', 1, min: 1, max: maxTimesPerDay);
    final enabled = map['enabled'];
    return CareFrequency(
      timesPerDay: timesPerDay,
      everyDays: everyDays,
      enabled: enabled is bool ? enabled : true,
    );
  }

  /// Ancien entier « fois par jour » : `n > 0` → `n`/jour ; `0` → [fallback] désactivé.
  static CareFrequency fromLegacyPerDay(Object? raw, CareFrequency fallback) {
    if (raw is! num || !raw.isFinite) return fallback;
    final value = raw.toInt();
    if (value <= 0) return fallback.copyWith(enabled: false);
    return CareFrequency(timesPerDay: value.clamp(1, maxTimesPerDay));
  }

  static int _readInt(
    Map<String, dynamic> map,
    String key,
    int fallback, {
    required int min,
    required int max,
  }) {
    final raw = map[key];
    return (raw is num && raw.isFinite ? raw.toInt() : fallback).clamp(
      min,
      max,
    );
  }
}

/// Conversion `CareSettings` ↔ map Firestore.
abstract final class CareSettingsDto {
  static Map<String, dynamic> toMap(CareSettings settings) => {
    'adrigyl': CareFrequencyDto.toMap(settings.adrigyl),
    'eyeCare': CareFrequencyDto.toMap(settings.eyeCare),
    'noseCare': CareFrequencyDto.toMap(settings.noseCare),
    'umbilicalCare': CareFrequencyDto.toMap(settings.umbilicalCare),
    'bath': CareFrequencyDto.toMap(settings.bath),
    'feedsPerDay': settings.feedsPerDay,
    'nightStartHour': settings.nightStartHour,
    'nightEndHour': settings.nightEndHour,
    'dailyTargetMl': settings.dailyTargetMl?.clamp(
      CareSettings.minDailyTargetMl,
      CareSettings.maxDailyTargetMl,
    ),
  };

  static int _readInt(
    Map<String, dynamic> map,
    String key,
    int fallback, {
    required int min,
    required int max,
  }) {
    final raw = map[key];
    return (raw is num && raw.isFinite ? raw.toInt() : fallback).clamp(
      min,
      max,
    );
  }

  /// Entier optionnel borné ; absent ou non numérique → `null`.
  /// Arrondi au multiple de `step` le plus proche avant de borner.
  static int? _readOptionalInt(
    Map<String, dynamic> map,
    String key, {
    required int min,
    required int max,
    int step = 1,
  }) {
    final raw = map[key];
    if (raw is! num || !raw.isFinite) return null;
    final rounded = (raw.toInt() / step).round() * step;
    return rounded.clamp(min, max);
  }

  /// Map du soin si présente, sinon ancien entier `xPerDay`, sinon [fallback].
  static CareFrequency _readFrequency(
    Map<String, dynamic> map,
    String key, {
    required String legacyKey,
    required CareFrequency fallback,
  }) {
    if (map[key] case final Map<String, dynamic> nested) {
      return CareFrequencyDto.fromMap(nested);
    }
    return CareFrequencyDto.fromLegacyPerDay(map[legacyKey], fallback);
  }

  /// Documents antérieurs : entier `umbilicalCarePerDay`, ou booléen `umbilicalCareEnabled`.
  static CareFrequency _readUmbilicalCare(Map<String, dynamic> map) {
    final fallback = const CareSettings().umbilicalCare;
    if (map['umbilicalCare'] case final Map<String, dynamic> nested) {
      return CareFrequencyDto.fromMap(nested);
    }
    if (map['umbilicalCarePerDay'] is num) {
      return CareFrequencyDto.fromLegacyPerDay(
        map['umbilicalCarePerDay'],
        fallback,
      );
    }
    return map['umbilicalCareEnabled'] == false
        ? fallback.copyWith(enabled: false)
        : fallback;
  }

  /// Documents antérieurs : entier `bathEveryDays`.
  static CareFrequency _readBath(Map<String, dynamic> map) {
    final fallback = const CareSettings().bath;
    if (map['bath'] case final Map<String, dynamic> nested) {
      return CareFrequencyDto.fromMap(nested);
    }
    final raw = map['bathEveryDays'];
    if (raw is! num || !raw.isFinite) return fallback;
    return CareFrequency(
      everyDays: raw.toInt().clamp(1, CareFrequencyDto.maxEveryDays),
    );
  }

  /// Borne chaque valeur à une plage sûre : un document modifié à la main ne doit jamais casser les calculs.
  static CareSettings fromMap(Map<String, dynamic> map) {
    const defaults = CareSettings();
    return CareSettings(
      adrigyl: _readFrequency(
        map,
        'adrigyl',
        legacyKey: 'adrigylPerDay',
        fallback: defaults.adrigyl,
      ),
      eyeCare: _readFrequency(
        map,
        'eyeCare',
        legacyKey: 'eyeCarePerDay',
        fallback: defaults.eyeCare,
      ),
      noseCare: _readFrequency(
        map,
        'noseCare',
        legacyKey: 'noseCarePerDay',
        fallback: defaults.noseCare,
      ),
      umbilicalCare: _readUmbilicalCare(map),
      bath: _readBath(map),
      feedsPerDay: _readInt(map, 'feedsPerDay', 8, min: 1, max: 24),
      nightStartHour: _readInt(map, 'nightStartHour', 20, min: 0, max: 23),
      nightEndHour: _readInt(map, 'nightEndHour', 7, min: 0, max: 23),
      dailyTargetMl: _readOptionalInt(
        map,
        'dailyTargetMl',
        min: CareSettings.minDailyTargetMl,
        max: CareSettings.maxDailyTargetMl,
        step: CareSettings.dailyTargetStepMl,
      ),
    );
  }
}
```

Ajouter l'import `package:colette/features/baby/domain/entities/care_frequency.dart` en tête du DTO.

`lib/features/baby/presentation/providers/baby_settings_controller.dart`, remplacer `setCordFallenAt` :

```dart
  /// Renseigner la date coupe le suivi du nombril ; l'effacer le rallume. La fréquence est conservée.
  Future<bool> setCordFallenAt(BabyProfile profile, DateTime? date) {
    final umbilicalCare = profile.careSettings.umbilicalCare;
    return saveProfile(
      profile.copyWith(
        cordFallenAt: date,
        careSettings: profile.careSettings.copyWith(
          umbilicalCare: umbilicalCare.copyWith(enabled: date == null),
        ),
      ),
    );
  }
```

L'import `care_settings.dart` devient inutile dans ce fichier si `CareSettings` n'y est plus référencé : `updateCareSettings` l'utilise encore, le garder.

`lib/features/dashboard/domain/use_cases/compute_daily_care_status.dart`, remplacer intégralement :

```dart
import 'package:colette/core/dates/date_extensions.dart';
import 'package:colette/features/baby/domain/entities/care_frequency.dart';
import 'package:colette/features/baby/domain/entities/care_settings.dart';
import 'package:colette/features/dashboard/domain/entities/care_task.dart';
import 'package:colette/features/events/domain/entities/care_event.dart';
import 'package:colette/shared/domain/care_type.dart';

/// Soins attendus aujourd'hui, avec leur avancement.
class ComputeDailyCareStatus {
  const ComputeDailyCareStatus();

  /// [events] : les 7 derniers jours civils, aujourd'hui inclus
  /// (fenêtre de [CareFrequency.maxEveryDays] jours).
  List<CareTask> call({
    required CareSettings settings,
    required List<CareEvent> events,
    required DateTime now,
  }) => [
    for (final type in CareType.scheduled)
      if (_task(type, settings.frequencyOf(type), events, now) case final task?)
        task,
  ];

  /// Tâche présente si le suivi est actif et que le soin est dû ou déjà fait aujourd'hui.
  CareTask? _task(
    CareType type,
    CareFrequency frequency,
    List<CareEvent> events,
    DateTime now,
  ) {
    if (!frequency.enabled) return null;
    final matching = events.where((e) => e.has(type)).toList()
      ..sort((a, b) => a.startAt.compareTo(b.startAt));
    final today = matching.where((e) => e.startAt.isSameDay(now)).toList();
    final lastDoneAt = matching.isEmpty ? null : matching.last.startAt;
    final expected = frequency.isExpected(lastDoneAt: lastDoneAt, now: now);
    if (!expected && today.isEmpty) return null;
    return CareTask(
      type: type,
      target: frequency.timesPerDay,
      done: today.length,
      lastDoneAt: today.isEmpty ? null : today.last.startAt,
    );
  }
}
```

`lib/features/dashboard/presentation/providers/dashboard_providers.dart`, remplacer `dailyCareTasks` :

```dart
/// Soins attendus aujourd'hui.
@riverpod
List<CareTask> dailyCareTasks(Ref ref) {
  final profile = ref.watch(babyProfileProvider).value;
  if (profile == null) return const [];
  return const ComputeDailyCareStatus()(
    settings: profile.careSettings,
    events: ref.watch(weekEventsProvider).value ?? const [],
    now: ref.watch(currentMinuteProvider),
  );
}
```

`lib/features/events/presentation/widgets/event_form_sheet.dart`, lignes 124-129, remplacer :

```dart
    final umbilicalEnabled =
        ref.watch(babyProfileProvider).value?.careSettings.umbilicalCare.enabled ??
        true;
```

`lib/features/baby/presentation/widgets/care_settings_section.dart`, remplacer le `build` et ajouter la table des bornes :

```dart
  /// Borne haute « fois par jour » de chaque soin.
  static const _maxTimesPerDay = {
    CareType.adrigyl: 3,
    CareType.eyeCare: 4,
    CareType.noseCare: 4,
    CareType.umbilicalCare: 4,
    CareType.bath: 2,
  };

  @override
  Widget build(BuildContext context) {
    // Garde le contrôleur autoDispose vivant pendant l'await de updateCareSettings.
    ref.watch(babySettingsControllerProvider);
    final s = S.of(context);
    return ColetteCardSurface(
      padding: AppSpacing.sm.all,
      child: Column(
        spacing: AppSpacing.xs.value,
        children: [
          for (final type in CareType.scheduled)
            CareFrequencyRow(
              type: type,
              frequency: _settings.frequencyOf(type),
              maxTimesPerDay: _maxTimesPerDay[type]!,
              onChanged: (frequency) => _update(
                (settings) => settings.withFrequency(type, frequency),
              ),
            ),
          IntStepperRow(
            label: s.settingsFeedsPerDay,
            value: _settings.feedsPerDay,
            min: 4,
            max: 12,
            onChanged: (v) =>
                _update((settings) => settings.copyWith(feedsPerDay: v)),
          ),
        ],
      ),
    );
  }
```

Imports à ajouter : `package:colette/features/baby/presentation/widgets/care_frequency_row.dart`, `package:colette/shared/domain/care_type.dart`. La doc de classe devient `/// Fréquence et suivi de chaque soin, et nombre de biberons par jour.`

`lib/l10n/app_fr.arb` : supprimer les cinq lignes `settingsAdrigylPerDay`, `settingsEyeCarePerDay`, `settingsNoseCarePerDay`, `settingsBathEveryDays`, `settingsUmbilicalCarePerDay`.

Run:

```bash
flutter gen-l10n
dart run build_runner build -d
dart analyze
```

Expected: `dart analyze` sans erreur (les `.g.dart` et `.freezed.dart` régénérés).

- [ ] **Step 5 : tests verts**

Run: `flutter test`
Expected: toute la suite passe.

- [ ] **Step 6 : commit**

```bash
dart format lib test
git add -A lib test
git commit -m "feat: CareSettings sur CareFrequency, accueil sur la fenêtre de 7 jours"
```

---

### Task 6 : suppression de `latestBath`

**Files:**
- Modify: `lib/features/events/domain/repositories/events_repository.dart`
- Modify: `lib/features/events/data/repositories/firestore_events_repository.dart`
- Modify: `lib/features/events/presentation/providers/events_providers.dart`
- Test: `test/features/events/data/firestore_events_repository_test.dart`, `test/features/events/presentation/events_providers_retry_test.dart`

- [ ] **Step 1 : retirer les tests**

`test/features/events/data/firestore_events_repository_test.dart` : renommer le test `watchLatestBath et watchLatestBottle renvoient le dernier de chaque` en `watchLatestBottle et getLatestBottle renvoient le dernier biberon`, supprimer la ligne `expect((await repo.watchLatestBath(code).first)?.id, 'bath');` (garder la sauvegarde de l'événement `bath`, qui vérifie que le filtre ignore les non-biberons), et supprimer le test `watchLatestBath émet null sans bain`.

`test/features/events/presentation/events_providers_retry_test.dart` : supprimer le stub `when(() => repo.watchLatestBath(any()))…` et le test `latestBath remonte la failure…`.

- [ ] **Step 2 : implémentation**

- `events_repository.dart` : supprimer `Stream<CareEvent?> watchLatestBath(String householdCode);`.
- `firestore_events_repository.dart` : supprimer l'override `watchLatestBath`.
- `events_providers.dart` : supprimer le provider `latestBath` (doc comprise).

Run: `dart run build_runner build -d && dart analyze`
Expected: sans erreur. `grep -rn latestBath lib test` ne renvoie rien.

- [ ] **Step 3 : tests verts**

Run: `flutter test test/features/events`
Expected: tout passe.

- [ ] **Step 4 : commit**

```bash
dart format lib test
git add -A lib test
git commit -m "chore: suppression de latestBath, remplacé par la fenêtre de 7 jours"
```

---

### Task 7 : Cloud Functions — `CareFrequency` dans `types.ts`

**Files:**
- Modify: `functions/src/lib/types.ts`
- Test: `functions/src/lib/types.test.ts`

Toutes les commandes de cette tâche et des suivantes se lancent depuis `functions/`.

- [ ] **Step 1 : test rouge**

Remplacer intégralement `functions/src/lib/types.test.ts` :

```ts
import { describe, expect, it } from 'vitest';
import { DEFAULT_CARE_SETTINGS, withDefaults } from './types';

const daily = { timesPerDay: 1, everyDays: 1, enabled: true };

describe('withDefaults', () => {
  it('sans réglages : les valeurs par défaut du client', () => {
    expect(withDefaults(undefined)).toEqual(DEFAULT_CARE_SETTINGS);
    expect(withDefaults({})).toEqual(DEFAULT_CARE_SETTINGS);
    expect(DEFAULT_CARE_SETTINGS.umbilicalCare).toEqual({ timesPerDay: 3, everyDays: 1, enabled: true });
    expect(DEFAULT_CARE_SETTINGS.bath).toEqual({ timesPerDay: 1, everyDays: 2, enabled: true });
  });

  it('map de soin : bornes 1..10 et 1..30, enabled vrai par défaut', () => {
    const settings = withDefaults({
      adrigyl: { timesPerDay: 99 },
      bath: { everyDays: 60, enabled: 'oui' },
      eyeCare: { timesPerDay: 0, everyDays: -1 },
    } as never);
    expect(settings.adrigyl).toEqual({ timesPerDay: 10, everyDays: 1, enabled: true });
    expect(settings.bath).toEqual({ timesPerDay: 1, everyDays: 30, enabled: true });
    expect(settings.eyeCare).toEqual(daily);
  });

  it('map de soin : deux entiers > 1 → timesPerDay ramené à 1', () => {
    expect(withDefaults({ noseCare: { timesPerDay: 3, everyDays: 2 } }).noseCare).toEqual({
      timesPerDay: 1,
      everyDays: 2,
      enabled: true,
    });
  });

  it('map de soin : enabled faux conservé', () => {
    expect(withDefaults({ adrigyl: { everyDays: 3, enabled: false } }).adrigyl).toEqual({
      timesPerDay: 1,
      everyDays: 3,
      enabled: false,
    });
  });

  it('ancien entier xPerDay : n > 0 → n/jour, 0 → désactivé avec la fréquence par défaut', () => {
    const settings = withDefaults({ adrigylPerDay: 2, eyeCarePerDay: 0, noseCarePerDay: 99, umbilicalCarePerDay: 0 });
    expect(settings.adrigyl).toEqual({ timesPerDay: 2, everyDays: 1, enabled: true });
    expect(settings.eyeCare).toEqual({ ...daily, enabled: false });
    expect(settings.noseCare).toEqual({ timesPerDay: 10, everyDays: 1, enabled: true });
    expect(settings.umbilicalCare).toEqual({ timesPerDay: 3, everyDays: 1, enabled: false });
  });

  it('ancien entier non numérique, nul ou non fini : défaut', () => {
    expect(withDefaults({ adrigylPerDay: 'deux', bathEveryDays: null, umbilicalCarePerDay: Number.NaN } as never)).toEqual(
      DEFAULT_CARE_SETTINGS,
    );
  });

  it('ancien bathEveryDays : tous les n jours, borné 1..30', () => {
    expect(withDefaults({ bathEveryDays: 3 }).bath).toEqual({ timesPerDay: 1, everyDays: 3, enabled: true });
    expect(withDefaults({ bathEveryDays: 0 }).bath).toEqual(daily);
    expect(withDefaults({ bathEveryDays: 60 }).bath).toEqual({ timesPerDay: 1, everyDays: 30, enabled: true });
  });

  it("nombril : repli sur l'ancien booléen umbilicalCareEnabled", () => {
    expect(withDefaults({ umbilicalCareEnabled: false }).umbilicalCare).toEqual({
      timesPerDay: 3,
      everyDays: 1,
      enabled: false,
    });
    expect(withDefaults({ umbilicalCareEnabled: true }).umbilicalCare).toEqual(DEFAULT_CARE_SETTINGS.umbilicalCare);
    expect(withDefaults({ umbilicalCarePerDay: 0, umbilicalCareEnabled: true }).umbilicalCare.enabled).toBe(false);
  });

  it("la map de soin prime sur l'ancien entier", () => {
    expect(withDefaults({ adrigyl: { everyDays: 2 }, adrigylPerDay: 0 }).adrigyl).toEqual({
      timesPerDay: 1,
      everyDays: 2,
      enabled: true,
    });
  });

  it('feedsPerDay : borné 1..24, défaut 8', () => {
    expect(withDefaults({ feedsPerDay: 99 }).feedsPerDay).toBe(24);
    expect(withDefaults({ feedsPerDay: 0 }).feedsPerDay).toBe(1);
    expect(withDefaults({ feedsPerDay: Number.NaN }).feedsPerDay).toBe(8);
  });
});
```

- [ ] **Step 2 : vérifier l'échec**

Run: `npm test -- src/lib/types.test.ts`
Expected: échecs (`withDefaults` renvoie encore des entiers).

- [ ] **Step 3 : implémentation**

Dans `functions/src/lib/types.ts`, remplacer tout ce qui va de `export type CareSettings` à la fin de `withDefaults` (en conservant `BabyDoc`, `FeedingPlanDoc`, `DeviceDoc`, `Device`, `MedicalReminder*`, `EventDoc`, `CareEvent`, `toCareEvent`) par :

```ts
/** Fréquence d'un soin : `timesPerDay` fois par jour, ou une fois tous les `everyDays` jours (l'un des deux vaut 1). */
export type CareFrequency = {
  timesPerDay: number;
  everyDays: number;
  enabled: boolean;
};

export type CareSettings = {
  adrigyl: CareFrequency;
  eyeCare: CareFrequency;
  noseCare: CareFrequency;
  umbilicalCare: CareFrequency;
  bath: CareFrequency;
  feedsPerDay: number;
};

const DAILY: CareFrequency = { timesPerDay: 1, everyDays: 1, enabled: true };

export const DEFAULT_CARE_SETTINGS: CareSettings = {
  adrigyl: DAILY,
  eyeCare: DAILY,
  noseCare: DAILY,
  umbilicalCare: { timesPerDay: 3, everyDays: 1, enabled: true },
  bath: { timesPerDay: 1, everyDays: 2, enabled: true },
  feedsPerDay: 8,
};

export type StoredCareFrequency = Partial<CareFrequency>;

/** Réglages tels que stockés : une map par soin, ou les anciens champs plats des documents antérieurs. */
export type StoredCareSettings = {
  adrigyl?: StoredCareFrequency;
  eyeCare?: StoredCareFrequency;
  noseCare?: StoredCareFrequency;
  umbilicalCare?: StoredCareFrequency;
  bath?: StoredCareFrequency;
  feedsPerDay?: number;
  adrigylPerDay?: number;
  eyeCarePerDay?: number;
  noseCarePerDay?: number;
  umbilicalCarePerDay?: number;
  umbilicalCareEnabled?: boolean;
  bathEveryDays?: number;
};

const MAX_TIMES_PER_DAY = 10;
const MAX_EVERY_DAYS = 30;

/** Borne une valeur comme le client : un document modifié à la main ne doit jamais casser les calculs. */
function clamped(value: unknown, min: number, max: number, fallback: number): number {
  if (typeof value !== 'number' || !Number.isFinite(value)) return fallback;
  return Math.min(max, Math.max(min, Math.trunc(value)));
}

function isMap(value: unknown): value is StoredCareFrequency {
  return typeof value === 'object' && value !== null && !Array.isArray(value);
}

/** Map de soin : bornes 1..10 et 1..30, `enabled` vrai par défaut ; deux entiers > 1 → `timesPerDay` ramené à 1. */
function readFrequencyMap(raw: StoredCareFrequency): CareFrequency {
  const everyDays = clamped(raw.everyDays, 1, MAX_EVERY_DAYS, 1);
  const timesPerDay = everyDays > 1 ? 1 : clamped(raw.timesPerDay, 1, MAX_TIMES_PER_DAY, 1);
  return { timesPerDay, everyDays, enabled: typeof raw.enabled === 'boolean' ? raw.enabled : true };
}

/** Ancien entier « fois par jour » : `n > 0` → `n`/jour ; `0` → `fallback` désactivé. */
function readLegacyPerDay(value: unknown, fallback: CareFrequency): CareFrequency {
  if (typeof value !== 'number' || !Number.isFinite(value)) return fallback;
  const times = Math.trunc(value);
  if (times <= 0) return { ...fallback, enabled: false };
  return { timesPerDay: Math.min(MAX_TIMES_PER_DAY, times), everyDays: 1, enabled: true };
}

function readFrequency(nested: unknown, legacy: unknown, fallback: CareFrequency): CareFrequency {
  return isMap(nested) ? readFrequencyMap(nested) : readLegacyPerDay(legacy, fallback);
}

/** Documents antérieurs : entier `umbilicalCarePerDay`, ou booléen `umbilicalCareEnabled`. */
function readUmbilicalCare(raw: StoredCareSettings): CareFrequency {
  const fallback = DEFAULT_CARE_SETTINGS.umbilicalCare;
  if (isMap(raw.umbilicalCare)) return readFrequencyMap(raw.umbilicalCare);
  if (typeof raw.umbilicalCarePerDay === 'number') return readLegacyPerDay(raw.umbilicalCarePerDay, fallback);
  return raw.umbilicalCareEnabled === false ? { ...fallback, enabled: false } : fallback;
}

/** Documents antérieurs : entier `bathEveryDays`. */
function readBath(raw: StoredCareSettings): CareFrequency {
  const fallback = DEFAULT_CARE_SETTINGS.bath;
  if (isMap(raw.bath)) return readFrequencyMap(raw.bath);
  if (typeof raw.bathEveryDays !== 'number' || !Number.isFinite(raw.bathEveryDays)) return fallback;
  return { timesPerDay: 1, everyDays: clamped(raw.bathEveryDays, 1, MAX_EVERY_DAYS, fallback.everyDays), enabled: true };
}

/** Mêmes valeurs par défaut, mêmes bornes et même repli que `CareSettingsDto.fromMap` côté client. */
export function withDefaults(settings: StoredCareSettings | undefined): CareSettings {
  const raw = settings ?? {};
  const d = DEFAULT_CARE_SETTINGS;
  return {
    adrigyl: readFrequency(raw.adrigyl, raw.adrigylPerDay, d.adrigyl),
    eyeCare: readFrequency(raw.eyeCare, raw.eyeCarePerDay, d.eyeCare),
    noseCare: readFrequency(raw.noseCare, raw.noseCarePerDay, d.noseCare),
    umbilicalCare: readUmbilicalCare(raw),
    bath: readBath(raw),
    feedsPerDay: clamped(raw.feedsPerDay, 1, 24, d.feedsPerDay),
  };
}
```

Le fichier doit conserver `BabyDoc = { name: string; careSettings?: StoredCareSettings }`.

- [ ] **Step 4 : test vert**

Run: `npm test -- src/lib/types.test.ts`
Expected: 10 tests passent. (`care-status.test.ts` et `morning-digest.test.ts` échouent à la compilation jusqu'aux Tasks 8 et 9 ; ne pas lancer `npm run build` ici.)

- [ ] **Step 5 : commit**

```bash
git add src/lib/types.ts src/lib/types.test.ts
git commit -m "feat(functions): CareFrequency dans withDefaults, repli des champs plats"
```

---

### Task 8 : Cloud Functions — `care-frequency.ts` et `pendingCares` sur la fenêtre

**Files:**
- Create: `functions/src/lib/care-frequency.ts`
- Modify: `functions/src/lib/care-status.ts`
- Test: `functions/src/lib/care-frequency.test.ts` (nouveau), `functions/src/lib/care-status.test.ts`

- [ ] **Step 1 : tests rouges**

Créer `functions/src/lib/care-frequency.test.ts` :

```ts
import { describe, expect, it } from 'vitest';
import { CARE_WINDOW_DAYS, isExpected } from './care-frequency';

const now = new Date('2026-09-21T12:00:00Z'); // 14h à Paris
const daily = { timesPerDay: 1, everyDays: 1, enabled: true };
const everyTwoDays = { timesPerDay: 1, everyDays: 2, enabled: true };

describe('isExpected', () => {
  it('désactivé : jamais attendu', () => {
    expect(isExpected({ ...daily, enabled: false }, null, now)).toBe(false);
  });

  it("quotidien : toujours attendu, même fait aujourd'hui", () => {
    expect(isExpected(daily, null, now)).toBe(true);
    expect(isExpected(daily, new Date('2026-09-21T06:00:00Z'), now)).toBe(true);
  });

  it('tous les 2 jours : attendu sans historique ou après 2 jours civils', () => {
    expect(isExpected(everyTwoDays, null, now)).toBe(true);
    expect(isExpected(everyTwoDays, new Date('2026-09-20T16:00:00Z'), now)).toBe(false);
    expect(isExpected(everyTwoDays, new Date('2026-09-19T16:00:00Z'), now)).toBe(true);
  });

  it('jours civils de Paris : 23h30 UTC la veille est déjà « hier »', () => {
    // 2026-09-19T23:30Z = 20 septembre 01h30 à Paris → un seul jour civil avant le 21.
    expect(isExpected(everyTwoDays, new Date('2026-09-19T23:30:00Z'), now)).toBe(false);
  });

  it('la fenêtre couvre 7 jours', () => {
    expect(CARE_WINDOW_DAYS).toBe(7);
  });
});
```

Remplacer intégralement `functions/src/lib/care-status.test.ts` :

```ts
import { describe, expect, it } from 'vitest';
import { pendingCares } from './care-status';
import { DEFAULT_CARE_SETTINGS } from './types';

const now = new Date('2026-09-21T06:00:00Z'); // 8h à Paris
const everyTwoDays = { timesPerDay: 1, everyDays: 2, enabled: true };

describe('pendingCares', () => {
  it('sans événement : tous les soins par défaut sont en attente, dans l’ordre', () => {
    expect(pendingCares({ settings: DEFAULT_CARE_SETTINGS, events: [], now })).toEqual([
      'Adrigyl',
      'Soin des yeux',
      'Soin du nez',
      'Soin du nombril',
      'Bain',
    ]);
  });

  it("un soin fait aujourd'hui disparaît de la liste", () => {
    const pending = pendingCares({
      settings: DEFAULT_CARE_SETTINGS,
      events: [{ startAt: new Date('2026-09-21T05:00:00Z'), adrigyl: true }],
      now,
    });
    expect(pending).not.toContain('Adrigyl');
  });

  it("un soin quotidien fait hier reste en attente aujourd'hui", () => {
    const pending = pendingCares({
      settings: DEFAULT_CARE_SETTINGS,
      events: [{ startAt: new Date('2026-09-20T05:00:00Z'), adrigyl: true }],
      now,
    });
    expect(pending).toContain('Adrigyl');
  });

  it('soin désactivé : jamais en attente, même bain récent', () => {
    const pending = pendingCares({
      settings: { ...DEFAULT_CARE_SETTINGS, umbilicalCare: { ...DEFAULT_CARE_SETTINGS.umbilicalCare, enabled: false } },
      events: [{ startAt: new Date('2026-09-20T16:00:00Z'), bath: true }],
      now,
    });
    expect(pending).toEqual(['Adrigyl', 'Soin des yeux', 'Soin du nez']);
  });

  it('nombril 3 par jour : deux soins faits encore en attente, trois faits absent', () => {
    const care = (hour: string) => ({ startAt: new Date(`2026-09-21T${hour}:00:00Z`), umbilicalCare: true });
    expect(pendingCares({ settings: DEFAULT_CARE_SETTINGS, events: [care('03'), care('05')], now })).toContain(
      'Soin du nombril',
    );
    expect(
      pendingCares({ settings: DEFAULT_CARE_SETTINGS, events: [care('03'), care('04'), care('05')], now }),
    ).not.toContain('Soin du nombril');
  });

  it('2 par jour avec une prise faite : encore en attente', () => {
    const pending = pendingCares({
      settings: { ...DEFAULT_CARE_SETTINGS, adrigyl: { timesPerDay: 2, everyDays: 1, enabled: true } },
      events: [{ startAt: new Date('2026-09-21T05:00:00Z'), adrigyl: true }],
      now,
    });
    expect(pending).toContain('Adrigyl');
  });

  it('tous les 2 jours : fait hier absent, fait avant-hier ou jamais en attente', () => {
    const settings = { ...DEFAULT_CARE_SETTINGS, adrigyl: everyTwoDays };
    expect(
      pendingCares({ settings, events: [{ startAt: new Date('2026-09-20T05:00:00Z'), adrigyl: true }], now }),
    ).not.toContain('Adrigyl');
    expect(
      pendingCares({ settings, events: [{ startAt: new Date('2026-09-19T05:00:00Z'), adrigyl: true }], now }),
    ).toContain('Adrigyl');
    expect(pendingCares({ settings, events: [], now })).toContain('Adrigyl');
  });

  it("tous les 2 jours, fait hier et aujourd'hui : absent (fait)", () => {
    const pending = pendingCares({
      settings: { ...DEFAULT_CARE_SETTINGS, adrigyl: everyTwoDays },
      events: [
        { startAt: new Date('2026-09-20T05:00:00Z'), adrigyl: true },
        { startAt: new Date('2026-09-21T05:00:00Z'), adrigyl: true },
      ],
      now,
    });
    expect(pending).not.toContain('Adrigyl');
  });

  it('bain : hier absent, avant-hier en attente (tous les 2 jours par défaut)', () => {
    expect(
      pendingCares({
        settings: DEFAULT_CARE_SETTINGS,
        events: [{ startAt: new Date('2026-09-20T16:00:00Z'), bath: true }],
        now,
      }),
    ).not.toContain('Bain');
    expect(
      pendingCares({
        settings: DEFAULT_CARE_SETTINGS,
        events: [{ startAt: new Date('2026-09-19T16:00:00Z'), bath: true }],
        now,
      }),
    ).toContain('Bain');
  });
});
```

- [ ] **Step 2 : vérifier l'échec**

Run: `npm test -- src/lib/care-frequency.test.ts src/lib/care-status.test.ts`
Expected: échecs (`care-frequency` introuvable, `pendingCares` attend `todayEvents`).

- [ ] **Step 3 : implémentation**

Créer `functions/src/lib/care-frequency.ts` :

```ts
import { calendarDaysBetween } from './paris-time';
import type { CareFrequency } from './types';

/** Espacement maximal réglable (jours) : fenêtre d'événements suffisante pour savoir si un soin est dû. */
export const CARE_WINDOW_DAYS = 7;

/**
 * Soin dû aujourd'hui : suivi actif, et quotidien, jamais fait, ou dernier fait il y a au moins
 * `everyDays` jours civils (Paris). Même règle que `CareFrequency.isExpected` côté app.
 */
export function isExpected(frequency: CareFrequency, lastDoneAt: Date | null, now: Date): boolean {
  if (!frequency.enabled) return false;
  if (frequency.everyDays === 1 || !lastDoneAt) return true;
  return calendarDaysBetween(lastDoneAt, now) >= frequency.everyDays;
}
```

Remplacer intégralement `functions/src/lib/care-status.ts` :

```ts
import { isExpected } from './care-frequency';
import { calendarDaysBetween } from './paris-time';
import { CARE_LABELS } from './summary';
import type { CareEvent, CareSettings } from './types';

type Input = {
  settings: CareSettings;
  /** Les 7 derniers jours civils (Paris), aujourd'hui inclus. */
  events: CareEvent[];
  now: Date;
};

/** Soins programmés, dans l'ordre du dashboard et du digest. */
export const SCHEDULED_CARES = ['adrigyl', 'eyeCare', 'noseCare', 'umbilicalCare', 'bath'] as const;

/** Libellés des soins attendus aujourd'hui et pas encore faits, dans l'ordre du dashboard. */
export function pendingCares({ settings, events, now }: Input): string[] {
  const pending: string[] = [];
  for (const care of SCHEDULED_CARES) {
    const frequency = settings[care];
    if (!frequency.enabled) continue;
    const matching = events.filter((e) => e[care]).sort((a, b) => a.startAt.getTime() - b.startAt.getTime());
    const lastDoneAt = matching.length === 0 ? null : matching[matching.length - 1].startAt;
    if (!isExpected(frequency, lastDoneAt, now)) continue;
    const doneToday = matching.filter((e) => calendarDaysBetween(e.startAt, now) === 0).length;
    if (doneToday < frequency.timesPerDay) pending.push(CARE_LABELS[care]);
  }
  return pending;
}
```

- [ ] **Step 4 : tests verts**

Run: `npm test -- src/lib/care-frequency.test.ts src/lib/care-status.test.ts`
Expected: 14 tests passent.

- [ ] **Step 5 : commit**

```bash
git add src/lib/care-frequency.ts src/lib/care-frequency.test.ts src/lib/care-status.ts src/lib/care-status.test.ts
git commit -m "feat(functions): pendingCares sur la fenêtre de 7 jours avec CareFrequency"
```

---

### Task 9 : Cloud Functions — digest sur une requête de 7 jours, index retiré

**Files:**
- Modify: `functions/src/lib/paris-time.ts`
- Modify: `functions/src/morning-digest.ts`
- Modify: `firestore.indexes.json` (racine du dépôt)
- Test: `functions/src/lib/paris-time.test.ts`, `functions/src/morning-digest.test.ts`

- [ ] **Step 1 : tests rouges**

Dans `functions/src/lib/paris-time.test.ts`, ajouter `startOfDayInParis` à l'import et un bloc :

```ts
describe('startOfDayInParis', () => {
  it('donne minuit de Paris, daysAgo jours avant (heure d’été)', () => {
    expect(startOfDayInParis(new Date('2026-09-21T12:32:00Z'), 6).toISOString()).toBe('2026-09-14T22:00:00.000Z');
  });

  it("enjambe un changement d'heure sans décaler minuit", () => {
    // 30 mars 2026 (heure d'été) − 6 jours = 24 mars (heure d'hiver) : minuit Paris = 23h UTC.
    expect(startOfDayInParis(new Date('2026-03-30T10:00:00Z'), 6).toISOString()).toBe('2026-03-23T23:00:00.000Z');
  });
});
```

Dans `functions/src/morning-digest.test.ts` :

1. Dans `fakeQuery`, supprimer la ligne `if (field === 'bath') return Boolean(event.bath) === value;` et mettre le commentaire `/** Requête Firestore en mémoire : filtres sur `startAt`, tri et limite. */`.
2. Ajouter, après le test `ne compte pas les événements datés de demain` :

```ts
  it("un bain d'hier (tous les 2 jours) n'est pas en attente", async () => {
    households.push({
      id: 'ABC123',
      baby: { name: 'Colette' },
      devices: [{ id: 'd1' }],
      events: [{ startAt: at('2026-09-20T16:00:00Z'), bath: true }],
    });

    await handler();

    expect(sendToDevices.mock.calls[0][2].body).toBe(
      buildDigestBody(['Adrigyl', 'Soin des yeux', 'Soin du nez', 'Soin du nombril']),
    );
  });

  it('un Adrigyl tous les 2 jours fait hier reste absent, fait il y a 8 jours est en attente', async () => {
    const everyTwoDays = { timesPerDay: 1, everyDays: 2, enabled: true };
    households.push({
      id: 'ABC123',
      baby: { name: 'Colette', careSettings: { adrigyl: everyTwoDays } },
      devices: [{ id: 'd1' }],
      events: [{ startAt: at('2026-09-20T05:00:00Z'), adrigyl: true }],
    });
    households.push({
      id: 'DEF456',
      baby: { name: 'Léon', careSettings: { adrigyl: everyTwoDays } },
      devices: [{ id: 'd2' }],
      events: [{ startAt: at('2026-09-13T05:00:00Z'), adrigyl: true }],
    });

    await handler();

    expect(sendToDevices).toHaveBeenCalledTimes(2);
    expect(sendToDevices.mock.calls[0][2].body).not.toContain('Adrigyl');
    expect(sendToDevices.mock.calls[1][2].body).toContain('Adrigyl');
  });
```

- [ ] **Step 2 : vérifier l'échec**

Run: `npm test`
Expected: `paris-time.test.ts` échoue (`startOfDayInParis` absent), `morning-digest.test.ts` échoue à la compilation (`pendingCares` attend `events`).

- [ ] **Step 3 : implémentation**

`functions/src/lib/paris-time.ts`, ajouter après `startOfTomorrowInParis` :

```ts
/** Minuit à Paris, `daysAgo` jours avant le jour de `date` : borne basse de la fenêtre des soins. */
export function startOfDayInParis(date: Date, daysAgo: number): Date {
  return paris(date).startOf('day').minus({ days: daysAgo }).toJSDate();
}
```

`functions/src/morning-digest.ts` :

- Import : ajouter `import { CARE_WINDOW_DAYS } from './lib/care-frequency';` et `startOfDayInParis` dans l'import de `./lib/paris-time` ; retirer `startOfTodayInParis` s'il n'est plus utilisé.
- Remplacer le bloc `const events = doc.ref.collection('events'); … const pending = pendingCares({ … });` par :

```ts
      const eventsSnap = await doc.ref
        .collection('events')
        .where('startAt', '>=', Timestamp.fromDate(startOfDayInParis(now, CARE_WINDOW_DAYS - 1)))
        .where('startAt', '<', Timestamp.fromDate(startOfTomorrowInParis(now)))
        .get();

      const pending = pendingCares({
        settings: withDefaults(baby.careSettings),
        events: eventsSnap.docs.map((d) => toCareEvent(d.data() as EventDoc)),
        now,
      });
```

`firestore.indexes.json` : supprimer l'objet d'index `{ "collectionGroup": "events", …, "fields": [ { "fieldPath": "bath", … }, { "fieldPath": "startAt", "order": "DESCENDING" } ] }`. Il reste les index `hasBottle + startAt` et `diaperChange + startAt`.

- [ ] **Step 4 : tests verts et build**

Run: `npm test && npm run build`
Expected: toute la suite passe, `tsc` sans erreur.

- [ ] **Step 5 : commit**

```bash
git add src/lib/paris-time.ts src/lib/paris-time.test.ts src/morning-digest.ts src/morning-digest.test.ts ../firestore.indexes.json
git commit -m "feat(functions): digest du matin sur 7 jours, index bain retiré"
```

---

### Task 10 : documentation et vérification finale

**Files:**
- Modify: `docs/superpowers/specs/2026-09-21-colette-v1-design.md`
- Modify: `docs/superpowers/specs/2026-09-22-umbilical-care-per-day-design.md`

- [ ] **Step 1 : spec v1**

Section 5, remplacer le bloc `careSettings:` (lignes `adrigylPerDay: 1` à `feedsPerDay: 8`) par :

```
    careSettings:                     une map par soin, voir 2026-09-24-care-frequency-design.md
      adrigyl:       { timesPerDay: 1, everyDays: 1, enabled: true }
      eyeCare:       { timesPerDay: 1, everyDays: 1, enabled: true }
      noseCare:      { timesPerDay: 1, everyDays: 1, enabled: true }
      umbilicalCare: { timesPerDay: 3, everyDays: 1, enabled: true }   enabled passe à false quand cordFallenAt est renseigné, à true quand elle est effacée
      bath:          { timesPerDay: 1, everyDays: 2, enabled: true }
      feedsPerDay: 8
```

Section 6.2, remplacer le tableau « Soins attendus » et la ligne du use case par :

```
Soins attendus (depuis `careSettings`, règle commune aux cinq soins, voir `2026-09-24-care-frequency-design.md`) :

| Cas | Accueil |
| --- | --- |
| Suivi coupé (`enabled: false`) | Jamais listé, même fait aujourd'hui. |
| `timesPerDay` par jour (`everyDays` = 1) | Toujours listé, cible `timesPerDay`. |
| Tous les `everyDays` jours, dernier fait il y a moins de `everyDays` jours civils | Absent (bain lundi, tous les 2 jours : attendu mercredi). |
| Tous les `everyDays` jours, dû ou jamais fait | Listé, à faire. |
| Fait aujourd'hui, quelle que soit la fréquence | Listé, grisé « fait ». |

Le jour civil va de 00:00 à 23:59 heure locale de l'appareil.

Use case `ComputeDailyCareStatus(événements des 7 derniers jours, careSettings, now) → List<CareTask>`. Pur, testé.
```

Section 6.6, remplacer la ligne « Soins attendus : … » par :

```
- Soins attendus : une ligne par soin (Adrigyl, yeux, nez, nombril, bain) avec un interrupteur « suivi » et une fréquence réglable de « N fois par jour » à « tous les 7 jours » ; prises de biberon / jour.
```

Section 7, ligne `morningDigest`, remplacer « calcule les soins attendus non faits ce jour, sur les événements de `[minuit, minuit + 1 j)` Paris (même règle que §6.2, réimplémentée en TypeScript avec ses tests) » par « calcule les soins attendus non faits ce jour, sur les événements des 7 derniers jours civils Paris `[minuit − 6 j, minuit + 1 j)` (même règle que §6.2, réimplémentée en TypeScript avec ses tests) ».

- [ ] **Step 2 : ancienne spec nombril**

En tête de `docs/superpowers/specs/2026-09-22-umbilical-care-per-day-design.md`, sous la ligne « Date : 2026-09-22… », ajouter :

```
> Remplacée le 2026-09-24 par `2026-09-24-care-frequency-design.md` : `umbilicalCarePerDay` devient `umbilicalCare: CareFrequency`. Conservée pour l'historique et le repli de lecture.
```

- [ ] **Step 3 : vérification complète**

Depuis la racine du worktree :

```bash
dart run build_runner build -d
dart format lib test
dart analyze
flutter test
```

Expected: `dart analyze` « No issues found! », `flutter test` tout vert.

Depuis `functions/` :

```bash
npm test && npm run build
```

Expected: tout vert, `tsc` sans erreur.

Contrôle : `grep -rn "PerDay\b\|bathEveryDays\|latestBath" lib test functions/src --include='*.dart' --include='*.ts'` ne renvoie que `feedsPerDay` et les clés de repli du DTO / `withDefaults`.

- [ ] **Step 4 : contrôle visuel sur simulateur**

Lancer l'app sur un simulateur iPhone (`flutter run -d <simulateur>` ou l'outil simulateur), puis :

1. Réglages → carte des soins : cinq lignes avec switch, « 1 fois par jour » ×3, « 3 fois par jour » (nombril), « tous les 2 jours » (bain). Le − sur Adrigyl affiche « tous les 2 jours », le + revient à « 1 fois par jour ». Couper un switch grise la ligne.
2. Aujourd'hui → « Reste à faire » : un soin réglé « tous les 2 jours » et enregistré hier n'apparaît pas ; un soin dont le switch est coupé n'apparaît pas.
3. Basculer le thème sombre (Réglages iOS → Apparence) et revérifier la lisibilité des deux écrans.

- [ ] **Step 5 : commit**

```bash
git add docs
git commit -m "docs: spec v1 alignée sur CareFrequency"
```

Puis suivre `superpowers:finishing-a-development-branch` : merge `--no-ff` dans `main` avec un message `merge: …`, validé par Maxence, jamais de push implicite.
