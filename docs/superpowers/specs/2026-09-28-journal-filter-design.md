# Filtre par tag dans le Journal — design

Date : 2026-09-28
Branche : `feat/journal-filter`

## Objectif

Dans l'onglet Journal, retrouver d'un tap tous les événements d'un même type (« tous les cacas », « tous les biberons », « tous les sommeils »), en remontant aussi loin que l'historique, sans casser la pagination par défilement.

## Périmètre

- Un seul filtre actif à la fois, choisi dans une rangée de puces en haut du Journal.
- Filtres : Tout (par défaut), Biberon, Caca, Pipi, Couche, Sommeil, Bain, Adrigyl, Soin des yeux, Soin du nez, Soin du nombril.
- Le filtre vit en mémoire le temps de la session. Il n'est ni persisté ni partagé entre appareils.
- Hors périmètre : sélection multiple, recherche dans les notes, filtre par date, compteur de résultats.

## Approche retenue

On filtre côté Firestore : `where(<champ>, isEqualTo: true).orderBy('startAt', descending: true).limit(n)`. La pagination existante (`TimelineLimit`, pages de 30) reste la même.

Tous les documents `events` écrivent déjà les 8 booléens de soin et `hasBottle` (`CareEventDto.toMap`), donc aucune migration n'est nécessaire.

On écarte le filtrage client des pages déjà chargées : une page de 30 peut ne contenir aucun événement du tag, ce qui obligerait à recharger en boucle.

## Domaine

### `TimelineFilter` (`lib/features/events/domain/entities/timeline_filter.dart`)

Classe scellée pure, sans Flutter :

```dart
sealed class TimelineFilter { const TimelineFilter(); }
final class AllEntriesFilter extends TimelineFilter { const AllEntriesFilter(); }
final class CareTypeFilter extends TimelineFilter { const CareTypeFilter(this.type); final CareType type; }
final class BottleFilter extends TimelineFilter { const BottleFilter(); }
final class SleepFilter extends TimelineFilter { const SleepFilter(); }
```

- `CareTypeFilter` implémente `==` et `hashCode` sur `type`.
- `static const List<TimelineFilter> values` donne l'ordre d'affichage des puces : Tout, Biberon, Caca, Pipi, Couche, Sommeil, Bain, Adrigyl, Yeux, Nez, Nombril.
- `bool get showsCares` : vrai sauf pour `SleepFilter`.
- `bool get showsSleeps` : vrai pour `AllEntriesFilter` et `SleepFilter`.

### `EventTag` et `EventsRepository.watchLatest`

Le critère de soin passé au repository est un type domaine :

```dart
sealed class EventTag { const EventTag(); }
final class CareTag extends EventTag { const CareTag(this.type); final CareType type; }
final class BottleTag extends EventTag { const BottleTag(); }
```

Signature : `watchLatest(String householdCode, {required int limit, EventTag? only})`.

- `only == null` : comportement actuel.
- `TimelineFilter` expose `EventTag? get eventTag` : `null` pour Tout et Sommeil, `CareTag(type)` ou `BottleTag()` sinon.

### `SleepRepository.watchLatestSessions`

Nouvelle méthode `Stream<List<SleepSession>> watchLatestSessions(String householdCode, {required int limit})` : les [limit] sommeils les plus récents, par `startAt` décroissant. Elle sert au filtre Sommeil. Le nom évite le conflit avec `watchLatest` (dernier sommeil unique), qui existe déjà.

## Data

- `FirestoreEventsRepository.watchLatest` ajoute `.where(field, isEqualTo: true)` quand `only != null`. La correspondance tag → champ vit dans le repository : `CareType.pee → 'pee'`, …, `BottleTag → 'hasBottle'`.
- `FirestoreSleepRepository.watchLatestSessions` : `orderBy('startAt', descending: true).limit(limit)`. Pas besoin d'index composite.
- `firestore.indexes.json` : un index `(champ ASC, startAt DESC)` sur `events` pour `pee`, `poop`, `diaperChange`, `adrigyl`, `bath`, `eyeCare`, `noseCare`, `umbilicalCare`. L'index `hasBottle` existe déjà. L'index `diaperChange ASC, startAt ASC` existant est conservé pour `watchDiaperChangeCountSince`.

## Présentation

### Providers (`lib/features/events/presentation/providers/`)

- `TimelineFilterController` (`@riverpod` classe) : `build()` renvoie `const AllEntriesFilter()`. `select(TimelineFilter)` met à jour l'état et appelle `ref.read(timelineLimitProvider.notifier).reset()`.
- `TimelineLimit` gagne `reset()`, qui remet `timelinePageSize`.
- `timelineEventsProvider` : si `!filter.showsCares`, émet `const []`. Sinon, `watchLatest(code, limit: limit, only: filter.eventTag)`.
- `timelineSleepsProvider` :
  - `AllEntriesFilter` : comportement actuel (fenêtre suivant le plus ancien soin chargé).
  - `SleepFilter` : `watchLatestSessions(code, limit: limit)`.
  - Autres filtres : `const []`.

### Pagination

`_TimelineList._onScroll` et l'indicateur de bas de liste se basent aujourd'hui sur `events.length >= limit`. Avec `SleepFilter`, ils doivent se baser sur `sleeps.length >= limit`. La règle est extraite dans une fonction pure `isLastPageFull(filter, events, sleeps, limit)`, testée seule.

### UI

- `TimelineFilterBar` (`presentation/widgets/timeline_filter_bar.dart`, moins de 300 lignes) est placé en tête du corps de la page, au-dessus de la liste. C'est une rangée horizontale défilante de `ChoiceChip`, avec icône et libellé. Il n'est pas en `bottom:` de l'AppBar : un `PreferredSizeWidget` imposerait une hauteur fixe, qui casserait avec les grandes tailles de texte.
  - soins : `CareTypeUi.icon`, `label(s)` et `color` ;
  - Biberon : `s.careBottle`, `AppColors.categoryFeeding` ;
  - Sommeil : `s.sleepCardTitle`, `AppColors.sleepNight` ;
  - Tout : nouvelle clé `journalFilterAll` (« Tout »).
- Espacements, rayons et hauteur viennent de `AppSpacing`, `AppRadius` et `AppSize`, sans nombre en dur.
- `TimelinePage` : un filtre actif sans résultat affiche `EmptyState(icon: Icons.filter_alt_off_outlined, message: s.journalFilterEmpty)`, avec la nouvelle clé « Aucun événement pour ce filtre. ». Le message `journalEmpty` actuel reste réservé à « Tout ».
- Le FAB « + » reste inchangé.
- L'écran doit être lisible en thème clair et sombre.

## Erreurs

Une requête filtrée qui échoue, par exemple parce que l'index n'est pas encore déployé, passe par l'`AsyncError` existant : l'`EmptyState` `errorUnknown` s'affiche et un `log(..., name: 'colette')` enregistre l'erreur. Aucun nouveau chemin d'erreur n'est ajouté.

## Tests

- Domaine : `TimelineFilter.values` (ordre), `showsCares`, `showsSleeps`, `eventTag`, égalité de `CareTypeFilter`, et `isLastPageFull`.
- Data (`fake_cloud_firestore`) :
  - `watchLatest(only: CareTag(poop))` ne renvoie que les cacas, triés et limités ;
  - `only: BottleTag()` ne renvoie que les biberons ;
  - `watchLatestSessions` renvoie les sommeils triés et limités.
- Providers :
  - `select` remet la limite à 30 ;
  - `timelineEventsProvider` émet `[]` avec `SleepFilter` ;
  - `timelineSleepsProvider` émet `[]` avec `CareTypeFilter`.
- Présentation (`pumpApp`) :
  - taper sur « Caca » sélectionne la puce, n'affiche que les soins filtrés et masque les sommeils ;
  - un filtre sans résultat affiche `journalFilterEmpty` ;
  - « Sommeil » n'affiche que les sommeils.

## Déploiement

1. `firebase deploy --only firestore:indexes` **avant** de diffuser l'app. La construction des index peut prendre quelques minutes.
2. Build et installation sur iPhone avec `devicectl install app`, par-dessus l'app existante.
