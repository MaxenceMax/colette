import 'package:colette/core/clock/app_clock.dart';
import 'package:colette/features/baby/domain/entities/baby_profile.dart';
import 'package:colette/features/baby/presentation/providers/baby_providers.dart';
import 'package:colette/features/photo_sharing/domain/use_cases/photo_reminder_schedule.dart';
import 'package:colette/features/photo_sharing/presentation/providers/photo_reminder.dart';
import 'package:colette/features/photo_sharing/presentation/providers/photo_sharing_providers.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../helpers/fake_photo_sharing_system.dart';
import '../../../helpers/in_memory_photo_sharing_repository.dart';

void main() {
  final now = DateTime(2026, 9, 30, 7);
  late InMemoryPhotoSharingRepository repo;
  late FakePhotoSharingSystem system;

  ProviderContainer makeContainer({BabyProfile? profile}) {
    final container = ProviderContainer(
      overrides: [
        photoSharingRepositoryProvider.overrideWithValue(repo),
        photoSharingSystemProvider.overrideWithValue(system),
        clockProvider.overrideWithValue(FixedClock(now)),
        babyProfileProvider.overrideWith((ref) => Stream.value(profile)),
      ],
    );
    addTearDown(container.dispose);
    // Garde le profil chargé, comme le fait PhotoReminderGate.
    container.listen(babyProfileProvider, (_, _) {});
    return container;
  }

  setUp(() {
    repo = InMemoryPhotoSharingRepository();
    system = FakePhotoSharingSystem();
  });

  test('sync actif : 14 dates, texte avec le prénom', () async {
    final container = makeContainer(
      profile: BabyProfile(name: 'Colette', birthDate: DateTime(2026, 9, 1)),
    );
    await container.read(babyProfileProvider.future);
    await container.read(photoReminderSyncProvider).sync();
    expect(system.syncedDates.single, hasLength(photoReminderDays));
    expect(system.lastTitle, "C'est l'heure d'une photo 📷");
    expect(system.lastBody, 'Envoie des nouvelles de Colette à tes proches.');
  });

  test('sync sans prénom : texte générique', () async {
    final container = makeContainer();
    await container.read(babyProfileProvider.future);
    await container.read(photoReminderSyncProvider).sync();
    expect(system.lastBody, 'Envoie des nouvelles de bébé à tes proches.');
  });

  test("sync après un envoi aujourd'hui : pas de date aujourd'hui", () async {
    repo.lastSentAt = DateTime(2026, 9, 30, 6);
    final container = makeContainer();
    await container.read(photoReminderSyncProvider).sync();
    expect(system.syncedDates.single.first.day, 1);
  });

  test('désactiver : enregistré puis aucune date programmée', () async {
    final container = makeContainer();
    expect(await container.read(photoReminderEnabledProvider.future), isTrue);
    await container.read(photoReminderEnabledProvider.notifier).set(false);
    expect(repo.reminderEnabled, isFalse);
    expect(container.read(photoReminderEnabledProvider).value, isFalse);
    expect(system.syncedDates.single, isEmpty);
  });

  test('markSent : enregistré et exposé', () async {
    final container = makeContainer();
    expect(await container.read(lastPhotoSentAtProvider.future), isNull);
    await container.read(lastPhotoSentAtProvider.notifier).markSent(now);
    expect(repo.lastSentAt, now);
    expect(container.read(lastPhotoSentAtProvider).value, now);
  });
}
