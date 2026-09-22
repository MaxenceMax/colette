# Colette — Nombre de soins du nombril par jour

Date : 2026-09-22. Complète la spec v1 (`2026-09-21-colette-v1-design.md`).

## 1. Problème

Le soin du nombril est figé à une fois par jour, partout : use case `ComputeDailyCareStatus`, fonction `pendingCares` du digest du matin, et un simple interrupteur activé / désactivé dans les Réglages. Les parents doivent pouvoir saisir le nombre attendu (trois fois par jour dans le foyer actuel), comme pour Adrigyl, les yeux et le nez.

La date de chute du cordon existe déjà (section « Bébé » des Réglages, champ « Chute du cordon » avec effacement) et n'est pas modifiée.

## 2. Décision

`umbilicalCareEnabled: bool` est remplacé par `umbilicalCarePerDay: int`, `0` signifiant désactivé. Valeur par défaut : **3**.

Alternative écartée : conserver le booléen et ajouter un entier à côté. Deux champs pour une notion, deux contrôles dans l'interface, aucun gain.

## 3. Règles

| Sujet | Règle |
| --- | --- |
| Soin attendu | `umbilicalCarePerDay` fois par jour civil ; tâche absente si `0` (même logique qu'Adrigyl, yeux, nez). |
| Chute du cordon renseignée | `umbilicalCarePerDay` passe à `0`. |
| Chute du cordon effacée | `umbilicalCarePerDay` repasse à `3` (valeur par défaut). |
| Puce « Soin du nombril » (formulaire d'événement, dashboard) | Masquée si `umbilicalCarePerDay == 0`, sauf si l'événement édité l'a déjà cochée (comportement actuel conservé). |
| Réglages | L'interrupteur devient un `IntStepperRow` « Soin du nombril par jour », de 0 à 4, placé à la suite du stepper du nez. |
| Bornes de lecture | 0 à 10, comme les autres compteurs (app et fonctions). |

## 4. Données Firestore

Champ écrit : `baby.careSettings.umbilicalCarePerDay: number`. Le champ `umbilicalCareEnabled` n'est plus écrit.

Lecture de repli, identique côté app (`CareSettingsDto.fromMap`) et côté fonctions (`withDefaults`) :

1. `umbilicalCarePerDay` présent et numérique → cette valeur, bornée 0..10.
2. Sinon, `umbilicalCareEnabled == false` → `0`.
3. Sinon → `3`.

Aucune migration de données : la première sauvegarde des réglages réécrit le document avec le nouveau champ.

## 5. Fichiers touchés

App Flutter :

- `lib/features/baby/domain/entities/care_settings.dart` : champ remplacé, défaut 3.
- `lib/features/baby/data/dtos/baby_profile_dto.dart` : `toMap` / `fromMap` avec repli.
- `lib/features/baby/presentation/providers/baby_settings_controller.dart` : `setCordFallenAt` écrit `0` ou `3`.
- `lib/features/baby/presentation/widgets/care_settings_section.dart` : stepper à la place du `SwitchListTile`.
- `lib/features/dashboard/domain/use_cases/compute_daily_care_status.dart` : cible `umbilicalCarePerDay`.
- `lib/features/events/presentation/widgets/event_form_sheet.dart` : condition `> 0`.
- `lib/l10n/app_fr.arb` : `settingsUmbilicalEnabled` remplacée par `settingsUmbilicalCarePerDay` = « Soin du nombril par jour ».
- Tests : `compute_daily_care_status_test`, `baby_settings_controller_test`, `event_form_sheet_test`, `care_settings_section` (nouveau test du stepper si absent), DTO (repli).

Cloud Functions :

- `functions/src/lib/types.ts` : type, défaut 3, `withDefaults` avec repli.
- `functions/src/lib/care-status.ts` : `count('umbilicalCare') < settings.umbilicalCarePerDay`.
- Tests : `types.test.ts`, `care-status.test.ts`.

Documentation : spec v1 (sections 5, 6.2 et 6.6) mise à jour. Les plans v1 sont historiques et ne sont pas modifiés.

## 6. Tests

- Domaine : tâche nombril avec cible 3 par défaut ; absente si `0` ; cible `n` quelconque.
- DTO : lecture de `umbilicalCarePerDay` ; repli `umbilicalCareEnabled: false` → 0 ; document sans les deux champs → 3 ; `toMap` n'écrit plus `umbilicalCareEnabled`.
- Contrôleur : renseigner la date → 0 ; effacer → 3.
- Présentation : le stepper incrémente et sauvegarde ; la puce nombril disparaît à 0.
- Fonctions : `withDefaults` (mêmes trois cas que le DTO) ; `pendingCares` avec cible 3 et deux soins faits → nombril en attente ; trois faits → absent ; cible 0 → absent.

Vérification finale : `dart format lib test`, `dart analyze`, `flutter test`, puis `npm test` et `npm run build` dans `functions/`.
