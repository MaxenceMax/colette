# Colette — Fréquence des soins : « N par jour », « tous les N jours », suivi désactivable

Date : 2026-09-24. Complète la spec v1 (`2026-09-21-colette-v1-design.md`) et remplace `2026-09-22-umbilical-care-per-day-design.md` pour la modélisation des fréquences.

## 1. Problème

Chaque soin attendu (Adrigyl, yeux, nez, nombril) est réglé par un entier « fois par jour », où `0` signifie « pas suivi ». Le bain est réglé à part, en « tous les N jours ». Trois manques :

- Impossible de régler un soin à « une fois tous les 2 jours » : en dessous de 1/jour, le bouton − passe directement à 0.
- Le « plus suivi » est implicite (valeur 0) : rien ne l'affiche comme tel, et la fréquence précédente est perdue.
- Deux règles d'affichage sur l'accueil : les soins « par jour » sont toujours listés, seul le bain sait se masquer quand il n'est pas dû.

## 2. Décision

Une entité `CareFrequency` unique pour les cinq soins (Adrigyl, yeux, nez, nombril, bain), avec une échelle continue et un interrupteur de suivi :

```
[+]  4/jour … 2/jour, 1/jour, tous les 2 jours … tous les 7 jours  [−]
```

L'accueil applique la règle du bain à tous les soins : un soin espacé n'apparaît que le jour où il est dû (ou s'il a déjà été fait aujourd'hui). Un soin dont le suivi est coupé n'apparaît jamais.

Alternatives écartées :

- Champs plats (`xPerDay` + `xEveryDays` + `xEnabled` pour chaque soin) : quinze champs, cinq fois la même logique de bornes dans le DTO et dans les Functions, le bain reste un cas à part.
- Index d'échelle (un entier signé par soin) : compact mais illisible en base et dans la console Firestore.

## 3. Domaine

### 3.1 `CareFrequency`

`lib/features/baby/domain/entities/care_frequency.dart`, freezed.

| Champ | Type | Défaut | Contrainte |
| --- | --- | --- | --- |
| `timesPerDay` | `int` | 1 | ≥ 1 |
| `everyDays` | `int` | 1 | ≥ 1 |
| `enabled` | `bool` | `true` | — |

Invariant : `timesPerDay == 1 || everyDays == 1`. Constante `maxEveryDays = 7`.

Méthodes pures :

- `next(int maxTimesPerDay)` (bouton +) : si `everyDays > 1` → `everyDays − 1` ; sinon si `timesPerDay < maxTimesPerDay` → `timesPerDay + 1` ; sinon `null` (butée).
- `previous()` (bouton −) : si `timesPerDay > 1` → `timesPerDay − 1` ; sinon si `everyDays < maxEveryDays` → `everyDays + 1` ; sinon `null` (butée).
- `isExpected({DateTime? lastDoneAt, required DateTime now})` : `false` si `!enabled` ; `true` si `everyDays == 1` ou `lastDoneAt == null` ; sinon `calendarDaysBetween(lastDoneAt, now) >= everyDays`. C'est la règle actuelle `isBathExpected`, qui disparaît.

### 3.2 `CareSettings`

Les cinq entiers `adrigylPerDay`, `eyeCarePerDay`, `noseCarePerDay`, `umbilicalCarePerDay`, `bathEveryDays` sont remplacés par cinq `CareFrequency` :

| Champ | Défaut |
| --- | --- |
| `adrigyl` | 1/jour |
| `eyeCare` | 1/jour |
| `noseCare` | 1/jour |
| `umbilicalCare` | 3/jour |
| `bath` | tous les 2 jours |

`feedsPerDay`, `nightStartHour`, `nightEndHour` et `dailyTargetMl` ne changent pas.

Accès par type : `CareFrequency frequencyOf(CareType type)` (lève `ArgumentError` pour pipi, caca, change, qui ne sont jamais passés) et `CareSettings withFrequency(CareType type, CareFrequency frequency)`. `CareType` gagne `bool get isScheduled` (vrai pour les cinq soins ci-dessus) et la liste ordonnée `CareType.scheduled` = Adrigyl, yeux, nez, nombril, bain, qui fixe l'ordre de l'accueil, des réglages et du digest.

### 3.3 `ComputeDailyCareStatus`

Signature : `call({required CareSettings settings, required List<CareEvent> events, required DateTime now}) → List<CareTask>`. `events` couvre les 7 derniers jours civils, aujourd'hui inclus (fenêtre `[aujourd'hui − 6 jours, demain)`) ; `lastBath` disparaît.

Pour chaque type de `CareType.scheduled`, dans cet ordre :

1. `frequency = settings.frequencyOf(type)`.
2. `todayEvents` = événements du jour civil de `now` ayant ce soin coché, triés par `startAt`.
3. `lastDoneAt` = `startAt` du plus récent événement de la fenêtre ayant ce soin coché (toutes dates), ou `null`.
4. Tâche présente si `frequency.enabled && (frequency.isExpected(lastDoneAt: lastDoneAt, now: now) || todayEvents.isNotEmpty)`.
5. `CareTask(type, target: frequency.timesPerDay, done: todayEvents.length, lastDoneAt: dernier de todayEvents)`.

Conséquences :

| Cas | Accueil |
| --- | --- |
| Soin 1/jour | Toujours listé (comportement actuel). |
| Soin tous les 2 jours, fait hier | Absent. |
| Soin tous les 2 jours, fait avant-hier ou jamais | Listé, à faire. |
| Soin tous les 2 jours, fait aujourd'hui (même si fait hier aussi) | Listé, grisé « fait ». |
| Soin désactivé, même fait aujourd'hui | Absent. |
| Dernier événement hors fenêtre (≥ 7 jours) | Traité comme « jamais fait » : dû, puisque `everyDays ≤ 7`. |

`CareTask` ne change pas.

## 4. Présentation

### 4.1 Providers

- `weekEventsProvider` (`events_providers.dart`) : `watchBetween(code, from: today − 6 jours, to: today.startOfNextDay)`, réévalué à minuit via `todayProvider`. Une seule écoute Firestore pour les cinq soins.
- `dailyCareTasksProvider` consomme `weekEventsProvider` et `currentMinuteProvider`.
- `latestBathProvider` et `EventsRepository.watchLatestBath` sont supprimés (plus aucun consommateur).

### 4.2 Réglages : `CareFrequencyRow`

`lib/features/baby/presentation/widgets/care_frequency_row.dart`, un widget par soin, deux lignes :

```
[icône]  Adrigyl                                   (●) Switch
         [−]        1 fois par jour           [+]
```

- Ligne 1 : icône et couleur de `CareType` (`care_type_ui.dart`), libellé `careAdrigyl` etc., `Switch` lié à `enabled`.
- Ligne 2 : boutons − / + (`IconButton`, couleur `AppColors.primary`, tooltips `actionDecrease` / `actionIncrease`), texte central `careFrequencyPerDay(n)` (« 1 fois par jour », « 3 fois par jour ») ou `careFrequencyEveryDays(n)` (« tous les 2 jours »). Un bouton est inactif en butée. Quand le switch est coupé, la ligne reste visible, grisée (`AppColors.textSecondary`), boutons inactifs : la fréquence conservée reste lisible.
- Paramètres : `type`, `frequency`, `maxTimesPerDay`, `onChanged(CareFrequency)`.

`CareSettingsSection` aligne cinq `CareFrequencyRow` (ordre `CareType.scheduled`) puis le stepper « Biberons par jour » inchangé. Bornes hautes : Adrigyl 3/jour, yeux, nez et nombril 4/jour, bain 2/jour. La copie locale optimiste et la fusion champ par champ dans le profil frais sont conservées, via `withFrequency`.

### 4.3 Chute du cordon

`BabySettingsController.setCordFallenAt` : renseigner la date écrit `umbilicalCare.copyWith(enabled: false)` ; l'effacer écrit `enabled: true`. La fréquence n'est pas modifiée dans les deux sens.

### 4.4 Formulaire d'événement

La puce « Soin du nombril » est masquée si `settings.umbilicalCare.enabled` est faux, sauf si l'événement édité l'a déjà cochée (condition actuelle, adaptée). Les puces des autres soins restent toujours proposées, suivi actif ou non : couper le suivi du bain ne doit pas empêcher d'enregistrer un bain.

### 4.5 Chaînes (`app_fr.arb`)

Ajoutées :

| Clé | Valeur |
| --- | --- |
| `careFrequencyPerDay` | `{n, plural, =1{1 fois par jour} other{{n} fois par jour}}` |
| `careFrequencyEveryDays` | `tous les {n} jours` |
| `settingsCareTracked` | `Suivi` (sémantique du switch) |

Supprimées : `settingsAdrigylPerDay`, `settingsEyeCarePerDay`, `settingsNoseCarePerDay`, `settingsUmbilicalCarePerDay`, `settingsBathEveryDays`.

## 5. Données Firestore

### 5.1 Écriture

```
baby.careSettings:
  adrigyl:       { timesPerDay: 1, everyDays: 1, enabled: true }
  eyeCare:       { timesPerDay: 1, everyDays: 1, enabled: true }
  noseCare:      { timesPerDay: 1, everyDays: 1, enabled: true }
  umbilicalCare: { timesPerDay: 3, everyDays: 1, enabled: true }
  bath:          { timesPerDay: 1, everyDays: 2, enabled: true }
  feedsPerDay, nightStartHour, nightEndHour, dailyTargetMl (inchangés)
```

Les champs `adrigylPerDay`, `eyeCarePerDay`, `noseCarePerDay`, `umbilicalCarePerDay`, `umbilicalCareEnabled` et `bathEveryDays` ne sont plus écrits.

### 5.2 Lecture de repli

Identique dans `CareSettingsDto.fromMap` (app) et `withDefaults` (Functions), pour chaque soin :

1. Map présente → `timesPerDay` borné 1..10, `everyDays` borné 1..30, `enabled` booléen (absent ou non booléen → `true`). Si les deux entiers dépassent 1, `timesPerDay` est ramené à 1.
2. Sinon, ancien champ plat :
   - `xPerDay` numérique : `0` → `enabled: false` avec la fréquence par défaut du soin ; `n > 0` → `n/jour` (borné 1..10).
   - Nombril : `umbilicalCarePerDay` comme ci-dessus ; sinon `umbilicalCareEnabled == false` → désactivé, fréquence par défaut.
   - Bain : `bathEveryDays: n` → tous les `n` jours (borné 1..30).
3. Sinon → défaut du soin.

Aucune migration : la première sauvegarde des réglages réécrit le document au nouveau format.

### 5.3 Index

L'index composite `events (bath ASC, startAt DESC)` de `firestore.indexes.json` n'a plus de consommateur (ni app, ni Functions) et est retiré.

## 6. Cloud Functions

- `lib/types.ts` : `CareFrequency`, `CareSettings` avec les cinq fréquences et `feedsPerDay`, `DEFAULT_CARE_SETTINGS`, `withDefaults` avec le repli de §5.2. `StoredCareSettings` accepte les anciens champs plats.
- `lib/care-frequency.ts` : `isExpected(frequency, lastDoneAt, now)`, miroir de §3.1.
- `lib/care-status.ts` : `pendingCares({ settings, events, now })` sur la fenêtre de 7 jours, même règle qu'en §3.3, libellés dans l'ordre Adrigyl, yeux, nez, nombril, bain. `isBathExpected` disparaît.
- `morning-digest.ts` : une seule requête `startAt ∈ [startOfTodayInParis(now) − 6 jours, startOfTomorrowInParis(now))` remplace « aujourd'hui » + « dernier bain ». `paris-time.ts` gagne `startOfDayInParis(date, daysAgo)` pour la borne basse.
- `bottle-reminder.ts` et `on-event-created.ts` ne changent pas.

## 7. Fichiers touchés

App :

- `lib/shared/domain/care_type.dart` : `isScheduled`, `scheduled`.
- `lib/features/baby/domain/entities/care_frequency.dart` (nouveau), `care_settings.dart`.
- `lib/features/baby/data/dtos/baby_profile_dto.dart` : `CareFrequencyDto` + repli.
- `lib/features/baby/presentation/providers/baby_settings_controller.dart` : `setCordFallenAt`.
- `lib/features/baby/presentation/widgets/care_frequency_row.dart` (nouveau), `care_settings_section.dart`.
- `lib/features/dashboard/domain/use_cases/compute_daily_care_status.dart`.
- `lib/features/dashboard/presentation/providers/dashboard_providers.dart`.
- `lib/features/events/domain/repositories/events_repository.dart`, `data/repositories/firestore_events_repository.dart`, `presentation/providers/events_providers.dart` : `weekEvents` ajouté, `latestBath` retiré.
- `lib/features/events/presentation/widgets/event_form_sheet.dart` : condition `enabled`.
- `lib/l10n/app_fr.arb`.
- `firestore.indexes.json`.

Functions : `lib/types.ts`, `lib/care-frequency.ts` (nouveau), `lib/care-status.ts`, `lib/paris-time.ts`, `morning-digest.ts`, tests associés.

Documentation : spec v1, sections 5 (modèle `careSettings`), 6.2 (règle des soins attendus), 6.6 (Réglages) et 7 (requête du digest). `README.md` ne décrit pas les fréquences et ne change pas.

## 8. Tests

Domaine :

- `care_frequency_test` : `next` / `previous` parcourent l'échelle dans les deux sens ; butées à `maxTimesPerDay` et à 7 jours → `null` ; `isExpected` désactivé → faux ; 1/jour → vrai ; tous les 2 jours fait hier → faux, avant-hier → vrai, jamais → vrai.
- `compute_daily_care_status_test` : les six cas du tableau §3.3, plus l'ordre des tâches et la cible `timesPerDay`. Les tests bain existants sont réécrits sur la fenêtre.

Data : DTO `toMap` écrit les cinq maps et plus aucun champ plat ; `fromMap` couvre les trois niveaux de repli, `xPerDay: 0`, `umbilicalCareEnabled: false`, `bathEveryDays: 3`, et la normalisation « deux entiers > 1 ».

Présentation :

- `care_frequency_row_test` : − depuis 1/jour affiche « tous les 2 jours » ; + depuis tous les 2 jours revient à « 1 fois par jour » ; switch coupé → boutons inactifs et `onChanged(enabled: false)`.
- `care_settings_section_test` : un changement de fréquence sauvegarde via `updateCareSettings` avec fusion dans le profil frais.
- `baby_settings_controller_test` : date renseignée → nombril `enabled: false`, fréquence conservée ; effacée → `enabled: true`.
- `event_form_sheet_test` : puce nombril absente si `enabled: false`, présente si l'événement édité la coche.
- `dashboard` : `TodoSection` masque un soin espacé fait hier.

Functions : `withDefaults` (trois niveaux de repli), `care-frequency.test.ts`, `pendingCares` sur la fenêtre (mêmes cas que §3.3), `morning-digest.test.ts` adapté à la requête unique.

Vérification finale : `dart run build_runner build -d`, `dart format lib test`, `dart analyze`, `flutter test`, puis `npm test` et `npm run build` dans `functions/`. Contrôle visuel des Réglages et de l'accueil sur simulateur iPhone, thèmes clair et sombre.

## 9. Hors périmètre

- Masquer les puces des soins désactivés autres que le nombril dans le formulaire d'événement.
- Fréquences autres que « N par jour » et « 1 fois tous les N jours » (par exemple « 3 fois par semaine »).
- Migration des documents Firestore existants.
