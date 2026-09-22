# Colette — Libellés des soins dans le journal

Date : 2026-09-22. Complète la spec v1 (`2026-09-21-colette-v1-design.md`), section Journal.

## 1. Problème

Dans une ligne du journal, chaque soin coché est rendu par une pastille ronde contenant une icône seule, et le biberon par un badge « 120 ml ». Sans le libellé, les icônes (goutte, nuage, œil, air…) ne sont pas parlantes pour les parents.

Le regroupement par jour (en-têtes « Aujourd'hui », « Hier », « Mardi 15 septembre » épinglés) et la pagination par pages de 30 au défilement existent déjà et ne changent pas.

## 2. Décision

Chaque soin coché et le biberon deviennent une **puce icône + texte** dans la tuile `EventTile`. Les puces restent dans le `Wrap` existant et passent à la ligne au besoin.

Alternatives écartées :

- Une ligne par soin : tuiles trop hautes quand un événement cumule quatre ou cinq soins.
- Pastilles conservées plus une phrase « Pipi · Caca · Biberon 120 ml » en dessous : l'icône et son libellé ne sont pas côte à côte, doublon visuel.

## 3. Règles d'affichage

| Élément | Règle |
| --- | --- |
| Puce de soin | Icône `CareTypeUi.icon` puis libellé `CareTypeUi.label` (« Pipi », « Caca », « Couche », « Adrigyl », « Bain », « Soin des yeux », « Soin du nez », « Soin du nombril »). |
| Puce biberon | Icône `Icons.local_drink_outlined` (déjà utilisée par `BottleField`) puis texte `bottleMl` (« 120 ml »). Couleur de la catégorie alimentation. Affichée après les soins, uniquement si `bottleMl` est renseigné. |
| Style commun | Fond : couleur de la catégorie en `AppOpacity.light`. Icône et texte : couleur de la catégorie. Texte : style `label`. Coins `AppRadius.round`. Padding `AppSpacing.sm` horizontal, `AppSpacing.xxs` vertical. Icône de taille `AppSize.xs`, espacement `AppSpacing.xs` entre icône et texte. |
| Disposition | `Wrap` existant conservé, espacement `AppSpacing.xs`. Heure, heure de fin, note et glissement pour supprimer inchangés. |
| Thèmes | Lisible en clair et en sombre : les couleurs de catégorie ont déjà une variante par thème dans `AppColors`. |

Un seul widget privé `_CareChip({icon, label, color})` remplace `_CareDot` et `_BottleBadge`.

## 4. Fichiers touchés

- `lib/features/events/presentation/widgets/event_tile.dart` : remplacement des deux widgets privés par `_CareChip`.
- `test/features/events/presentation/timeline_page_test.dart` : vérifier que le libellé de chaque soin coché (« Couche », « Bain ») et « 120 ml » s'affichent, et que l'icône biberon est présente.

Aucune modification de domaine, de données, de providers ni de `app_fr.arb` : tous les libellés existent.

## 5. Vérification

`dart format lib test`, `dart analyze`, `flutter test`, puis contrôle visuel sur simulateur iPhone en thème clair et sombre avec un événement cumulant plusieurs soins et un biberon.
