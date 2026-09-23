# Colette

App iOS privée pour suivre les soins quotidiens de notre nouveau-né, à deux.

## Fonctionnalités

- Documents : consultation du dossier iCloud Drive partagé (choisi une fois par iPhone), aperçu Quick Look, scan et import dans le dossier.
- Croissance : mesures de poids, taille et périmètre crânien, courbes avec repères OMS.

## Prérequis

- Flutter 3.47 (stable), Xcode, CocoaPods.
- Un projet Firebase en plan Blaze, avec Firestore, Authentication (anonyme activée) et Cloud Messaging.
- Firebase CLI (`npm i -g firebase-tools`) et FlutterFire CLI (`dart pub global activate flutterfire_cli`).
- Un compte Apple Developer (push notifications).

La création du projet Firebase et la configuration Apple sont détaillées pas à pas dans `docs/firebase-setup.md`.

## Mise en route

1. `flutter pub get`
2. `flutterfire configure --platforms=ios` (remplace `lib/firebase_options.dart` et dépose `ios/Runner/GoogleService-Info.plist`).
3. Dans Xcode, cible Runner → Signing & Capabilities : *Push Notifications* et *Background Modes → Remote notifications*.
4. Dans la console Firebase → Cloud Messaging : déposer la clé APNs (.p8).
5. `dart run build_runner build -d`
6. `flutter run`

Les sources Swift de `ios/Runner/Documents/` sont référencées dans le projet Xcode par `ruby ios/scripts/add_documents_sources.rb` (gem `xcodeproj`, livré avec CocoaPods).

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

`dart analyze` (et non `flutter analyze`) exécute les règles `riverpod_lint` déclarées dans `analysis_options.yaml`.

## Documentation

- Spec : `docs/superpowers/specs/2026-09-21-colette-v1-design.md`
- Règles projet : `CLAUDE.md`
