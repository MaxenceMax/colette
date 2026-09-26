# Minuteur de biberon : écran allumé, sons et enregistrement automatique — design

Date : 2026-09-26. Complète `2026-09-25-bottle-timer-design.md`.

## Objectif

Pendant le minuteur de biberon (30 min de biberon puis 12 min à la verticale) :

1. l'iPhone ne se verrouille pas ;
2. un son marque la fin du biberon, un autre la fin de la verticale ;
3. à la fin de la verticale, le soin est enregistré automatiquement et le formulaire se ferme.

## Décisions

- **Pas de package** : un canal natif `colette/device` dans `AppDelegate.swift`.
  - `setKeepScreenOn(bool)` : `UIApplication.shared.isIdleTimerDisabled`.
  - `playSound(String)` : `AudioServicesPlaySystemSound`. Ces sons système **respectent le mode silencieux** ; la vibration reste.
  - `feedingEnded` → son système 1007 (« tri-tone ») ; `uprightEnded` → 1008 (« carillon »).
- **Enregistrement automatique** : `startAt` = lancement du minuteur, `endAt` = fin réelle du biberon (30 min après le lancement, ou le moment du « Biberon terminé »). Le reste du brouillon (quantité, soins cochés, note) est conservé. Enregistrer puis fermer la feuille ; en cas d'échec, la feuille reste ouverte avec le message d'erreur habituel. Rien si un enregistrement est déjà en cours.
- Si l'app a été suspendue (verrouillage manuel) et que la phase saute de Biberon à Terminé au retour, seul le son de fin joue, puis l'enregistrement automatique a lieu.

## Domaine

- `lib/features/events/domain/entities/bottle_timer_run.dart` (freezed) : `BottleTimerRun(startedAt, feedingEndsAt)`, fabrique `BottleTimerRun.startingAt(start)` (fin du biberon à `start + 30 min`), getter `uprightEndsAt = feedingEndsAt + 12 min`.
- `computeBottleTimerPhase({required BottleTimerRun run, required DateTime now})` :
  - `now` antérieur à `startedAt` compte comme `startedAt` ;
  - `now < feedingEndsAt` : `BottleFeeding(feedingEndsAt − now, (now − startedAt) / 30 min)` ;
  - `now < uprightEndsAt` : `BottleUpright(uprightEndsAt − now, (now − feedingEndsAt) / 12 min)` ;
  - sinon `BottleTimerDone()`.
- `enum BottleTimerTransition { started, feedingEnded, finished, stopped }` et `bottleTimerTransition(previous, next)` (phases nullable) :
  - repos ou terminé → en cours : `started` ;
  - Biberon → Verticale : `feedingEnded` ;
  - en cours → Terminé : `finished` ;
  - en cours → repos : `stopped` ;
  - sinon `null`.

## Présentation

- `lib/core/device/device_feedback.dart` : `enum AppSound { feedingEnded, uprightEnded }`, interface `DeviceFeedback` (`setKeepScreenOn`, `playSound`), `NativeDeviceFeedback` (canal `colette/device`, erreurs loguées via `dart:developer`), provider `deviceFeedbackProvider` (keepAlive).
- `BottleTimerController` : état `BottleTimerRun?` ; `start()`, `skipToUpright()` (met `feedingEndsAt` à maintenant, seulement en phase Biberon), `reset()`.
- `bottleTimerEffectsProvider` (autoDispose, watché par `EventFormSheet`) : écoute `bottleTimerPhaseProvider` et applique la transition :
  - `started` : écran maintenu allumé ;
  - `feedingEnded` : son `feedingEnded` + vibration ;
  - `finished` : son `uprightEnded` + vibration + écran relâché ;
  - `stopped` : écran relâché ;
  - à sa destruction (fermeture de la feuille) : écran relâché.
- La vibration quitte `BottleTimerSection` pour ce provider.
- `EventFormSheet` : `ref.listen(bottleTimerPhaseProvider)` ; sur `finished`, applique `startAt` / `endAt` du minuteur au brouillon et appelle `_save()`.

## Tests

- Domaine : phases avec et sans « Biberon terminé », transitions.
- Contrôleur : `start`, `skipToUpright` conserve `startedAt`, `reset`.
- Effets (conteneur + faux `DeviceFeedback`) : écran allumé au lancement, son 1 à la fin du biberon, son 2 et écran relâché à la fin, écran relâché à l'arrêt et à la destruction, saut Biberon → Terminé ne joue que le son 2.
- Formulaire : fin du minuteur → soin enregistré avec les heures du minuteur et la quantité, feuille fermée ; avec « Biberon terminé », `endAt` = moment du clic.
- Swift : vérifié sur simulateur ou iPhone (son et veille).
