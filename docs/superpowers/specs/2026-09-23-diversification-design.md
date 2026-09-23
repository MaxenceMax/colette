# Colette — Diversification alimentaire

Date : 2026-09-23. Complète la spec v1 (`2026-09-21-colette-v1-design.md`).

## 1. Problème

Vers 6 mois, les parents commenceront la diversification alimentaire. Ils veulent savoir ce que la petite a déjà goûté, ce qu'elle a aimé ou refusé, ce qui est déconseillé à son âge et pourquoi. Ils ne sont pas experts : l'app doit porter les repères officiels, avec leur source.

Besoin exprimé : un nouvel onglet dédié, avec l'OMS comme référence.

## 2. Décisions

| Sujet | Décision |
| --- | --- |
| Suivi | Carnet de dégustations. Chaque essai a une date, et en option une appréciation (aimé / bof / refusé), une réaction observée (oui / non) et une note. |
| Catalogue | Environ 110 aliments embarqués dans l'app, classés par groupe OMS, avec leurs allergènes et leurs règles sourcées. Le foyer peut ajouter des aliments perso, partagés entre les deux appareils. |
| Sources | L'OMS d'abord, complétée par l'Anses, Santé publique France (SPF), l'ESPGHAN et le ministère de l'Agriculture pour ce que l'OMS ne traite pas (allergènes, interdits précis, étouffement). Chaque règle affiche sa source. En cas de divergence, les deux avis sont montrés et **la règle la plus prudente fixe le statut**. |
| Aliment déconseillé à l'âge actuel | L'app avertit sans bloquer : la saisie demande une confirmation. |
| Avant 6 mois | L'onglet est visible en mode « préparation ». |
| Suivis v1 | Diversité du jour (groupes OMS), allergènes introduits, aliments à reproposer, feuille « Repères à son âge ». |
| Stockage | Catalogue en JSON versionné avec l'app. Dégustations et aliments perso dans Firestore, dans des collections dédiées (pas dans `events`). |

Hors v1 : les dégustations dans l'onglet Journal, les notifications, les quantités par repas, l'ajout de règles d'âge sur un aliment perso.

## 3. Repères retenus (recherche du 2026-09-23)

### 3.1 Début et phases

- **OMS (ligne directrice 2023)** : aliments complémentaires à 6 mois (180 jours), en poursuivant le lait.
- **France (Anses 2019, SPF 2021, ESPGHAN 2017)** : entre 4 et 6 mois révolus, jamais avant 4 mois, pas après 6 mois. Pour un prématuré, demander un avis médical.
- Phases OMS utilisées par l'app :

| Phase | Textures (OMS) | Repas par jour (OMS) | Repère France (SPF) |
| --- | --- | --- | --- |
| Préparation (< 6 mois) | — | — | Purées et compotes lisses possibles dès 4 mois |
| 6–8 mois | Bouillie épaisse, aliments bien écrasés | 2 à 3, plus 1 à 2 collations selon l'appétit | Haché ou écrasé grossièrement dès 6–8 mois |
| 9–11 mois | Haché fin, écrasé, aliments à prendre avec les doigts | 3 à 4, plus 1 à 2 collations | Morceaux très mous dès 8 mois, morceaux à mâcher dès 10 mois. L'Anses dit textures non lisses pas après 10 mois |
| 12–23 mois | Plats familiaux, hachés ou écrasés si besoin | 3 à 4, plus 1 à 2 collations | 3 repas et un goûter dès 1 an |

- Signes que bébé est prêt pour les textures (SPF) : il tient sa tête et son dos droits, avale bien les purées lisses, attrape les aliments et les porte à sa bouche, fait des mouvements de mâchonnement.

### 3.2 Groupes alimentaires

Les 8 groupes OMS/UNICEF de la diversité alimentaire minimale (repère : au moins 5 groupes sur 8 la veille, de 6 à 23 mois) :

1. Lait maternel. Non suivi par l'onglet.
2. Céréales, racines, tubercules et plantains → `grainsRootsTubers`
3. Légumineuses, fruits à coque et graines → `legumesNutsSeeds`
4. Produits laitiers (lait, préparation infantile, yaourt, fromage) → `dairy`
5. Chairs (viande, poisson, volaille, abats) → `fleshFoods`
6. Œufs → `eggs`
7. Fruits et légumes riches en vitamine A → `vitaminAFruitsVeg`
8. Autres fruits et légumes → `otherFruitsVeg`

S'y ajoute `outsideGroups` pour ce qui ne compte pas dans la diversité : matières grasses, miel, sucre, sel, boissons, condiments.

### 3.3 Allergènes

- Les 14 allergènes de l'UE (règlement 1169/2011, annexe II) sont modélisés : `gluten`, `crustaceans`, `eggs`, `fish`, `peanut`, `soy`, `milk`, `treeNuts`, `celery`, `mustard`, `sesame`, `sulphites`, `lupin`, `molluscs`.
- La carte Allergènes en suit 9 : lait, œuf, gluten, arachide, fruits à coque, poisson, crustacés, sésame, soja. Les 5 autres restent visibles sur la fiche de l'aliment.
- France (Anses 2019, SPF) : ne pas retarder le lait, l'œuf, l'arachide et le gluten, même chez un enfant à risque. L'arachide et les fruits à coque se donnent uniquement en poudre ou en pâte.
- Pas de règle « attendre 3 à 5 jours entre deux nouveaux aliments » : elle n'est pas officielle en France. SPF conseille seulement de présenter un nouvel aliment seul, pour en faire découvrir le goût.
- Un refus n'est pas une réaction. Reproposer jusqu'à 8 à 10 fois (SPF, Anses).

### 3.4 Interdits et précautions

| Aliment | Règle | Jusqu'à | Sources |
| --- | --- | --- | --- |
| Miel, même cuit | `avoid` | 12 mois | OMS, Anses |
| Lait de vache comme boisson principale | `avoid` | 12 mois | Anses, SPF. L'OMS accepte le lait entier pasteurisé dès 6 mois : les deux avis sont affichés |
| Boissons végétales à la place du lait | `avoid` | 12 mois | Anses, SPF |
| Sel ajouté | `avoid` | 36 mois | SPF, OMS |
| Sucre ajouté, boissons sucrées, édulcorants | `avoid` | 36 mois | OMS, SPF |
| Jus de fruits | `info` (à limiter) | — | OMS, SPF |
| Viande, poisson crus ou peu cuits, coquillages crus | `avoid` | 36 mois | Anses |
| Œuf cru ou peu cuit (mayonnaise, mousse maison) | `avoid` | 72 mois | Anses |
| Lait cru et fromages au lait cru, sauf pâtes pressées cuites (comté, emmental, gruyère, beaufort) | `avoid` | 60 mois | Anses (3 ans), ministère de l'Agriculture (5 ans) |
| Poisson fumé | `avoid` | 36 mois | Anses |
| Espadon, marlin, siki, requin, lamproie | `avoid` | 36 mois | Anses |
| Grands prédateurs (thon, lotte, bar, dorade, brochet, raie) | `info` (à limiter) | — | Anses |
| Soja et produits au soja | `avoid` | 36 mois | Anses, SPF |
| Thé, café, sodas | `avoid` | 36 mois | Anses |
| Chocolat | `info` (à limiter avant 3 ans) | — | Anses |
| Fruits à coque et arachide entiers, aliments petits, durs et ronds | `avoid` | 60 mois | SPF (5 ans), Anses (3 ans) |
| Raisin, tomate cerise, myrtille | `prepare` : couper en deux ou en quatre, retirer les pépins | 60 mois | SPF |
| Arachide, fruits à coque, sésame (pâte, poudre) | `prepare` : en pâte ou en poudre dans une purée | 60 mois | SPF |
| Épinards et légumes-feuilles cuits | `info` : ne pas conserver à température ambiante, éviter en cas d'infection digestive | — | EFSA 2010 |

Un avis Anses de mai 2026 propose d'abaisser la dose tolérable de méthylmercure. Les règles sur les poissons pourront évoluer : c'est une simple mise à jour du JSON.

### 3.5 Alimentation attentive (feuille Repères)

- OMS : laisser l'enfant manger selon sa faim, l'encourager à manger de façon autonome.
- SPF :
  - signes de faim : il pleure, s'agite, ouvre la bouche ;
  - signes de satiété : il ralentit, tourne la tête ;
  - proposer sans jamais forcer ;
  - pas d'écran pendant le repas ;
  - pas d'aliment en récompense.
- Sécurité (SPF) : enfant assis et surveillé pendant tout le repas.

## 4. Écrans

### 4.1 Navigation

- Un 4ᵉ onglet **Assiette** (icône bol), placé entre Journal et Réglages, route `/plate`.
- La fiche d'un aliment est une sous-route : `/plate/food/:foodId`.

### 4.2 Page Assiette

De haut en bas, dans un `CustomScrollView` :

1. **En-tête de phase.**
   - Contenu : « 7 mois · phase 6–8 mois · 2 à 3 repas ».
   - L'icône ⓘ (cible tactile de 48 pt) ouvre la feuille **Repères à son âge**. La feuille contient :
     - textures et nombre de repas (OMS puis France) ;
     - signes de maturité ;
     - signes de faim et de satiété ;
     - conseils contre l'étouffement ;
     - la section « Sources » (liens et date de consultation) ;
     - la mention « Informations générales, ne remplacent pas l'avis de votre pédiatre ».
   - Sans profil bébé : message invitant à renseigner le profil dans Réglages. Le catalogue reste affiché, sans statut lié à l'âge.
2. **Carte Préparation**, avant 6 mois, à la place de la carte Aujourd'hui. Elle contient :
   - le compte à rebours « Dans N jours : 6 mois » ;
   - la mention « OMS : 6 mois · France : entre 4 et 6 mois, jamais avant 4 » ;
   - les signes que bébé est prêt ;
   - le bouton « Noter une dégustation ».
3. **Carte Aujourd'hui**, à partir de 6 mois.
   - Elle affiche « N groupes sur 7 », avec une puce par groupe, pleine s'il est couvert.
   - Une ligne rappelle le repère : « Repère OMS : 5 groupes sur 8, lait compris ».
   - Elle donne le nombre de dégustations du jour.
   - Elle porte le bouton « Noter une dégustation ».
4. **Carte Allergènes**.
   - Elle affiche « N sur 9 introduits » et une grille des 9 allergènes. Chacun a trois états : pas encore, introduit, réaction signalée.
   - Un tap sur un allergène filtre le catalogue sur cet allergène.
5. **Carte À reproposer**.
   - Elle liste les aliments dont la dernière dégustation avec appréciation est « bof » ou « refusé », avec le nombre total d'essais.
   - Un tap ouvre la fiche. La carte est masquée si elle est vide.
6. **Catalogue**.
   - Un en-tête « Aliments · N goûtés » et un bouton « Ajouter un aliment », qui ouvre la feuille Aliment perso.
   - Un champ de recherche insensible aux accents et à la casse.
   - Des filtres : Tous / Pas goûtés / À éviter, plus le filtre allergène venu de la carte.
   - Une liste groupée par groupe OMS, dans l'ordre du §3.2, puis « Hors groupes ».
   - Chaque ligne affiche le nom et un badge de statut (§5.3).

### 4.3 Fiche aliment

La fiche montre :
- le nom, le groupe OMS et les allergènes (les 14 possibles) ;
- les règles actives et à venir, chacune avec son texte et sa ou ses sources ;
- quand les sources divergent, un avis par source ;
- l'historique des dégustations, de la plus récente à la plus ancienne. Un tap modifie une dégustation, un balayage la supprime avec confirmation ;
- le bouton « Noter une dégustation », qui ouvre la feuille avec l'aliment présélectionné.

Pour un aliment perso, un bouton « Modifier » permet de changer le nom, le groupe et les allergènes. « Supprimer » n'est proposé que s'il n'a aucune dégustation.

### 4.4 Feuille Dégustation

Champs :
- **Aliment** : sélecteur avec recherche, sur le catalogue et les aliments perso.
- **Quand** : maintenant par défaut, via le `date_time_picker` existant. Bornes : entre la naissance et maintenant.
- **Appréciation** : aimé / bof / refusé, ou rien.
- **Réaction** : aucune / réaction observée.
- **Note** : texte libre, 500 caractères maximum.

Comportement :
- Choisir un aliment affiche ses règles actives dans un encadré, avec son allergène le cas échéant.
- Si « réaction observée » est cochée, un rappel s'affiche : « En cas de gêne respiratoire, gonflement du visage ou malaise : appelez le 15 ».
- À l'enregistrement, `CheckTastingWarnings` peut renvoyer des avertissements : règle `avoid` active, âge inférieur à 4 mois. Dans ce cas, une boîte de dialogue les liste, avec leurs sources, et propose « Enregistrer quand même » ou « Annuler ».
- La même feuille sert à la modification.

### 4.5 Feuille Aliment perso

Champs :
- nom, obligatoire, de 1 à 40 caractères après suppression des espaces en début et fin ;
- groupe : les 7 groupes OMS ou « Hors groupes » ;
- allergènes : sélection multiple parmi les 14.

Aucun doublon de nom (insensible aux accents et à la casse) n'est autorisé avec le catalogue ou les autres aliments perso.

## 5. Catalogue

### 5.1 Fichier

`assets/diversification/catalogue.json`, déclaré dans `pubspec.yaml`. Il contient :

```json
{
  "version": 1,
  "reviewedAt": "2026-09-23",
  "sources": {
    "oms": { "label": "OMS, ligne directrice 2023", "url": "https://www.who.int/publications/i/item/9789240081864" },
    "anses": { "label": "Anses, repères 0–3 ans, 2019", "url": "https://www.anses.fr/fr/system/files/NUT2017SA0145.pdf" },
    "spf": { "label": "Santé publique France, « Pas à pas », 2021", "url": "https://www.mangerbouger.fr/content/show/1500/file/Brochure-SPF-Mangerbougerfr.pdf" },
    "espghan": { "label": "ESPGHAN, position 2017", "url": "https://www.espghan.org/dam/jcr:3d960daa-e2f3-499f-9df9-2da682976cec/2017%20Complementary_Feeding__A_Position_Paper_by_the.21.pdf" },
    "agriculture": { "label": "Ministère de l'Agriculture, lait cru", "url": "https://agriculture.gouv.fr/consommation-de-fromages-base-de-lait-cru-rappel-des-precautions-prendre" },
    "efsa": { "label": "EFSA, nitrates, 2010", "url": "https://efsa.onlinelibrary.wiley.com/doi/10.2903/j.efsa.2010.1935" }
  },
  "guide": { "…": "contenu de la feuille Repères, par phase (§3.1, §3.5)" },
  "foods": [
    {
      "id": "miel",
      "name": "Miel",
      "group": "outsideGroups",
      "allergens": [],
      "rules": [
        { "kind": "avoid", "untilMonths": 12, "sources": ["oms", "anses"],
          "text": "Risque de botulisme infantile, même cuit ou dans une préparation." }
      ]
    }
  ]
}
```

- `id` : slug ASCII en minuscules, stable. Il ne change jamais une fois publié, car les dégustations y font référence.
- `rules[].kind` : `avoid` ou `prepare` (tous deux avec `untilMonths` obligatoire), ou `info` (sans `untilMonths`).
- Quand deux sources divergent sur un même aliment, le JSON porte une règle par avis. Exemple avec le lait de vache : une règle `info` source `oms` (« acceptable dès 6 mois ») et une règle `avoid` source `anses`/`spf` jusqu'à 12 mois.
- Contenu cible, environ 110 aliments :

| Groupe | Nombre visé | Exemples |
| --- | --- | --- |
| Céréales et féculents | ~12 | pâtes, riz, semoule, pomme de terre, pain |
| Légumineuses, fruits à coque et graines | ~10 | lentilles, pois chiches, arachide, amande, sésame, en poudre ou en purée |
| Produits laitiers | ~8 | yaourt, fromage blanc, comté, fromage au lait cru, lait de vache |
| Viandes, poissons et abats | ~18 | poulet, bœuf, saumon, cabillaud, saumon fumé, espadon, thon |
| Œufs | ~3 | œuf bien cuit, jaune d'œuf, œuf cru ou peu cuit |
| Fruits et légumes riches en vitamine A | ~12 | carotte, courge, patate douce, épinard, mangue, abricot |
| Autres fruits et légumes | ~35 | courgette, brocoli, pomme, poire, banane, raisin, tomate cerise |
| Hors groupes | ~12 | huile de colza, beurre, miel, sel, sucre, jus, thé, boisson végétale |

Le JSON est rédigé pendant l'implémentation. Maxence le relit avant le merge.

### 5.2 Validation (test)

Un test charge le vrai fichier et vérifie que :
- les `id` sont uniques et au format slug ;
- tout `group`, `allergens[]`, `kind` et `sources[]` est connu ;
- chaque règle a au moins une source ;
- `untilMonths` est présent et compris entre 1 et 120 pour `avoid` et `prepare`, et absent pour `info` ;
- aucun nom n'est en doublon (insensible aux accents et à la casse) ;
- le guide couvre les 4 phases.

### 5.3 Statut d'un aliment (`ComputeFoodStatus`)

L'âge est pris en mois révolus. Le calcul applique ces règles dans l'ordre :

1. **Règle `avoid` active** (`ageMonths < untilMonths`) : `FoodStatus.avoid(untilMonths, sources)`. On retient la règle active au `untilMonths` le plus grand, c'est-à-dire la plus prudente. Badge : « À éviter avant 1 an · OMS, Anses ».
2. **Âge inférieur à 6 mois** : `FoodStatus.notYetRecommended`. Badge : « Dès 6 mois (OMS) », avec la mention « possible dès 4 mois (France) » sur la fiche.
3. **Au moins une dégustation** : `FoodStatus.tasted(count, needsPreparation)`. Badge : « Goûté ×N ». Une règle `prepare` active ajoute une icône de précaution.
4. **Sinon** : `FoodStatus.notTasted`. Badge : « Pas encore ».

Sans profil bébé, les étapes 1 et 2 sont ignorées. Un aliment perso n'a pas de règle : seules les étapes 2 à 4 s'appliquent.

## 6. Données Firestore

```
households/{code}/tastings/{id}
  foodId: string          id du catalogue ou d'un aliment perso
  at: Timestamp
  liking: string?         "loved" | "meh" | "refused" ; absent = non renseigné
  hadReaction: bool       défaut false
  note: string?           absente si vide

households/{code}/customFoods/{id}
  name: string
  group: string           valeur de FoodGroup
  allergens: string[]     valeurs de Allergen
```

- `id` vient de `idGeneratorProvider`.
- Lecture tolérante :
  - un `liking` inconnu est lu comme `null` ;
  - un allergène inconnu est ignoré ;
  - un `group` inconnu est lu comme `outsideGroups` ;
  - un document sans `at` ou `foodId` valides est ignoré, avec un log `colette`.
- Un `foodId` introuvable dans le catalogue comme dans les aliments perso produit un aliment « Aliment inconnu » (groupe `outsideGroups`, sans règle). Il reste visible dans les historiques et ne compte pas dans la diversité.
- **Flux unique** : `tastings` trié par `at` décroissant, sans limite. Le volume attendu est de quelques centaines de documents sur 18 mois. Tous les indicateurs sont calculés côté app, et aucun compteur n'est stocké.
- Aucun index composite n'est nécessaire.
- Règles de sécurité inchangées : `households/{code}/{collection}/{docId}` couvre déjà les deux collections. Seul le commentaire est mis à jour.
- Ni `feedingPlanSyncProvider` ni les Cloud Functions ne sont concernés.

## 7. Architecture

Nouvelle feature `lib/features/diversification/`. Elle consomme `babyProfileProvider` (feature `baby`), `currentHouseholdCodeProvider` (feature `household`) et `clockProvider`. Elle n'accède jamais à un `data/` d'une autre feature.

### 7.1 Domaine

- **Entités** (freezed ou enums) :
  - `FoodGroup`, `Allergen`, `RuleSource`, `RuleKind`, `Liking` ;
  - `FoodRule(kind, untilMonths?, sources, text)` ;
  - `Food(id, name, group, allergens, rules, isCustom)` ;
  - `Tasting(id, foodId, at, liking?, hadReaction, note?)` ;
  - `SourceRef(label, url)` ;
  - `AgeGuide` (contenu par phase) ;
  - `FoodCatalog(foods, sources, guide, reviewedAt)` ;
  - sealed `FoodStatus` ;
  - `DiversificationPhase` : `preparation`, `months6To8`, `months9To11`, `months12To23` ; au-delà de 23 mois, on reste en `months12To23`.
- **Repositories** :
  - `FoodCatalogRepository.load() → Future<Either<Failure, FoodCatalog>>` ;
  - `TastingsRepository.watchAll(code)`, `save(code, tasting)`, `delete(code, id)` ;
  - `CustomFoodsRepository.watchAll(code)`, `save(code, food)`, `delete(code, id)`.
- **Use cases**, purs et testés :
  - `ComputeDiversificationPhase(birthDate, now)` → phase, mois révolus, jours restants avant 6 mois.
  - `ComputeFoodStatus(food, ageMonths?, tastingCount)` → `FoodStatus` (§5.3).
  - `ComputeDailyDiversity(tastings, foodsById, now)` → groupes couverts le jour local de `now`, hors `outsideGroups` et aliments inconnus.
  - `ComputeAllergenProgress(tastings, foodsById)` → état de chacun des 9 allergènes suivis. Une dégustation avec réaction fixe l'état « réaction signalée », quelles que soient les suivantes. Sinon, une dégustation sans réaction fixe l'état « introduit ».
  - `ComputeFoodsToRetry(tastings, foodsById)` → aliments dont la dernière dégustation à `liking` non nul vaut `meh` ou `refused`, avec le nombre total d'essais. Ordre : dernière dégustation la plus récente d'abord.
  - `CheckTastingWarnings(food, at, birthDate?)` → règles `avoid` actives à l'âge du bébé à la date `at`, et avertissement si cet âge est inférieur à 4 mois.
  - `ValidateCustomFood(name, existingNames)` → erreurs : nom vide, nom trop long, doublon.
- **Mois révolus** : `_monthsBetween` de `ComputeBabyAge` est extrait en fonction publique `completedMonthsBetween` dans `core/dates/date_extensions.dart`. `ComputeBabyAge` l'utilise, ses tests restent inchangés, et la diversification l'utilise aussi.

### 7.2 Data

- `CatalogAssetDataSource(AssetBundle)` lit et décode le JSON. `FoodCatalogRepositoryImpl` mappe le résultat via `FoodDto` et convertit les erreurs avec `guard()`.
- `TastingDto` et `CustomFoodDto` implémentent `toMap` et `fromMap`, avec conversion `Timestamp` ↔ `DateTime`.
- `FirestoreTastingsRepository` et `FirestoreCustomFoodsRepository`.
- `FirestorePaths.tastings = 'tastings'` et `FirestorePaths.customFoods = 'customFoods'`.

### 7.3 Présentation

- **Providers** (`presentation/providers/`, codegen) :
  - `foodCatalogProvider` (keepAlive) ;
  - `tastingsProvider` et `customFoodsProvider` (Stream) ;
  - `foodsProvider` : fusion catalogue + perso, indexée par id ;
  - `diversificationPhaseProvider` ;
  - `dailyDiversityProvider`, `allergenProgressProvider`, `foodsToRetryProvider` ;
  - `foodStatusesProvider` ;
  - `tastingFormControllerProvider` et `customFoodControllerProvider` (actions `save` et `delete`).
- **Pages** : `PlatePage`, `FoodDetailPage`.
- **Widgets** :
  - `PhaseHeader`, `PreparationCard`, `TodayDiversityCard`, `AllergensCard`, `RetryCard` ;
  - `FoodCatalogSection` et `FoodRow` (liste en `SliverList.builder`) ;
  - `FoodStatusBadge` ;
  - `TastingFormSheet`, `CustomFoodSheet`, `AgeGuideSheet`, `TastingWarningsDialog`.
- L'état des filtres et de la recherche du catalogue est un état d'interface local, dans un `ConsumerStatefulWidget` avec `TextEditingController`, disposé dans `dispose()`.
- **Hors de la feature** :
  - `AppRoutes.plate = '/plate'` et une 4ᵉ `StatefulShellBranch` dans `app_router.dart` ;
  - une 4ᵉ `NavigationDestination` dans `MainShell`, dont le commentaire passe de « trois » à « quatre » onglets ;
  - de nouvelles clés dans `app_fr.arb`.
- **Design system** :
  - de nouvelles couleurs `AppColors`, clair et sombre, pour les états d'allergène et de statut, si les couleurs existantes (catégories de soin, succès, alerte) ne suffisent pas ;
  - le contenu du catalogue et du guide est de la donnée : il vient du JSON, pas de l'ARB. Les libellés d'interface restent dans l'ARB.

## 8. Erreurs

| Cas | Comportement |
| --- | --- |
| Échec du chargement du catalogue | État d'erreur dans l'onglet (`failureMessage`). |
| Échec d'écriture d'une dégustation ou d'un aliment perso | Erreur affichée dans la feuille ; la feuille reste ouverte. |
| Suppression d'un aliment perso ayant des dégustations | Bouton absent. Si une dégustation arrive entre-temps, un contrôle au moment du tap renvoie un `Failure` avec un message dédié. |
| Hors ligne | Cache Firestore, comme le reste de l'app. |

## 9. Tests

- **Domaine** : chaque use case, en particulier :
  - le jour de bascule de phase ;
  - la fin d'une règle au mois près ;
  - des sources divergentes, où la plus prudente l'emporte ;
  - une dégustation pile à minuit pour la diversité du jour ;
  - un allergène avec réaction puis sans réaction ;
  - un aliment inconnu ;
  - un `liking` nul ignoré dans « À reproposer » ;
  - l'avertissement avant 4 mois ;
  - l'absence de profil.
- **Catalogue** : validation du vrai `catalogue.json` (§5.2).
- **Data** : DTO et repositories avec `fake_cloud_firestore`, y compris la lecture tolérante.
- **Présentation**, avec `pumpApp`, overrides et `FixedClock` :
  - mode préparation et mode actif ;
  - absence de profil ;
  - cartes vides et masquées ;
  - recherche et filtres ;
  - boîte de dialogue d'avertissement à l'enregistrement ;
  - navigation vers la fiche ;
  - onglet présent dans `MainShell`.
- **Rendu** : clair et sombre en PNG, en test, pour la page Assiette et la feuille Dégustation. Vérification sur simulateur si un foyer est disponible (pas de foyer de test en production sans accord).

## 10. Livraison

- Branche `feat/diversification`, dans le worktree `.claude/worktrees/diversification`, créée depuis `main` (`5ed01d6`, qui contient la courbe de poids et les documents iCloud).
- Le merge sur `main` est validé par Maxence. Il n'y a pas de push sans demande explicite.
