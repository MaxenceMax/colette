import 'dart:async';

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
  final profile = BabyProfile(name: 'Colette', birthDate: DateTime(2026, 9, 1));

  ProviderContainer containerWith(
    FakeSleepRepository repo, {
    DateTime? clockNow,
    Stream<BabyProfile?>? profileStream,
  }) {
    final container = ProviderContainer(
      overrides: [
        sleepRepositoryProvider.overrideWithValue(repo),
        clockProvider.overrideWithValue(FixedClock(clockNow ?? now)),
        minuteTickerProvider.overrideWith((ref) => const Stream.empty()),
        idGeneratorProvider.overrideWithValue(const FixedIdGenerator('new')),
        householdLocalStoreProvider.overrideWithValue(
          InMemoryHouseholdLocalStore(
            householdCode: 'ABCDEFGH',
            deviceId: 'dev',
          ),
        ),
        babyProfileProvider.overrideWith(
          (ref) => profileStream ?? Stream.value(profile),
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

  test('fallAsleep à 14h classe le sommeil en sieste', () async {
    final repo = FakeSleepRepository();
    final c = containerWith(repo, clockNow: DateTime(2026, 9, 23, 14));
    await settle(c);
    expect(await c.read(sleepControllerProvider.notifier).fallAsleep(), isTrue);
    expect(repo.saved.single.kind, SleepKind.nap);
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

  test('fallAsleep renvoie false et expose l\'échec du dépôt', () async {
    final repo = FakeSleepRepository()..failure = const NetworkFailure();
    final c = containerWith(repo);
    await settle(c);
    expect(
      await c.read(sleepControllerProvider.notifier).fallAsleep(),
      isFalse,
    );
    expect(c.read(sleepControllerProvider).error, isA<NetworkFailure>());
  });

  test('un appel concurrent à fallAsleep est ignoré', () async {
    final repo = FakeSleepRepository()..writeGate = Completer<void>();
    final c = containerWith(repo);
    await settle(c);
    final notifier = c.read(sleepControllerProvider.notifier);
    final first = notifier.fallAsleep();
    expect(c.read(sleepControllerProvider), isA<AsyncLoading>());
    expect(await notifier.fallAsleep(), isFalse);
    repo.writeGate!.complete();
    expect(await first, isTrue);
    expect(repo.saved, hasLength(1));
  });

  test(
    'le profil qui émet pendant une écriture ne remet pas l\'état à AsyncData',
    () async {
      final repo = FakeSleepRepository()..writeGate = Completer<void>();
      final profileController = StreamController<BabyProfile?>.broadcast();
      final c = containerWith(repo, profileStream: profileController.stream);
      addTearDown(profileController.close);
      profileController.add(profile);
      await settle(c);
      final future = c.read(sleepControllerProvider.notifier).fallAsleep();
      await Future<void>.delayed(Duration.zero);
      expect(c.read(sleepControllerProvider), isA<AsyncLoading>());
      profileController.add(profile);
      await Future<void>.delayed(Duration.zero);
      expect(c.read(sleepControllerProvider), isA<AsyncLoading>());
      repo.writeGate!.complete();
      expect(await future, isTrue);
      expect(c.read(sleepControllerProvider), isA<AsyncData<void>>());
    },
  );

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

  test('wakeUp sans sommeil ouvert renvoie false', () async {
    final repo = FakeSleepRepository();
    final c = containerWith(repo);
    await settle(c);
    expect(await c.read(sleepControllerProvider.notifier).wakeUp(), isFalse);
  });
}
