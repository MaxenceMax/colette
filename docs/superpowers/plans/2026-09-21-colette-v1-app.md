# Colette v1 — Plan d'implémentation (app Flutter)

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Construire l'app iOS Colette : onboarding par code foyer, dashboard du jour avec plan biberons OMS, journal paginé, formulaire d'événement, réglages, enregistrement push.

**Architecture:** Clean Architecture feature-first (`domain` / `data` / `presentation`) avec Riverpod 3 en codegen, entités `freezed`, erreurs `Either<Failure, T>` (fpdart), Firestore comme unique source de données partagée. Design system par tokens (`AppColors`, `AppSpacing`, `ColetteTextStyle`) : aucune valeur de style en dur dans les pages.

**Tech Stack:** Flutter 3.47 / Dart 3.13, flutter_riverpod 3.4, riverpod_generator 4, riverpod_lint 3.1 (plugin analyzer natif, sans custom_lint), freezed 4, go_router 18, cloud_firestore 6, firebase_auth 6, firebase_messaging 16, shared_preferences, google_fonts (Fraunces + DM Sans), fpdart, mocktail, fake_cloud_firestore.

**Spec de référence :** `docs/superpowers/specs/2026-09-21-colette-v1-design.md`. Deux précisions par rapport à la spec, décidées en écrivant ce plan :
- Les DTOs sont des mappers manuels (`toMap` / `fromMap`) plutôt que `json_serializable`, parce que Firestore manipule des `Timestamp` et que la conversion manuelle est plus courte.
- Les événements portent un champ stocké `hasBottle: bool` pour permettre la requête « dernier biberon » par égalité (index composite simple).

**Plan compagnon :** `docs/superpowers/plans/2026-09-21-colette-v1-functions.md` (Cloud Functions, règles et index Firestore). Il peut être exécuté après la tâche 10 de ce plan.

---

## Carte des fichiers

| Fichier | Responsabilité |
| --- | --- |
| `CLAUDE.md` | Règles projet |
| `pubspec.yaml`, `analysis_options.yaml`, `l10n.yaml` | Dépendances, lints, i18n |
| `lib/main.dart` | Bootstrap Firebase, auth anonyme, prefs, `ProviderScope` |
| `lib/firebase_options.dart` | Placeholder remplacé par `flutterfire configure` |
| `lib/app/colette_app.dart` | `MaterialApp.router`, thèmes, locale |
| `lib/app/router/app_router.dart` | Routes, redirection onboarding, shell 3 onglets |
| `lib/app/main_shell.dart` | `NavigationBar` + bandeau hors ligne |
| `lib/core/result/failure.dart` | `Failure` sealed + `ValidationReason` |
| `lib/core/result/failure_mapper.dart` | `guard()` : exceptions → `Failure` |
| `lib/core/result/either_extensions.dart` | `leftOrNull` |
| `lib/core/clock/app_clock.dart` | `AppClock`, `SystemClock`, `FixedClock`, `clockProvider` |
| `lib/core/ids/id_generator.dart` | `IdGenerator`, `idGeneratorProvider` |
| `lib/core/dates/date_extensions.dart` | `dateOnly`, `isSameDay` |
| `lib/core/firebase/firebase_providers.dart` | Providers Firestore, Auth, Messaging, SharedPreferences |
| `lib/core/firebase/firestore_paths.dart` | Noms de collections |
| `lib/core/firebase/anonymous_auth.dart` | `ensureAnonymousSession` |
| `lib/core/connectivity/connectivity_provider.dart` | `isOnlineProvider` |
| `lib/core/theme/app_colors.dart` | Enum `AppColors` light/dark + `context.appColor` |
| `lib/core/theme/design_tokens.dart` | `AppSpacing`, `AppRadius`, `AppSize`, `AppFontSize`, `AppDuration`, `AppOpacity`, `AppElevation` |
| `lib/core/theme/text_styles.dart` | `ColetteTextStyle`, `coletteTextStyles` |
| `lib/core/theme/theme_service.dart` | `ThemeService.light()` / `.dark()` |
| `lib/core/ui/failure_message.dart` | `Failure` → texte traduit |
| `lib/core/ui/date_time_picker.dart` | `showColetteDateTimePicker` |
| `lib/shared/domain/care_type.dart` | `CareType`, `CareCategory` |
| `lib/shared/ui/care_type_ui.dart` | Icône, libellé, couleur d'un `CareType` |
| `lib/shared/ui/widgets/colette_card_surface.dart` | Carte tokens |
| `lib/shared/ui/widgets/section_header.dart` | Titre de section |
| `lib/shared/ui/widgets/empty_state.dart` | État vide |
| `lib/shared/ui/widgets/care_chip.dart` | Puce à cocher |
| `lib/shared/ui/widgets/offline_banner.dart` | Bandeau hors ligne |
| `lib/shared/ui/widgets/int_stepper_row.dart` | Ligne label + stepper entier |
| `lib/features/baby/domain/entities/*.dart` | `CareSettings`, `BabyProfile`, `WeightEntry`, `FeedingPlanSnapshot` |
| `lib/features/baby/domain/repositories/baby_repository.dart` | Interface |
| `lib/features/baby/data/dtos/*.dart` | Mappers Firestore |
| `lib/features/baby/data/repositories/firestore_baby_repository.dart` | Implémentation |
| `lib/features/baby/presentation/providers/baby_providers.dart` | `babyRepositoryProvider`, `babyProfileProvider`, `weightsProvider`, `latestWeightProvider` |
| `lib/features/baby/presentation/providers/baby_settings_controller.dart` | Actions réglages |
| `lib/features/baby/presentation/pages/settings_page.dart` | Onglet Réglages |
| `lib/features/baby/presentation/widgets/*.dart` | Sections des réglages |
| `lib/features/household/domain/entities/*.dart` | `Household`, `DeviceInfo` |
| `lib/features/household/domain/household_code_generator.dart` | Code 8 caractères |
| `lib/features/household/domain/repositories/*.dart` | `HouseholdRepository`, `DeviceRepository`, `HouseholdLocalStore` |
| `lib/features/household/data/*.dart` | Prefs + Firestore |
| `lib/features/household/presentation/providers/household_providers.dart` | `currentHouseholdCodeProvider`, `deviceIdProvider`, repositories |
| `lib/features/household/presentation/providers/onboarding_controller.dart` | Créer / rejoindre |
| `lib/features/household/presentation/pages/*.dart` | Onboarding, création, jonction |
| `lib/features/events/domain/entities/care_event.dart` | `CareEvent` |
| `lib/features/events/domain/use_cases/validate_care_event.dart` | Validation |
| `lib/features/events/domain/repositories/events_repository.dart` | Interface |
| `lib/features/events/data/*.dart` | DTO + Firestore |
| `lib/features/events/presentation/providers/events_providers.dart` | Streams du jour, derniers bain/biberon, timeline |
| `lib/features/events/presentation/providers/event_form_controller.dart` | Soumission |
| `lib/features/events/presentation/widgets/event_form_sheet.dart` | Formulaire |
| `lib/features/events/presentation/widgets/event_tile.dart` | Ligne du journal |
| `lib/features/events/presentation/pages/timeline_page.dart` | Onglet Journal |
| `lib/features/events/presentation/day_label.dart` | « Aujourd'hui », « Hier », date |
| `lib/features/dashboard/domain/entities/*.dart` | `FeedingPlan`, `CareTask`, `BabyAge` |
| `lib/features/dashboard/domain/use_cases/*.dart` | `ComputeFeedingPlan`, `ComputeDailyCareStatus`, `ComputeBabyAge` |
| `lib/features/dashboard/presentation/providers/dashboard_providers.dart` | Plan, tâches, compteurs |
| `lib/features/dashboard/presentation/providers/feeding_plan_sync.dart` | Écriture `feedingPlan` |
| `lib/features/dashboard/presentation/pages/dashboard_page.dart` | Onglet Aujourd'hui |
| `lib/features/dashboard/presentation/widgets/*.dart` | Sections du dashboard |
| `lib/features/notifications/domain/push_token_source.dart` | Interface FCM |
| `lib/features/notifications/data/firebase_push_token_source.dart` | Implémentation |
| `lib/features/notifications/presentation/providers/*.dart` | Enregistrement, préférences |
| `lib/features/notifications/presentation/widgets/notifications_section.dart` | Section réglages |
| `lib/app/notification_tap_handler.dart` | Ouverture par notification |
| `test/helpers/*.dart` | `pumpApp`, `InMemoryHouseholdLocalStore`, fakes |

---

### Task 1: Projet iOS uniquement, dépendances, configuration, CLAUDE.md

**Files:**
- Delete: `android/`, `web/`, `macos/`, `linux/`, `windows/`, `test/widget_test.dart`
- Modify: `pubspec.yaml`, `analysis_options.yaml`, `.gitignore`, `lib/main.dart`
- Create: `l10n.yaml`, `lib/l10n/app_fr.arb`, `lib/firebase_options.dart`, `CLAUDE.md`

- [ ] **Step 1: Supprimer les plateformes hors iOS et le test template**

```bash
cd /Users/maxencemontet/Documents/colette
rm -rf android web macos linux windows test/widget_test.dart
```

- [ ] **Step 2: Remplacer `pubspec.yaml`**

```yaml
name: colette
description: Suivi des soins du nouveau-né, pour deux parents.
publish_to: 'none'
version: 1.0.0+1

environment:
  sdk: ^3.13.4

dependencies:
  flutter:
    sdk: flutter
  flutter_localizations:
    sdk: flutter
  cupertino_icons: ^1.0.8
  flutter_riverpod: ^3.4.3
  riverpod_annotation: ^4.0.7
  freezed_annotation: ^3.1.0
  go_router: ^18.0.1
  firebase_core: ^4.15.0
  cloud_firestore: ^6.10.0
  firebase_auth: ^6.7.0
  firebase_messaging: ^16.7.0
  shared_preferences: ^2.5.5
  google_fonts: ^8.2.1
  fpdart: ^1.2.0
  uuid: ^4.6.0
  intl: ^0.20.3
  connectivity_plus: ^7.3.1

dev_dependencies:
  flutter_test:
    sdk: flutter
  flutter_lints: ^6.0.0
  build_runner: ^2.16.1
  riverpod_generator: ^4.0.9
  freezed: ^4.0.2
  mocktail: ^1.0.5
  fake_cloud_firestore: ^4.3.0

flutter:
  generate: true
  uses-material-design: true
```

- [ ] **Step 3: Remplacer `analysis_options.yaml`**

```yaml
include: package:flutter_lints/flutter.yaml

plugins:
  riverpod_lint: 3.1.9

analyzer:
  exclude:
    - "**/*.g.dart"
    - "**/*.freezed.dart"
    - lib/l10n/generated/**
    - build/**
    - ios/**

linter:
  rules:
    prefer_const_constructors: true
    prefer_const_declarations: true
    prefer_final_locals: true
    avoid_print: true
    require_trailing_commas: true
    always_declare_return_types: true
```

- [ ] **Step 4: Créer `l10n.yaml`**

```yaml
arb-dir: lib/l10n
template-arb-file: app_fr.arb
output-localization-file: app_localizations.dart
output-class: S
output-dir: lib/l10n/generated
nullable-getter: false
```

- [ ] **Step 5: Créer `lib/l10n/app_fr.arb` (toutes les chaînes de la v1)**

```json
{
  "@@locale": "fr",
  "appTitle": "Colette",
  "tabToday": "Aujourd'hui",
  "tabJournal": "Journal",
  "tabSettings": "Réglages",
  "onboardingTitle": "Bienvenue",
  "onboardingSubtitle": "Crée votre foyer sur le premier iPhone, puis rejoins-le avec le code sur le second.",
  "onboardingCreate": "Créer notre foyer",
  "onboardingJoin": "Rejoindre avec un code",
  "createHouseholdTitle": "Créer notre foyer",
  "joinHouseholdTitle": "Rejoindre un foyer",
  "fieldBabyName": "Prénom du bébé",
  "fieldBirthDate": "Date de naissance",
  "fieldDeviceLabel": "Nom de cet iPhone",
  "fieldDeviceLabelHint": "iPhone de Maxence",
  "deviceLabelDefault": "Cet iPhone",
  "fieldHouseholdCode": "Code du foyer",
  "actionCreate": "Créer",
  "actionJoin": "Rejoindre",
  "actionSave": "Enregistrer",
  "actionCancel": "Annuler",
  "actionUndo": "Annuler",
  "actionDelete": "Supprimer",
  "actionRetry": "Réessayer",
  "actionCopy": "Copier",
  "actionAdd": "Ajouter",
  "actionChoose": "Choisir",
  "errorUnknownCode": "Code inconnu. Vérifie les 8 caractères.",
  "errorEmptyName": "Le prénom est obligatoire.",
  "errorNetwork": "Pas de connexion. Réessaie dans un instant.",
  "errorUnknown": "Une erreur est survenue.",
  "errorNotFound": "Introuvable : l'élément a peut-être été supprimé.",
  "actionDecrease": "Diminuer",
  "actionIncrease": "Augmenter",
  "errorEmptyEvent": "Coche au moins un soin ou renseigne un biberon.",
  "errorEndBeforeStart": "L'heure de fin doit être après le début.",
  "errorStartInFuture": "L'heure de début ne peut pas être dans le futur.",
  "errorBottleOutOfRange": "La quantité doit être entre 10 et 300 ml.",
  "errorInvalidWeight": "Le poids doit être entre 1 000 et 20 000 g.",
  "saved": "Enregistré",
  "offlineBanner": "Hors ligne : tes saisies partiront à la reconnexion.",
  "dashboardAge": "{name} a {age}",
  "@dashboardAge": { "placeholders": { "name": { "type": "String" }, "age": { "type": "String" } } },
  "ageDays": "{count, plural, =0{0 jour} =1{1 jour} other{{count} jours}}",
  "@ageDays": { "placeholders": { "count": { "type": "int" } } },
  "ageWeeks": "{count, plural, =1{1 semaine} other{{count} semaines}}",
  "@ageWeeks": { "placeholders": { "count": { "type": "int" } } },
  "ageMonths": "{count, plural, =1{1 mois} other{{count} mois}}",
  "@ageMonths": { "placeholders": { "count": { "type": "int" } } },
  "nextBottleTitle": "Prochain biberon",
  "nextBottleAt": "vers {time}",
  "@nextBottleAt": { "placeholders": { "time": { "type": "String" } } },
  "nextBottleLate": "en retard de {minutes} min",
  "@nextBottleLate": { "placeholders": { "minutes": { "type": "int" } } },
  "nextBottleNow": "maintenant",
  "bottleProgress": "{given} sur {total} donnés · {givenMl} / {targetMl} ml",
  "@bottleProgress": { "placeholders": { "given": { "type": "int" }, "total": { "type": "int" }, "givenMl": { "type": "int" }, "targetMl": { "type": "int" } } },
  "feedingPlanEstimated": "Repères par âge : ajoute une pesée pour un calcul au poids.",
  "feedingPlanUnavailable": "Renseigne le profil du bébé pour voir le plan biberons.",
  "todoTitle": "Reste à faire",
  "todoAllDone": "Tout est fait pour aujourd'hui.",
  "doneAt": "fait à {time}",
  "@doneAt": { "placeholders": { "time": { "type": "String" } } },
  "countersDiapers": "couches",
  "countersPee": "pipis",
  "countersPoop": "cacas",
  "carePee": "Pipi",
  "carePoop": "Caca",
  "careDiaperChange": "Couche",
  "careAdrigyl": "Adrigyl",
  "careBath": "Bain",
  "careEyeCare": "Soin des yeux",
  "careNoseCare": "Soin du nez",
  "careUmbilicalCare": "Soin du nombril",
  "careBottle": "Biberon",
  "bottleMl": "{ml} ml",
  "@bottleMl": { "placeholders": { "ml": { "type": "int" } } },
  "journalTitle": "Journal",
  "journalEmpty": "Aucun événement pour l'instant. Appuie sur + pour commencer.",
  "dayToday": "Aujourd'hui",
  "dayYesterday": "Hier",
  "deleteEventTitle": "Supprimer cet événement ?",
  "deleteEventBody": "Cette action est définitive.",
  "eventFormNewTitle": "Nouvel événement",
  "eventFormEditTitle": "Modifier l'événement",
  "fieldStartAt": "Début",
  "fieldEndAt": "Fin",
  "fieldNote": "Note",
  "fieldNoteHint": "Un détail à retenir ?",
  "settingsTitle": "Réglages",
  "settingsBabySection": "Bébé",
  "settingsCordFallenAt": "Chute du cordon",
  "settingsCordNotYet": "Pas encore",
  "settingsWeightsSection": "Pesées",
  "settingsWeightsEmpty": "Aucune pesée. Ajoute la première pour un calcul au poids.",
  "settingsAddWeight": "Ajouter une pesée",
  "fieldWeightGrams": "Poids (g)",
  "fieldMeasuredAt": "Date",
  "weightGrams": "{grams} g",
  "@weightGrams": { "placeholders": { "grams": { "type": "int" } } },
  "settingsCareSection": "Soins attendus",
  "settingsAdrigylPerDay": "Adrigyl par jour",
  "settingsEyeCarePerDay": "Soin des yeux par jour",
  "settingsNoseCarePerDay": "Soin du nez par jour",
  "settingsBathEveryDays": "Bain tous les N jours",
  "settingsUmbilicalEnabled": "Soin du nombril",
  "settingsFeedsPerDay": "Biberons par jour",
  "settingsNotificationsSection": "Notifications de cet iPhone",
  "settingsNotifyOthersEvents": "Événements ajoutés par l'autre",
  "settingsNotifyBottle": "Rappel biberon",
  "settingsNotifyMorning": "Digest du matin",
  "settingsMorningHour": "Heure du digest",
  "settingsHouseholdSection": "Foyer",
  "settingsHouseholdCode": "Code à partager",
  "settingsLeaveHousehold": "Quitter ce foyer",
  "leaveHouseholdTitle": "Quitter ce foyer ?",
  "leaveHouseholdBody": "Les données restent sur le cloud. Tu pourras rejoindre à nouveau avec le code.",
  "copied": "Code copié",
  "hourLabel": "{hour}h",
  "@hourLabel": { "placeholders": { "hour": { "type": "int" } } }
}
```

- [ ] **Step 6: Compléter `.gitignore`**

Ajouter à la fin du fichier existant :

```gitignore
# Généré par gen-l10n à chaque `flutter pub get`
lib/l10n/generated/
# Node (Cloud Functions)
functions/node_modules/
functions/lib/
```

- [ ] **Step 7: Créer `lib/firebase_options.dart` (placeholder)**

```dart
// Placeholder : remplacer ce fichier par la sortie de
// `flutterfire configure --platforms=ios`.
import 'package:firebase_core/firebase_core.dart';

/// Options Firebase de l'app. Les valeurs ci-dessous sont factices
/// et permettent seulement de compiler et de lancer les tests.
class DefaultFirebaseOptions {
  static FirebaseOptions get currentPlatform => ios;

  static const FirebaseOptions ios = FirebaseOptions(
    apiKey: 'REPLACE_ME',
    appId: '1:000000000000:ios:0000000000000000',
    messagingSenderId: '000000000000',
    projectId: 'colette-placeholder',
    storageBucket: 'colette-placeholder.appspot.com',
    iosBundleId: 'com.example.colette',
  );
}
```

- [ ] **Step 8: Remplacer `lib/main.dart` par un point d'entrée minimal**

```dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

void main() {
  runApp(const ProviderScope(child: SizedBox.shrink()));
}
```

- [ ] **Step 9: Créer `CLAUDE.md`**

```markdown
# Colette — Instructions pour Claude Code

## Contexte

App iOS privée pour deux parents : suivi des soins quotidiens d'un nouveau-né. Pas de compte utilisateur, partage par code foyer sur Firestore, notifications par Cloud Functions. Spec : `docs/superpowers/specs/2026-09-21-colette-v1-design.md`.

## Plateforme (OBLIGATOIRE)

- iOS uniquement. Ne jamais recréer `android/`, `web/`, `macos/`, `linux/`, `windows/`.
- Cible iOS 15 et plus. Vérifier sur simulateur iPhone.

## Architecture

Clean Architecture feature-first : `lib/features/{name}/domain|data|presentation/`.

- `domain` : entités `freezed`, interfaces de repositories, use cases purs. N'importe ni Flutter ni Firebase.
- `data` : DTOs (mappers Firestore `toMap` / `fromMap`), data sources, implémentations de repositories.
- `presentation` : providers Riverpod, pages, widgets.
- Flux : `presentation → domain ← data`. Une feature peut consommer les providers publics (`presentation/providers/`) et les entités de domaine d'une autre feature ; jamais son `data/`.
- Transverse : `core/` (theme, result, clock, ids, dates, firebase, connectivity, ui), `shared/` (entités et widgets partagés).

## State management (OBLIGATOIRE)

- Riverpod 3 en codegen : `@riverpod` sur fonctions et classes, `part 'x.g.dart'`. Jamais de provider écrit à la main.
- Actions asynchrones : `class XController extends _$XController { @override FutureOr<void> build() {} }`, `state = const AsyncLoading()` puis `AsyncData` ou `AsyncError(failure, stackTrace)`.
- `ref.watch` dans `build`, `ref.read` dans les callbacks. Jamais `ref.read` dans un `build`. Un contrôleur `autoDispose` appelé via `ref.read(xProvider.notifier)` depuis un callback doit être `ref.watch`é (ou `ref.listen`é) dans le `build` du widget appelant, sinon il est détruit pendant l'`await`.
- UI : `switch` sur `AsyncValue` (`AsyncData(:final value)`, `AsyncLoading()`, `AsyncError(:final error)`). Jamais `.when`.
- Interdits : Bloc, Provider, GetIt, `setState` pour de la logique métier.
- Après toute modification d'un fichier annoté : `dart run build_runner build -d`.

## Design system (OBLIGATOIRE)

- Couleurs : `context.appColor(AppColors.xxx)`. Jamais `Colors.xxx` ni `Color(0x…)` hors de `app_colors.dart`. Couleur manquante : l'ajouter dans `AppColors` avec `light` ET `dark`.
- Espacements, rayons, tailles : `AppSpacing.md.all`, `AppRadius.lg.circular`, `AppSize.xl.value`. Jamais de nombre en dur.
- Texte : `Theme.of(context).coletteTextStyles.heading1`. Jamais `TextStyle(fontSize: …)` hors de `text_styles.dart` et `theme_service.dart`.
- Pas de `width` / `height` fixes : `Expanded`, `Flexible`, `LayoutBuilder`, `AppSize`.
- Strings : `S.of(context).cle` depuis `lib/l10n/app_fr.arb`. Jamais de string UI en dur.
- Chaque écran doit être lisible en thème clair et sombre.

## Widgets

- `const` partout où possible ; `final` sur les variables locales.
- Un widget par responsabilité, fichier de moins de 300 lignes, sections extraites en widgets privés `_XxxSection`.
- Listes dynamiques : `ListView.builder` ou `SliverList.builder`.
- Tout `TextEditingController`, `ScrollController`, `FocusNode` est disposé dans `dispose()`.
- Commentaire `///` d'une ligne sur chaque classe publique.

## Erreurs

- Repositories et use cases renvoient `Either<Failure, T>` (fpdart). Les exceptions sont converties par `guard()` dans `core/result/failure_mapper.dart`.
- Interdits : `print`, catch vide, `throw` depuis un repository.
- Log : `dart:developer` `log(..., name: 'colette')`.

## Données

- Chemins Firestore via `FirestorePaths`. Dates stockées en `Timestamp`, converties dans les DTOs.
- Toute écriture d'un biberon, d'une pesée ou des réglages de soins déclenche `feedingPlanSyncProvider`.

## Tests

- TDD : test rouge, implémentation minimale, test vert, commit.
- Domaine : tests purs sans Flutter. Data : `fake_cloud_firestore`. Présentation : `pumpApp` (`test/helpers/pump_app.dart`) avec `overrides` et `mocktail`.
- Horloge : toujours `clockProvider` (`FixedClock` en test). Identifiants : `idGeneratorProvider`.
- Avant de déclarer une tâche terminée : `dart format lib test`, puis `dart analyze` et `flutter test` sans erreur. Utiliser `dart analyze`, pas `flutter analyze` : seul `dart analyze` exécute le plugin `riverpod_lint` déclaré dans `analysis_options.yaml`.

## Syntaxe Dart

- Dot shorthand quand le type est inféré : `.center`, `.bold`, `.circular`.
- `switch` expressions, pattern matching, sealed classes, records.
- Fichiers snake_case, classes PascalCase, membres camelCase.

## Commits

- Préfixes : `feat:`, `fix:`, `test:`, `docs:`, `chore:`. Message en français, une ligne de résumé.
```

- [ ] **Step 10: Installer et vérifier**

Run: `cd /Users/maxencemontet/Documents/colette && flutter pub get && dart format lib test && dart analyze`
Expected: `Got dependencies!` puis `No issues found!` (`dart analyze` charge le plugin riverpod_lint au premier lancement, ce qui peut prendre une minute). Le dossier `lib/l10n/generated/` apparaît (ignoré par git).

- [ ] **Step 11: Commit**

```bash
git add -A
git commit -m "chore: projet iOS uniquement, dépendances Riverpod/Firebase, règles CLAUDE.md, chaînes fr"
```

---

### Task 2: Core — Failure, guard, horloge, ids, dates, providers Firebase

**Files:**
- Create: `lib/core/result/failure.dart`, `lib/core/result/failure_mapper.dart`, `lib/core/result/either_extensions.dart`
- Create: `lib/core/clock/app_clock.dart`, `lib/core/ids/id_generator.dart`, `lib/core/dates/date_extensions.dart`
- Create: `lib/core/firebase/firebase_providers.dart`, `lib/core/firebase/firestore_paths.dart`, `lib/core/firebase/anonymous_auth.dart`
- Test: `test/core/result/failure_mapper_test.dart`, `test/core/clock/app_clock_test.dart`, `test/core/dates/date_extensions_test.dart`

- [ ] **Step 1: Écrire les tests (rouges)**

`test/core/result/failure_mapper_test.dart` :

```dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:colette/core/result/failure.dart';
import 'package:colette/core/result/failure_mapper.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('guard', () {
    test('renvoie Right quand l\'action réussit', () async {
      final result = await guard(() async => 42);
      expect(result.getRight().toNullable(), 42);
    });

    test('convertit FirebaseException unavailable en NetworkFailure', () async {
      final result = await guard<int>(
        () async => throw FirebaseException(plugin: 'cloud_firestore', code: 'unavailable'),
      );
      expect(result.getLeft().toNullable(), isA<NetworkFailure>());
    });

    test('convertit FirebaseException not-found en NotFoundFailure', () async {
      final result = await guard<int>(
        () async => throw FirebaseException(plugin: 'cloud_firestore', code: 'not-found'),
      );
      expect(result.getLeft().toNullable(), isA<NotFoundFailure>());
    });

    test('convertit toute autre exception en UnknownFailure', () async {
      final result = await guard<int>(() async => throw StateError('boom'));
      expect(result.getLeft().toNullable(), isA<UnknownFailure>());
    });
  });
}
```

`test/core/clock/app_clock_test.dart` :

```dart
import 'package:colette/core/clock/app_clock.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('clockProvider peut être surchargé par une FixedClock', () {
    final fixed = DateTime(2026, 9, 21, 14, 30);
    final container = ProviderContainer(
      overrides: [clockProvider.overrideWithValue(FixedClock(fixed))],
    );
    addTearDown(container.dispose);
    expect(container.read(clockProvider).now(), fixed);
  });
}
```

`test/core/dates/date_extensions_test.dart` :

```dart
import 'package:colette/core/dates/date_extensions.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('dateOnly supprime l\'heure', () {
    expect(DateTime(2026, 9, 21, 14, 30).dateOnly, DateTime(2026, 9, 21));
  });

  test('isSameDay compare le jour civil', () {
    expect(DateTime(2026, 9, 21, 1).isSameDay(DateTime(2026, 9, 21, 23)), isTrue);
    expect(DateTime(2026, 9, 21, 23).isSameDay(DateTime(2026, 9, 22, 0)), isFalse);
  });

  test('startOfNextDay renvoie minuit du lendemain', () {
    expect(DateTime(2026, 9, 21, 14).startOfNextDay, DateTime(2026, 9, 22));
  });
}
```

- [ ] **Step 2: Lancer les tests pour vérifier l'échec**

Run: `flutter test test/core`
Expected: échec de compilation, `package:colette/core/result/failure.dart` introuvable.

- [ ] **Step 3: Créer `lib/core/result/failure.dart`**

```dart
/// Raison d'une [ValidationFailure], traduite par la présentation.
enum ValidationReason {
  emptyEvent,
  endBeforeStart,
  startInFuture,
  bottleOutOfRange,
  invalidWeight,
  emptyName,
  unknownHouseholdCode,
}

/// Erreur remontée par les repositories et les use cases via `Either`.
sealed class Failure {
  const Failure();
}

/// Réseau indisponible ou appel Firestore échoué pour cause de connectivité.
final class NetworkFailure extends Failure {
  const NetworkFailure();
}

/// Ressource introuvable : code foyer inconnu, document supprimé.
final class NotFoundFailure extends Failure {
  const NotFoundFailure();
}

/// Donnée saisie invalide.
final class ValidationFailure extends Failure {
  const ValidationFailure(this.reason);

  final ValidationReason reason;
}

/// Erreur inattendue, conservée avec sa pile pour le log.
final class UnknownFailure extends Failure {
  const UnknownFailure(this.error, [this.stackTrace]);

  final Object error;
  final StackTrace? stackTrace;
}
```

- [ ] **Step 4: Créer `lib/core/result/failure_mapper.dart`**

```dart
import 'dart:developer' as developer;

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:colette/core/result/failure.dart';
import 'package:fpdart/fpdart.dart';

const _networkCodes = {'unavailable', 'deadline-exceeded', 'network-request-failed'};

/// Exécute [action] et convertit toute exception en [Failure].
Future<Either<Failure, T>> guard<T>(Future<T> Function() action) async {
  try {
    return right(await action());
  } on FirebaseException catch (e, stackTrace) {
    if (_networkCodes.contains(e.code)) return left(const NetworkFailure());
    if (e.code == 'not-found') return left(const NotFoundFailure());
    developer.log('Firebase error', error: e, stackTrace: stackTrace, name: 'colette');
    return left(UnknownFailure(e, stackTrace));
  } catch (e, stackTrace) {
    developer.log('Unexpected error', error: e, stackTrace: stackTrace, name: 'colette');
    return left(UnknownFailure(e, stackTrace));
  }
}
```

- [ ] **Step 5: Créer `lib/core/result/either_extensions.dart`**

```dart
import 'package:fpdart/fpdart.dart';

/// Raccourcis de lecture sur `Either`.
extension EitherX<L, R> on Either<L, R> {
  /// La valeur gauche, ou `null` si c'est un `Right`.
  L? get leftOrNull => fold((l) => l, (_) => null);
}
```

- [ ] **Step 6: Créer `lib/core/clock/app_clock.dart`**

```dart
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'app_clock.g.dart';

/// Horloge injectable pour rendre les calculs de dates testables.
abstract interface class AppClock {
  DateTime now();
}

/// Horloge système.
final class SystemClock implements AppClock {
  const SystemClock();

  @override
  DateTime now() => DateTime.now();
}

/// Horloge figée, pour les tests.
final class FixedClock implements AppClock {
  const FixedClock(this.fixed);

  final DateTime fixed;

  @override
  DateTime now() => fixed;
}

/// Horloge de l'app ; surchargée par une [FixedClock] dans les tests.
@riverpod
AppClock clock(Ref ref) => const SystemClock();
```

- [ ] **Step 7: Créer `lib/core/ids/id_generator.dart`**

```dart
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:uuid/uuid.dart';

part 'id_generator.g.dart';

/// Générateur d'identifiants de documents.
abstract interface class IdGenerator {
  String newId();
}

/// UUID v4.
final class UuidIdGenerator implements IdGenerator {
  const UuidIdGenerator();

  @override
  String newId() => const Uuid().v4();
}

/// Renvoie toujours la même valeur, pour les tests.
final class FixedIdGenerator implements IdGenerator {
  const FixedIdGenerator(this.id);

  final String id;

  @override
  String newId() => id;
}

/// Générateur d'identifiants de l'app.
@riverpod
IdGenerator idGenerator(Ref ref) => const UuidIdGenerator();
```

- [ ] **Step 8: Créer `lib/core/dates/date_extensions.dart`**

```dart
/// Aides sur les jours civils (heure locale de l'appareil).
extension DateOnlyX on DateTime {
  /// Minuit du même jour.
  DateTime get dateOnly => DateTime(year, month, day);

  /// Minuit du lendemain.
  DateTime get startOfNextDay => DateTime(year, month, day + 1);

  /// `true` si [other] tombe le même jour civil.
  bool isSameDay(DateTime other) =>
      year == other.year && month == other.month && day == other.day;
}
```

- [ ] **Step 9: Créer `lib/core/firebase/firestore_paths.dart` et `firebase_providers.dart`**

`lib/core/firebase/firestore_paths.dart` :

```dart
/// Noms des collections Firestore.
abstract final class FirestorePaths {
  static const households = 'households';
  static const events = 'events';
  static const weights = 'weights';
  static const devices = 'devices';
}
```

`lib/core/firebase/firebase_providers.dart` :

```dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:shared_preferences/shared_preferences.dart';

part 'firebase_providers.g.dart';

/// Instance Firestore ; surchargée par `FakeFirebaseFirestore` en test.
/// Singleton applicatif : `keepAlive` pour pouvoir être consommé par des providers `keepAlive`.
@Riverpod(keepAlive: true)
FirebaseFirestore firestore(Ref ref) => FirebaseFirestore.instance;

/// Instance Firebase Auth.
/// Singleton applicatif : `keepAlive` pour pouvoir être consommé par des providers `keepAlive`.
@Riverpod(keepAlive: true)
FirebaseAuth firebaseAuth(Ref ref) => FirebaseAuth.instance;

/// Instance Firebase Messaging.
/// Singleton applicatif : `keepAlive` pour pouvoir être consommé par des providers `keepAlive`.
@Riverpod(keepAlive: true)
FirebaseMessaging firebaseMessaging(Ref ref) => FirebaseMessaging.instance;

/// Surchargé dans `main()` après `SharedPreferences.getInstance()`.
/// `keepAlive` : singleton applicatif, consommé par des providers `keepAlive`.
@Riverpod(keepAlive: true)
SharedPreferences sharedPreferences(Ref ref) => throw UnimplementedError(
  'sharedPreferencesProvider doit être surchargé dans main()',
);
```

- [ ] **Step 10: Créer `lib/core/firebase/anonymous_auth.dart`**

```dart
import 'dart:async';
import 'dart:developer' as developer;

import 'package:firebase_auth/firebase_auth.dart';

/// Ouvre une session anonyme si aucune n'existe, sans bloquer le démarrage
/// plus de [timeout] : hors ligne, la tentative continue en arrière-plan et
/// la prochaine ouverture réessaiera. Les échecs sont journalisés, jamais propagés.
Future<void> ensureAnonymousSession(
  FirebaseAuth auth, {
  Duration timeout = const Duration(seconds: 5),
}) async {
  if (auth.currentUser != null) return;
  try {
    await auth.signInAnonymously().timeout(timeout);
  } on TimeoutException {
    developer.log('Anonymous sign-in still pending after timeout', name: 'colette');
  } on FirebaseAuthException catch (e, stackTrace) {
    developer.log('Anonymous sign-in failed', error: e, stackTrace: stackTrace, name: 'colette');
  }
}
```

- [ ] **Step 11: Générer et tester**

Run: `dart run build_runner build -d && flutter test test/core`
Expected: `app_clock.g.dart`, `id_generator.g.dart`, `firebase_providers.g.dart` générés ; `All tests passed!`.

- [ ] **Step 12: Commit**

```bash
git add lib/core test/core
git commit -m "feat: core result/guard, horloge, ids, dates et providers Firebase"
```

---

### Task 3: Design tokens — `AppColors` et tokens dimensionnels

**Files:**
- Create: `lib/core/theme/app_colors.dart`, `lib/core/theme/design_tokens.dart`
- Test: `test/core/theme/app_colors_test.dart`

- [ ] **Step 1: Écrire le test (rouge)**

`test/core/theme/app_colors_test.dart` :

```dart
import 'package:colette/core/theme/app_colors.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  Future<Color> readPrimary(WidgetTester tester, Brightness brightness) async {
    late Color color;
    await tester.pumpWidget(
      MaterialApp(
        theme: ThemeData(brightness: brightness),
        home: Builder(
          builder: (context) {
            color = context.appColor(AppColors.primary);
            return const SizedBox();
          },
        ),
      ),
    );
    return color;
  }

  testWidgets('appColor renvoie la valeur light en thème clair', (tester) async {
    expect(await readPrimary(tester, Brightness.light), AppColors.primary.light);
  });

  testWidgets('appColor renvoie la valeur dark en thème sombre', (tester) async {
    expect(await readPrimary(tester, Brightness.dark), AppColors.primary.dark);
  });
}
```

- [ ] **Step 2: Vérifier l'échec**

Run: `flutter test test/core/theme`
Expected: échec de compilation, `app_colors.dart` introuvable.

- [ ] **Step 3: Créer `lib/core/theme/app_colors.dart`**

```dart
import 'package:flutter/material.dart';

/// Palette « Cocon cannelle ». Chaque token porte sa valeur claire et sombre.
enum AppColors {
  // Marque
  /// Cannelle : actions, accents, onglet actif.
  primary(light: Color(0xFFA8573F), dark: Color(0xFFD08A6F)),
  onPrimary(light: Color(0xFFFFFFFF), dark: Color(0xFF1C1514)),

  /// Poudre : lignes de tâches, fonds légers.
  primaryContainer(light: Color(0xFFF3E2DA), dark: Color(0xFF3A2A24)),

  /// Rose poudré : compteurs, badges.
  secondary(light: Color(0xFFE9B9A8), dark: Color(0xFF86584B)),
  onSecondary(light: Color(0xFF5C2A1B), dark: Color(0xFFF7E6E0)),

  /// Miel : fonds et décorations uniquement, jamais en texte (contraste insuffisant en clair).
  accent(light: Color(0xFFD9A441), dark: Color(0xFFE4B85C)),

  // Surfaces
  /// Lin : fond des écrans.
  pageBackground(light: Color(0xFFFBF5EF), dark: Color(0xFF1C1514)),
  surface(light: Color(0xFFFFFFFF), dark: Color(0xFF2B2220)),
  surfaceContainer(light: Color(0xFFF6EBE4), dark: Color(0xFF342925)),

  // Texte
  onSurface(light: Color(0xFF2E2320), dark: Color(0xFFF1E6E0)),
  textSecondary(light: Color(0xFF7B655E), dark: Color(0xFFB8A39B)),
  border(light: Color(0xFFEAD9CF), dark: Color(0xFF4A3A34)),

  // Sémantique
  /// Eucalyptus : fait, validé. Valeurs claires assombries pour rester lisibles en texte.
  success(light: Color(0xFF57795D), dark: Color(0xFF9DBBA2)),
  warning(light: Color(0xFF8F6412), dark: Color(0xFFE4B85C)),
  error(light: Color(0xFFC0563F), dark: Color(0xFFE27A62)),

  // Catégories de soins
  categoryFeeding(light: Color(0xFFA8573F), dark: Color(0xFFD08A6F)),
  categoryDiaper(light: Color(0xFF8F6412), dark: Color(0xFFE4B85C)),
  categoryCare(light: Color(0xFF57795D), dark: Color(0xFF9DBBA2)),
  categoryBath(light: Color(0xFFA8624F), dark: Color(0xFFC98A79)),

  shadow(light: Color(0xFF000000), dark: Color(0xFFFFFFFF));

  const AppColors({required this.light, required this.dark});

  /// Valeur en thème clair.
  final Color light;

  /// Valeur en thème sombre.
  final Color dark;

  /// Valeur selon [isDark].
  Color resolve({required bool isDark}) => isDark ? dark : light;

  /// Valeur selon le thème du [context].
  Color fromContext(BuildContext context) =>
      resolve(isDark: Theme.of(context).brightness == Brightness.dark);
}

/// Accès aux couleurs depuis un `BuildContext`.
extension BuildContextAppColors on BuildContext {
  /// Couleur du token selon le thème courant.
  Color appColor(AppColors color) => color.fromContext(this);
}
```

- [ ] **Step 4: Créer `lib/core/theme/design_tokens.dart`**

```dart
import 'package:flutter/material.dart';

/// Espacements.
enum AppSpacing {
  none(0),
  xxs(2),
  xs(4),
  sm(8),
  md(16),
  lg(24),
  xl(32),
  xxl(48),
  xxxl(64);

  const AppSpacing(this.value);

  final double value;

  EdgeInsets get all => EdgeInsets.all(value);
  EdgeInsets get horizontal => EdgeInsets.symmetric(horizontal: value);
  EdgeInsets get vertical => EdgeInsets.symmetric(vertical: value);
  EdgeInsets get top => EdgeInsets.only(top: value);
  EdgeInsets get bottom => EdgeInsets.only(bottom: value);
  EdgeInsets get left => EdgeInsets.only(left: value);
  EdgeInsets get right => EdgeInsets.only(right: value);
  Widget get verticalSpace => SizedBox(height: value);
  Widget get horizontalSpace => SizedBox(width: value);

  /// Padding avec des valeurs différentes par côté (côtés omis = 0).
  static EdgeInsets only({
    AppSpacing? left,
    AppSpacing? right,
    AppSpacing? top,
    AppSpacing? bottom,
  }) => EdgeInsets.only(
    left: left?.value ?? 0,
    right: right?.value ?? 0,
    top: top?.value ?? 0,
    bottom: bottom?.value ?? 0,
  );

  /// Padding symétrique.
  static EdgeInsets symmetric({AppSpacing? horizontal, AppSpacing? vertical}) =>
      EdgeInsets.symmetric(
        horizontal: horizontal?.value ?? 0,
        vertical: vertical?.value ?? 0,
      );
}

/// Tailles de composants (icônes, boutons, avatars).
enum AppSize {
  nano(8),
  xxs(12),
  xs(16),
  sm(24),
  md(32),
  lg(40),
  xl(48),
  xxl(56),
  xxxl(64),
  huge(80),
  massive(96);

  const AppSize(this.value);

  final double value;

  Widget get square => SizedBox(width: value, height: value);
  Size get size => Size(value, value);
}

/// Rayons de bordure.
enum AppRadius {
  none(0),
  xs(4),
  sm(8),
  md(12),
  lg(16),
  xl(20),
  xxl(24),
  round(999);

  const AppRadius(this.value);

  final double value;

  BorderRadius get circular => BorderRadius.circular(value);
  Radius get radius => Radius.circular(value);
  BorderRadius get topOnly =>
      BorderRadius.only(topLeft: radius, topRight: radius);
  BorderRadius get bottomOnly =>
      BorderRadius.only(bottomLeft: radius, bottomRight: radius);
}

/// Élévations, traduites en ombres.
enum AppElevation {
  none(0),
  low(2),
  medium(4),
  high(8);

  const AppElevation(this.value);

  final double value;

  /// Ombres correspondantes ; [shadowColor] vient de `AppColors.shadow`.
  List<BoxShadow> boxShadow(Color shadowColor) {
    if (value == 0) return const [];
    return [
      BoxShadow(
        color: shadowColor.withValues(alpha: 0.08),
        blurRadius: value * 2,
        offset: Offset(0, value / 2),
      ),
    ];
  }
}

/// Tailles de police brutes, pour les rares cas hors `ColetteTextStyle`.
enum AppFontSize {
  xs(10),
  sm(12),
  md(14),
  lg(16),
  xl(18),
  xxl(20),
  xxxl(24),
  display(32),
  hero(40);

  const AppFontSize(this.value);

  final double value;
}

/// Durées d'animation.
enum AppDuration {
  fast(Duration(milliseconds: 150)),
  normal(Duration(milliseconds: 250)),
  slow(Duration(milliseconds: 350));

  const AppDuration(this.value);

  final Duration value;
}

/// Opacités courantes.
enum AppOpacity {
  veryLight(0.1),
  light(0.25),
  medium(0.5),
  strong(0.75);

  const AppOpacity(this.value);

  final double value;

  /// Applique cette opacité à [color].
  Color applyTo(Color color) => color.withValues(alpha: value);
}
```

- [ ] **Step 5: Vérifier le test**

Run: `flutter test test/core/theme`
Expected: `All tests passed!`

- [ ] **Step 6: Commit**

```bash
git add lib/core/theme test/core/theme
git commit -m "feat: tokens de design AppColors, AppSpacing, AppRadius, AppSize"
```

---

### Task 4: Styles de texte et `ThemeService`

**Files:**
- Create: `lib/core/theme/text_styles.dart`, `lib/core/theme/theme_service.dart`
- Create: `test/flutter_test_config.dart`
- Test: `test/core/theme/theme_service_test.dart`

- [ ] **Step 1: Créer `test/flutter_test_config.dart` (désactive le téléchargement des polices en test)**

```dart
import 'dart:async';

import 'package:google_fonts/google_fonts.dart';
import 'package:intl/date_symbol_data_local.dart';

Future<void> testExecutable(FutureOr<void> Function() testMain) async {
  GoogleFonts.config.allowRuntimeFetching = false;
  await initializeDateFormatting('fr');
  await testMain();
}
```

- [ ] **Step 2: Écrire le test (rouge)**

`test/core/theme/theme_service_test.dart` :

```dart
import 'package:colette/core/theme/app_colors.dart';
import 'package:colette/core/theme/theme_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const service = ThemeService();

  test('le thème clair utilise les tokens light', () {
    final theme = service.light();
    expect(theme.brightness, Brightness.light);
    expect(theme.scaffoldBackgroundColor, AppColors.pageBackground.light);
    expect(theme.colorScheme.primary, AppColors.primary.light);
  });

  test('le thème sombre utilise les tokens dark', () {
    final theme = service.dark();
    expect(theme.brightness, Brightness.dark);
    expect(theme.scaffoldBackgroundColor, AppColors.pageBackground.dark);
    expect(theme.colorScheme.primary, AppColors.primary.dark);
  });

  test('les styles Colette sont accessibles depuis ThemeData', () {
    final theme = service.light();
    expect(theme.coletteTextStyles.heading1.fontSize, 26);
    expect(theme.coletteTextStyles.body.fontSize, 14);
  });
}
```

- [ ] **Step 3: Vérifier l'échec**

Run: `flutter test test/core/theme/theme_service_test.dart`
Expected: échec de compilation, `theme_service.dart` introuvable.

- [ ] **Step 4: Créer `lib/core/theme/text_styles.dart`**

```dart
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Styles de texte Colette : titres et nombres en Fraunces, corps en DM Sans.
enum ColetteTextStyle {
  displayTitle,
  heading1,
  heading2,
  heading3,
  numberLarge,
  numberMedium,
  bodyLarge,
  body,
  bodyMedium,
  label,
  small,
  overline;

  TextStyle get textStyle => switch (this) {
    ColetteTextStyle.displayTitle => GoogleFonts.fraunces(fontSize: 32, fontWeight: .w600, height: 1.15),
    ColetteTextStyle.heading1 => GoogleFonts.fraunces(fontSize: 26, fontWeight: .w600, height: 1.2),
    ColetteTextStyle.heading2 => GoogleFonts.fraunces(fontSize: 20, fontWeight: .w600, height: 1.2),
    ColetteTextStyle.heading3 => GoogleFonts.fraunces(fontSize: 17, fontWeight: .w600, height: 1.2),
    ColetteTextStyle.numberLarge => GoogleFonts.fraunces(fontSize: 40, fontWeight: .w600, height: 1.0),
    ColetteTextStyle.numberMedium => GoogleFonts.fraunces(fontSize: 24, fontWeight: .w600, height: 1.0),
    ColetteTextStyle.bodyLarge => GoogleFonts.dmSans(fontSize: 16, fontWeight: .w400, height: 1.4),
    ColetteTextStyle.body => GoogleFonts.dmSans(fontSize: 14, fontWeight: .w400, height: 1.4),
    ColetteTextStyle.bodyMedium => GoogleFonts.dmSans(fontSize: 14, fontWeight: .w500, height: 1.4),
    ColetteTextStyle.label => GoogleFonts.dmSans(fontSize: 13, fontWeight: .w500, height: 1.3),
    ColetteTextStyle.small => GoogleFonts.dmSans(fontSize: 12, fontWeight: .w400, height: 1.3),
    ColetteTextStyle.overline => GoogleFonts.dmSans(fontSize: 11, fontWeight: .w500, height: 1.3, letterSpacing: 0.66),
  };
}

/// Accès nommé aux styles : `Theme.of(context).coletteTextStyles.heading1`.
class ColetteTextStyles {
  const ColetteTextStyles();

  TextStyle get displayTitle => ColetteTextStyle.displayTitle.textStyle;
  TextStyle get heading1 => ColetteTextStyle.heading1.textStyle;
  TextStyle get heading2 => ColetteTextStyle.heading2.textStyle;
  TextStyle get heading3 => ColetteTextStyle.heading3.textStyle;
  TextStyle get numberLarge => ColetteTextStyle.numberLarge.textStyle;
  TextStyle get numberMedium => ColetteTextStyle.numberMedium.textStyle;
  TextStyle get bodyLarge => ColetteTextStyle.bodyLarge.textStyle;
  TextStyle get body => ColetteTextStyle.body.textStyle;
  TextStyle get bodyMedium => ColetteTextStyle.bodyMedium.textStyle;
  TextStyle get label => ColetteTextStyle.label.textStyle;
  TextStyle get small => ColetteTextStyle.small.textStyle;
  TextStyle get overline => ColetteTextStyle.overline.textStyle;
}

/// Expose [ColetteTextStyles] sur `ThemeData`.
extension ColetteTextStylesX on ThemeData {
  ColetteTextStyles get coletteTextStyles => const ColetteTextStyles();
}
```

- [ ] **Step 5: Créer `lib/core/theme/theme_service.dart`**

```dart
import 'package:colette/core/theme/app_colors.dart';
import 'package:colette/core/theme/design_tokens.dart';
import 'package:colette/core/theme/text_styles.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Construit les `ThemeData` clair et sombre à partir des tokens.
class ThemeService {
  const ThemeService();

  ThemeData light() => _build(Brightness.light);

  ThemeData dark() => _build(Brightness.dark);

  ThemeData _build(Brightness brightness) {
    final isDark = brightness == Brightness.dark;
    Color c(AppColors color) => color.resolve(isDark: isDark);

    final colorScheme = ColorScheme(
      brightness: brightness,
      primary: c(AppColors.primary),
      onPrimary: c(AppColors.onPrimary),
      primaryContainer: c(AppColors.primaryContainer),
      onPrimaryContainer: c(AppColors.onSurface),
      secondary: c(AppColors.secondary),
      onSecondary: c(AppColors.onSecondary),
      error: c(AppColors.error),
      onError: c(AppColors.onPrimary),
      surface: c(AppColors.surface),
      onSurface: c(AppColors.onSurface),
      surfaceContainerHighest: c(AppColors.surfaceContainer),
      outline: c(AppColors.border),
    );

    final base = ThemeData(brightness: brightness).textTheme;
    final textTheme = GoogleFonts.dmSansTextTheme(base).apply(
      bodyColor: c(AppColors.onSurface),
      displayColor: c(AppColors.onSurface),
    );

    return ThemeData(
      useMaterial3: true,
      brightness: brightness,
      colorScheme: colorScheme,
      scaffoldBackgroundColor: c(AppColors.pageBackground),
      textTheme: textTheme,
      appBarTheme: AppBarTheme(
        backgroundColor: c(AppColors.pageBackground),
        foregroundColor: c(AppColors.onSurface),
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: false,
        titleTextStyle: ColetteTextStyle.heading1.textStyle.copyWith(
          color: c(AppColors.onSurface),
        ),
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: c(AppColors.surface),
        indicatorColor: c(AppColors.primaryContainer),
        labelTextStyle: WidgetStateProperty.resolveWith(
          (states) => ColetteTextStyle.label.textStyle.copyWith(
            color: states.contains(WidgetState.selected)
                ? c(AppColors.primary)
                : c(AppColors.textSecondary),
          ),
        ),
        iconTheme: WidgetStateProperty.resolveWith(
          (states) => IconThemeData(
            color: states.contains(WidgetState.selected)
                ? c(AppColors.primary)
                : c(AppColors.textSecondary),
          ),
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: c(AppColors.primary),
          foregroundColor: c(AppColors.onPrimary),
          minimumSize: Size.fromHeight(AppSize.xl.value),
          shape: RoundedRectangleBorder(borderRadius: AppRadius.lg.circular),
          textStyle: ColetteTextStyle.bodyMedium.textStyle,
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: c(AppColors.primary),
          side: BorderSide(color: c(AppColors.primary)),
          minimumSize: Size.fromHeight(AppSize.xl.value),
          shape: RoundedRectangleBorder(borderRadius: AppRadius.lg.circular),
          textStyle: ColetteTextStyle.bodyMedium.textStyle,
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: c(AppColors.primary),
          textStyle: ColetteTextStyle.bodyMedium.textStyle,
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: c(AppColors.surfaceContainer),
        border: OutlineInputBorder(
          borderRadius: AppRadius.md.circular,
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: AppRadius.md.circular,
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: AppRadius.md.circular,
          borderSide: BorderSide(color: c(AppColors.primary), width: 1.5),
        ),
        contentPadding: AppSpacing.md.all,
        labelStyle: ColetteTextStyle.label.textStyle.copyWith(
          color: c(AppColors.textSecondary),
        ),
      ),
      bottomSheetTheme: BottomSheetThemeData(
        backgroundColor: c(AppColors.pageBackground),
        shape: RoundedRectangleBorder(borderRadius: AppRadius.xxl.topOnly),
        showDragHandle: true,
      ),
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: c(AppColors.primary),
        foregroundColor: c(AppColors.onPrimary),
        shape: RoundedRectangleBorder(borderRadius: AppRadius.lg.circular),
      ),
      dividerTheme: DividerThemeData(color: c(AppColors.border), thickness: 1),
      chipTheme: ChipThemeData(
        backgroundColor: c(AppColors.surface),
        selectedColor: c(AppColors.primaryContainer),
        side: BorderSide(color: c(AppColors.border)),
        shape: RoundedRectangleBorder(borderRadius: AppRadius.round.circular),
        labelStyle: ColetteTextStyle.bodyMedium.textStyle.copyWith(color: c(AppColors.onSurface)),
        secondaryLabelStyle: ColetteTextStyle.bodyMedium.textStyle.copyWith(color: c(AppColors.onSurface)),
        checkmarkColor: c(AppColors.primary),
        padding: AppSpacing.symmetric(horizontal: AppSpacing.sm, vertical: AppSpacing.xs),
      ),
      snackBarTheme: const SnackBarThemeData(behavior: SnackBarBehavior.floating),
      switchTheme: SwitchThemeData(
        thumbColor: WidgetStateProperty.resolveWith(
          (states) => states.contains(WidgetState.selected)
              ? c(AppColors.onPrimary)
              : c(AppColors.textSecondary),
        ),
        trackColor: WidgetStateProperty.resolveWith(
          (states) => states.contains(WidgetState.selected)
              ? c(AppColors.primary)
              : c(AppColors.border),
        ),
        trackOutlineColor: const WidgetStatePropertyAll(Colors.transparent),
      ),
    );
  }
}
```

- [ ] **Step 6: Vérifier le test**

Run: `flutter test test/core/theme`
Expected: `All tests passed!`

- [ ] **Step 7: Commit**

```bash
git add lib/core/theme test
git commit -m "feat: styles de texte Fraunces/DM Sans et ThemeService"
```

---

### Task 5: Domaine partagé `CareType`, widgets partagés, helpers de test

**Files:**
- Create: `lib/shared/domain/care_type.dart`, `lib/shared/ui/care_type_ui.dart`
- Create: `lib/shared/ui/widgets/colette_card_surface.dart`, `section_header.dart`, `empty_state.dart`, `care_chip.dart`, `offline_banner.dart`, `int_stepper_row.dart`
- Create: `lib/core/connectivity/connectivity_provider.dart`, `lib/core/ui/failure_message.dart`, `lib/core/ui/date_time_picker.dart`
- Create: `test/helpers/pump_app.dart`
- Test: `test/shared/ui/widgets/care_chip_test.dart`, `test/shared/ui/widgets/int_stepper_row_test.dart`

- [ ] **Step 1: Créer `lib/shared/domain/care_type.dart`**

```dart
/// Catégorie d'un soin, pour la couleur et l'icône.
enum CareCategory { feeding, diaper, care, bath }

/// Soins cochables dans un événement.
enum CareType {
  pee(CareCategory.diaper),
  poop(CareCategory.diaper),
  diaperChange(CareCategory.diaper),
  adrigyl(CareCategory.care),
  bath(CareCategory.bath),
  eyeCare(CareCategory.care),
  noseCare(CareCategory.care),
  umbilicalCare(CareCategory.care);

  const CareType(this.category);

  final CareCategory category;
}
```

- [ ] **Step 2: Créer `lib/core/connectivity/connectivity_provider.dart`**

```dart
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'connectivity_provider.g.dart';

bool _hasNetwork(List<ConnectivityResult> results) =>
    results.isNotEmpty && !results.contains(ConnectivityResult.none);

/// `true` tant qu'au moins une interface réseau est disponible.
/// Émet d'abord l'état courant, puis chaque changement.
@riverpod
Stream<bool> isOnline(Ref ref) async* {
  final connectivity = Connectivity();
  yield _hasNetwork(await connectivity.checkConnectivity());
  yield* connectivity.onConnectivityChanged.map(_hasNetwork);
}
```

- [ ] **Step 3: Créer `test/helpers/pump_app.dart`**

```dart
import 'package:colette/core/connectivity/connectivity_provider.dart';
import 'package:colette/core/theme/theme_service.dart';
import 'package:colette/l10n/generated/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

/// Monte [child] dans une `MaterialApp` fr avec le thème Colette
/// et un `ProviderScope` surchargeable.
Future<void> pumpApp(
  WidgetTester tester,
  Widget child, {
  List<Override> overrides = const [],
}) async {
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        isOnlineProvider.overrideWith((ref) => Stream.value(true)),
        ...overrides,
      ],
      child: MaterialApp(
        theme: const ThemeService().light(),
        locale: const Locale('fr'),
        localizationsDelegates: S.localizationsDelegates,
        supportedLocales: S.supportedLocales,
        home: child,
      ),
    ),
  );
  await tester.pumpAndSettle();
}
```

- [ ] **Step 4: Écrire les tests de widgets (rouges)**

`test/shared/ui/widgets/care_chip_test.dart` :

```dart
import 'package:colette/shared/domain/care_type.dart';
import 'package:colette/shared/ui/widgets/care_chip.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../helpers/pump_app.dart';

void main() {
  testWidgets('CareChip affiche le libellé et appelle onChanged au tap', (tester) async {
    bool? received;
    await pumpApp(
      tester,
      Scaffold(
        body: CareChip(
          type: CareType.adrigyl,
          selected: false,
          onChanged: (value) => received = value,
        ),
      ),
    );
    expect(find.text('Adrigyl'), findsOneWidget);
    await tester.tap(find.byType(CareChip));
    expect(received, isTrue);
  });
}
```

`test/shared/ui/widgets/int_stepper_row_test.dart` :

```dart
import 'package:colette/shared/ui/widgets/int_stepper_row.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../helpers/pump_app.dart';

void main() {
  testWidgets('IntStepperRow respecte min et max', (tester) async {
    var value = 1;
    await pumpApp(
      tester,
      StatefulBuilder(
        builder: (context, setState) => Scaffold(
          body: IntStepperRow(
            label: 'Adrigyl par jour',
            value: value,
            min: 0,
            max: 2,
            onChanged: (v) => setState(() => value = v),
          ),
        ),
      ),
    );
    await tester.tap(find.byIcon(Icons.add));
    await tester.pump();
    expect(value, 2);
    await tester.tap(find.byIcon(Icons.add));
    await tester.pump();
    expect(value, 2);
    await tester.tap(find.byIcon(Icons.remove));
    await tester.pump();
    expect(value, 1);
  });
}
```

- [ ] **Step 5: Vérifier l'échec**

Run: `flutter test test/shared`
Expected: échec de compilation, `care_chip.dart` introuvable.

- [ ] **Step 6: Créer `lib/shared/ui/care_type_ui.dart`**

```dart
import 'package:colette/core/theme/app_colors.dart';
import 'package:colette/l10n/generated/app_localizations.dart';
import 'package:colette/shared/domain/care_type.dart';
import 'package:flutter/material.dart';

/// Rendu d'un [CareType] : icône, libellé, couleur.
extension CareTypeUi on CareType {
  IconData get icon => switch (this) {
    CareType.pee => Icons.water_drop_outlined,
    CareType.poop => Icons.cloud_outlined,
    CareType.diaperChange => Icons.baby_changing_station,
    CareType.adrigyl => Icons.medication_liquid_outlined,
    CareType.bath => Icons.bathtub_outlined,
    CareType.eyeCare => Icons.visibility_outlined,
    CareType.noseCare => Icons.air,
    CareType.umbilicalCare => Icons.healing_outlined,
  };

  String label(S s) => switch (this) {
    CareType.pee => s.carePee,
    CareType.poop => s.carePoop,
    CareType.diaperChange => s.careDiaperChange,
    CareType.adrigyl => s.careAdrigyl,
    CareType.bath => s.careBath,
    CareType.eyeCare => s.careEyeCare,
    CareType.noseCare => s.careNoseCare,
    CareType.umbilicalCare => s.careUmbilicalCare,
  };

  AppColors get color => category.color;
}

/// Couleur d'une catégorie de soin.
extension CareCategoryUi on CareCategory {
  AppColors get color => switch (this) {
    CareCategory.feeding => AppColors.categoryFeeding,
    CareCategory.diaper => AppColors.categoryDiaper,
    CareCategory.care => AppColors.categoryCare,
    CareCategory.bath => AppColors.categoryBath,
  };
}
```

- [ ] **Step 7: Créer les widgets partagés**

`lib/shared/ui/widgets/colette_card_surface.dart` :

```dart
import 'package:colette/core/theme/app_colors.dart';
import 'package:colette/core/theme/design_tokens.dart';
import 'package:flutter/material.dart';

/// Carte : fond `surface`, bordure `border`, rayon `AppRadius.lg`.
class ColetteCardSurface extends StatelessWidget {
  const ColetteCardSurface({
    super.key,
    required this.child,
    this.padding,
    this.backgroundColor = AppColors.surface,
    this.borderColor = AppColors.border,
    this.radius = AppRadius.lg,
    this.onTap,
  });

  final Widget child;
  final EdgeInsetsGeometry? padding;
  final AppColors backgroundColor;
  final AppColors borderColor;
  final AppRadius radius;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final content = Padding(padding: padding ?? AppSpacing.md.all, child: child);
    return Material(
      color: context.appColor(backgroundColor),
      shape: RoundedRectangleBorder(
        borderRadius: radius.circular,
        side: BorderSide(color: context.appColor(borderColor)),
      ),
      clipBehavior: Clip.antiAlias,
      child: onTap == null ? content : InkWell(onTap: onTap, child: content),
    );
  }
}

/// Enveloppe n'importe quel widget dans une [ColetteCardSurface].
extension ColetteCardSurfaceX on Widget {
  Widget withCardSurface({EdgeInsetsGeometry? padding, VoidCallback? onTap}) =>
      ColetteCardSurface(padding: padding, onTap: onTap, child: this);
}
```

`lib/shared/ui/widgets/section_header.dart` :

```dart
import 'package:colette/core/theme/app_colors.dart';
import 'package:colette/core/theme/design_tokens.dart';
import 'package:colette/core/theme/text_styles.dart';
import 'package:flutter/material.dart';

/// Titre de section en Fraunces, avec action optionnelle à droite.
class SectionHeader extends StatelessWidget {
  const SectionHeader({super.key, required this.title, this.trailing});

  final String title;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: AppSpacing.only(top: AppSpacing.lg, bottom: AppSpacing.sm),
      child: Row(
        children: [
          Expanded(
            child: Text(
              title,
              style: Theme.of(context).coletteTextStyles.heading3.copyWith(
                color: context.appColor(AppColors.textSecondary),
              ),
            ),
          ),
          ?trailing,
        ],
      ),
    );
  }
}
```

`lib/shared/ui/widgets/empty_state.dart` :

```dart
import 'package:colette/core/theme/app_colors.dart';
import 'package:colette/core/theme/design_tokens.dart';
import 'package:colette/core/theme/text_styles.dart';
import 'package:flutter/material.dart';

/// État vide : icône et message centrés.
class EmptyState extends StatelessWidget {
  const EmptyState({super.key, required this.icon, required this.message});

  final IconData icon;
  final String message;

  @override
  Widget build(BuildContext context) {
    final secondary = context.appColor(AppColors.textSecondary);
    return Center(
      child: Padding(
        padding: AppSpacing.xl.all,
        child: Column(
          mainAxisSize: .min,
          children: [
            Icon(icon, size: AppSize.xl.value, color: secondary),
            AppSpacing.md.verticalSpace,
            Text(
              message,
              textAlign: .center,
              style: Theme.of(context).coletteTextStyles.body.copyWith(color: secondary),
            ),
          ],
        ),
      ),
    );
  }
}
```

`lib/shared/ui/widgets/care_chip.dart` :

```dart
import 'package:colette/core/theme/app_colors.dart';
import 'package:colette/core/theme/design_tokens.dart';
import 'package:colette/core/theme/text_styles.dart';
import 'package:colette/l10n/generated/app_localizations.dart';
import 'package:colette/shared/domain/care_type.dart';
import 'package:colette/shared/ui/care_type_ui.dart';
import 'package:flutter/material.dart';

/// Puce à cocher pour un soin : icône + libellé, colorée quand sélectionnée.
class CareChip extends StatelessWidget {
  const CareChip({
    super.key,
    required this.type,
    required this.selected,
    required this.onChanged,
  });

  final CareType type;
  final bool selected;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    final accent = context.appColor(type.color);
    final background = selected ? accent : context.appColor(AppColors.surface);
    final foreground = selected
        ? context.appColor(AppColors.onPrimary)
        : context.appColor(AppColors.onSurface);
    return Material(
      color: background,
      shape: RoundedRectangleBorder(
        borderRadius: AppRadius.round.circular,
        side: BorderSide(color: selected ? accent : context.appColor(AppColors.border)),
      ),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () => onChanged(!selected),
        child: Padding(
          padding: AppSpacing.symmetric(horizontal: AppSpacing.md, vertical: AppSpacing.sm),
          child: Row(
            mainAxisSize: .min,
            spacing: AppSpacing.xs.value,
            children: [
              Icon(type.icon, size: AppSize.xs.value, color: foreground),
              Text(
                type.label(S.of(context)),
                style: Theme.of(context).coletteTextStyles.bodyMedium.copyWith(color: foreground),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
```

`lib/shared/ui/widgets/offline_banner.dart` :

```dart
import 'package:colette/core/connectivity/connectivity_provider.dart';
import 'package:colette/core/theme/app_colors.dart';
import 'package:colette/core/theme/design_tokens.dart';
import 'package:colette/core/theme/text_styles.dart';
import 'package:colette/l10n/generated/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Bandeau discret affiché quand l'appareil est hors ligne.
class OfflineBanner extends ConsumerWidget {
  const OfflineBanner({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final online = ref.watch(isOnlineProvider).value ?? true;
    if (online) return const SizedBox.shrink();
    return ColoredBox(
      color: context.appColor(AppColors.primaryContainer),
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: AppSpacing.symmetric(horizontal: AppSpacing.md, vertical: AppSpacing.xs),
          child: Text(
            S.of(context).offlineBanner,
            textAlign: .center,
            style: Theme.of(context).coletteTextStyles.small.copyWith(
              color: context.appColor(AppColors.onSurface),
            ),
          ),
        ),
      ),
    );
  }
}
```

`lib/shared/ui/widgets/int_stepper_row.dart` :

```dart
import 'package:colette/core/theme/app_colors.dart';
import 'package:colette/core/theme/design_tokens.dart';
import 'package:colette/core/theme/text_styles.dart';
import 'package:flutter/material.dart';

/// Ligne « libellé … [-] valeur [+] » bornée par [min] et [max].
class IntStepperRow extends StatelessWidget {
  const IntStepperRow({
    super.key,
    required this.label,
    required this.value,
    required this.min,
    required this.max,
    required this.onChanged,
    this.step = 1,
    this.suffix,
  });

  final String label;
  final int value;
  final int min;
  final int max;
  final int step;
  final String? suffix;
  final ValueChanged<int> onChanged;

  @override
  Widget build(BuildContext context) {
    final styles = Theme.of(context).coletteTextStyles;
    return Row(
      children: [
        Expanded(child: Text(label, style: styles.body)),
        IconButton(
          onPressed: value - step >= min ? () => onChanged(value - step) : null,
          icon: const Icon(Icons.remove),
          color: context.appColor(AppColors.primary),
        ),
        Text(
          suffix == null ? '$value' : '$value $suffix',
          style: styles.numberMedium.copyWith(color: context.appColor(AppColors.onSurface)),
        ),
        IconButton(
          onPressed: value + step <= max ? () => onChanged(value + step) : null,
          icon: const Icon(Icons.add),
          color: context.appColor(AppColors.primary),
        ),
        AppSpacing.xs.horizontalSpace,
      ],
    );
  }
}
```

- [ ] **Step 8: Créer `lib/core/ui/failure_message.dart` et `lib/core/ui/date_time_picker.dart`**

`lib/core/ui/failure_message.dart` :

```dart
import 'package:colette/core/result/failure.dart';
import 'package:colette/l10n/generated/app_localizations.dart';

/// Texte affichable pour une [Failure].
String failureMessage(Object failure, S s) => switch (failure) {
  NetworkFailure() => s.errorNetwork,
  NotFoundFailure() => s.errorNotFound,
  ValidationFailure(:final reason) => switch (reason) {
    ValidationReason.emptyEvent => s.errorEmptyEvent,
    ValidationReason.endBeforeStart => s.errorEndBeforeStart,
    ValidationReason.startInFuture => s.errorStartInFuture,
    ValidationReason.bottleOutOfRange => s.errorBottleOutOfRange,
    ValidationReason.invalidWeight => s.errorInvalidWeight,
    ValidationReason.emptyName => s.errorEmptyName,
    ValidationReason.unknownHouseholdCode => s.errorUnknownCode,
  },
  _ => s.errorUnknown,
};
```

`lib/core/ui/date_time_picker.dart` :

```dart
import 'package:colette/core/theme/design_tokens.dart';
import 'package:colette/l10n/generated/app_localizations.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

/// Ouvre un sélecteur Cupertino et renvoie la date choisie, ou `null`.
Future<DateTime?> showColetteDateTimePicker(
  BuildContext context, {
  required DateTime initial,
  required CupertinoDatePickerMode mode,
  DateTime? maximum,
  DateTime? minimum,
}) {
  var safeInitial = initial;
  if (maximum != null && safeInitial.isAfter(maximum)) safeInitial = maximum;
  if (minimum != null && safeInitial.isBefore(minimum)) safeInitial = minimum;
  var selected = safeInitial;
  return showModalBottomSheet<DateTime>(
    context: context,
    builder: (sheetContext) => SafeArea(
      child: Column(
        mainAxisSize: .min,
        children: [
          SizedBox(
            height: AppSize.massive.value * 2,
            child: CupertinoDatePicker(
              mode: mode,
              initialDateTime: safeInitial,
              maximumDate: maximum,
              minimumDate: minimum,
              use24hFormat: true,
              onDateTimeChanged: (value) => selected = value,
            ),
          ),
          Padding(
            padding: AppSpacing.md.all,
            child: FilledButton(
              onPressed: () => Navigator.of(sheetContext).pop(selected),
              child: Text(S.of(sheetContext).actionChoose),
            ),
          ),
        ],
      ),
    ),
  );
}
```

**Note post-revue (appliquée dans le code) :** `IntStepperRow` porte des `tooltip` (`actionDecrease` / `actionIncrease`) sur ses boutons ; `CareChip` garantit une hauteur tactile de `AppSize.xl` via `ConstrainedBox` ; `showColetteDateTimePicker` borne `initial` à `maximum` ; tests supplémentaires : `test/core/ui/failure_message_test.dart`, `test/shared/ui/widgets/offline_banner_test.dart` ; `pumpApp` n'ajoute son override `isOnlineProvider` que si l'appelant n'en fournit pas déjà un.

- [ ] **Step 9: Générer, analyser, tester**

Run: `dart run build_runner build -d && dart format lib test && dart analyze && flutter test test/shared`
Expected: `No issues found!` puis `All tests passed!`.

- [ ] **Step 10: Commit**

```bash
git add lib/shared lib/core test/helpers test/shared test/flutter_test_config.dart
git commit -m "feat: CareType, widgets partagés (carte, puce, stepper, bandeau hors ligne), helpers de test"
```

---

### Task 6: Entités du domaine (baby, events, household)

**Files:**
- Create: `lib/features/baby/domain/entities/care_settings.dart`, `baby_profile.dart`, `weight_entry.dart`, `feeding_plan_snapshot.dart`
- Create: `lib/features/events/domain/entities/care_event.dart`
- Create: `lib/features/household/domain/entities/household.dart`, `device_info.dart`
- Test: `test/features/events/domain/entities/care_event_test.dart`

- [ ] **Step 1: Écrire le test (rouge)**

`test/features/events/domain/entities/care_event_test.dart` :

```dart
import 'package:colette/features/events/domain/entities/care_event.dart';
import 'package:colette/shared/domain/care_type.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  final now = DateTime(2026, 9, 21, 14, 30);
  final empty = CareEvent(
    id: 'e1',
    startAt: now,
    endAt: now,
    createdByDeviceId: 'd1',
    createdAt: now,
    updatedAt: now,
  );

  test('un événement sans soin ni biberon est vide', () {
    expect(empty.isEmpty, isTrue);
    expect(empty.checkedCares, isEmpty);
  });

  test('toggle coche un soin et checkedCares le liste', () {
    final withAdrigyl = empty.toggle(CareType.adrigyl, true);
    expect(withAdrigyl.has(CareType.adrigyl), isTrue);
    expect(withAdrigyl.checkedCares, [CareType.adrigyl]);
    expect(withAdrigyl.isEmpty, isFalse);
  });

  test('un biberon seul rend l\'événement non vide', () {
    final withBottle = empty.copyWith(bottleMl: 120);
    expect(withBottle.hasBottle, isTrue);
    expect(withBottle.isEmpty, isFalse);
  });
}
```

- [ ] **Step 2: Vérifier l'échec**

Run: `flutter test test/features/events`
Expected: échec de compilation, `care_event.dart` introuvable.

- [ ] **Step 3: Créer les entités baby**

`lib/features/baby/domain/entities/care_settings.dart` :

```dart
import 'package:freezed_annotation/freezed_annotation.dart';

part 'care_settings.freezed.dart';

/// Fréquences des soins attendus chaque jour.
@freezed
abstract class CareSettings with _$CareSettings {
  const factory CareSettings({
    @Default(1) int adrigylPerDay,
    @Default(1) int eyeCarePerDay,
    @Default(1) int noseCarePerDay,
    @Default(true) bool umbilicalCareEnabled,
    @Default(2) int bathEveryDays,
    @Default(8) int feedsPerDay,
  }) = _CareSettings;
}
```

`lib/features/baby/domain/entities/baby_profile.dart` :

```dart
import 'package:colette/features/baby/domain/entities/care_settings.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

part 'baby_profile.freezed.dart';

/// Profil du bébé.
@freezed
abstract class BabyProfile with _$BabyProfile {
  const factory BabyProfile({
    required String name,
    required DateTime birthDate,
    DateTime? cordFallenAt,
    @Default(CareSettings()) CareSettings careSettings,
  }) = _BabyProfile;
}
```

`lib/features/baby/domain/entities/weight_entry.dart` :

```dart
import 'package:freezed_annotation/freezed_annotation.dart';

part 'weight_entry.freezed.dart';

/// Une pesée.
@freezed
abstract class WeightEntry with _$WeightEntry {
  const factory WeightEntry({
    required String id,
    required DateTime measuredAt,
    required int grams,
  }) = _WeightEntry;
}
```

`lib/features/baby/domain/entities/feeding_plan_snapshot.dart` :

```dart
import 'package:freezed_annotation/freezed_annotation.dart';

part 'feeding_plan_snapshot.freezed.dart';

/// Résumé du plan biberons écrit dans le foyer, lu par les Cloud Functions.
@freezed
abstract class FeedingPlanSnapshot with _$FeedingPlanSnapshot {
  const factory FeedingPlanSnapshot({
    required DateTime nextBottleAt,
    required int suggestedMl,
    required DateTime computedAt,
  }) = _FeedingPlanSnapshot;
}
```

- [ ] **Step 4: Créer `lib/features/events/domain/entities/care_event.dart`**

```dart
import 'package:colette/shared/domain/care_type.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

part 'care_event.freezed.dart';

/// Un événement de soin : une plage horaire et des soins cochés.
@freezed
abstract class CareEvent with _$CareEvent {
  const CareEvent._();

  const factory CareEvent({
    required String id,
    required DateTime startAt,
    required DateTime endAt,
    @Default(false) bool pee,
    @Default(false) bool poop,
    @Default(false) bool diaperChange,
    @Default(false) bool adrigyl,
    @Default(false) bool bath,
    @Default(false) bool eyeCare,
    @Default(false) bool noseCare,
    @Default(false) bool umbilicalCare,
    int? bottleMl,
    String? note,
    required String createdByDeviceId,
    required DateTime createdAt,
    required DateTime updatedAt,
  }) = _CareEvent;

  /// `true` si [type] est coché.
  bool has(CareType type) => switch (type) {
    CareType.pee => pee,
    CareType.poop => poop,
    CareType.diaperChange => diaperChange,
    CareType.adrigyl => adrigyl,
    CareType.bath => bath,
    CareType.eyeCare => eyeCare,
    CareType.noseCare => noseCare,
    CareType.umbilicalCare => umbilicalCare,
  };

  /// Copie avec [type] mis à [value].
  CareEvent toggle(CareType type, bool value) => switch (type) {
    CareType.pee => copyWith(pee: value),
    CareType.poop => copyWith(poop: value),
    CareType.diaperChange => copyWith(diaperChange: value),
    CareType.adrigyl => copyWith(adrigyl: value),
    CareType.bath => copyWith(bath: value),
    CareType.eyeCare => copyWith(eyeCare: value),
    CareType.noseCare => copyWith(noseCare: value),
    CareType.umbilicalCare => copyWith(umbilicalCare: value),
  };

  bool get hasBottle => bottleMl != null;

  List<CareType> get checkedCares => CareType.values.where(has).toList();

  bool get isEmpty => checkedCares.isEmpty && !hasBottle;
}
```

- [ ] **Step 5: Créer les entités household**

`lib/features/household/domain/entities/household.dart` :

```dart
import 'package:freezed_annotation/freezed_annotation.dart';

part 'household.freezed.dart';

/// Un foyer, identifié par son code.
@freezed
abstract class Household with _$Household {
  const factory Household({required String code, required DateTime createdAt}) =
      _Household;
}
```

`lib/features/household/domain/entities/device_info.dart` :

```dart
import 'package:freezed_annotation/freezed_annotation.dart';

part 'device_info.freezed.dart';

/// Un iPhone membre du foyer et ses préférences de notification.
@freezed
abstract class DeviceInfo with _$DeviceInfo {
  const factory DeviceInfo({
    required String id,
    required String label,
    String? fcmToken,
    @Default(true) bool notifyOnOthersEvents,
    @Default(true) bool notifyBottleReminder,
    @Default(true) bool notifyMorningDigest,
    @Default(8) int morningDigestHour,
  }) = _DeviceInfo;
}
```

- [ ] **Step 6: Générer et tester**

Run: `dart run build_runner build -d && flutter test test/features/events`
Expected: fichiers `*.freezed.dart` générés ; `All tests passed!`.

- [ ] **Step 7: Commit**

```bash
git add lib/features test/features
git commit -m "feat: entités freezed CareEvent, BabyProfile, CareSettings, WeightEntry, Household, DeviceInfo"
```

---

### Task 7: Feature household — code foyer, stockage local, repositories, providers

**Files:**
- Create: `lib/features/household/domain/household_code_generator.dart`
- Create: `lib/features/household/domain/repositories/household_repository.dart`, `device_repository.dart`, `household_local_store.dart`
- Create: `lib/features/household/data/prefs_household_local_store.dart`, `firestore_household_repository.dart`, `firestore_device_repository.dart`, `dtos/device_info_dto.dart`
- Create: `lib/features/household/presentation/providers/household_providers.dart`
- Create: `test/helpers/in_memory_household_local_store.dart`
- Test: `test/features/household/domain/household_code_generator_test.dart`, `test/features/household/data/prefs_household_local_store_test.dart`, `test/features/household/data/firestore_household_repository_test.dart`, `test/features/household/data/firestore_device_repository_test.dart`

- [ ] **Step 1: Écrire les tests (rouges)**

`test/features/household/domain/household_code_generator_test.dart` :

```dart
import 'dart:math';

import 'package:colette/features/household/domain/household_code_generator.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('génère 8 caractères de l\'alphabet sans ambiguïté', () {
    final code = HouseholdCodeGenerator().generate();
    expect(code.length, 8);
    expect(code.split('').every(HouseholdCodeGenerator.alphabet.contains), isTrue);
  });

  test('est déterministe avec un Random seedé', () {
    final a = HouseholdCodeGenerator(Random(42)).generate();
    final b = HouseholdCodeGenerator(Random(42)).generate();
    expect(a, b);
  });

  test('isValid accepte un code généré et refuse les autres', () {
    expect(HouseholdCodeGenerator.isValid(HouseholdCodeGenerator().generate()), isTrue);
    expect(HouseholdCodeGenerator.isValid('ABCD'), isFalse);
    expect(HouseholdCodeGenerator.isValid('ABCDEFG0'), isFalse);
    expect(HouseholdCodeGenerator.isValid('abcdefgh'), isFalse);
  });

  test('normalize met en majuscules et retire les espaces', () {
    expect(HouseholdCodeGenerator.normalize(' abcd efgh '), 'ABCDEFGH');
  });
}
```

`test/features/household/data/prefs_household_local_store_test.dart` :

```dart
import 'package:colette/core/ids/id_generator.dart';
import 'package:colette/features/household/data/prefs_household_local_store.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  test('ensureDeviceId crée l\'identifiant une seule fois', () async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    await PrefsHouseholdLocalStore.ensureDeviceId(prefs, const FixedIdGenerator('dev-1'));
    await PrefsHouseholdLocalStore.ensureDeviceId(prefs, const FixedIdGenerator('dev-2'));
    expect(PrefsHouseholdLocalStore(prefs).deviceId, 'dev-1');
  });

  test('sauvegarde, lit et efface le code foyer', () async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    final store = PrefsHouseholdLocalStore(prefs);
    expect(store.householdCode, isNull);
    await store.saveHouseholdCode('ABCDEFGH');
    expect(store.householdCode, 'ABCDEFGH');
    await store.clearHouseholdCode();
    expect(store.householdCode, isNull);
  });
}
```

`test/features/household/data/firestore_household_repository_test.dart` :

```dart
import 'package:colette/core/clock/app_clock.dart';
import 'package:colette/core/result/failure.dart';
import 'package:colette/features/household/data/firestore_household_repository.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  final now = DateTime(2026, 9, 21, 10);

  test('create écrit le document du foyer avec createdAt', () async {
    final db = FakeFirebaseFirestore();
    final repo = FirestoreHouseholdRepository(db, FixedClock(now));
    final result = await repo.create('ABCDEFGH');
    expect(result.getRight().toNullable()?.code, 'ABCDEFGH');
    final doc = await db.collection('households').doc('ABCDEFGH').get();
    expect(doc.exists, isTrue);
  });

  test('join renvoie NotFoundFailure pour un code inconnu', () async {
    final repo = FirestoreHouseholdRepository(FakeFirebaseFirestore(), FixedClock(now));
    final result = await repo.join('ZZZZZZZZ');
    expect(result.getLeft().toNullable(), isA<NotFoundFailure>());
  });

  test('join renvoie le foyer existant', () async {
    final db = FakeFirebaseFirestore();
    final repo = FirestoreHouseholdRepository(db, FixedClock(now));
    await repo.create('ABCDEFGH');
    final result = await repo.join('ABCDEFGH');
    expect(result.getRight().toNullable()?.createdAt, now);
  });
}
```

`test/features/household/data/firestore_device_repository_test.dart` :

```dart
import 'package:colette/features/household/data/firestore_device_repository.dart';
import 'package:colette/features/household/domain/entities/device_info.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('saveDevice puis watchDevice renvoie l\'appareil', () async {
    final repo = FirestoreDeviceRepository(FakeFirebaseFirestore());
    const device = DeviceInfo(id: 'dev-1', label: 'iPhone de Maxence', morningDigestHour: 7);
    await repo.saveDevice('ABCDEFGH', device);
    expect(await repo.watchDevice('ABCDEFGH', 'dev-1').first, device);
  });

  test('updateFcmToken ne touche pas aux autres champs', () async {
    final repo = FirestoreDeviceRepository(FakeFirebaseFirestore());
    const device = DeviceInfo(id: 'dev-1', label: 'iPhone', notifyMorningDigest: false);
    await repo.saveDevice('ABCDEFGH', device);
    await repo.updateFcmToken('ABCDEFGH', 'dev-1', 'token-1');
    final updated = await repo.watchDevice('ABCDEFGH', 'dev-1').first;
    expect(updated?.fcmToken, 'token-1');
    expect(updated?.notifyMorningDigest, isFalse);
  });

  test('watchDevice émet null si l\'appareil n\'existe pas', () async {
    final repo = FirestoreDeviceRepository(FakeFirebaseFirestore());
    expect(await repo.watchDevice('ABCDEFGH', 'nope').first, isNull);
  });
}
```

- [ ] **Step 2: Vérifier l'échec**

Run: `flutter test test/features/household`
Expected: échec de compilation.

- [ ] **Step 3: Créer `lib/features/household/domain/household_code_generator.dart`**

```dart
import 'dart:math';

/// Génère et valide les codes foyer : 8 caractères, sans O/0 ni I/1.
class HouseholdCodeGenerator {
  HouseholdCodeGenerator([Random? random]) : _random = random ?? Random.secure();

  static const alphabet = 'ABCDEFGHJKLMNPQRSTUVWXYZ23456789';
  static const length = 8;

  final Random _random;

  String generate() => List.generate(
    length,
    (_) => alphabet[_random.nextInt(alphabet.length)],
  ).join();

  /// Majuscules, sans espaces.
  static String normalize(String input) => input.replaceAll(' ', '').toUpperCase();

  static bool isValid(String code) =>
      code.length == length && code.split('').every(alphabet.contains);
}
```

- [ ] **Step 4: Créer les interfaces du domaine**

`lib/features/household/domain/repositories/household_repository.dart` :

```dart
import 'package:colette/core/result/failure.dart';
import 'package:colette/features/household/domain/entities/household.dart';
import 'package:fpdart/fpdart.dart';

/// Création et jonction d'un foyer.
abstract interface class HouseholdRepository {
  Future<Either<Failure, Household>> create(String code);

  /// [NotFoundFailure] si le code n'existe pas.
  Future<Either<Failure, Household>> join(String code);
}
```

`lib/features/household/domain/repositories/device_repository.dart` :

```dart
import 'package:colette/core/result/failure.dart';
import 'package:colette/features/household/domain/entities/device_info.dart';
import 'package:fpdart/fpdart.dart';

/// Appareils membres d'un foyer.
abstract interface class DeviceRepository {
  Stream<DeviceInfo?> watchDevice(String householdCode, String deviceId);

  Future<Either<Failure, void>> saveDevice(String householdCode, DeviceInfo device);

  Future<Either<Failure, void>> updateFcmToken(
    String householdCode,
    String deviceId,
    String token,
  );
}
```

`lib/features/household/domain/repositories/household_local_store.dart` :

```dart
/// Ce que l'appareil retient localement : code foyer et identifiant d'appareil.
abstract interface class HouseholdLocalStore {
  String? get householdCode;

  Future<void> saveHouseholdCode(String code);

  Future<void> clearHouseholdCode();

  String get deviceId;
}
```

- [ ] **Step 5: Créer la couche data**

`lib/features/household/data/prefs_household_local_store.dart` :

```dart
import 'package:colette/core/ids/id_generator.dart';
import 'package:colette/features/household/domain/repositories/household_local_store.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Stockage local via `shared_preferences`.
class PrefsHouseholdLocalStore implements HouseholdLocalStore {
  PrefsHouseholdLocalStore(this._prefs);

  static const householdCodeKey = 'household_code';
  static const deviceIdKey = 'device_id';

  final SharedPreferences _prefs;

  /// À appeler au démarrage : crée l'identifiant d'appareil s'il manque.
  static Future<void> ensureDeviceId(SharedPreferences prefs, IdGenerator ids) async {
    if (!prefs.containsKey(deviceIdKey)) {
      await prefs.setString(deviceIdKey, ids.newId());
    }
  }

  @override
  String? get householdCode => _prefs.getString(householdCodeKey);

  @override
  Future<void> saveHouseholdCode(String code) => _prefs.setString(householdCodeKey, code);

  @override
  Future<void> clearHouseholdCode() => _prefs.remove(householdCodeKey);

  @override
  String get deviceId =>
      _prefs.getString(deviceIdKey) ??
      (throw StateError('PrefsHouseholdLocalStore.ensureDeviceId doit être appelé au démarrage'));
}
```

`lib/features/household/data/dtos/device_info_dto.dart` :

```dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:colette/features/household/domain/entities/device_info.dart';

/// Conversion `DeviceInfo` ↔ document Firestore `devices/{id}`.
abstract final class DeviceInfoDto {
  static Map<String, dynamic> toMap(DeviceInfo device) => {
    'label': device.label,
    'fcmToken': device.fcmToken,
    'notifyOnOthersEvents': device.notifyOnOthersEvents,
    'notifyBottleReminder': device.notifyBottleReminder,
    'notifyMorningDigest': device.notifyMorningDigest,
    'morningDigestHour': device.morningDigestHour,
    'updatedAt': FieldValue.serverTimestamp(),
  };

  static DeviceInfo fromMap(String id, Map<String, dynamic> map) => DeviceInfo(
    id: id,
    label: map['label'] as String? ?? '',
    fcmToken: map['fcmToken'] as String?,
    notifyOnOthersEvents: map['notifyOnOthersEvents'] as bool? ?? true,
    notifyBottleReminder: map['notifyBottleReminder'] as bool? ?? true,
    notifyMorningDigest: map['notifyMorningDigest'] as bool? ?? true,
    morningDigestHour: (map['morningDigestHour'] as num?)?.toInt() ?? 8,
  );
}
```

`lib/features/household/data/firestore_household_repository.dart` :

```dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:colette/core/clock/app_clock.dart';
import 'package:colette/core/firebase/firestore_paths.dart';
import 'package:colette/core/result/failure.dart';
import 'package:colette/core/result/failure_mapper.dart';
import 'package:colette/features/household/domain/entities/household.dart';
import 'package:colette/features/household/domain/repositories/household_repository.dart';
import 'package:fpdart/fpdart.dart';

/// Foyers stockés dans `households/{code}`.
class FirestoreHouseholdRepository implements HouseholdRepository {
  FirestoreHouseholdRepository(this._db, this._clock);

  final FirebaseFirestore _db;
  final AppClock _clock;

  DocumentReference<Map<String, dynamic>> _doc(String code) =>
      _db.collection(FirestorePaths.households).doc(code);

  @override
  Future<Either<Failure, Household>> create(String code) => guard(() async {
    final now = _clock.now();
    await _doc(code).set({'createdAt': Timestamp.fromDate(now)}, SetOptions(merge: true));
    return Household(code: code, createdAt: now);
  });

  @override
  Future<Either<Failure, Household>> join(String code) async {
    final snapshot = await guard(() => _doc(code).get());
    return snapshot.flatMap<Household>((snap) {
      final data = snap.data();
      if (data == null) return left(const NotFoundFailure());
      return right(
        Household(code: code, createdAt: (data['createdAt'] as Timestamp).toDate()),
      );
    });
  }
}
```

`lib/features/household/data/firestore_device_repository.dart` :

```dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:colette/core/firebase/firestore_paths.dart';
import 'package:colette/core/result/failure.dart';
import 'package:colette/core/result/failure_mapper.dart';
import 'package:colette/features/household/data/dtos/device_info_dto.dart';
import 'package:colette/features/household/domain/entities/device_info.dart';
import 'package:colette/features/household/domain/repositories/device_repository.dart';
import 'package:fpdart/fpdart.dart';

/// Appareils stockés dans `households/{code}/devices/{deviceId}`.
class FirestoreDeviceRepository implements DeviceRepository {
  FirestoreDeviceRepository(this._db);

  final FirebaseFirestore _db;

  DocumentReference<Map<String, dynamic>> _doc(String code, String deviceId) => _db
      .collection(FirestorePaths.households)
      .doc(code)
      .collection(FirestorePaths.devices)
      .doc(deviceId);

  @override
  Stream<DeviceInfo?> watchDevice(String householdCode, String deviceId) =>
      _doc(householdCode, deviceId).snapshots().map((snap) {
        final data = snap.data();
        return data == null ? null : DeviceInfoDto.fromMap(deviceId, data);
      });

  @override
  Future<Either<Failure, void>> saveDevice(String householdCode, DeviceInfo device) =>
      guard(
        () => _doc(householdCode, device.id).set(
          DeviceInfoDto.toMap(device),
          SetOptions(merge: true),
        ),
      );

  @override
  Future<Either<Failure, void>> updateFcmToken(
    String householdCode,
    String deviceId,
    String token,
  ) => guard(
    () => _doc(householdCode, deviceId).set(
      {'fcmToken': token, 'updatedAt': FieldValue.serverTimestamp()},
      SetOptions(merge: true),
    ),
  );
}
```

- [ ] **Step 6: Créer `lib/features/household/presentation/providers/household_providers.dart`**

```dart
import 'package:colette/core/clock/app_clock.dart';
import 'package:colette/core/firebase/firebase_providers.dart';
import 'package:colette/features/household/data/firestore_device_repository.dart';
import 'package:colette/features/household/data/firestore_household_repository.dart';
import 'package:colette/features/household/data/prefs_household_local_store.dart';
import 'package:colette/features/household/domain/entities/device_info.dart';
import 'package:colette/features/household/domain/household_code_generator.dart';
import 'package:colette/features/household/domain/repositories/device_repository.dart';
import 'package:colette/features/household/domain/repositories/household_local_store.dart';
import 'package:colette/features/household/domain/repositories/household_repository.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'household_providers.g.dart';

@Riverpod(keepAlive: true)
HouseholdLocalStore householdLocalStore(Ref ref) =>
    PrefsHouseholdLocalStore(ref.watch(sharedPreferencesProvider));

@riverpod
HouseholdRepository householdRepository(Ref ref) =>
    FirestoreHouseholdRepository(ref.watch(firestoreProvider), ref.watch(clockProvider));

/// Sans état : `keepAlive` car consommé par l'enregistrement push (keepAlive).
@Riverpod(keepAlive: true)
DeviceRepository deviceRepository(Ref ref) =>
    FirestoreDeviceRepository(ref.watch(firestoreProvider));

@riverpod
HouseholdCodeGenerator householdCodeGenerator(Ref ref) => HouseholdCodeGenerator();

/// Code du foyer courant ; `null` tant que l'onboarding n'est pas terminé.
@Riverpod(keepAlive: true)
class CurrentHouseholdCode extends _$CurrentHouseholdCode {
  @override
  String? build() => ref.watch(householdLocalStoreProvider).householdCode;

  Future<void> set(String code) async {
    await ref.read(householdLocalStoreProvider).saveHouseholdCode(code);
    state = code;
  }

  Future<void> clear() async {
    await ref.read(householdLocalStoreProvider).clearHouseholdCode();
    state = null;
  }
}

/// Identifiant stable de cet iPhone.
@Riverpod(keepAlive: true)
String deviceId(Ref ref) => ref.watch(householdLocalStoreProvider).deviceId;

/// Document de cet iPhone dans le foyer courant.
@riverpod
Stream<DeviceInfo?> currentDevice(Ref ref) {
  final code = ref.watch(currentHouseholdCodeProvider);
  if (code == null) return Stream.value(null);
  return ref.watch(deviceRepositoryProvider).watchDevice(code, ref.watch(deviceIdProvider));
}
```

- [ ] **Step 7: Créer `test/helpers/in_memory_household_local_store.dart`**

```dart
import 'package:colette/features/household/domain/repositories/household_local_store.dart';

/// Stockage local en mémoire pour les tests.
class InMemoryHouseholdLocalStore implements HouseholdLocalStore {
  InMemoryHouseholdLocalStore({this.householdCode, this.deviceId = 'device-test'});

  @override
  String? householdCode;

  @override
  final String deviceId;

  @override
  Future<void> saveHouseholdCode(String code) async => householdCode = code;

  @override
  Future<void> clearHouseholdCode() async => householdCode = null;
}
```

- [ ] **Step 8: Générer, analyser, tester**

Run: `dart run build_runner build -d && dart format lib test && dart analyze && flutter test test/features/household`
Expected: `No issues found!` puis `All tests passed!`.

- [ ] **Step 9: Commit**

```bash
git add lib/features/household test/features/household test/helpers
git commit -m "feat: feature household (code foyer, stockage local, repositories Firestore, providers)"
```

---

### Task 8: Feature baby — DTOs, repository Firestore, providers

**Files:**
- Create: `lib/features/baby/domain/repositories/baby_repository.dart`
- Create: `lib/features/baby/data/dtos/baby_profile_dto.dart`, `weight_entry_dto.dart`
- Create: `lib/features/baby/data/repositories/firestore_baby_repository.dart`
- Create: `lib/features/baby/presentation/providers/baby_providers.dart`
- Test: `test/features/baby/data/firestore_baby_repository_test.dart`

- [ ] **Step 1: Écrire le test (rouge)**

`test/features/baby/data/firestore_baby_repository_test.dart` :

```dart
import 'package:colette/features/baby/data/repositories/firestore_baby_repository.dart';
import 'package:colette/features/baby/domain/entities/baby_profile.dart';
import 'package:colette/features/baby/domain/entities/care_settings.dart';
import 'package:colette/features/baby/domain/entities/feeding_plan_snapshot.dart';
import 'package:colette/features/baby/domain/entities/weight_entry.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const code = 'ABCDEFGH';
  final profile = BabyProfile(
    name: 'Colette',
    birthDate: DateTime(2026, 9, 1),
    careSettings: const CareSettings(bathEveryDays: 3),
  );

  test('watchProfile émet null tant que rien n\'est écrit', () async {
    final repo = FirestoreBabyRepository(FakeFirebaseFirestore());
    expect(await repo.watchProfile(code).first, isNull);
  });

  test('saveProfile puis watchProfile renvoie le profil', () async {
    final repo = FirestoreBabyRepository(FakeFirebaseFirestore());
    await repo.saveProfile(code, profile);
    expect(await repo.watchProfile(code).first, profile);
  });

  test('saveProfile conserve le cordon tombé', () async {
    final repo = FirestoreBabyRepository(FakeFirebaseFirestore());
    final withCord = profile.copyWith(cordFallenAt: DateTime(2026, 9, 12));
    await repo.saveProfile(code, withCord);
    expect(await repo.watchProfile(code).first, withCord);
  });

  test('les pesées sont triées de la plus récente à la plus ancienne', () async {
    final repo = FirestoreBabyRepository(FakeFirebaseFirestore());
    await repo.addWeight(code, WeightEntry(id: 'w1', measuredAt: DateTime(2026, 9, 2), grams: 3200));
    await repo.addWeight(code, WeightEntry(id: 'w2', measuredAt: DateTime(2026, 9, 10), grams: 3600));
    final weights = await repo.watchWeights(code).first;
    expect(weights.map((w) => w.id), ['w2', 'w1']);
  });

  test('deleteWeight retire la pesée', () async {
    final repo = FirestoreBabyRepository(FakeFirebaseFirestore());
    await repo.addWeight(code, WeightEntry(id: 'w1', measuredAt: DateTime(2026, 9, 2), grams: 3200));
    await repo.deleteWeight(code, 'w1');
    expect(await repo.watchWeights(code).first, isEmpty);
  });

  test('saveFeedingPlan écrit feedingPlan sans effacer baby', () async {
    final db = FakeFirebaseFirestore();
    final repo = FirestoreBabyRepository(db);
    await repo.saveProfile(code, profile);
    await repo.saveFeedingPlan(
      code,
      FeedingPlanSnapshot(
        nextBottleAt: DateTime(2026, 9, 21, 14),
        suggestedMl: 120,
        computedAt: DateTime(2026, 9, 21, 11),
      ),
    );
    final data = (await db.collection('households').doc(code).get()).data()!;
    expect((data['feedingPlan'] as Map)['suggestedMl'], 120);
    expect(data['baby'], isNotNull);
  });
}
```

- [ ] **Step 2: Vérifier l'échec**

Run: `flutter test test/features/baby`
Expected: échec de compilation.

- [ ] **Step 3: Créer l'interface `lib/features/baby/domain/repositories/baby_repository.dart`**

```dart
import 'package:colette/core/result/failure.dart';
import 'package:colette/features/baby/domain/entities/baby_profile.dart';
import 'package:colette/features/baby/domain/entities/feeding_plan_snapshot.dart';
import 'package:colette/features/baby/domain/entities/weight_entry.dart';
import 'package:fpdart/fpdart.dart';

/// Profil du bébé, pesées et résumé du plan biberons.
abstract interface class BabyRepository {
  Stream<BabyProfile?> watchProfile(String householdCode);

  Future<Either<Failure, void>> saveProfile(String householdCode, BabyProfile profile);

  /// Pesées triées de la plus récente à la plus ancienne.
  Stream<List<WeightEntry>> watchWeights(String householdCode);

  Future<Either<Failure, void>> addWeight(String householdCode, WeightEntry entry);

  Future<Either<Failure, void>> deleteWeight(String householdCode, String weightId);

  Future<Either<Failure, void>> saveFeedingPlan(
    String householdCode,
    FeedingPlanSnapshot snapshot,
  );
}
```

- [ ] **Step 4: Créer les DTOs**

`lib/features/baby/data/dtos/baby_profile_dto.dart` :

```dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:colette/features/baby/domain/entities/baby_profile.dart';
import 'package:colette/features/baby/domain/entities/care_settings.dart';

/// Conversion `CareSettings` ↔ map Firestore.
abstract final class CareSettingsDto {
  static Map<String, dynamic> toMap(CareSettings settings) => {
    'adrigylPerDay': settings.adrigylPerDay,
    'eyeCarePerDay': settings.eyeCarePerDay,
    'noseCarePerDay': settings.noseCarePerDay,
    'umbilicalCareEnabled': settings.umbilicalCareEnabled,
    'bathEveryDays': settings.bathEveryDays,
    'feedsPerDay': settings.feedsPerDay,
  };

  static int _readInt(
    Map<String, dynamic> map,
    String key,
    int fallback, {
    required int min,
    required int max,
  }) => ((map[key] as num?)?.toInt() ?? fallback).clamp(min, max);

  /// Borne chaque valeur à une plage sûre : un document modifié à la main
  /// ne doit jamais casser les calculs.
  static CareSettings fromMap(Map<String, dynamic> map) => CareSettings(
    adrigylPerDay: _readInt(map, 'adrigylPerDay', 1, min: 0, max: 10),
    eyeCarePerDay: _readInt(map, 'eyeCarePerDay', 1, min: 0, max: 10),
    noseCarePerDay: _readInt(map, 'noseCarePerDay', 1, min: 0, max: 10),
    umbilicalCareEnabled: map['umbilicalCareEnabled'] as bool? ?? true,
    bathEveryDays: _readInt(map, 'bathEveryDays', 2, min: 1, max: 30),
    feedsPerDay: _readInt(map, 'feedsPerDay', 8, min: 1, max: 24),
  );
}

/// Conversion `BabyProfile` ↔ champ `baby` du document foyer.
abstract final class BabyProfileDto {
  static Map<String, dynamic> toMap(BabyProfile profile) => {
    'name': profile.name,
    'birthDate': Timestamp.fromDate(profile.birthDate),
    'cordFallenAt': switch (profile.cordFallenAt) {
      null => null,
      final date => Timestamp.fromDate(date),
    },
    'careSettings': CareSettingsDto.toMap(profile.careSettings),
  };

  static BabyProfile fromMap(Map<String, dynamic> map) => BabyProfile(
    name: map['name'] as String? ?? '',
    birthDate: (map['birthDate'] as Timestamp).toDate(),
    cordFallenAt: (map['cordFallenAt'] as Timestamp?)?.toDate(),
    careSettings: CareSettingsDto.fromMap(
      (map['careSettings'] as Map<String, dynamic>?) ?? const {},
    ),
  );
}
```

`lib/features/baby/data/dtos/weight_entry_dto.dart` :

```dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:colette/features/baby/domain/entities/weight_entry.dart';

/// Conversion `WeightEntry` ↔ document `weights/{id}`.
abstract final class WeightEntryDto {
  static Map<String, dynamic> toMap(WeightEntry entry) => {
    'measuredAt': Timestamp.fromDate(entry.measuredAt),
    'grams': entry.grams,
  };

  static WeightEntry fromDoc(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data()!;
    return WeightEntry(
      id: doc.id,
      measuredAt: (data['measuredAt'] as Timestamp).toDate(),
      grams: (data['grams'] as num).toInt(),
    );
  }
}
```

- [ ] **Step 5: Créer `lib/features/baby/data/repositories/firestore_baby_repository.dart`**

```dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:colette/core/firebase/firestore_paths.dart';
import 'package:colette/core/result/failure.dart';
import 'package:colette/core/result/failure_mapper.dart';
import 'package:colette/features/baby/data/dtos/baby_profile_dto.dart';
import 'package:colette/features/baby/data/dtos/weight_entry_dto.dart';
import 'package:colette/features/baby/domain/entities/baby_profile.dart';
import 'package:colette/features/baby/domain/entities/feeding_plan_snapshot.dart';
import 'package:colette/features/baby/domain/entities/weight_entry.dart';
import 'package:colette/features/baby/domain/repositories/baby_repository.dart';
import 'package:fpdart/fpdart.dart';

/// Profil dans `households/{code}.baby`, pesées dans `households/{code}/weights`.
class FirestoreBabyRepository implements BabyRepository {
  FirestoreBabyRepository(this._db);

  final FirebaseFirestore _db;

  DocumentReference<Map<String, dynamic>> _household(String code) =>
      _db.collection(FirestorePaths.households).doc(code);

  CollectionReference<Map<String, dynamic>> _weights(String code) =>
      _household(code).collection(FirestorePaths.weights);

  @override
  Stream<BabyProfile?> watchProfile(String householdCode) =>
      _household(householdCode).snapshots().map((snap) {
        final baby = snap.data()?['baby'] as Map<String, dynamic>?;
        return baby == null ? null : BabyProfileDto.fromMap(baby);
      });

  @override
  Future<Either<Failure, void>> saveProfile(String householdCode, BabyProfile profile) =>
      guard(
        () => _household(householdCode).set(
          {'baby': BabyProfileDto.toMap(profile)},
          SetOptions(merge: true),
        ),
      );

  @override
  Stream<List<WeightEntry>> watchWeights(String householdCode) => _weights(householdCode)
      .orderBy('measuredAt', descending: true)
      .snapshots()
      .map((snap) => snap.docs.map(WeightEntryDto.fromDoc).toList());

  @override
  Future<Either<Failure, void>> addWeight(String householdCode, WeightEntry entry) =>
      guard(() => _weights(householdCode).doc(entry.id).set(WeightEntryDto.toMap(entry)));

  @override
  Future<Either<Failure, void>> deleteWeight(String householdCode, String weightId) =>
      guard(() => _weights(householdCode).doc(weightId).delete());

  @override
  Future<Either<Failure, void>> saveFeedingPlan(
    String householdCode,
    FeedingPlanSnapshot snapshot,
  ) => guard(
    () => _household(householdCode).set({
      'feedingPlan': {
        'nextBottleAt': Timestamp.fromDate(snapshot.nextBottleAt),
        'suggestedMl': snapshot.suggestedMl,
        'computedAt': Timestamp.fromDate(snapshot.computedAt),
      },
    }, SetOptions(merge: true)),
  );
}
```

- [ ] **Step 6: Créer `lib/features/baby/presentation/providers/baby_providers.dart`**

```dart
import 'package:colette/core/firebase/firebase_providers.dart';
import 'package:colette/features/baby/data/repositories/firestore_baby_repository.dart';
import 'package:colette/features/baby/domain/entities/baby_profile.dart';
import 'package:colette/features/baby/domain/entities/weight_entry.dart';
import 'package:colette/features/baby/domain/repositories/baby_repository.dart';
import 'package:colette/features/household/presentation/providers/household_providers.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'baby_providers.g.dart';

@riverpod
BabyRepository babyRepository(Ref ref) => FirestoreBabyRepository(ref.watch(firestoreProvider));

/// Profil du bébé du foyer courant.
@riverpod
Stream<BabyProfile?> babyProfile(Ref ref) {
  final code = ref.watch(currentHouseholdCodeProvider);
  if (code == null) return Stream.value(null);
  return ref.watch(babyRepositoryProvider).watchProfile(code);
}

/// Pesées du foyer courant, de la plus récente à la plus ancienne.
@riverpod
Stream<List<WeightEntry>> weights(Ref ref) {
  final code = ref.watch(currentHouseholdCodeProvider);
  if (code == null) return Stream.value(const []);
  return ref.watch(babyRepositoryProvider).watchWeights(code);
}

/// Pesée la plus récente, ou `null`.
@riverpod
WeightEntry? latestWeight(Ref ref) {
  final list = ref.watch(weightsProvider).value;
  return list == null || list.isEmpty ? null : list.first;
}
```

- [ ] **Step 7: Générer, analyser, tester**

Run: `dart run build_runner build -d && dart format lib test && dart analyze && flutter test test/features/baby`
Expected: `No issues found!` puis `All tests passed!`.

- [ ] **Step 8: Commit**

```bash
git add lib/features/baby test/features/baby
git commit -m "feat: feature baby (DTOs, repository Firestore, providers profil et pesées)"
```

---

### Task 9: Onboarding, routeur, shell 3 onglets, `main.dart`

**Files:**
- Create: `lib/features/household/presentation/providers/onboarding_controller.dart`
- Create: `lib/features/household/presentation/pages/onboarding_page.dart`, `create_household_page.dart`, `join_household_page.dart`
- Create: `lib/shared/ui/widgets/date_field.dart`
- Create: `lib/app/router/app_router.dart`, `lib/app/main_shell.dart`, `lib/app/colette_app.dart`
- Create (placeholders remplacés plus tard) : `lib/features/dashboard/presentation/pages/dashboard_page.dart`, `lib/features/events/presentation/pages/timeline_page.dart`, `lib/features/baby/presentation/pages/settings_page.dart`
- Modify: `lib/main.dart`
- Test: `test/app/app_router_test.dart`, `test/features/household/presentation/onboarding_controller_test.dart`

- [ ] **Step 1: Écrire les tests (rouges)**

`test/features/household/presentation/onboarding_controller_test.dart` :

```dart
import 'package:colette/core/result/failure.dart';
import 'package:colette/features/baby/domain/entities/baby_profile.dart';
import 'package:colette/features/baby/domain/repositories/baby_repository.dart';
import 'package:colette/features/baby/presentation/providers/baby_providers.dart';
import 'package:colette/features/household/domain/entities/device_info.dart';
import 'package:colette/features/household/domain/entities/household.dart';
import 'package:colette/features/household/domain/repositories/device_repository.dart';
import 'package:colette/features/household/domain/repositories/household_repository.dart';
import 'package:colette/features/household/presentation/providers/household_providers.dart';
import 'package:colette/features/household/presentation/providers/onboarding_controller.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:mocktail/mocktail.dart';

import '../../../helpers/in_memory_household_local_store.dart';

class MockHouseholdRepository extends Mock implements HouseholdRepository {}

class MockBabyRepository extends Mock implements BabyRepository {}

class MockDeviceRepository extends Mock implements DeviceRepository {}

void main() {
  late MockHouseholdRepository households;
  late MockBabyRepository babies;
  late MockDeviceRepository devices;
  late InMemoryHouseholdLocalStore store;
  late ProviderContainer container;

  setUpAll(() {
    registerFallbackValue(BabyProfile(name: 'x', birthDate: DateTime(2026)));
    registerFallbackValue(const DeviceInfo(id: 'x', label: 'x'));
  });

  setUp(() {
    households = MockHouseholdRepository();
    babies = MockBabyRepository();
    devices = MockDeviceRepository();
    store = InMemoryHouseholdLocalStore(deviceId: 'dev-1');
    container = ProviderContainer(
      overrides: [
        householdRepositoryProvider.overrideWithValue(households),
        babyRepositoryProvider.overrideWithValue(babies),
        deviceRepositoryProvider.overrideWithValue(devices),
        householdLocalStoreProvider.overrideWithValue(store),
      ],
    );
    addTearDown(container.dispose);
  });

  test('createHousehold crée le foyer, le profil, l\'appareil et enregistre le code', () async {
    when(() => households.create(any())).thenAnswer(
      (inv) async => right(Household(code: inv.positionalArguments.first as String, createdAt: DateTime(2026))),
    );
    when(() => babies.saveProfile(any(), any())).thenAnswer((_) async => right(null));
    when(() => devices.saveDevice(any(), any())).thenAnswer((_) async => right(null));

    final ok = await container.read(onboardingControllerProvider.notifier).createHousehold(
      babyName: 'Colette',
      birthDate: DateTime(2026, 9, 1),
      deviceLabel: 'iPhone de Maxence',
    );

    expect(ok, isTrue);
    expect(store.householdCode, hasLength(8));
    verify(() => babies.saveProfile(any(), any())).called(1);
    verify(() => devices.saveDevice(any(), any(that: isA<DeviceInfo>()))).called(1);
  });

  test('createHousehold refuse un prénom vide sans appeler Firestore', () async {
    final ok = await container.read(onboardingControllerProvider.notifier).createHousehold(
      babyName: '  ',
      birthDate: DateTime(2026, 9, 1),
      deviceLabel: 'iPhone',
    );
    expect(ok, isFalse);
    expect(container.read(onboardingControllerProvider).error, isA<ValidationFailure>());
    verifyNever(() => households.create(any()));
  });

  test('joinHousehold convertit NotFoundFailure en code inconnu', () async {
    when(() => households.join('ABCDEFGH')).thenAnswer((_) async => left(const NotFoundFailure()));
    final ok = await container.read(onboardingControllerProvider.notifier).joinHousehold(
      code: 'abcd efgh',
      deviceLabel: 'iPhone',
    );
    expect(ok, isFalse);
    final error = container.read(onboardingControllerProvider).error;
    expect(error, isA<ValidationFailure>());
    expect((error! as ValidationFailure).reason, ValidationReason.unknownHouseholdCode);
    expect(store.householdCode, isNull);
  });

  test('joinHousehold enregistre le code après succès', () async {
    when(() => households.join('ABCDEFGH')).thenAnswer(
      (_) async => right(Household(code: 'ABCDEFGH', createdAt: DateTime(2026))),
    );
    when(() => devices.saveDevice(any(), any())).thenAnswer((_) async => right(null));
    final ok = await container.read(onboardingControllerProvider.notifier).joinHousehold(
      code: 'ABCDEFGH',
      deviceLabel: 'iPhone',
    );
    expect(ok, isTrue);
    expect(store.householdCode, 'ABCDEFGH');
  });
}
```

`test/app/app_router_test.dart` :

```dart
import 'package:colette/app/colette_app.dart';
import 'package:colette/core/connectivity/connectivity_provider.dart';
import 'package:colette/core/firebase/firebase_providers.dart';
import 'package:colette/features/household/presentation/pages/onboarding_page.dart';
import 'package:colette/features/household/presentation/providers/household_providers.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import '../helpers/in_memory_household_local_store.dart';

void main() {
  Future<void> pumpColetteApp(WidgetTester tester, {String? code}) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          householdLocalStoreProvider.overrideWithValue(
            InMemoryHouseholdLocalStore(householdCode: code),
          ),
          isOnlineProvider.overrideWith((ref) => Stream.value(true)),
          firestoreProvider.overrideWithValue(FakeFirebaseFirestore()),
        ],
        child: const ColetteApp(),
      ),
    );
    await tester.pumpAndSettle();
  }

  testWidgets('sans code foyer, l\'app démarre sur l\'onboarding', (tester) async {
    await pumpColetteApp(tester);
    expect(find.byType(OnboardingPage), findsOneWidget);
    expect(find.byType(NavigationBar), findsNothing);
  });

  testWidgets('avec un code foyer, l\'app démarre sur le shell 3 onglets', (tester) async {
    await pumpColetteApp(tester, code: 'ABCDEFGH');
    expect(find.byType(NavigationBar), findsOneWidget);
    expect(find.text('Aujourd\'hui'), findsWidgets);
    expect(find.byType(OnboardingPage), findsNothing);
  });
}
```

- [ ] **Step 2: Vérifier l'échec**

Run: `flutter test test/app test/features/household/presentation`
Expected: échec de compilation.

- [ ] **Step 3: Créer `lib/features/household/presentation/providers/onboarding_controller.dart`**

```dart
import 'dart:async';

import 'package:colette/core/result/either_extensions.dart';
import 'package:colette/core/result/failure.dart';
import 'package:colette/features/baby/domain/entities/baby_profile.dart';
import 'package:colette/features/baby/presentation/providers/baby_providers.dart';
import 'package:colette/features/household/domain/entities/device_info.dart';
import 'package:colette/features/household/domain/household_code_generator.dart';
import 'package:colette/features/household/presentation/providers/household_providers.dart';
import 'package:fpdart/fpdart.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'onboarding_controller.g.dart';

/// Création ou jonction d'un foyer. L'état porte l'échec éventuel.
@riverpod
class OnboardingController extends _$OnboardingController {
  /// Code généré, conservé entre deux tentatives pour ne pas créer d'orphelin.
  String? _pendingCode;

  @override
  FutureOr<void> build() {}

  Future<bool> createHousehold({
    required String babyName,
    required DateTime birthDate,
    required String deviceLabel,
  }) => _run(() async {
    final name = babyName.trim();
    if (name.isEmpty) return left(const ValidationFailure(ValidationReason.emptyName));
    final code = _pendingCode ??= ref.read(householdCodeGeneratorProvider).generate();
    final created = await ref.read(householdRepositoryProvider).create(code);
    if (created.leftOrNull case final failure?) return left(failure);
    final saved = await ref
        .read(babyRepositoryProvider)
        .saveProfile(code, BabyProfile(name: name, birthDate: birthDate));
    if (saved.leftOrNull case final failure?) return left(failure);
    return _registerDeviceAndEnter(code, deviceLabel);
  });

  Future<bool> joinHousehold({required String code, required String deviceLabel}) =>
      _run(() async {
        final normalized = HouseholdCodeGenerator.normalize(code);
        if (!HouseholdCodeGenerator.isValid(normalized)) {
          return left(const ValidationFailure(ValidationReason.unknownHouseholdCode));
        }
        final joined = await ref.read(householdRepositoryProvider).join(normalized);
        if (joined.leftOrNull case final failure?) {
          return left(
            failure is NotFoundFailure
                ? const ValidationFailure(ValidationReason.unknownHouseholdCode)
                : failure,
          );
        }
        return _registerDeviceAndEnter(normalized, deviceLabel);
      });

  Future<Either<Failure, void>> _registerDeviceAndEnter(String code, String deviceLabel) async {
    final device = DeviceInfo(id: ref.read(deviceIdProvider), label: deviceLabel.trim());
    final registered = await ref.read(deviceRepositoryProvider).saveDevice(code, device);
    if (registered.leftOrNull case final failure?) return left(failure);
    await ref.read(currentHouseholdCodeProvider.notifier).set(code);
    _pendingCode = null;
    return right(null);
  }

  Future<bool> _run(Future<Either<Failure, void>> Function() action) async {
    state = const AsyncLoading();
    final result = await action();
    state = result.fold(
      (failure) => AsyncError(failure, StackTrace.current),
      (_) => const AsyncData(null),
    );
    return result.isRight();
  }
}
```

- [ ] **Step 4: Créer `lib/shared/ui/widgets/date_field.dart`**

```dart
import 'package:colette/core/theme/app_colors.dart';
import 'package:colette/core/theme/design_tokens.dart';
import 'package:colette/core/theme/text_styles.dart';
import 'package:flutter/material.dart';

/// Champ non éditable « libellé / valeur » qui ouvre un sélecteur au tap.
class DateField extends StatelessWidget {
  const DateField({super.key, required this.label, required this.value, required this.onTap});

  final String label;
  final String value;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final styles = Theme.of(context).coletteTextStyles;
    return Material(
      color: context.appColor(AppColors.surfaceContainer),
      borderRadius: AppRadius.md.circular,
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: AppSpacing.md.all,
          child: Row(
            children: [
              Expanded(
                child: Text(
                  label,
                  style: styles.label.copyWith(color: context.appColor(AppColors.textSecondary)),
                ),
              ),
              Text(value, style: styles.bodyMedium),
              AppSpacing.xs.horizontalSpace,
              Icon(
                Icons.chevron_right,
                size: AppSize.xs.value,
                color: context.appColor(AppColors.textSecondary),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
```

- [ ] **Step 5: Créer les pages d'onboarding**

`lib/features/household/presentation/pages/onboarding_page.dart` :

```dart
import 'package:colette/app/router/app_router.dart';
import 'package:colette/core/theme/app_colors.dart';
import 'package:colette/core/theme/design_tokens.dart';
import 'package:colette/core/theme/text_styles.dart';
import 'package:colette/l10n/generated/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

/// Premier écran sans foyer : créer ou rejoindre.
class OnboardingPage extends StatelessWidget {
  const OnboardingPage({super.key});

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    final styles = Theme.of(context).coletteTextStyles;
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: AppSpacing.lg.all,
          child: Column(
            children: [
              const Spacer(),
              Icon(
                Icons.child_friendly_outlined,
                size: AppSize.huge.value,
                color: context.appColor(AppColors.primary),
              ),
              AppSpacing.lg.verticalSpace,
              Text(s.onboardingTitle, style: styles.displayTitle, textAlign: .center),
              AppSpacing.sm.verticalSpace,
              Text(
                s.onboardingSubtitle,
                style: styles.body.copyWith(color: context.appColor(AppColors.textSecondary)),
                textAlign: .center,
              ),
              const Spacer(),
              FilledButton(
                onPressed: () => context.push(AppRoutes.onboardingCreate),
                child: Text(s.onboardingCreate),
              ),
              AppSpacing.sm.verticalSpace,
              OutlinedButton(
                onPressed: () => context.push(AppRoutes.onboardingJoin),
                child: Text(s.onboardingJoin),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
```

`lib/features/household/presentation/pages/create_household_page.dart` :

```dart
import 'package:colette/core/clock/app_clock.dart';
import 'package:colette/core/dates/date_extensions.dart';
import 'package:colette/core/theme/design_tokens.dart';
import 'package:colette/core/ui/date_time_picker.dart';
import 'package:colette/core/ui/failure_message.dart';
import 'package:colette/features/household/presentation/providers/onboarding_controller.dart';
import 'package:colette/l10n/generated/app_localizations.dart';
import 'package:colette/shared/ui/widgets/date_field.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

/// Saisie du prénom, de la date de naissance et du nom de l'appareil.
class CreateHouseholdPage extends ConsumerStatefulWidget {
  const CreateHouseholdPage({super.key});

  @override
  ConsumerState<CreateHouseholdPage> createState() => _CreateHouseholdPageState();
}

class _CreateHouseholdPageState extends ConsumerState<CreateHouseholdPage> {
  final _nameController = TextEditingController();
  final _deviceController = TextEditingController();
  late DateTime _birthDate = ref.read(clockProvider).now().dateOnly;

  @override
  void dispose() {
    _nameController.dispose();
    _deviceController.dispose();
    super.dispose();
  }

  Future<void> _pickBirthDate() async {
    final picked = await showColetteDateTimePicker(
      context,
      initial: _birthDate,
      mode: CupertinoDatePickerMode.date,
      maximum: ref.read(clockProvider).now(),
    );
    if (picked != null) setState(() => _birthDate = picked.dateOnly);
  }

  Future<void> _submit() async {
    if (ref.read(onboardingControllerProvider).isLoading) return;
    final s = S.of(context);
    final label = _deviceController.text.trim().isEmpty
        ? s.deviceLabelDefault
        : _deviceController.text;
    await ref.read(onboardingControllerProvider.notifier).createHousehold(
      babyName: _nameController.text,
      birthDate: _birthDate,
      deviceLabel: label,
    );
  }

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    ref.listen(onboardingControllerProvider, (_, next) {
      if (next case AsyncError(:final error)) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(failureMessage(error, s))),
        );
      }
    });
    final isLoading = ref.watch(onboardingControllerProvider) is AsyncLoading;
    return Scaffold(
      appBar: AppBar(title: Text(s.createHouseholdTitle)),
      body: SafeArea(
        child: ListView(
          padding: AppSpacing.lg.all,
          children: [
            TextField(
              controller: _nameController,
              decoration: InputDecoration(labelText: s.fieldBabyName),
              textCapitalization: .words,
            ),
            AppSpacing.md.verticalSpace,
            DateField(
              label: s.fieldBirthDate,
              value: DateFormat.yMMMMd('fr').format(_birthDate),
              onTap: _pickBirthDate,
            ),
            AppSpacing.md.verticalSpace,
            TextField(
              controller: _deviceController,
              decoration: InputDecoration(
                labelText: s.fieldDeviceLabel,
                hintText: s.fieldDeviceLabelHint,
              ),
            ),
            AppSpacing.xl.verticalSpace,
            FilledButton(
              onPressed: isLoading ? null : _submit,
              child: Text(s.actionCreate),
            ),
          ],
        ),
      ),
    );
  }
}
```

`lib/features/household/presentation/pages/join_household_page.dart` :

```dart
import 'package:colette/core/theme/design_tokens.dart';
import 'package:colette/core/ui/failure_message.dart';
import 'package:colette/features/household/domain/household_code_generator.dart';
import 'package:colette/features/household/presentation/providers/onboarding_controller.dart';
import 'package:colette/l10n/generated/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Saisie du code foyer et du nom de l'appareil.
class JoinHouseholdPage extends ConsumerStatefulWidget {
  const JoinHouseholdPage({super.key});

  @override
  ConsumerState<JoinHouseholdPage> createState() => _JoinHouseholdPageState();
}

class _JoinHouseholdPageState extends ConsumerState<JoinHouseholdPage> {
  final _codeController = TextEditingController();
  final _deviceController = TextEditingController();

  @override
  void dispose() {
    _codeController.dispose();
    _deviceController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (ref.read(onboardingControllerProvider).isLoading) return;
    final s = S.of(context);
    final label = _deviceController.text.trim().isEmpty
        ? s.deviceLabelDefault
        : _deviceController.text;
    await ref
        .read(onboardingControllerProvider.notifier)
        .joinHousehold(code: _codeController.text, deviceLabel: label);
  }

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    ref.listen(onboardingControllerProvider, (_, next) {
      if (next case AsyncError(:final error)) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(failureMessage(error, s))),
        );
      }
    });
    final isLoading = ref.watch(onboardingControllerProvider) is AsyncLoading;
    return Scaffold(
      appBar: AppBar(title: Text(s.joinHouseholdTitle)),
      body: SafeArea(
        child: ListView(
          padding: AppSpacing.lg.all,
          children: [
            TextField(
              controller: _codeController,
              decoration: InputDecoration(labelText: s.fieldHouseholdCode),
              textCapitalization: .characters,
              maxLength: HouseholdCodeGenerator.length,
              autocorrect: false,
            ),
            AppSpacing.md.verticalSpace,
            TextField(
              controller: _deviceController,
              decoration: InputDecoration(
                labelText: s.fieldDeviceLabel,
                hintText: s.fieldDeviceLabelHint,
              ),
            ),
            AppSpacing.xl.verticalSpace,
            FilledButton(
              onPressed: isLoading ? null : _submit,
              child: Text(s.actionJoin),
            ),
          ],
        ),
      ),
    );
  }
}
```

- [ ] **Step 6: Créer les pages placeholder des trois onglets**

Ces trois fichiers sont intégralement remplacés dans les tâches 12, 14 et 15.

`lib/features/dashboard/presentation/pages/dashboard_page.dart` :

```dart
import 'package:colette/l10n/generated/app_localizations.dart';
import 'package:colette/shared/ui/widgets/empty_state.dart';
import 'package:flutter/material.dart';

/// Onglet Aujourd'hui (placeholder, remplacé en tâche 14).
class DashboardPage extends StatelessWidget {
  const DashboardPage({super.key});

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    return Scaffold(
      appBar: AppBar(title: Text(s.tabToday)),
      body: EmptyState(icon: Icons.wb_sunny_outlined, message: s.todoAllDone),
    );
  }
}
```

`lib/features/events/presentation/pages/timeline_page.dart` :

```dart
import 'package:colette/l10n/generated/app_localizations.dart';
import 'package:colette/shared/ui/widgets/empty_state.dart';
import 'package:flutter/material.dart';

/// Onglet Journal (placeholder, remplacé en tâche 12).
class TimelinePage extends StatelessWidget {
  const TimelinePage({super.key});

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    return Scaffold(
      appBar: AppBar(title: Text(s.journalTitle)),
      body: EmptyState(icon: Icons.view_timeline_outlined, message: s.journalEmpty),
    );
  }
}
```

`lib/features/baby/presentation/pages/settings_page.dart` :

```dart
import 'package:colette/l10n/generated/app_localizations.dart';
import 'package:colette/shared/ui/widgets/empty_state.dart';
import 'package:flutter/material.dart';

/// Onglet Réglages (placeholder, remplacé en tâche 15).
class SettingsPage extends StatelessWidget {
  const SettingsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    return Scaffold(
      appBar: AppBar(title: Text(s.settingsTitle)),
      body: EmptyState(icon: Icons.tune_outlined, message: s.settingsTitle),
    );
  }
}
```

- [ ] **Step 7: Créer le routeur, le shell et l'app**

`lib/app/router/app_router.dart` :

```dart
import 'package:colette/app/main_shell.dart';
import 'package:colette/features/baby/presentation/pages/settings_page.dart';
import 'package:colette/features/dashboard/presentation/pages/dashboard_page.dart';
import 'package:colette/features/events/presentation/pages/timeline_page.dart';
import 'package:colette/features/household/presentation/pages/create_household_page.dart';
import 'package:colette/features/household/presentation/pages/join_household_page.dart';
import 'package:colette/features/household/presentation/pages/onboarding_page.dart';
import 'package:colette/features/household/presentation/providers/household_providers.dart';
import 'package:go_router/go_router.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'app_router.g.dart';

/// Chemins des routes.
abstract final class AppRoutes {
  static const onboarding = '/onboarding';
  static const onboardingCreate = '/onboarding/create';
  static const onboardingJoin = '/onboarding/join';
  static const today = '/today';
  static const journal = '/journal';
  static const settings = '/settings';

  /// Paramètre de requête qui ouvre le formulaire biberon à l'arrivée sur Aujourd'hui.
  static const openBottleParam = 'bottle';
}

/// Routeur : onboarding tant qu'aucun foyer, sinon shell à trois onglets.
@riverpod
GoRouter appRouter(Ref ref) {
  final hasHousehold = ref.watch(currentHouseholdCodeProvider) != null;
  final router = GoRouter(
    initialLocation: hasHousehold ? AppRoutes.today : AppRoutes.onboarding,
    redirect: (context, state) {
      final onOnboarding = state.matchedLocation.startsWith(AppRoutes.onboarding);
      if (!hasHousehold && !onOnboarding) return AppRoutes.onboarding;
      if (hasHousehold && onOnboarding) return AppRoutes.today;
      return null;
    },
    routes: [
      GoRoute(
        path: AppRoutes.onboarding,
        builder: (_, _) => const OnboardingPage(),
        routes: [
          GoRoute(path: 'create', builder: (_, _) => const CreateHouseholdPage()),
          GoRoute(path: 'join', builder: (_, _) => const JoinHouseholdPage()),
        ],
      ),
      StatefulShellRoute.indexedStack(
        builder: (_, _, shell) => MainShell(navigationShell: shell),
        branches: [
          StatefulShellBranch(
            routes: [GoRoute(path: AppRoutes.today, builder: (_, _) => const DashboardPage())],
          ),
          StatefulShellBranch(
            routes: [GoRoute(path: AppRoutes.journal, builder: (_, _) => const TimelinePage())],
          ),
          StatefulShellBranch(
            routes: [GoRoute(path: AppRoutes.settings, builder: (_, _) => const SettingsPage())],
          ),
        ],
      ),
    ],
  );
  ref.onDispose(router.dispose);
  return router;
}
```

`lib/app/main_shell.dart` :

```dart
import 'package:colette/l10n/generated/app_localizations.dart';
import 'package:colette/shared/ui/widgets/offline_banner.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

/// Scaffold commun aux trois onglets : bandeau hors ligne + `NavigationBar`.
class MainShell extends StatelessWidget {
  const MainShell({super.key, required this.navigationShell});

  final StatefulNavigationShell navigationShell;

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    return Scaffold(
      body: Column(
        children: [
          const OfflineBanner(),
          Expanded(child: navigationShell),
        ],
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: navigationShell.currentIndex,
        onDestinationSelected: (index) => navigationShell.goBranch(
          index,
          initialLocation: index == navigationShell.currentIndex,
        ),
        destinations: [
          NavigationDestination(
            icon: const Icon(Icons.wb_sunny_outlined),
            selectedIcon: const Icon(Icons.wb_sunny),
            label: s.tabToday,
          ),
          NavigationDestination(
            icon: const Icon(Icons.view_timeline_outlined),
            selectedIcon: const Icon(Icons.view_timeline),
            label: s.tabJournal,
          ),
          NavigationDestination(
            icon: const Icon(Icons.tune_outlined),
            selectedIcon: const Icon(Icons.tune),
            label: s.tabSettings,
          ),
        ],
      ),
    );
  }
}
```

`lib/app/colette_app.dart` :

```dart
import 'package:colette/app/router/app_router.dart';
import 'package:colette/core/theme/theme_service.dart';
import 'package:colette/l10n/generated/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Racine de l'app : thèmes, locale française, routeur.
class ColetteApp extends ConsumerWidget {
  const ColetteApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    const themeService = ThemeService();
    return MaterialApp.router(
      onGenerateTitle: (context) => S.of(context).appTitle,
      theme: themeService.light(),
      darkTheme: themeService.dark(),
      themeMode: ThemeMode.system,
      locale: const Locale('fr'),
      localizationsDelegates: S.localizationsDelegates,
      supportedLocales: S.supportedLocales,
      routerConfig: ref.watch(appRouterProvider),
    );
  }
}
```

- [ ] **Step 8: Remplacer `lib/main.dart`**

```dart
import 'package:colette/app/colette_app.dart';
import 'package:colette/core/firebase/anonymous_auth.dart';
import 'package:colette/core/firebase/firebase_providers.dart';
import 'package:colette/core/ids/id_generator.dart';
import 'package:colette/features/household/data/prefs_household_local_store.dart';
import 'package:colette/firebase_options.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:shared_preferences/shared_preferences.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  await ensureAnonymousSession(FirebaseAuth.instance);
  await initializeDateFormatting('fr');
  final prefs = await SharedPreferences.getInstance();
  await PrefsHouseholdLocalStore.ensureDeviceId(prefs, const UuidIdGenerator());
  runApp(
    ProviderScope(
      overrides: [sharedPreferencesProvider.overrideWithValue(prefs)],
      child: const ColetteApp(),
    ),
  );
}
```

- [ ] **Step 9: Générer, analyser, tester**

Run: `dart run build_runner build -d && dart format lib test && dart analyze && flutter test`
Expected: `No issues found!` puis `All tests passed!`.

- [ ] **Step 10: Commit**

```bash
git add lib test
git commit -m "feat: onboarding (créer/rejoindre), routeur go_router, shell 3 onglets, main"
```

---

### Task 10: Feature events — validation, repository Firestore, providers

**Files:**
- Create: `lib/features/events/domain/use_cases/validate_care_event.dart`
- Create: `lib/features/events/domain/repositories/events_repository.dart`
- Create: `lib/features/events/data/dtos/care_event_dto.dart`, `lib/features/events/data/repositories/firestore_events_repository.dart`
- Create: `lib/features/events/presentation/providers/events_providers.dart`
- Create: `test/helpers/care_event_factory.dart`
- Test: `test/features/events/domain/use_cases/validate_care_event_test.dart`, `test/features/events/data/firestore_events_repository_test.dart`

- [ ] **Step 1: Créer `test/helpers/care_event_factory.dart`**

```dart
import 'package:colette/features/events/domain/entities/care_event.dart';

/// Construit un `CareEvent` de test avec des valeurs par défaut.
CareEvent makeEvent({
  String id = 'e1',
  required DateTime startAt,
  DateTime? endAt,
  bool pee = false,
  bool poop = false,
  bool diaperChange = false,
  bool adrigyl = false,
  bool bath = false,
  bool eyeCare = false,
  bool noseCare = false,
  bool umbilicalCare = false,
  int? bottleMl,
  String? note,
  String createdByDeviceId = 'device-test',
}) => CareEvent(
  id: id,
  startAt: startAt,
  endAt: endAt ?? startAt,
  pee: pee,
  poop: poop,
  diaperChange: diaperChange,
  adrigyl: adrigyl,
  bath: bath,
  eyeCare: eyeCare,
  noseCare: noseCare,
  umbilicalCare: umbilicalCare,
  bottleMl: bottleMl,
  note: note,
  createdByDeviceId: createdByDeviceId,
  createdAt: startAt,
  updatedAt: startAt,
);
```

- [ ] **Step 2: Écrire les tests (rouges)**

`test/features/events/domain/use_cases/validate_care_event_test.dart` :

```dart
import 'package:colette/core/result/failure.dart';
import 'package:colette/features/events/domain/use_cases/validate_care_event.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../../helpers/care_event_factory.dart';

void main() {
  const validate = ValidateCareEvent();
  final now = DateTime(2026, 9, 21, 14, 30);

  ValidationReason? reasonOf(Object? result) =>
      result is ValidationFailure ? result.reason : null;

  test('refuse un événement vide', () {
    final result = validate(makeEvent(startAt: now), now: now);
    expect(reasonOf(result.getLeft().toNullable()), ValidationReason.emptyEvent);
  });

  test('refuse une fin avant le début', () {
    final event = makeEvent(startAt: now, endAt: now.subtract(const Duration(minutes: 5)), pee: true);
    final result = validate(event, now: now);
    expect(reasonOf(result.getLeft().toNullable()), ValidationReason.endBeforeStart);
  });

  test('refuse un début dans le futur au-delà de la tolérance', () {
    final event = makeEvent(startAt: now.add(const Duration(minutes: 10)), pee: true);
    final result = validate(event, now: now);
    expect(reasonOf(result.getLeft().toNullable()), ValidationReason.startInFuture);
  });

  test('tolère un début 5 minutes dans le futur', () {
    final event = makeEvent(startAt: now.add(const Duration(minutes: 5)), pee: true);
    expect(validate(event, now: now).isRight(), isTrue);
  });

  test('refuse un biberon hors bornes', () {
    expect(
      reasonOf(validate(makeEvent(startAt: now, bottleMl: 5), now: now).getLeft().toNullable()),
      ValidationReason.bottleOutOfRange,
    );
    expect(
      reasonOf(validate(makeEvent(startAt: now, bottleMl: 310), now: now).getLeft().toNullable()),
      ValidationReason.bottleOutOfRange,
    );
  });

  test('accepte un biberon seul de 120 ml', () {
    expect(validate(makeEvent(startAt: now, bottleMl: 120), now: now).isRight(), isTrue);
  });
}
```

`test/features/events/data/firestore_events_repository_test.dart` :

```dart
import 'package:colette/features/events/data/repositories/firestore_events_repository.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../helpers/care_event_factory.dart';

void main() {
  const code = 'ABCDEFGH';
  final day = DateTime(2026, 9, 21);

  test('watchLatest trie du plus récent au plus ancien et respecte la limite', () async {
    final repo = FirestoreEventsRepository(FakeFirebaseFirestore());
    await repo.save(code, makeEvent(id: 'a', startAt: day.add(const Duration(hours: 8)), pee: true));
    await repo.save(code, makeEvent(id: 'b', startAt: day.add(const Duration(hours: 11)), pee: true));
    await repo.save(code, makeEvent(id: 'c', startAt: day.add(const Duration(hours: 14)), pee: true));
    final latest = await repo.watchLatest(code, limit: 2).first;
    expect(latest.map((e) => e.id), ['c', 'b']);
  });

  test('watchBetween ne renvoie que les événements du jour', () async {
    final repo = FirestoreEventsRepository(FakeFirebaseFirestore());
    await repo.save(code, makeEvent(id: 'hier', startAt: day.subtract(const Duration(hours: 2)), pee: true));
    await repo.save(code, makeEvent(id: 'today', startAt: day.add(const Duration(hours: 9)), pee: true));
    await repo.save(code, makeEvent(id: 'demain', startAt: day.add(const Duration(hours: 25)), pee: true));
    final today = await repo.watchBetween(code, from: day, to: day.add(const Duration(days: 1))).first;
    expect(today.map((e) => e.id), ['today']);
  });

  test('watchLatestBath et watchLatestBottle renvoient le dernier de chaque', () async {
    final repo = FirestoreEventsRepository(FakeFirebaseFirestore());
    await repo.save(code, makeEvent(id: 'b1', startAt: day.add(const Duration(hours: 8)), bottleMl: 90));
    await repo.save(code, makeEvent(id: 'bath', startAt: day.add(const Duration(hours: 9)), bath: true));
    await repo.save(code, makeEvent(id: 'b2', startAt: day.add(const Duration(hours: 11)), bottleMl: 120));
    expect((await repo.watchLatestBath(code).first)?.id, 'bath');
    expect((await repo.watchLatestBottle(code).first)?.id, 'b2');
    expect((await repo.getLatestBottle(code)).getRight().toNullable()?.id, 'b2');
  });

  test('watchLatestBath émet null sans bain', () async {
    final repo = FirestoreEventsRepository(FakeFirebaseFirestore());
    expect(await repo.watchLatestBath(code).first, isNull);
  });

  test('save écrase un événement existant et delete le retire', () async {
    final repo = FirestoreEventsRepository(FakeFirebaseFirestore());
    final event = makeEvent(id: 'e', startAt: day.add(const Duration(hours: 8)), pee: true);
    await repo.save(code, event);
    await repo.save(code, event.copyWith(poop: true, note: 'ok'));
    var latest = await repo.watchLatest(code, limit: 10).first;
    expect(latest.single.poop, isTrue);
    expect(latest.single.note, 'ok');
    await repo.delete(code, 'e');
    latest = await repo.watchLatest(code, limit: 10).first;
    expect(latest, isEmpty);
  });
}
```

- [ ] **Step 3: Vérifier l'échec**

Run: `flutter test test/features/events`
Expected: échec de compilation.

- [ ] **Step 4: Créer `lib/features/events/domain/use_cases/validate_care_event.dart`**

```dart
import 'package:colette/core/result/failure.dart';
import 'package:colette/features/events/domain/entities/care_event.dart';
import 'package:fpdart/fpdart.dart';

/// Règles de validité d'un événement avant enregistrement.
class ValidateCareEvent {
  const ValidateCareEvent();

  static const minBottleMl = 10;
  static const maxBottleMl = 300;
  static const futureTolerance = Duration(minutes: 5);

  Either<ValidationFailure, CareEvent> call(CareEvent event, {required DateTime now}) {
    if (event.isEmpty) return left(const ValidationFailure(ValidationReason.emptyEvent));
    if (event.endAt.isBefore(event.startAt)) {
      return left(const ValidationFailure(ValidationReason.endBeforeStart));
    }
    if (event.startAt.isAfter(now.add(futureTolerance))) {
      return left(const ValidationFailure(ValidationReason.startInFuture));
    }
    if (event.bottleMl case final ml? when ml < minBottleMl || ml > maxBottleMl) {
      return left(const ValidationFailure(ValidationReason.bottleOutOfRange));
    }
    return right(event);
  }
}
```

- [ ] **Step 5: Créer l'interface `lib/features/events/domain/repositories/events_repository.dart`**

```dart
import 'package:colette/core/result/failure.dart';
import 'package:colette/features/events/domain/entities/care_event.dart';
import 'package:fpdart/fpdart.dart';

/// Événements de soin d'un foyer.
abstract interface class EventsRepository {
  /// Les [limit] événements les plus récents, du plus récent au plus ancien.
  Stream<List<CareEvent>> watchLatest(String householdCode, {required int limit});

  /// Événements dont `startAt` est dans `[from, to[`, du plus récent au plus ancien.
  Stream<List<CareEvent>> watchBetween(
    String householdCode, {
    required DateTime from,
    required DateTime to,
  });

  Future<Either<Failure, List<CareEvent>>> getBetween(
    String householdCode, {
    required DateTime from,
    required DateTime to,
  });

  Stream<CareEvent?> watchLatestBath(String householdCode);

  Stream<CareEvent?> watchLatestBottle(String householdCode);

  Future<Either<Failure, CareEvent?>> getLatestBottle(String householdCode);

  /// Crée ou remplace l'événement (clé : `event.id`).
  Future<Either<Failure, void>> save(String householdCode, CareEvent event);

  Future<Either<Failure, void>> delete(String householdCode, String eventId);
}
```

- [ ] **Step 6: Créer le DTO et le repository**

`lib/features/events/data/dtos/care_event_dto.dart` :

```dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:colette/features/events/domain/entities/care_event.dart';

/// Conversion `CareEvent` ↔ document `events/{id}`.
abstract final class CareEventDto {
  static Map<String, dynamic> toMap(CareEvent event) => {
    'startAt': Timestamp.fromDate(event.startAt),
    'endAt': Timestamp.fromDate(event.endAt),
    'pee': event.pee,
    'poop': event.poop,
    'diaperChange': event.diaperChange,
    'adrigyl': event.adrigyl,
    'bath': event.bath,
    'eyeCare': event.eyeCare,
    'noseCare': event.noseCare,
    'umbilicalCare': event.umbilicalCare,
    'bottleMl': event.bottleMl,
    'hasBottle': event.hasBottle,
    'note': event.note,
    'createdByDeviceId': event.createdByDeviceId,
    'createdAt': Timestamp.fromDate(event.createdAt),
    'updatedAt': Timestamp.fromDate(event.updatedAt),
  };

  static CareEvent fromDoc(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data()!;
    return CareEvent(
      id: doc.id,
      startAt: (data['startAt'] as Timestamp).toDate(),
      endAt: (data['endAt'] as Timestamp).toDate(),
      pee: data['pee'] as bool? ?? false,
      poop: data['poop'] as bool? ?? false,
      diaperChange: data['diaperChange'] as bool? ?? false,
      adrigyl: data['adrigyl'] as bool? ?? false,
      bath: data['bath'] as bool? ?? false,
      eyeCare: data['eyeCare'] as bool? ?? false,
      noseCare: data['noseCare'] as bool? ?? false,
      umbilicalCare: data['umbilicalCare'] as bool? ?? false,
      bottleMl: (data['bottleMl'] as num?)?.toInt(),
      note: data['note'] as String?,
      createdByDeviceId: data['createdByDeviceId'] as String? ?? '',
      createdAt: (data['createdAt'] as Timestamp).toDate(),
      updatedAt: (data['updatedAt'] as Timestamp).toDate(),
    );
  }
}
```

`lib/features/events/data/repositories/firestore_events_repository.dart` :

```dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:colette/core/firebase/firestore_paths.dart';
import 'package:colette/core/result/failure.dart';
import 'package:colette/core/result/failure_mapper.dart';
import 'package:colette/features/events/data/dtos/care_event_dto.dart';
import 'package:colette/features/events/domain/entities/care_event.dart';
import 'package:colette/features/events/domain/repositories/events_repository.dart';
import 'package:fpdart/fpdart.dart';

/// Événements dans `households/{code}/events/{id}`.
class FirestoreEventsRepository implements EventsRepository {
  FirestoreEventsRepository(this._db);

  final FirebaseFirestore _db;

  CollectionReference<Map<String, dynamic>> _events(String code) =>
      _db.collection(FirestorePaths.households).doc(code).collection(FirestorePaths.events);

  Query<Map<String, dynamic>> _between(String code, DateTime from, DateTime to) => _events(code)
      .where('startAt', isGreaterThanOrEqualTo: Timestamp.fromDate(from))
      .where('startAt', isLessThan: Timestamp.fromDate(to))
      .orderBy('startAt', descending: true);

  Query<Map<String, dynamic>> _latestWhere(String code, String field) =>
      _events(code).where(field, isEqualTo: true).orderBy('startAt', descending: true).limit(1);

  List<CareEvent> _toList(QuerySnapshot<Map<String, dynamic>> snap) =>
      snap.docs.map(CareEventDto.fromDoc).toList();

  CareEvent? _firstOrNull(QuerySnapshot<Map<String, dynamic>> snap) =>
      snap.docs.isEmpty ? null : CareEventDto.fromDoc(snap.docs.first);

  @override
  Stream<List<CareEvent>> watchLatest(String householdCode, {required int limit}) =>
      _events(householdCode)
          .orderBy('startAt', descending: true)
          .limit(limit)
          .snapshots()
          .map(_toList);

  @override
  Stream<List<CareEvent>> watchBetween(
    String householdCode, {
    required DateTime from,
    required DateTime to,
  }) => _between(householdCode, from, to).snapshots().map(_toList);

  @override
  Future<Either<Failure, List<CareEvent>>> getBetween(
    String householdCode, {
    required DateTime from,
    required DateTime to,
  }) => guard(() async => _toList(await _between(householdCode, from, to).get()));

  @override
  Stream<CareEvent?> watchLatestBath(String householdCode) =>
      _latestWhere(householdCode, 'bath').snapshots().map(_firstOrNull);

  @override
  Stream<CareEvent?> watchLatestBottle(String householdCode) =>
      _latestWhere(householdCode, 'hasBottle').snapshots().map(_firstOrNull);

  @override
  Future<Either<Failure, CareEvent?>> getLatestBottle(String householdCode) =>
      guard(() async => _firstOrNull(await _latestWhere(householdCode, 'hasBottle').get()));

  @override
  Future<Either<Failure, void>> save(String householdCode, CareEvent event) =>
      guard(() => _events(householdCode).doc(event.id).set(CareEventDto.toMap(event)));

  @override
  Future<Either<Failure, void>> delete(String householdCode, String eventId) =>
      guard(() => _events(householdCode).doc(eventId).delete());
}
```

- [ ] **Step 7: Créer `lib/features/events/presentation/providers/events_providers.dart`**

```dart
import 'package:colette/core/clock/app_clock.dart';
import 'package:colette/core/dates/date_extensions.dart';
import 'package:colette/core/firebase/firebase_providers.dart';
import 'package:colette/features/events/data/repositories/firestore_events_repository.dart';
import 'package:colette/features/events/domain/entities/care_event.dart';
import 'package:colette/features/events/domain/repositories/events_repository.dart';
import 'package:colette/features/household/presentation/providers/household_providers.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'events_providers.g.dart';

/// Taille d'une page du journal.
const timelinePageSize = 30;

@riverpod
EventsRepository eventsRepository(Ref ref) =>
    FirestoreEventsRepository(ref.watch(firestoreProvider));

/// Événements du jour civil courant, du plus récent au plus ancien.
@riverpod
Stream<List<CareEvent>> todayEvents(Ref ref) {
  final code = ref.watch(currentHouseholdCodeProvider);
  if (code == null) return Stream.value(const []);
  final today = ref.watch(clockProvider).now().dateOnly;
  return ref
      .watch(eventsRepositoryProvider)
      .watchBetween(code, from: today, to: today.startOfNextDay);
}

/// Dernier bain enregistré, toutes dates confondues.
@riverpod
Stream<CareEvent?> latestBath(Ref ref) {
  final code = ref.watch(currentHouseholdCodeProvider);
  if (code == null) return Stream.value(null);
  return ref.watch(eventsRepositoryProvider).watchLatestBath(code);
}

/// Dernier biberon enregistré, toutes dates confondues.
@riverpod
Stream<CareEvent?> latestBottle(Ref ref) {
  final code = ref.watch(currentHouseholdCodeProvider);
  if (code == null) return Stream.value(null);
  return ref.watch(eventsRepositoryProvider).watchLatestBottle(code);
}

/// Nombre d'événements demandés au journal ; grandit par pages.
@riverpod
class TimelineLimit extends _$TimelineLimit {
  @override
  int build() => timelinePageSize;

  void loadMore() => state += timelinePageSize;
}

/// Événements du journal, limités par [TimelineLimit].
@riverpod
Stream<List<CareEvent>> timelineEvents(Ref ref) {
  final code = ref.watch(currentHouseholdCodeProvider);
  if (code == null) return Stream.value(const []);
  final limit = ref.watch(timelineLimitProvider);
  return ref.watch(eventsRepositoryProvider).watchLatest(code, limit: limit);
}
```

- [ ] **Step 8: Générer, analyser, tester**

Run: `dart run build_runner build -d && dart format lib test && dart analyze && flutter test test/features/events`
Expected: `No issues found!` puis `All tests passed!`.

- [ ] **Step 9: Commit**

```bash
git add lib/features/events test/features/events test/helpers
git commit -m "feat: feature events (validation, repository Firestore, providers du jour et du journal)"
```

---

### Task 11: Formulaire d'événement (contrôleur + bottom sheet)

**Files:**
- Create: `lib/features/events/domain/use_cases/new_event_draft.dart`
- Create: `lib/features/events/presentation/providers/event_form_controller.dart`
- Create: `lib/features/events/presentation/widgets/event_form_sheet.dart`, `bottle_field.dart`
- Create: `lib/core/dates/time_format.dart`
- Modify: `lib/l10n/app_fr.arb` (ajout de `unitMl`)
- Test: `test/features/events/domain/use_cases/new_event_draft_test.dart`, `test/features/events/presentation/event_form_controller_test.dart`, `test/features/events/presentation/event_form_sheet_test.dart`

- [ ] **Step 1: Ajouter les clés `unitMl` et `fieldQuantity` dans `lib/l10n/app_fr.arb`**

Insérer après la ligne `"bottleMl": "{ml} ml",` et son bloc `@bottleMl` :

```json
  "unitMl": "ml",
  "fieldQuantity": "Quantité",
```

- [ ] **Step 2: Écrire les tests (rouges)**

`test/features/events/domain/use_cases/new_event_draft_test.dart` :

```dart
import 'package:colette/features/events/domain/use_cases/new_event_draft.dart';
import 'package:colette/shared/domain/care_type.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  final now = DateTime(2026, 9, 21, 14, 30);

  test('le brouillon est daté de maintenant, vide, avec l\'appareil courant', () {
    final draft = newEventDraft(now: now, deviceId: 'dev-1', id: 'e1');
    expect(draft.startAt, now);
    expect(draft.endAt, now);
    expect(draft.createdByDeviceId, 'dev-1');
    expect(draft.isEmpty, isTrue);
  });

  test('preChecked et bottleMl préremplissent le brouillon', () {
    final draft = newEventDraft(
      now: now,
      deviceId: 'dev-1',
      id: 'e1',
      preChecked: CareType.adrigyl,
      bottleMl: 120,
    );
    expect(draft.adrigyl, isTrue);
    expect(draft.bottleMl, 120);
  });
}
```

`test/features/events/presentation/event_form_controller_test.dart` :

```dart
import 'package:colette/core/clock/app_clock.dart';
import 'package:colette/core/result/failure.dart';
import 'package:colette/features/events/domain/entities/care_event.dart';
import 'package:colette/features/events/domain/repositories/events_repository.dart';
import 'package:colette/features/events/presentation/providers/event_form_controller.dart';
import 'package:colette/features/events/presentation/providers/events_providers.dart';
import 'package:colette/features/household/presentation/providers/household_providers.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:mocktail/mocktail.dart';

import '../../../helpers/care_event_factory.dart';
import '../../../helpers/in_memory_household_local_store.dart';

class MockEventsRepository extends Mock implements EventsRepository {}

void main() {
  final now = DateTime(2026, 9, 21, 14, 30);
  late MockEventsRepository repo;
  late ProviderContainer container;

  setUpAll(() => registerFallbackValue(makeEvent(startAt: DateTime(2026))));

  setUp(() {
    repo = MockEventsRepository();
    container = ProviderContainer(
      overrides: [
        eventsRepositoryProvider.overrideWithValue(repo),
        clockProvider.overrideWithValue(FixedClock(now)),
        householdLocalStoreProvider.overrideWithValue(
          InMemoryHouseholdLocalStore(householdCode: 'ABCDEFGH'),
        ),
      ],
    );
    addTearDown(container.dispose);
  });

  test('submit valide, met à jour updatedAt et enregistre', () async {
    when(() => repo.save(any(), any())).thenAnswer((_) async => right(null));
    final draft = makeEvent(startAt: now.subtract(const Duration(hours: 1)), pee: true);
    final saved = await container.read(eventFormControllerProvider.notifier).submit(draft);
    expect(saved, isNotNull);
    expect(saved!.updatedAt, now);
    final captured = verify(() => repo.save('ABCDEFGH', captureAny())).captured.single as CareEvent;
    expect(captured.pee, isTrue);
  });

  test('submit refuse un brouillon vide sans écrire', () async {
    final saved = await container
        .read(eventFormControllerProvider.notifier)
        .submit(makeEvent(startAt: now));
    expect(saved, isNull);
    expect(container.read(eventFormControllerProvider).error, isA<ValidationFailure>());
    verifyNever(() => repo.save(any(), any()));
  });

  test('delete appelle le repository', () async {
    when(() => repo.delete('ABCDEFGH', 'e1')).thenAnswer((_) async => right(null));
    final ok = await container.read(eventFormControllerProvider.notifier).delete('e1');
    expect(ok, isTrue);
  });
}
```

`test/features/events/presentation/event_form_sheet_test.dart` :

```dart
import 'package:colette/core/clock/app_clock.dart';
import 'package:colette/core/ids/id_generator.dart';
import 'package:colette/features/baby/presentation/providers/baby_providers.dart';
import 'package:colette/features/events/domain/entities/care_event.dart';
import 'package:colette/features/events/domain/repositories/events_repository.dart';
import 'package:colette/features/events/presentation/providers/events_providers.dart';
import 'package:colette/features/events/presentation/widgets/event_form_sheet.dart';
import 'package:colette/features/household/presentation/providers/household_providers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:mocktail/mocktail.dart';

import '../../../helpers/care_event_factory.dart';
import '../../../helpers/in_memory_household_local_store.dart';
import '../../../helpers/pump_app.dart';

class MockEventsRepository extends Mock implements EventsRepository {}

void main() {
  final now = DateTime(2026, 9, 21, 14, 30);
  late MockEventsRepository repo;

  setUpAll(() => registerFallbackValue(makeEvent(startAt: DateTime(2026))));

  setUp(() {
    repo = MockEventsRepository();
    when(() => repo.save(any(), any())).thenAnswer((_) async => right(null));
  });

  Future<void> pumpSheet(WidgetTester tester) => pumpApp(
    tester,
    const Scaffold(body: EventFormSheet()),
    overrides: [
      eventsRepositoryProvider.overrideWithValue(repo),
      clockProvider.overrideWithValue(FixedClock(now)),
      idGeneratorProvider.overrideWithValue(const FixedIdGenerator('e-new')),
      householdLocalStoreProvider.overrideWithValue(
        InMemoryHouseholdLocalStore(householdCode: 'ABCDEFGH', deviceId: 'dev-1'),
      ),
      babyProfileProvider.overrideWith((ref) => Stream.value(null)),
    ],
  );

  FilledButton saveButton(WidgetTester tester) =>
      tester.widget<FilledButton>(find.widgetWithText(FilledButton, 'Enregistrer'));

  testWidgets('le bouton Enregistrer est désactivé tant que rien n\'est coché', (tester) async {
    await pumpSheet(tester);
    expect(saveButton(tester).onPressed, isNull);
  });

  testWidgets('cocher Adrigyl puis Enregistrer sauvegarde l\'événement', (tester) async {
    await pumpSheet(tester);
    await tester.tap(find.text('Adrigyl'));
    await tester.pump();
    expect(saveButton(tester).onPressed, isNotNull);
    await tester.tap(find.widgetWithText(FilledButton, 'Enregistrer'));
    await tester.pumpAndSettle();
    final saved = verify(() => repo.save('ABCDEFGH', captureAny())).captured.single as CareEvent;
    expect(saved.id, 'e-new');
    expect(saved.adrigyl, isTrue);
    expect(saved.createdByDeviceId, 'dev-1');
    expect(saved.startAt, now);
  });

  testWidgets('activer Biberon propose 120 ml par défaut', (tester) async {
    await pumpSheet(tester);
    await tester.tap(find.byType(Switch));
    await tester.pump();
    expect(find.text('120 ml'), findsWidgets);
    expect(saveButton(tester).onPressed, isNotNull);
  });
}
```

- [ ] **Step 3: Vérifier l'échec**

Run: `flutter test test/features/events`
Expected: échec de compilation.

- [ ] **Step 4: Créer `lib/features/events/domain/use_cases/new_event_draft.dart`**

```dart
import 'package:colette/features/events/domain/entities/care_event.dart';
import 'package:colette/shared/domain/care_type.dart';

/// Brouillon d'événement daté de [now], éventuellement pré-coché.
CareEvent newEventDraft({
  required DateTime now,
  required String deviceId,
  required String id,
  CareType? preChecked,
  int? bottleMl,
}) {
  final base = CareEvent(
    id: id,
    startAt: now,
    endAt: now,
    bottleMl: bottleMl,
    createdByDeviceId: deviceId,
    createdAt: now,
    updatedAt: now,
  );
  return preChecked == null ? base : base.toggle(preChecked, true);
}
```

- [ ] **Step 5: Créer `lib/core/dates/time_format.dart`**

```dart
import 'package:intl/intl.dart';

/// « 14h32 ».
String formatHourMinute(DateTime time) => DateFormat("HH'h'mm", 'fr').format(time);

/// « lun. 21 sept., 14h32 ».
String formatDayAndTime(DateTime time) => DateFormat("EEE d MMM, HH'h'mm", 'fr').format(time);
```

- [ ] **Step 6: Créer `lib/features/events/presentation/providers/event_form_controller.dart`**

```dart
import 'dart:async';

import 'package:colette/core/clock/app_clock.dart';
import 'package:colette/core/result/failure.dart';
import 'package:colette/features/events/domain/entities/care_event.dart';
import 'package:colette/features/events/domain/use_cases/validate_care_event.dart';
import 'package:colette/features/events/presentation/providers/events_providers.dart';
import 'package:colette/features/household/presentation/providers/household_providers.dart';
import 'package:fpdart/fpdart.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'event_form_controller.g.dart';

/// Enregistrement et suppression d'un événement. L'état porte l'échec éventuel.
@riverpod
class EventFormController extends _$EventFormController {
  @override
  FutureOr<void> build() {}

  /// Valide puis enregistre [draft]. Renvoie l'événement enregistré, ou `null`.
  Future<CareEvent?> submit(CareEvent draft) async {
    final code = ref.read(currentHouseholdCodeProvider);
    if (code == null) return null;
    final now = ref.read(clockProvider).now();
    final validated = const ValidateCareEvent()(draft.copyWith(updatedAt: now), now: now);
    state = const AsyncLoading();
    final result = await validated.fold<Future<Either<Failure, CareEvent>>>(
      (failure) async => left(failure),
      (event) async {
        final saved = await ref.read(eventsRepositoryProvider).save(code, event);
        return saved.map((_) => event);
      },
    );
    state = result.fold(
      (failure) => AsyncError(failure, StackTrace.current),
      (_) => const AsyncData(null),
    );
    return result.getRight().toNullable();
  }

  Future<bool> delete(String eventId) async {
    final code = ref.read(currentHouseholdCodeProvider);
    if (code == null) return false;
    state = const AsyncLoading();
    final result = await ref.read(eventsRepositoryProvider).delete(code, eventId);
    state = result.fold(
      (failure) => AsyncError(failure, StackTrace.current),
      (_) => const AsyncData(null),
    );
    return result.isRight();
  }
}
```

- [ ] **Step 7: Créer `lib/features/events/presentation/widgets/bottle_field.dart`**

```dart
import 'package:colette/core/theme/app_colors.dart';
import 'package:colette/core/theme/design_tokens.dart';
import 'package:colette/core/theme/text_styles.dart';
import 'package:colette/features/events/domain/use_cases/validate_care_event.dart';
import 'package:colette/l10n/generated/app_localizations.dart';
import 'package:colette/shared/ui/widgets/int_stepper_row.dart';
import 'package:flutter/material.dart';

/// Interrupteur « Biberon » + stepper de 10 ml + raccourcis.
class BottleField extends StatelessWidget {
  const BottleField({super.key, required this.bottleMl, required this.onChanged});

  static const presets = [60, 90, 120, 150, 180, 210];
  static const defaultMl = 120;

  /// `null` quand aucun biberon.
  final int? bottleMl;
  final ValueChanged<int?> onChanged;

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    final ml = bottleMl;
    return Column(
      crossAxisAlignment: .start,
      children: [
        Row(
          children: [
            Icon(Icons.local_drink_outlined, color: context.appColor(AppColors.categoryFeeding)),
            AppSpacing.sm.horizontalSpace,
            Expanded(child: Text(s.careBottle, style: Theme.of(context).coletteTextStyles.bodyMedium)),
            Switch(
              value: ml != null,
              onChanged: (on) => onChanged(on ? defaultMl : null),
            ),
          ],
        ),
        if (ml != null) ...[
          IntStepperRow(
            label: s.fieldQuantity,
            value: ml,
            min: ValidateCareEvent.minBottleMl,
            max: ValidateCareEvent.maxBottleMl,
            step: 10,
            suffix: s.unitMl,
            onChanged: onChanged,
          ),
          Wrap(
            spacing: AppSpacing.sm.value,
            children: [
              for (final preset in presets)
                ChoiceChip(
                  label: Text(s.bottleMl(preset)),
                  selected: preset == ml,
                  onSelected: (_) => onChanged(preset),
                ),
            ],
          ),
        ],
      ],
    );
  }
}
```

- [ ] **Step 8: Créer `lib/features/events/presentation/widgets/event_form_sheet.dart`**

```dart
import 'package:colette/core/clock/app_clock.dart';
import 'package:colette/core/dates/time_format.dart';
import 'package:colette/core/ids/id_generator.dart';
import 'package:colette/core/theme/design_tokens.dart';
import 'package:colette/core/theme/text_styles.dart';
import 'package:colette/core/ui/date_time_picker.dart';
import 'package:colette/core/ui/failure_message.dart';
import 'package:colette/features/baby/presentation/providers/baby_providers.dart';
import 'package:colette/features/events/domain/entities/care_event.dart';
import 'package:colette/features/events/domain/use_cases/new_event_draft.dart';
import 'package:colette/features/events/presentation/providers/event_form_controller.dart';
import 'package:colette/features/events/presentation/widgets/bottle_field.dart';
import 'package:colette/features/household/presentation/providers/household_providers.dart';
import 'package:colette/l10n/generated/app_localizations.dart';
import 'package:colette/shared/domain/care_type.dart';
import 'package:colette/shared/ui/widgets/care_chip.dart';
import 'package:colette/shared/ui/widgets/date_field.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Ouvre le formulaire en bottom sheet. Renvoie `true` si un événement a été enregistré.
Future<bool?> showEventFormSheet(
  BuildContext context, {
  CareEvent? initial,
  CareType? preChecked,
  int? suggestedBottleMl,
}) => showModalBottomSheet<bool>(
  context: context,
  isScrollControlled: true,
  useSafeArea: true,
  builder: (_) => EventFormSheet(
    initial: initial,
    preChecked: preChecked,
    suggestedBottleMl: suggestedBottleMl,
  ),
);

/// Formulaire de création ou d'édition d'un événement.
class EventFormSheet extends ConsumerStatefulWidget {
  const EventFormSheet({super.key, this.initial, this.preChecked, this.suggestedBottleMl});

  final CareEvent? initial;
  final CareType? preChecked;
  final int? suggestedBottleMl;

  @override
  ConsumerState<EventFormSheet> createState() => _EventFormSheetState();
}

class _EventFormSheetState extends ConsumerState<EventFormSheet> {
  late CareEvent _draft;
  late final TextEditingController _noteController;

  bool get _isEditing => widget.initial != null;

  @override
  void initState() {
    super.initState();
    _draft = widget.initial ??
        newEventDraft(
          now: ref.read(clockProvider).now(),
          deviceId: ref.read(deviceIdProvider),
          id: ref.read(idGeneratorProvider).newId(),
          preChecked: widget.preChecked,
          bottleMl: widget.suggestedBottleMl,
        );
    _noteController = TextEditingController(text: _draft.note ?? '');
  }

  @override
  void dispose() {
    _noteController.dispose();
    super.dispose();
  }

  Future<void> _pickTime({required bool isStart}) async {
    final picked = await showColetteDateTimePicker(
      context,
      initial: isStart ? _draft.startAt : _draft.endAt,
      mode: CupertinoDatePickerMode.dateAndTime,
      minimum: isStart ? null : _draft.startAt,
    );
    if (picked == null) return;
    setState(() {
      _draft = isStart
          ? _draft.copyWith(startAt: picked, endAt: picked.isAfter(_draft.endAt) ? picked : _draft.endAt)
          : _draft.copyWith(endAt: picked);
    });
  }

  Future<void> _save() async {
    final note = _noteController.text.trim();
    final saved = await ref
        .read(eventFormControllerProvider.notifier)
        .submit(_draft.copyWith(note: note.isEmpty ? null : note));
    if (saved != null && mounted) await Navigator.of(context).maybePop(true);
  }

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    final styles = Theme.of(context).coletteTextStyles;
    ref.listen(eventFormControllerProvider, (_, next) {
      if (next case AsyncError(:final error)) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(failureMessage(error, s))),
        );
      }
    });
    final isLoading = ref.watch(eventFormControllerProvider) is AsyncLoading;
    final umbilicalEnabled =
        ref.watch(babyProfileProvider).value?.careSettings.umbilicalCareEnabled ?? true;
    final visibleCares = CareType.values
        .where((type) => type != CareType.umbilicalCare || umbilicalEnabled || _draft.umbilicalCare)
        .toList();

    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(context).bottom),
      child: ListView(
        shrinkWrap: true,
        padding: AppSpacing.lg.all,
        children: [
          Text(_isEditing ? s.eventFormEditTitle : s.eventFormNewTitle, style: styles.heading2),
          AppSpacing.md.verticalSpace,
          Row(
            spacing: AppSpacing.sm.value,
            children: [
              Expanded(
                child: DateField(
                  label: s.fieldStartAt,
                  value: formatHourMinute(_draft.startAt),
                  onTap: () => _pickTime(isStart: true),
                ),
              ),
              Expanded(
                child: DateField(
                  label: s.fieldEndAt,
                  value: formatHourMinute(_draft.endAt),
                  onTap: () => _pickTime(isStart: false),
                ),
              ),
            ],
          ),
          AppSpacing.md.verticalSpace,
          Wrap(
            spacing: AppSpacing.sm.value,
            runSpacing: AppSpacing.sm.value,
            children: [
              for (final type in visibleCares)
                CareChip(
                  type: type,
                  selected: _draft.has(type),
                  onChanged: (value) => setState(() => _draft = _draft.toggle(type, value)),
                ),
            ],
          ),
          AppSpacing.md.verticalSpace,
          BottleField(
            bottleMl: _draft.bottleMl,
            onChanged: (ml) => setState(() => _draft = _draft.copyWith(bottleMl: ml)),
          ),
          AppSpacing.md.verticalSpace,
          TextField(
            controller: _noteController,
            decoration: InputDecoration(labelText: s.fieldNote, hintText: s.fieldNoteHint),
            minLines: 1,
            maxLines: 3,
            textCapitalization: .sentences,
          ),
          AppSpacing.lg.verticalSpace,
          FilledButton(
            onPressed: _draft.isEmpty || isLoading ? null : _save,
            child: Text(s.actionSave),
          ),
        ],
      ),
    );
  }
}
```

- [ ] **Step 9: Générer, analyser, tester**

Run: `flutter pub get && dart run build_runner build -d && dart format lib test && dart analyze && flutter test test/features/events`
Expected: `No issues found!` puis `All tests passed!`. (`flutter pub get` régénère `S` avec `unitMl`.)

- [ ] **Step 10: Commit**

```bash
git add lib test
git commit -m "feat: formulaire d'événement (brouillon, contrôleur, bottom sheet, champ biberon)"
```

---

### Task 12: Onglet Journal (timeline groupée, pagination, édition, suppression)

**Files:**
- Create: `lib/features/events/presentation/day_label.dart`, `lib/features/events/presentation/timeline_grouping.dart`
- Create: `lib/features/events/presentation/widgets/event_tile.dart`, `day_header_delegate.dart`
- Modify (remplacement complet) : `lib/features/events/presentation/pages/timeline_page.dart`
- Test: `test/features/events/presentation/day_label_test.dart`, `test/features/events/presentation/timeline_grouping_test.dart`, `test/features/events/presentation/timeline_page_test.dart`

- [ ] **Step 1: Écrire les tests (rouges)**

`test/features/events/presentation/day_label_test.dart` :

```dart
import 'package:colette/features/events/presentation/day_label.dart';
import 'package:colette/l10n/generated/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  final now = DateTime(2026, 9, 21, 14);
  late S s;

  setUpAll(() async => s = await S.delegate.load(const Locale('fr')));

  test('aujourd\'hui et hier', () {
    expect(dayLabel(DateTime(2026, 9, 21), now: now, s: s), 'Aujourd\'hui');
    expect(dayLabel(DateTime(2026, 9, 20), now: now, s: s), 'Hier');
  });

  test('les autres jours sont écrits en toutes lettres, capitalisés', () {
    expect(dayLabel(DateTime(2026, 9, 15), now: now, s: s), 'Mardi 15 septembre');
  });
}
```

`test/features/events/presentation/timeline_grouping_test.dart` :

```dart
import 'package:colette/features/events/presentation/timeline_grouping.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../helpers/care_event_factory.dart';

void main() {
  test('groupe par jour civil en conservant l\'ordre', () {
    final events = [
      makeEvent(id: 'c', startAt: DateTime(2026, 9, 21, 14), pee: true),
      makeEvent(id: 'b', startAt: DateTime(2026, 9, 21, 8), pee: true),
      makeEvent(id: 'a', startAt: DateTime(2026, 9, 20, 23), pee: true),
    ];
    final groups = groupEventsByDay(events);
    expect(groups.map((g) => g.day), [DateTime(2026, 9, 21), DateTime(2026, 9, 20)]);
    expect(groups.first.events.map((e) => e.id), ['c', 'b']);
    expect(groups.last.events.map((e) => e.id), ['a']);
  });

  test('liste vide donne aucun groupe', () {
    expect(groupEventsByDay(const []), isEmpty);
  });
}
```

`test/features/events/presentation/timeline_page_test.dart` :

```dart
import 'package:colette/core/clock/app_clock.dart';
import 'package:colette/features/events/domain/repositories/events_repository.dart';
import 'package:colette/features/events/presentation/pages/timeline_page.dart';
import 'package:colette/features/events/presentation/providers/events_providers.dart';
import 'package:colette/features/household/presentation/providers/household_providers.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import '../../../helpers/care_event_factory.dart';
import '../../../helpers/in_memory_household_local_store.dart';
import '../../../helpers/pump_app.dart';

class MockEventsRepository extends Mock implements EventsRepository {}

void main() {
  final now = DateTime(2026, 9, 21, 14);

  testWidgets('affiche les événements groupés par jour', (tester) async {
    final repo = MockEventsRepository();
    when(() => repo.watchLatest(any(), limit: any(named: 'limit'))).thenAnswer(
      (_) => Stream.value([
        makeEvent(id: 'today', startAt: DateTime(2026, 9, 21, 9, 5), bottleMl: 120, diaperChange: true),
        makeEvent(id: 'yesterday', startAt: DateTime(2026, 9, 20, 22), bath: true),
      ]),
    );
    await pumpApp(
      tester,
      const TimelinePage(),
      overrides: [
        eventsRepositoryProvider.overrideWithValue(repo),
        clockProvider.overrideWithValue(FixedClock(now)),
        householdLocalStoreProvider.overrideWithValue(
          InMemoryHouseholdLocalStore(householdCode: 'ABCDEFGH'),
        ),
      ],
    );
    expect(find.text('Aujourd\'hui'), findsOneWidget);
    expect(find.text('Hier'), findsOneWidget);
    expect(find.text('09h05'), findsOneWidget);
    expect(find.text('120 ml'), findsOneWidget);
  });

  testWidgets('affiche l\'état vide sans événement', (tester) async {
    final repo = MockEventsRepository();
    when(() => repo.watchLatest(any(), limit: any(named: 'limit')))
        .thenAnswer((_) => Stream.value(const []));
    await pumpApp(
      tester,
      const TimelinePage(),
      overrides: [
        eventsRepositoryProvider.overrideWithValue(repo),
        clockProvider.overrideWithValue(FixedClock(now)),
        householdLocalStoreProvider.overrideWithValue(
          InMemoryHouseholdLocalStore(householdCode: 'ABCDEFGH'),
        ),
      ],
    );
    expect(find.textContaining('Aucun événement'), findsOneWidget);
  });
}
```

- [ ] **Step 2: Vérifier l'échec**

Run: `flutter test test/features/events/presentation`
Expected: échec de compilation.

- [ ] **Step 3: Créer `lib/features/events/presentation/day_label.dart` et `timeline_grouping.dart`**

`lib/features/events/presentation/day_label.dart` :

```dart
import 'package:colette/core/dates/date_extensions.dart';
import 'package:colette/l10n/generated/app_localizations.dart';
import 'package:intl/intl.dart';

/// « Aujourd'hui », « Hier », sinon « Mardi 15 septembre ».
String dayLabel(DateTime day, {required DateTime now, required S s}) {
  if (day.isSameDay(now)) return s.dayToday;
  if (day.isSameDay(now.subtract(const Duration(days: 1)))) return s.dayYesterday;
  final text = DateFormat('EEEE d MMMM', 'fr').format(day);
  return '${text[0].toUpperCase()}${text.substring(1)}';
}
```

`lib/features/events/presentation/timeline_grouping.dart` :

```dart
import 'package:colette/core/dates/date_extensions.dart';
import 'package:colette/features/events/domain/entities/care_event.dart';

/// Un jour du journal et ses événements, dans l'ordre reçu.
typedef TimelineDay = ({DateTime day, List<CareEvent> events});

/// Regroupe des événements déjà triés par jour civil.
List<TimelineDay> groupEventsByDay(List<CareEvent> events) {
  final groups = <TimelineDay>[];
  for (final event in events) {
    final day = event.startAt.dateOnly;
    if (groups.isNotEmpty && groups.last.day == day) {
      groups.last.events.add(event);
    } else {
      groups.add((day: day, events: [event]));
    }
  }
  return groups;
}
```

- [ ] **Step 4: Créer `lib/features/events/presentation/widgets/day_header_delegate.dart`**

```dart
import 'package:colette/core/theme/app_colors.dart';
import 'package:colette/core/theme/design_tokens.dart';
import 'package:colette/core/theme/text_styles.dart';
import 'package:flutter/material.dart';

/// En-tête de jour épinglé en haut de son groupe.
class DayHeaderDelegate extends SliverPersistentHeaderDelegate {
  const DayHeaderDelegate(this.label);

  final String label;

  @override
  double get minExtent => AppSize.lg.value;

  @override
  double get maxExtent => AppSize.lg.value;

  @override
  Widget build(BuildContext context, double shrinkOffset, bool overlapsContent) {
    return ColoredBox(
      color: context.appColor(AppColors.pageBackground),
      child: Padding(
        padding: AppSpacing.symmetric(horizontal: AppSpacing.md, vertical: AppSpacing.sm),
        child: Align(
          alignment: .centerLeft,
          child: Text(
            label,
            style: Theme.of(context).coletteTextStyles.label.copyWith(
              color: context.appColor(AppColors.textSecondary),
            ),
          ),
        ),
      ),
    );
  }

  @override
  bool shouldRebuild(DayHeaderDelegate oldDelegate) => oldDelegate.label != label;
}
```

- [ ] **Step 5: Créer `lib/features/events/presentation/widgets/event_tile.dart`**

```dart
import 'package:colette/core/dates/time_format.dart';
import 'package:colette/core/theme/app_colors.dart';
import 'package:colette/core/theme/design_tokens.dart';
import 'package:colette/core/theme/text_styles.dart';
import 'package:colette/features/events/domain/entities/care_event.dart';
import 'package:colette/l10n/generated/app_localizations.dart';
import 'package:colette/shared/ui/care_type_ui.dart';
import 'package:colette/shared/ui/widgets/colette_card_surface.dart';
import 'package:flutter/material.dart';

/// Ligne du journal : heure, icônes des soins, biberon, note. Glisser pour supprimer.
class EventTile extends StatelessWidget {
  const EventTile({
    super.key,
    required this.event,
    required this.onTap,
    required this.onConfirmDelete,
  });

  final CareEvent event;
  final VoidCallback onTap;

  /// Doit renvoyer `true` pour confirmer la suppression, puis la réaliser.
  final Future<bool> Function() onConfirmDelete;

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    final styles = Theme.of(context).coletteTextStyles;
    final secondary = context.appColor(AppColors.textSecondary);
    return Padding(
      padding: AppSpacing.only(left: AppSpacing.md, right: AppSpacing.md, bottom: AppSpacing.sm),
      child: Dismissible(
        key: ValueKey(event.id),
        direction: DismissDirection.endToStart,
        confirmDismiss: (_) => onConfirmDelete(),
        background: Container(
          alignment: .centerRight,
          padding: AppSpacing.md.horizontal,
          decoration: BoxDecoration(
            color: context.appColor(AppColors.error),
            borderRadius: AppRadius.lg.circular,
          ),
          child: Icon(Icons.delete_outline, color: context.appColor(AppColors.onPrimary)),
        ),
        child: ColetteCardSurface(
          onTap: onTap,
          child: Row(
            crossAxisAlignment: .start,
            children: [
              Column(
                crossAxisAlignment: .start,
                children: [
                  Text(formatHourMinute(event.startAt), style: styles.bodyMedium),
                  if (!event.endAt.isAtSameMomentAs(event.startAt))
                    Text(
                      formatHourMinute(event.endAt),
                      style: styles.small.copyWith(color: secondary),
                    ),
                ],
              ),
              AppSpacing.md.horizontalSpace,
              Expanded(
                child: Column(
                  crossAxisAlignment: .start,
                  spacing: AppSpacing.xs.value,
                  children: [
                    Wrap(
                      spacing: AppSpacing.xs.value,
                      runSpacing: AppSpacing.xs.value,
                      crossAxisAlignment: .center,
                      children: [
                        for (final type in event.checkedCares)
                          _CareDot(icon: type.icon, color: context.appColor(type.color)),
                        if (event.bottleMl case final ml?)
                          _BottleBadge(label: s.bottleMl(ml)),
                      ],
                    ),
                    if (event.note case final note?)
                      Text(
                        note,
                        maxLines: 1,
                        overflow: .ellipsis,
                        style: styles.small.copyWith(color: secondary),
                      ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _CareDot extends StatelessWidget {
  const _CareDot({required this.icon, required this.color});

  final IconData icon;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: AppSize.md.value,
      height: AppSize.md.value,
      decoration: BoxDecoration(
        color: AppOpacity.light.applyTo(color),
        borderRadius: AppRadius.round.circular,
      ),
      child: Icon(icon, size: AppSize.xs.value, color: color),
    );
  }
}

class _BottleBadge extends StatelessWidget {
  const _BottleBadge({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: AppSpacing.symmetric(horizontal: AppSpacing.sm, vertical: AppSpacing.xxs),
      decoration: BoxDecoration(
        color: context.appColor(AppColors.categoryFeeding),
        borderRadius: AppRadius.round.circular,
      ),
      child: Text(
        label,
        style: Theme.of(context).coletteTextStyles.label.copyWith(
          color: context.appColor(AppColors.onPrimary),
        ),
      ),
    );
  }
}
```

- [ ] **Step 6: Remplacer `lib/features/events/presentation/pages/timeline_page.dart`**

```dart
import 'package:colette/core/clock/app_clock.dart';
import 'package:colette/core/theme/design_tokens.dart';
import 'package:colette/features/events/domain/entities/care_event.dart';
import 'package:colette/features/events/presentation/day_label.dart';
import 'package:colette/features/events/presentation/providers/event_form_controller.dart';
import 'package:colette/features/events/presentation/providers/events_providers.dart';
import 'package:colette/features/events/presentation/timeline_grouping.dart';
import 'package:colette/features/events/presentation/widgets/day_header_delegate.dart';
import 'package:colette/features/events/presentation/widgets/event_form_sheet.dart';
import 'package:colette/features/events/presentation/widgets/event_tile.dart';
import 'package:colette/l10n/generated/app_localizations.dart';
import 'package:colette/shared/ui/widgets/empty_state.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Onglet Journal : événements groupés par jour, pagination par défilement.
class TimelinePage extends ConsumerWidget {
  const TimelinePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final s = S.of(context);
    final events = ref.watch(timelineEventsProvider);
    return Scaffold(
      appBar: AppBar(title: Text(s.journalTitle)),
      floatingActionButton: FloatingActionButton(
        onPressed: () => showEventFormSheet(context),
        child: const Icon(Icons.add),
      ),
      // `hasValue` plutôt que `AsyncData` : quand la limite grandit, le provider
      // repasse en AsyncLoading avec la valeur précédente ; la liste doit rester montée.
      body: switch (events) {
        AsyncValue(hasValue: true, value: final value) when value.isEmpty =>
          EmptyState(icon: Icons.view_timeline_outlined, message: s.journalEmpty),
        AsyncValue(hasValue: true, value: final value) => _TimelineList(events: value),
        AsyncError() => EmptyState(icon: Icons.error_outline, message: s.errorUnknown),
        _ => const Center(child: CircularProgressIndicator()),
      },
    );
  }
}

class _TimelineList extends ConsumerWidget {
  const _TimelineList({required this.events});

  static const _loadMoreThreshold = 300.0;

  final List<CareEvent> events;

  bool _onScroll(WidgetRef ref, ScrollNotification notification) {
    final lastPageFull = events.length >= ref.read(timelineLimitProvider);
    if (lastPageFull && notification.metrics.extentAfter < _loadMoreThreshold) {
      ref.read(timelineLimitProvider.notifier).loadMore();
    }
    return false;
  }

  Future<bool> _confirmDelete(BuildContext context, WidgetRef ref, CareEvent event) async {
    final s = S.of(context);
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(s.deleteEventTitle),
        content: Text(s.deleteEventBody),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: Text(s.actionCancel),
          ),
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: Text(s.actionDelete),
          ),
        ],
      ),
    );
    if (confirmed != true) return false;
    final deleted = await ref.read(eventFormControllerProvider.notifier).delete(event.id);
    if (!deleted && context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(s.errorUnknown)));
    }
    return deleted;
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Garde le contrôleur autoDispose vivant pendant l'await d'une suppression.
    ref.watch(eventFormControllerProvider);
    final s = S.of(context);
    final now = ref.watch(clockProvider).now();
    final groups = groupEventsByDay(events);
    final lastPageFull = events.length >= ref.watch(timelineLimitProvider);
    return NotificationListener<ScrollNotification>(
      onNotification: (notification) => _onScroll(ref, notification),
      child: CustomScrollView(
        slivers: [
          for (final group in groups)
            SliverMainAxisGroup(
              slivers: [
                SliverPersistentHeader(
                  pinned: true,
                  delegate: DayHeaderDelegate(dayLabel(group.day, now: now, s: s)),
                ),
                SliverList.builder(
                  itemCount: group.events.length,
                  itemBuilder: (context, index) {
                    final event = group.events[index];
                    return EventTile(
                      key: ValueKey(event.id),
                      event: event,
                      onTap: () => showEventFormSheet(context, initial: event),
                      onConfirmDelete: () => _confirmDelete(context, ref, event),
                    );
                  },
                ),
              ],
            ),
          SliverToBoxAdapter(
            child: Padding(
              padding: AppSpacing.lg.all,
              child: lastPageFull
                  ? const Center(child: CircularProgressIndicator())
                  : AppSpacing.xxl.verticalSpace,
            ),
          ),
        ],
      ),
    );
  }
}
```

**Note post-revue (appliquée dans le code) :** `timeline_page_test.dart` contient aussi un test « charger plus conserve la liste affichée pendant le rechargement » et un test « glisser puis confirmer supprime l'événement ».

- [ ] **Step 7: Analyser et tester**

Run: `dart format lib test && dart analyze && flutter test test/features/events`
Expected: `No issues found!` puis `All tests passed!`.

- [ ] **Step 8: Commit**

```bash
git add lib test
git commit -m "feat: onglet Journal (groupes par jour épinglés, pagination, édition, suppression)"
```

---

### Task 13: Dashboard — use cases purs (plan biberons OMS, soins du jour, âge)

**Files:**
- Create: `lib/features/dashboard/domain/entities/feeding_plan.dart`, `care_task.dart`, `baby_age.dart`
- Create: `lib/features/dashboard/domain/use_cases/compute_feeding_plan.dart`, `compute_daily_care_status.dart`, `compute_baby_age.dart`
- Test: `test/features/dashboard/domain/compute_feeding_plan_test.dart`, `compute_daily_care_status_test.dart`, `compute_baby_age_test.dart`

- [ ] **Step 1: Écrire les tests (rouges)**

`test/features/dashboard/domain/compute_feeding_plan_test.dart` :

```dart
import 'package:colette/features/dashboard/domain/use_cases/compute_feeding_plan.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../helpers/care_event_factory.dart';

void main() {
  const compute = ComputeFeedingPlan();
  final birth = DateTime(2026, 9, 1, 6);

  group('règles OMS', () {
    test('jour de vie : 1 le jour de la naissance', () {
      expect(ComputeFeedingPlan.dayOfLife(birth, DateTime(2026, 9, 1, 23)), 1);
      expect(ComputeFeedingPlan.dayOfLife(birth, DateTime(2026, 9, 2, 0, 5)), 2);
      expect(ComputeFeedingPlan.dayOfLife(birth, DateTime(2026, 8, 31)), 1);
    });

    test('ml par kg : 60 le jour 1, +20 par jour, plafonné à 150', () {
      expect(ComputeFeedingPlan.mlPerKg(1), 60);
      expect(ComputeFeedingPlan.mlPerKg(3), 100);
      expect(ComputeFeedingPlan.mlPerKg(6), 150);
      expect(ComputeFeedingPlan.mlPerKg(40), 150);
    });

    test('repères par âge sans pesée', () {
      expect(ComputeFeedingPlan.dailyTargetFromAge(1), 240);
      expect(ComputeFeedingPlan.dailyTargetFromAge(5), 480);
      expect(ComputeFeedingPlan.dailyTargetFromAge(20), 480);
      expect(ComputeFeedingPlan.dailyTargetFromAge(45), 630);
      expect(ComputeFeedingPlan.dailyTargetFromAge(100), 720);
      expect(ComputeFeedingPlan.dailyTargetFromAge(150), 900);
    });
  });

  test('jour 10, 3 600 g, 2 biberons de 60 : cible 540, reste 420 sur 6 prises', () {
    final now = DateTime(2026, 9, 10, 12);
    final bottles = [
      makeEvent(id: 'a', startAt: DateTime(2026, 9, 10, 6), bottleMl: 60),
      makeEvent(id: 'b', startAt: DateTime(2026, 9, 10, 9), bottleMl: 60),
    ];
    final plan = compute(
      birthDate: birth,
      latestWeightGrams: 3600,
      feedsPerDay: 8,
      todayBottles: bottles,
      lastBottle: bottles.last,
      now: now,
    );
    expect(plan.dailyTargetMl, 540);
    expect(plan.isEstimatedFromAge, isFalse);
    expect(plan.bottlesGiven, 2);
    expect(plan.bottlesRemaining, 6);
    expect(plan.givenMl, 120);
    expect(plan.remainingMl, 420);
    expect(plan.suggestedMl, 70);
    expect(plan.nextBottleAt, DateTime(2026, 9, 10, 12));
    expect(plan.lateBy(now), Duration.zero);
  });

  test('sans biberon, le prochain est maintenant et la suggestion vaut cible / prises', () {
    final now = DateTime(2026, 9, 1, 12);
    final plan = compute(
      birthDate: birth,
      latestWeightGrams: 3500,
      feedsPerDay: 8,
      todayBottles: const [],
      lastBottle: null,
      now: now,
    );
    expect(plan.dailyTargetMl, 210);
    expect(plan.nextBottleAt, now);
    expect(plan.suggestedMl, 30);
  });

  test('sans pesée, la cible vient des repères par âge', () {
    final plan = compute(
      birthDate: birth,
      latestWeightGrams: null,
      feedsPerDay: 8,
      todayBottles: const [],
      lastBottle: null,
      now: DateTime(2026, 9, 20, 12),
    );
    expect(plan.dailyTargetMl, 480);
    expect(plan.isEstimatedFromAge, isTrue);
    expect(plan.suggestedMl, 60);
  });

  test('le retard est calculé depuis le dernier biberon + intervalle', () {
    final last = makeEvent(id: 'a', startAt: DateTime(2026, 9, 10, 6), bottleMl: 90);
    final plan = compute(
      birthDate: birth,
      latestWeightGrams: 3600,
      feedsPerDay: 8,
      todayBottles: [last],
      lastBottle: last,
      now: DateTime(2026, 9, 10, 10),
    );
    expect(plan.nextBottleAt, DateTime(2026, 9, 10, 9));
    expect(plan.lateBy(DateTime(2026, 9, 10, 10)), const Duration(hours: 1));
  });

  test('la suggestion est bornée entre 30 et 240 ml', () {
    final high = compute(
      birthDate: birth,
      latestWeightGrams: 8000,
      feedsPerDay: 4,
      todayBottles: const [],
      lastBottle: null,
      now: DateTime(2026, 12, 10, 12),
    );
    expect(high.suggestedMl, 240);
  });

  test('toutes les prises données : suggestion = cible / prises', () {
    final bottles = List.generate(
      8,
      (i) => makeEvent(id: '$i', startAt: DateTime(2026, 9, 10, i * 2), bottleMl: 60),
    );
    final plan = compute(
      birthDate: birth,
      latestWeightGrams: 3600,
      feedsPerDay: 8,
      todayBottles: bottles,
      lastBottle: bottles.last,
      now: DateTime(2026, 9, 10, 16),
    );
    expect(plan.bottlesRemaining, 0);
    expect(plan.suggestedMl, 70);
  });
}
```

`test/features/dashboard/domain/compute_daily_care_status_test.dart` :

```dart
import 'package:colette/features/baby/domain/entities/care_settings.dart';
import 'package:colette/features/dashboard/domain/use_cases/compute_daily_care_status.dart';
import 'package:colette/shared/domain/care_type.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../helpers/care_event_factory.dart';

void main() {
  const compute = ComputeDailyCareStatus();
  final now = DateTime(2026, 9, 21, 14);

  test('réglages par défaut sans événement : 5 tâches, aucune faite', () {
    final tasks = compute(settings: const CareSettings(), todayEvents: const [], lastBath: null, now: now);
    expect(tasks.map((t) => t.type), [
      CareType.adrigyl,
      CareType.eyeCare,
      CareType.noseCare,
      CareType.umbilicalCare,
      CareType.bath,
    ]);
    expect(tasks.every((t) => !t.isDone), isTrue);
  });

  test('un Adrigyl aujourd\'hui marque la tâche faite avec son heure', () {
    final event = makeEvent(startAt: DateTime(2026, 9, 21, 8), adrigyl: true);
    final tasks = compute(settings: const CareSettings(), todayEvents: [event], lastBath: null, now: now);
    final adrigyl = tasks.firstWhere((t) => t.type == CareType.adrigyl);
    expect(adrigyl.isDone, isTrue);
    expect(adrigyl.lastDoneAt, event.startAt);
  });

  test('adrigylPerDay 2 avec une prise reste à faire', () {
    final event = makeEvent(startAt: DateTime(2026, 9, 21, 8), adrigyl: true);
    final tasks = compute(
      settings: const CareSettings(adrigylPerDay: 2),
      todayEvents: [event],
      lastBath: null,
      now: now,
    );
    final adrigyl = tasks.firstWhere((t) => t.type == CareType.adrigyl);
    expect(adrigyl.target, 2);
    expect(adrigyl.done, 1);
    expect(adrigyl.isDone, isFalse);
  });

  test('nombril désactivé : pas de tâche nombril', () {
    final tasks = compute(
      settings: const CareSettings(umbilicalCareEnabled: false),
      todayEvents: const [],
      lastBath: null,
      now: now,
    );
    expect(tasks.any((t) => t.type == CareType.umbilicalCare), isFalse);
  });

  test('bain hier avec bathEveryDays 2 : pas attendu aujourd\'hui', () {
    final bath = makeEvent(startAt: DateTime(2026, 9, 20, 18), bath: true);
    final tasks = compute(settings: const CareSettings(), todayEvents: const [], lastBath: bath, now: now);
    expect(tasks.any((t) => t.type == CareType.bath), isFalse);
  });

  test('bain avant-hier avec bathEveryDays 2 : attendu', () {
    final bath = makeEvent(startAt: DateTime(2026, 9, 19, 18), bath: true);
    final tasks = compute(settings: const CareSettings(), todayEvents: const [], lastBath: bath, now: now);
    expect(tasks.any((t) => t.type == CareType.bath && !t.isDone), isTrue);
  });

  test('bain aujourd\'hui : listé et fait', () {
    final bath = makeEvent(startAt: DateTime(2026, 9, 21, 9), bath: true);
    final tasks = compute(settings: const CareSettings(), todayEvents: [bath], lastBath: bath, now: now);
    final task = tasks.firstWhere((t) => t.type == CareType.bath);
    expect(task.isDone, isTrue);
  });
}
```

`test/features/dashboard/domain/compute_baby_age_test.dart` :

```dart
import 'package:colette/features/dashboard/domain/entities/baby_age.dart';
import 'package:colette/features/dashboard/domain/use_cases/compute_baby_age.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const compute = ComputeBabyAge();
  final birth = DateTime(2026, 9, 1, 10);

  test('moins de 14 jours : en jours', () {
    expect(compute(birthDate: birth, now: DateTime(2026, 9, 1, 12)), const BabyAge(unit: BabyAgeUnit.days, count: 0));
    expect(compute(birthDate: birth, now: DateTime(2026, 9, 14, 8)), const BabyAge(unit: BabyAgeUnit.days, count: 13));
  });

  test('de 14 jours à 2 mois : en semaines', () {
    expect(compute(birthDate: birth, now: DateTime(2026, 9, 15)), const BabyAge(unit: BabyAgeUnit.weeks, count: 2));
    expect(compute(birthDate: birth, now: DateTime(2026, 10, 30)), const BabyAge(unit: BabyAgeUnit.weeks, count: 8));
  });

  test('ensuite : en mois civils', () {
    expect(compute(birthDate: birth, now: DateTime(2026, 11, 1)), const BabyAge(unit: BabyAgeUnit.months, count: 2));
    expect(compute(birthDate: birth, now: DateTime(2026, 11, 30)), const BabyAge(unit: BabyAgeUnit.months, count: 2));
    expect(compute(birthDate: birth, now: DateTime(2027, 3, 1)), const BabyAge(unit: BabyAgeUnit.months, count: 6));
  });
}
```

- [ ] **Step 2: Vérifier l'échec**

Run: `flutter test test/features/dashboard`
Expected: échec de compilation.

- [ ] **Step 3: Créer les entités**

`lib/features/dashboard/domain/entities/feeding_plan.dart` :

```dart
import 'dart:math';

import 'package:freezed_annotation/freezed_annotation.dart';

part 'feeding_plan.freezed.dart';

/// Plan biberons du jour : cible, progression, prochain biberon.
@freezed
abstract class FeedingPlan with _$FeedingPlan {
  const FeedingPlan._();

  const factory FeedingPlan({
    required int dailyTargetMl,
    required int feedsPerDay,
    required DateTime nextBottleAt,
    required int suggestedMl,
    required int bottlesGiven,
    required int givenMl,
    required bool isEstimatedFromAge,
  }) = _FeedingPlan;

  int get bottlesRemaining => max(0, feedsPerDay - bottlesGiven);

  int get remainingMl => max(0, dailyTargetMl - givenMl);

  /// Retard sur le prochain biberon, ou zéro.
  Duration lateBy(DateTime now) =>
      now.isAfter(nextBottleAt) ? now.difference(nextBottleAt) : Duration.zero;
}
```

`lib/features/dashboard/domain/entities/care_task.dart` :

```dart
import 'package:colette/shared/domain/care_type.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

part 'care_task.freezed.dart';

/// Un soin attendu aujourd'hui et son avancement.
@freezed
abstract class CareTask with _$CareTask {
  const CareTask._();

  const factory CareTask({
    required CareType type,
    required int target,
    required int done,
    DateTime? lastDoneAt,
  }) = _CareTask;

  bool get isDone => done >= target;
}
```

`lib/features/dashboard/domain/entities/baby_age.dart` :

```dart
import 'package:freezed_annotation/freezed_annotation.dart';

part 'baby_age.freezed.dart';

/// Unité d'affichage de l'âge.
enum BabyAgeUnit { days, weeks, months }

/// Âge du bébé dans l'unité la plus parlante.
@freezed
abstract class BabyAge with _$BabyAge {
  const factory BabyAge({required BabyAgeUnit unit, required int count}) = _BabyAge;
}
```

- [ ] **Step 4: Créer les use cases**

`lib/features/dashboard/domain/use_cases/compute_feeding_plan.dart` :

```dart
import 'dart:math';

import 'package:colette/core/dates/date_extensions.dart';
import 'package:colette/features/dashboard/domain/entities/feeding_plan.dart';
import 'package:colette/features/events/domain/entities/care_event.dart';

/// Plan biberons selon l'OMS : 150 ml/kg/jour (montée progressive la 1re semaine),
/// réparti sur `feedsPerDay` prises ; repères par âge sans pesée.
/// `feedsPerDay` est borné à 1 minimum pour ne jamais diviser par zéro.
class ComputeFeedingPlan {
  const ComputeFeedingPlan();

  static const minSuggestedMl = 30;
  static const maxSuggestedMl = 240;

  FeedingPlan call({
    required DateTime birthDate,
    required int? latestWeightGrams,
    required int feedsPerDay,
    required List<CareEvent> todayBottles,
    required CareEvent? lastBottle,
    required DateTime now,
  }) {
    final safeFeedsPerDay = max(1, feedsPerDay);
    final day = dayOfLife(birthDate, now);
    final (dailyTargetMl, estimated) = switch (latestWeightGrams) {
      null => (dailyTargetFromAge(day), true),
      final grams => (_roundTo10(mlPerKg(day) * grams / 1000), false),
    };
    final interval = Duration(minutes: (24 * 60 / safeFeedsPerDay).round());
    final nextBottleAt = lastBottle == null ? now : lastBottle.startAt.add(interval);
    final givenMl = todayBottles.fold(0, (sum, e) => sum + (e.bottleMl ?? 0));
    final bottlesGiven = todayBottles.length;
    final bottlesRemaining = max(0, safeFeedsPerDay - bottlesGiven);
    final remainingMl = max(0, dailyTargetMl - givenMl);
    final raw = bottlesRemaining > 0
        ? remainingMl / bottlesRemaining
        : dailyTargetMl / safeFeedsPerDay;
    final suggestedMl = _roundTo10(raw).clamp(minSuggestedMl, maxSuggestedMl);
    return FeedingPlan(
      dailyTargetMl: dailyTargetMl,
      feedsPerDay: safeFeedsPerDay,
      nextBottleAt: nextBottleAt,
      suggestedMl: suggestedMl,
      bottlesGiven: bottlesGiven,
      givenMl: givenMl,
      isEstimatedFromAge: estimated,
    );
  }

  /// Jour de vie en jours civils ; 1 le jour de la naissance, jamais moins.
  static int dayOfLife(DateTime birthDate, DateTime now) =>
      max(1, now.dateOnly.difference(birthDate.dateOnly).inDays + 1);

  /// 60 ml/kg le jour 1, +20 ml/kg par jour, plafonné à 150 ml/kg.
  static int mlPerKg(int dayOfLife) => min(150, 60 + 20 * (dayOfLife - 1));

  /// Cible journalière indicative quand aucune pesée n'est connue.
  static int dailyTargetFromAge(int dayOfLife) {
    if (dayOfLife <= 5) return const [240, 320, 400, 440, 480][dayOfLife - 1];
    if (dayOfLife <= 30) return 480;
    if (dayOfLife <= 60) return 630;
    if (dayOfLife <= 120) return 720;
    return 900;
  }

  static int _roundTo10(double value) => (value / 10).round() * 10;
}
```

`lib/features/dashboard/domain/use_cases/compute_daily_care_status.dart` :

```dart
import 'package:colette/core/dates/date_extensions.dart';
import 'package:colette/features/baby/domain/entities/care_settings.dart';
import 'package:colette/features/dashboard/domain/entities/care_task.dart';
import 'package:colette/features/events/domain/entities/care_event.dart';
import 'package:colette/shared/domain/care_type.dart';

/// Soins attendus aujourd'hui, avec leur avancement.
class ComputeDailyCareStatus {
  const ComputeDailyCareStatus();

  List<CareTask> call({
    required CareSettings settings,
    required List<CareEvent> todayEvents,
    required CareEvent? lastBath,
    required DateTime now,
  }) {
    CareTask task(CareType type, int target) {
      final matching = todayEvents.where((e) => e.has(type)).toList()
        ..sort((a, b) => a.startAt.compareTo(b.startAt));
      return CareTask(
        type: type,
        target: target,
        done: matching.length,
        lastDoneAt: matching.isEmpty ? null : matching.last.startAt,
      );
    }

    final bathToday = todayEvents.any((e) => e.bath);
    final bathExpected = isBathExpected(
      lastBath: lastBath,
      bathEveryDays: settings.bathEveryDays,
      now: now,
    );

    return [
      if (settings.adrigylPerDay > 0) task(CareType.adrigyl, settings.adrigylPerDay),
      if (settings.eyeCarePerDay > 0) task(CareType.eyeCare, settings.eyeCarePerDay),
      if (settings.noseCarePerDay > 0) task(CareType.noseCare, settings.noseCarePerDay),
      if (settings.umbilicalCareEnabled) task(CareType.umbilicalCare, 1),
      if (bathExpected || bathToday) task(CareType.bath, 1),
    ];
  }

  /// Bain attendu si aucun bain, ou si le dernier date d'au moins [bathEveryDays] jours civils.
  static bool isBathExpected({
    required CareEvent? lastBath,
    required int bathEveryDays,
    required DateTime now,
  }) {
    if (lastBath == null) return true;
    final daysSince = now.dateOnly.difference(lastBath.startAt.dateOnly).inDays;
    return daysSince >= bathEveryDays;
  }
}
```

`lib/features/dashboard/domain/use_cases/compute_baby_age.dart` :

```dart
import 'dart:math';

import 'package:colette/core/dates/date_extensions.dart';
import 'package:colette/features/dashboard/domain/entities/baby_age.dart';

/// Jours jusqu'à 2 semaines, semaines jusqu'à 2 mois, puis mois civils.
class ComputeBabyAge {
  const ComputeBabyAge();

  BabyAge call({required DateTime birthDate, required DateTime now}) {
    final days = max(0, now.dateOnly.difference(birthDate.dateOnly).inDays);
    if (days < 14) return BabyAge(unit: BabyAgeUnit.days, count: days);
    if (days < 61) return BabyAge(unit: BabyAgeUnit.weeks, count: days ~/ 7);
    return BabyAge(unit: BabyAgeUnit.months, count: _monthsBetween(birthDate, now));
  }

  static int _monthsBetween(DateTime from, DateTime to) {
    final months = (to.year - from.year) * 12 + to.month - from.month;
    return to.day < from.day ? months - 1 : months;
  }
}
```

- [ ] **Step 5: Générer et tester**

Run: `dart run build_runner build -d && dart format lib test && dart analyze && flutter test test/features/dashboard`
Expected: `No issues found!` puis `All tests passed!`.

- [ ] **Step 6: Commit**

```bash
git add lib/features/dashboard test/features/dashboard
git commit -m "feat: use cases dashboard (plan biberons OMS, soins du jour, âge du bébé)"
```

---

### Task 14: Onglet Aujourd'hui — providers, synchronisation du plan, page

**Files:**
- Create: `lib/core/clock/now_providers.dart`
- Create: `lib/features/dashboard/presentation/providers/dashboard_providers.dart`, `feeding_plan_sync.dart`
- Create: `lib/features/dashboard/presentation/widgets/dashboard_header.dart`, `next_bottle_card.dart`, `todo_section.dart`, `care_task_row.dart`, `day_counters_row.dart`
- Modify (remplacement complet) : `lib/features/dashboard/presentation/pages/dashboard_page.dart`
- Modify: `lib/features/events/presentation/providers/events_providers.dart` (`todayEvents` suit le jour courant), `lib/features/events/presentation/providers/event_form_controller.dart` (sync après écriture), `lib/core/dates/time_format.dart` (`formatLongDate`), `lib/app/router/app_router.dart` (paramètre `bottle`)
- Modify: `test/features/events/presentation/event_form_controller_test.dart`, `test/features/events/presentation/event_form_sheet_test.dart` (override du sync)
- Test: `test/features/dashboard/presentation/feeding_plan_sync_test.dart`, `test/features/dashboard/presentation/dashboard_page_test.dart`

- [ ] **Step 1: Créer `lib/core/clock/now_providers.dart`**

```dart
import 'package:colette/core/clock/app_clock.dart';
import 'package:colette/core/dates/date_extensions.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'now_providers.g.dart';

/// Émet chaque minute ; surchargé par `Stream.empty()` dans les tests.
@riverpod
Stream<DateTime> minuteTicker(Ref ref) {
  final clock = ref.watch(clockProvider);
  return Stream<DateTime>.periodic(const Duration(minutes: 1), (_) => clock.now());
}

/// Heure courante, rafraîchie chaque minute.
@riverpod
DateTime currentMinute(Ref ref) {
  ref.watch(minuteTickerProvider);
  return ref.watch(clockProvider).now();
}

/// Jour civil courant ; ne notifie ses dépendants qu'au changement de jour.
@riverpod
DateTime today(Ref ref) => ref.watch(currentMinuteProvider).dateOnly;
```

- [ ] **Step 2: Modifier `todayEvents` dans `lib/features/events/presentation/providers/events_providers.dart`**

Remplacer l'import `package:colette/core/clock/app_clock.dart` par `package:colette/core/clock/now_providers.dart` et le corps de `todayEvents` par :

```dart
@riverpod
Stream<List<CareEvent>> todayEvents(Ref ref) {
  final code = ref.watch(currentHouseholdCodeProvider);
  if (code == null) return Stream.value(const []);
  final today = ref.watch(todayProvider);
  return ref
      .watch(eventsRepositoryProvider)
      .watchBetween(code, from: today, to: today.startOfNextDay);
}
```

- [ ] **Step 3: Ajouter `formatLongDate` dans `lib/core/dates/time_format.dart`**

```dart
/// « Lundi 21 septembre ».
String formatLongDate(DateTime day) {
  final text = DateFormat('EEEE d MMMM', 'fr').format(day);
  return '${text[0].toUpperCase()}${text.substring(1)}';
}
```

- [ ] **Step 4: Écrire les tests (rouges)**

`test/features/dashboard/presentation/feeding_plan_sync_test.dart` :

```dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:colette/core/clock/app_clock.dart';
import 'package:colette/core/firebase/firebase_providers.dart';
import 'package:colette/features/baby/domain/entities/baby_profile.dart';
import 'package:colette/features/baby/presentation/providers/baby_providers.dart';
import 'package:colette/features/dashboard/presentation/providers/feeding_plan_sync.dart';
import 'package:colette/features/events/presentation/providers/events_providers.dart';
import 'package:colette/features/household/presentation/providers/household_providers.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../helpers/care_event_factory.dart';
import '../../../helpers/in_memory_household_local_store.dart';

void main() {
  test('sync écrit nextBottleAt = dernier biberon + 3 h et la suggestion', () async {
    final db = FakeFirebaseFirestore();
    final now = DateTime(2026, 9, 10, 12);
    final container = ProviderContainer(
      overrides: [
        firestoreProvider.overrideWithValue(db),
        clockProvider.overrideWithValue(FixedClock(now)),
        householdLocalStoreProvider.overrideWithValue(
          InMemoryHouseholdLocalStore(householdCode: 'ABCDEFGH'),
        ),
      ],
    );
    addTearDown(container.dispose);
    await container.read(babyRepositoryProvider).saveProfile(
      'ABCDEFGH',
      BabyProfile(name: 'Colette', birthDate: DateTime(2026, 9, 1)),
    );
    final bottle = makeEvent(id: 'b', startAt: DateTime(2026, 9, 10, 9), bottleMl: 60);
    await container.read(eventsRepositoryProvider).save('ABCDEFGH', bottle);

    await container.read(feedingPlanSyncProvider).sync();

    final data = (await db.collection('households').doc('ABCDEFGH').get()).data()!;
    final plan = data['feedingPlan'] as Map<String, dynamic>;
    expect((plan['nextBottleAt'] as Timestamp).toDate(), DateTime(2026, 9, 10, 12));
    expect(plan['suggestedMl'], 60);
  });
}
```

`test/features/dashboard/presentation/dashboard_page_test.dart` :

```dart
import 'package:colette/core/clock/app_clock.dart';
import 'package:colette/core/clock/now_providers.dart';
import 'package:colette/features/baby/domain/entities/baby_profile.dart';
import 'package:colette/features/baby/domain/entities/weight_entry.dart';
import 'package:colette/features/baby/presentation/providers/baby_providers.dart';
import 'package:colette/features/dashboard/presentation/pages/dashboard_page.dart';
import 'package:colette/features/events/presentation/providers/events_providers.dart';
import 'package:colette/features/household/presentation/providers/household_providers.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../helpers/care_event_factory.dart';
import '../../../helpers/in_memory_household_local_store.dart';
import '../../../helpers/pump_app.dart';

void main() {
  final now = DateTime(2026, 9, 10, 12);
  final profile = BabyProfile(name: 'Colette', birthDate: DateTime(2026, 9, 1));
  final bottle = makeEvent(id: 'b', startAt: DateTime(2026, 9, 10, 8), bottleMl: 60);
  final adrigyl = makeEvent(id: 'a', startAt: DateTime(2026, 9, 10, 9), adrigyl: true, diaperChange: true);

  testWidgets('affiche l\'âge, le prochain biberon, les tâches et les compteurs', (tester) async {
    await pumpApp(
      tester,
      const DashboardPage(),
      overrides: [
        clockProvider.overrideWithValue(FixedClock(now)),
        minuteTickerProvider.overrideWith((ref) => const Stream.empty()),
        householdLocalStoreProvider.overrideWithValue(
          InMemoryHouseholdLocalStore(householdCode: 'ABCDEFGH'),
        ),
        babyProfileProvider.overrideWith((ref) => Stream.value(profile)),
        weightsProvider.overrideWith(
          (ref) => Stream.value([WeightEntry(id: 'w', measuredAt: DateTime(2026, 9, 9), grams: 3600)]),
        ),
        todayEventsProvider.overrideWith((ref) => Stream.value([adrigyl, bottle])),
        latestBottleProvider.overrideWith((ref) => Stream.value(bottle)),
        latestBathProvider.overrideWith((ref) => Stream.value(null)),
      ],
    );

    expect(find.text('Colette a 9 jours'), findsOneWidget);
    expect(find.text('Prochain biberon'), findsOneWidget);
    expect(find.text('70 ml'), findsOneWidget);
    expect(find.text('en retard de 60 min'), findsOneWidget);
    expect(find.text('fait à 09h00'), findsOneWidget);
    expect(find.text('Soin des yeux'), findsOneWidget);
    expect(find.text('Bain'), findsOneWidget);
    expect(find.text('couches'), findsOneWidget);
  });
}
```

- [ ] **Step 5: Vérifier l'échec**

Run: `flutter test test/features/dashboard/presentation`
Expected: échec de compilation.

- [ ] **Step 6: Créer `lib/features/dashboard/presentation/providers/feeding_plan_sync.dart`**

```dart
import 'dart:developer' as developer;

import 'package:colette/core/clock/app_clock.dart';
import 'package:colette/core/dates/date_extensions.dart';
import 'package:colette/features/baby/domain/entities/feeding_plan_snapshot.dart';
import 'package:colette/features/baby/presentation/providers/baby_providers.dart';
import 'package:colette/features/dashboard/domain/use_cases/compute_feeding_plan.dart';
import 'package:colette/features/events/presentation/providers/events_providers.dart';
import 'package:colette/features/household/presentation/providers/household_providers.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'feeding_plan_sync.g.dart';

/// Recalcule le plan biberons et l'écrit dans le foyer pour les Cloud Functions.
abstract interface class FeedingPlanSync {
  Future<void> sync();
}

/// Ne fait rien ; pour les tests.
final class NoopFeedingPlanSync implements FeedingPlanSync {
  const NoopFeedingPlanSync();

  @override
  Future<void> sync() async {}
}

/// Relit les données depuis Firestore via les repositories (et non depuis les
/// providers, qui peuvent être détruits pendant l'attente), calcule, puis écrit
/// `feedingPlan`. Best-effort : une erreur est journalisée, jamais propagée.
final class FirestoreFeedingPlanSync implements FeedingPlanSync {
  const FirestoreFeedingPlanSync(this._ref);

  final Ref _ref;

  @override
  Future<void> sync() async {
    final code = _ref.read(currentHouseholdCodeProvider);
    if (code == null) return;
    try {
      final babyRepository = _ref.read(babyRepositoryProvider);
      final profile = await babyRepository.watchProfile(code).first;
      if (profile == null) return;
      final weights = await babyRepository.watchWeights(code).first;
      final now = _ref.read(clockProvider).now();
      final events = _ref.read(eventsRepositoryProvider);
      final today = (await events.getBetween(code, from: now.dateOnly, to: now.startOfNextDay))
          .getOrElse((_) => const []);
      final lastBottle = (await events.getLatestBottle(code)).getOrElse((_) => null);
      final plan = const ComputeFeedingPlan()(
        birthDate: profile.birthDate,
        latestWeightGrams: weights.isEmpty ? null : weights.first.grams,
        feedsPerDay: profile.careSettings.feedsPerDay,
        todayBottles: today.where((e) => e.hasBottle).toList(),
        lastBottle: lastBottle,
        now: now,
      );
      await babyRepository.saveFeedingPlan(
        code,
        FeedingPlanSnapshot(
          nextBottleAt: plan.nextBottleAt,
          suggestedMl: plan.suggestedMl,
          computedAt: now,
        ),
      );
    } catch (e, stackTrace) {
      developer.log('Feeding plan sync failed', error: e, stackTrace: stackTrace, name: 'colette');
    }
  }
}

@Riverpod(keepAlive: true)
FeedingPlanSync feedingPlanSync(Ref ref) => FirestoreFeedingPlanSync(ref);
```

- [ ] **Step 7: Modifier `lib/features/events/presentation/providers/event_form_controller.dart` pour synchroniser après écriture**

Ajouter l'import :

```dart
import 'package:colette/features/dashboard/presentation/providers/feeding_plan_sync.dart';
```

Dans `submit`, remplacer la ligne `return result.getRight().toNullable();` par :

```dart
    final saved = result.getRight().toNullable();
    if (saved != null) await ref.read(feedingPlanSyncProvider).sync();
    return saved;
```

Dans `delete`, remplacer `return result.isRight();` par :

```dart
    if (result.isRight()) await ref.read(feedingPlanSyncProvider).sync();
    return result.isRight();
```

- [ ] **Step 8: Ajouter l'override du sync dans les deux tests existants**

Dans `test/features/events/presentation/event_form_controller_test.dart` et `test/features/events/presentation/event_form_sheet_test.dart`, ajouter l'import :

```dart
import 'package:colette/features/dashboard/presentation/providers/feeding_plan_sync.dart';
```

et, dans la liste `overrides` de chaque test, la ligne :

```dart
        feedingPlanSyncProvider.overrideWithValue(const NoopFeedingPlanSync()),
```

Même override `feedingPlanSyncProvider` dans le test « glisser puis confirmer supprime l'événement » de `test/features/events/presentation/timeline_page_test.dart`, puisque `delete` déclenche désormais la synchronisation.

Dans `test/app/app_router_test.dart`, le dashboard réel dépend maintenant du ticker minute : ajouter l'import `package:colette/core/clock/now_providers.dart` et, dans `overrides` de `pumpColetteApp`, la ligne :

```dart
          minuteTickerProvider.overrideWith((ref) => const Stream.empty()),
```

- [ ] **Step 9: Créer `lib/features/dashboard/presentation/providers/dashboard_providers.dart`**

```dart
import 'package:colette/core/clock/now_providers.dart';
import 'package:colette/features/baby/presentation/providers/baby_providers.dart';
import 'package:colette/features/dashboard/domain/entities/baby_age.dart';
import 'package:colette/features/dashboard/domain/entities/care_task.dart';
import 'package:colette/features/dashboard/domain/entities/feeding_plan.dart';
import 'package:colette/features/dashboard/domain/use_cases/compute_baby_age.dart';
import 'package:colette/features/dashboard/domain/use_cases/compute_daily_care_status.dart';
import 'package:colette/features/dashboard/domain/use_cases/compute_feeding_plan.dart';
import 'package:colette/features/events/presentation/providers/events_providers.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'dashboard_providers.g.dart';

/// Compteurs du jour.
typedef DayCounters = ({int diapers, int pee, int poop});

/// Plan biberons du jour ; `null` sans profil.
@riverpod
FeedingPlan? feedingPlan(Ref ref) {
  final profile = ref.watch(babyProfileProvider).value;
  if (profile == null) return null;
  final today = ref.watch(todayEventsProvider).value ?? const [];
  return const ComputeFeedingPlan()(
    birthDate: profile.birthDate,
    latestWeightGrams: ref.watch(latestWeightProvider)?.grams,
    feedsPerDay: profile.careSettings.feedsPerDay,
    todayBottles: today.where((e) => e.hasBottle).toList(),
    lastBottle: ref.watch(latestBottleProvider).value,
    now: ref.watch(currentMinuteProvider),
  );
}

/// Soins attendus aujourd'hui.
@riverpod
List<CareTask> dailyCareTasks(Ref ref) {
  final profile = ref.watch(babyProfileProvider).value;
  if (profile == null) return const [];
  return const ComputeDailyCareStatus()(
    settings: profile.careSettings,
    todayEvents: ref.watch(todayEventsProvider).value ?? const [],
    lastBath: ref.watch(latestBathProvider).value,
    now: ref.watch(currentMinuteProvider),
  );
}

@riverpod
DayCounters dayCounters(Ref ref) {
  final events = ref.watch(todayEventsProvider).value ?? const [];
  return (
    diapers: events.where((e) => e.diaperChange).length,
    pee: events.where((e) => e.pee).length,
    poop: events.where((e) => e.poop).length,
  );
}

/// Âge du bébé ; `null` sans profil.
@riverpod
BabyAge? babyAge(Ref ref) {
  final profile = ref.watch(babyProfileProvider).value;
  if (profile == null) return null;
  return const ComputeBabyAge()(birthDate: profile.birthDate, now: ref.watch(currentMinuteProvider));
}
```

- [ ] **Step 10: Créer les widgets du dashboard**

`lib/features/dashboard/presentation/widgets/dashboard_header.dart` :

```dart
import 'package:colette/core/clock/now_providers.dart';
import 'package:colette/core/dates/time_format.dart';
import 'package:colette/core/theme/app_colors.dart';
import 'package:colette/core/theme/text_styles.dart';
import 'package:colette/features/baby/presentation/providers/baby_providers.dart';
import 'package:colette/features/dashboard/domain/entities/baby_age.dart';
import 'package:colette/features/dashboard/presentation/providers/dashboard_providers.dart';
import 'package:colette/l10n/generated/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Date du jour et âge du bébé.
class DashboardHeader extends ConsumerWidget {
  const DashboardHeader({super.key});

  String _ageText(BabyAge age, S s) => switch (age.unit) {
    BabyAgeUnit.days => s.ageDays(age.count),
    BabyAgeUnit.weeks => s.ageWeeks(age.count),
    BabyAgeUnit.months => s.ageMonths(age.count),
  };

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final s = S.of(context);
    final styles = Theme.of(context).coletteTextStyles;
    final today = ref.watch(todayProvider);
    final name = ref.watch(babyProfileProvider).value?.name;
    final age = ref.watch(babyAgeProvider);
    return Column(
      crossAxisAlignment: .start,
      children: [
        Text(
          formatLongDate(today),
          style: styles.small.copyWith(color: context.appColor(AppColors.textSecondary)),
        ),
        Text(
          name != null && age != null ? s.dashboardAge(name, _ageText(age, s)) : s.appTitle,
          style: styles.heading1,
        ),
      ],
    );
  }
}
```

`lib/features/dashboard/presentation/widgets/next_bottle_card.dart` :

```dart
import 'package:colette/core/clock/now_providers.dart';
import 'package:colette/core/dates/time_format.dart';
import 'package:colette/core/theme/app_colors.dart';
import 'package:colette/core/theme/design_tokens.dart';
import 'package:colette/core/theme/text_styles.dart';
import 'package:colette/features/dashboard/domain/entities/feeding_plan.dart';
import 'package:colette/features/dashboard/presentation/providers/dashboard_providers.dart';
import 'package:colette/features/events/presentation/widgets/event_form_sheet.dart';
import 'package:colette/l10n/generated/app_localizations.dart';
import 'package:colette/shared/ui/widgets/colette_card_surface.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Carte « Prochain biberon » : quantité suggérée, heure, progression du jour.
class NextBottleCard extends ConsumerWidget {
  const NextBottleCard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final s = S.of(context);
    final styles = Theme.of(context).coletteTextStyles;
    final plan = ref.watch(feedingPlanProvider);
    if (plan == null) {
      return ColetteCardSurface(
        child: Text(
          s.feedingPlanUnavailable,
          style: styles.body.copyWith(color: context.appColor(AppColors.textSecondary)),
        ),
      );
    }
    final now = ref.watch(currentMinuteProvider);
    return ColetteCardSurface(
      onTap: () => showEventFormSheet(context, suggestedBottleMl: plan.suggestedMl),
      child: Column(
        crossAxisAlignment: .start,
        spacing: AppSpacing.xs.value,
        children: [
          Text(
            s.nextBottleTitle,
            style: styles.overline.copyWith(color: context.appColor(AppColors.primary)),
          ),
          Row(
            crossAxisAlignment: .baseline,
            textBaseline: .alphabetic,
            spacing: AppSpacing.sm.value,
            children: [
              Text(
                s.bottleMl(plan.suggestedMl),
                style: styles.numberLarge.copyWith(color: context.appColor(AppColors.primary)),
              ),
              Expanded(child: _WhenText(plan: plan, now: now)),
            ],
          ),
          Text(
            s.bottleProgress(plan.bottlesGiven, plan.feedsPerDay, plan.givenMl, plan.dailyTargetMl),
            style: styles.small.copyWith(color: context.appColor(AppColors.textSecondary)),
          ),
          ClipRRect(
            borderRadius: AppRadius.round.circular,
            child: LinearProgressIndicator(
              value: plan.dailyTargetMl == 0 ? 0 : (plan.givenMl / plan.dailyTargetMl).clamp(0, 1),
              minHeight: AppSpacing.sm.value,
              backgroundColor: context.appColor(AppColors.primaryContainer),
              color: context.appColor(AppColors.primary),
            ),
          ),
          if (plan.isEstimatedFromAge)
            Text(
              s.feedingPlanEstimated,
              style: styles.small.copyWith(color: context.appColor(AppColors.textSecondary)),
            ),
        ],
      ),
    );
  }
}

class _WhenText extends StatelessWidget {
  const _WhenText({required this.plan, required this.now});

  final FeedingPlan plan;
  final DateTime now;

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    final styles = Theme.of(context).coletteTextStyles;
    final late = plan.lateBy(now);
    if (late > Duration.zero) {
      return Text(
        s.nextBottleLate(late.inMinutes),
        style: styles.bodyMedium.copyWith(color: context.appColor(AppColors.warning)),
      );
    }
    final text = plan.nextBottleAt.isAfter(now)
        ? s.nextBottleAt(formatHourMinute(plan.nextBottleAt))
        : s.nextBottleNow;
    return Text(
      text,
      style: styles.bodyMedium.copyWith(color: context.appColor(AppColors.textSecondary)),
    );
  }
}
```

`lib/features/dashboard/presentation/widgets/care_task_row.dart` :

```dart
import 'package:colette/core/dates/time_format.dart';
import 'package:colette/core/theme/app_colors.dart';
import 'package:colette/core/theme/design_tokens.dart';
import 'package:colette/core/theme/text_styles.dart';
import 'package:colette/features/dashboard/domain/entities/care_task.dart';
import 'package:colette/l10n/generated/app_localizations.dart';
import 'package:colette/shared/ui/care_type_ui.dart';
import 'package:flutter/material.dart';

/// Ligne « à faire » : icône, libellé, état ; tap = enregistrer le soin.
class CareTaskRow extends StatelessWidget {
  const CareTaskRow({super.key, required this.task, required this.onTap});

  final CareTask task;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    final styles = Theme.of(context).coletteTextStyles;
    final done = task.isDone;
    final accent = context.appColor(task.type.color);
    final muted = context.appColor(AppColors.textSecondary);
    return Material(
      color: context.appColor(done ? AppColors.pageBackground : AppColors.primaryContainer),
      shape: RoundedRectangleBorder(
        borderRadius: AppRadius.md.circular,
        side: done ? BorderSide(color: context.appColor(AppColors.border)) : BorderSide.none,
      ),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: AppSpacing.symmetric(horizontal: AppSpacing.md, vertical: AppSpacing.sm),
          child: Row(
            spacing: AppSpacing.sm.value,
            children: [
              Icon(task.type.icon, color: done ? muted : accent),
              Expanded(
                child: Text(
                  task.type.label(s),
                  style: styles.bodyMedium.copyWith(
                    color: done ? muted : context.appColor(AppColors.onSurface),
                    decoration: done ? TextDecoration.lineThrough : null,
                  ),
                ),
              ),
              if (task.target > 1)
                Text('${task.done}/${task.target}', style: styles.small.copyWith(color: muted)),
              if ((done, task.lastDoneAt) case (true, final at?))
                Text(
                  s.doneAt(formatHourMinute(at)),
                  style: styles.small.copyWith(color: context.appColor(AppColors.success)),
                ),
              Icon(
                done ? Icons.check_circle_outline : Icons.radio_button_unchecked,
                color: done ? context.appColor(AppColors.success) : context.appColor(AppColors.primary),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
```

`lib/features/dashboard/presentation/widgets/todo_section.dart` :

```dart
import 'package:colette/core/clock/app_clock.dart';
import 'package:colette/core/ids/id_generator.dart';
import 'package:colette/core/theme/app_colors.dart';
import 'package:colette/core/theme/design_tokens.dart';
import 'package:colette/core/theme/text_styles.dart';
import 'package:colette/features/dashboard/presentation/providers/dashboard_providers.dart';
import 'package:colette/features/dashboard/presentation/widgets/care_task_row.dart';
import 'package:colette/features/events/domain/use_cases/new_event_draft.dart';
import 'package:colette/features/events/presentation/providers/event_form_controller.dart';
import 'package:colette/features/household/presentation/providers/household_providers.dart';
import 'package:colette/l10n/generated/app_localizations.dart';
import 'package:colette/shared/domain/care_type.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Liste des soins du jour : à faire en premier, faits ensuite, grisés.
class TodoSection extends ConsumerWidget {
  const TodoSection({super.key});

  Future<void> _quickAdd(BuildContext context, WidgetRef ref, CareType type) async {
    final s = S.of(context);
    final draft = newEventDraft(
      now: ref.read(clockProvider).now(),
      deviceId: ref.read(deviceIdProvider),
      id: ref.read(idGeneratorProvider).newId(),
      preChecked: type,
    );
    final saved = await ref.read(eventFormControllerProvider.notifier).submit(draft);
    if (saved == null || !context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(s.saved),
        action: SnackBarAction(
          label: s.actionUndo,
          onPressed: () {
            if (!context.mounted) return;
            ref.read(eventFormControllerProvider.notifier).delete(saved.id);
          },
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Garde le contrôleur autoDispose vivant pendant l'await de _quickAdd / annuler.
    ref.watch(eventFormControllerProvider);
    final s = S.of(context);
    final tasks = ref.watch(dailyCareTasksProvider);
    final pending = tasks.where((t) => !t.isDone).toList();
    final done = tasks.where((t) => t.isDone).toList();
    if (tasks.isEmpty) {
      return Text(
        s.todoAllDone,
        style: Theme.of(context).coletteTextStyles.body.copyWith(
          color: context.appColor(AppColors.textSecondary),
        ),
      );
    }
    return Column(
      spacing: AppSpacing.sm.value,
      children: [
        for (final task in pending)
          CareTaskRow(task: task, onTap: () => _quickAdd(context, ref, task.type)),
        for (final task in done) CareTaskRow(task: task, onTap: null),
      ],
    );
  }
}
```

`lib/features/dashboard/presentation/widgets/day_counters_row.dart` :

```dart
import 'package:colette/core/theme/app_colors.dart';
import 'package:colette/core/theme/text_styles.dart';
import 'package:colette/features/dashboard/presentation/providers/dashboard_providers.dart';
import 'package:colette/l10n/generated/app_localizations.dart';
import 'package:colette/shared/ui/widgets/colette_card_surface.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Compteurs du jour : couches, pipis, cacas.
class DayCountersRow extends ConsumerWidget {
  const DayCountersRow({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final s = S.of(context);
    final counters = ref.watch(dayCountersProvider);
    return ColetteCardSurface(
      backgroundColor: AppColors.secondary,
      borderColor: AppColors.secondary,
      child: Row(
        children: [
          _Counter(value: counters.diapers, label: s.countersDiapers),
          _Counter(value: counters.pee, label: s.countersPee),
          _Counter(value: counters.poop, label: s.countersPoop),
        ],
      ),
    );
  }
}

class _Counter extends StatelessWidget {
  const _Counter({required this.value, required this.label});

  final int value;
  final String label;

  @override
  Widget build(BuildContext context) {
    final styles = Theme.of(context).coletteTextStyles;
    final color = context.appColor(AppColors.onSecondary);
    return Expanded(
      child: Column(
        children: [
          Text('$value', style: styles.numberMedium.copyWith(color: color)),
          Text(label, style: styles.small.copyWith(color: color)),
        ],
      ),
    );
  }
}
```

- [ ] **Step 11: Remplacer `lib/features/dashboard/presentation/pages/dashboard_page.dart`**

```dart
import 'package:colette/core/theme/design_tokens.dart';
import 'package:colette/features/dashboard/presentation/providers/bottle_form_request.dart';
import 'package:colette/features/dashboard/presentation/providers/dashboard_providers.dart';
import 'package:colette/features/dashboard/presentation/widgets/dashboard_header.dart';
import 'package:colette/features/dashboard/presentation/widgets/day_counters_row.dart';
import 'package:colette/features/dashboard/presentation/widgets/next_bottle_card.dart';
import 'package:colette/features/dashboard/presentation/widgets/todo_section.dart';
import 'package:colette/features/events/presentation/widgets/event_form_sheet.dart';
import 'package:colette/l10n/generated/app_localizations.dart';
import 'package:colette/shared/ui/widgets/section_header.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Onglet Aujourd'hui : âge, prochain biberon, reste à faire, compteurs.
class DashboardPage extends ConsumerStatefulWidget {
  const DashboardPage({super.key});

  @override
  ConsumerState<DashboardPage> createState() => _DashboardPageState();
}

class _DashboardPageState extends ConsumerState<DashboardPage> {
  @override
  void initState() {
    super.initState();
    ref.listenManual(bottleFormRequestProvider, fireImmediately: true, (
      _,
      requested,
    ) {
      if (!requested) return;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        ref.read(bottleFormRequestProvider.notifier).consume();
        final plan = ref.read(feedingPlanProvider);
        showEventFormSheet(context, suggestedBottleMl: plan?.suggestedMl);
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    return Scaffold(
      body: SafeArea(
        child: ListView(
          padding: AppSpacing.md.all,
          children: [
            const DashboardHeader(),
            AppSpacing.md.verticalSpace,
            const NextBottleCard(),
            SectionHeader(title: s.todoTitle),
            const TodoSection(),
            AppSpacing.lg.verticalSpace,
            const DayCountersRow(),
            AppSpacing.xl.verticalSpace,
          ],
        ),
      ),
    );
  }
}
```

- [ ] **Step 12: Créer le signal d'ouverture `lib/features/dashboard/presentation/providers/bottle_form_request.dart`**

La route `/today` reste `builder: (_, _) => const DashboardPage()`. L'ouverture du formulaire biberon à l'arrivée par notification passe par un signal Riverpod keepAlive, pas par un paramètre de requête : `StatefulShellRoute.indexedStack` ne reconstruit pas la page d'une branche déjà active quand seule la query change, donc un `go('/today?bottle=1')` depuis Aujourd'hui n'aurait aucun effet. `NotificationsGate` (tâche 16) appelle `request()`, `DashboardPage` consomme le signal dans son `listenManual` (`fireImmediately: true` pour le démarrage à froid).

```dart
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'bottle_form_request.g.dart';

/// Demande d'ouverture du formulaire biberon sur Aujourd'hui (arrivée par notification).
@Riverpod(keepAlive: true)
class BottleFormRequest extends _$BottleFormRequest {
  @override
  bool build() => false;

  void request() => state = true;

  void consume() => state = false;
}
```

**Note post-revue (appliquée dans le code) :** `feeding_plan_sync_test.dart` contient aussi un test « sync n'échoue pas sans profil » ; `dashboard_page_test.dart` surcharge `feedingPlanSyncProvider` (noop) et `eventsRepositoryProvider` (mock) et contient un test « taper une tâche à faire enregistre le soin et propose d'annuler ».

- [ ] **Step 13: Générer, analyser, tester**

Run: `dart run build_runner build -d && dart format lib test && dart analyze && flutter test`
Expected: `No issues found!` puis `All tests passed!`.

- [ ] **Step 14: Commit**

```bash
git add lib test
git commit -m "feat: onglet Aujourd'hui (plan biberons, soins du jour, compteurs) et sync du plan"
```

---

### Task 15: Onglet Réglages — bébé, pesées, soins attendus, foyer

**Files:**
- Create: `lib/features/baby/presentation/providers/baby_settings_controller.dart`
- Create: `lib/features/baby/presentation/widgets/baby_section.dart`, `weights_section.dart`, `add_weight_sheet.dart`, `care_settings_section.dart`
- Create: `lib/features/household/presentation/widgets/household_section.dart`
- Modify (remplacement complet) : `lib/features/baby/presentation/pages/settings_page.dart`
- Test: `test/features/baby/presentation/baby_settings_controller_test.dart`, `test/features/baby/presentation/settings_page_test.dart`

- [ ] **Step 1: Écrire les tests (rouges)**

`test/features/baby/presentation/baby_settings_controller_test.dart` :

```dart
import 'package:colette/core/ids/id_generator.dart';
import 'package:colette/core/result/failure.dart';
import 'package:colette/features/baby/domain/entities/baby_profile.dart';
import 'package:colette/features/baby/domain/entities/care_settings.dart';
import 'package:colette/features/baby/domain/entities/weight_entry.dart';
import 'package:colette/features/baby/domain/repositories/baby_repository.dart';
import 'package:colette/features/baby/presentation/providers/baby_providers.dart';
import 'package:colette/features/baby/presentation/providers/baby_settings_controller.dart';
import 'package:colette/features/dashboard/presentation/providers/feeding_plan_sync.dart';
import 'package:colette/features/household/presentation/providers/household_providers.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:mocktail/mocktail.dart';

import '../../../helpers/in_memory_household_local_store.dart';

class MockBabyRepository extends Mock implements BabyRepository {}

class MockFeedingPlanSync extends Mock implements FeedingPlanSync {}

void main() {
  late MockBabyRepository repo;
  late MockFeedingPlanSync sync;
  late ProviderContainer container;
  final profile = BabyProfile(name: 'Colette', birthDate: DateTime(2026, 9, 1));

  setUpAll(() {
    registerFallbackValue(profile);
    registerFallbackValue(WeightEntry(id: 'x', measuredAt: DateTime(2026), grams: 3000));
  });

  setUp(() {
    repo = MockBabyRepository();
    sync = MockFeedingPlanSync();
    when(() => sync.sync()).thenAnswer((_) async {});
    when(() => repo.watchProfile(any())).thenAnswer((_) => Stream.value(profile));
    container = ProviderContainer(
      overrides: [
        babyRepositoryProvider.overrideWithValue(repo),
        feedingPlanSyncProvider.overrideWithValue(sync),
        idGeneratorProvider.overrideWithValue(const FixedIdGenerator('w-new')),
        householdLocalStoreProvider.overrideWithValue(
          InMemoryHouseholdLocalStore(householdCode: 'ABCDEFGH'),
        ),
      ],
    );
    addTearDown(container.dispose);
  });

  BabySettingsController controller() => container.read(babySettingsControllerProvider.notifier);

  test('addWeight refuse un poids hors bornes', () async {
    final ok = await controller().addWeight(measuredAt: DateTime(2026, 9, 10), grams: 500);
    expect(ok, isFalse);
    expect(container.read(babySettingsControllerProvider).error, isA<ValidationFailure>());
    verifyNever(() => repo.addWeight(any(), any()));
  });

  test('addWeight enregistre puis synchronise le plan', () async {
    when(() => repo.addWeight(any(), any())).thenAnswer((_) async => right(null));
    final ok = await controller().addWeight(measuredAt: DateTime(2026, 9, 10), grams: 3600);
    expect(ok, isTrue);
    final saved = verify(() => repo.addWeight('ABCDEFGH', captureAny())).captured.single as WeightEntry;
    expect(saved.id, 'w-new');
    expect(saved.grams, 3600);
    verify(() => sync.sync()).called(1);
  });

  test('setCordFallenAt désactive le soin du nombril', () async {
    when(() => repo.saveProfile(any(), any())).thenAnswer((_) async => right(null));
    final ok = await controller().setCordFallenAt(profile, DateTime(2026, 9, 12));
    expect(ok, isTrue);
    final saved = verify(() => repo.saveProfile('ABCDEFGH', captureAny())).captured.single as BabyProfile;
    expect(saved.cordFallenAt, DateTime(2026, 9, 12));
    expect(saved.careSettings.umbilicalCareEnabled, isFalse);
  });

  test('updateCareSettings enregistre et synchronise', () async {
    when(() => repo.saveProfile(any(), any())).thenAnswer((_) async => right(null));
    final ok = await controller().updateCareSettings(profile, const CareSettings(feedsPerDay: 7));
    expect(ok, isTrue);
    final saved = verify(() => repo.saveProfile('ABCDEFGH', captureAny())).captured.single as BabyProfile;
    expect(saved.careSettings.feedsPerDay, 7);
    verify(() => sync.sync()).called(1);
  });
}
```

`test/features/baby/presentation/settings_page_test.dart` :

```dart
import 'package:colette/core/clock/app_clock.dart';
import 'package:colette/features/baby/domain/entities/baby_profile.dart';
import 'package:colette/features/baby/domain/entities/weight_entry.dart';
import 'package:colette/features/baby/presentation/pages/settings_page.dart';
import 'package:colette/features/baby/presentation/providers/baby_providers.dart';
import 'package:colette/features/household/presentation/providers/household_providers.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../helpers/in_memory_household_local_store.dart';
import '../../../helpers/pump_app.dart';

void main() {
  testWidgets('affiche le profil, les pesées et le code foyer', (tester) async {
    await pumpApp(
      tester,
      const SettingsPage(),
      overrides: [
        clockProvider.overrideWithValue(FixedClock(DateTime(2026, 9, 21, 12))),
        householdLocalStoreProvider.overrideWithValue(
          InMemoryHouseholdLocalStore(householdCode: 'ABCDEFGH'),
        ),
        babyProfileProvider.overrideWith(
          (ref) => Stream.value(BabyProfile(name: 'Colette', birthDate: DateTime(2026, 9, 1))),
        ),
        weightsProvider.overrideWith(
          (ref) => Stream.value([WeightEntry(id: 'w', measuredAt: DateTime(2026, 9, 9), grams: 3600)]),
        ),
        currentDeviceProvider.overrideWith((ref) => Stream.value(null)),
      ],
    );
    expect(find.text('Colette'), findsOneWidget);
    expect(find.text('3600 g'), findsOneWidget);
    expect(find.text('ABCDEFGH'), findsOneWidget);
    expect(find.text('Soins attendus'), findsOneWidget);
  });
}
```

- [ ] **Step 2: Vérifier l'échec**

Run: `flutter test test/features/baby/presentation`
Expected: échec de compilation.

- [ ] **Step 3: Créer `lib/features/baby/presentation/providers/baby_settings_controller.dart`**

```dart
import 'dart:async';

import 'package:colette/core/ids/id_generator.dart';
import 'package:colette/core/result/failure.dart';
import 'package:colette/features/baby/domain/entities/baby_profile.dart';
import 'package:colette/features/baby/domain/entities/care_settings.dart';
import 'package:colette/features/baby/domain/entities/weight_entry.dart';
import 'package:colette/features/baby/presentation/providers/baby_providers.dart';
import 'package:colette/features/dashboard/presentation/providers/feeding_plan_sync.dart';
import 'package:colette/features/household/presentation/providers/household_providers.dart';
import 'package:fpdart/fpdart.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'baby_settings_controller.g.dart';

/// Actions de l'onglet Réglages sur le profil, les pesées et les soins attendus.
@riverpod
class BabySettingsController extends _$BabySettingsController {
  static const minWeightGrams = 1000;
  static const maxWeightGrams = 20000;

  @override
  FutureOr<void> build() {}

  Future<bool> saveProfile(BabyProfile profile) =>
      _run((code) => ref.read(babyRepositoryProvider).saveProfile(code, profile));

  /// Le profil est passé par l'appelant : jamais relu depuis un provider
  /// autoDispose, qui pourrait être détruit pendant l'attente.
  Future<bool> updateCareSettings(BabyProfile profile, CareSettings settings) =>
      saveProfile(profile.copyWith(careSettings: settings));

  /// Renseigner la date désactive le soin du nombril ; l'effacer le réactive.
  Future<bool> setCordFallenAt(BabyProfile profile, DateTime? date) => saveProfile(
    profile.copyWith(
      cordFallenAt: date,
      careSettings: profile.careSettings.copyWith(umbilicalCareEnabled: date == null),
    ),
  );

  Future<bool> addWeight({required DateTime measuredAt, required int grams}) => _run((code) async {
    if (grams < minWeightGrams || grams > maxWeightGrams) {
      return left(const ValidationFailure(ValidationReason.invalidWeight));
    }
    final entry = WeightEntry(
      id: ref.read(idGeneratorProvider).newId(),
      measuredAt: measuredAt,
      grams: grams,
    );
    return ref.read(babyRepositoryProvider).addWeight(code, entry);
  });

  Future<bool> deleteWeight(String weightId) =>
      _run((code) => ref.read(babyRepositoryProvider).deleteWeight(code, weightId));

  Future<bool> _run(Future<Either<Failure, void>> Function(String code) action) async {
    final code = ref.read(currentHouseholdCodeProvider);
    if (code == null) return false;
    state = const AsyncLoading();
    final result = await action(code);
    state = result.fold(
      (failure) => AsyncError(failure, StackTrace.current),
      (_) => const AsyncData(null),
    );
    if (result.isRight()) await ref.read(feedingPlanSyncProvider).sync();
    return result.isRight();
  }
}
```

- [ ] **Step 4: Créer les sections**

`lib/features/baby/presentation/widgets/baby_section.dart` :

```dart
import 'package:colette/core/clock/app_clock.dart';
import 'package:colette/core/dates/date_extensions.dart';
import 'package:colette/core/theme/design_tokens.dart';
import 'package:colette/core/theme/text_styles.dart';
import 'package:colette/core/ui/date_time_picker.dart';
import 'package:colette/features/baby/domain/entities/baby_profile.dart';
import 'package:colette/features/baby/presentation/providers/baby_settings_controller.dart';
import 'package:colette/l10n/generated/app_localizations.dart';
import 'package:colette/shared/ui/widgets/colette_card_surface.dart';
import 'package:colette/shared/ui/widgets/date_field.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

/// Prénom, date de naissance, chute du cordon.
class BabySection extends ConsumerWidget {
  const BabySection({super.key, required this.profile});

  final BabyProfile profile;

  Future<void> _editName(BuildContext context, WidgetRef ref) async {
    final s = S.of(context);
    final controller = TextEditingController(text: profile.name);
    final name = await showDialog<String>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(s.fieldBabyName),
        content: TextField(controller: controller, autofocus: true, textCapitalization: .words),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: Text(s.actionCancel),
          ),
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(controller.text.trim()),
            child: Text(s.actionSave),
          ),
        ],
      ),
    );
    controller.dispose();
    if (name == null || name.isEmpty) return;
    await ref.read(babySettingsControllerProvider.notifier).saveProfile(profile.copyWith(name: name));
  }

  Future<void> _pickBirthDate(BuildContext context, WidgetRef ref) async {
    final picked = await showColetteDateTimePicker(
      context,
      initial: profile.birthDate,
      mode: CupertinoDatePickerMode.date,
      maximum: ref.read(clockProvider).now(),
    );
    if (picked == null) return;
    await ref
        .read(babySettingsControllerProvider.notifier)
        .saveProfile(profile.copyWith(birthDate: picked.dateOnly));
  }

  Future<void> _pickCordFallenAt(BuildContext context, WidgetRef ref) async {
    final now = ref.read(clockProvider).now();
    final picked = await showColetteDateTimePicker(
      context,
      initial: profile.cordFallenAt ?? now.dateOnly,
      mode: CupertinoDatePickerMode.date,
      maximum: now,
    );
    if (picked == null) return;
    await ref
        .read(babySettingsControllerProvider.notifier)
        .setCordFallenAt(profile, picked.dateOnly);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final s = S.of(context);
    final styles = Theme.of(context).coletteTextStyles;
    final dateFormat = DateFormat.yMMMMd('fr');
    return ColetteCardSurface(
      child: Column(
        spacing: AppSpacing.sm.value,
        children: [
          ListTile(
            contentPadding: EdgeInsets.zero,
            title: Text(s.fieldBabyName, style: styles.label),
            subtitle: Text(profile.name, style: styles.bodyLarge),
            trailing: const Icon(Icons.edit_outlined),
            onTap: () => _editName(context, ref),
          ),
          DateField(
            label: s.fieldBirthDate,
            value: dateFormat.format(profile.birthDate),
            onTap: () => _pickBirthDate(context, ref),
          ),
          Row(
            spacing: AppSpacing.sm.value,
            children: [
              Expanded(
                child: DateField(
                  label: s.settingsCordFallenAt,
                  value: switch (profile.cordFallenAt) {
                    null => s.settingsCordNotYet,
                    final date => dateFormat.format(date),
                  },
                  onTap: () => _pickCordFallenAt(context, ref),
                ),
              ),
              if (profile.cordFallenAt != null)
                IconButton(
                  onPressed: () => ref
                      .read(babySettingsControllerProvider.notifier)
                      .setCordFallenAt(profile, null),
                  icon: const Icon(Icons.close),
                ),
            ],
          ),
        ],
      ),
    );
  }
}
```

`lib/features/baby/presentation/widgets/add_weight_sheet.dart` :

```dart
import 'package:colette/core/clock/app_clock.dart';
import 'package:colette/core/dates/date_extensions.dart';
import 'package:colette/core/theme/design_tokens.dart';
import 'package:colette/core/theme/text_styles.dart';
import 'package:colette/core/ui/date_time_picker.dart';
import 'package:colette/features/baby/presentation/providers/baby_settings_controller.dart';
import 'package:colette/l10n/generated/app_localizations.dart';
import 'package:colette/shared/ui/widgets/date_field.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

/// Ouvre la saisie d'une pesée.
Future<void> showAddWeightSheet(BuildContext context) => showModalBottomSheet<void>(
  context: context,
  isScrollControlled: true,
  useSafeArea: true,
  builder: (_) => const AddWeightSheet(),
);

/// Date + grammes.
class AddWeightSheet extends ConsumerStatefulWidget {
  const AddWeightSheet({super.key});

  @override
  ConsumerState<AddWeightSheet> createState() => _AddWeightSheetState();
}

class _AddWeightSheetState extends ConsumerState<AddWeightSheet> {
  final _gramsController = TextEditingController();
  late DateTime _measuredAt = ref.read(clockProvider).now().dateOnly;

  @override
  void dispose() {
    _gramsController.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final picked = await showColetteDateTimePicker(
      context,
      initial: _measuredAt,
      mode: CupertinoDatePickerMode.date,
      maximum: ref.read(clockProvider).now(),
    );
    if (picked != null) setState(() => _measuredAt = picked.dateOnly);
  }

  Future<void> _save() async {
    final grams = int.tryParse(_gramsController.text.trim()) ?? 0;
    final ok = await ref
        .read(babySettingsControllerProvider.notifier)
        .addWeight(measuredAt: _measuredAt, grams: grams);
    if (ok && mounted) await Navigator.of(context).maybePop();
  }

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(context).bottom),
      child: ListView(
        shrinkWrap: true,
        padding: AppSpacing.lg.all,
        children: [
          Text(s.settingsAddWeight, style: Theme.of(context).coletteTextStyles.heading2),
          AppSpacing.md.verticalSpace,
          DateField(
            label: s.fieldMeasuredAt,
            value: DateFormat.yMMMMd('fr').format(_measuredAt),
            onTap: _pickDate,
          ),
          AppSpacing.md.verticalSpace,
          TextField(
            controller: _gramsController,
            decoration: InputDecoration(labelText: s.fieldWeightGrams),
            keyboardType: TextInputType.number,
            autofocus: true,
          ),
          AppSpacing.lg.verticalSpace,
          FilledButton(onPressed: _save, child: Text(s.actionAdd)),
        ],
      ),
    );
  }
}
```

`lib/features/baby/presentation/widgets/weights_section.dart` :

```dart
import 'package:colette/core/theme/app_colors.dart';
import 'package:colette/core/theme/design_tokens.dart';
import 'package:colette/core/theme/text_styles.dart';
import 'package:colette/features/baby/domain/entities/weight_entry.dart';
import 'package:colette/features/baby/presentation/providers/baby_providers.dart';
import 'package:colette/features/baby/presentation/providers/baby_settings_controller.dart';
import 'package:colette/features/baby/presentation/widgets/add_weight_sheet.dart';
import 'package:colette/l10n/generated/app_localizations.dart';
import 'package:colette/shared/ui/widgets/colette_card_surface.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

/// Liste des pesées, ajout et suppression.
class WeightsSection extends ConsumerWidget {
  const WeightsSection({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final s = S.of(context);
    final styles = Theme.of(context).coletteTextStyles;
    final weights = ref.watch(weightsProvider).value ?? const <WeightEntry>[];
    return ColetteCardSurface(
      padding: AppSpacing.sm.all,
      child: Column(
        children: [
          if (weights.isEmpty)
            Padding(
              padding: AppSpacing.sm.all,
              child: Text(
                s.settingsWeightsEmpty,
                style: styles.body.copyWith(color: context.appColor(AppColors.textSecondary)),
              ),
            ),
          for (final weight in weights)
            ListTile(
              dense: true,
              title: Text(s.weightGrams(weight.grams), style: styles.bodyMedium),
              subtitle: Text(DateFormat.yMMMd('fr').format(weight.measuredAt), style: styles.small),
              trailing: IconButton(
                icon: const Icon(Icons.delete_outline),
                onPressed: () =>
                    ref.read(babySettingsControllerProvider.notifier).deleteWeight(weight.id),
              ),
            ),
          TextButton.icon(
            onPressed: () => showAddWeightSheet(context),
            icon: const Icon(Icons.add),
            label: Text(s.settingsAddWeight),
          ),
        ],
      ),
    );
  }
}
```

`lib/features/baby/presentation/widgets/care_settings_section.dart` :

```dart
import 'package:colette/core/theme/design_tokens.dart';
import 'package:colette/core/theme/text_styles.dart';
import 'package:colette/features/baby/domain/entities/baby_profile.dart';
import 'package:colette/features/baby/domain/entities/care_settings.dart';
import 'package:colette/features/baby/presentation/providers/baby_settings_controller.dart';
import 'package:colette/l10n/generated/app_localizations.dart';
import 'package:colette/shared/ui/widgets/colette_card_surface.dart';
import 'package:colette/shared/ui/widgets/int_stepper_row.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Fréquences des soins attendus et nombre de biberons par jour.
/// Tient une copie locale optimiste : des taps rapides s'enchaînent sans attendre Firestore.
class CareSettingsSection extends ConsumerStatefulWidget {
  const CareSettingsSection({super.key, required this.profile});

  final BabyProfile profile;

  @override
  ConsumerState<CareSettingsSection> createState() => _CareSettingsSectionState();
}

class _CareSettingsSectionState extends ConsumerState<CareSettingsSection> {
  late CareSettings _settings = widget.profile.careSettings;

  @override
  void didUpdateWidget(covariant CareSettingsSection oldWidget) {
    super.didUpdateWidget(oldWidget);
    final incoming = widget.profile.careSettings;
    final writing = ref.read(babySettingsControllerProvider).isLoading;
    if (incoming != oldWidget.profile.careSettings && !writing) {
      _settings = incoming;
    }
  }

  void _update(CareSettings next) {
    setState(() => _settings = next);
    ref.read(babySettingsControllerProvider.notifier).updateCareSettings(widget.profile, next);
  }

  @override
  Widget build(BuildContext context) {
    // Garde le contrôleur autoDispose vivant pendant l'await de updateCareSettings.
    ref.watch(babySettingsControllerProvider);
    final s = S.of(context);
    final settings = _settings;
    void update(CareSettings next) => _update(next);
    return ColetteCardSurface(
      padding: AppSpacing.sm.all,
      child: Column(
        children: [
          IntStepperRow(
            label: s.settingsAdrigylPerDay,
            value: settings.adrigylPerDay,
            min: 0,
            max: 3,
            onChanged: (v) => update(settings.copyWith(adrigylPerDay: v)),
          ),
          IntStepperRow(
            label: s.settingsEyeCarePerDay,
            value: settings.eyeCarePerDay,
            min: 0,
            max: 4,
            onChanged: (v) => update(settings.copyWith(eyeCarePerDay: v)),
          ),
          IntStepperRow(
            label: s.settingsNoseCarePerDay,
            value: settings.noseCarePerDay,
            min: 0,
            max: 4,
            onChanged: (v) => update(settings.copyWith(noseCarePerDay: v)),
          ),
          IntStepperRow(
            label: s.settingsBathEveryDays,
            value: settings.bathEveryDays,
            min: 1,
            max: 7,
            onChanged: (v) => update(settings.copyWith(bathEveryDays: v)),
          ),
          IntStepperRow(
            label: s.settingsFeedsPerDay,
            value: settings.feedsPerDay,
            min: 4,
            max: 12,
            onChanged: (v) => update(settings.copyWith(feedsPerDay: v)),
          ),
          SwitchListTile(
            contentPadding: AppSpacing.sm.horizontal,
            title: Text(s.settingsUmbilicalEnabled, style: Theme.of(context).coletteTextStyles.body),
            value: settings.umbilicalCareEnabled,
            onChanged: (v) => update(settings.copyWith(umbilicalCareEnabled: v)),
          ),
        ],
      ),
    );
  }
}
```

`lib/features/household/presentation/widgets/household_section.dart` :

```dart
import 'package:colette/core/theme/app_colors.dart';
import 'package:colette/core/theme/design_tokens.dart';
import 'package:colette/core/theme/text_styles.dart';
import 'package:colette/features/household/presentation/providers/household_providers.dart';
import 'package:colette/l10n/generated/app_localizations.dart';
import 'package:colette/shared/ui/widgets/colette_card_surface.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Code du foyer à partager et sortie du foyer.
class HouseholdSection extends ConsumerWidget {
  const HouseholdSection({super.key, required this.code});

  final String code;

  Future<void> _copy(BuildContext context) async {
    final s = S.of(context);
    await Clipboard.setData(ClipboardData(text: code));
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(s.copied)));
  }

  Future<void> _leave(BuildContext context, WidgetRef ref) async {
    final s = S.of(context);
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(s.leaveHouseholdTitle),
        content: Text(s.leaveHouseholdBody),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: Text(s.actionCancel),
          ),
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: Text(s.settingsLeaveHousehold),
          ),
        ],
      ),
    );
    if (confirmed == true) await ref.read(currentHouseholdCodeProvider.notifier).clear();
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final s = S.of(context);
    final styles = Theme.of(context).coletteTextStyles;
    return ColetteCardSurface(
      child: Column(
        crossAxisAlignment: .start,
        spacing: AppSpacing.sm.value,
        children: [
          Text(
            s.settingsHouseholdCode,
            style: styles.label.copyWith(color: context.appColor(AppColors.textSecondary)),
          ),
          Row(
            children: [
              Expanded(
                child: SelectableText(
                  code,
                  style: styles.numberMedium.copyWith(
                    color: context.appColor(AppColors.primary),
                    letterSpacing: AppSpacing.xxs.value,
                  ),
                ),
              ),
              TextButton.icon(
                onPressed: () => _copy(context),
                icon: const Icon(Icons.copy_outlined),
                label: Text(s.actionCopy),
              ),
            ],
          ),
          const Divider(),
          TextButton.icon(
            onPressed: () => _leave(context, ref),
            icon: Icon(Icons.logout, color: context.appColor(AppColors.error)),
            label: Text(
              s.settingsLeaveHousehold,
              style: styles.bodyMedium.copyWith(color: context.appColor(AppColors.error)),
            ),
          ),
        ],
      ),
    );
  }
}
```

- [ ] **Step 5: Remplacer `lib/features/baby/presentation/pages/settings_page.dart`**

```dart
import 'package:colette/core/theme/design_tokens.dart';
import 'package:colette/core/ui/failure_message.dart';
import 'package:colette/features/baby/presentation/providers/baby_providers.dart';
import 'package:colette/features/baby/presentation/providers/baby_settings_controller.dart';
import 'package:colette/features/baby/presentation/widgets/baby_section.dart';
import 'package:colette/features/baby/presentation/widgets/care_settings_section.dart';
import 'package:colette/features/baby/presentation/widgets/weights_section.dart';
import 'package:colette/features/household/presentation/providers/household_providers.dart';
import 'package:colette/features/household/presentation/widgets/household_section.dart';
import 'package:colette/l10n/generated/app_localizations.dart';
import 'package:colette/shared/ui/widgets/section_header.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Onglet Réglages : bébé, pesées, soins attendus, notifications, foyer.
class SettingsPage extends ConsumerWidget {
  const SettingsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final s = S.of(context);
    ref.listen(babySettingsControllerProvider, (_, next) {
      if (next case AsyncError(:final error)) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(failureMessage(error, s))),
        );
      }
    });
    final profile = ref.watch(babyProfileProvider).value;
    final code = ref.watch(currentHouseholdCodeProvider);
    return Scaffold(
      appBar: AppBar(title: Text(s.settingsTitle)),
      body: ListView(
        padding: AppSpacing.md.horizontal,
        children: [
          if (profile != null) ...[
            SectionHeader(title: s.settingsBabySection),
            BabySection(profile: profile),
            SectionHeader(title: s.settingsWeightsSection),
            const WeightsSection(),
            SectionHeader(title: s.settingsCareSection),
            CareSettingsSection(profile: profile),
          ] else
            const Padding(
              padding: EdgeInsets.zero,
              child: Center(child: CircularProgressIndicator()),
            ),
          if (code != null) ...[
            SectionHeader(title: s.settingsHouseholdSection),
            HouseholdSection(code: code),
          ],
          AppSpacing.xl.verticalSpace,
        ],
      ),
    );
  }
}
```

**Note post-revue (appliquée dans le code) :** `test/features/baby/presentation/care_settings_section_test.dart` vérifie que deux taps rapides sur un stepper s'additionnent ; `settings_page_test.dart` fait un `scrollUntilVisible` avant de chercher le code foyer.

- [ ] **Step 6: Générer, analyser, tester**

Run: `dart run build_runner build -d && dart format lib test && dart analyze && flutter test`
Expected: `No issues found!` puis `All tests passed!`.

- [ ] **Step 7: Commit**

```bash
git add lib test
git commit -m "feat: onglet Réglages (profil bébé, pesées, soins attendus, foyer)"
```

---

### Task 16: Notifications côté client — token FCM, préférences, ouverture par notification

**Files:**
- Create: `lib/features/notifications/domain/push_token_source.dart`
- Create: `lib/features/notifications/data/firebase_push_token_source.dart`
- Create: `lib/features/notifications/presentation/providers/notifications_providers.dart`
- Create: `lib/features/notifications/presentation/widgets/notifications_section.dart`
- Create: `lib/app/notifications_gate.dart`
- Create: `test/helpers/fake_push_token_source.dart`
- Modify: `lib/app/colette_app.dart`, `lib/features/baby/presentation/pages/settings_page.dart`, `lib/l10n/app_fr.arb` (`unitHour`), `ios/Runner/Info.plist`, `test/app/app_router_test.dart`
- Test: `test/features/notifications/presentation/push_registration_test.dart`

- [ ] **Step 1: Ajouter la clé `unitHour` dans `lib/l10n/app_fr.arb`**

Après la ligne `"unitMl": "ml",` :

```json
  "unitHour": "h",
```

- [ ] **Step 2: Créer `test/helpers/fake_push_token_source.dart`**

```dart
import 'dart:async';

import 'package:colette/features/notifications/domain/push_token_source.dart';

/// Source de token FCM contrôlable pour les tests.
class FakePushTokenSource implements PushTokenSource {
  FakePushTokenSource({this.granted = false, this.token});

  final bool granted;
  final String? token;
  final _refresh = StreamController<String>.broadcast();
  final _opened = StreamController<Map<String, String>>.broadcast();

  @override
  Future<bool> requestPermission() async => granted;

  @override
  Future<String?> getToken() async => token;

  @override
  Stream<String> get onTokenRefresh => _refresh.stream;

  @override
  Future<Map<String, String>?> getInitialMessageData() async => null;

  @override
  Stream<Map<String, String>> get onMessageOpened => _opened.stream;

  void emitRefresh(String newToken) => _refresh.add(newToken);

  void emitOpened(Map<String, String> data) => _opened.add(data);
}
```

- [ ] **Step 3: Écrire le test (rouge)**

`test/features/notifications/presentation/push_registration_test.dart` :

```dart
import 'package:colette/features/household/domain/repositories/device_repository.dart';
import 'package:colette/features/household/presentation/providers/household_providers.dart';
import 'package:colette/features/notifications/presentation/providers/notifications_providers.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:mocktail/mocktail.dart';

import '../../../helpers/fake_push_token_source.dart';
import '../../../helpers/in_memory_household_local_store.dart';

class MockDeviceRepository extends Mock implements DeviceRepository {}

void main() {
  late MockDeviceRepository devices;

  ProviderContainer makeContainer(FakePushTokenSource source) {
    final container = ProviderContainer(
      overrides: [
        pushTokenSourceProvider.overrideWithValue(source),
        deviceRepositoryProvider.overrideWithValue(devices),
        householdLocalStoreProvider.overrideWithValue(
          InMemoryHouseholdLocalStore(householdCode: 'ABCDEFGH', deviceId: 'dev-1'),
        ),
      ],
    );
    addTearDown(container.dispose);
    return container;
  }

  setUp(() {
    devices = MockDeviceRepository();
    when(() => devices.updateFcmToken(any(), any(), any())).thenAnswer((_) async => right(null));
  });

  test('register écrit le token puis suit les renouvellements', () async {
    final source = FakePushTokenSource(granted: true, token: 'tok-1');
    final container = makeContainer(source);
    await container.read(pushRegistrationProvider.notifier).register();
    verify(() => devices.updateFcmToken('ABCDEFGH', 'dev-1', 'tok-1')).called(1);

    source.emitRefresh('tok-2');
    await Future<void>.delayed(Duration.zero);
    verify(() => devices.updateFcmToken('ABCDEFGH', 'dev-1', 'tok-2')).called(1);
  });

  test('sans permission, aucun token n\'est écrit', () async {
    final container = makeContainer(FakePushTokenSource(granted: false, token: 'tok-1'));
    await container.read(pushRegistrationProvider.notifier).register();
    verifyNever(() => devices.updateFcmToken(any(), any(), any()));
  });
}
```

- [ ] **Step 4: Vérifier l'échec**

Run: `flutter test test/features/notifications`
Expected: échec de compilation.

- [ ] **Step 5: Créer le domaine et la data**

`lib/features/notifications/domain/push_token_source.dart` :

```dart
/// Accès au système de push : permission, token, ouvertures par notification.
abstract interface class PushTokenSource {
  /// Demande la permission iOS ; `true` si accordée (ou provisoire).
  Future<bool> requestPermission();

  Future<String?> getToken();

  Stream<String> get onTokenRefresh;

  /// Données de la notification qui a lancé l'app depuis l'état terminé.
  Future<Map<String, String>?> getInitialMessageData();

  /// Données des notifications ouvertes pendant que l'app était en arrière-plan.
  Stream<Map<String, String>> get onMessageOpened;
}
```

`lib/features/notifications/data/firebase_push_token_source.dart` :

```dart
import 'package:colette/features/notifications/domain/push_token_source.dart';
import 'package:firebase_messaging/firebase_messaging.dart';

/// Implémentation Firebase Cloud Messaging.
final class FirebasePushTokenSource implements PushTokenSource {
  FirebasePushTokenSource(this._messaging);

  final FirebaseMessaging _messaging;

  static Map<String, String> _stringData(RemoteMessage message) =>
      message.data.map((key, value) => MapEntry(key, '$value'));

  @override
  Future<bool> requestPermission() async {
    final settings = await _messaging.requestPermission();
    await _messaging.setForegroundNotificationPresentationOptions(
      alert: true,
      badge: true,
      sound: true,
    );
    return switch (settings.authorizationStatus) {
      AuthorizationStatus.authorized || AuthorizationStatus.provisional => true,
      _ => false,
    };
  }

  @override
  Future<String?> getToken() => _messaging.getToken();

  @override
  Stream<String> get onTokenRefresh => _messaging.onTokenRefresh;

  @override
  Future<Map<String, String>?> getInitialMessageData() async {
    final message = await _messaging.getInitialMessage();
    return message == null ? null : _stringData(message);
  }

  @override
  Stream<Map<String, String>> get onMessageOpened =>
      FirebaseMessaging.onMessageOpenedApp.map(_stringData);
}
```

- [ ] **Step 6: Créer `lib/features/notifications/presentation/providers/notifications_providers.dart`**

```dart
import 'dart:async';
import 'dart:developer' as developer;

import 'package:colette/core/firebase/firebase_providers.dart';
import 'package:colette/features/household/domain/entities/device_info.dart';
import 'package:colette/features/household/presentation/providers/household_providers.dart';
import 'package:colette/features/notifications/data/firebase_push_token_source.dart';
import 'package:colette/features/notifications/domain/push_token_source.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'notifications_providers.g.dart';

@Riverpod(keepAlive: true)
PushTokenSource pushTokenSource(Ref ref) =>
    FirebasePushTokenSource(ref.watch(firebaseMessagingProvider));

/// Enregistre le token FCM de cet iPhone dans le foyer et suit ses renouvellements.
@Riverpod(keepAlive: true)
class PushRegistration extends _$PushRegistration {
  StreamSubscription<String>? _refreshSubscription;

  @override
  FutureOr<void> build() {
    ref.onDispose(() => _refreshSubscription?.cancel());
  }

  Future<void> register() async {
    final code = ref.read(currentHouseholdCodeProvider);
    if (code == null) return;
    final source = ref.read(pushTokenSourceProvider);
    if (!await source.requestPermission()) return;
    final token = await source.getToken();
    if (token != null) await _saveToken(code, token);
    await _refreshSubscription?.cancel();
    _refreshSubscription = source.onTokenRefresh.listen(
      (newToken) => _saveToken(code, newToken),
    );
  }

  Future<void> _saveToken(String code, String token) async {
    final result = await ref
        .read(deviceRepositoryProvider)
        .updateFcmToken(code, ref.read(deviceIdProvider), token);
    result.fold(
      (failure) =>
          developer.log('Token FCM non enregistré : $failure', name: 'colette'),
      (_) {},
    );
  }
}

/// Enregistre les préférences de notification de cet iPhone.
@riverpod
class NotificationSettingsController extends _$NotificationSettingsController {
  @override
  FutureOr<void> build() {}

  Future<bool> save(DeviceInfo device) async {
    final code = ref.read(currentHouseholdCodeProvider);
    if (code == null) return false;
    state = const AsyncLoading();
    final result = await ref
        .read(deviceRepositoryProvider)
        .saveDevice(code, device);
    state = result.fold(
      (failure) => AsyncError(failure, StackTrace.current),
      (_) => const AsyncData(null),
    );
    return result.isRight();
  }
}
```

- [ ] **Step 7: Créer `lib/features/notifications/presentation/widgets/notifications_section.dart`**

```dart
import 'package:colette/core/theme/design_tokens.dart';
import 'package:colette/core/theme/text_styles.dart';
import 'package:colette/features/household/domain/entities/device_info.dart';
import 'package:colette/features/notifications/presentation/providers/notifications_providers.dart';
import 'package:colette/l10n/generated/app_localizations.dart';
import 'package:colette/shared/ui/widgets/colette_card_surface.dart';
import 'package:colette/shared/ui/widgets/int_stepper_row.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Préférences de notification de cet iPhone.
/// Tient une copie locale optimiste : un échec d'enregistrement revient en arrière.
class NotificationsSection extends ConsumerStatefulWidget {
  const NotificationsSection({super.key, required this.device});

  final DeviceInfo device;

  static const minHour = 5;
  static const maxHour = 12;

  @override
  ConsumerState<NotificationsSection> createState() =>
      _NotificationsSectionState();
}

class _NotificationsSectionState extends ConsumerState<NotificationsSection> {
  late DeviceInfo _device = widget.device;

  @override
  void didUpdateWidget(covariant NotificationsSection oldWidget) {
    super.didUpdateWidget(oldWidget);
    final writing = ref.read(notificationSettingsControllerProvider).isLoading;
    if (widget.device != oldWidget.device && !writing) {
      _device = widget.device;
    }
  }

  Future<void> _update(DeviceInfo next, {bool enabling = false}) async {
    setState(() => _device = next);
    final ok = await ref
        .read(notificationSettingsControllerProvider.notifier)
        .save(next);
    if (!ok && mounted) setState(() => _device = widget.device);
    if (ok && enabling) ref.read(pushRegistrationProvider.notifier).register();
  }

  @override
  Widget build(BuildContext context) {
    // Garde le contrôleur autoDispose vivant pendant l'await de save.
    ref.watch(notificationSettingsControllerProvider);
    final s = S.of(context);
    final body = Theme.of(context).coletteTextStyles.body;
    return ColetteCardSurface(
      padding: AppSpacing.sm.all,
      child: Column(
        children: [
          SwitchListTile(
            contentPadding: AppSpacing.sm.horizontal,
            title: Text(s.settingsNotifyOthersEvents, style: body),
            value: _device.notifyOnOthersEvents,
            onChanged: (v) =>
                _update(_device.copyWith(notifyOnOthersEvents: v), enabling: v),
          ),
          SwitchListTile(
            contentPadding: AppSpacing.sm.horizontal,
            title: Text(s.settingsNotifyBottle, style: body),
            value: _device.notifyBottleReminder,
            onChanged: (v) =>
                _update(_device.copyWith(notifyBottleReminder: v), enabling: v),
          ),
          SwitchListTile(
            contentPadding: AppSpacing.sm.horizontal,
            title: Text(s.settingsNotifyMorning, style: body),
            value: _device.notifyMorningDigest,
            onChanged: (v) =>
                _update(_device.copyWith(notifyMorningDigest: v), enabling: v),
          ),
          if (_device.notifyMorningDigest)
            IntStepperRow(
              label: s.settingsMorningHour,
              value: _device.morningDigestHour,
              min: NotificationsSection.minHour,
              max: NotificationsSection.maxHour,
              suffix: s.unitHour,
              onChanged: (v) => _update(_device.copyWith(morningDigestHour: v)),
            ),
        ],
      ),
    );
  }
}
```

- [ ] **Step 8: Créer `lib/app/notifications_gate.dart`**

```dart
import 'dart:async';

import 'package:colette/app/router/app_router.dart';
import 'package:colette/features/dashboard/presentation/providers/bottle_form_request.dart';
import 'package:colette/features/household/presentation/providers/household_providers.dart';
import 'package:colette/features/notifications/presentation/providers/notifications_providers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Enregistre le push dès qu'un foyer existe et navigue à l'ouverture d'une notification.
class NotificationsGate extends ConsumerStatefulWidget {
  const NotificationsGate({super.key, required this.child});

  final Widget child;

  @override
  ConsumerState<NotificationsGate> createState() => _NotificationsGateState();
}

class _NotificationsGateState extends ConsumerState<NotificationsGate> {
  StreamSubscription<Map<String, String>>? _openedSubscription;

  @override
  void initState() {
    super.initState();
    ref.listenManual(currentHouseholdCodeProvider, fireImmediately: true, (
      _,
      code,
    ) {
      if (code != null) ref.read(pushRegistrationProvider.notifier).register();
    });
    final source = ref.read(pushTokenSourceProvider);
    _openedSubscription = source.onMessageOpened.listen(_navigate);
    source.getInitialMessageData().then((data) {
      if (!mounted || data == null) return;
      _navigate(data);
    });
  }

  static const _allowedPaths = {
    AppRoutes.today,
    AppRoutes.journal,
    AppRoutes.settings,
  };

  void _navigate(Map<String, String> data) {
    final route = data['route'];
    if (route == null) return;
    final uri = Uri.tryParse(route);
    if (uri == null || !_allowedPaths.contains(uri.path)) return;
    if (uri.path == AppRoutes.today &&
        uri.queryParameters[AppRoutes.openBottleParam] == '1') {
      ref.read(bottleFormRequestProvider.notifier).request();
    }
    ref.read(appRouterProvider).go(uri.path);
  }

  @override
  void dispose() {
    _openedSubscription?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => widget.child;
}
```

- [ ] **Step 9: Brancher la gate dans `lib/app/colette_app.dart`**

Ajouter l'import `package:colette/app/notifications_gate.dart` et, dans `MaterialApp.router`, le paramètre :

```dart
      builder: (context, child) => NotificationsGate(child: child ?? const SizedBox.shrink()),
```

- [ ] **Step 10: Ajouter la section dans `lib/features/baby/presentation/pages/settings_page.dart`**

Ajouter les imports `package:colette/features/notifications/presentation/widgets/notifications_section.dart` et `package:colette/features/notifications/presentation/providers/notifications_providers.dart`. Dans `build`, à côté du `ref.listen(babySettingsControllerProvider, …)`, ajouter le même SnackBar pour le contrôleur des notifications :

```dart
    ref.listen(notificationSettingsControllerProvider, (_, next) {
      if (next case AsyncError(:final error)) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(failureMessage(error, s))));
      }
    });
    final device = ref.watch(currentDeviceProvider).value;
```

et, juste avant `if (code != null) ...[`, insérer (pas d'en-tête sans contenu pendant le chargement du flux) :

```dart
          if (device != null) ...[
            SectionHeader(title: s.settingsNotificationsSection),
            NotificationsSection(device: device),
          ],
```

- [ ] **Step 10 bis: Tests de la section — `test/features/notifications/presentation/notifications_section_test.dart`**

Copie locale optimiste (deux taps rapides s'additionnent), activation d'un switch qui enregistre puis déclenche `register()`, et retour arrière du switch sur échec :

```dart
import 'package:colette/core/result/failure.dart';
import 'package:colette/features/household/domain/entities/device_info.dart';
import 'package:colette/features/household/domain/repositories/device_repository.dart';
import 'package:colette/features/household/presentation/providers/household_providers.dart';
import 'package:colette/features/notifications/presentation/providers/notifications_providers.dart';
import 'package:colette/features/notifications/presentation/widgets/notifications_section.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:mocktail/mocktail.dart';

import '../../../helpers/fake_push_token_source.dart';
import '../../../helpers/in_memory_household_local_store.dart';
import '../../../helpers/pump_app.dart';

class MockDeviceRepository extends Mock implements DeviceRepository {}

void main() {
  const device = DeviceInfo(id: 'dev-1', label: 'iPhone');
  late MockDeviceRepository devices;

  setUpAll(() => registerFallbackValue(device));

  setUp(() {
    devices = MockDeviceRepository();
    when(() => devices.updateFcmToken(any(), any(), any()))
        .thenAnswer((_) async => right(null));
  });

  List<Override> overrides() => [
    deviceRepositoryProvider.overrideWithValue(devices),
    householdLocalStoreProvider.overrideWithValue(
      InMemoryHouseholdLocalStore(householdCode: 'ABCDEFGH'),
    ),
    pushTokenSourceProvider.overrideWithValue(
      FakePushTokenSource(granted: true, token: 'tok'),
    ),
  ];

  testWidgets('deux taps rapides sur l\'heure du digest s\'additionnent', (
    tester,
  ) async {
    when(() => devices.saveDevice(any(), any()))
        .thenAnswer((_) async => right(null));
    await pumpApp(
      tester,
      const Scaffold(
        body: SingleChildScrollView(
          child: NotificationsSection(device: device),
        ),
      ),
      overrides: overrides(),
    );
    final plusButton = find.widgetWithIcon(IconButton, Icons.add);
    await tester.tap(plusButton);
    await tester.pump();
    await tester.tap(plusButton);
    await tester.pumpAndSettle();
    final saved = verify(() => devices.saveDevice('ABCDEFGH', captureAny()))
        .captured
        .cast<DeviceInfo>();
    expect(saved.last.morningDigestHour, 10);
    expect(find.text('10 h'), findsOneWidget);
  });

  testWidgets(
    'activer un switch enregistre et déclenche l\'enregistrement push',
    (tester) async {
      when(() => devices.saveDevice(any(), any()))
          .thenAnswer((_) async => right(null));
      await pumpApp(
        tester,
        NotificationsSection(
          device: device.copyWith(notifyBottleReminder: false),
        ),
        overrides: overrides(),
      );
      await tester.tap(find.widgetWithText(SwitchListTile, 'Rappel biberon'));
      await tester.pumpAndSettle();
      final saved = verify(() => devices.saveDevice('ABCDEFGH', captureAny()))
          .captured
          .cast<DeviceInfo>();
      expect(saved.single.notifyBottleReminder, isTrue);
      verify(() => devices.updateFcmToken('ABCDEFGH', any(), 'tok')).called(1);
    },
  );

  testWidgets('un échec d\'enregistrement remet le switch en arrière', (
    tester,
  ) async {
    when(() => devices.saveDevice(any(), any()))
        .thenAnswer((_) async => left(const NetworkFailure()));
    await pumpApp(
      tester,
      NotificationsSection(
        device: device.copyWith(notifyBottleReminder: false),
      ),
      overrides: overrides(),
    );
    await tester.tap(find.widgetWithText(SwitchListTile, 'Rappel biberon'));
    await tester.pumpAndSettle();
    final tile = tester.widget<SwitchListTile>(
      find.widgetWithText(SwitchListTile, 'Rappel biberon'),
    );
    expect(tile.value, isFalse);
  });
}
```

- [ ] **Step 11: Surcharger la source push dans `test/app/app_router_test.dart`**

Ajouter les imports :

```dart
import 'package:colette/features/notifications/presentation/providers/notifications_providers.dart';
import '../helpers/fake_push_token_source.dart';
```

et dans la liste `overrides` de `pumpColetteApp` :

```dart
          pushTokenSourceProvider.overrideWithValue(FakePushTokenSource()),
```

- [ ] **Step 11 bis: Tests de la gate — `test/app/notifications_gate_test.dart`**

Token écrit dans Firestore au démarrage avec un foyer, ouverture du formulaire biberon depuis Aujourd'hui et depuis le Journal, changement d'onglet par route, routes invalides ignorées, message initial (démarrage à froid) :

```dart
import 'package:colette/app/colette_app.dart';
import 'package:colette/core/clock/now_providers.dart';
import 'package:colette/core/connectivity/connectivity_provider.dart';
import 'package:colette/core/firebase/firebase_providers.dart';
import 'package:colette/core/firebase/firestore_paths.dart';
import 'package:colette/features/events/presentation/pages/timeline_page.dart';
import 'package:colette/features/events/presentation/widgets/event_form_sheet.dart';
import 'package:colette/features/household/presentation/providers/household_providers.dart';
import 'package:colette/features/notifications/presentation/providers/notifications_providers.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import '../helpers/fake_push_token_source.dart';
import '../helpers/in_memory_household_local_store.dart';

void main() {
  Future<void> pumpColetteApp(
    WidgetTester tester, {
    required FakePushTokenSource pushSource,
    FakeFirebaseFirestore? firestore,
  }) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          householdLocalStoreProvider.overrideWithValue(
            InMemoryHouseholdLocalStore(
              householdCode: 'ABCDEFGH',
              deviceId: 'dev-1',
            ),
          ),
          isOnlineProvider.overrideWith((ref) => Stream.value(true)),
          firestoreProvider.overrideWithValue(
            firestore ?? FakeFirebaseFirestore(),
          ),
          minuteTickerProvider.overrideWith((ref) => const Stream.empty()),
          pushTokenSourceProvider.overrideWithValue(pushSource),
        ],
        child: const ColetteApp(),
      ),
    );
    await tester.pumpAndSettle();
  }

  testWidgets('au démarrage avec un foyer, le token est écrit dans Firestore', (
    tester,
  ) async {
    final firestore = FakeFirebaseFirestore();
    await pumpColetteApp(
      tester,
      pushSource: FakePushTokenSource(granted: true, token: 'tok'),
      firestore: firestore,
    );
    final doc = await firestore
        .collection(FirestorePaths.households)
        .doc('ABCDEFGH')
        .collection(FirestorePaths.devices)
        .doc('dev-1')
        .get();
    expect(doc.data()?['fcmToken'], 'tok');
  });

  testWidgets('ouvrir une notification navigue vers sa route', (tester) async {
    final source = FakePushTokenSource(granted: true, token: 'tok');
    await pumpColetteApp(tester, pushSource: source);
    source.emitOpened({'route': '/journal'});
    await tester.pumpAndSettle();
    expect(find.byType(TimelinePage), findsOneWidget);
  });

  testWidgets(
    'ouvrir la notification biberon depuis Aujourd\'hui ouvre le formulaire',
    (tester) async {
      final source = FakePushTokenSource(granted: true, token: 'tok');
      await pumpColetteApp(tester, pushSource: source);
      source.emitOpened({'route': '/today?bottle=1'});
      await tester.pumpAndSettle();
      expect(find.byType(EventFormSheet), findsOneWidget);
    },
  );

  testWidgets('ouvrir la notification biberon depuis le Journal revient sur '
      'Aujourd\'hui et ouvre le formulaire', (tester) async {
    final source = FakePushTokenSource(granted: true, token: 'tok');
    await pumpColetteApp(tester, pushSource: source);
    await tester.tap(find.text('Journal'));
    await tester.pumpAndSettle();
    expect(find.byType(TimelinePage), findsOneWidget);
    source.emitOpened({'route': '/today?bottle=1'});
    await tester.pumpAndSettle();
    expect(find.byType(EventFormSheet), findsOneWidget);
    expect(find.byType(TimelinePage), findsNothing);
  });

  testWidgets('une route invalide est ignorée', (tester) async {
    final source = FakePushTokenSource(granted: true, token: 'tok');
    await pumpColetteApp(tester, pushSource: source);
    source.emitOpened({'route': 'javascript:evil'});
    await tester.pumpAndSettle();
    expect(find.byType(EventFormSheet), findsNothing);
    expect(find.text('Aujourd\'hui'), findsWidgets);
    source.emitOpened({'route': '/nope'});
    await tester.pumpAndSettle();
    expect(find.byType(EventFormSheet), findsNothing);
    expect(find.text('Aujourd\'hui'), findsWidgets);
  });

  testWidgets('le message initial est traité au démarrage (route biberon)', (
    tester,
  ) async {
    await pumpColetteApp(
      tester,
      pushSource: FakePushTokenSource(
        granted: true,
        token: 'tok',
        initialMessageData: {'route': '/today?bottle=1'},
      ),
    );
    expect(find.byType(EventFormSheet), findsOneWidget);
  });

  testWidgets(
    'le message initial est traité au démarrage (changement de branche)',
    (tester) async {
      await pumpColetteApp(
        tester,
        pushSource: FakePushTokenSource(
          granted: true,
          token: 'tok',
          initialMessageData: {'route': '/journal'},
        ),
      );
      expect(find.byType(TimelinePage), findsOneWidget);
    },
  );
}
```

- [ ] **Step 12: Activer le mode arrière-plan push dans `ios/Runner/Info.plist`**

Run:

```bash
/usr/libexec/PlistBuddy -c "Add :UIBackgroundModes array" -c "Add :UIBackgroundModes:0 string remote-notification" ios/Runner/Info.plist && /usr/libexec/PlistBuddy -c "Print :UIBackgroundModes" ios/Runner/Info.plist
```

Expected: `Array { remote-notification }`.

Étape manuelle pour Maxence, hors plan : dans Xcode, cible Runner → Signing & Capabilities → ajouter *Push Notifications* et *Background Modes → Remote notifications* (crée `Runner.entitlements` avec `aps-environment`).

- [ ] **Step 13: Générer, analyser, tester**

Run: `flutter pub get && dart run build_runner build -d && dart format lib test && dart analyze && flutter test`
Expected: `No issues found!` puis `All tests passed!`.

- [ ] **Step 14: Commit**

```bash
git add lib test ios/Runner/Info.plist
git commit -m "feat: notifications client (token FCM, préférences, ouverture par notification)"
```

---

### Task 17: Finalisation — README, lints Riverpod, vérification complète

**Files:**
- Modify: `README.md`

- [ ] **Step 1: Remplacer `README.md`**

```markdown
# Colette

App iOS privée pour suivre les soins quotidiens de notre nouveau-né, à deux.

## Prérequis

- Flutter 3.47 (stable), Xcode, CocoaPods.
- Un projet Firebase en plan Blaze, avec Firestore, Authentication (anonyme activée) et Cloud Messaging.
- Firebase CLI (`npm i -g firebase-tools`) et FlutterFire CLI (`dart pub global activate flutterfire_cli`).
- Un compte Apple Developer (push notifications).

## Mise en route

1. `flutter pub get`
2. `flutterfire configure --platforms=ios` (remplace `lib/firebase_options.dart` et dépose `ios/Runner/GoogleService-Info.plist`).
3. Dans Xcode, cible Runner → Signing & Capabilities : *Push Notifications* et *Background Modes → Remote notifications*.
4. Dans la console Firebase → Cloud Messaging : déposer la clé APNs (.p8).
5. `dart run build_runner build -d`
6. `flutter run`

## Backend (Cloud Functions, règles, index)

Voir `docs/superpowers/plans/2026-09-21-colette-v1-functions.md`. En résumé :

```bash
firebase use <project-id>
firebase deploy --only firestore:rules,firestore:indexes
cd functions && npm install && npm test && cd ..
firebase deploy --only functions
```

## Qualité

```bash
dart format lib test
dart analyze
flutter test
```

## Documentation

- Spec : `docs/superpowers/specs/2026-09-21-colette-v1-design.md`
- Règles projet : `CLAUDE.md`
```

- [ ] **Step 2: Vérification complète**

Run: `dart format lib test && dart analyze && flutter test`
Expected: `No issues found!` (les règles `riverpod_lint` tournent dans `dart analyze` via le plugin natif ; `flutter analyze` ne les exécute pas), `All tests passed!`. Corriger tout lint Riverpod signalé avant de continuer (les plus courants : `ref.read` dans un `build`, provider non généré).

- [ ] **Step 3: Vérifier le build iOS (sans lancer)**

Run: `flutter build ios --simulator --no-codesign`
Expected: `Built build/ios/iphonesimulator/Runner.app`. Si Firebase refuse les options placeholder au lancement, c'est attendu tant que `flutterfire configure` n'a pas été exécuté ; la compilation, elle, doit passer.

- [ ] **Step 4: Commit**

```bash
git add README.md
git commit -m "docs: README de mise en route"
```

---

## Auto-revue du plan

**Couverture de la spec :**
- §2 stack → T1 ; §3 architecture → T1–T16 ; §4 design system → T3, T4, T5 ; §5 données → T7, T8, T10 (+ `hasBottle`) ; §5.1 règles et §5.2 hors ligne → plan functions + `OfflineBanner` T5 ; §6.1 onboarding → T9 ; §6.2 dashboard → T13, T14 ; §6.3 plan biberons et écriture `feedingPlan` → T13, T14 (sync appelé par T11 modifié, T15) ; §6.4 journal → T12 ; §6.5 formulaire → T11 ; §6.6 réglages → T15, T16 ; §7 notifications client → T16 (fonctions : plan compagnon) ; §8 erreurs → T2, `failureMessage` T5 ; §9 tests → chaque tâche ; §10 CLAUDE.md → T1 ; §11 prérequis → README T17.
- Non couvert volontairement : bouton « Réessayer » sur échec d'écriture (la snackbar affiche le message ; l'utilisateur ré-appuie sur Enregistrer). Mode thème utilisateur : hors v1.

**Cohérence des noms entre tâches :** `currentHouseholdCodeProvider`, `deviceIdProvider`, `deviceRepositoryProvider` (T7) ; `babyRepositoryProvider`, `babyProfileProvider`, `weightsProvider`, `latestWeightProvider` (T8) ; `eventsRepositoryProvider`, `todayEventsProvider`, `latestBathProvider`, `latestBottleProvider`, `timelineLimitProvider`, `timelineEventsProvider` (T10) ; `eventFormControllerProvider` (T11) ; `feedingPlanSyncProvider` + `NoopFeedingPlanSync` (T14) ; `currentMinuteProvider`, `todayProvider`, `minuteTickerProvider` (T14) ; `pushTokenSourceProvider`, `pushRegistrationProvider`, `notificationSettingsControllerProvider` (T16) ; `bottleFormRequestProvider` (T14, consommé par la gate T16). `IntStepperRow(label, value, min, max, step, suffix, onChanged)` identique en T5, T11, T15, T16. `showColetteDateTimePicker(context, initial:, mode:, maximum:)` identique en T5, T9, T11, T15.
