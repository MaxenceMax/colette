# Bilan du jour dans le Journal

## Besoin

Au-dessus de chaque jour du Journal, un bilan rapide :

1. quantité de lait bue sur la journée, avec le nombre de biberons ;
2. nombre de couches changées et de pipis.

## Affichage

Le bilan est à droite du nom du jour, dans l'en-tête épinglé :

```
MARDI 20 OCTOBRE          🍼 620 ml · 6   🚼 5   💧 4
```

- Icônes et couleurs du Journal : biberon `Icons.local_drink_outlined` en
  `AppColors.categoryFeeding`, change et pipi avec `CareType.icon` et
  `CareType.color` (catégorie couche).
- Un chiffre à zéro est masqué : sans biberon, pas de bloc lait ; sans
  change, pas de bloc couches ; sans pipi, pas de bloc pipis. Un jour sans
  aucun des trois n'a pas de bilan.
- Le nom du jour est coupé avec « … » (une ligne) quand la place manque ; le
  bilan prend au plus 70 % de la largeur et rétrécit (`FittedBox`) au-delà.
- Le bilan porte une étiquette d'accessibilité unique, par exemple
  « 620 ml en 6 biberons, 5 couches, 4 pipis », qui ne cite que les
  éléments affichés.
- Lisible en thème clair et sombre.

## Données

Le bilan porte toujours sur la journée civile entière, quel que soit le
filtre actif et même si la pagination n'a chargé qu'une partie du jour le
plus ancien.

### Domaine (`features/events/domain`)

- Entité `freezed` `CareDaySummary` : `bottleMl`, `bottleCount`, `diapers`,
  `pee` (entiers), getter `isEmpty` (les trois blocs à zéro).
- Use case pur `summarizeCareDays(List<CareEvent>)` →
  `Map<DateTime, CareDaySummary>`, clé = `startAt.dateOnly`. Un soin compte
  pour un biberon s'il a `bottleMl`, pour une couche s'il a `diaperChange`,
  pour un pipi s'il a `pee` ; un même soin peut compter dans plusieurs blocs.

### Présentation (`features/events/presentation/providers`)

- Provider unique `timelineDaySummariesProvider` (pas de famille), sur le
  modèle de `timelineSleepsProvider` :
  - `from` = plus ancien jour chargé dans le Journal, soins
    (`timelineEventsProvider`) et sommeils (`timelineSleepsProvider`)
    confondus ; à défaut, aujourd'hui à minuit ;
  - `to` = demain à minuit ;
  - lecture `EventsRepository.watchBetween(code, from:, to:)`, sans tag :
    le filtre est ignoré ;
  - renvoie `summarizeCareDays` du résultat. Sans foyer : carte vide.
- Une seule écoute Firestore ; la requête par plage de `startAt` existe
  déjà, aucun index nouveau.

### Page

- `_TimelineList` lit `timelineDaySummariesProvider` et passe à
  `DayHeaderDelegate` le `CareDaySummary?` du jour, résolu en valeur.
- `DayHeaderDelegate` ne lit ni `Theme` ni `ref` : il reçoit en plus les
  couleurs résolues du biberon et des couches, et `shouldRebuild` compare
  aussi le bilan et ces couleurs.
- Le contenu de l'en-tête (nom du jour + bilan) est un widget public
  `DayHeaderContent` dans son propre fichier, pour rester sous 300 lignes
  et être testable seul.

## Strings (`app_fr.arb`)

- `daySummaryMilk` : « {ml} ml · {count} »
- Étiquette d'accessibilité composée de `daySummaryMilkSemantics`
  (« {ml} ml en {count} biberons », pluriel ICU), `daySummaryDiapersSemantics`
  (« {count} couches », pluriel) et `daySummaryPeeSemantics` (« {count} pipis »,
  pluriel), joints par « , ».

## Tests

- Domaine : somme des ml et compte des biberons, change et pipi dans le même
  soin, séparation à minuit, soin vide ignoré.
- Provider (dépôt mocké avec `mocktail`, comme les autres tests du Journal, `FixedClock`) : filtre « Pipi » actif →
  le bilan compte quand même les biberons ; `from` suit le plus ancien soin
  ou sommeil chargé.
- Widget (`pumpApp`) : chiffres affichés, blocs à zéro masqués, pas de bilan
  pour un jour vide, nom de jour long coupé sans débordement, thème sombre.

## Hors périmètre

Cacas, sommeil, soins programmés : non demandés.
