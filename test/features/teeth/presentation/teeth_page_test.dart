import 'package:colette/core/clock/app_clock.dart';
import 'package:colette/core/result/failure.dart';
import 'package:colette/features/baby/domain/entities/baby_profile.dart';
import 'package:colette/features/baby/presentation/providers/baby_providers.dart';
import 'package:colette/features/household/presentation/providers/household_providers.dart';
import 'package:colette/features/teeth/domain/entities/tooth_id.dart';
import 'package:colette/features/teeth/domain/entities/tooth_record.dart';
import 'package:colette/features/teeth/presentation/pages/teeth_page.dart';
import 'package:colette/features/teeth/presentation/providers/teeth_providers.dart';
import 'package:colette/features/teeth/presentation/widgets/teeth_chart.dart';
import 'package:colette/features/teeth/presentation/widgets/teeth_layout.dart';
import 'package:colette/l10n/generated/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../helpers/in_memory_household_local_store.dart';
import '../../../helpers/pump_app.dart';
import '../teeth_factories.dart';

void main() {
  final day = DateTime(2027, 1, 10, 12);
  final records = <ToothId, ToothRecord>{
    tooth(71): makeTooth(71, eruptedAt: day),
    tooth(81): makeTooth(81, eruptedAt: day, lostAt: DateTime(2027, 2, 1, 12)),
  };

  Future<void> pumpPage(
    WidgetTester tester, {
    Stream<Map<ToothId, ToothRecord>>? stream,
  }) => pumpApp(
    tester,
    const TeethPage(),
    viewSize: const Size(390, 1200),
    overrides: [
      teethRepositoryProvider.overrideWithValue(MockTeethRepository()),
      teethProvider.overrideWith((ref) => stream ?? Stream.value(records)),
      clockProvider.overrideWithValue(FixedClock(DateTime(2027, 3, 10, 9))),
      householdLocalStoreProvider.overrideWithValue(
        InMemoryHouseholdLocalStore(householdCode: 'ABCDEFGH'),
      ),
      babyProfileProvider.overrideWith(
        (ref) => Stream.value(
          BabyProfile(name: 'C', birthDate: DateTime(2026, 9, 1)),
        ),
      ),
    ],
  );

  Future<void> tapTooth(
    WidgetTester tester,
    Dentition dentition,
    ToothId id,
  ) async {
    final canvas = tester.getRect(find.byKey(TeethChart.canvasKey));
    final layout = TeethLayout(dentition, canvas.size);
    await tester.tapAt(canvas.topLeft + layout.rectOf(id).center);
    await tester.pumpAndSettle();
  }

  testWidgets('dents de lait par défaut, compteur, fiche au toucher', (
    tester,
  ) async {
    await pumpPage(tester);
    expect(find.text('Dents'), findsOneWidget);
    expect(find.text('2 sorties sur 20 · 1 tombée'), findsOneWidget);
    await tapTooth(tester, Dentition.primary, tooth(51));
    expect(find.text('Incisive centrale du haut, à droite'), findsOneWidget);
    expect(find.text('Ajouter la date de sortie'), findsOneWidget);
  });

  testWidgets('bascule sur les dents définitives', (tester) async {
    await pumpPage(tester);
    await tester.tap(find.text('Définitives'));
    await tester.pumpAndSettle();
    expect(find.text('0 sortie sur 32'), findsOneWidget);
    await tapTooth(tester, Dentition.permanent, tooth(36));
    expect(find.text('Première molaire du bas, à gauche'), findsOneWidget);
    expect(find.text('Ajouter la date de chute'), findsNothing);
  });

  testWidgets('erreur de lecture affichée', (tester) async {
    await pumpPage(tester, stream: Stream.error(const NetworkFailure()));
    expect(
      find.text(S.of(tester.element(find.byType(TeethPage))).errorNetwork),
      findsOneWidget,
    );
  });
}
