# Minuteur de biberon : Live Activity, notifications et reprise — design

Date : 2026-09-28. Complète `2026-09-25-bottle-timer-design.md` et `2026-09-26-bottle-timer-alerts-design.md`.

## Objectif

Le minuteur de biberon (30 min de biberon puis 12 min à la verticale) reste visible et utile quand l'app n'est plus au premier plan, y compris si iOS ou l'utilisateur l'a tuée :

1. une **Live Activity** l'affiche dans le Dynamic Island et sur l'écran verrouillé ;
2. deux **notifications locales** marquent la fin du biberon et la fin de la verticale ;
3. à la réouverture après une app tuée, le minuteur et le brouillon **reprennent** ; s'il est terminé, le soin est enregistré automatiquement.

## Décisions

- **Pas de package** : canal natif `colette/bottle-timer`, sur le modèle de `colette/device`. Deux méthodes idempotentes : `sync` et `clear`.
- **Affichage sans mise à jour** : une Live Activity ne change pas de vue seule à une date donnée ; seuls `Text(timerInterval:)` et `ProgressView(timerInterval:)` avancent sans l'app. Donc :
  - écran verrouillé et îlot étendu : les deux phases côte à côte, chacune avec son décompte (`startedAt…feedingEndsAt` et `feedingEndsAt…uprightEndsAt`) ; le décompte de la verticale reste à 12:00 tant que le biberon n'est pas fini ;
  - îlot compact : icône biberon à gauche, temps restant jusqu'à `uprightEndsAt` à droite ;
  - îlot minimal : icône biberon ;
  - `staleDate = uprightEndsAt` : vue « Minuteur terminé · Ouvre Colette pour enregistrer » quand `context.isStale`.
- **Pas de bouton** dans l'activité : un appui ouvre l'app (comportement par défaut, pas de lien profond). La feuille déjà ouverte ou la reprise font le reste.
- **Notifications locales** programmées en natif (`UNUserNotificationCenter`), identifiants `bottle-timer.feeding` et `bottle-timer.upright`, son par défaut. Masquées au premier plan (les sons de l'app prennent le relais). L'autorisation est celle déjà demandée pour FCM ; rien n'est redemandé.
- **Reprise** : la session (minuteur + brouillon) est persistée dans `shared_preferences` pendant que le minuteur tourne.
- **Design system** : les couleurs (cannelle, vert de la verticale, clair et sombre) et les textes de l'extension sont dupliqués côté Swift (asset catalog, `Localizable.strings` fr). Entorse assumée : Flutter ne peut pas les partager avec une Widget Extension.
- **Hors périmètre** : activité chez l'autre parent (push FCM), boutons interactifs (App Intents), son personnalisé.

## Domaine

- `lib/features/events/domain/entities/bottle_timer_session.dart` (freezed) : `BottleTimerSession({required BottleTimerRun run, required CareEvent draft, required bool editing})`. `editing` : minuteur lancé depuis l'édition d'un soin existant.
- `bottleTimerSessionExpiry = Duration(hours: 12)` et `isBottleTimerSessionExpired({required BottleTimerSession session, required DateTime now})` : vrai si `now − run.startedAt > 12 h`.

## Data

- `lib/features/events/data/bottle_timer_session_dto.dart` : `toJson` / `fromJson` (dates en millisecondes epoch UTC, brouillon via ses champs). Un JSON invalide lève une exception convertie par `guard()`.
- `BottleTimerSessionRepository` (interface domaine) et `SharedPrefsBottleTimerSessionRepository` (clé `bottle_timer_session`) :
  - `save(session)` → `Either<Failure, Unit>` ;
  - `load()` → `Either<Failure, BottleTimerSession?>` ; `null` si absente ;
  - `clear()` → `Either<Failure, Unit>`.
- Provider `bottleTimerSessionRepositoryProvider` (keepAlive).

## Pont natif

- `lib/core/device/bottle_timer_system.dart` : interface `BottleTimerSystem` avec `sync({required BottleTimerRun run, required String babyName})` et `clear()`, implémentation `NativeBottleTimerSystem` (canal `colette/bottle-timer`, arguments `startedAt`, `feedingEndsAt`, `uprightEndsAt` en millisecondes epoch, `babyName`, erreurs loguées via `dart:developer`, jamais propagées), provider `bottleTimerSystemProvider` (keepAlive).

## Présentation

- `bottleTimerEffectsProvider` (existant) écoute aussi `bottleTimerControllerProvider` :
  - nouveau `run` non nul (lancement, relance, « Biberon terminé », restauration) : `sync(run, prénom)`, le prénom venant de `babyProfileProvider` (feature `baby`, provider public) ; chaîne vide si le profil manque, l'activité affiche alors « Biberon » sans prénom ;
  - `run` → `null` (arrêt) : `clear()` et effacement de la session ;
  - destruction du provider (feuille fermée, y compris après l'enregistrement automatique) : `clear()` et effacement de la session. Un échec d'enregistrement laisse la feuille ouverte : l'activité reste en vue « terminé » et la session est conservée.
- `EventFormSheet` :
  - nouveau paramètre `restored` (`BottleTimerSession?`) : brouillon repris, `_isEditing = restored.editing`, et `BottleTimerController.restore(run)` au premier frame ;
  - si la phase restaurée est déjà `BottleTimerDone`, appel direct de `_autoSave()` (la transition `null → Done` ne déclenche rien, et aucun son ne joue : les notifications ont déjà sonné) ;
  - pendant que le minuteur tourne, chaque modification du brouillon (quantité, soins cochés, heures, note) et chaque changement de `run` sauvegarde la session.
- `BottleTimerController.restore(BottleTimerRun run)` : remet un minuteur existant sans changer ses dates.
- `BottleTimerResumeGate` (dans le shell, comme `NotificationsGate`), une fois au démarrage :
  - pas de session : `BottleTimerSystem.clear()` (ferme une activité orpheline) ;
  - session expirée : effacement et `clear()` ;
  - sinon : bascule sur l'onglet Aujourd'hui et `showEventFormSheet(context, restored: session)`.

## Natif iOS

- **Canal** dans `AppDelegate.swift` (`registerBottleTimerChannel`), code métier dans `ios/Runner/BottleTimer/` :
  - `sync` : si iOS ≥ 16.1 et `ActivityAuthorizationInfo().areActivitiesEnabled`, met à jour l'activité en cours (`Activity<BottleTimerAttributes>.activities.first`) ou en démarre une, avec `staleDate = uprightEndsAt` ; puis retire et reprogramme les deux notifications, en sautant celles dont l'heure est passée ;
  - `clear` : termine toutes les activités `BottleTimerAttributes` avec `dismissalPolicy: .immediate` et retire les notifications en attente et affichées `bottle-timer.*`.
- **Premier plan** : dans `userNotificationCenter(_:willPresent:)` de l'`AppDelegate`, les notifications dont l'identifiant commence par `bottle-timer.` sont présentées avec `[]` ; les autres suivent le comportement actuel (`super`, pour `firebase_messaging`).
- **`BottleTimerAttributes`** (fichier partagé entre Runner et l'extension) : attribut fixe `babyName` ; `ContentState` avec `startedAt`, `feedingEndsAt`, `uprightEndsAt`.
- **Target `BottleTimerWidget`** (Widget Extension, iOS 16.1) : `ActivityConfiguration` avec les vues compacte, minimale, étendue et écran verrouillé décrites plus haut ; couleurs en asset catalog clair / sombre ; textes dans `Localizable.strings` (fr).
- `Info.plist` du Runner : `NSSupportsLiveActivities = YES`.
- Build : la phase « Embed Foundation Extensions » doit précéder « Thin Binary » dans le Runner, sinon Xcode signale un cycle.
- La cible de l'app reste iOS 15 : tout le code ActivityKit est sous `if #available(iOS 16.1, *)`.

## Dégradations silencieuses

| Cas | Comportement |
|---|---|
| iOS 15 | Pas d'activité ; notifications locales et reprise actives. |
| Live Activities désactivées dans Réglages | Pas d'activité ; notifications et reprise actives. |
| Notifications refusées | Sons dans l'app seulement ; activité et reprise actives. |
| Session de plus de 12 h | Effacée au démarrage, activité fermée. |

## Tests

- **Domaine** : expiration à 12 h (`FixedClock`).
- **Data** (`SharedPreferences.setMockInitialValues`) : aller-retour `save` / `load` (minuteur, brouillon, `editing`) ; `load` sans session → `Right(null)` ; JSON corrompu → `Left(Failure)` ; `clear`.
- **Effets** (conteneur, faux `BottleTimerSystem`, faux repository) : lancement → `sync` ; « Biberon terminé » → `sync` avec la nouvelle fin ; arrêt → `clear` et effacement ; destruction → `clear` et effacement.
- **Formulaire** : modifier la quantité pendant le minuteur sauvegarde la session ; `restored` en cours → brouillon affiché et minuteur restauré ; `restored` terminé → soin enregistré avec `startAt` = lancement et `endAt` = fin du biberon, feuille fermée ; `restored` en édition → mode édition.
- **Gate** : sans session → `clear()` et pas de feuille ; session expirée → effacée ; session valide → feuille ouverte.
- **Natif (manuel)** sur simulateur iPhone 17 Pro puis iPhone : vues compacte, étendue et écran verrouillé en clair et sombre ; décompte de la verticale figé pendant le biberon ; vue périmée à la fin ; notifications app en arrière-plan puis tuée, masquées au premier plan ; reprise après avoir tué l'app ; build Xcode sans cycle.
