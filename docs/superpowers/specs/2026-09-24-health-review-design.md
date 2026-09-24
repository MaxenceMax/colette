# Revue de l'onglet Santé et tuile Rendez-vous sur Aujourd'hui

Date : 2026-09-24. Base : `main` (`d40c71e`). Complète la spec `2026-09-23-custom-appointments-design.md`, dont la décision « la carte Santé ne revient pas » est annulée par cette spec.

## 1. Objectif

Décisions prises le 2026-09-24 avec Maxence :

1. Les rendez-vous **programmés** sont mis en avant sur l'onglet Santé : le prochain en carte accentuée en tête de page, les autres en liste datée juste dessous.
2. Ce qui reste **à programmer** (étapes en retard ou à faire) est rétrogradé en lignes compactes et discrètes ; les étapes à venir sont repliées.
3. Une tuile **Rendez-vous** revient sur l'onglet Aujourd'hui. Elle est toujours affichée, montre le prochain RDV programmé avec une emphase qui monte à mesure que la date approche, et indique « Pas de rendez-vous programmé » sinon.

## 2. Domaine (`lib/features/health/domain`)

Aucune nouvelle entité persistée. Ajouts purs, sans Flutter ni Firebase.

### 2.1 `MedicalTimelineItem`

- `DateTime? get appointmentAt` : `visit?.appointmentAt` pour un `StageItem`, `appointment.appointmentAt` pour un `AppointmentItem`.
- `String? get practitioner` : `visit?.practitioner` ou `appointment.practitioner`, `null` si vide après `trim()`.

### 2.2 `MedicalTimeline`

Getters calculés sur `items` :

| Getter | Contenu |
| --- | --- |
| `scheduled` | Éléments de statut `scheduled`, triés par `appointmentAt` croissant puis, à date égale, dans l'ordre de `items`. |
| `nextAppointment` | `scheduled.firstOrNull`. |
| `awaitingConfirmation` | Éléments de statut `appointmentPassed`, triés par `appointmentAt` croissant. |
| `toSchedule` | Éléments de statut `late` puis `due`, chacun dans l'ordre de `items` (les retards d'abord). |
| `upcoming` | Éléments de statut `upcoming`, ordre de `items`. |
| `done` | Éléments de statut `done`, ordre de `items`. |

`next` (premier non fait) est conservé : il reste utilisé par le snapshot du digest.

### 2.3 `AppointmentProximity` et `ComputeAppointmentProximity`

```dart
/// Distance d'un RDV programmé au jour courant, pour graduer son emphase.
enum AppointmentProximity { today, tomorrow, soon, later }
```

`ComputeAppointmentProximity` (`const`, `call({required DateTime appointmentAt, required DateTime today})`) compare les jours calendaires via `calendarDaysBetween(today, appointmentAt.dateOnly)` :

| Écart en jours | Résultat |
| --- | --- |
| 0 | `today` |
| 1 | `tomorrow` |
| 2 à 7 inclus | `soon` |
| 8 et plus | `later` |

`static const soonDays = 7`. Un écart négatif (RDV passé) n'arrive pas : les RDV passés ont le statut `appointmentPassed` et ne passent pas par ce calcul. Par sûreté, un écart négatif renvoie `today`.

## 3. Présentation (`lib/features/health/presentation`)

### 3.1 Providers

- `medicalTimelineProvider` inchangé.
- Nouveau `@riverpod AppointmentProximity? nextAppointmentProximity(Ref ref)` : `null` sans frise ou sans `nextAppointment`, sinon le résultat de `ComputeAppointmentProximity` avec `todayProvider`. Recalculé chaque minute par `currentMinuteProvider` via `todayProvider`.

### 3.2 Onglet Santé (`HealthPage`)

Ordre des blocs, de haut en bas. Chaque bloc est un widget privé ou un fichier de `widgets/` ; `health_page.dart` reste sous 200 lignes.

1. **Alerte calendrier** (`_CalendarStatus`, existant) : affichée en haut **seulement** s'il y a un `calendarSyncIssueProvider` non nul (icône `sync_problem`, couleur `warning`). Sinon rien ici.
2. **Prochain rendez-vous** (`NextAppointmentCard`, `widgets/next_appointment_card.dart`) : en-tête `overline` « Prochain rendez-vous » en `primary`, puis `ColetteCardSurface` avec `backgroundColor: AppColors.primaryContainer`, `borderColor: AppColors.primaryContainer`.
   - Ligne 1, style `heading2`, couleur `primary` : la date. Texte selon la proximité : `today` → « Aujourd'hui à 10:30 », `tomorrow` → « Demain à 10:30 », sinon `formatDayAndTime` (« jeu. 2 oct. · 10:30 »).
   - Ligne 2, `bodyMedium` : libellé de l'étape (`HealthLabels.stage`) ou titre du RDV libre.
   - Ligne 3, `small` `textSecondary`, facultative : praticien et compte à rebours joints par « · » ; le compte à rebours n'apparaît que pour `soon` (« dans 3 jours ») et `later` (« dans 12 jours »).
   - Ligne 4 : pastilles `MedicalChip` (Examen / Vaccins / Certificat pour une étape, RDV libre / Vaccins pour un RDV libre).
   - Tap : `showMedicalStageSheet` ou `showCustomAppointmentSheet` selon l'élément.
   - Sans `nextAppointment` : même carte en `surface` / `border`, icône `event_busy_outlined` `textSecondary` et texte `body` `textSecondary` « Pas de rendez-vous programmé », sans tap.
3. **Aussi programmés** (`ScheduledSection`, `widgets/scheduled_section.dart`) : `SectionHeader` « Aussi programmés » puis `ColetteCardSurface` contenant une `DatedAppointmentTile` par élément de `scheduled` sauf le premier. Section absente si `scheduled.length < 2`.
   - `DatedAppointmentTile` (`widgets/dated_appointment_tile.dart`) : `ListTile` dont le `leading` est un bloc date (jour du mois en `numberMedium`, mois abrégé en `small` `textSecondary`, via deux nouveaux helpers `formatDayOfMonth` et `formatShortMonth` dans `core/dates/time_format.dart`), `title` = libellé, `subtitle` = heure (`formatHourMinute`) puis praticien ou pastille « RDV libre » sur la même ligne joints par « · », `trailing` chevron. Tap : feuille correspondante.
4. **RDV passé, à confirmer** (`AwaitingConfirmationSection`) : `SectionHeader` « RDV passé, à confirmer » ; `ColetteCardSurface` avec `borderColor: AppColors.warning`, contenant les tuiles existantes (`MedicalStageTile` / `CustomAppointmentTile`) pour `awaitingConfirmation`. Absente si vide. Le texte de statut existant (« RDV du 18 sept. passé · à marquer comme faite ») est rendu en `warning` par les deux tuiles pour ce statut (aujourd'hui seule `MedicalStageTile` colore, et seulement `late`).
5. **À programmer** (`ToScheduleSection`, `widgets/to_schedule_section.dart`) : `SectionHeader` « À programmer » puis une liste de `CompactStageRow` **sans** `ColetteCardSurface` ni pastilles : une ligne par élément de `toSchedule`, `dense`, libellé en `body` `textSecondary` à gauche, à droite un texte `small` : « en retard » en `warning` pour `late`, la fenêtre courte « du 5 au 30 nov. » en `textSecondary` pour `due`. Pas de chevron. Tap : feuille d'étape. Séparateur `Divider` (couleur `border`) entre les lignes. Absente si vide.
6. **À venir (n)** : `ExpansionTile` replié par défaut, même construction que `_DoneSection` actuelle, contenant les `MedicalStageTile` de `upcoming`. Absente si vide.
7. **Faites (n)** : inchangé.
8. **Pied calendrier** : la ligne « Synchronisé avec … » ou « RDV non ajoutés au Calendrier (à régler dans Réglages) » en `small` `textSecondary`, en bas de page, uniquement quand il n'y a pas de problème de sync (sinon l'alerte du haut suffit).

Bouton « + » de l'`AppBar` et écoute des contrôleurs inchangés.

### 3.3 Tuile Rendez-vous sur Aujourd'hui (`AppointmentCard`)

Fichier `lib/features/health/presentation/widgets/appointment_card.dart`, importé par `DashboardPage` entre `SleepCard` et le `SectionHeader` « Reste à faire » (consommation d'un widget de `presentation/` d'une autre feature, conforme aux règles). Toujours rendue ; si `medicalTimelineProvider` est `null` (pas de profil, flux non lus), elle affiche l'état « Pas de rendez-vous programmé ».

Tap : `context.go(AppRoutes.health)` dans tous les états.

Élément affiché : `awaitingConfirmation.firstOrNull` s'il existe, sinon `nextAppointment`. Cinq états, du plus discret au plus fort :

| État | Condition | Fond / bordure | Icône | En-tête (`overline`) | Corps |
| --- | --- | --- | --- | --- | --- |
| Aucun | pas d'élément | `surface` / `border` | `event_busy_outlined` `textSecondary` | « Rendez-vous » `textSecondary` | `body` `textSecondary` « Pas de rendez-vous programmé » |
| Éloigné | `later` | `surface` / `border` | `event_outlined` `textSecondary` | « Rendez-vous » `textSecondary` | libellé `bodyMedium` ; ligne `small` `textSecondary` date `formatDayAndTime` + praticien |
| Bientôt | `soon` | `surface` / `primary` | `event_outlined` `primary` | « Rendez-vous dans N jours » `primary` | idem Éloigné |
| Imminent | `today` ou `tomorrow` | `primaryContainer` / `primaryContainer` | `event_outlined` `primary` | « Rendez-vous » `primary` | ligne `heading2` `primary` « Aujourd'hui à 10:30 » / « Demain à 10:30 », puis libellé `bodyMedium`, puis praticien `small` `textSecondary` s'il existe |
| À confirmer | élément de `awaitingConfirmation` | `surface` / `warning` | `event_busy_outlined` `warning` | « RDV passé · à marquer comme faite » `warning` | libellé `bodyMedium` ; date `formatDayAndTime` `small` `textSecondary` |

Chevron `chevron_right` à droite dans tous les états, `textSecondary` (ou `primary` dans l'état Imminent). L'état À confirmer prime sur les quatre autres.

### 3.4 Textes (`app_fr.arb`)

Nouveaux :

| Clé | Valeur |
| --- | --- |
| `healthNextAppointment` | Prochain rendez-vous |
| `healthNoAppointment` | Pas de rendez-vous programmé |
| `healthSectionScheduled` | Aussi programmés |
| `healthSectionAwaiting` | RDV passé, à confirmer |
| `healthSectionToSchedule` | À programmer |
| `healthSectionUpcomingCount` | À venir ({count}) |
| `healthTodayAt` | Aujourd'hui à {time} |
| `healthTomorrowAt` | Demain à {time} |
| `healthInDays` | dans {count} jours (pluriel : `{count, plural, =1{dans 1 jour} other{dans {count} jours}}`) |
| `healthLateShort` | en retard |
| `healthDueWindowShort` | du {from} au {to} |
| `dashboardAppointmentTitle` | Rendez-vous |
| `dashboardAppointmentSoon` | Rendez-vous dans {count} jours (même pluriel) |
| `dashboardAppointmentAwaiting` | RDV passé · à marquer comme faite |

Supprimés (plus utilisés) : `healthSectionToDo`, `healthSectionUpcoming` (remplacée par la version comptée), `healthNextFar`, `healthAllDone`.

## 4. Erreurs

Rien de nouveau : aucune écriture. Les erreurs des contrôleurs restent affichées par `HealthPage` via `ref.listen`.

## 5. Tests

- **Domaine** (purs) : `medical_timeline_test` pour `appointmentAt`, `practitioner`, `scheduled` (tri, mélange étape / RDV libre), `nextAppointment`, `awaitingConfirmation`, `toSchedule` (retards avant à faire), `upcoming`, `done`. `compute_appointment_proximity_test` pour les quatre bornes (0, 1, 2, 7, 8 jours, écart négatif).
- **Présentation** (`pumpApp`, `FixedClock`) :
  - `health_page_test` : carte « Prochain rendez-vous » avec date, libellé, praticien et compte à rebours ; état « Pas de rendez-vous programmé » ; section « Aussi programmés » absente avec un seul RDV, présente avec deux ; « RDV passé, à confirmer » ; « À programmer » avec un retard en `warning` et une étape à faire avec sa fenêtre, sans pastille ; « À venir (n) » repliée ; alerte calendrier en haut seulement en cas de problème, pied de page sinon ; tap sur la carte ouvre la bonne feuille.
  - `appointment_card_test` : six cas (aucun, éloigné, bientôt, imminent aujourd'hui, imminent demain, à confirmer), priorité de « à confirmer », tap navigue vers `/health`.
  - `dashboard_page_test` : la tuile est présente même sans frise.
  - `next_appointment_proximity` : `null` sans frise, valeur sinon.

## 6. Livraison

- Branche `feat/health-review`, worktree `.claude/worktrees/health-review`, partie de `main` (`d40c71e`). La branche `correctifs` (un commit, sommeil) est indépendante et sera fusionnée séparément.
- Merge `--no-ff` après validation explicite de Maxence ; pas de push implicite. Vérification sur simulateur iPhone en thème clair et sombre avant de demander le merge.
- Conflits prévisibles : `app_fr.arb`, `health_page.dart`, `dashboard_page.dart`.

## 7. Hors périmètre

Deuxième RDV dans la tuile d'accueil. Nombre d'examens à programmer dans la tuile quand rien n'est programmé. Rappel des RDV libres dans le digest du matin. Changement du calcul des statuts.
