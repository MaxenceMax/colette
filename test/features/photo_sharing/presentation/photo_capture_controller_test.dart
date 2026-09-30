import 'package:colette/core/result/failure.dart';
import 'package:colette/features/photo_sharing/domain/entities/photo_source.dart';
import 'package:colette/features/photo_sharing/presentation/providers/photo_capture_controller.dart';
import 'package:colette/features/photo_sharing/presentation/providers/photo_sharing_providers.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../helpers/fake_photo_sharing_system.dart';

void main() {
  late FakePhotoSharingSystem system;
  late ProviderContainer container;

  setUp(() {
    system = FakePhotoSharingSystem();
    container = ProviderContainer(
      overrides: [photoSharingSystemProvider.overrideWithValue(system)],
    );
    addTearDown(container.dispose);
    container.listen(photoCaptureControllerProvider, (_, _) {});
  });

  Future<List<String>> capture(PhotoSource source) =>
      container.read(photoCaptureControllerProvider.notifier).capture(source);

  test('capture : chemins rendus', () async {
    system.photos = ['/tmp/a.jpg', '/tmp/b.jpg'];
    final paths = await capture(PhotoSource.gallery);
    expect(paths, ['/tmp/a.jpg', '/tmp/b.jpg']);
    expect(container.read(photoCaptureControllerProvider), isA<AsyncData>());
  });

  test('capture annulée : liste vide et AsyncData', () async {
    system.photos = const [];
    final paths = await capture(PhotoSource.camera);
    expect(paths, isEmpty);
    expect(container.read(photoCaptureControllerProvider), isA<AsyncData>());
  });

  test('capture en échec : liste vide et AsyncError', () async {
    system.photosFailure = const PhotoSharingFailure(
      PhotoSharingReason.cameraUnavailable,
    );
    final paths = await capture(PhotoSource.camera);
    expect(paths, isEmpty);
    expect(container.read(photoCaptureControllerProvider).hasError, isTrue);
  });
}
