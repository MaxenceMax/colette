import 'package:colette/features/baby/domain/entities/care_frequency.dart';
import 'package:colette/features/baby/presentation/widgets/care_frequency_row.dart';
import 'package:colette/shared/domain/care_type.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../helpers/pump_app.dart';

void main() {
  Future<List<CareFrequency>> pumpRow(
    WidgetTester tester,
    CareFrequency frequency, {
    int maxTimesPerDay = 3,
  }) async {
    final changes = <CareFrequency>[];
    await pumpApp(
      tester,
      Scaffold(
        body: CareFrequencyRow(
          type: CareType.adrigyl,
          frequency: frequency,
          maxTimesPerDay: maxTimesPerDay,
          onChanged: changes.add,
        ),
      ),
    );
    return changes;
  }

  final minus = find.widgetWithIcon(IconButton, Icons.remove);
  final plus = find.widgetWithIcon(IconButton, Icons.add);

  testWidgets('affiche le libellé du soin et « 1 fois par jour »', (
    tester,
  ) async {
    await pumpRow(tester, const CareFrequency());
    expect(find.text('Adrigyl'), findsOneWidget);
    expect(find.text('1 fois par jour'), findsOneWidget);
    expect(find.byType(Switch), findsOneWidget);
  });

  testWidgets('− depuis 1/jour passe à tous les 2 jours', (tester) async {
    final changes = await pumpRow(tester, const CareFrequency());
    await tester.tap(minus);
    await tester.pump();
    expect(changes, [const CareFrequency(everyDays: 2)]);
  });

  testWidgets('+ depuis tous les 2 jours revient à 1/jour', (tester) async {
    final changes = await pumpRow(tester, const CareFrequency(everyDays: 2));
    expect(find.text('tous les 2 jours'), findsOneWidget);
    await tester.tap(plus);
    await tester.pump();
    expect(changes, [const CareFrequency()]);
  });

  testWidgets('3 fois par jour au pluriel, + inactif en butée', (tester) async {
    await pumpRow(tester, const CareFrequency(timesPerDay: 3));
    expect(find.text('3 fois par jour'), findsOneWidget);
    expect(tester.widget<IconButton>(plus).onPressed, isNull);
    expect(tester.widget<IconButton>(minus).onPressed, isNotNull);
  });

  testWidgets('− inactif à tous les 7 jours', (tester) async {
    await pumpRow(tester, const CareFrequency(everyDays: 7));
    expect(tester.widget<IconButton>(minus).onPressed, isNull);
  });

  testWidgets('suivi coupé : fréquence visible, boutons inactifs', (
    tester,
  ) async {
    final changes = await pumpRow(
      tester,
      const CareFrequency(everyDays: 2, enabled: false),
    );
    expect(find.text('tous les 2 jours'), findsOneWidget);
    expect(tester.widget<IconButton>(minus).onPressed, isNull);
    expect(tester.widget<IconButton>(plus).onPressed, isNull);
    expect(tester.widget<Switch>(find.byType(Switch)).value, isFalse);
    await tester.tap(find.byType(Switch));
    await tester.pump();
    expect(changes, [const CareFrequency(everyDays: 2)]);
  });

  testWidgets('le switch coupe le suivi sans toucher à la fréquence', (
    tester,
  ) async {
    final changes = await pumpRow(tester, const CareFrequency(timesPerDay: 2));
    await tester.tap(find.byType(Switch));
    await tester.pump();
    expect(changes, [const CareFrequency(timesPerDay: 2, enabled: false)]);
  });
}
