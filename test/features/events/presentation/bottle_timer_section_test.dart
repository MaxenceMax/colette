import 'dart:async';

import 'package:colette/core/clock/app_clock.dart';
import 'package:colette/features/events/presentation/providers/bottle_timer_controller.dart';
import 'package:colette/features/events/presentation/widgets/bottle_timer_section.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../helpers/pump_app.dart';

void main() {
  final start = DateTime(2026, 9, 25, 14);
  late StreamController<DateTime> ticks;

  setUp(() => ticks = StreamController<DateTime>.broadcast());
  tearDown(() => ticks.close());

  Future<void> pumpSection(WidgetTester tester) => pumpApp(
    tester,
    const Scaffold(body: BottleTimerSection()),
    overrides: [
      clockProvider.overrideWithValue(FixedClock(start)),
      bottleTimerTickProvider.overrideWith((ref) => ticks.stream),
    ],
  );

  Future<void> tick(WidgetTester tester, Duration elapsed) async {
    ticks.add(start.add(elapsed));
    await tester.pump();
    await tester.pump();
  }

  testWidgets('au repos, propose de lancer le minuteur', (tester) async {
    await pumpSection(tester);
    expect(find.text('Lancer le minuteur (30 + 12 min)'), findsOneWidget);
  });

  testWidgets('enchaîne biberon, verticale puis fin', (tester) async {
    await pumpSection(tester);
    await tester.tap(find.text('Lancer le minuteur (30 + 12 min)'));
    await tester.pump();
    expect(find.text('Biberon'), findsOneWidget);
    expect(find.text('30:00'), findsOneWidget);

    await tick(tester, const Duration(minutes: 10, seconds: 5));
    expect(find.text('19:55'), findsOneWidget);

    await tick(tester, const Duration(minutes: 30));
    expect(find.text('À la verticale'), findsOneWidget);
    expect(find.text('12:00'), findsOneWidget);

    await tick(tester, const Duration(minutes: 42));
    expect(find.text('Minuteur terminé'), findsOneWidget);
    expect(find.text('Relancer'), findsOneWidget);
  });

  testWidgets('Arrêter revient au repos', (tester) async {
    await pumpSection(tester);
    await tester.tap(find.text('Lancer le minuteur (30 + 12 min)'));
    await tester.pump();
    await tester.tap(find.text('Arrêter'));
    await tester.pump();
    expect(find.text('Lancer le minuteur (30 + 12 min)'), findsOneWidget);
  });

  testWidgets('Biberon terminé passe directement à la verticale', (
    tester,
  ) async {
    await pumpSection(tester);
    await tester.tap(find.text('Lancer le minuteur (30 + 12 min)'));
    await tester.pump();
    await tester.tap(find.text('Biberon terminé'));
    await tester.pump();
    expect(find.text('À la verticale'), findsOneWidget);
    expect(find.text('12:00'), findsOneWidget);
    expect(find.text('Biberon terminé'), findsNothing);
  });
}
