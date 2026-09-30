import 'package:colette/core/clock/app_clock.dart';
import 'package:colette/core/firebase/firebase_providers.dart';
import 'package:colette/core/result/failure.dart';
import 'package:colette/features/baby/domain/entities/baby_profile.dart';
import 'package:colette/features/baby/presentation/providers/baby_providers.dart';
import 'package:colette/features/household/presentation/providers/household_providers.dart';
import 'package:colette/features/photo_sharing/domain/use_cases/photo_reminder_schedule.dart';
import 'package:colette/features/photo_sharing/presentation/providers/photo_reminder.dart';
import 'package:colette/features/photo_sharing/presentation/providers/photo_sharing_providers.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../helpers/fake_photo_sharing_system.dart';
import '../../../helpers/in_memory_household_local_store.dart';
import '../../../helpers/in_memory_photo_sharing_repository.dart';

void main() {
  const code = 'ABCDEFGH';
  final now = DateTime(2026, 9, 30, 7);
  late InMemoryPhotoSharingRepository repo;
  late FakePhotoSharingSystem system;

  Future<ProviderContainer> makeContainer({
    String? householdCode = code,
    BabyProfile? profile,
  }) async {
    final container = ProviderContainer(
      overrides: [
        photoSharingRepositoryProvider.overrideWithValue(repo),
        photoSharingSystemProvider.overrideWithValue(system),
        clockProvider.overrideWithValue(FixedClock(now)),
        firestoreProvider.overrideWithValue(FakeFirebaseFirestore()),
        householdLocalStoreProvider.overrideWithValue(
          InMemoryHouseholdLocalStore(householdCode: householdCode),
        ),
      ],
    );
    addTearDown(container.dispose);
    if (profile != null) {
      await container.read(babyRepositoryProvider).saveProfile(code, profile);
    }
    return container;
  }

  setUp(() {
    repo = InMemoryPhotoSharingRepository();
    system = FakePhotoSharingSystem();
  });

  test('sync actif : 14 dates, texte avec le prénom relu', () async {
    final container = await makeContainer(
      profile: BabyProfile(name: 'Colette', birthDate: DateTime(2026, 9, 1)),
    );
    await container.read(photoReminderSyncProvider).sync();
    expect(system.syncedDates.single, hasLength(photoReminderDays));
    expect(system.lastTitle, "C'est l'heure d'une photo 📷");
    expect(system.lastBody, 'Envoie des nouvelles de Colette à tes proches.');
  });

  test('sync sans profil : texte générique', () async {
    final container = await makeContainer();
    await container.read(photoReminderSyncProvider).sync();
    expect(system.lastBody, 'Envoie des nouvelles de bébé à tes proches.');
  });

  test('sync sans foyer : texte générique', () async {
    final container = await makeContainer(householdCode: null);
    await container.read(photoReminderSyncProvider).sync();
    expect(system.syncedDates.single, hasLength(photoReminderDays));
    expect(system.lastBody, 'Envoie des nouvelles de bébé à tes proches.');
  });

  test("sync après un envoi aujourd'hui : pas de date aujourd'hui", () async {
    repo.lastSentAt = DateTime(2026, 9, 30, 6);
    final container = await makeContainer();
    await container.read(photoReminderSyncProvider).sync();
    expect(system.syncedDates.single.first.day, 1);
  });

  test('désactiver : enregistré puis aucune date programmée', () async {
    final container = await makeContainer();
    expect(await container.read(photoReminderEnabledProvider.future), isTrue);
    await container.read(photoReminderEnabledProvider.notifier).set(false);
    expect(repo.reminderEnabled, isFalse);
    expect(container.read(photoReminderEnabledProvider).value, isFalse);
    expect(system.syncedDates.single, isEmpty);
  });

  test('désactiver en échec : failure, état inchangé, aucune sync', () async {
    final container = await makeContainer();
    expect(await container.read(photoReminderEnabledProvider.future), isTrue);
    repo.failSaves = true;
    final result = await container
        .read(photoReminderEnabledProvider.notifier)
        .set(false);
    expect(result.getLeft().toNullable(), isA<UnknownFailure>());
    expect(container.read(photoReminderEnabledProvider).value, isTrue);
    expect(system.syncedDates, isEmpty);
  });

  test(
    'programmation en échec : sync et set se terminent sans erreur',
    () async {
      system.syncError = StateError('notifications indisponibles');
      final container = await makeContainer();
      await expectLater(
        container.read(photoReminderSyncProvider).sync(),
        completes,
      );
      final result = await container
          .read(photoReminderEnabledProvider.notifier)
          .set(false);
      expect(result.isRight(), isTrue);
      expect(repo.reminderEnabled, isFalse);
    },
  );

  test('markSent : enregistré et exposé', () async {
    final container = await makeContainer();
    expect(await container.read(lastPhotoSentAtProvider.future), isNull);
    await container.read(lastPhotoSentAtProvider.notifier).markSent(now);
    expect(repo.lastSentAt, now);
    expect(container.read(lastPhotoSentAtProvider).value, now);
  });
}
