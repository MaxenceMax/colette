# Horaires des biberons choisis — design

Date : 2026-10-07
Branche : `feat/bottle-custom-times`
Précédents : `2026-09-30-bottle-schedule-design.md`, `2026-10-01-bottle-no-window-design.md`

## Objectif

Le parent choisit le nombre de biberons par jour, puis l'heure de chacun : 5 biberons, 5 heures. Ces horaires forment une grille fixe qui remplace le rythme actuel (premier biberon, biberon du soir, intervalle, nombre déduit).

## Choix de Maxence (2026-10-07)

- Grille fixe : un biberon donné en retard ne décale pas les suivants. Horaire 10h30 donné à 11h15 : le suivant reste à 14h.
- Rattachement à l'horaire le plus proche : un biberon donné à 12h45 entre 10h30 et 14h compte pour 14h, le suivant est 17h30 ; donné avant 12h15 (milieu), il compte pour 10h30 et le suivant est 14h.
- Changer le nombre garde les horaires saisis : +1 insère un horaire au milieu du plus grand écart de journée, −1 retire le dernier.
- Rappel push 10 min avant chaque horaire, même si aucun biberon n'est enregistré entre-temps.

## Règle (`BottleSchedule`, `baby/domain`)

`BottleSchedule` ne porte plus que `times` : liste triée de `Duration` depuis minuit, au moins 1, écarts d'au moins 30 min (y compris entre le dernier et le premier du lendemain). Ses méthodes publiques gardent leur nom, les consommateurs changent peu.

Les horaires se déroulent en créneaux datés sur plusieurs jours (`… 23h30 la veille, 07h00, 10h30, …, 23h30, 07h00 le lendemain …`).

- `slotOf(at)` : créneau le plus proche de `at`. Au milieu exact de deux créneaux, le plus tardif.
- `nextAfter(last)` : créneau qui suit `slotOf(last)`.
- `nextDue(last, now)` : le plus tardif de `nextAfter(last)` et `slotOf(now)`. Un horaire sauté reste dû (« en retard ») jusqu'au milieu de l'écart avec le suivant, puis le suivant devient dû. La nuit n'a plus de règle propre : à 3h, entre 23h30 et 7h, `slotOf` vaut 23h30 (déjà donné) et le prochain dû est 7h ; aucun retard n'est compté.
- `morningAfter(at)` : premier horaire de la liste (`times.first`) strictement après `at`. Garde pour `morningBottleAt` (rétrocompatibilité des Functions).
- `feedsPerDay` : `times.length`.
- `BottleSchedule.fromLegacy(first, last, interval)` : grille tirée des trois anciens réglages, par la règle d'avant. Chaîne `first, first + interval, …` tant qu'elle reste avant `last` ; le soir s'ajoute si le dernier créneau en est à au moins un demi-intervalle, sinon il le remplace. 7h / 23h30 / 3h donne 07h00, 10h00, 13h00, 16h00, 19h00, 22h00, 23h30 (7 biberons, comme aujourd'hui).

Supprimés : `margin`, `upcomingMorning`, la règle « rabattre sur le soir », la bascule de nuit.

`ComputeFeedingPlan` et `ProjectBottleSchedule` ne changent pas de logique : ils appellent `nextDue` et `nextAfter`. La projection donne donc les horaires de la grille des 24 prochaines heures. Retard, « maintenant », « demain à » : inchangés.

## Réglages

### Entité

`CareSettings` remplace `firstBottleMinutes`, `lastBottleMinutes`, `bottleIntervalMinutes` par `bottleTimesMinutes` (`List<int>`, minutes depuis minuit), par défaut `[420, 600, 780, 960, 1140, 1320, 1410]`. `bottleSchedule` construit la grille depuis cette liste.

Constantes : `minBottlesPerDay = 3`, `maxBottlesPerDay = 12`, `bottleTimeStepMinutes = 5`, `minBottleGapMinutes = 30`. Les anciennes bornes (`min/maxFirstBottleMinutes`, etc.) disparaissent.

Modifications pures, testées en domaine :

- `withBottleCount(int count)` : vers le haut, insère à chaque pas le milieu (arrondi au pas de 5 min inférieur) du plus grand écart entre deux horaires consécutifs de la journée, sans compter l'écart de nuit (dernier → premier). Vers le bas, retire les derniers. Bornée à 3–12.
- `canAddBottle` : faux à 12 biberons, ou si aucun écart de journée n'atteint 60 min (le milieu serait à moins de 30 min d'un voisin).
- `withBottleTime(int index, int minutes)` : remplace un horaire et retrie. Renvoie `null` si le nouvel horaire est à moins de 30 min d'un autre (écart circulaire sur 24 h).

### Carte « Biberons »

- `IntStepperRow` « Biberons par jour » (3–12). Le + est désactivé si `canAddBottle` est faux.
- Une ligne par horaire, dans l'ordre : « 1er biberon », « 2e biberon », … et l'heure à droite (« 07h00 »). Un appui ouvre `showColetteDateTimePicker` en mode heure, par pas de 5 min. Le sélecteur partagé reçoit un paramètre optionnel `minuteInterval`, et l'heure initiale est arrondie à ce pas comme l'exige `CupertinoDatePicker`.
- Horaire refusé (à moins de 30 min d'un autre) : rien n'est écrit, une SnackBar explique « Deux biberons doivent être espacés d'au moins 30 min ».
- Liste construite avec `Column` (12 lignes au plus, dans une page déjà défilante). Copie locale optimiste et fusion dans le profil frais (`_update`) conservées. Le résumé « ≈ N biberons par jour » disparaît : le compteur l'affiche.
- Pour rester sous 300 lignes, la ligne d'horaire est un widget dédié (`bottle_time_row.dart`).

Clés l10n : ajout de `settingsBottlesPerDay` (« Biberons par jour »), `settingsBottleNth` (`{n, plural, =1{1er biberon} other{{n}e biberon}}`), `settingsBottleTimeTooClose`. Retrait de `settingsFirstBottle`, `settingsLastBottle`, `settingsBottleInterval`, `settingsFeedsPerDaySummary`.

## Données

### `careSettings` (DTO du profil)

- Écrit `bottleTimesMinutes`. N'écrit plus les trois anciens champs, mais ne les supprime pas : une ancienne version de l'app sur l'autre iPhone continue de lire les derniers écrits.
- Lecture, dans l'ordre :
  1. `bottleTimesMinutes` valide : chaque valeur entière dans 0–1439, 3 à 12 valeurs, écarts circulaires ≥ 30 min après tri. Valeurs triées.
  2. Sinon, les trois anciens champs (bornés comme aujourd'hui), convertis par `fromLegacy`.
  3. Sinon, la grille par défaut.

### Snapshot `feedingPlan`

`FeedingPlanSnapshot` gagne `upcomingBottles` : liste de `{at, suggestedMl}`, les biberons de `ProjectBottleSchedule` (24 h depuis `now`), en `Timestamp`. `nextBottleAt`, `suggestedMl`, `computedAt`, `morningBottleAt` restent écrits pour la version déployée de `bottleReminder`.

`FeedingPlanSync` calcule la projection en plus du plan. L'écriture reste en `merge`, best-effort.

## Rappels (`bottleReminder`)

- `FeedingPlanDoc` gagne `upcomingBottles?: { at: Timestamp; suggestedMl: number }[]`.
- Avec `upcomingBottles` : les échéances sont ses créneaux, triés. Le premier créneau dû par `isReminderDue` (10 min avant, tolérance 15 min, `computedAt` antérieur à l'échéance) est rappelé, avec ses ml. Le message reste « Biberon dans 10 min · Environ X ml, prévu vers HH:MM ».
- Pas de doublon : un créneau est ignoré si `lastBottleNotifiedFor` lui est égal **ou postérieur** (on ne revient pas sur un créneau plus ancien que le dernier rappelé). `lastBottleNotifiedFor` reçoit le créneau rappelé.
- Sans `upcomingBottles` (ancienne version de l'app) : `deadlinesOf` actuel (prochain biberon + secours du matin), inchangé.
- Un biberon enregistré réécrit la liste : un horaire déjà donné en avance n'est plus rappelé. Si personne n'ouvre l'app pendant 24 h, la liste s'épuise ; acceptable.
- Ordre de déploiement libre : l'ancienne fonction ignore `upcomingBottles` et lit `nextBottleAt` ; la nouvelle lit `upcomingBottles` s'il est là.

## Hors périmètre

Horaires différents selon les jours, ml par horaire choisis à la main, `feedsPerDay` mort dans `functions/src/lib/types.ts`, accessibilité VoiceOver des steppers.

## Tests

- Domaine : `bottle_schedule_test` réécrit (`slotOf` dont égalité au milieu, `nextAfter` dont passage de minuit, `nextDue` dont horaire sauté puis bascule au milieu, nuit sans retard, `fromLegacy` dont cas « remplace le soir ») ; `care_settings_test` (`withBottleCount` haut/bas/bornes, `canAddBottle`, `withBottleTime` tri et refus circulaire) ; `compute_feeding_plan_test` et `project_bottle_schedule_test` adaptés à la grille.
- Données : DTO du profil (lecture nouvelle liste, liste invalide → anciens champs, anciens champs → `fromLegacy`, rien → défaut, écriture sans anciens champs) ; `firestore_baby_repository_test` et `feeding_plan_sync_test` (`upcomingBottles` écrit).
- Présentation : `bottle_schedule_settings_section_test` (compteur, ligne ouverte → sélecteur, horaire refusé → SnackBar sans écriture, + désactivé) ; `dashboard_page_test` inchangé hors données.
- Functions : `bottle-reminder.test.ts` (un rappel par créneau, pas de doublon ni de retour en arrière, ml du créneau, repli sans `upcomingBottles`), `types.test.ts`.

## Livraison

Worktree `.claude/worktrees/bottle-custom-times` depuis `main` 9c5184b, fusion `--no-ff` validée par Maxence. Ensuite : installer l'app sur les deux iPhones, redéployer `bottleReminder` (dans n'importe quel ordre).
