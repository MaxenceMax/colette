import 'dart:ui' show Tristate;

import 'package:colette/features/teeth/domain/entities/tooth_id.dart';
import 'package:colette/features/teeth/domain/entities/tooth_record.dart';
import 'package:colette/features/teeth/presentation/widgets/teeth_chart.dart';
import 'package:colette/features/teeth/presentation/widgets/teeth_chart_painter.dart';
import 'package:colette/features/teeth/presentation/widgets/teeth_layout.dart';
import 'package:colette/features/teeth/presentation/widgets/teeth_legend.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../helpers/pump_app.dart';
import '../teeth_factories.dart';

void main() {
  final records = <ToothId, ToothRecord>{
    tooth(71): makeTooth(71, eruptedAt: DateTime(2027, 1, 10, 12)),
  };

  Future<List<ToothId>> pumpChart(
    WidgetTester tester,
    Dentition dentition, {
    ToothId? selected,
  }) async {
    final tapped = <ToothId>[];
    await pumpApp(
      tester,
      Scaffold(
        body: ListView(
          children: [
            TeethChart(
              dentition: dentition,
              records: records,
              selected: selected,
              onToothTap: tapped.add,
            ),
            const TeethLegend(),
          ],
        ),
      ),
      viewSize: const Size(390, 900),
    );
    return tapped;
  }

  Future<void> tapTooth(
    WidgetTester tester,
    Dentition dentition,
    ToothId id,
  ) async {
    final canvas = tester.getRect(find.byKey(TeethChart.canvasKey));
    final layout = TeethLayout(dentition, canvas.size);
    await tester.tapAt(canvas.topLeft + layout.rectOf(id).center);
    await tester.pump();
  }

  testWidgets('toucher une dent la signale', (tester) async {
    final tapped = await pumpChart(tester, Dentition.primary);
    await tapTooth(tester, Dentition.primary, tooth(51));
    await tapTooth(tester, Dentition.primary, tooth(85));
    expect(tapped, [tooth(51), tooth(85)]);
  });

  testWidgets('toucher le centre du schéma ne fait rien', (tester) async {
    final tapped = await pumpChart(tester, Dentition.permanent);
    await tester.tap(find.byKey(TeethChart.canvasKey));
    expect(tapped, isEmpty);
  });

  testWidgets('libellés, légende et VoiceOver', (tester) async {
    final handle = tester.ensureSemantics();
    final tapped = await pumpChart(tester, Dentition.primary);
    for (final text in [
      'Haut',
      'Bas',
      'Droite',
      'Gauche',
      'Sortie',
      'Tombée',
      'Pas encore',
    ]) {
      expect(find.text(text), findsOneWidget, reason: text);
    }
    expect(
      find.semantics.byLabel(
        'Incisive centrale du bas, à gauche, sortie le 10 janv. 2027',
      ),
      findsOne,
    );
    final upperRight = find.semantics.byLabel(
      'Incisive centrale du haut, à droite, pas encore sortie',
    );
    expect(upperRight, findsOne);
    tester.semantics.tap(upperRight);
    expect(tapped, [tooth(51)]);
    handle.dispose();
  });

  testWidgets('la dent sélectionnée est annoncée comme sélectionnée', (
    tester,
  ) async {
    final handle = tester.ensureSemantics();
    await pumpChart(tester, Dentition.primary, selected: tooth(71));
    const selectedLabel =
        'Incisive centrale du bas, à gauche, sortie le 10 janv. 2027';
    const otherLabel = 'Incisive centrale du haut, à droite, pas encore sortie';
    expect(
      find.semantics
          .byLabel(selectedLabel)
          .evaluate()
          .single
          .flagsCollection
          .isSelected,
      Tristate.isTrue,
    );
    expect(
      find.semantics
          .byLabel(otherLabel)
          .evaluate()
          .single
          .flagsCollection
          .isSelected,
      Tristate.isFalse,
    );
    handle.dispose();
  });

  group('TeethChartPainter.shouldRebuildSemantics', () {
    final layout = TeethLayout(Dentition.primary, const Size(300, 330));
    const colors = (
      erupted: Colors.red,
      lostFill: Colors.green,
      lostStroke: Colors.blue,
      mark: Colors.black,
      absent: Colors.grey,
      selected: Colors.white,
    );
    TeethChartPainter painterWith(Map<ToothId, ToothRecord> records) =>
        TeethChartPainter(
          layout: layout,
          records: records,
          selected: null,
          colors: colors,
          labelOf: (_) => '',
          onToothTap: (_) {},
        );

    test('vrai quand la date de sortie change', () {
      final before = painterWith({
        tooth(71): makeTooth(71, eruptedAt: DateTime(2027, 1, 10)),
      });
      final after = painterWith({
        tooth(71): makeTooth(71, eruptedAt: DateTime(2027, 1, 11)),
      });
      expect(after.shouldRebuildSemantics(before), isTrue);
    });

    test('faux quand les dents sont identiques', () {
      final before = painterWith({
        tooth(71): makeTooth(71, eruptedAt: DateTime(2027, 1, 10)),
      });
      final after = painterWith({
        tooth(71): makeTooth(71, eruptedAt: DateTime(2027, 1, 10)),
      });
      expect(after.shouldRebuildSemantics(before), isFalse);
    });
  });
}
