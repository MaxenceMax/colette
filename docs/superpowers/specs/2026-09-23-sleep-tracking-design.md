# Colette — Suivi du sommeil

Date : 2026-09-23. Complète la spec v1 (`2026-09-21-colette-v1-design.md`).

## 1. Problème

Colette suit les biberons, les couches et les soins, mais pas le sommeil. Les parents ne savent pas depuis quand le bébé dort ou est éveillé, ni combien il a dormi sur 24 h, alors que c'est la question la plus fréquente entre deux parents qui se relaient.

## 2. Décision

Un suivi du sommeil « noter et voir », calé sur le socle commun des applis du marché (Huckleberry, Baby Tracker, BabyTime, Baby Connect, Nara, Glow) et sur les repères officiels :

1. **Saisie** : chrono partagé « Endormi·e / Réveillé·e » depuis l'accueil, visible en direct sur l'autre iPhone, et saisie après coup d'un sommeil passé (début, fin).
2. **Sieste ou nuit** : déduit de l'heure d'endormissement selon des horaires de nuit réglables, modifiable par sommeil.
3. **Affichage** : carte Sommeil sur l'accueil, sommeils mêlés aux soins dans le Journal, page Sommeil avec frise 24 h sur 7 jours.
4. **Repère OMS 2019** de durée sur 24 h selon l'âge, affiché de façon neutre.

Stockage dans une collection dédiée `households/{code}/sleeps/{id}`, feature `lib/features/sleep/`.

Hors périmètre : notifications (aucune, ni à l'endormissement ni au réveil), prédiction de sieste et fenêtres d'éveil (fonction premium des concurrents, sans validation scientifique), lieu, mode d'endormissement, note, fiche couchage sûr HAS, Live Activity, statistiques au-delà de 7 jours.

Alternatives écartées :

- **Soin « sommeil » dans `CareEvent`** : `endAt` deviendrait facultatif dans la validation, le DTO et les Cloud Functions (`summary`, `morningDigest`) ; chaque endormissement déclencherait `onEventCreated` et une notification ; un même événement pourrait mêler biberon et sommeil.
- **Deux événements ponctuels « endormi » et « réveillé »** : il faut reconstituer les sommeils par appariement, fragile en cas d'oubli, de correction d'heure ou d'appuis simultanés des deux parents.

## 3. Repères retenus

| Source | Contenu utilisé |
| --- | --- |
| OMS 2019, *Guidelines on physical activity, sedentary behaviour and sleep for children under 5 years of age* | Sommeil sur 24 h, siestes comprises : 0-3 mois 14 à 17 h ; 4-11 mois 12 à 16 h ; 1-2 ans 11 à 14 h. Repris tels quels par Santé publique France (1000-premiers-jours.fr). |
| AASM 2016 (Paruthi et al.) | Aucune recommandation avant 4 mois ; 4-12 mois 12 à 16 h. Non affiché, confirme l'OMS. |
| ameli, Santé publique France | Pas de rythme jour/nuit à la naissance, « très variable d'un enfant à l'autre ». Justifie l'affichage neutre, sans code couleur. |
| Fenêtres d'éveil (Taking Cara Babies, Huckleberry) | Écartées : aucune étude publiée ne les valide (Canapari, ParentData). |

## 4. Règles

| Sujet | Règle |
| --- | --- |
| Sommeil | `SleepSession` : `id`, `startAt`, `endAt?` (`null` = en cours), `kind` (`nap` ou `night`), `createdByDeviceId`, `createdAt`, `updatedAt`. |
| Sieste ou nuit | `classifySleepKind(startAt, nightStartHour, nightEndHour)` : `night` si l'heure de `startAt` est dans `[nightStartHour, nightEndHour[` (fenêtre qui peut passer minuit, ex. 20 → 7), sinon `nap`. Si `nightStartHour == nightEndHour`, tout est `nap`. Calculé à la création (chrono ou formulaire), modifiable dans le formulaire, **stocké** : changer les horaires ne reclasse pas l'historique. |
| Horaires de nuit | `CareSettings.nightStartHour` (défaut 20) et `CareSettings.nightEndHour` (défaut 7), entiers 0 à 23. Écrits par `BabySettingsController.updateCareSettings` (la resynchronisation du plan biberon qu'elle déclenche est sans effet ici). |
| Endormi·e | Crée un sommeil `startAt = now`, `endAt = null`, `kind` classé. Proposé seulement si aucun sommeil n'est en cours. |
| Réveillé·e | `planWakeUp(openSessions, now)` : ferme le plus ancien sommeil ouvert à `now`, supprime les autres ouverts (doublons nés de deux appuis simultanés sur les deux iPhones). Une seule écriture en lot (`WriteBatch`). |
| Réveil oublié | Sommeil en cours depuis plus de 16 h : la carte affiche « Réveil oublié ? » et son bouton ouvre le formulaire pour saisir la fin. |
| Validation | `ValidateSleepSession` refuse : fin avant ou égale au début ; début ou fin dans le futur (tolérance 1 min) ; durée supérieure à 24 h ; début avant la naissance ; chevauchement d'un autre sommeil (l'erreur porte les heures du sommeil en conflit, format de l'app « 14h10 »). Un sommeil en cours chevauche tout sommeil qui commence après son début. |
| Total sur 24 h | Fenêtre glissante `[now − 24 h, now]`. Chaque sommeil compte pour sa partie dans la fenêtre ; un sommeil en cours compte jusqu'à `now`. |
| Éveillé·e depuis | `endAt` du dernier sommeil terminé. Sans aucun sommeil enregistré : « Aucun sommeil noté », sans durée. |
| Jour de la page | Jour civil 0 h → 24 h. Un sommeil qui passe minuit est découpé en deux segments. Total du jour = somme des segments du jour. Nombre de siestes = `nap` dont `startAt` est dans le jour. Plus longue période = plus longue durée complète (non découpée) parmi les sommeils dont `startAt` est dans le jour ; un sommeil en cours compte jusqu'à `now`. |
| Moyenne | « Moyenne des jours précédents » : moyenne des totaux des 6 jours complets précédant aujourd'hui (aujourd'hui est incomplet), en ne retenant que les jours où un sommeil est noté (un premier usage en cours de semaine ne fait pas chuter la moyenne). Masquée tant qu'aucun de ces jours n'a de sommeil. |
| Repère OMS | `SleepAgeBand.forAge(birthDate, now)` d'après l'âge en mois révolus : moins de 4 mois → 14 à 17 h ; 4 à 11 mois → 12 à 16 h ; 12 à 23 mois → 11 à 14 h ; 24 mois et plus → aucun repère (`null`), ligne masquée. Texte neutre : « Repère OMS à son âge : 14 à 17 h sur 24 h ». Aucun code couleur selon l'écart. |
| Notifications | Aucune. La collection `sleeps` ne déclenche pas `onEventCreated`. Aucune modification des Cloud Functions. |
| Hors ligne | Persistance Firestore existante : le chrono démarre et s'arrête hors ligne, synchronisé au retour du réseau. |

## 5. Écrans

### 5.1 Carte Sommeil (accueil)

Placée juste sous « Prochain biberon ». Titre « Sommeil » avec icône lune, à droite un bouton `+` (saisie d'un sommeil passé) et un chevron ; un tap sur la carte hors boutons ouvre la page Sommeil.

| État | Contenu |
| --- | --- |
| Endormi·e | « Dort depuis 42 min », sous-ligne « Sieste · depuis 14h05 » (ou « Nuit »), bouton plein « Réveillé·e ». |
| Éveillé·e | « Éveillé·e depuis 1 h 10 » (ou « Aucun sommeil noté »), bouton contour « Endormi·e ». |
| Réveil oublié | « Dort depuis 17 h 20 · Réveil oublié ? », bouton « Saisir le réveil » qui ouvre le formulaire. |

Dernière ligne, dans tous les états : « Sur 24 h : 13 h 40 · repère OMS 14 à 17 h » (partie repère masquée au-delà de 2 ans). Durées rafraîchies par `currentMinuteProvider`. Pendant l'écriture, le bouton affiche un indicateur ; en cas d'erreur, `SnackBar` avec `failureMessage`.

### 5.2 Formulaire du sommeil (bottom sheet)

`showSleepFormSheet(context, {SleepSession? initial})`. Champs : début et fin (`DateField` existant), fin facultative uniquement si le sommeil édité est en cours ; sélecteur segmenté Sieste / Nuit, pré-rempli par `classifySleepKind` à la création et reclassé automatiquement quand le début change, tant que l'utilisateur ne l'a pas touché. Nouveau sommeil : début = maintenant − 1 h, fin = maintenant. Bouton Enregistrer ; bouton Supprimer (avec confirmation) en édition. Erreurs de validation affichées dans le formulaire.

### 5.3 Journal

Les sommeils sont mêlés aux soins, triés par `startAt` décroissant, dans les mêmes en-têtes de jour. Tuile : icône lune (couleur `sleepNight` ou `sleepNap`), « 10h20 → 12h00 · Sieste », sous-ligne « 1 h 40 » ou « en cours · 42 min ». Tap : formulaire du sommeil. Balayage : suppression après confirmation, comme les soins. Le `+` du Journal reste réservé aux soins.

Fenêtre des sommeils affichés : depuis le `startAt` du plus ancien soin chargé ; sans soin chargé, depuis 7 jours. Quand le Journal charge une page de soins de plus, la fenêtre des sommeils s'élargit.

### 5.4 Page Sommeil (`/today/sleep`)

AppBar « Sommeil », bouton flottant `+` (formulaire). Contenu :

1. En-tête : « Moyenne des jours précédents : 14 h 50 » et le repère OMS.
2. Frise : une ligne par jour, les 7 derniers jours (aujourd'hui en bas), axe 0 / 6 / 12 / 18 / 24 h. Segments `sleepNight` et `sleepNap`, total du jour à droite. Un tap sur une ligne la sélectionne (aujourd'hui par défaut, ligne sélectionnée surlignée). Dessinée par `SleepWeekChart` (`CustomPainter` dans un `LayoutBuilder`), sans hauteur fixe hors `AppSize`.
3. Détail du jour sélectionné : total, nombre de siestes, plus longue période.

### 5.5 Réglages

Nouvelle section « Sommeil » dans Réglages : « Début de la nuit » et « Fin de la nuit », `IntStepperRow` de 0 à 23 avec suffixe « h ». État local optimiste et erreur affichée comme `CareSettingsSection`.

## 6. Architecture

### Domaine (`lib/features/sleep/domain`)

- `entities/sleep_session.dart` (freezed) : `SleepSession`, getters `isOngoing`, `durationUntil(DateTime now)`.
- `entities/sleep_kind.dart` : enum `SleepKind { nap, night }`.
- `entities/sleep_status.dart` : sealed `SleepStatus` → `Asleep(since, kind)`, `Awake(since?)`, `ForgottenWake(since)` ; record ou freezed `SleepSummary(status, last24h)`.
- `entities/sleep_day.dart` (freezed) : `day`, `segments` (`List<({DateTime start, DateTime end, SleepKind kind})>`), `total`, `napCount`, `longest`.
- `entities/sleep_age_band.dart` : enum avec `minHours`, `maxHours`, `static SleepAgeBand? forAge(DateTime birthDate, DateTime now)`.
- `use_cases/classify_sleep_kind.dart`, `use_cases/validate_sleep_session.dart` (`Either<Failure, Unit>`, failures dédiées dans la hiérarchie existante), `use_cases/compute_sleep_summary.dart`, `use_cases/compute_sleep_days.dart`, `use_cases/plan_wake_up.dart` (renvoie `({SleepSession close, List<String> deleteIds})?`).
- `repositories/sleep_repository.dart` :
  - `Stream<List<SleepSession>> watchStartedSince(String code, DateTime from)` (tri `startAt` décroissant) ;
  - `Stream<SleepSession?> watchLatest(String code)` ;
  - `Future<Either<Failure, List<SleepSession>>> getStartedBetween(String code, {from, to})` ;
  - `save`, `delete`, `wakeUp(String code, {required SleepSession close, required List<String> deleteIds})`.

### Données (`lib/features/sleep/data`)

- `FirestorePaths.sleeps = 'sleeps'`.
- `dtos/sleep_session_dto.dart` : `toMap` / `fromMap`, `Timestamp`, `endAt: null` écrit explicitement, `kind` en chaîne (`'nap'`, `'night'`, inconnu → `nap`).
- `repositories/firestore_sleep_repository.dart` : toutes les méthodes via `guard()` ; `wakeUp` en `WriteBatch`.
- `features/baby` : `CareSettings.nightStartHour` / `nightEndHour` ; `baby_profile_dto.dart` lit avec `_readInt` borné 0 à 23 et écrit les deux champs.

### Présentation (`lib/features/sleep/presentation`)

- `providers/sleep_providers.dart` (publics) :
  - `sleepRepositoryProvider` ;
  - `recentSleepsProvider` : `watchStartedSince(now − 48 h)` (couvre la fenêtre de 24 h, durée max 24 h) ;
  - `latestSleepProvider` ;
  - `sleepSummaryProvider` : combine récents, dernier, `currentMinuteProvider` ;
  - `sleepAgeBandProvider` : d'après `BabyProfile.birthDate` ;
  - `sleepWeekProvider` : `watchStartedSince(début du jour J−7)` puis `computeSleepDays` sur J−6 à J ;
  - `timelineSleepsProvider(DateTime from)`.
- `providers/sleep_controller.dart` : `SleepController` auto-dispose (`fallAsleep`, `wakeUp`, `save`, `delete`), horloge `clockProvider`, identifiants `idGeneratorProvider`, appareil `deviceIdProvider`. `save` lit les sommeils voisins par `getStartedBetween(start − 24 h, end ?? now)` puis valide.
- Widgets : `sleep_card.dart`, `sleep_form_sheet.dart`, `sleep_week_chart.dart`, `sleep_day_details.dart`, `sleep_settings_section.dart`, `sleep_tile.dart` ; page `pages/sleep_page.dart`.
- Route `sleep` sous `/today` ; `DashboardPage` ajoute `SleepCard` sous `NextBottleCard` ; `SettingsPage` ajoute `SleepSettingsSection`.

### Journal (`lib/features/events/presentation`)

- `timeline_entry.dart` : sealed `TimelineEntry` → `CareEntry(CareEvent)`, `SleepEntry(SleepSession)`, `startAt` commun.
- `timeline_grouping.dart` : `groupEntriesByDay(List<TimelineEntry>)` remplace `groupEventsByDay`.
- `TimelinePage` fusionne `timelineEventsProvider` et `timelineSleepsProvider(from)` ; tuile `SleepTile` importée des widgets publics de `sleep`. Aucun import de `sleep/data`.

### Design system et l10n

- `AppColors.sleepNight` et `AppColors.sleepNap`, `light` et `dark`, lisibles sur les surfaces des cartes.
- Toutes les chaînes dans `app_fr.arb` (états de la carte, formulaire, erreurs de validation, page, réglages, repère OMS).

## 7. Tests

- **Domaine** (purs) :
  - `classifySleepKind` : bornes 19 h 59 / 20 h 00 / 6 h 59 / 7 h 00, fenêtre sans passage de minuit, `start == end` ;
  - `ValidateSleepSession` : chaque refus, chevauchement avec un sommeil en cours, sommeils bord à bord acceptés ;
  - `computeSleepSummary` : sommeil en cours, sommeil à cheval sur la fenêtre, réveil oublié à 16 h, aucun sommeil ;
  - `computeSleepDays` : découpage à minuit, siestes comptées au jour de début, plus longue période non découpée, jours vides ;
  - `SleepAgeBand.forAge` : 3 mois 30 j, 4 mois pile, 11/12 mois, 24 mois ;
  - `planWakeUp` : un ouvert, deux ouverts, aucun.
- **Données** (`fake_cloud_firestore`) : aller-retour du DTO avec et sans `endAt`, `kind` inconnu, `watchStartedSince` trié, `wakeUp` ferme et supprime en lot, horaires de nuit bornés et valeurs par défaut.
- **Présentation** (`pumpApp`, `FixedClock`, `minuteTicker` → `Stream.empty()`) :
  - carte : trois états, bouton appelant le contrôleur, ligne OMS masquée au-delà de 2 ans ;
  - formulaire : erreur de chevauchement, reclassement automatique, suppression ;
  - Journal : soins et sommeils mêlés dans le bon ordre et le bon jour ;
  - page : sélection d'un jour, moyenne masquée sans historique ;
  - réglages : stepper qui écrit les horaires ;
  - rendu PNG clair et sombre de la carte et de la frise, comme la courbe de poids.
- Avant la fin : `dart format lib test`, `dart analyze`, `flutter test`, puis vérification sur simulateur iPhone.

## 8. Fichiers touchés

- Nouveau : `lib/features/sleep/**`, `test/features/sleep/**`.
- `lib/core/firebase/firestore_paths.dart` : `sleeps`.
- `lib/core/theme/app_colors.dart` : `sleepNight`, `sleepNap`.
- `lib/features/baby/domain/entities/care_settings.dart`, `lib/features/baby/data/dtos/baby_profile_dto.dart` : horaires de nuit.
- `lib/features/baby/presentation/pages/settings_page.dart` : section Sommeil.
- `lib/features/dashboard/presentation/pages/dashboard_page.dart` : `SleepCard`.
- `lib/features/events/presentation/timeline_grouping.dart`, `timeline_entry.dart` (nouveau), `pages/timeline_page.dart`.
- `lib/app/router/app_router.dart` : route `/today/sleep`.
- `lib/l10n/app_fr.arb`.
- `firestore.rules` : inchangé (la règle générique `households/{code}/{collection}/{docId}` couvre `sleeps`).
- `functions/` : inchangé.
