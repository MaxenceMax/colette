import 'package:colette/core/clock/app_clock.dart';
import 'package:colette/core/result/failure.dart';
import 'package:colette/features/baby/presentation/providers/baby_providers.dart';
import 'package:colette/features/photo_sharing/domain/entities/broadcast_list.dart';
import 'package:colette/features/photo_sharing/domain/entities/photo_source.dart';
import 'package:colette/features/photo_sharing/domain/entities/recipient.dart';
import 'package:colette/features/photo_sharing/domain/entities/send_report.dart';
import 'package:colette/features/photo_sharing/presentation/providers/photo_capture_controller.dart';
import 'package:colette/features/photo_sharing/presentation/providers/photo_send_controller.dart';
import 'package:colette/features/photo_sharing/presentation/providers/photo_sharing_providers.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../helpers/fake_photo_sharing_system.dart';
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

  setUp(() {
    repo = InMemoryPhotoSharingRepository();
    system = FakePhotoSharingSystem();
    container = ProviderContainer(
      overrides: [
        photoSharingRepositoryProvider.overrideWithValue(repo),
        photoSharingSystemProvider.overrideWithValue(system),
        clockProvider.overrideWithValue(FixedClock(now)),
        babyProfileProvider.overrideWith((ref) => Stream.value(null)),
      ],
    );
    addTearDown(container.dispose);
    container.listen(photoSendControllerProvider, (_, _) {});
    container.listen(photoCaptureControllerProvider, (_, _) {});
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
    expect(system.syncedDates.single.first.day, 1);
  });

  test('tout annulé : rien d\'enregistré, pas de resynchronisation', () async {
    system.report = const SendReport(sent: 0, cancelled: 2, failed: 0);
    await send();
    expect(repo.lastSentAt, isNull);
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

  test('capture : chemins rendus', () async {
    system.photos = ['/tmp/a.jpg', '/tmp/b.jpg'];
    final paths = await container
        .read(photoCaptureControllerProvider.notifier)
        .capture(PhotoSource.gallery);
    expect(paths, ['/tmp/a.jpg', '/tmp/b.jpg']);
  });

  test('capture en échec : liste vide et AsyncError', () async {
    system.photosFailure = const PhotoSharingFailure(
      PhotoSharingReason.cameraUnavailable,
    );
    final paths = await container
        .read(photoCaptureControllerProvider.notifier)
        .capture(PhotoSource.camera);
    expect(paths, isEmpty);
    expect(container.read(photoCaptureControllerProvider).hasError, isTrue);
  });
}
