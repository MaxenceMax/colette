import 'package:colette/core/clock/app_clock.dart';
import 'package:colette/core/clock/now_providers.dart';
import 'package:colette/features/dashboard/domain/entities/projected_bottle.dart';
import 'package:colette/features/dashboard/presentation/providers/dashboard_providers.dart';
import 'package:colette/features/dashboard/presentation/widgets/bottle_schedule_sheet.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../helpers/pump_app.dart';

void main() {
  final now = DateTime(2026, 9, 10, 22);

  ProjectedBottle bottle(DateTime at, int ml) =>
      ProjectedBottle(at: at, suggestedMl: ml);

  Future<void> pumpSheet(WidgetTester tester, List<ProjectedBottle> bottles) =>
      pumpApp(
        tester,
        const Scaffold(body: BottleScheduleSheet()),
        overrides: [
          clockProvider.overrideWithValue(FixedClock(now)),
          minuteTickerProvider.overrideWith((ref) => const Stream.empty()),
          bottleScheduleProvider.overrideWithValue(bottles),
        ],
      );

  testWidgets('groupe par jour avec heure et quantité', (tester) async {
    await pumpSheet(tester, [
      bottle(DateTime(2026, 9, 10, 23), 70),
      bottle(DateTime(2026, 9, 11, 2), 80),
    ]);
    expect(find.text('Prochaines 24 h'), findsOneWidget);
    expect(find.text('Aujourd\'hui'), findsOneWidget);
    expect(find.text('Demain'), findsOneWidget);
    expect(find.text('23h00'), findsOneWidget);
    expect(find.text('70 ml'), findsOneWidget);
    expect(find.text('02h00'), findsOneWidget);
    expect(find.text('80 ml'), findsOneWidget);
  });

  testWidgets('le prochain biberon en retard porte la mention', (tester) async {
    await pumpSheet(tester, [
      bottle(DateTime(2026, 9, 10, 21, 25), 70),
      bottle(DateTime(2026, 9, 11, 1), 80),
    ]);
    expect(find.text('en retard de 35 min'), findsOneWidget);
    expect(find.text('Aujourd\'hui'), findsOneWidget);
  });

  testWidgets('un retard de plus d\'une heure s\'affiche en heures', (
    tester,
  ) async {
    await pumpSheet(tester, [bottle(DateTime(2026, 9, 10, 20, 25), 70)]);
    // Prévu à 20 h 25 : 1 h 35 de retard à 22 h.
    expect(find.text('en retard de 1 h 35'), findsOneWidget);
  });

  testWidgets('le prochain biberon à l\'heure pile porte « maintenant »', (
    tester,
  ) async {
    await pumpSheet(tester, [bottle(DateTime(2026, 9, 10, 22), 70)]);
    expect(find.text('maintenant'), findsOneWidget);
  });

  testWidgets('un biberon à venir ne porte aucune mention', (tester) async {
    await pumpSheet(tester, [bottle(DateTime(2026, 9, 10, 22, 10), 70)]);
    expect(find.text('maintenant'), findsNothing);
    expect(find.textContaining('en retard'), findsNothing);
  });

  testWidgets(
    'moins d\'une minute après l\'heure prévue : « maintenant », pas de retard',
    (tester) async {
      await pumpSheet(tester, [bottle(DateTime(2026, 9, 10, 21, 59, 30), 70)]);
      expect(find.text('maintenant'), findsOneWidget);
      expect(find.textContaining('en retard'), findsNothing);
    },
  );
}
