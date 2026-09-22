import 'package:colette/core/result/failure.dart';
import 'package:colette/features/household/domain/entities/device_info.dart';
import 'package:colette/features/household/domain/repositories/device_repository.dart';
import 'package:colette/features/household/presentation/providers/household_providers.dart';
import 'package:colette/features/notifications/presentation/providers/notifications_providers.dart';
import 'package:colette/features/notifications/presentation/widgets/notifications_section.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:mocktail/mocktail.dart';

import '../../../helpers/fake_push_token_source.dart';
import '../../../helpers/in_memory_household_local_store.dart';
import '../../../helpers/pump_app.dart';

class MockDeviceRepository extends Mock implements DeviceRepository {}

void main() {
  const device = DeviceInfo(id: 'dev-1', label: 'iPhone');
  late MockDeviceRepository devices;

  setUpAll(() => registerFallbackValue(device));

  setUp(() {
    devices = MockDeviceRepository();
    when(() => devices.updateFcmToken(any(), any(), any()))
        .thenAnswer((_) async => right(null));
  });

  List<Override> overrides({bool granted = true}) => [
    deviceRepositoryProvider.overrideWithValue(devices),
    householdLocalStoreProvider.overrideWithValue(
      InMemoryHouseholdLocalStore(householdCode: 'ABCDEFGH'),
    ),
    pushTokenSourceProvider.overrideWithValue(
      FakePushTokenSource(granted: granted, token: 'tok'),
    ),
  ];

  testWidgets('deux taps rapides sur l\'heure du digest s\'additionnent', (
    tester,
  ) async {
    when(() => devices.saveDevice(any(), any()))
        .thenAnswer((_) async => right(null));
    await pumpApp(
      tester,
      const Scaffold(
        body: SingleChildScrollView(
          child: NotificationsSection(device: device),
        ),
      ),
      overrides: overrides(),
    );
    final plusButton = find.widgetWithIcon(IconButton, Icons.add);
    await tester.tap(plusButton);
    await tester.pump();
    await tester.tap(plusButton);
    await tester.pumpAndSettle();
    final saved = verify(() => devices.saveDevice('ABCDEFGH', captureAny()))
        .captured
        .cast<DeviceInfo>();
    expect(saved.last.morningDigestHour, 10);
    expect(find.text('10 h'), findsOneWidget);
  });

  testWidgets(
    'activer un switch enregistre et déclenche l\'enregistrement push',
    (tester) async {
      when(() => devices.saveDevice(any(), any()))
          .thenAnswer((_) async => right(null));
      await pumpApp(
        tester,
        NotificationsSection(
          device: device.copyWith(notifyBottleReminder: false),
        ),
        overrides: overrides(),
      );
      await tester.tap(find.widgetWithText(SwitchListTile, 'Rappel biberon'));
      await tester.pumpAndSettle();
      final saved = verify(() => devices.saveDevice('ABCDEFGH', captureAny()))
          .captured
          .cast<DeviceInfo>();
      expect(saved.single.notifyBottleReminder, isTrue);
      verify(() => devices.updateFcmToken('ABCDEFGH', any(), 'tok')).called(1);
    },
  );

  testWidgets('un échec d\'enregistrement remet le switch en arrière', (
    tester,
  ) async {
    when(() => devices.saveDevice(any(), any())).thenAnswer((_) async {
      // Délai réel (Timer), pas seulement un microtask : sinon la chaîne
      // save → setState de retour en arrière se résout avant même le
      // premier `pump()`, et l'état optimiste ne serait jamais observable.
      await Future<void>.delayed(Duration.zero);
      return left(const NetworkFailure());
    });
    await pumpApp(
      tester,
      NotificationsSection(
        device: device.copyWith(notifyBottleReminder: false),
      ),
      overrides: overrides(),
    );
    await tester.tap(find.widgetWithText(SwitchListTile, 'Rappel biberon'));
    await tester.pump();
    expect(
      tester
          .widget<SwitchListTile>(
            find.widgetWithText(SwitchListTile, 'Rappel biberon'),
          )
          .value,
      isTrue,
    );
    await tester.pumpAndSettle();
    expect(
      tester
          .widget<SwitchListTile>(
            find.widgetWithText(SwitchListTile, 'Rappel biberon'),
          )
          .value,
      isFalse,
    );
    verify(() => devices.saveDevice('ABCDEFGH', any())).called(1);
  });

  testWidgets('activer un switch sans permission affiche un message', (
    tester,
  ) async {
    when(() => devices.saveDevice(any(), any()))
        .thenAnswer((_) async => right(null));
    await pumpApp(
      tester,
      Scaffold(
        body: NotificationsSection(
          device: device.copyWith(notifyBottleReminder: false),
        ),
      ),
      overrides: overrides(granted: false),
    );
    await tester.tap(find.widgetWithText(SwitchListTile, 'Rappel biberon'));
    await tester.pumpAndSettle();
    expect(
      find.text(
        'Notifications refusées. Autorise-les dans Réglages iOS › Colette.',
      ),
      findsOneWidget,
    );
  });
}
