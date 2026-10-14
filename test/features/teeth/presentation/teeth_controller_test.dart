import 'package:colette/core/clock/app_clock.dart';
import 'package:colette/core/result/failure.dart';
import 'package:colette/features/household/presentation/providers/household_providers.dart';
import 'package:colette/features/teeth/domain/entities/tooth_record.dart';
import 'package:colette/features/teeth/presentation/providers/teeth_controller.dart';
import 'package:colette/features/teeth/presentation/providers/teeth_providers.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:mocktail/mocktail.dart';

import '../../../helpers/in_memory_household_local_store.dart';
import '../teeth_factories.dart';

void main() {
  late MockTeethRepository repo;
  late ProviderContainer container;
  final birth = DateTime(2026, 9, 1);
  final now = DateTime(2027, 3, 10, 9);

  setUpAll(() {
    registerFallbackValue(makeTooth(51));
    registerFallbackValue(tooth(51));
  });

  setUp(() {
    repo = MockTeethRepository();
    container = ProviderContainer(
      overrides: [
        teethRepositoryProvider.overrideWithValue(repo),
        clockProvider.overrideWithValue(FixedClock(now)),
        householdLocalStoreProvider.overrideWithValue(
          InMemoryHouseholdLocalStore(
            householdCode: 'ABCDEFGH',
            deviceId: 'device-b',
          ),
        ),
      ],
    );
    addTearDown(container.dispose);
  });

  TeethController controller() =>
      container.read(teethControllerProvider.notifier);

  test('enregistre la dent horodatée par cet iPhone, note rognée', () async {
    when(() => repo.saveTooth(any(), any()))
        .thenAnswer((_) async => right(null));
    final ok = await controller().save(
      makeTooth(
        71,
        eruptedAt: DateTime(2027, 3, 10, 12),
        note: ' nuit agitée ',
      ),
      birthDate: birth,
    );
    expect(ok, isTrue);
    final saved =
        verify(() => repo.saveTooth('ABCDEFGH', captureAny())).captured.single
            as ToothRecord;
    expect(saved.updatedAt, now);
    expect(saved.updatedByDeviceId, 'device-b');
    expect(saved.note, 'nuit agitée');
  });

  test('une dent vidée est supprimée', () async {
    when(() => repo.deleteTooth(any(), any()))
        .thenAnswer((_) async => right(null));
    expect(await controller().save(makeTooth(71), birthDate: birth), isTrue);
    verify(() => repo.deleteTooth('ABCDEFGH', tooth(71))).called(1);
    verifyNever(() => repo.saveTooth(any(), any()));
  });

  test('refuse une dent invalide sans écrire', () async {
    final sub = container.listen(teethControllerProvider, (_, _) {});
    addTearDown(sub.close);
    final ok = await controller().save(
      makeTooth(11, lostAt: DateTime(2027, 1, 10, 12)),
      birthDate: birth,
    );
    expect(ok, isFalse);
    expect(
      (container.read(teethControllerProvider).error! as ValidationFailure)
          .reason,
      ValidationReason.toothLossOnPermanent,
    );
    verifyNever(() => repo.saveTooth(any(), any()));
  });

  test('remonte l\'échec d\'écriture', () async {
    when(() => repo.saveTooth(any(), any()))
        .thenAnswer((_) async => left(const NetworkFailure()));
    final sub = container.listen(teethControllerProvider, (_, _) {});
    addTearDown(sub.close);
    final ok = await controller().save(
      makeTooth(71, eruptedAt: DateTime(2027, 3, 1, 12)),
      birthDate: birth,
    );
    expect(ok, isFalse);
    expect(
      container.read(teethControllerProvider).error,
      isA<NetworkFailure>(),
    );
  });

  test('clear supprime la dent', () async {
    when(() => repo.deleteTooth(any(), any()))
        .thenAnswer((_) async => right(null));
    expect(await controller().clear(tooth(71)), isTrue);
    verify(() => repo.deleteTooth('ABCDEFGH', tooth(71))).called(1);
  });
}
