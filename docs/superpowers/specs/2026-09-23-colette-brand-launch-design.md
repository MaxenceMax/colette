# Colette — logo, icône et écran de lancement

Date : 2026-09-23. Branche : `feat/brand-identity`.

## Objectif

Remplacer l'icône et l'écran de lancement Flutter par défaut par une identité « Cocon cannelle » : un bébé emmailloté, un lancement natif sans écran blanc, puis une courte intro animée au démarrage à froid.

## Logo

Piste retenue : **bébé emmailloté**, forme simplifiée pour rester lisible à 40 pt.

- Corps (lange) : cannelle `primary.light` `#A8573F`.
- Visage : lin `pageBackground.light` `#FBF5EF`.
- Bonnet : rose poudré `secondary.light` `#E9B9A8`.
- Bande du lange : miel `accent.light` `#D9A441`.
- Yeux fermés : deux petits arcs `onSecondary.light` `#5C2A1B` (pas de points).
- Pas d'autre détail (pas de bouche, pas de mains).

Wordmark « Colette » en Fraunces (graisse 600), converti en tracés dans le SVG pour ne dépendre d'aucune police au rendu. Couleur : `onSurface` clair `#2E2320` sur fond clair, `onSurface` sombre `#F1E6E0` sur fond sombre.

## Sources et export

- `assets/brand/logo.svg` : le bébé seul, fond transparent.
- `assets/brand/icon.svg`, `icon-dark.svg`, `icon-tinted.svg` : icône 1024 × 1024 carrée (iOS applique le masque), fond poudre `#F3E2DA`, cacao `#1C1514` pour la variante sombre ; la variante teintée est le logo en niveaux de gris sur fond transparent (iOS applique la teinte).
- `assets/brand/splash.svg`, `splash-dark.svg` : logo + wordmark, fond transparent.
- `tool/export_brand.sh` : exporte tous les PNG avec `rsvg-convert` (`brew install librsvg`), idempotent. Les PNG générés sont versionnés ; le script échoue avec un message clair si `rsvg-convert` est absent.

PNG produits :

- `ios/Runner/Assets.xcassets/AppIcon.appiconset/` : une seule entrée universelle 1024 px, plus les variantes `dark` et `tinted` (iOS 18 ; ignorées par iOS 15–17). Les anciennes tailles multiples sont supprimées du catalogue.
- `assets/brand/splash.png`, `splash-dark.png` (@1x, 2.0x, 3.0x) : utilisés à la fois par le launch screen natif et par l'intro Flutter.

## Launch screen natif

Généré par `flutter_native_splash` (dépendance de dev), configuré dans `pubspec.yaml` :

- `color` `#FBF5EF`, `color_dark` `#1C1514` (valeurs de `AppColors.pageBackground`).
- `image` `assets/brand/splash.png`, `image_dark` `assets/brand/splash-dark.png`, centrés.
- `android: false`, `web: false` (iOS uniquement).
- Ni `preserve` ni `remove` : le natif disparaît au premier frame Flutter, comme aujourd'hui.

Le storyboard par défaut et `LaunchImage.imageset` sont remplacés par la sortie du générateur.

## Intro Flutter

Widget `SplashIntro` dans `lib/app/splash_intro.dart`, posé en overlay au-dessus du routeur via `MaterialApp.router(builder: …)` dans `ColetteApp`. Il n'existe qu'une fois par processus : l'intro se joue au démarrage à froid seulement, jamais au retour du fond.

Premier frame identique à l'écran natif : fond `context.appColor(AppColors.pageBackground)`, même image (`splash.png` ou `splash-dark.png` selon la luminosité), même taille logique, centrée. Taille logique de l'image : celle du PNG @1x, fixée par l'asset lui-même (pas de `width`/`height` en dur).

Séquence (≈ 1,1 s), un seul `AnimationController` et des `Interval` :

1. 0–600 ms : « respiration » du visuel, échelle 1,0 → 1,06 → 1,0 (`Curves.easeInOut`).
2. 400–700 ms : léger glissement vers le haut du visuel (translation de `AppSpacing.sm`).
3. 700–1100 ms : fondu de l'overlay entier jusqu'à 0, qui révèle l'app déjà construite en dessous.
4. Fin : l'overlay est retiré de l'arbre (`IgnorePointer` pendant le fondu, puis `SizedBox.shrink`).

Animations réduites (`MediaQuery.disableAnimations`) : pas de respiration ni de glissement, fondu seul en `AppDuration.normal`.

Tokens : ajouter `AppDuration.splash` (1100 ms) dans `design_tokens.dart`. Le contrôleur d'animation est un détail de widget (`SingleTickerProviderStateMixin`), pas de la logique métier, ce qui reste conforme à la règle Riverpod.

Accessibilité : l'image porte un `Semantics(label: S.of(context).appTitle)` ; aucune string en dur.

## Tests

`test/app/splash_intro_test.dart` (via `pumpApp`) :

- l'overlay est visible au premier frame et masque l'enfant ;
- après `AppDuration.splash`, l'overlay a disparu et l'enfant reçoit les taps ;
- avec `disableAnimations: true`, l'overlay disparaît après `AppDuration.normal`.

Vérification manuelle sur simulateur iPhone : icône (clair, sombre, teintée si iOS 18), lancement à froid en clair puis en sombre, sans saut visible entre natif et Flutter.

## Hors périmètre

- Icône alternative choisie par l'utilisateur, animation Lottie/Rive, écran de lancement Android.
