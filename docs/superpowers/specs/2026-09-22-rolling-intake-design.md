# Colette — Biberons sur les dernières 24 heures

Date : 2026-09-22. Complète la spec v1 (`2026-09-21-colette-v1-design.md`, §6.2).

## 1. Problème

Le plan biberons compte par jour civil (00:00 → 23:59, heure locale). Un biberon donné à 00:10 tombe donc sur le jour d'après, et à 00:15 la carte « Prochain biberon » repart de zéro. C'est correct et cohérent avec les Cloud Functions, mais la cible OMS est exprimée par 24 heures : les parents n'ont aucun repère sur ce que le bébé a réellement bu sur une journée physiologique.

## 2. Décision

Le jour civil reste la seule règle de découpage, partout (journal, compteurs, soins, digest). On ajoute un **indicateur complémentaire** sur la carte « Prochain biberon » : nombre de biberons et ml donnés sur les dernières 24 heures glissantes.

Alternatives écartées :

- **Journée décalée** (début à 04:00 ou 06:00) : deux notions de « jour » cohabiteraient (âge, jour de vie et naissance en jour civil ; journal, compteurs et soins en jour décalé), à répliquer dans les fonctions. Coût élevé, bénéfice marginal pour un nouveau-né sans rythme jour / nuit.
- **Fenêtre glissante partout** : détruit la notion « à faire aujourd'hui », rend « restants » non actionnable le matin, et le journal ne peut pas se regrouper ainsi.

## 3. Règles

| Sujet | Règle |
| --- | --- |
| Fenêtre | Événements avec `hasBottle` dont `startAt` est dans `[now − 24 h, now]`, bornes incluses. |
| Biberons | Nombre d'événements retenus. |
| ml | Somme des `bottleMl` ; un biberon sans quantité compte 0 ml. |
| Affichage | Ligne de texte secondaire dans `NextBottleCard`, sous la barre de progression, avant la mention « estimé ». Style `small`, couleur `textSecondary`. |
| Libellé | « {n} biberon(s) · {ml} ml sur les dernières 24 h », pluriel ICU (`=0{0 biberon} =1{1 biberon} other{{n} biberons}`). Toujours affichée, même à zéro. |
| Sans profil | La carte « plan indisponible » n'est pas modifiée. |
| Cloud Functions | Aucun changement : `FeedingPlan`, `ComputeFeedingPlan` et `FeedingPlanSync` sont intacts. |

## 4. Architecture

Domaine (`features/dashboard/domain`) :

- Entité freezed `RollingIntake({int bottles, int ml})`.
- Use case pur `ComputeRollingIntake()(events: List<CareEvent>, now: DateTime) → RollingIntake`. Filtre lui-même sur `hasBottle` et sur la fenêtre.

Présentation :

- `events_providers.dart` : `recentEventsProvider`, flux `watchBetween(code, from: today − 1 jour, to: today.startOfNextDay)`, dérivé de `todayProvider` comme `todayEventsProvider`. La fenêtre ne change qu'au changement de jour, donc pas de ré-abonnement Firestore à chaque minute ; le filtrage fin est fait en mémoire par le use case avec `currentMinuteProvider`.
- `dashboard_providers.dart` : `rollingIntakeProvider` = `ComputeRollingIntake()(events: recentEvents, now: currentMinute)`.
- `next_bottle_card.dart` : `ref.watch(rollingIntakeProvider)` et nouvelle ligne.

`from = DateTime(today.year, today.month, today.day − 1)` : 48 h glissantes couvrent toujours `[now − 24 h, now]` puisque `now` est dans le jour `today`.

## 5. Fichiers touchés

- `lib/features/dashboard/domain/entities/rolling_intake.dart` (nouveau, freezed).
- `lib/features/dashboard/domain/use_cases/compute_rolling_intake.dart` (nouveau).
- `lib/features/events/presentation/providers/events_providers.dart` : `recentEventsProvider`.
- `lib/features/dashboard/presentation/providers/dashboard_providers.dart` : `rollingIntakeProvider`.
- `lib/features/dashboard/presentation/widgets/next_bottle_card.dart` : ligne ajoutée.
- `lib/l10n/app_fr.arb` : clé `bottleRollingIntake` avec placeholders `count` (pluriel) et `ml`.
- `core/dates/date_extensions.dart` : getter `startOfPreviousDay` si utile (symétrique de `startOfNextDay`).
- Tests : `compute_rolling_intake_test.dart` (nouveau), `dashboard_page_test.dart` (ligne visible avec override de `recentEventsProvider`).

Documentation : spec v1 §6.2 complétée d'une phrase sur l'indicateur.

## 6. Tests

- Use case : liste vide → (0, 0) ; biberon à exactement `now − 24 h` retenu ; biberon à `now − 24 h − 1 min` exclu ; biberon sans `bottleMl` compte 1 biberon et 0 ml ; événement sans biberon ignoré ; biberon dans le futur (`> now`) exclu.
- Présentation : la carte affiche « 2 biberons · 150 ml sur les dernières 24 h » avec deux biberons dans le flux récent dont un la veille au soir ; « 0 biberon · 0 ml » avec un flux vide.

Vérification finale : `dart run build_runner build -d`, `dart format lib test`, `dart analyze`, `flutter test`.
