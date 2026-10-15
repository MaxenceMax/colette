import 'package:colette/core/clock/app_clock.dart';
import 'package:colette/core/theme/app_colors.dart';
import 'package:colette/core/theme/theme_service.dart';
import 'package:colette/features/teeth/presentation/pages/teeth_page.dart';
import 'package:colette/features/teeth/presentation/providers/teeth_providers.dart';
import 'package:colette/features/teeth/presentation/widgets/teeth_card.dart';
import 'package:colette/features/teeth/presentation/widgets/teeth_chart.dart';
import 'package:colette/features/teeth/presentation/widgets/teeth_chart_painter.dart';
import 'package:colette/l10n/generated/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import '../teeth_factories.dart';

void main() {
  Future<void> pumpThemed(
    WidgetTester tester,
    Widget child,
    ThemeMode mode,
  ) async {
    tester.view.physicalSize = const Size(390, 1200);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    const themeService = ThemeService();
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          teethProvider.overrideWith(
            (ref) => Stream.value({
              tooth(71): makeTooth(71, eruptedAt: DateTime(2027, 1, 10, 12)),
              tooth(81): makeTooth(
                81,
                eruptedAt: DateTime(2027, 1, 10, 12),
                lostAt: DateTime(2027, 2, 1, 12),
              ),
            }),
          ),
          clockProvider.overrideWithValue(FixedClock(DateTime(2027, 3, 10, 9))),
        ],
        child: MaterialApp(
          theme: themeService.light(),
          darkTheme: themeService.dark(),
          themeMode: mode,
          locale: const Locale('fr'),
          localizationsDelegates: S.localizationsDelegates,
          supportedLocales: S.supportedLocales,
          home: child,
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  TeethChartPainter painter(WidgetTester tester) =>
      tester.widget<CustomPaint>(find.byKey(TeethChart.canvasKey)).painter!
          as TeethChartPainter;

  testWidgets('page Dents : aucune exception, couleurs au thème', (
    tester,
  ) async {
    await pumpThemed(tester, const TeethPage(), ThemeMode.light);
    expect(tester.takeException(), isNull);
    expect(painter(tester).colors.erupted, AppColors.primary.light);

    await pumpThemed(tester, const TeethPage(), ThemeMode.dark);
    expect(tester.takeException(), isNull);
    expect(painter(tester).colors.erupted, AppColors.primary.dark);
  });

  testWidgets('carte Dents : aucune exception en clair et en sombre', (
    tester,
  ) async {
    for (final mode in [ThemeMode.light, ThemeMode.dark]) {
      await pumpThemed(tester, const Scaffold(body: TeethCard()), mode);
      expect(tester.takeException(), isNull);
    }
  });
}
