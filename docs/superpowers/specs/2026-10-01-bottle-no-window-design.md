# Biberons sans fourchette — design

Date : 2026-10-01
Branche : `feat/bottle-no-window`
Précédent : `2026-09-30-bottle-schedule-design.md`

## Objectif

Supprimer la fourchette de ± 30 min autour du prochain biberon. Le premier biberon du matin est à l'heure réglée, puis chaque biberon est prévu à l'heure de début du dernier biberon réel plus l'intervalle réglé. L'app annonce une heure (« à 10h00 »), plus une plage.

## Choix de Maxence (2026-10-01)

- Pause de nuit conservée : rien n'est prévu après le biberon du soir, le suivant est le premier du matin à l'heure réglée. Les règles « rabattre sur le soir » et « écart minimum » restent.
- Rappel push 10 min avant l'heure prévue ; « en retard » dès l'heure prévue dépassée.
- Approche : la notion de fourchette disparaît du code, pas seulement de l'écran.

## Règle (`BottleSchedule`)

Inchangée, sauf :

- `halfWindow` devient `margin` (30 min) : marge interne de classement, jamais affichée. Un biberon donné jusqu'à 30 min avant le premier du matin compte comme celui du matin ; un biberon donné à moins de 30 min du soir compte comme celui du soir. `upcomingMorning` bascule sur le lendemain à `soir − margin`.
- `nextDue` : un biberon manqué reste dû (donc « en retard ») jusqu'à `prévu + margin`, puis bascule sur le premier du matin si la soirée est entamée ou passée. Inchangé hormis le nom.
- `windowAround` est supprimé.

## Plan du jour et projection

- `FeedingPlan` perd `windowStart`, `windowEnd`, `hasWindow`, `isOpen`. `nextBottleAt` reste ; sans biberon enregistré il vaut `now`.
- Retard : `FeedingPlan.latenessAt(at, now)` (statique) vaut `now − at` s'il atteint 1 min, sinon zéro (évite « en retard de 0 min » quand l'heure prévue porte des secondes). `plan.lateBy(now)` l'applique à `nextBottleAt`.
- `ProjectedBottle` perd `windowStart` / `windowEnd` : `at` et `suggestedMl`. La projection enchaîne toujours `schedule.nextAfter` depuis `max(nextBottleAt, now)`.

## Affichage

Carte « Prochain biberon », à la place de la fourchette :

| Situation | Texte |
|---|---|
| retard ≥ 1 min | « en retard de 25 min » (orange, inchangé) |
| heure prévue atteinte, ou aucun biberon | « maintenant » |
| heure prévue un autre jour que `now` | « demain à 07h00 » |
| sinon | « à 12h10 » |

L'état vert « Go pour un biberon, jusqu'à … » disparaît.

Feuille « Prochaines 24 h » : chaque ligne affiche l'heure (« 13h00 ») ; la mention du prochain biberon suit la même règle (retard, « maintenant », sinon rien).

Clés l10n : ajout `nextBottleAtTime` (« à {time} ») et `nextBottleAtTimeTomorrow` (« demain à {time} ») ; retrait de `nextBottleWindow`, `nextBottleWindowTomorrow`, `nextBottleGo`, `bottleScheduleRange`.

## Snapshot Firestore et rappels

- `FeedingPlanSnapshot` perd `windowStartAt`, `windowEndAt`, `morningWindowStartAt`, `morningWindowEndAt` ; il garde `nextBottleAt`, `suggestedMl`, `computedAt`, `morningBottleAt`.
- `saveFeedingPlan` écrit explicitement `null` dans les quatre champs de fourchette (écriture `merge` : sinon les valeurs d'une version précédente resteraient).
- Cloud Function `bottleReminder` : sans fourchette, `isReminderDue` utilise déjà le rappel 10 min avant (`REMINDER_LEAD_MS`), tolérance 15 min, message « Biberon dans 10 min · Environ X ml, prévu vers HH:MM ». Aucun changement pour le rappel principal.
- `deadlinesOf` : le rappel de secours du matin n'exige plus que `morningBottleAt` (toujours strictement après `nextBottleAt`) ; ses fourchettes sont reprises si présentes (ancienne version de l'app), sinon `null`.
- Compatibilité : une app d'ancienne version continue d'écrire ses fourchettes, la fonction les utilise ; la dernière écriture l'emporte. La fonction peut être déployée avant ou après l'installation de l'app.

## Hors périmètre

`feedsPerDay` mort dans `functions/src/lib/types.ts`, biberons de nuit comptés dans le jour, ml du rappel du matin tirés de la veille.

## Tests

- Domaine : `bottle_schedule_test` (sans `windowAround`), `compute_feeding_plan_test` (retard depuis l'heure prévue), `project_bottle_schedule_test`.
- Données : `firestore_baby_repository_test` (fourchettes écrites à `null`), `feeding_plan_sync_test`.
- Présentation : `dashboard_page_test` (textes de la carte), `bottle_schedule_sheet_test`.
- Functions : `bottle-reminder.test.ts` (rappel du matin sans fourchette).
