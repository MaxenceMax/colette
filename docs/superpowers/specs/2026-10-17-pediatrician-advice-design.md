# Consignes du pédiatre regroupées — design

Date : 2026-10-17. Remplace l'intégration du 2026-10-15 (390bfe0), où les
consignes du Dr R. Deliège étaient mêlées aux repères OMS / France.

## Objectif

Toutes les consignes du PDF « Diversification et prévention des allergies
alimentaires » (Dr R. Deliège) au même endroit, sur une fiche dédiée ouverte
depuis l'en-tête de l'onglet Assiette. Les repères OMS / France redeviennent
ceux d'avant le 2026-10-15.

## Ce qui sort de l'existant

- `catalogue.json` : repères `pediatre` du guide (phases préparation et 6–8 mois),
  règles `pediatre` des aliments, source `pediatre`. `mealsSummary` de la
  préparation redevient « Lait uniquement ».
- `PreparationCard` : section « À son âge » retirée, `preparationReferences`
  redevient « OMS : à 6 mois · France : entre 4 et 6 mois, jamais avant 4 mois ».
- Code devenu inutile : `GuideItem.fromMonths`, `RuleSource.pediatre`,
  `sourcePediatre`, `preparationAtAge`, `SourceRef.url` facultatif (redevient
  obligatoire), lien conditionnel de `AgeGuideSheet`.
- Conservé : `huile-tournesol` reste au catalogue (règle Anses/SPF seule) pour ne
  pas rendre « inconnue » une dégustation déjà saisie ; `Food.fromMonths` et
  `fromMonths: 3` sur `yaourt`, donc pas d'alerte « trop tôt » dès 3 mois.

## Données

Nouvelle section `pediatricianAdvice` à la racine de `catalogue.json` :

```json
"pediatricianAdvice": {
  "title": "Diversification et prévention des allergies alimentaires",
  "author": "Dr R. Deliège",
  "scope": "Quel que soit l'allaitement, sauf lait HPLV.",
  "steps": [
    { "fromMonths": 3, "items": [ { "text": "…", "details": ["…"] } ] }
  ],
  "avoid": "Pas de farine, pas de céréales, pas de crème dessert et pas de petit-suisse."
}
```

Domaine (`domain/entities/pediatrician_advice.dart`, freezed) :

- `AdviceItem { String text, List<String> details }` (`details` vide par défaut).
- `AdviceStep { int fromMonths, List<AdviceItem> items }`.
- `PediatricianAdvice { title, author, scope, List<AdviceStep> steps, String avoid }`
  avec `AdviceStep? currentStep(int ageMonths)` : dernière étape dont
  `fromMonths <= ageMonths`, `null` avant la première.
- `FoodCatalog.pediatricianAdvice` (obligatoire). DTO : étapes triées
  strictement croissantes, sinon `FormatException` (échec `UnknownFailure`).

Contenu : les 4 étapes du PDF (3, 4, 5, 6 mois), texte fidèle, coquilles corrigées.
À 4 mois, protéines (œuf dur, poisson, viande) et ajouts aux compotes
(fruits à coque, huiles) en `details`.

## Interface

- `PhaseHeader` : deuxième `IconButton` (`Icons.medical_services_outlined`,
  infobulle « Consignes du pédiatre ») à gauche du bouton « Repères à son âge »,
  désactivé tant que le catalogue n'est pas chargé.
- `PediatricianAdviceSheet` (`showPediatricianAdviceSheet`), même gabarit que
  `AgeGuideSheet` : titre, auteur, portée (HPLV), une section par étape
  « À partir de N mois » avec puces et sous-puces, badge « En ce moment » sur
  l'étape courante (âge issu de `diversificationTimelineProvider`, aucun badge
  sans profil ou avant 3 mois), section « À éviter ».
- Tokens du design system uniquement, lisible en clair et sombre.

## Tests

- Domaine : `currentStep` (avant 3 mois, 3, 4, 7 mois).
- Data : mapping de la section, étapes non triées → échec ; contenu réel :
  4 étapes 3/4/5/6, aucune source ni règle `pediatre` restante, yaourt seul
  avec `fromMonths` = 3.
- Présentation : fiche (titre, étapes, sous-puces, badge sur l'étape courante,
  « À éviter ») ; en-tête : l'icône ouvre la fiche ; carte Préparation sans
  « À son âge ».
