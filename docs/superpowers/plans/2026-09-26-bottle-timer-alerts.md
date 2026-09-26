# Minuteur de biberon : écran allumé, sons, enregistrement automatique — plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal :** garder l'écran allumé pendant le minuteur, jouer un son à la fin de chaque phase et enregistrer le soin automatiquement à la fin.

**Architecture :** une entité `BottleTimerRun` mémorise le lancement et la fin réelle du biberon. Une fonction pure `bottleTimerTransition` qualifie chaque changement de phase. `bottleTimerEffectsProvider` traduit ces transitions en appels au canal natif `colette/device`, et `EventFormSheet` enregistre le soin sur `finished`.

**Tech Stack :** Flutter, Riverpod 3 codegen, freezed, Swift (`AudioToolbox`, `UIApplication`).

Spec : `docs/superpowers/specs/2026-09-26-bottle-timer-alerts-design.md`.

---

### Task 1 : domaine (`BottleTimerRun`, phases, transitions)

**Files :**
- Create : `lib/features/events/domain/entities/bottle_timer_run.dart`
- Modify : `lib/features/events/domain/use_cases/bottle_timer.dart`
- Test : `test/features/events/domain/use_cases/bottle_timer_test.dart`

- [ ] Réécrire les tests de phase avec `BottleTimerRun.startingAt(start)`. Ajouter :
  - avec `feedingEndsAt = start + 10 min`, phase Verticale à +10 min (12 min restantes) et Terminé à +22 min ;
  - tests de `bottleTimerTransition` pour chaque ligne de la spec.
- [ ] Lancer les tests : ils doivent échouer (compilation).
- [ ] Implémenter l'entité freezed, puis `computeBottleTimerPhase({run, now})`, `BottleTimerTransition` et `bottleTimerTransition`.
- [ ] `dart run build_runner build -d`, relancer les tests : ils doivent passer. Commit `feat: fin réelle du biberon et transitions du minuteur`.

### Task 2 : contrôleur, `DeviceFeedback` et effets

**Files :**
- Create : `lib/core/device/device_feedback.dart`, `test/helpers/fake_device_feedback.dart`
- Modify : `lib/features/events/presentation/providers/bottle_timer_controller.dart`, `lib/features/events/presentation/widgets/bottle_timer_section.dart` (retrait de la vibration)
- Test : `test/features/events/presentation/bottle_timer_controller_test.dart`

- [ ] Tests du contrôleur adaptés à `BottleTimerRun`. Tests d'effets avec `FakeDeviceFeedback`, qui enregistre les appels dans une liste de chaînes (`'screen:on'`, `'sound:feedingEnded'`…) :
  - lancement → `screen:on` ;
  - tick à +30 min → `sound:feedingEnded` ;
  - tick à +42 min → `sound:uprightEnded`, `screen:off` ;
  - `reset` → `screen:off` ;
  - `container.dispose()` → `screen:off` ;
  - saut direct de +5 min à +50 min → seulement `sound:uprightEnded`, `screen:off`.
- [ ] Lancer les tests : ils doivent échouer.
- [ ] Implémenter `DeviceFeedback` / `NativeDeviceFeedback` / `deviceFeedbackProvider`, le contrôleur (`BottleTimerRun?`), `bottleTimerPhaseProvider` (sur `run`) et `bottleTimerEffectsProvider`.
- [ ] Codegen, puis tests verts. Commit `feat: écran allumé, sons et vibrations aux transitions du minuteur`.

### Task 3 : enregistrement automatique

**Files :**
- Modify : `lib/features/events/presentation/widgets/event_form_sheet.dart`
- Test : `test/features/events/presentation/event_form_sheet_timer_test.dart`

- [ ] Tests :
  - lancement puis tick à +42 min → `repo.save` appelé avec `startAt` = lancement, `endAt` = +30 min, `bottleMl` 120 ; feuille fermée ;
  - lancement, « Biberon terminé » à +10 min (horloge mutable), tick à +22 min → `endAt` = +10 min.
- [ ] Lancer les tests : ils doivent échouer.
- [ ] Dans `build`, ajouter `ref.watch(bottleTimerEffectsProvider)` et un `ref.listen(bottleTimerPhaseProvider)` qui appelle `_autoSave()` sur `finished`. `_autoSave` lit le `run`, ne fait rien si le contrôleur d'enregistrement est déjà en `AsyncLoading`, sinon applique `startAt` / `endAt` puis `_save()`.
- [ ] Tests verts. Commit `feat: enregistrement automatique du soin à la fin du minuteur`.

### Task 4 : canal natif Swift

**Files :**
- Modify : `ios/Runner/AppDelegate.swift`

- [ ] Enregistrer `FlutterMethodChannel("colette/device")` dans `didInitializeImplicitFlutterEngine`, via `registrar(forPlugin: "DevicePlugin")`, avec deux méthodes :
  - `setKeepScreenOn` (argument `Bool`) → `UIApplication.shared.isIdleTimerDisabled` ;
  - `playSound` (argument `String`) → `AudioServicesPlaySystemSound(1007 | 1008)`.
- [ ] `flutter build ios --simulator --debug` compile.
- [ ] `dart format lib test`, `dart analyze`, `flutter test`. Commit `feat: canal natif colette/device (veille et sons système)`.
