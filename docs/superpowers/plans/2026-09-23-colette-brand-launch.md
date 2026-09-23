# Logo, icône et écran de lancement — plan d'implémentation

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Donner à Colette une icône « bébé emmailloté », un launch screen natif clair/sombre et une intro Flutter animée au démarrage à froid.

**Architecture:** Des SVG maîtres dans `assets/brand/` sont rendus par un script Swift/AppKit (`tool/brand/export.swift`) vers tous les PNG (icône, launch screen natif, asset Flutter). Le storyboard natif est édité à la main (couleur nommée + imageset clair/sombre). `SplashIntro` (`lib/app/splash_intro.dart`) retarde le premier frame jusqu'au décodage de l'image, affiche un écran identique au natif, puis anime et s'efface au-dessus du routeur.

**Tech Stack:** Swift (AppKit, CoreText) en script, Flutter 3 / Riverpod 3, xcassets iOS.

Spec : `docs/superpowers/specs/2026-09-23-colette-brand-launch-design.md`.

---

## Fichiers

- Create `assets/brand/logo.svg`, `assets/brand/logo-tinted.svg` : maîtres du logo (canevas 1024).
- Create `tool/brand/wordmark.swift` : génère `assets/brand/wordmark.svg` depuis un TTF Fraunces 600.
- Create `tool/brand/export.swift` : compose et écrit tous les PNG.
- Generated `assets/brand/splash.png`, `splash_dark.png` (+ `2.0x/`, `3.0x/`), `ios/Runner/Assets.xcassets/AppIcon.appiconset/*`, `ios/Runner/Assets.xcassets/LaunchImage.imageset/*`.
- Create `ios/Runner/Assets.xcassets/LaunchBackground.colorset/Contents.json`.
- Modify `ios/Runner/Base.lproj/LaunchScreen.storyboard`, `pubspec.yaml` (assets), `lib/core/theme/design_tokens.dart` (`AppDuration.splash`), `lib/app/colette_app.dart` (builder).
- Create `lib/app/splash_intro.dart`, `test/app/splash_intro_test.dart`.

---

### Task 1 : maîtres SVG du logo et wordmark

- [ ] **Step 1 : écrire `assets/brand/logo.svg`** (canevas 1024, contenu centré dans ~70 % pour le masque d'icône)

```svg
<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 1024 1024" width="1024" height="1024">
  <defs>
    <clipPath id="body"><path d="M512 330 C724 330 776 530 756 690 C736 836 622 884 512 884 C402 884 288 836 268 690 C248 530 300 330 512 330 Z"/></clipPath>
  </defs>
  <path d="M512 330 C724 330 776 530 756 690 C736 836 622 884 512 884 C402 884 288 836 268 690 C248 530 300 330 512 330 Z" fill="#A8573F"/>
  <path d="M250 640 C380 572 644 572 774 640 L774 700 C644 632 380 632 250 700 Z" fill="#D9A441" clip-path="url(#body)"/>
  <circle cx="512" cy="392" r="150" fill="#FBF5EF"/>
  <path d="M363 408 C356 272 432 222 512 222 C592 222 668 272 661 408 C606 356 418 356 363 408 Z" fill="#E9B9A8"/>
  <circle cx="512" cy="204" r="30" fill="#E9B9A8"/>
  <path d="M438 446 Q465 472 492 446 M532 446 Q559 472 586 446" stroke="#5C2A1B" stroke-width="15" stroke-linecap="round" fill="none"/>
</svg>
```

- [ ] **Step 2 : écrire `assets/brand/logo-tinted.svg`** : même fichier, couleurs en niveaux de gris (corps `#8C8C8C`, bande `#C8C8C8`, visage `#FFFFFF`, bonnet `#D9D9D9`, yeux `#3A3A3A`).

- [ ] **Step 3 : écrire `tool/brand/wordmark.swift`** : charge le TTF passé en argument, construit le `CGPath` des glyphes de « Colette » via CoreText, retourne l'axe Y, écrit un SVG `fill="#2E2320"` recadré sur la boîte englobante sur la sortie standard.

- [ ] **Step 4 : générer le wordmark**

Run: `swift tool/brand/wordmark.swift "<chemin du TTF Fraunces_600 en cache>" > assets/brand/wordmark.svg`
Expected: un SVG avec un seul `<path>` et un `viewBox` d'environ 3,5:1.

- [ ] **Step 5 : commit** `feat: maîtres SVG du logo et du wordmark`

### Task 2 : script d'export et PNG

- [ ] **Step 1 : écrire `tool/brand/export.swift`**. Fonctions : `loadSVG(name, recolor:)` (`NSImage(data:)` après remplacement de couleurs), `write(width:height:scale:opaque:path:draw:)` (`CGContext` RGB, `noneSkipLast` si opaque pour une icône sans canal alpha, sinon `premultipliedLast`, puis `CGImageDestination` PNG). Sorties :
  - `AppIcon.appiconset/icon.png` (fond `#F3E2DA`, opaque), `icon-dark.png` (fond `#1C1514`, opaque), `icon-tinted.png` (logo-tinted, transparent) + `Contents.json` universel 1024 avec `appearances` `dark` et `tinted`.
  - visuel de lancement 200 × 240 pt : logo dessiné dans `(-20, 26, 240, 240)` pt, wordmark centré en bas sur 150 pt de large ; version sombre = wordmark recoloré `#2E2320 → #F1E6E0`.
  - `LaunchImage.imageset/LaunchImage{,@2x,@3x}.png` et `LaunchImageDark{,@2x,@3x}.png` + `Contents.json` avec `appearances` luminosity dark.
  - `assets/brand/splash.png`, `2.0x/splash.png`, `3.0x/splash.png`, et idem `splash_dark.png`.
- [ ] **Step 2 : supprimer les anciens PNG** de `AppIcon.appiconset` (`Icon-App-*.png`) et de `LaunchImage.imageset`.
- [ ] **Step 3 : lancer** `swift tool/brand/export.swift` et vérifier visuellement `icon.png`, `icon-dark.png`, `splash.png` (3.0x), `splash_dark.png` (3.0x).
- [ ] **Step 4 : commit** `feat: icône de l'app et visuels de lancement générés`

### Task 3 : launch screen natif

- [ ] **Step 1 : créer `LaunchBackground.colorset/Contents.json`** : sRGB `#FBF5EF`, variante `appearances` luminosity dark `#1C1514`.
- [ ] **Step 2 : modifier `LaunchScreen.storyboard`** : `<color key="backgroundColor" name="LaunchBackground"/>`, ressource `<image name="LaunchImage" width="200" height="240"/>` et `<namedColor name="LaunchBackground">` ; `imageView` `contentMode="center"` inchangé, centré.
- [ ] **Step 3 : `flutter build ios --simulator --debug`**, Expected: build OK.
- [ ] **Step 4 : commit** `feat: écran de lancement natif clair et sombre`

### Task 4 : `SplashIntro`

- [ ] **Step 1 : ajouter `AppDuration.splash(Duration(milliseconds: 1100))`** dans `design_tokens.dart`, et `assets/brand/` sous `flutter: assets:` dans `pubspec.yaml`.
- [ ] **Step 2 : test rouge `test/app/splash_intro_test.dart`**

```dart
Widget _wrap(Widget child, {bool reduceMotion = false}) => MaterialApp(
  theme: const ThemeService().light(),
  locale: const Locale('fr'),
  localizationsDelegates: S.localizationsDelegates,
  supportedLocales: S.supportedLocales,
  builder: (context, _) => MediaQuery(
    data: MediaQuery.of(context).copyWith(disableAnimations: reduceMotion),
    child: child,
  ),
);

Future<void> _pumpUntilStarted(WidgetTester tester) async {
  // Le décodage de l'image est réellement asynchrone.
  await tester.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 200)));
  await tester.pump();
}
```

Tests :
  1. premier frame : `find.byKey(SplashIntro.overlayKey)` trouvé, `find.bySemanticsLabel('Colette')` trouvé, un tap sur le bouton enfant n'incrémente pas le compteur ;
  2. après `_pumpUntilStarted` puis `pump(AppDuration.splash.value)` : overlay absent, tap sur l'enfant incrémente le compteur ;
  3. `reduceMotion: true` : après `_pumpUntilStarted` puis `pump(AppDuration.normal.value)`, overlay absent.

Run: `flutter test test/app/splash_intro_test.dart` — Expected: FAIL (fichier inexistant).

- [ ] **Step 3 : implémenter `lib/app/splash_intro.dart`**
  - `initState` : `WidgetsBinding.instance.deferFirstFrame()`.
  - `didChangeDependencies` (une seule fois) : choisit l'image selon `Theme.of(context).brightness`, durée selon `MediaQuery.disableAnimationsOf`, `precacheImage(...).whenComplete(...)` → `allowFirstFrame()` puis `_controller.forward()` ; fin d'animation → `setState(() => _done = true)`.
  - `build` : `Stack(children: [widget.child, if (!_done) AnimatedBuilder(...)])`. Overlay : `AbsorbPointer` tant que le fondu n'a pas commencé, `Opacity`, `ColoredBox(context.appColor(AppColors.pageBackground))`, `Center` → `Transform.translate` (0 → `-AppSpacing.sm.value`, `Interval(400/1100, 700/1100)`) → `Transform.scale` (`TweenSequence` 1 → 1,06 → 1 sur `Interval(0, 600/1100)`) → `Semantics(label: S.of(context).appTitle, image: true)` → `Image.asset(...)`. Animations réduites : échelle et translation neutres, fondu sur tout l'intervalle.
  - `dispose` : `_controller.dispose()` ; si le premier frame est encore différé, `allowFirstFrame()`.
- [ ] **Step 4 : tests verts**, puis brancher dans `ColetteApp.builder` : `SplashIntro(child: NotificationsGate(child: child ?? const SizedBox.shrink()))`.
- [ ] **Step 5 : `dart format lib test`, `dart analyze`, `flutter test`**, puis commit `feat: intro animée au démarrage à froid`.

### Task 5 : vérification simulateur

- [ ] Build et lancement sur simulateur iPhone ; captures : écran d'accueil (icône), lancement à froid clair, lancement à froid sombre, arrivée sur l'app.
- [ ] Ajuster les proportions si besoin (relancer l'export, recommit `fix:`).
