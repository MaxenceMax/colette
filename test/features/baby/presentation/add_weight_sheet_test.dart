import 'package:colette/core/clock/app_clock.dart';
import 'package:colette/features/baby/domain/entities/baby_profile.dart';
import 'package:colette/features/baby/presentation/providers/baby_providers.dart';
import 'package:colette/features/baby/presentation/widgets/add_weight_sheet.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../helpers/pump_app.dart';

void main() {
  testWidgets('la date de pesée va de la naissance à aujourd\'hui', (
    tester,
  ) async {
    await pumpApp(
      tester,
      const Scaffold(body: AddWeightSheet()),
      overrides: [
        clockProvider.overrideWithValue(FixedClock(DateTime(2026, 9, 21, 12))),
        babyProfileProvider.overrideWith(
          (ref) => Stream.value(
            BabyProfile(name: 'Colette', birthDate: DateTime(2026, 9, 1)),
          ),
        ),
      ],
    );
    await tester.tap(find.text('21 septembre 2026'));
    await tester.pumpAndSettle();
    final picker = tester.widget<CupertinoDatePicker>(
      find.byType(CupertinoDatePicker),
    );
    expect(picker.minimumDate, DateTime(2026, 9, 1));
    expect(picker.maximumDate, DateTime(2026, 9, 21, 12));
  });
}
