import 'dart:async';

import 'package:colette/core/clock/app_clock.dart';
import 'package:colette/core/clock/now_providers.dart';
import 'package:colette/core/ids/id_generator.dart';
import 'package:colette/core/result/failure.dart';
import 'package:colette/features/baby/domain/entities/baby_profile.dart';
import 'package:colette/features/baby/presentation/providers/baby_providers.dart';
import 'package:colette/features/household/presentation/providers/household_providers.dart';
import 'package:colette/features/sleep/presentation/providers/sleep_form_controller.dart';
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
    String? householdCode = 'ABCDEFGH',
    Stream<BabyProfile?>? profileStream,
  }) {
    final container = ProviderContainer(
      overrides: [
        sleepRepositoryProvider.overrideWithValue(repo),
        clockProvider.overrideWithValue(FixedClock(now)),
        minuteTickerProvider.overrideWith((ref) => const Stream.empty()),
        idGeneratorProvider.overrideWithValue(const FixedIdGenerator('new')),
        householdLocalStoreProvider.overrideWithValue(
          InMemoryHouseholdLocalStore(
            householdCode: householdCode,
            deviceId: 'dev',
          ),
        ),
        babyProfileProvider.overrideWith(
          (ref) => profileStream ?? Stream.value(profile),
        ),
      ],
    );
    addTearDown(container.dispose);
    // Garde le contrôleur en vie, comme le ferait le formulaire.
    container.listen(sleepFormControllerProvider, (_, _) {});
    return container;
  }

  Future<void> settle(ProviderContainer c) async {
    await c.read(babyProfileProvider.future);
  }

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
    expect(
      await c.read(sleepFormControllerProvider.notifier).save(draft),
      isNull,
    );
    expect(
      c.read(sleepFormControllerProvider).error,
      isA<SleepOverlapFailure>(),
    );
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
      final saved = await c
          .read(sleepFormControllerProvider.notifier)
          .save(draft);
      expect(saved, draft.copyWith(updatedAt: now));
      expect(repo.saved.single, draft.copyWith(updatedAt: now));
    },
  );

  test('save sans code foyer expose NotFoundFailure et renvoie null', () async {
    final repo = FakeSleepRepository();
    final c = containerWith(repo, householdCode: null);
    await settle(c);
    final draft = makeSleep(id: 'n', startAt: DateTime(2026, 9, 23, 14));
    expect(
      await c.read(sleepFormControllerProvider.notifier).save(draft),
      isNull,
    );
    expect(c.read(sleepFormControllerProvider).error, isA<NotFoundFailure>());
    expect(repo.saved, isEmpty);
  });

  test('save sans profil expose NotFoundFailure et renvoie null', () async {
    final repo = FakeSleepRepository();
    final c = containerWith(repo, profileStream: Stream.value(null));
    await settle(c);
    final draft = makeSleep(id: 'n', startAt: DateTime(2026, 9, 23, 14));
    expect(
      await c.read(sleepFormControllerProvider.notifier).save(draft),
      isNull,
    );
    expect(c.read(sleepFormControllerProvider).error, isA<NotFoundFailure>());
    expect(repo.saved, isEmpty);
  });

  test('save renvoie null et expose l\'échec du dépôt', () async {
    final repo = FakeSleepRepository()..failure = const NetworkFailure();
    final c = containerWith(repo);
    await settle(c);
    final draft = makeSleep(id: 'n', startAt: DateTime(2026, 9, 23, 14));
    expect(
      await c.read(sleepFormControllerProvider.notifier).save(draft),
      isNull,
    );
    expect(c.read(sleepFormControllerProvider).error, isA<NetworkFailure>());
  });

  test('un appel concurrent à save est ignoré', () async {
    final repo = FakeSleepRepository()..writeGate = Completer<void>();
    final c = containerWith(repo);
    await settle(c);
    final notifier = c.read(sleepFormControllerProvider.notifier);
    final draft = makeSleep(id: 'n', startAt: DateTime(2026, 9, 23, 14));
    final first = notifier.save(draft);
    expect(c.read(sleepFormControllerProvider), isA<AsyncLoading>());
    expect(await notifier.save(draft), isNull);
    repo.writeGate!.complete();
    expect(await first, isNotNull);
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
      final draft = makeSleep(id: 'n', startAt: DateTime(2026, 9, 23, 14));
      final future = c.read(sleepFormControllerProvider.notifier).save(draft);
      await Future<void>.delayed(Duration.zero);
      expect(c.read(sleepFormControllerProvider), isA<AsyncLoading>());
      profileController.add(profile);
      await Future<void>.delayed(Duration.zero);
      expect(c.read(sleepFormControllerProvider), isA<AsyncLoading>());
      repo.writeGate!.complete();
      expect(await future, isNotNull);
      expect(c.read(sleepFormControllerProvider), isA<AsyncData<void>>());
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
    expect(
      await c.read(sleepFormControllerProvider.notifier).delete('x'),
      isTrue,
    );
    expect(repo.deleted, ['x']);
  });

  test('delete sans code foyer renvoie false', () async {
    final repo = FakeSleepRepository();
    final c = containerWith(repo, householdCode: null);
    await settle(c);
    expect(
      await c.read(sleepFormControllerProvider.notifier).delete('x'),
      isFalse,
    );
  });

  test('delete renvoie false et expose l\'échec du dépôt', () async {
    final repo = FakeSleepRepository()..failure = const NetworkFailure();
    final c = containerWith(repo);
    await settle(c);
    expect(
      await c.read(sleepFormControllerProvider.notifier).delete('x'),
      isFalse,
    );
    expect(c.read(sleepFormControllerProvider).error, isA<NetworkFailure>());
  });

  test('un appel concurrent à delete est ignoré', () async {
    final repo = FakeSleepRepository()..writeGate = Completer<void>();
    final c = containerWith(repo);
    await settle(c);
    final notifier = c.read(sleepFormControllerProvider.notifier);
    final first = notifier.delete('x');
    expect(c.read(sleepFormControllerProvider), isA<AsyncLoading>());
    expect(await notifier.delete('x'), isFalse);
    repo.writeGate!.complete();
    expect(await first, isTrue);
    expect(repo.deleted, ['x']);
  });
}
