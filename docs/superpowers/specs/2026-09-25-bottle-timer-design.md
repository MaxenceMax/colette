# Minuteur de biberon — design

Date : 2026-09-25

## Objectif

Dans le formulaire de saisie d'un soin (`EventFormSheet`), section Biberon, proposer un minuteur facultatif en deux phases :

1. **Biberon** : 30 minutes, durée utile pour nourrir l'enfant ;
2. **À la verticale** : 12 minutes, enchaînées automatiquement à la fin de la première phase.

Le minuteur n'est jamais obligatoire : il n'influence ni le brouillon, ni la validation, ni l'enregistrement du soin.

## Décisions

- Le minuteur **vit dans le formulaire** : fermer ou enregistrer la sheet l'arrête.
- Alerte **uniquement dans l'app** : pas de notification locale, pas de nouveau package. Un retour haptique marque le changement de phase et la fin.
- **Local à l'iPhone** : rien n'est écrit dans Firestore.
- **Confirmation à la fermeture** : si le minuteur tourne (phase Biberon ou Verticale), taper hors de la sheet affiche « Arrêter le minuteur ? ». Enregistrer ferme sans demander.
- **Glisser pour fermer désactivé** (`enableDrag: false`) sur le formulaire de soin : dans Flutter, le glisser d'une bottom sheet modale appelle `Navigator.pop` et contourne `PopScope`, donc il ne peut pas être confirmé. On ferme en tapant hors de la sheet.
- Hors périmètre : pause, notifications, modification de l'heure de fin du soin, partage entre parents.

## Domaine

`lib/features/events/domain/use_cases/bottle_timer.dart` (pur Dart, sans Flutter) :

- `const bottleFeedingDuration = Duration(minutes: 30);`
- `const bottleUprightDuration = Duration(minutes: 12);`
- `sealed class BottleTimerPhase` :
  - `BottleFeeding(Duration remaining, double progress)` ;
  - `BottleUpright(Duration remaining, double progress)` ;
  - `BottleTimerDone()`.
- `BottleTimerPhase computeBottleTimerPhase({required DateTime startedAt, required DateTime now})` :
  - `elapsed = now - startedAt`, ramené à zéro s'il est négatif ;
  - si `elapsed < 30 min` : `BottleFeeding(30 min - elapsed, elapsed / 30 min)` ;
  - si `elapsed < 42 min` : `BottleUpright(42 min - elapsed, (elapsed - 30 min) / 12 min)` ;
  - sinon `BottleTimerDone()`.

La phase se calcule toujours à partir de `startedAt` et de l'horloge. Le décompte reste donc juste même si iOS suspend l'app en arrière-plan.

## Présentation

### `BottleTimerController`

`lib/features/events/presentation/providers/bottle_timer_controller.dart`, `@riverpod` (autoDispose) :

- l'état est un `DateTime?` (`startedAt`), `null` au repos ;
- `start()` : `state = ref.read(clockProvider).now()` ;
- `reset()` : `state = null` ;
- `skipToUpright()` : `state = now - bottleFeedingDuration` (sans effet au repos).

Il est `ref.watch`é (via `bottleTimerPhaseProvider`) par `EventFormSheet`, donc détruit à la fermeture de la sheet.

### `bottleTimerPhaseProvider`

`@riverpod BottleTimerPhase?` (autoDispose) : `null` au repos ; sinon il combine `startedAt` et le dernier tick (ou `clock.now()` avant le premier) via `computeBottleTimerPhase`. Le ticker n'est watché que si un minuteur est lancé.

### `bottleTimerTickProvider`

`@riverpod Stream<DateTime>` (autoDispose) : il émet `clock.now()` immédiatement puis chaque seconde. Il n'est watché que par `bottleTimerPhaseProvider` quand un minuteur est lancé.

### `BottleTimerSection`

`lib/features/events/presentation/widgets/bottle_timer_section.dart`, `ConsumerWidget`, affiché dans `BottleField` sous les presets, uniquement quand l'interrupteur Biberon est activé :

- **au repos** : `OutlinedButton.icon` « Lancer le minuteur (30 + 12 min) » ;
- **phase Biberon ou Verticale** :
  - libellé de phase (« Biberon » / « À la verticale ») ;
  - décompte `mm:ss` ;
  - `LinearProgressIndicator` de la phase, couleur `AppColors.categoryFeeding` ;
  - bouton « Arrêter » qui appelle `reset()` ;
  - en phase Biberon seulement, bouton « Biberon terminé » qui appelle `skipToUpright()` : l'heure de départ est recalée à `now - 30 min`, la verticale démarre donc avec 12 min pleines ;
- **terminé** : « Minuteur terminé » et bouton « Relancer » qui appelle `start()`.

Un `ref.listen` sur la phase dérivée déclenche `HapticFeedback.mediumImpact()` à chaque transition (Biberon → Verticale, Verticale → Terminé).

Désactiver l'interrupteur Biberon masque la section et appelle `reset()`.

### `EventFormSheet`

- Enveloppe le contenu dans `PopScope(canPop: !timerRunning && !isLoading)`, où `timerRunning` veut dire `startedAt != null` et une phase différente de `BottleTimerDone`.
- `onPopInvokedWithResult` : si `didPop` vaut `false` et que le minuteur tourne, afficher une `AlertDialog` « Arrêter le minuteur ? » avec les actions « Continuer » et « Arrêter ». Si l'utilisateur choisit « Arrêter », appeler `reset()` puis `Navigator.of(context).pop()`.
- `_save` : remplacer `maybePop(true)` par `Navigator.of(context).pop(true)`, comme dans `sleep_form_sheet.dart`, pour que l'enregistrement ferme sans confirmation.

### Chaînes (`app_fr.arb`)

- `bottleTimerStart` : « Lancer le minuteur (30 + 12 min) »
- `bottleTimerFeeding` : « Biberon »
- `bottleTimerUpright` : « À la verticale »
- `bottleTimerDone` : « Minuteur terminé »
- `bottleTimerStop` : « Arrêter »
- `bottleTimerRestart` : « Relancer »
- `bottleTimerCloseTitle` : « Arrêter le minuteur ? »
- `bottleTimerCloseBody` : « Le minuteur sera perdu si tu fermes le formulaire. »
- `bottleTimerContinue` : « Continuer »

## Tests

- **Domaine** (`test/features/events/domain/bottle_timer_test.dart`) :
  - bornes 0 s, 29:59, 30:00, 41:59, 42:00, et un `now` antérieur à `startedAt` ;
  - valeurs de `remaining` et `progress`.
- **Contrôleur** : `start` prend l'heure de `FixedClock`, `reset` remet l'état à `null`.
- **Widget** (`pumpApp`, `FixedClock` et override du ticker) :
  - bouton absent si Biberon est désactivé, présent sinon ;
  - après `start`, affichage de la phase Biberon et du décompte ;
  - avec l'horloge à +30 min, affichage de « À la verticale » ;
  - à +42 min, affichage de « Minuteur terminé » ;
  - « Enregistrer » reste actif et enregistre sans minuteur lancé ;
  - fermer pendant que le minuteur tourne affiche la confirmation, et « Continuer » laisse la sheet ouverte ;
  - enregistrer pendant que le minuteur tourne ferme la sheet sans confirmation.
- Vérification manuelle sur le simulateur iPhone, en thème clair et sombre.
