import 'dart:async';

import 'package:colette/app/router/app_router.dart';
import 'package:colette/core/result/failure.dart';
import 'package:colette/core/theme/theme_service.dart';
import 'package:colette/features/teeth/domain/entities/tooth_id.dart';
import 'package:colette/features/teeth/domain/entities/tooth_record.dart';
import 'package:colette/features/teeth/presentation/providers/teeth_providers.dart';
import 'package:colette/features/teeth/presentation/widgets/teeth_card.dart';
import 'package:colette/l10n/generated/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

import '../teeth_factories.dart';

void main() {
  Future<void> pumpCard(
    WidgetTester tester,
    Stream<Map<ToothId, ToothRecord>> teeth, {
    bool settle = true,
  }) async {
    final router = GoRouter(
      initialLocation: AppRoutes.health,
      routes: [
        GoRoute(
          path: AppRoutes.health,
          builder: (_, _) => const Scaffold(body: TeethCard()),
          routes: [
            GoRoute(
              path: 'teeth',
              builder: (_, _) => const Scaffold(body: Text('page dents')),
            ),
          ],
        ),
      ],
    );
    addTearDown(router.dispose);
    await tester.pumpWidget(
      ProviderScope(
        overrides: [teethProvider.overrideWith((ref) => teeth)],
        child: MaterialApp.router(
          theme: const ThemeService().light(),
          locale: const Locale('fr'),
          localizationsDelegates: S.localizationsDelegates,
          supportedLocales: S.supportedLocales,
          routerConfig: router,
        ),
      ),
    );
    if (settle) {
      await tester.pumpAndSettle();
    } else {
      await tester.pump();
    }
  }

  testWidgets('sans dent : premières dents attendues', (tester) async {
    await pumpCard(tester, Stream.value(const {}));
    expect(find.text('Dents'), findsOneWidget);
    expect(find.text('Pas encore de dent'), findsOneWidget);
    expect(
      find.text(
        'Ensuite : incisives centrales du bas (6-10 mois), '
        'puis incisives centrales du haut (8-12 mois)',
      ),
      findsOneWidget,
    );
  });

  testWidgets('avec des dents : nombre en bouche', (tester) async {
    final day = DateTime(2027, 1, 10, 12);
    await pumpCard(
      tester,
      Stream.value({
        tooth(71): makeTooth(71, eruptedAt: day),
        tooth(81): makeTooth(81, eruptedAt: day),
      }),
    );
    expect(find.text('2 dents en bouche'), findsOneWidget);
    expect(
      find.text(
        'Ensuite : incisives centrales du haut (8-12 mois), '
        'puis incisives latérales du haut (9-13 mois)',
      ),
      findsOneWidget,
    );
  });

  testWidgets('erreur de lecture affichée', (tester) async {
    await pumpCard(tester, Stream.error(const NetworkFailure()));
    final s = S.of(tester.element(find.byType(TeethCard)));
    expect(find.text(s.errorNetwork), findsOneWidget);
  });

  testWidgets('ouvre la page Dents', (tester) async {
    await pumpCard(tester, Stream.value(const {}));
    await tester.tap(find.text('Dents'));
    await tester.pumpAndSettle();
    expect(find.text('page dents'), findsOneWidget);
  });

  testWidgets('pendant le chargement : titre seul', (tester) async {
    final controller = StreamController<Map<ToothId, ToothRecord>>();
    addTearDown(controller.close);
    await pumpCard(tester, controller.stream, settle: false);
    expect(find.text('Dents'), findsOneWidget);
    expect(find.textContaining('Ensuite'), findsNothing);
    expect(find.text('Pas encore de dent'), findsNothing);
  });
}
