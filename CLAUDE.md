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
- `ref.watch` dans `build`, `ref.read` dans les callbacks. Jamais `ref.read` dans un `build`.
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
- Avant de déclarer une tâche terminée : `dart format lib test`, puis `flutter analyze` (qui exécute aussi les règles riverpod_lint via le plugin déclaré dans `analysis_options.yaml`) et `flutter test` sans erreur.

## Syntaxe Dart

- Dot shorthand quand le type est inféré : `.center`, `.bold`, `.circular`.
- `switch` expressions, pattern matching, sealed classes, records.
- Fichiers snake_case, classes PascalCase, membres camelCase.

## Commits

- Préfixes : `feat:`, `fix:`, `test:`, `docs:`, `chore:`. Message en français, une ligne de résumé.
