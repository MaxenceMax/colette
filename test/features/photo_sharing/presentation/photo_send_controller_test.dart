import 'dart:async';

import 'package:colette/core/clock/app_clock.dart';
import 'package:colette/core/firebase/firebase_providers.dart';
import 'package:colette/core/result/failure.dart';
import 'package:colette/features/household/presentation/providers/household_providers.dart';
import 'package:colette/features/photo_sharing/domain/entities/broadcast_list.dart';
import 'package:colette/features/photo_sharing/domain/entities/recipient.dart';
import 'package:colette/features/photo_sharing/domain/entities/send_report.dart';
import 'package:colette/features/photo_sharing/presentation/providers/photo_send_controller.dart';
import 'package:colette/features/photo_sharing/presentation/providers/photo_sharing_providers.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../helpers/fake_photo_sharing_system.dart';
import '../../../helpers/in_memory_household_local_store.dart';
import '../../../helpers/in_memory_photo_sharing_repository.dart';

void main() {
  final now = DateTime(2026, 9, 30, 15, 20);
  const list = BroadcastList(
    id: 'l1',
    name: 'Famille',
    recipients: [
      Recipient(name: 'Mamie', phone: '0611'),
      Recipient(name: 'Papi', phone: '0622'),
    ],
  );
  late InMemoryPhotoSharingRepository repo;
  late FakePhotoSharingSystem system;
  late ProviderContainer container;
  late ProviderSubscription<AsyncValue<SendReport?>> sub;

  setUp(() {
    repo = InMemoryPhotoSharingRepository(lists: const [list]);
    system = FakePhotoSharingSystem();
    container = ProviderContainer(
      overrides: [
        photoSharingRepositoryProvider.overrideWithValue(repo),
        photoSharingSystemProvider.overrideWithValue(system),
        clockProvider.overrideWithValue(FixedClock(now)),
        firestoreProvider.overrideWithValue(FakeFirebaseFirestore()),
        householdLocalStoreProvider.overrideWithValue(
          InMemoryHouseholdLocalStore(householdCode: 'ABCDEFGH'),
        ),
      ],
    );
    addTearDown(container.dispose);
    sub = container.listen(photoSendControllerProvider, (_, _) {});
  });

  Future<void> send() => container
      .read(photoSendControllerProvider.notifier)
      .send(list: list, photoPaths: ['/tmp/a.jpg'], body: '  Coucou  ');

  test('un message par personne, texte nettoyé, photos effacées', () async {
    system.report = const SendReport(sent: 2, cancelled: 0, failed: 0);
    await send();
    expect(system.sendCalls.single.phones, ['0611', '0622']);
    expect(system.sendCalls.single.body, 'Coucou');
    expect(system.discarded, ['/tmp/a.jpg']);
    expect(
      container.read(photoSendControllerProvider).value,
      const SendReport(sent: 2, cancelled: 0, failed: 0),
    );
  });

  test('au moins un envoi : date enregistrée, rappel du jour retiré', () async {
    system.report = const SendReport(sent: 1, cancelled: 1, failed: 0);
    await send();
    expect(repo.lastSentAt, now);
    expect(repo.lists.single.lastSentAt, now);
    expect(system.syncedDates.single.first.day, 1);
  });

  test('écran fermé pendant l\'envoi : date et rappel enregistrés', () async {
    system.report = const SendReport(sent: 1, cancelled: 0, failed: 0);
    final gate = system.sendGate = Completer<void>();
    final sending = send();
    await pumpEventQueue();
    sub.close();
    await pumpEventQueue();
    gate.complete();
    await sending;
    expect(repo.lastSentAt, now);
    expect(repo.lists.single.lastSentAt, now);
    expect(system.syncedDates, isNotEmpty);
    expect(system.discarded, ['/tmp/a.jpg']);
  });

  test('tout annulé : rien d\'enregistré, pas de resynchronisation', () async {
    system.report = const SendReport(sent: 0, cancelled: 2, failed: 0);
    await send();
    expect(repo.lastSentAt, isNull);
    expect(repo.lists.single.lastSentAt, isNull);
    expect(system.syncedDates, isEmpty);
  });

  test('Messages indisponible : AsyncError, photos effacées', () async {
    system.sendFailure = const PhotoSharingFailure(
      PhotoSharingReason.messagesUnavailable,
    );
    await send();
    expect(
      container.read(photoSendControllerProvider).error,
      const PhotoSharingFailure(PhotoSharingReason.messagesUnavailable),
    );
    expect(system.discarded, ['/tmp/a.jpg']);
  });
}
