# Horaires et intervalle des biberons — design

Date : 2026-09-30
Branche : `feat/bottle-schedule`

## Objectif

Rendre réglable dans l'onglet Réglages le rythme des biberons, aujourd'hui codé en dur (fourchette de 2 h 30 à 5 h après chaque biberon, jour et nuit). Les parents donnent le dernier biberon vers 23 h 30 et le premier entre 6 h 30 et 7 h 30 ; entre les deux, ils espacent les biberons d'un temps fixe.

## Périmètre

- Trois réglages partagés par le foyer : heure du premier biberon, heure du biberon du soir, intervalle entre deux biberons.
- Le prochain biberon reste calculé à partir du dernier biberon réel ; la nuit, rien n'est prévu ni rappelé.
- Le nombre de biberons par jour est déduit des réglages ; le réglage manuel « Biberons par jour » disparaît.
- Hors périmètre : Cloud Functions (inchangées, aucun redéploiement), biberons de nuit comptés à part, horaires différents selon les jours.

## Réglages

Nouvelle carte « Biberons » dans l'onglet Réglages, sous la carte des soins, avec trois lignes −/+ par pas de 15 min :

| Réglage | Défaut | Bornes |
|---|---|---|
| Premier biberon | 7 h 00 | 4 h 00 – 10 h 00 |
| Biberon du soir | 23 h 30 | 20 h 00 – 23 h 45 |
| Intervalle | 3 h 00 | 1 h 30 – 5 h 00 |

Sous les lignes, un résumé : « ≈ 7 biberons par jour ».

`IntStepperRow` reçoit un paramètre optionnel `String Function(int value)? format` pour afficher `7 h 00` ou `3 h 00` au lieu d'un entier. La carte est un widget `BottleScheduleSettingsSection` (`lib/features/baby/presentation/widgets/`), avec la même copie locale optimiste que `CareSettingsSection` et `SleepSettingsSection`. Le stepper « Biberons par jour » est retiré de `CareSettingsSection`.

## Données

`CareSettings` gagne trois champs, en minutes depuis minuit ou en minutes :

- `firstBottleMinutes` (défaut 420)
- `lastBottleMinutes` (défaut 1410)
- `bottleIntervalMinutes` (défaut 180)

avec leurs bornes et leur pas (15) en constantes statiques. `feedsPerDay` sort de l'entité ; `CareSettingsDto` ne l'écrit plus et l'ignore à la lecture. Les trois champs sont lus avec `_readBoundedInt` : une valeur absente retombe sur le défaut, une valeur hors bornes est ramenée à la borne. Un foyer existant démarre donc sur 7 h 00 / 23 h 30 / 3 h 00.

`CareSettings` expose `BottleSchedule get bottleSchedule`, construit depuis ces trois champs ; les consommateurs lisent `bottleSchedule.feedsPerDay`.

Modifier les réglages passe par `babySettingsControllerProvider.updateCareSettings`, qui déclenche déjà `feedingPlanSyncProvider`.

## Règle de calcul

Value object pur `BottleSchedule` (`lib/features/baby/domain/entities/bottle_schedule.dart`, à côté de `CareSettings` pour ne pas faire dépendre `baby` de `dashboard`), champs `firstBottle`, `lastBottle`, `interval` en `Duration`, défauts 7 h / 23 h 30 / 3 h.

### Constantes

- `halfWindow = 30 min` : la fourchette va de 30 min avant l'heure prévue à 30 min après.

### `DateTime nextAfter(DateTime last)`

Soit `prévu = last + interval`, `soir = jour de last à lastBottle`, `débutSoir = soir − halfWindow`, `matin = première occurrence de firstBottle strictement après last`, `débutMatin = matin − halfWindow`.

1. **Biberon de journée** : `last` est dans `[jour de last à firstBottle − halfWindow, débutSoir[`. Le suivant est `prévu`, rabattu sur `soir` s'il le dépasse.
2. **Biberon du soir ou de nuit** : sinon. Le suivant est `matin`, sauf si `prévu` est plus tard (biberon à 6 h 00 → 9 h 00).

Exemples (7 h 00 / 23 h 30 / 3 h) : 10 h → 13 h ; 22 h → 23 h 30 ; 22 h 45 → 23 h 30 ; 23 h 10 → 7 h ; 0 h 30 → 7 h ; 5 h → 8 h ; 6 h 40 → 9 h 40.

Les heures sont construites en heure locale par `DateTime(y, m, d, 0, minutes)`.

### `(DateTime, DateTime) windowAround(DateTime at)`

`(at − halfWindow, at + halfWindow)`.

### `int get feedsPerDay`

`1 + ⌈(lastBottle − firstBottle) ÷ interval⌉`, au moins 1. 7 h 00 → 23 h 30 toutes les 3 h : 1 + ⌈5,5⌉ = 7.

## Plan du jour (`ComputeFeedingPlan`)

- Reçoit un `BottleSchedule` à la place de `feedsPerDay`.
- Avec un dernier biberon : `nextBottleAt = schedule.nextAfter(lastBottle.startAt)`, fourchette `schedule.windowAround(nextBottleAt)`.
- Sans biberon enregistré : inchangé (`now`, fourchette vide).
- `feedsPerDay` du plan = `schedule.feedsPerDay` ; répartition des ml inchangée.
- Suppression de `intervalFor`, `minGap`, `maxGap`, `windowAfter`.

`dashboard_providers.dart` et `feeding_plan_sync.dart` construisent le `BottleSchedule` depuis `profile.careSettings`.

## Projection « Prochaines 24 h » (`ProjectBottleSchedule`)

Le premier biberon projeté reste celui du plan. Les suivants enchaînent `schedule.nextAfter` à partir de `max(plan.nextBottleAt, now)`, chacun supposé donné à son heure prévue, tant qu'ils tombent dans les 24 h. Chaque fourchette vaut `windowAround(at)`. Exemple : 7 h, 10 h, 13 h, 16 h, 19 h, 22 h, 23 h 30, 7 h.

Cela remplace l'hypothèse « au plus tôt » (chaque fourchette partait du début de la précédente), qui avec une fourchette de ± 30 min avancerait chaque biberon de 30 min.

La cible de demain reste répartie sur `feedsPerDay`, désormais déduit.

## Rappel push

Cloud Functions inchangées. `bottleReminder` notifie à l'ouverture de la fourchette du snapshot, soit 30 min avant l'heure prévue (« Biberon possible dès maintenant, d'ici 10 h 30 »), validé par Maxence. La nuit, la fourchette suivante est celle du matin : aucun rappel entre le biberon du soir et 6 h 30.

`functions/src/lib/types.ts` continue de lire `feedsPerDay` avec son défaut ; ce champ n'est plus écrit et n'est utilisé par aucune fonction.

## Libellés (`app_fr.arb`)

- `settingsBottlesSection` : « Biberons » (titre de section, comme `settingsSleepSection`)
- `settingsFirstBottle` : « Premier biberon »
- `settingsLastBottle` : « Biberon du soir »
- `settingsBottleInterval` : « Intervalle »
- `settingsFeedsPerDaySummary` : « ≈ {count} biberons par jour » (pluriel ICU)
- Valeurs des trois lignes : clé existante `durationHoursMinutes` (« {hours} h {minutes} »), minutes sur deux chiffres formatées côté widget.

`settingsFeedsPerDay` est supprimé (seul usage : `CareSettingsSection`).

## Tests (TDD)

- `bottle_schedule_test.dart` : chaque exemple de la règle, rabattement du soir, nuit après minuit, biberon tôt le matin, `windowAround`, `feedsPerDay` (dont intervalle qui divise exactement la plage).
- `compute_feeding_plan_test.dart` et `project_bottle_schedule_test.dart` réécrits sur `BottleSchedule`.
- DTO : aller-retour des trois champs, bornes, ancien `feedsPerDay` ignoré, défauts sur document vide.
- `bottle_schedule_settings_section_test.dart` : affichage formaté, −/+ par 15 min, bornes désactivant les boutons, appel de `updateCareSettings`, résumé mis à jour.
- `care_settings_section_test.dart` : plus de stepper « Biberons par jour ».
- Vérification finale : `dart format lib test`, `dart analyze`, `flutter test`, puis carte Réglages en clair et en sombre sur simulateur.
