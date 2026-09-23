# Colette — Mesures de croissance : taille et périmètre crânien

Date : 2026-09-23. Complète la spec v1 (`2026-09-21-colette-v1-design.md`) et la courbe de poids (fusionnée dans `main`, commit `6ce7193`).

Premier des trois sous-projets du volet santé, dans l'ordre retenu : **A. croissance** (cette spec), B. suivi médical (examens obligatoires, vaccins), C. fièvre et médicaments.

## 1. Problème

L'app suit le poids (pesées, courbe, repères OMS P3 / P50 / P97), mais pas la taille ni le périmètre crânien, que le carnet de santé et le pédiatre relèvent à chaque examen. Les parents veulent saisir les trois valeurs d'un même examen en une fois et voir chaque grandeur sur sa courbe, avec les repères OMS.

## 2. Décision : étendre les documents `weights`

Les documents `households/{code}/weights/{id}` deviennent des mesures de croissance :

```
{ measuredAt: Timestamp, grams?: int, lengthMm?: int, headCircumferenceMm?: int }
```

- Au moins une des trois valeurs est présente. Les pesées existantes (`{measuredAt, grams}`) restent valides sans migration.
- Taille et périmètre sont stockés en millimètres entiers, saisis en centimètres à une décimale (52,5 cm → `525`).
- Le chemin ne change pas. `FirestorePaths.weights` porte un commentaire `///` : « Mesures de croissance (poids, taille, périmètre crânien) ; nom historique ».
- Règles Firestore et Cloud Functions : non touchées (les fonctions ne lisent pas les pesées, seulement le snapshot `feedingPlan`).

Alternatives écartées :

- **Nouvelle collection `measurements` avec migration des pesées.** Modèle plus propre, mais un iPhone encore sur l'ancienne version continuerait d'écrire dans `weights` pendant la transition : divergence sur des données de production.
- **Une collection par grandeur reliée par un identifiant de groupe.** Compatible avec l'ancienne version, mais une mesure affichée sur une ligne serait éclatée en trois documents : suppression et modification en batch, lien de groupe à maintenir. Complexité sans gain.

**Compatibilité, contrainte assumée.** L'ancien `WeightEntryDto.fromDoc` lit `grams` sans contrôle et échoue sur une mesure sans poids. Les deux iPhones doivent recevoir la nouvelle version avant la première saisie d'une mesure sans poids. Installation par `devicectl` par-dessus l'app existante (pas `flutter install`, qui désinstalle et efface les données locales, dont le code foyer).

## 3. Domaine (`features/baby/domain`)

| Élément | Rôle |
| --- | --- |
| `GrowthMeasurement` (freezed) | Remplace `WeightEntry` : `{id, measuredAt, int? grams, int? lengthMm, int? headCircumferenceMm}`. |
| `GrowthMetric` (enum) | `weight`, `length`, `headCircumference`. Méthode `valueOf(GrowthMeasurement) → int?` (grammes ou millimètres) ; la série d'une grandeur = les mesures où `valueOf` n'est pas nul. |
| `ValidateGrowthMeasurement` (use case pur) | `Either<Failure, GrowthMeasurement>`. Refuse une mesure sans aucune valeur (`emptyMeasurement`), un poids hors 1 000 – 20 000 g (`invalidWeight`, règle actuelle), une taille hors 300 – 1 200 mm (`invalidLength`), un périmètre hors 250 – 600 mm (`invalidHeadCircumference`). Remplace le contrôle de bornes aujourd'hui dans `BabySettingsController.addWeight`. |
| `GrowthTrend` (freezed) | Remplace `WeightTrend` : `{GrowthMetric metric, int latestValue, DateTime latestAt, int? previousValue, DateTime? previousAt}`, avec `delta`, `days` (jours civils, au moins 1) et `perDay` (gain moyen arrondi, affiché pour le poids seulement). |
| `ComputeGrowthTrend` (use case pur) | Remplace `ComputeWeightTrend`. Pour une grandeur donnée, ne retient que les mesures qui la contiennent, puis applique la règle actuelle : dernière valeur, et précédente = la plus récente mesurée un jour civil antérieur. `null` si aucune mesure ne contient la grandeur. |
| `WhoPercentiles` (freezed) | Remplace `WhoWeightPercentiles` : `{ageDays, date, p3, p50, p97}` dans l'unité de la grandeur (grammes ou millimètres). |
| `ComputeWhoReference` (use case pur) | Remplace `ComputeWhoWeightReference`, paramétré par `GrowthMetric`. Même méthode LMS, mêmes bornes `[0, 730]` jours ; conversion kg → g pour le poids, cm → mm pour la taille et le périmètre. |
| Tables de référence | `domain/reference/who_length_for_age.dart` (source `lenanthro.txt`, mesure couchée, filles et garçons, jours 0 à 730) et `who_head_circumference_for_age.dart` (source `hcanthro.txt`, jours 0 à 730), générées depuis `data-raw/growthstandards/` du dépôt `WorldHealthOrganization/anthro`, même en-tête « Ne pas modifier à la main » et même type `WhoLms` que `who_weight_for_age.dart`. `WhoLms` passe dans un fichier commun `who_lms.dart`. |
| `BabyRepository` | `watchWeights` / `addWeight` / `deleteWeight` deviennent `watchMeasurements` (triées de la plus récente à la plus ancienne), `saveMeasurement` (`set` sur l'identifiant : ajout ou modification) et `deleteMeasurement`. |

`ValidationReason` gagne `emptyMeasurement`, `invalidLength` et `invalidHeadCircumference`.

## 4. Données (`features/baby/data`)

`WeightEntryDto` devient `GrowthMeasurementDto`. `toMap` n'écrit que les champs non nuls (pas de clé à `null`). `fromDoc` lit chaque champ comme `num?` et convertit en `int?`. Une modification remplace le document entier (`set` sans `merge`) : effacer le périmètre d'une mesure le supprime bien du document.

## 5. Plan biberons

`latestWeightProvider` et `FeedingPlanSync` prennent la **mesure la plus récente qui contient un poids**, et non plus la première de la liste. Sans cette règle, une mesure de taille seule ferait basculer le plan sur les repères par âge. Toute écriture ou suppression de mesure continue de déclencher `feedingPlanSyncProvider`, même sans poids (le recalcul est alors sans effet, et la règle reste simple).

## 6. Présentation

### 6.1 Route

`AppRoutes.weights` (`/today/weights`) devient `AppRoutes.growth` (`/today/growth`), page `GrowthPage` (remplace `WeightCurvePage`). Aucune notification ne pointe vers cette route.

### 6.2 Page « Croissance »

De haut en bas :

1. Sélecteur `SegmentedButton` Poids / Taille / Périmètre (même composant que `theme_mode_section.dart`). État dans un provider `autoDispose` propre à la page (`selectedGrowthMetricProvider`), initialisé à `weight` à chaque ouverture.
2. Carte de la grandeur sélectionnée (`ColetteCardSurface`) :
   - Résumé `GrowthTrendSummary` (remplace `WeightTrendSummary`, trois lignes comme aujourd'hui) : valeur, date, évolution. Poids : textes actuels inchangés (« 4 250 g », « Pesée du … », « +320 g en 10 jours · +32 g/jour » ou « Première pesée »). Taille et périmètre : « 54,5 cm », « Mesure du … », « +2,0 cm en 18 jours » ou « Première mesure ».
   - Courbe `GrowthChart` avec repères OMS si le toggle est actif.
   - Toggle OMS : le provider `whoCurvesVisibilityProvider` existant, commun aux trois grandeurs ; inactif tant que le sexe n'est pas renseigné (règle actuelle).
   - Aucune valeur pour la grandeur : état vide « Aucun poids enregistré » / « Aucune taille enregistrée » / « Aucun périmètre crânien enregistré » et bouton « Ajouter une mesure ».
3. Section « Mesures » (`MeasurementsSection`, remplace `WeightsSection`) : une ligne par mesure. Titre : les valeurs présentes séparées par « · » (« 4 250 g · 54,5 cm · PC 37,0 cm »). Sous-titre : la date. Tap sur la ligne : feuille en modification. Icône poubelle : suppression immédiate (comportement actuel).

Formatage des centimètres : `NumberFormat('0.0', 'fr')` sur `mm / 10` (virgule décimale).

### 6.3 Feuille « Ajouter une mesure » / « Modifier la mesure »

`GrowthMeasurementSheet` remplace `AddWeightSheet`. `showGrowthMeasurementSheet(context, {GrowthMeasurement? initial})`.

- Date : `DateField` + `showColetteDateTimePicker`, bornée entre la naissance et aujourd'hui (règle actuelle), défaut aujourd'hui ou date de la mesure modifiée.
- Trois `TextField` facultatifs, préremplis en modification : poids en grammes (clavier numérique), taille en cm et périmètre crânien en cm (clavier décimal ; virgule et point acceptés). Les trois contrôleurs sont disposés dans `dispose()`.
- Bouton « Enregistrer » désactivé tant que les trois champs sont vides.
- Conversion des saisies dans la feuille : champ vide → `null` ; texte illisible (« 5a ») → valeur hors bornes (`-1`), pour que `ValidateGrowthMeasurement` renvoie la raison du champ concerné.
- Enregistrement via `BabySettingsController.saveMeasurement(...)` (remplace `addWeight`), qui valide, écrit, puis lance la sync du plan. Suppression via `deleteMeasurement`. Erreurs affichées par la snackbar existante (`failureMessage`), un message par nouvelle raison.

### 6.4 Graphique

`WeightChart` et `WeightChartScale` deviennent `GrowthChart` et `GrowthChartScale`, qui prennent des points `(DateTime date, int value)` et un `GrowthMetric` :

- Pas de graduation : poids `[100, 250, 500, 1000, 2000]` g ; taille et périmètre `[5, 10, 20, 50]` mm. Même règle de choix (au plus 4 intervalles).
- Libellés d'axe : grammes pour le poids (format actuel), centimètres sans décimale pour la taille et le périmètre si le pas est un multiple de 10 mm, sinon avec une décimale.
- Mode `compact` inchangé (carte d'accueil).

### 6.5 Ce qui ne change pas de comportement

- Carte « Poids » de l'accueil (`WeightCard`) : mêmes textes, alimentée par `ComputeGrowthTrend(weight)` et les seules mesures avec poids ; le tap ouvre `/today/growth` sur l'onglet Poids.
- Réglages : la section « Pesées » devient « Mesures » et affiche `MeasurementsSection`.

## 7. Localisation (`app_fr.arb`)

Même registre que l'existant (tutoiement, espaces insécables avant les unités, pluriels ICU).

Nouvelles clés, entre autres :

- Page : `growthTitle` (« Croissance »), `growthMetricWeight` / `growthMetricLength` / `growthMetricHeadCircumference` (« Poids » / « Taille » / « Périmètre »), `growthEmptyWeight` / `growthEmptyLength` / `growthEmptyHeadCircumference` (« Aucun poids enregistré », « Aucune taille enregistrée », « Aucun périmètre crânien enregistré »), `growthCurveHint` (« Touche la courbe pour afficher une mesure. »).
- Résumé : `measurementCm` (« {value} cm »), `measurementMeasuredOn` (« Mesure du {date} »), `measurementTrendSinceCm` (« {delta} cm en {days, plural, =1{1 jour} other{{days} jours}} »), `measurementTrendFirst` (« Première mesure »), `measurementHeadCircumferenceShort` (« PC {value} cm »).
- Liste et feuille : `settingsMeasurementsSection` (« Mesures »), `settingsMeasurementsEmpty` (« Aucune mesure. Ajoute un poids pour un calcul au poids. »), `actionAddMeasurement` (« Ajouter une mesure »), `editMeasurementTitle` (« Modifier la mesure »), `fieldLengthCm` (« Taille (cm) »), `fieldHeadCircumferenceCm` (« Périmètre crânien (cm) »).
- Erreurs : `errorEmptyMeasurement` (« Renseigne au moins une valeur. »), `errorInvalidLength` (« La taille doit être entre 30 et 120 cm. »), `errorInvalidHeadCircumference` (« Le périmètre crânien doit être entre 25 et 60 cm. »).

Conservées : `weightGrams`, `weightMeasuredOn`, `weightTrendSince`, `weightTrendFirst`, `weightCardTitle`, `weightCardEmpty`, `fieldWeightGrams`, `errorInvalidWeight`. Supprimées : `weightCurveTitle`, `weightCurveEmpty`, `weightCurveHint`, `settingsWeightsSection`, `settingsWeightsEmpty`, `settingsAddWeight`.

## 8. Tests

- **Domaine** (purs) :
  - `ValidateGrowthMeasurement` : mesure vide ; chaque borne basse et haute des trois grandeurs ; mesure avec seulement la taille valide.
  - `ComputeGrowthTrend` : pour chaque grandeur, ignore les mesures qui ne la contiennent pas ; précédente prise un jour civil antérieur ; `null` sans valeur.
  - `ComputeWhoReference` : P50 à 0, 30 et 365 jours comparés aux valeurs M des tables OMS (filles et garçons) pour la taille et le périmètre ; non-régression sur le poids (tests existants adaptés).
  - `GrowthChartScale` : choix du pas en grammes et en millimètres, mesure unique.
- **Data** (`fake_cloud_firestore`) : un ancien document `{measuredAt, grams}` est relu correctement ; aller-retour d'une mesure complète et d'une mesure sans poids ; `toMap` n'écrit pas les clés nulles ; une modification qui retire le périmètre le retire du document.
- **Plan biberons** : si la mesure la plus récente n'a qu'une taille, `latestWeightProvider` et `FeedingPlanSync` utilisent la pesée précédente.
- **Présentation** (`pumpApp`, `mocktail`) : bascule des onglets de `GrowthPage` ; état vide par grandeur ; feuille en ajout puis en modification (préremplissage) ; bouton désactivé tant que tout est vide ; message d'erreur par raison ; tap sur la carte d'accueil ouvre l'onglet Poids.

## 9. Livraison

- Branche `feat/growth-measurements`, worktree `.claude/worktrees/growth-measurements`, partie de `main` (`5ed01d6`).
- Commits en français (`feat:`, `test:`, `docs:`…), `git add` de fichiers ciblés.
- Fin de lot : `dart format lib test`, `dart analyze`, `flutter test`, vérification sur simulateur iPhone en clair et en sombre.
- Merge `--no-ff` « merge: mesures de croissance, taille et périmètre crânien (feat/growth-measurements) » après validation explicite, sans push.
- Conflits prévisibles avec les branches en cours (sommeil, diversification) : `app_fr.arb`, `app_router.dart` et `ValidationReason` s'ils y ajoutent aussi des entrées. Résolution par juxtaposition.

## 10. Hors périmètre

- Percentile du bébé affiché en texte (« autour du 50e »).
- Mesures après 2 ans (taille debout, tables au-delà de 730 jours).
- Export PDF pour le pédiatre.
- Lien avec les examens médicaux (sous-projet B) : une mesure pourra plus tard être rattachée à un examen, sans changer ce modèle.
