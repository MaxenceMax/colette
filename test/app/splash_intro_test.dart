import 'package:colette/app/splash_intro.dart';
import 'package:colette/core/theme/design_tokens.dart';
import 'package:colette/core/theme/theme_service.dart';
import 'package:colette/l10n/generated/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

// `pumpApp` n'est pas utilisé : son `pumpAndSettle` jouerait toute l'intro
// avant la première assertion.
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

/// Un frame à 60 Hz : le ticker prend son temps zéro au frame qui suit `forward`.
const _frame = Duration(milliseconds: 16);

/// Laisse le décodage réel de l'image aboutir, ce qui démarre l'animation,
/// puis amorce le ticker (son temps zéro est pris au frame suivant).
Future<void> _pumpUntilStarted(WidgetTester tester) async {
  for (var i = 0; i < 20 && !tester.binding.sendFramesToEngine; i++) {
    await tester.runAsync(
      () => Future<void>.delayed(const Duration(milliseconds: 50)),
    );
    await tester.pump();
  }
  expect(tester.binding.sendFramesToEngine, isTrue);
  await tester.pump();
}

void main() {
  late int taps;
  late Widget app;

  setUp(() {
    taps = 0;
    app = SplashIntro(
      child: Center(
        child: TextButton(onPressed: () => taps++, child: const Text('app')),
      ),
    );
  });

  testWidgets('retarde le premier frame puis masque l\'app', (tester) async {
    final semantics = tester.ensureSemantics();
    await tester.pumpWidget(_wrap(app));
    expect(tester.binding.sendFramesToEngine, isFalse);
    await _pumpUntilStarted(tester);

    expect(find.byKey(SplashIntro.overlayKey), findsOneWidget);
    expect(find.bySemanticsLabel('Colette'), findsOneWidget);
    await tester.tap(find.text('app'), warnIfMissed: false);
    expect(taps, 0);
    semantics.dispose();
  });

  testWidgets('se retire après l\'intro et rend la main à l\'app', (
    tester,
  ) async {
    await tester.pumpWidget(_wrap(app));
    await _pumpUntilStarted(tester);
    await tester.pump(AppDuration.splash.value + _frame);

    expect(find.byKey(SplashIntro.overlayKey), findsNothing);
    await tester.tap(find.text('app'));
    expect(taps, 1);
  });

  testWidgets('animations réduites : simple fondu court', (tester) async {
    await tester.pumpWidget(_wrap(app, reduceMotion: true));
    await _pumpUntilStarted(tester);
    await tester.pump(AppDuration.normal.value + _frame);

    expect(find.byKey(SplashIntro.overlayKey), findsNothing);
  });
}
