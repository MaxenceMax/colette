# Colette — Stock de couches

Date : 2026-09-22. Complète la spec v1 (`2026-09-21-colette-v1-design.md`).

## 1. Problème

Les parents veulent savoir combien de couches il reste à la maison et être prévenus avant la rupture. Aujourd'hui l'app compte les changes du jour (compteur « couches » de l'accueil) mais ne connaît pas le stock.

Besoin exprimé : saisir le stock, le décrémenter à chaque change, le ré-incrémenter si un change est supprimé, régler un seuil et afficher une alerte sur l'accueil quand le stock passe sous ce seuil.

## 2. Décision : compteur dérivé d'un point de référence

Le foyer stocke un couple `count` / `countedAt` : « `count` couches en stock à l'instant `countedAt` ». Le stock restant est calculé côté app :

```
restant = max(0, count − nombre d'événements avec diaperChange == true et startAt ≥ countedAt)
```

Aucune écriture de stock à la création, l'édition ou la suppression d'un événement. Supprimer un change, en ajouter un après coup, cocher ou décocher « change » en édition, annuler depuis la snackbar « Enregistré » : le restant est juste par construction. Les deux iPhones convergent sans conflit puisqu'ils lisent les mêmes événements.

Alternatives écartées :

- **Compteur stocké** mis à jour par `FieldValue.increment(±1)` à chaque sauvegarde, suppression ou édition. Simple à lire, mais toute écriture ratée d'un seul côté fait dériver le compteur sans détection possible, et l'édition exige de transporter l'état précédent de l'événement jusqu'au contrôleur.
- **Ledger de mouvements** dans une sous-collection. Rigoureux, mais duplique chaque change et impose de gérer la cohérence des suppressions. Disproportionné pour deux parents.

Limite assumée : un change antidaté à une heure antérieure à `countedAt` n'est pas décompté. Le recomptage corrige.

## 3. Règles

| Sujet | Règle |
| --- | --- |
| Stock non renseigné | Champ `diaperStock` absent du foyer. La section Réglages affiche « Stock non renseigné ». Aucune alerte. |
| Recompter | `count = n`, `countedAt = now`, seuil et taille de paquet conservés. |
| Ajouter un paquet | `count = restant + taille`, `countedAt = now`, `lastPackSize = taille`. |
| Seuil d'alerte | `alertThreshold`, défaut **10**, de 0 à 30. `0` désactive l'alerte. |
| Alerte | `isLow = alertThreshold > 0 && restant < alertThreshold` (« moins de 10 » : strictement inférieur). |
| Accueil | Carte d'alerte sous l'en-tête, uniquement si `isLow`. Texte « Plus que {n} couches » (ou « Plus de couches » à 0). Tap : ouvre l'onglet Réglages. Rien d'autre ne change sur l'accueil. |
| Réglages | Section « Couches » entre « Soins attendus » et « Notifications ». |
| Plan biberons | Non concerné : aucune écriture du stock ne déclenche `feedingPlanSyncProvider`. |
| Cloud Functions | Non touchées. Le stock étant dans le document foyer, un rappel dans le digest du matin restera possible. |

## 4. Données Firestore

```
households/{code}
  diaperStock:
    count: number             couches comptées à countedAt
    countedAt: Timestamp      instant du recomptage ou du dernier ajout de paquet
    alertThreshold: number    défaut 10, 0 = alerte désactivée
    lastPackSize: number      défaut 44, préremplit « + paquet »
```

Lecture (`DiaperStockDto.fromMap`) avec bornes : `count` 0..9999, `alertThreshold` 0..999, `lastPackSize` 1..999. Un `countedAt` absent ou non `Timestamp` rend le stock non renseigné (`null`).

Règles de sécurité : inchangées, la mise à jour du document foyer est déjà autorisée.

Index composite à ajouter dans `firestore.indexes.json`, sur le modèle de `bath` et `hasBottle` :

```json
{
  "collectionGroup": "events",
  "queryScope": "COLLECTION",
  "fields": [
    { "fieldPath": "diaperChange", "order": "ASCENDING" },
    { "fieldPath": "startAt", "order": "ASCENDING" }
  ]
}
```

## 5. Architecture

Nouvelle feature `lib/features/diapers/` (domain, data, presentation). Elle consomme les providers publics de `events` et le `currentHouseholdCodeProvider`, jamais un `data/` d'une autre feature.

### 5.1 Domaine (`diapers/domain`)

- `entities/diaper_stock.dart` : `DiaperStock` freezed, champs `count`, `countedAt`, `alertThreshold` (défaut 10), `lastPackSize` (défaut 44). Méthodes : `recount(int n, {required DateTime now})` et `addPack(int size, {required int remaining, required DateTime now})`.
- `entities/diaper_stock_status.dart` : `DiaperStockStatus` freezed, champs `remaining`, `isLow`.
- `repositories/diaper_stock_repository.dart` : `Stream<DiaperStock?> watchStock(String householdCode)` et `Future<Either<Failure, void>> saveStock(String householdCode, DiaperStock stock)`.
- `use_cases/compute_diaper_stock_status.dart` : `ComputeDiaperStockStatus()(stock: DiaperStock, changesSinceCount: int) → DiaperStockStatus`. Pur, sans Flutter ni Firebase.

### 5.2 Côté `events`

- `EventsRepository` : nouvelle méthode `Stream<int> watchDiaperChangeCountSince(String householdCode, {required DateTime from})`. Implémentation Firestore : `where('diaperChange', isEqualTo: true).where('startAt', isGreaterThanOrEqualTo: Timestamp.fromDate(from))`, longueur du snapshot.
- `events_providers.dart` : provider public `diaperChangesSince(DateTime from) → Stream<int>` (famille), `0` sans code foyer.

### 5.3 Data (`diapers/data`)

- `dtos/diaper_stock_dto.dart` : `toMap` / `fromMap` avec `Timestamp` et bornes de la section 4.
- `repositories/firestore_diaper_stock_repository.dart` : lecture depuis `households/{code}.diaperStock` via `snapshots()`, écriture par `set({'diaperStock': …}, SetOptions(merge: true))`, exceptions converties par `guard()`.

### 5.4 Présentation (`diapers/presentation`)

Providers (`providers/diaper_stock_providers.dart`) :

- `diaperStockRepository` : `keepAlive`, comme les autres repositories.
- `diaperStock` : `Stream<DiaperStock?>`, `null` sans code foyer ou sans champ.
- `diaperStockStatus` : `DiaperStockStatus?`, `null` si le stock n'est pas renseigné ; sinon `ComputeDiaperStockStatus` sur `diaperStock` et `diaperChangesSince(stock.countedAt)`.

Contrôleur (`providers/diaper_stock_controller.dart`) : `DiaperStockController` autoDispose, `FutureOr<void> build() {}`, `AsyncLoading` puis `AsyncData` ou `AsyncError(failure, stackTrace)`. Actions :

- `recount(int count)` : stock courant (ou `DiaperStock` neuf si absent) → `recount`, puis `saveStock`.
- `addPack(int size)` : stock courant (ou neuf, restant 0) → `addPack` avec le restant courant, puis `saveStock`.
- `setThreshold(int threshold)` : `copyWith(alertThreshold:)` sur le stock courant, puis `saveStock`. Sans stock renseigné : ne fait rien et renvoie `false` (le stepper n'est de toute façon pas affiché dans ce cas, voir la section).

Chaque action valide la valeur (`count` 0..9999, `size` 1..999, `threshold` 0..999) et renvoie `ValidationFailure` sinon ; les bornes du DTO ne sont qu'un filet côté lecture. Horloge via `clockProvider`.

Widgets :

- `widgets/diaper_stock_section.dart` : `DiaperStockSection` dans les Réglages. Ligne « Il reste {n} couches » ou « Stock non renseigné », deux boutons « Recompter » et « + paquet », puis, uniquement si le stock est renseigné, `IntStepperRow` « Alerte sous N couches » (0..30) avec copie locale optimiste sur le modèle de `CareSettingsSection`. Sans stock renseigné, le stepper est masqué : régler un seuil sans stock n'a pas de sens et créer un stock à 0 déclencherait l'alerte aussitôt. `ref.watch(diaperStockControllerProvider)` dans le `build` pour garder le contrôleur vivant pendant l'`await`.
- `widgets/diaper_stock_sheet.dart` : `showDiaperStockSheet(context, mode)` avec `enum DiaperStockSheetMode { recount, addPack }`. Un titre, un champ numérique (`TextEditingController` disposé), un bouton. En mode `addPack` le champ est prérempli avec `lastPackSize`. Même patron que `AddWeightSheet`.
- `widgets/diaper_stock_alert_card.dart` : `DiaperStockAlertCard`, `SizedBox.shrink()` si `diaperStockStatus` est `null` ou `isLow` faux ; sinon `ColetteCardSurface` sur fond `AppColors.warning`, texte lisible en clair et sombre, `InkWell` vers `/settings`.

Intégration :

- `settings_page.dart` : `SectionHeader(title: s.settingsDiapersSection)` + `DiaperStockSection()` après `CareSettingsSection`, et `ref.listen(diaperStockControllerProvider, …)` pour la snackbar d'erreur via `failureMessage`.
- `dashboard_page.dart` : `const DiaperStockAlertCard()` juste après `DashboardHeader`.

### 5.5 Chaînes (`lib/l10n/app_fr.arb`)

- `settingsDiapersSection` : « Couches »
- `diapersRemaining` : « Il reste {count} couches » (plural : « Il reste 1 couche »)
- `diapersNotSet` : « Stock non renseigné »
- `diapersRecount` : « Recompter »
- `diapersAddPack` : « + paquet »
- `diapersAlertThreshold` : « Alerte sous N couches »
- `diapersRecountTitle` : « Couches en stock »
- `diapersAddPackTitle` : « Taille du paquet »
- `diapersFieldCount` : « Nombre de couches »
- `diapersAlertLow` : « Plus que {count} couches » (plural : « Plus que 1 couche »)
- `diapersAlertEmpty` : « Plus de couches »

Nouvelle raison de validation : `ValidationReason.invalidDiaperCount` dans `core/result/failure.dart`, message `errorInvalidDiaperCount` : « Nombre de couches invalide » dans `core/ui/failure_message.dart`.

## 6. Tests

Domaine (purs) :

- `compute_diaper_stock_status_test` : restant = count − changes ; borne à 0 ; `isLow` vrai sous le seuil, faux au seuil exact et au-dessus ; seuil 0 → jamais `isLow`.
- `diaper_stock_test` : `recount` pose `count` et `countedAt` sans toucher seuil ni paquet ; `addPack` pose `restant + taille`, `countedAt = now` et `lastPackSize`.

Data (`fake_cloud_firestore`) :

- `diaper_stock_dto_test` : aller-retour ; bornes ; `countedAt` absent → `null`.
- `firestore_diaper_stock_repository_test` : `watchStock` émet `null` puis le stock après `saveStock` ; `saveStock` ne touche pas `baby` ni `feedingPlan` (merge).
- `firestore_events_repository_test` : `watchDiaperChangeCountSince` ne compte que les changes à partir de `from`.

Présentation (`pumpApp`, `mocktail`, `FixedClock`) :

- `diaper_stock_controller_test` : `recount` écrit `count` et `countedAt = now` ; `addPack` écrit `restant + taille` ; `setThreshold` conserve `count` ; stock absent → `recount` et `addPack` créent le stock, `setThreshold` renvoie `false` sans écrire ; valeur hors bornes → `AsyncError(ValidationFailure)`.
- `diaper_stock_section_test` : affiche « Il reste N couches » et le stepper ; « Stock non renseigné » sans stepper sans stock ; le stepper appelle `setThreshold`.
- `diaper_stock_sheet_test` : saisie puis bouton → appel `recount` / `addPack` ; préremplissage en mode `addPack`.
- `diaper_stock_alert_card_test` : absente au-dessus du seuil, présente en dessous, texte à 0.
- `settings_page_test` : la section « Couches » est présente.
- `dashboard_page_test` (ou test de la carte dans la page) : l'alerte apparaît quand le statut est bas.

Vérification finale : `dart run build_runner build -d`, `dart format lib test`, `dart analyze`, `flutter test`.

## 7. Fichiers touchés

Nouveaux :

- `lib/features/diapers/domain/entities/diaper_stock.dart`, `diaper_stock_status.dart`
- `lib/features/diapers/domain/repositories/diaper_stock_repository.dart`
- `lib/features/diapers/domain/use_cases/compute_diaper_stock_status.dart`
- `lib/features/diapers/data/dtos/diaper_stock_dto.dart`
- `lib/features/diapers/data/repositories/firestore_diaper_stock_repository.dart`
- `lib/features/diapers/presentation/providers/diaper_stock_providers.dart`, `diaper_stock_controller.dart`
- `lib/features/diapers/presentation/widgets/diaper_stock_section.dart`, `diaper_stock_sheet.dart`, `diaper_stock_alert_card.dart`
- Tests correspondants sous `test/features/diapers/`.

Modifiés :

- `lib/features/events/domain/repositories/events_repository.dart`, `data/repositories/firestore_events_repository.dart`, `presentation/providers/events_providers.dart`
- `lib/features/baby/presentation/pages/settings_page.dart`
- `lib/features/dashboard/presentation/pages/dashboard_page.dart`
- `lib/core/result/failure.dart`, `lib/core/ui/failure_message.dart`
- `lib/l10n/app_fr.arb`
- `firestore.indexes.json`
- `docs/superpowers/specs/2026-09-21-colette-v1-design.md` : section 5 (champ `diaperStock`), 6.2 (carte d'alerte) et 6.6 (section « Couches »).
