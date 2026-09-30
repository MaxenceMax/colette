import 'package:colette/app/colette_app.dart';
import 'package:colette/core/clock/app_clock.dart';
import 'package:colette/features/household/presentation/providers/household_providers.dart';
import 'package:colette/features/photo_sharing/domain/use_cases/photo_reminder_schedule.dart';
import 'package:colette/features/photo_sharing/presentation/pages/photos_page.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import '../helpers/colette_app_overrides.dart';
import '../helpers/fake_photo_sharing_system.dart';
import '../helpers/fake_push_token_source.dart';

void main() {
  // La relecture du prénom dans Firestore (faux) demande un tour de boucle
  // d'événements réel, que `pumpAndSettle` seul n'accorde pas.
  Future<void> settle(WidgetTester tester) async {
    await tester.pumpAndSettle();
    await tester.runAsync(() => Future<void>.delayed(Duration.zero));
    await tester.pumpAndSettle();
  }

  Future<void> pumpColetteApp(
    WidgetTester tester, {
    required FakePhotoSharingSystem system,
    String? code = 'ABCDEFGH',
    FakePushTokenSource? pushSource,
  }) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          ...await coletteAppOverrides(
            householdCode: code,
            deviceId: 'dev-1',
            photoSharingSystem: system,
            pushTokenSource: pushSource,
          ),
          clockProvider.overrideWithValue(FixedClock(DateTime(2026, 9, 30, 7))),
        ],
        child: const ColetteApp(),
      ),
    );
    await settle(tester);
  }

  testWidgets('au démarrage avec un foyer : 14 rappels programmés', (
    tester,
  ) async {
    final system = FakePhotoSharingSystem();
    await pumpColetteApp(tester, system: system);
    expect(system.syncedDates, isNotEmpty);
    expect(system.syncedDates.last, hasLength(photoReminderDays));
  });

  testWidgets('sans foyer : rappels déjà programmés retirés', (tester) async {
    final system = FakePhotoSharingSystem();
    await pumpColetteApp(tester, system: system, code: null);
    expect(system.syncedDates, hasLength(1));
    expect(system.syncedDates.single, isEmpty);
  });

  testWidgets('foyer quitté sans prénom : rappels retirés', (tester) async {
    final system = FakePhotoSharingSystem();
    await pumpColetteApp(tester, system: system);
    expect(system.syncedDates.last, isNotEmpty);
    final container = ProviderScope.containerOf(
      tester.element(find.byType(ColetteApp)),
    );
    await container.read(currentHouseholdCodeProvider.notifier).clear();
    await settle(tester);
    expect(system.syncedDates.last, isEmpty);
  });

  testWidgets('autorisation des notifications obtenue : reprogrammation', (
    tester,
  ) async {
    final system = FakePhotoSharingSystem();
    await pumpColetteApp(
      tester,
      system: system,
      pushSource: FakePushTokenSource(granted: true, token: 'tok'),
    );
    await settle(tester);
    expect(system.syncedDates, hasLength(2));
    expect(system.syncedDates.last, hasLength(photoReminderDays));
  });

  testWidgets(
    'autorisation des notifications refusée : pas de reprogrammation',
    (tester) async {
      final system = FakePhotoSharingSystem();
      await pumpColetteApp(tester, system: system);
      expect(system.syncedDates, hasLength(1));
    },
  );

  testWidgets('notification en attente sans foyer : pas de page Photos', (
    tester,
  ) async {
    final system = FakePhotoSharingSystem(pendingRoute: '/today/photos');
    await pumpColetteApp(tester, system: system, code: null);
    expect(find.byType(PhotosPage), findsNothing);
  });

  testWidgets('retour au premier plan : reprogrammation', (tester) async {
    final system = FakePhotoSharingSystem();
    await pumpColetteApp(tester, system: system);
    final before = system.syncedDates.length;
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.inactive);
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
    await settle(tester);
    expect(system.syncedDates.length, before + 1);
  });

  testWidgets('lancé par la notification : page Photos', (tester) async {
    final system = FakePhotoSharingSystem(pendingRoute: '/today/photos');
    await pumpColetteApp(tester, system: system);
    expect(find.byType(PhotosPage), findsOneWidget);
  });

  testWidgets('notification ouverte app lancée : page Photos', (tester) async {
    final system = FakePhotoSharingSystem();
    await pumpColetteApp(tester, system: system);
    expect(find.byType(PhotosPage), findsNothing);
    system
      ..pendingRoute = '/today/photos'
      ..signals.add(null);
    await tester.pumpAndSettle();
    expect(find.byType(PhotosPage), findsOneWidget);
  });
}
