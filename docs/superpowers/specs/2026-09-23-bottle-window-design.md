# Fourchette du prochain biberon et timeline 24 h — design

Date : 2026-09-23. Branche : `feat/bottle-window`.

## Pourquoi

Les recommandations pédiatriques (HAS, AAP) préconisent une alimentation du nouveau-né guidée par ses signes de faim, avec un repère d'environ 2 h 30 à 3 h 30 entre deux prises. Une heure précise (« vers 8h10 ») suggère un horaire strict et affiche « en retard » dès la première minute. Une fourchette (« entre 7h45 et 8h35 ») reflète mieux la pratique. Les parents veulent aussi voir d'un coup d'œil les biberons prévus sur les 24 prochaines heures.

## Règles

### Fourchette

- Intervalle : `I = round(24 × 60 / feedsPerDay)` minutes (inchangé).
- Heure centrale : `nextBottleAt = dernierBiberon.startAt + I` (inchangé).
- Bornes (révision du 2026-09-23, à la demande de Maxence) : fenêtre de tir fixe `windowStart = dernierBiberon.startAt + 2 h 30`, `windowEnd = dernierBiberon.startAt + 5 h`, quel que soit le rythme. L'ancienne règle « ±15 % de l'intervalle, arrondie aux 5 min » est abandonnée.
- Aucun biberon enregistré : `windowStart = windowEnd = nextBottleAt = now`.

Exemple : dernier biberon à 5h10 → fenêtre **7h40 – 10h10**.

### Carte « Prochain biberon »

| Situation | Texte |
|---|---|
| `now < windowStart` | « entre 7h45 et 8h35 » |
| `windowStart ≤ now ≤ windowEnd`, bornes distinctes | « Go pour un biberon, jusqu'à 10h10 » (couleur `success`) |
| `windowStart = windowEnd` (aucun biberon) | « maintenant » |
| `now > windowEnd` | « en retard de N min », N compté depuis `windowEnd` (couleur `warning`) |

Sous la quantité, une ligne « 2 h 50 depuis le dernier biberon » (`formatDuration` partagé, absente sans biberon connu).

Un bouton horloge (`Icons.schedule`, infobulle « Prochaines 24 h ») s'ajoute à gauche du bouton ⓘ dans l'en-tête de la carte et ouvre la feuille timeline.

### Timeline « Prochaines 24 h »

Bottom sheet (`showModalBottomSheet`, même gabarit que la feuille OMS) :

- Titre « Prochaines 24 h », rappel « Prévisions indicatives : suis aussi ses signes de faim. »
- Une ligne par biberon prévu : fourchette « 7h45 – 8h35 » et quantité « 120 ml ».
- En-têtes de jour « Aujourd'hui » / « Demain », selon le jour civil de `max(heure centrale, now)`.
- Première ligne = le prochain biberon du plan (même fourchette, même quantité que la carte). S'il est en cours ou en retard, la ligne porte la mention de la carte (« maintenant » en `primary`, « en retard de N min » en `warning`).
- Biberons suivants : `ancre = max(nextBottleAt, now)`, puis centres `ancre + k × I` (k = 1, 2, …) tant que le centre est `< now + 24 h`. Chaque fourchette est calculée depuis le biberon précédent (`centre − I`) selon la règle ci-dessus. Un retard décale donc toute la suite.
- **Révision du 2026-09-25** (à la demande de Maxence) : la projection suppose chaque biberon donné au plus tôt. `ancre = max(windowStart, now)` ; la fourchette suivante vaut `ancre + 2 h 30 – ancre + 5 h`, puis chacune part du début de la précédente, tant que son début est `< now + 24 h`. L'intervalle `I` n'intervient plus dans la projection (seulement dans la quantité de demain, `cibleDemain / feedsPerDay`). L'ancienne règle faisait partir les fourchettes d'un centre invisible (`précédent + I`), décalé de la fourchette affichée, et les faisait se chevaucher dès 10 prises par jour.
- Quantités : un centre le même jour civil que `now` reprend `plan.suggestedMl` (reste du jour réparti). Un centre le lendemain prend `arrondi10(cibleDemain / feedsPerDay)` borné à 30–240 ml, où `cibleDemain` = cible ajustée si elle existe, sinon cible OMS au poids (dernière pesée) ou à l'âge, calculée pour le jour de vie de demain.

### Rappel push (Cloud Function `bottleReminder`)

- Le snapshot `households/{code}.feedingPlan` gagne `windowStartAt` et `windowEndAt` (`Timestamp`).
- Avec ces champs : rappel dû si `windowStartAt ≤ now ≤ windowEndAt`, `lastBottleNotifiedFor ≠ nextBottleAt` et `computedAt < windowStartAt`. Titre « Biberon possible dès maintenant », texte « Environ {suggestedMl} ml, d'ici {windowEnd} ».
- Sans ces champs (l'autre téléphone n'est pas encore à jour) : règle actuelle inchangée (10 min avant `nextBottleAt`, tolérance 15 min, texte actuel).
- `lastBottleNotifiedFor` reste la clé de dédoublonnage (`nextBottleAt`).

## Architecture

- `dashboard/domain`
  - `FeedingPlan` : champs `windowStart`, `windowEnd` ; `lateBy(now)` se base sur `windowEnd` ; `isOpen(now)` vrai dans la fenêtre.
  - `ComputeFeedingPlan` : calcule la fourchette ; helpers statiques `intervalFor(feedsPerDay)`, `windowAfter(lastBottleAt)` (record `(DateTime, DateTime)`, constantes `minGap` / `maxGap`), `dailyTargetFor(...)` pour factoriser la cible OMS.
  - Nouvelle entité `ProjectedBottle` (freezed : `at`, `windowStart`, `windowEnd`, `suggestedMl`).
  - Nouveau use case pur `ProjectBottleSchedule` : `(plan, birthDate, latestWeightGrams, dailyTargetMlOverride, now) → List<ProjectedBottle>`.
- `baby/domain` : `FeedingPlanSnapshot` gagne `windowStartAt`, `windowEndAt` ; `FirestoreBabyRepository.saveFeedingPlan` les écrit en `Timestamp` ; `FirestoreFeedingPlanSync` les renseigne.
- `dashboard/presentation`
  - `bottleScheduleProvider` (`@riverpod`, `null` sans plan).
  - `NextBottleCard` : `_WhenText` réécrit, bouton timeline.
  - Nouveau `bottle_schedule_sheet.dart` : `showBottleScheduleSheet`, `BottleScheduleSheet`, `ListView.builder` sur des entrées aplaties (en-têtes + lignes).
- `functions/src` : `FeedingPlanDoc` (champs optionnels), `isReminderDue` (branche fourchette + repli), `bottle-reminder.ts` (texte selon la branche).
- l10n : `nextBottleWindow`, `nextBottleNowUntil`, `bottleScheduleTooltip`, `bottleScheduleTitle`, `bottleScheduleHint`, `bottleScheduleRange`, `dayTomorrow` (à côté de `dayToday` existante) ; `nextBottleAt` supprimée.

## Tests

- Domaine : fourchette (arrondi aux 5 min, 2 h / 3 h / 4 h, aucun biberon), `lateBy` depuis `windowEnd`, projection (nombre de lignes, passage de minuit et cible de demain, retard qui décale, cible ajustée, bornes 30–240).
- Data : `saveFeedingPlan` écrit les deux nouveaux `Timestamp` ; `feeding_plan_sync_test` vérifie les bornes.
- Présentation : quatre états de la carte, ouverture de la feuille depuis le bouton, en-têtes Aujourd'hui/Demain, mention retard sur la première ligne.
- Cloud Functions : `reminder.test.ts` (branche fourchette : avant, début, fin, après, dédoublonnage, `computedAt ≥ windowStartAt` ; repli sans champs), `bottle-reminder.test.ts` (texte et dédoublonnage avec fourchette).

## Hors périmètre

- Fourchette réglable par l'utilisateur.
- Affichage des biberons passés dans la timeline.
- Déplacement du rappel quand le snapshot est périmé la nuit (reliquat connu).
