# Minuteur de biberon — plan d'implémentation

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal :** ajouter dans la section Biberon du formulaire de soin un minuteur facultatif : 30 min de biberon, puis 12 min à la verticale.

**Architecture :** une fonction pure `computeBottleTimerPhase` calcule la phase à partir de `startedAt` et de `now`. Trois providers `autoDispose` portent l'état : `BottleTimerController` (l'heure de départ), `bottleTimerTick` (un tick par seconde) et `bottleTimerPhase` (la phase dérivée). Le widget `BottleTimerSection` s'affiche dans `BottleField`. `EventFormSheet` bloque la fermeture par `PopScope` et demande confirmation tant que le minuteur tourne.

**Tech Stack :** Flutter, Riverpod 3 codegen, flutter_test, mocktail.

Spec : `docs/superpowers/specs/2026-09-25-bottle-timer-design.md`.

---

## Fichiers

- Create : `lib/features/events/domain/use_cases/bottle_timer.dart` (phases et calcul pur)
- Create : `lib/features/events/presentation/providers/bottle_timer_controller.dart` (+ `.g.dart`)
- Create : `lib/features/events/presentation/widgets/bottle_timer_section.dart`
- Modify : `lib/core/dates/time_format.dart` (ajout de `formatCountdown`)
- Modify : `lib/l10n/app_fr.arb`
- Modify : `lib/features/events/presentation/widgets/bottle_field.dart`
- Modify : `lib/features/events/presentation/widgets/event_form_sheet.dart`
- Test : `test/features/events/domain/use_cases/bottle_timer_test.dart`
- Test : `test/features/events/presentation/bottle_timer_controller_test.dart`
- Test : `test/features/events/presentation/bottle_timer_section_test.dart`

---

### Task 1 : domaine `computeBottleTimerPhase` et `formatCountdown`

- [ ] **Step 1 : test rouge** `test/features/events/domain/use_cases/bottle_timer_test.dart`

```dart
import 'package:colette/features/events/domain/use_cases/bottle_timer.dart';
import 'package:test/test.dart';

void main() {
  final start = DateTime(2026, 9, 25, 14);

  BottleTimerPhase at(Duration elapsed) =>
      computeBottleTimerPhase(startedAt: start, now: start.add(elapsed));

  test('au départ : biberon, 30 min restantes, progression nulle', () {
    expect(
      at(Duration.zero),
      isA<BottleFeeding>()
          .having((p) => p.remaining, 'remaining', const Duration(minutes: 30))
          .having((p) => p.progress, 'progress', 0),
    );
  });

  test('à 29:59 : encore biberon, 1 s restante', () {
    expect(
      at(const Duration(minutes: 29, seconds: 59)),
      isA<BottleFeeding>().having(
        (p) => p.remaining,
        'remaining',
        const Duration(seconds: 1),
      ),
    );
  });

  test('à 15 min : biberon à mi-parcours', () {
    expect(
      at(const Duration(minutes: 15)),
      isA<BottleFeeding>().having((p) => p.progress, 'progress', 0.5),
    );
  });

  test('à 30:00 : verticale, 12 min restantes', () {
    expect(
      at(const Duration(minutes: 30)),
      isA<BottleUpright>()
          .having((p) => p.remaining, 'remaining', const Duration(minutes: 12))
          .having((p) => p.progress, 'progress', 0),
    );
  });

  test('à 36 min : verticale à mi-parcours', () {
    expect(
      at(const Duration(minutes: 36)),
      isA<BottleUpright>().having((p) => p.progress, 'progress', 0.5),
    );
  });

  test('à 41:59 : encore verticale', () {
    expect(
      at(const Duration(minutes: 41, seconds: 59)),
      isA<BottleUpright>(),
    );
  });

  test('à 42:00 : terminé', () {
    expect(at(const Duration(minutes: 42)), isA<BottleTimerDone>());
  });

  test('une horloge antérieure au départ compte comme le départ', () {
    expect(
      at(const Duration(minutes: -5)),
      isA<BottleFeeding>().having(
        (p) => p.remaining,
        'remaining',
        const Duration(minutes: 30),
      ),
    );
  });
}
```

Et dans le test existant de `time_format` (ou un nouveau fichier `test/core/dates/format_countdown_test.dart`) :

```dart
import 'package:colette/core/dates/time_format.dart';
import 'package:test/test.dart';

void main() {
  test('formatCountdown affiche mm:ss', () {
    expect(formatCountdown(const Duration(minutes: 29, seconds: 5)), '29:05');
    expect(formatCountdown(Duration.zero), '00:00');
  });
}
```

- [ ] **Step 2 :** `flutter test test/features/events/domain/use_cases/bottle_timer_test.dart test/core/dates/format_countdown_test.dart` → FAIL (fichier absent).

- [ ] **Step 3 : implémentation** `lib/features/events/domain/use_cases/bottle_timer.dart`

```dart
/// Durée utile pour donner le biberon.
const bottleFeedingDuration = Duration(minutes: 30);

/// Durée de maintien à la verticale après le biberon.
const bottleUprightDuration = Duration(minutes: 12);

/// Phase du minuteur de biberon à un instant donné.
sealed class BottleTimerPhase {
  const BottleTimerPhase();
}

/// Biberon en cours.
final class BottleFeeding extends BottleTimerPhase {
  const BottleFeeding({required this.remaining, required this.progress});

  final Duration remaining;

  /// Avancement de la phase, entre 0 et 1.
  final double progress;
}

/// Maintien à la verticale en cours.
final class BottleUpright extends BottleTimerPhase {
  const BottleUpright({required this.remaining, required this.progress});

  final Duration remaining;

  /// Avancement de la phase, entre 0 et 1.
  final double progress;
}

/// Minuteur terminé.
final class BottleTimerDone extends BottleTimerPhase {
  const BottleTimerDone();
}

/// Phase du minuteur lancé à [startedAt], vue à [now].
BottleTimerPhase computeBottleTimerPhase({
  required DateTime startedAt,
  required DateTime now,
}) {
  final elapsed = now.isBefore(startedAt)
      ? Duration.zero
      : now.difference(startedAt);
  if (elapsed < bottleFeedingDuration) {
    return BottleFeeding(
      remaining: bottleFeedingDuration - elapsed,
      progress: elapsed.inMilliseconds / bottleFeedingDuration.inMilliseconds,
    );
  }
  final upright = elapsed - bottleFeedingDuration;
  if (upright < bottleUprightDuration) {
    return BottleUpright(
      remaining: bottleUprightDuration - upright,
      progress: upright.inMilliseconds / bottleUprightDuration.inMilliseconds,
    );
  }
  return const BottleTimerDone();
}
```

Et à la fin de `lib/core/dates/time_format.dart` :

```dart
/// « 29:05 ».
String formatCountdown(Duration duration) {
  final minutes = duration.inMinutes.toString().padLeft(2, '0');
  final seconds = (duration.inSeconds % 60).toString().padLeft(2, '0');
  return '$minutes:$seconds';
}
```

- [ ] **Step 4 :** relancer les tests → PASS.
- [ ] **Step 5 :** `git add` des 4 fichiers ; `git commit -m "feat: calcul des phases du minuteur de biberon"`.

### Task 2 : providers du minuteur

- [ ] **Step 1 : test rouge** `test/features/events/presentation/bottle_timer_controller_test.dart`

```dart
import 'dart:async';

import 'package:colette/core/clock/app_clock.dart';
import 'package:colette/features/events/domain/use_cases/bottle_timer.dart';
import 'package:colette/features/events/presentation/providers/bottle_timer_controller.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  final start = DateTime(2026, 9, 25, 14);
  late StreamController<DateTime> ticks;
  late ProviderContainer container;

  setUp(() {
    ticks = StreamController<DateTime>.broadcast();
    container = ProviderContainer(
      overrides: [
        clockProvider.overrideWithValue(FixedClock(start)),
        bottleTimerTickProvider.overrideWith((ref) => ticks.stream),
      ],
    );
    addTearDown(container.dispose);
    addTearDown(ticks.close);
    container.listen(bottleTimerPhaseProvider, (_, _) {});
  });

  test('au repos, pas de phase', () {
    expect(container.read(bottleTimerControllerProvider), isNull);
    expect(container.read(bottleTimerPhaseProvider), isNull);
  });

  test('start prend l\'heure de l\'horloge et démarre la phase biberon', () {
    container.read(bottleTimerControllerProvider.notifier).start();
    expect(container.read(bottleTimerControllerProvider), start);
    expect(container.read(bottleTimerPhaseProvider), isA<BottleFeeding>());
  });

  test('un tick à +30 min passe à la verticale', () async {
    container.read(bottleTimerControllerProvider.notifier).start();
    container.read(bottleTimerPhaseProvider);
    ticks.add(start.add(const Duration(minutes: 30)));
    await Future<void>.delayed(Duration.zero);
    expect(container.read(bottleTimerPhaseProvider), isA<BottleUpright>());
  });

  test('reset revient au repos', () {
    container.read(bottleTimerControllerProvider.notifier)
      ..start()
      ..reset();
    expect(container.read(bottleTimerPhaseProvider), isNull);
  });
}
```

- [ ] **Step 2 :** `flutter test test/features/events/presentation/bottle_timer_controller_test.dart` → FAIL.

- [ ] **Step 3 : implémentation** `lib/features/events/presentation/providers/bottle_timer_controller.dart`

```dart
import 'package:colette/core/clock/app_clock.dart';
import 'package:colette/features/events/domain/use_cases/bottle_timer.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'bottle_timer_controller.g.dart';

/// Heure de lancement du minuteur de biberon ; `null` au repos.
@riverpod
class BottleTimerController extends _$BottleTimerController {
  @override
  DateTime? build() => null;

  /// Lance (ou relance) le minuteur maintenant.
  void start() => state = ref.read(clockProvider).now();

  /// Arrête le minuteur.
  void reset() => state = null;
}

/// Heure courante, émise chaque seconde tant qu'un minuteur est lancé.
@riverpod
Stream<DateTime> bottleTimerTick(Ref ref) async* {
  final clock = ref.watch(clockProvider);
  yield clock.now();
  yield* Stream.periodic(const Duration(seconds: 1), (_) => clock.now());
}

/// Phase courante du minuteur de biberon ; `null` au repos.
@riverpod
BottleTimerPhase? bottleTimerPhase(Ref ref) {
  final startedAt = ref.watch(bottleTimerControllerProvider);
  if (startedAt == null) return null;
  final now =
      ref.watch(bottleTimerTickProvider).value ??
      ref.watch(clockProvider).now();
  return computeBottleTimerPhase(startedAt: startedAt, now: now);
}
```

- [ ] **Step 4 :** `dart run build_runner build -d` puis relancer le test → PASS.
- [ ] **Step 5 :** commit `feat: providers du minuteur de biberon`.

### Task 3 : chaînes et `BottleTimerSection`

- [ ] **Step 1 :** ajouter dans `lib/l10n/app_fr.arb` (avant la dernière clé) :

```json
  "bottleTimerStart": "Lancer le minuteur (30 + 12 min)",
  "bottleTimerFeeding": "Biberon",
  "bottleTimerUpright": "À la verticale",
  "bottleTimerDone": "Minuteur terminé",
  "bottleTimerStop": "Arrêter",
  "bottleTimerRestart": "Relancer",
  "bottleTimerCloseTitle": "Arrêter le minuteur ?",
  "bottleTimerCloseBody": "Le minuteur sera perdu si tu fermes le formulaire.",
  "bottleTimerContinue": "Continuer",
```

puis `flutter gen-l10n`.

- [ ] **Step 2 : test rouge** `test/features/events/presentation/bottle_timer_section_test.dart`

```dart
import 'dart:async';

import 'package:colette/core/clock/app_clock.dart';
import 'package:colette/features/events/presentation/providers/bottle_timer_controller.dart';
import 'package:colette/features/events/presentation/widgets/bottle_timer_section.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../helpers/pump_app.dart';

void main() {
  final start = DateTime(2026, 9, 25, 14);
  late StreamController<DateTime> ticks;

  setUp(() => ticks = StreamController<DateTime>.broadcast());
  tearDown(() => ticks.close());

  Future<void> pumpSection(WidgetTester tester) => pumpApp(
    tester,
    const Scaffold(body: BottleTimerSection()),
    overrides: [
      clockProvider.overrideWithValue(FixedClock(start)),
      bottleTimerTickProvider.overrideWith((ref) => ticks.stream),
    ],
  );

  Future<void> tick(WidgetTester tester, Duration elapsed) async {
    ticks.add(start.add(elapsed));
    await tester.pump();
    await tester.pump();
  }

  testWidgets('au repos, propose de lancer le minuteur', (tester) async {
    await pumpSection(tester);
    expect(find.text('Lancer le minuteur (30 + 12 min)'), findsOneWidget);
  });

  testWidgets('enchaîne biberon, verticale puis fin', (tester) async {
    await pumpSection(tester);
    await tester.tap(find.text('Lancer le minuteur (30 + 12 min)'));
    await tester.pump();
    expect(find.text('Biberon'), findsOneWidget);
    expect(find.text('30:00'), findsOneWidget);

    await tick(tester, const Duration(minutes: 10, seconds: 5));
    expect(find.text('19:55'), findsOneWidget);

    await tick(tester, const Duration(minutes: 30));
    expect(find.text('À la verticale'), findsOneWidget);
    expect(find.text('12:00'), findsOneWidget);

    await tick(tester, const Duration(minutes: 42));
    expect(find.text('Minuteur terminé'), findsOneWidget);
    expect(find.text('Relancer'), findsOneWidget);
  });

  testWidgets('Arrêter revient au repos', (tester) async {
    await pumpSection(tester);
    await tester.tap(find.text('Lancer le minuteur (30 + 12 min)'));
    await tester.pump();
    await tester.tap(find.text('Arrêter'));
    await tester.pump();
    expect(find.text('Lancer le minuteur (30 + 12 min)'), findsOneWidget);
  });
}
```

- [ ] **Step 3 :** lancer le test → FAIL.

- [ ] **Step 4 : implémentation** `lib/features/events/presentation/widgets/bottle_timer_section.dart`

```dart
import 'package:colette/core/dates/time_format.dart';
import 'package:colette/core/theme/app_colors.dart';
import 'package:colette/core/theme/design_tokens.dart';
import 'package:colette/core/theme/text_styles.dart';
import 'package:colette/features/events/domain/use_cases/bottle_timer.dart';
import 'package:colette/features/events/presentation/providers/bottle_timer_controller.dart';
import 'package:colette/l10n/generated/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Minuteur facultatif : 30 min de biberon puis 12 min à la verticale.
class BottleTimerSection extends ConsumerWidget {
  const BottleTimerSection({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final s = S.of(context);
    ref.listen(bottleTimerPhaseProvider, (previous, next) {
      if (previous != null &&
          next != null &&
          previous.runtimeType != next.runtimeType) {
        HapticFeedback.mediumImpact();
      }
    });
    final phase = ref.watch(bottleTimerPhaseProvider);
    void start() => ref.read(bottleTimerControllerProvider.notifier).start();
    void stop() => ref.read(bottleTimerControllerProvider.notifier).reset();
    return switch (phase) {
      null => Align(
        alignment: .centerLeft,
        child: OutlinedButton.icon(
          onPressed: start,
          icon: const Icon(Icons.timer_outlined),
          label: Text(s.bottleTimerStart),
        ),
      ),
      BottleFeeding(:final remaining, :final progress) => _RunningPhase(
        label: s.bottleTimerFeeding,
        remaining: remaining,
        progress: progress,
        onStop: stop,
      ),
      BottleUpright(:final remaining, :final progress) => _RunningPhase(
        label: s.bottleTimerUpright,
        remaining: remaining,
        progress: progress,
        onStop: stop,
      ),
      BottleTimerDone() => Row(
        children: [
          Icon(
            Icons.check_circle_outline,
            color: context.appColor(AppColors.categoryFeeding),
          ),
          AppSpacing.sm.horizontalSpace,
          Expanded(
            child: Text(
              s.bottleTimerDone,
              style: Theme.of(context).coletteTextStyles.bodyMedium,
            ),
          ),
          TextButton(onPressed: start, child: Text(s.bottleTimerRestart)),
        ],
      ),
    };
  }
}

class _RunningPhase extends StatelessWidget {
  const _RunningPhase({
    required this.label,
    required this.remaining,
    required this.progress,
    required this.onStop,
  });

  final String label;
  final Duration remaining;
  final double progress;
  final VoidCallback onStop;

  @override
  Widget build(BuildContext context) {
    final styles = Theme.of(context).coletteTextStyles;
    final color = context.appColor(AppColors.categoryFeeding);
    return Column(
      crossAxisAlignment: .stretch,
      children: [
        Row(
          children: [
            Icon(Icons.timer_outlined, color: color),
            AppSpacing.sm.horizontalSpace,
            Expanded(child: Text(label, style: styles.bodyMedium)),
            Text(formatCountdown(remaining), style: styles.numberMedium),
            AppSpacing.sm.horizontalSpace,
            TextButton(
              onPressed: onStop,
              child: Text(S.of(context).bottleTimerStop),
            ),
          ],
        ),
        ClipRRect(
          borderRadius: AppRadius.round.circular,
          child: LinearProgressIndicator(value: progress, color: color),
        ),
      ],
    );
  }
}
```

- [ ] **Step 5 :** relancer le test → PASS ; commit `feat: section minuteur de biberon`.

### Task 4 : intégration dans `BottleField` et `EventFormSheet`

- [ ] **Step 1 : tests rouges** à ajouter dans `bottle_timer_section_test.dart`, en montant la vraie sheet via `showEventFormSheet` (mêmes overrides que `event_form_sheet_test.dart`, plus le ticker) :
  - Biberon désactivé → pas de bouton « Lancer le minuteur » ; après activation → bouton présent.
  - Minuteur lancé puis `maybePop` du navigateur → dialogue « Arrêter le minuteur ? » ; « Continuer » → la sheet reste ; « Arrêter » → la sheet se ferme.
  - Minuteur lancé puis « Enregistrer » → la sheet se ferme sans dialogue et `repo.save` est appelé.
  - Désactiver Biberon pendant le minuteur puis `maybePop` → la sheet se ferme sans dialogue.

(Le code complet des tests est celui de `test/features/events/presentation/event_form_sheet_timer_test.dart`, écrit dans cette tâche avec un bouton hôte `Builder` → `showEventFormSheet(context)`.)

- [ ] **Step 2 :** `BottleField` : sous le `Wrap` des presets, ajouter `AppSpacing.sm.verticalSpace, const BottleTimerSection(),`.

- [ ] **Step 3 :** `EventFormSheet` :
  - `showEventFormSheet` : `enableDrag: false`.
  - Dans `build` : `final timerPhase = ref.watch(bottleTimerPhaseProvider);` et `final timerRunning = timerPhase is BottleFeeding || timerPhase is BottleUpright;`.
  - Envelopper le `Padding` dans :

```dart
PopScope(
  canPop: !timerRunning && !isLoading,
  onPopInvokedWithResult: (didPop, _) {
    if (!didPop && timerRunning) _confirmClose();
  },
  child: ...,
)
```

  - Ajouter :

```dart
Future<void> _confirmClose() async {
  final s = S.of(context);
  final stop = await showDialog<bool>(
    context: context,
    builder: (dialogContext) => AlertDialog(
      title: Text(s.bottleTimerCloseTitle),
      content: Text(s.bottleTimerCloseBody),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(dialogContext).pop(false),
          child: Text(s.bottleTimerContinue),
        ),
        TextButton(
          onPressed: () => Navigator.of(dialogContext).pop(true),
          child: Text(s.bottleTimerStop),
        ),
      ],
    ),
  );
  if (stop != true || !mounted) return;
  ref.read(bottleTimerControllerProvider.notifier).reset();
  Navigator.of(context).pop();
}
```

  - `_save` : `Navigator.of(context).pop(true)` au lieu de `maybePop(true)`.
  - `BottleField.onChanged` : si `ml == null`, appeler `ref.read(bottleTimerControllerProvider.notifier).reset()` avant `setState`.

- [ ] **Step 4 :** `flutter test test/features/events` → PASS.
- [ ] **Step 5 :** `dart format lib test`, `dart analyze`, `flutter test` ; commit `feat: minuteur de biberon dans le formulaire de soin`.
- [ ] **Step 6 :** vérifier sur le simulateur iPhone en thème clair et sombre.
