# Colette — Suivi des dents

Date : 2026-10-14. Complète la spec v1 (`2026-09-21-colette-v1-design.md`) et le volet santé (`2026-09-23-health-follow-up-design.md`).

## 1. Problème

Les parents veulent garder la trace des dents de leur enfant : quand chaque dent de lait sort, quand elle tombe, puis quand les dents définitives arrivent. Un carnet papier ou une note ne permet pas de voir d'un coup d'œil quelles dents sont là. Ils veulent :

- un **schéma de la bouche interactif** : on touche une dent pour noter sa sortie ou sa chute ;
- savoir quelles dents arrivent en général ensuite, **sans alerte de retard** ;
- retrouver ces informations sur les deux iPhones du foyer.

Décisions validées par Maxence le 2026-10-14 :

- deux dentitions : les 20 dents de lait et les 32 dents définitives ;
- par dent : date de sortie, date de chute (dents de lait seulement), note libre facultative ; pas de photo ;
- âges habituels affichés en repère discret ;
- aucun effet ailleurs dans l'app : ni notification, ni Journal, ni Cloud Function ;
- schéma dessiné par le code (`CustomPainter`), plutôt qu'une image SVG ou une grille de cases ;
- accès par une carte « Dents » dans l'onglet Santé, qui ouvre une page dédiée.

## 2. Âges de référence

Source : American Dental Association, tableaux *Primary Tooth Development* et *Permanent Tooth Development* (©2012), téléchargés le 2026-10-14 depuis [MouthHealthy, Eruption Charts](https://www.mouthhealthy.org/all-topics-a-z/eruption-charts). Ils sont les seuls à donner un âge par dent et par arcade, sortie et chute comprises. Les fourchettes de l'UFSBD ([fiche « Des dents de lait aux dents définitives »](https://www.ufsbd.fr/wp-content/uploads/2013/08/fiche-dents-laits-definitives.pdf)) sont cohérentes (de 6 à 30 mois pour les dents de lait), mais ne distinguent pas le haut du bas.

Dents de lait :

| Dent | Haut : sortie | Haut : chute | Bas : sortie | Bas : chute |
| --- | --- | --- | --- | --- |
| Incisive centrale | 8-12 mois | 6-7 ans | 6-10 mois | 6-7 ans |
| Incisive latérale | 9-13 mois | 7-8 ans | 10-16 mois | 7-8 ans |
| Canine | 16-22 mois | 10-12 ans | 17-23 mois | 9-12 ans |
| Première molaire | 13-19 mois | 9-11 ans | 14-18 mois | 9-11 ans |
| Deuxième molaire | 25-33 mois | 10-12 ans | 23-31 mois | 10-12 ans |

Dents définitives (sortie seulement) :

| Dent | Haut | Bas |
| --- | --- | --- |
| Incisive centrale | 7-8 ans | 6-7 ans |
| Incisive latérale | 8-9 ans | 7-8 ans |
| Canine | 11-12 ans | 9-10 ans |
| Première prémolaire | 10-11 ans | 10-12 ans |
| Deuxième prémolaire | 10-12 ans | 11-12 ans |
| Première molaire | 6-7 ans | 6-7 ans |
| Deuxième molaire | 12-13 ans | 11-13 ans |
| Troisième molaire (dent de sagesse) | 17-21 ans | 17-21 ans |

Ces âges sont une **table embarquée** (`lib/features/teeth/domain/reference/tooth_schedule.dart`), comme le calendrier des vaccins : rien dans Firestore. Ils sont affichés tels quels, en mois ou en ans comme dans la source. Ils ne déclenchent jamais d'alerte : l'UFSBD rappelle qu'un retard n'est pas un signe de mauvaise santé.

## 3. Numérotation

Chaque dent est identifiée par son numéro international (FDI), celui qu'emploient les dentistes en France :

- premier chiffre, le quadrant : dents définitives 1 (haut droite), 2 (haut gauche), 3 (bas gauche), 4 (bas droite) ; dents de lait 5, 6, 7, 8 dans le même ordre ;
- second chiffre, la position depuis le milieu : 1 à 5 pour les dents de lait, 1 à 8 pour les définitives.

Exemples : 51 = incisive centrale de lait en haut à droite ; 36 = première molaire définitive en bas à gauche. Droite et gauche sont celles de l'enfant. Le schéma est vu de face, comme chez le dentiste : la droite de l'enfant est à gauche de l'écran, avec les libellés « Droite » et « Gauche » sous le schéma pour lever le doute.

## 4. Domaine (`lib/features/teeth/domain`)

Nouvelle feature `teeth`, sur le modèle de `sleep`.

| Élément | Rôle |
| --- | --- |
| `Dentition` (enum) | `primary` (lait), `permanent` (définitive). |
| `ToothArch` (enum) | `upper`, `lower`. |
| `ToothSide` (enum) | `right`, `left` (côté de l'enfant). |
| `ToothKind` (enum) | `centralIncisor`, `lateralIncisor`, `canine`, `firstPremolar`, `secondPremolar`, `firstMolar`, `secondMolar`, `thirdMolar`. |
| `ToothId` (extension type sur `int`) | Numéro FDI. Getters `dentition`, `arch`, `side`, `kind` déduits du numéro (pour une dent de lait, positions 4 et 5 = `firstMolar` et `secondMolar`). Constantes `ToothId.primaryAll` (20) et `ToothId.permanentAll` (32), dans l'ordre du schéma. Construction depuis un entier hors table → `null` (`ToothId.tryParse`). |
| `AgeRange` (record) | `(from, to, unit)`, `unit` = `AgeUnit.months` ou `AgeUnit.years`, pour l'affichage tel que dans la source. |
| `ToothReference` (record) | `(eruption, shedding?)`, `shedding` pour les dents de lait seulement. `toothReferenceOf(ToothId)` lit la table indexée par `(dentition, arch, kind)`. |
| `ToothRecord` (freezed) | Ce qui a été noté pour une dent : `toothId`, `eruptedAt?`, `lostAt?`, `note?`, `updatedAt`, `updatedByDeviceId`. Getter `isEmpty` : ni date ni note. |
| `ToothStatus` (enum) | `absent`, `erupted`, `lost`. |
| `ComputeToothStatus` (pur) | `lost` si `lostAt`, sinon `erupted` si `eruptedAt`, sinon `absent`. Une chute sans date de sortie est acceptée (dent sortie avant que l'app ne soit utilisée). |
| `ComputeTeethSummary` (pur) | Renvoie un `TeethSummary` pour la carte : nombre de dents en bouche (statut `erupted`, les deux dentitions) et jusqu'à deux **groupes attendus** (voir ci-dessous). |
| `ValidateToothRecord` (pur) | Voir §4.2. |
| `TeethRepository` | `watchTeeth(code)`, `saveTooth(code, record)` (`set` complet), `deleteTooth(code, toothId)`. |

### 4.1 Prochaines dents attendues

Un groupe = un type de dent sur une arcade, sans distinguer droite et gauche (« incisives centrales du bas »). Calcul :

1. candidats : les dents de lait au statut `absent` ; s'il n'y en a plus, les dents définitives au statut `absent` ;
2. regroupement par `(dentition, arch, kind)` ; un groupe est candidat dès qu'une de ses deux dents est absente ;
3. tri par début de fourchette de sortie, puis le bas avant le haut à égalité ;
4. les deux premiers groupes, avec leur fourchette.

Exemple à la naissance : « incisives centrales du bas (6-10 mois) » puis « incisives centrales du haut (8-12 mois) ». Le calcul ne dépend pas de l'âge de l'enfant : c'est l'ordre habituel de sortie, pas une échéance.

### 4.2 Validation

Nouvelles raisons dans `ValidationReason` :

- `toothDateBeforeBirth` : sortie ou chute avant la date de naissance ;
- `toothDateInFuture` : sortie ou chute après aujourd'hui (jour civil). Une date choisie au sélecteur est enregistrée à midi : une tolérance en minutes, comme pour les événements, refuserait une dent sortie le matin même ;
- `toothLostBeforeErupted` : chute avant la sortie, quand les deux dates sont renseignées ;
- `toothLossOnPermanent` : chute renseignée sur une dent définitive (garde-fou, l'interface ne la propose pas).

Les dates sont comparées en jours civils locaux (`date_extensions.dart`) : sortie et chute le même jour, c'est accepté. La note est rognée ; une note vide devient `null`.

## 5. Données

- `households/{code}/teeth/{toothId}` (identifiant du document = numéro FDI en texte, ex. `"51"`) :
  ```
  { eruptedAt?: Timestamp, lostAt?: Timestamp, note?: string,
    updatedAt: Timestamp, updatedByDeviceId: string }
  ```
  Clés absentes plutôt que `null`. Un enregistrement vidé (`isEmpty`) est supprimé au lieu d'être écrit. Un document dont l'identifiant n'est pas un numéro FDI connu est ignoré à la lecture (journalisé).
- Dates enregistrées à midi, heure locale, comme une date choisie au sélecteur : seul le jour compte.
- `FirestorePaths.teeth = 'teeth'`. Règles Firestore : la règle générique des sous-collections couvre déjà `teeth`, seul le commentaire de `firestore.rules` est complété (rien à déployer).
- Aucune écriture ne déclenche `feedingPlanSyncProvider` (ni biberon, ni pesée, ni réglage de soins).

## 6. Présentation (`lib/features/teeth/presentation`)

### 6.1 Providers

- `teethRepositoryProvider` (`keepAlive`) → `FirestoreTeethRepository`.
- `teethProvider` : `Stream<Map<ToothId, ToothRecord>>` du foyer courant (`retry: noRetry`, comme `babyProfile`).
- `teethSummaryProvider` : `ComputeTeethSummary` sur `teethProvider`.
- `TeethController` (`@riverpod` classe, `FutureOr<void> build()`) : `save(ToothRecord)` valide avec la date de naissance (`babyProfileProvider`) et `clockProvider`, puis supprime si `isEmpty`, sinon écrit ; `clear(ToothId)` supprime. `updatedAt` via `clockProvider`, `updatedByDeviceId` via `deviceIdProvider`.

### 6.2 Carte « Dents » dans Santé

`TeethCard`, insérée dans `HealthPage` juste après `NextAppointmentCard` :

- titre « Dents », icône ;
- ligne 1 : « Pas encore de dent » ou « {n} dents en bouche » (pluriel ICU) ;
- ligne 2 : « Ensuite : incisives centrales du bas (6-10 mois) », avec le second groupe s'il existe ; absente quand toutes les dents sont notées ;
- au tap, ouvre `/health/teeth`.

Pendant le chargement, la carte affiche ses libellés sans chiffre ; en erreur, `failureMessage` en texte secondaire.

### 6.3 Page Dents

Route `AppRoutes.teeth = '/health/teeth'`, imbriquée sous la branche Santé pour garder la barre d'onglets.

- AppBar « Dents ».
- `SegmentedButton` « De lait » / « Définitives » (« De lait » par défaut, non mémorisé).
- Compteur : « {n} sorties sur 20 » (ou « sur 32 »), où n compte les dents sorties ou tombées ; suivi de « · {m} tombées » dès qu'une dent de lait est tombée.
- Le schéma (§6.4), puis la légende : sortie, tombée, pas encore.
- Toucher une dent ouvre la fiche (§6.5).

### 6.4 Schéma

Deux classes séparées pour pouvoir tester la géométrie sans dessin :

- `TeethLayout` (pur, sans Flutter UI) : pour une `Dentition` et une `Size`, place chaque dent sur deux demi-ellipses (arcade du haut ouverte vers le bas, arcade du bas ouverte vers le haut) et renvoie un `Rect` par `ToothId`. La taille d'une dent dépend de son type (incisives plus petites, molaires plus grandes). `hitTest(Offset) → ToothId?` renvoie la dent la plus proche dans un rayon de tolérance (zone tactile d'au moins 44 pt, `AppSize`).
- `TeethChart` (widget) : `LayoutBuilder` (largeur disponible, hauteur au ratio fixe du schéma), `GestureDetector` qui appelle `hitTest`, `CustomPaint` avec `TeethChartPainter`.

Rendu, avec les couleurs existantes d'`AppColors` (rien à ajouter) :

| État | Rendu |
| --- | --- |
| `absent` | contour pointillé `textSecondary`, sans remplissage |
| `erupted` | remplissage `primary`, contour `primary` |
| `lost` | remplissage `surfaceContainer`, contour `border`, petite croix `textSecondary` |
| dent de la fiche ouverte | contour épaissi `accent` |

Libellés « Droite » et « Gauche » sous le schéma, « Haut » et « Bas » au centre de chaque arcade, en `coletteTextStyles.small`.

Accessibilité : `semanticsBuilder` du painter, un nœud par dent, ex. « Incisive centrale du haut, droite, sortie le 12 septembre 2026 », avec l'action tap. Les tests de widget s'en servent pour toucher une dent précise.

### 6.5 Fiche d'une dent

`ToothSheet` (feuille modale, comme `CustomAppointmentSheet`), `ConsumerStatefulWidget` qui `ref.watch` `teethControllerProvider` :

- titre : « Incisive centrale du haut, à droite » ; sous-titre : « Dent n° 51 » ;
- repère : « Sort en général vers 8-12 mois, tombe vers 6-7 ans. » (définitives : sortie seulement) ;
- « Sortie le » : bouton « Ajouter la date de sortie », qui devient un `DateField` (aujourd'hui par défaut) avec un bouton pour retirer la date ;
- « Tombée le » : idem, dents de lait seulement ;
- note : `TextField` multiligne facultatif, contrôleur disposé dans `dispose()` ;
- « Enregistrer » ; « Tout effacer » si un enregistrement existe, après confirmation ;
- erreurs de validation sous le formulaire (`failureMessage`), un message par nouvelle raison.

## 7. Localisation (`app_fr.arb`)

Tutoiement, pluriels ICU, comme l'existant. Clés principales :

- Carte et page : `teethTitle` (« Dents »), `teethNone` (« Pas encore de dent »), `teethInMouth` (« {count, plural, =1{1 dent en bouche} other{{count} dents en bouche}} »), `teethNextOne` (« Ensuite : {first} »), `teethNextTwo` (« Ensuite : {first}, puis {second} »), `teethPrimary` (« De lait »), `teethPermanent` (« Définitives »), `teethEruptedCount` (« {count} sorties sur {total} »), `teethLostCount` (« {count} tombées »), `teethCounterWithLost` (« {erupted} · {lost} »), `teethLegendErupted` / `teethLegendLost` / `teethLegendAbsent` (« Sortie », « Tombée », « Pas encore »), `teethRight` / `teethLeft` / `teethUpper` / `teethLower`.
- Noms : un libellé par `ToothKind` au singulier et au pluriel, plus « du haut » / « du bas », « à droite » / « à gauche ».
- Âges : `ageRangeMonths` (« {from}-{to} mois »), `ageRangeYears` (« {from}-{to} ans »).
- Fiche : `toothNumber` (« Dent n° {id} »), `toothReferenceEruption` (« Sort en général vers {range}. »), `toothReferenceFull` (« Sort en général vers {eruption}, tombe vers {shedding}. »), `toothEruptedAt` (« Sortie le »), `toothLostAt` (« Tombée le »), `toothAddEruption`, `toothAddLoss`, `toothNoteHint`, `toothClear`, `toothClearConfirm`.
- Erreurs : `errorToothDateBeforeBirth` (« La date ne peut pas être avant la naissance. »), `errorToothDateInFuture` (« La date ne peut pas être dans le futur. »), `errorToothLostBeforeErupted` (« La chute ne peut pas précéder la sortie. »), `errorToothLossOnPermanent` (« Une dent définitive ne tombe pas. »).

## 8. Tests

- **Domaine** (purs) :
  - `ToothId` : `dentition`, `arch`, `side`, `kind` pour 51, 55, 65, 71, 11, 18, 36, 48 ; `tryParse` refuse 19, 56, 0, 99 ; `primaryAll` a 20 dents et `permanentAll` 32, sans doublon.
  - `toothSchedule` : chaque `(dentition, arch, kind)` existant a une entrée ; les dents de lait ont une chute, les définitives non ; quelques valeurs vérifiées contre le tableau du §2.
  - `ComputeToothStatus` : les trois états, chute sans sortie.
  - `ComputeTeethSummary` : à la naissance ; après les incisives centrales du bas (une seule des deux puis les deux) ; égalité de fourchette ; passage aux définitives quand les 20 dents de lait sont notées ; plus de groupe quand tout est noté ; une dent tombée ne compte pas en bouche.
  - `ValidateToothRecord` : chaque raison, sortie et chute le même jour acceptées, date du jour acceptée même à midi le matin, note rognée.
- **Data** (`fake_cloud_firestore`) : aller-retour complet et partiel ; `toMap` n'écrit pas les clés nulles ; identifiant inconnu ignoré ; suppression.
- **Géométrie** : `TeethLayout` sans recouvrement de deux dents, symétrie droite/gauche, `hitTest` au centre de chaque dent renvoie cette dent, `null` au centre du schéma.
- **Présentation** (`pumpApp`, `mocktail`) : carte (vide, avec dents, groupes attendus) et navigation vers la page ; bascule « De lait » / « Définitives » ; toucher une dent ouvre sa fiche ; pas de « Tombée le » sur une définitive ; enregistrement appelle le contrôleur ; message d'erreur affiché ; « Tout effacer » demande confirmation ; rendu en thème clair et sombre.

## 9. Livraison

- Branche `feat/teeth-tracking`, worktree `.claude/worktrees/teeth-tracking`, partie de `main` (`3416698`).
- Commits en français, `git add` de fichiers ciblés, `dart run build_runner build -d` après chaque fichier annoté.
- Fin de lot : `dart format lib test`, `dart analyze`, `flutter test`, vérification sur simulateur iPhone en clair et en sombre.
- Merge `--no-ff` « merge: suivi des dents (feat/teeth-tracking) » sur `main` après validation explicite de Maxence, sans push.
- Conflits possibles avec d'autres branches : `app_fr.arb`, `app_router.dart`, `ValidationReason`, `health_page.dart`. Résolution par juxtaposition.

## 10. Hors périmètre

- Photo par dent.
- Notification à l'autre parent, entrée dans le Journal.
- Alerte de retard de pousse ou de chute.
- Lien entre une dent de lait tombée et la dent définitive qui la remplace.
- Symptômes de poussée (fièvre, sommeil) : relèvent du futur volet fièvre et médicaments.
- Export pour le dentiste.
