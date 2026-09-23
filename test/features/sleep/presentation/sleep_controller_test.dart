import 'package:colette/core/clock/app_clock.dart';
import 'package:colette/core/clock/now_providers.dart';
import 'package:colette/core/ids/id_generator.dart';
import 'package:colette/core/result/failure.dart';
import 'package:colette/features/baby/domain/entities/baby_profile.dart';
import 'package:colette/features/baby/presentation/providers/baby_providers.dart';
import 'package:colette/features/household/presentation/providers/household_providers.dart';
import 'package:colette/features/sleep/domain/entities/sleep_kind.dart';
import 'package:colette/features/sleep/presentation/providers/sleep_controller.dart';
import 'package:colette/features/sleep/presentation/providers/sleep_providers.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../helpers/fake_sleep_repository.dart';
import '../../../helpers/in_memory_household_local_store.dart';
import '../../../helpers/sleep_session_factory.dart';

void main() {
  final now = DateTime(2026, 9, 23, 21);

  ProviderContainer containerWith(FakeSleepRepository repo) {
    final container = ProviderContainer(
      overrides: [
        sleepRepositoryProvider.overrideWithValue(repo),
        clockProvider.overrideWithValue(FixedClock(now)),
        minuteTickerProvider.overrideWith((ref) => const Stream.empty()),
        idGeneratorProvider.overrideWithValue(const FixedIdGenerator('new')),
        householdLocalStoreProvider.overrideWithValue(
          InMemoryHouseholdLocalStore(
            householdCode: 'ABCDEFGH',
            deviceId: 'dev',
          ),
        ),
        babyProfileProvider.overrideWith(
          (ref) => Stream.value(
            BabyProfile(name: 'Colette', birthDate: DateTime(2026, 9, 1)),
          ),
        ),
      ],
    );
    addTearDown(container.dispose);
    // Garde le contrôleur et les flux en vie, comme le ferait la carte.
    container.listen(sleepControllerProvider, (_, _) {});
    container.listen(sleepSummaryProvider, (_, _) {});
    return container;
  }

  Future<void> settle(ProviderContainer c) async {
    await c.read(recentSleepsProvider.future);
    await c.read(latestSleepProvider.future);
    await c.read(babyProfileProvider.future);
  }

  test('fallAsleep crée un sommeil en cours classé selon l\'heure', () async {
    final repo = FakeSleepRepository();
    final c = containerWith(repo);
    await settle(c);
    expect(await c.read(sleepControllerProvider.notifier).fallAsleep(), isTrue);
    final saved = repo.saved.single;
    expect(saved.id, 'new');
    expect(saved.startAt, now);
    expect(saved.endAt, isNull);
    expect(saved.kind, SleepKind.night);
    expect(saved.createdByDeviceId, 'dev');
  });

  test('fallAsleep ne fait rien si un sommeil est déjà en cours', () async {
    final repo = FakeSleepRepository([
      makeSleep(id: 'o', startAt: DateTime(2026, 9, 23, 20)),
    ]);
    final c = containerWith(repo);
    await settle(c);
    expect(
      await c.read(sleepControllerProvider.notifier).fallAsleep(),
      isFalse,
    );
    expect(repo.saved, isEmpty);
  });

  test('wakeUp ferme le plus ancien et supprime les doublons', () async {
    final first = makeSleep(id: 'a', startAt: DateTime(2026, 9, 23, 20));
    final dup = makeSleep(id: 'b', startAt: DateTime(2026, 9, 23, 20, 1));
    final repo = FakeSleepRepository([first, dup]);
    final c = containerWith(repo);
    await settle(c);
    expect(await c.read(sleepControllerProvider.notifier).wakeUp(), isTrue);
    expect(repo.lastWakeUp!.close.endAt, now);
    expect(repo.lastWakeUp!.close.id, 'a');
    expect(repo.lastWakeUp!.deleteIds, ['b']);
  });

  test('save refuse un chevauchement et expose l\'échec', () async {
    final other = makeSleep(
      id: 'o',
      startAt: DateTime(2026, 9, 23, 14),
      endAt: DateTime(2026, 9, 23, 15),
    );
    final repo = FakeSleepRepository([other]);
    final c = containerWith(repo);
    await settle(c);
    final draft = makeSleep(
      id: 'n',
      startAt: DateTime(2026, 9, 23, 14, 30),
      endAt: DateTime(2026, 9, 23, 16),
    );
    expect(await c.read(sleepControllerProvider.notifier).save(draft), isNull);
    expect(c.read(sleepControllerProvider).error, isA<SleepOverlapFailure>());
    expect(repo.saved, isEmpty);
  });

  test(
    'save enregistre un sommeil valide avec updatedAt = maintenant',
    () async {
      final repo = FakeSleepRepository();
      final c = containerWith(repo);
      await settle(c);
      final draft = makeSleep(
        id: 'n',
        startAt: DateTime(2026, 9, 23, 14),
        endAt: DateTime(2026, 9, 23, 15),
      );
      final saved = await c.read(sleepControllerProvider.notifier).save(draft);
      expect(saved, draft.copyWith(updatedAt: now));
      expect(repo.saved.single, draft.copyWith(updatedAt: now));
    },
  );

  test('delete supprime et renvoie true', () async {
    final repo = FakeSleepRepository([
      makeSleep(
        id: 'x',
        startAt: DateTime(2026, 9, 23, 14),
        endAt: DateTime(2026, 9, 23, 15),
      ),
    ]);
    final c = containerWith(repo);
    await settle(c);
    expect(await c.read(sleepControllerProvider.notifier).delete('x'), isTrue);
    expect(repo.deleted, ['x']);
  });
}
