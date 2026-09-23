# Colette — Repères OMS et cible journalière ajustable

Date : 2026-09-22. Complète la spec v1 (`2026-09-21-colette-v1-design.md`, §6.3).

## 1. Problème

La carte « Prochain biberon » affiche une cible journalière calculée d'après l'OMS (ml/kg selon le jour de vie, ou repère par âge sans pesée), sans jamais montrer d'où vient ce chiffre. Les parents n'ont aucun tableau de référence dans l'app, et aucun moyen d'ajuster la cible quand la pédiatre ou la maternité donne une consigne différente (bébé prématuré, reflux, reprise de poids lente). Les seuls leviers sont indirects : nombre de biberons par jour et ajout d'une pesée.

## 2. Décision

Deux ajouts, réunis dans une même feuille « Repères OMS » ouverte depuis la carte « Prochain biberon » :

1. **Tableau indicatif OMS** : repères par âge (ml/jour) et règle au poids (ml/kg), avec la ligne du jour surlignée et, si une pesée existe, le calcul du jour.
2. **Cible journalière ajustable** : une valeur fixe en ml/jour, persistante, qui remplace le calcul OMS tant qu'elle est renseignée. Un bouton ramène au calcul OMS.

La cible ajustée est stockée dans `careSettings.dailyTargetMl` (`null` = calcul OMS). Le snapshot `feedingPlan` lu par les Cloud Functions reste inchangé dans sa forme : il est simplement recalculé avec la cible effective.

Alternatives écartées :

- **Écart en pourcentage ou delta appliqué à l'OMS** : suit les pesées automatiquement, mais moins lisible (« +10 % de quoi ? ») et la consigne médicale est presque toujours donnée en ml/jour ou en ml par biberon.
- **Ajustement valable pour le jour seul** : à refaire chaque matin, alors que le besoin réel est une consigne qui dure jusqu'à la prochaine consultation.
- **Champ dédié sur `BabyProfile` ou repository séparé** : plomberie supplémentaire pour un entier, alors que `feedsPerDay` vit déjà dans `CareSettings` et que toute écriture des réglages de soins déclenche déjà la resynchronisation du plan.

## 3. Règles

| Sujet | Règle |
| --- | --- |
| Cible ajustée | `CareSettings.dailyTargetMl: int?`, défaut `null`. Bornes 100 à 1500 ml, pas de 10. |
| Cible effective | `dailyTargetMl = careSettings.dailyTargetMl ?? omsTargetMl`. Suggestion, restant, barre de progression et snapshot `feedingPlan` découlent de la cible effective. |
| Cible OMS | Inchangée : `min(150, 60 + 20 × (d − 1))` ml/kg × poids, arrondi à 10 ml ; sans pesée, repère par âge. Toujours calculée et exposée, même quand une cible ajustée existe. |
| Repères par âge | Source unique `FeedingAgeBand` : jour 1 → 240, jour 2 → 320, jour 3 → 400, jour 4 → 440, jour 5 → 480, jour 6 à 1 mois (≤ 30 j) → 480, 1 à 2 mois (≤ 60 j) → 630, 2 à 4 mois (≤ 120 j) → 720, 4 à 6 mois (≤ 180 j) → 900, 6 mois et plus → 900. |
| Règle au poids | Lignes jour 1 → 60, jour 2 → 80, jour 3 → 100, jour 4 → 120, jour 5 → 140, jour 6 et plus → 150 ml/kg. |
| Ligne du jour | Surlignée (fond `primaryContainer`) dans les deux tables, d'après le jour de vie. |
| Calcul du jour | Avec pesée : « {mlPerKg} ml/kg × {kg} kg = {ml} ml » sous la règle au poids (poids en kg avec une décimale, séparateur locale). Sans pesée : l'invitation existante à ajouter une pesée. |
| Carte, ligne d'aide | Cible ajustée : « Cible ajustée à {ml} ml · OMS : {oms} ml ». Sinon, comportement actuel (mention « Repères par âge… » uniquement sans pesée). |
| Carte, accès | Icône info (`Icons.info_outline`) à droite du titre « Prochain biberon », infobulle « Voir les repères OMS ». Le tap sur la carte continue d'ouvrir le formulaire biberon. |
| Écriture | Chaque changement de la cible passe par `BabySettingsController.updateCareSettings`, qui déclenche `feedingPlanSync`. État local optimiste dans la feuille, comme `CareSettingsSection`. `BabySettingsController._run` lit `feedingPlanSyncProvider` avant l'`await` et ne touche `state` que si `ref.mounted`, pour que fermer la feuille pendant l'écriture ne casse ni le contrôleur ni la sync. |
| Erreurs | Affichée dans la feuille, sous le titre de la section cible (texte en `error`), et la valeur optimiste est remise à celle du profil. Pas de `SnackBar` : la feuille modale le masquerait. |
| Sans profil | L'icône info n'existe pas (la carte « plan indisponible » est inchangée). |
| Cloud Functions | Aucun changement : `StoredCareSettings` est partiel, le champ inconnu est ignoré ; les fonctions ne lisent que `feedingPlan.suggestedMl` et `nextBottleAt`. |

## 4. Architecture

Domaine (`features/baby/domain`) :

- `CareSettings` : champ `int? dailyTargetMl` (défaut `null`).

Domaine (`features/dashboard/domain`) :

- `FeedingAgeBand` (enum, `entities/feeding_age_band.dart`) : dix valeurs avec `dailyMl`, et `static FeedingAgeBand forDayOfLife(int day)`. `ComputeFeedingPlan.dailyTargetFromAge` délègue à `forDayOfLife(day).dailyMl` ; la table de nombres n'existe plus qu'ici.
- `FeedingPlan` : champs ajoutés `omsTargetMl` et `isTargetOverridden`. `dailyTargetMl` reste la cible effective.
- `ComputeFeedingPlan.call` : paramètre `int? dailyTargetMlOverride`. Calcule `omsTargetMl` comme aujourd'hui, puis `dailyTargetMl = dailyTargetMlOverride ?? omsTargetMl`, `isTargetOverridden = dailyTargetMlOverride != null`. `isEstimatedFromAge` garde son sens : cible OMS obtenue sans pesée.
- `ComputeFeedingPlan.weightTargetMl(dayOfLife, grams)` : seul endroit qui calcule la cible OMS au poids ; réutilisé par `ComputeFeedingReference`.
- `FeedingReference` (freezed, `entities/feeding_reference.dart`) : `dayOfLife`, `ageBand`, `mlPerKg`, `weightGrams?`, `weightTargetMl?`.
- `ComputeFeedingReference()(birthDate, latestWeightGrams, now) → FeedingReference` : réutilise `ComputeFeedingPlan.dayOfLife`, `mlPerKg` et `weightTargetMl` ; `null` sans pesée.

Données (`features/baby/data`) :

- `CareSettingsDto.toMap` écrit `dailyTargetMl` (`null` accepté). `fromMap` lit un `num?` borné 100 à 1500 ; absent ou non numérique → `null`.

Présentation :

- `dashboard_providers.dart` : `feedingPlanProvider` passe `profile.careSettings.dailyTargetMl` ; nouveau `feedingReferenceProvider` (`FeedingReference?`, `null` sans profil).
- `feeding_plan_sync.dart` : `FirestoreFeedingPlanSync` passe aussi l'override.
- `next_bottle_card.dart` : icône info dans la ligne de titre, ligne d'aide conditionnelle.
- `feeding_reference_sheet.dart` (nouveau, `dashboard/presentation/widgets`) : `showFeedingReferenceSheet(context)` et `FeedingReferenceSheet` (`ConsumerWidget`, `isScrollControlled`, `useSafeArea`). Sections en widgets privés :
  - `_AgeTableSection` : une ligne par `FeedingAgeBand`, ligne courante surlignée.
  - `_WeightRuleSection` : six lignes ml/kg, ligne courante surlignée, calcul du jour ou invitation à peser.
  - `FeedingTargetSection` (fichier `feeding_target_section.dart`, `ConsumerStatefulWidget` à état local optimiste) : cible OMS affichée ; bouton « Ajuster » qui pose `dailyTargetMl = omsTargetMl` (borné) ; une fois ajustée, `IntStepperRow` (min 100, max 1500, pas 10, suffixe ml) et bouton texte « Revenir au calcul OMS » qui pose `null` ; erreur d'écriture affichée en ligne.
- Les libellés des tranches d'âge et des jours sont des clés l10n ; le domaine ne porte aucun texte.

## 5. Fichiers touchés

- `lib/features/baby/domain/entities/care_settings.dart` : `dailyTargetMl`.
- `lib/features/baby/data/dtos/baby_profile_dto.dart` : lecture / écriture bornée.
- `lib/features/dashboard/domain/entities/feeding_age_band.dart` (nouveau).
- `lib/features/dashboard/domain/entities/feeding_reference.dart` (nouveau, freezed).
- `lib/features/dashboard/domain/entities/feeding_plan.dart` : `omsTargetMl`, `isTargetOverridden`.
- `lib/features/dashboard/domain/use_cases/compute_feeding_plan.dart` : override, délégation à `FeedingAgeBand`.
- `lib/features/dashboard/domain/use_cases/compute_feeding_reference.dart` (nouveau).
- `lib/features/dashboard/presentation/providers/dashboard_providers.dart` : override, `feedingReferenceProvider`.
- `lib/features/dashboard/presentation/providers/feeding_plan_sync.dart` : override.
- `lib/features/dashboard/presentation/widgets/next_bottle_card.dart` : icône info, ligne d'aide.
- `lib/features/dashboard/presentation/widgets/feeding_reference_sheet.dart` (nouveau) : feuille, table par âge, règle au poids.
- `lib/features/dashboard/presentation/widgets/feeding_target_section.dart` (nouveau) : `FeedingTargetSection`, cible ajustable avec état local optimiste et erreur en ligne.
- `lib/features/baby/presentation/providers/baby_settings_controller.dart` : sync lue avant l'`await`, garde `ref.mounted`.
- `lib/l10n/app_fr.arb` : `feedingPlanAdjusted(ml, oms)`, `feedingReferenceTooltip`, `feedingReferenceTitle`, `feedingReferenceSource`, `feedingReferenceAgeTitle`, `feedingReferenceWeightTitle`, `feedingDayOfLife(day)` (jours 1 à 5, dans les deux tables), `feedingAgeBandDay6ToMonth1`, `feedingAgeBandMonth1To2`, `feedingAgeBandMonth2To4`, `feedingAgeBandMonth4To6`, `feedingAgeBandMonth6Plus`, `feedingWeightRuleDay6Plus`, `feedingMlPerDay(ml)`, `feedingMlPerKg(ml)`, `feedingWeightCalc(mlPerKg, kg, ml)`, `feedingTargetTitle`, `feedingTargetOms(ml)`, `feedingTargetAdjust`, `feedingTargetAdjusted`, `feedingTargetReset`.
- Tests : `feeding_age_band_test.dart`, `compute_feeding_reference_test.dart`, `dashboard_providers_test.dart`, `feeding_reference_sheet_test.dart` (nouveaux) ; ajouts dans `compute_feeding_plan_test.dart` (override, bornes), `baby_profile_dto_test.dart`, `firestore_baby_repository_test.dart` (effacement via merge), `baby_settings_controller_test.dart` (destruction pendant l'écriture), `feeding_plan_sync_test.dart`, `dashboard_page_test.dart` (mention, icône, tap carte).

Documentation : spec v1 §6.3 complétée (cible ajustée, source unique de la table par âge, snapshot inchangé).

## 6. Tests

- `FeedingAgeBand.forDayOfLife` : jours 1 à 5 distincts ; 6 et 30 → jour 6 à 1 mois ; 31 et 60 → 1 à 2 mois ; 61 et 120 → 2 à 4 mois ; 121 et 180 → 4 à 6 mois ; 181 → 6 mois et plus.
- `ComputeFeedingPlan` : override 600 avec pesée 4 200 g au jour 10 → `dailyTargetMl` 600, `omsTargetMl` 630, `isTargetOverridden` vrai, `suggestedMl` calculé sur 600 ; override `null` → comportement actuel, `isTargetOverridden` faux ; override sans pesée → `isEstimatedFromAge` vrai et cible effective = override.
- `ComputeFeedingReference` : jour 3 sans pesée → `mlPerKg` 100, `weightTargetMl` null ; jour 10 avec 4 200 g → `mlPerKg` 150, `weightTargetMl` 630.
- DTO : aller-retour avec 600 ; absent → `null` ; `'abc'` → `null` ; 50 → 100 ; 9 999 → 1 500.
- `FirestoreFeedingPlanSync` : avec `dailyTargetMl` 600 dans le profil, le snapshot écrit reflète la cible ajustée (`suggestedMl` cohérent).
- Carte : avec override, texte « Cible ajustée à 600 ml · OMS : 630 ml » ; sans override et sans pesée, mention actuelle ; l'icône info ouvre la feuille.
- Feuille : la ligne du jour est surlignée dans les deux tables ; « Ajuster » appelle `updateCareSettings` avec `dailyTargetMl` = cible OMS ; « + » appelle avec +10 ; « Revenir au calcul OMS » appelle avec `null` ; une cible poussée par l'autre appareil est adoptée ; une erreur d'écriture s'affiche en ligne et annule l'ajustement.

Vérification finale : `dart run build_runner build -d`, `dart format lib test`, `dart analyze`, `flutter test`.
