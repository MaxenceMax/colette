import 'package:colette/core/clock/app_clock.dart';
import 'package:colette/features/household/presentation/providers/household_providers.dart';
import 'package:colette/features/photo_sharing/presentation/providers/photo_sharing_providers.dart';
import 'package:colette/features/photo_sharing/presentation/widgets/photo_reminder_switch.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../helpers/fake_photo_sharing_system.dart';
import '../../../helpers/in_memory_household_local_store.dart';
import '../../../helpers/in_memory_photo_sharing_repository.dart';
import '../../../helpers/pump_app.dart';

void main() {
  late InMemoryPhotoSharingRepository repo;
  late FakePhotoSharingSystem system;

  Future<void> pumpSwitch(WidgetTester tester) => pumpApp(
    tester,
    const Scaffold(body: PhotoReminderSwitch()),
    overrides: [
      photoSharingRepositoryProvider.overrideWithValue(repo),
      photoSharingSystemProvider.overrideWithValue(system),
      clockProvider.overrideWithValue(FixedClock(DateTime(2026, 9, 30, 7))),
      householdLocalStoreProvider.overrideWithValue(
        InMemoryHouseholdLocalStore(),
      ),
    ],
  );

  setUp(() {
    repo = InMemoryPhotoSharingRepository();
    system = FakePhotoSharingSystem();
  });

  testWidgets('activé par défaut, désactivation enregistrée', (tester) async {
    await pumpSwitch(tester);
    expect(find.text('Rappel photo quotidien'), findsOneWidget);
    expect(tester.widget<Switch>(find.byType(Switch)).value, isTrue);
    await tester.tap(find.byType(Switch));
    await tester.pumpAndSettle();
    expect(repo.reminderEnabled, isFalse);
    expect(tester.widget<Switch>(find.byType(Switch)).value, isFalse);
    expect(system.syncedDates.single, isEmpty);
  });

  testWidgets("échec d'écriture : reste activé, message", (tester) async {
    repo.failSaves = true;
    await pumpSwitch(tester);
    await tester.tap(find.byType(Switch));
    await tester.pumpAndSettle();
    expect(tester.widget<Switch>(find.byType(Switch)).value, isTrue);
    expect(find.byType(SnackBar), findsOneWidget);
  });
}
