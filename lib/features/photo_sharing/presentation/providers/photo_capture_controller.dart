import 'package:colette/features/photo_sharing/domain/entities/photo_source.dart';
import 'package:colette/features/photo_sharing/presentation/providers/photo_sharing_providers.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'photo_capture_controller.g.dart';

/// Prise ou choix des photos d'un envoi ; une failure passe en `AsyncError`.
@riverpod
class PhotoCaptureController extends _$PhotoCaptureController {
  @override
  FutureOr<void> build() {}

  /// Chemins des photos préparées ; vide si annulé ou en échec.
  Future<List<String>> capture(PhotoSource source) async {
    state = const AsyncLoading();
    final system = ref.read(photoSharingSystemProvider);
    final result = await switch (source) {
      PhotoSource.camera => system.takePhoto(),
      PhotoSource.gallery => system.pickPhotos(),
    };
    final paths = result.getOrElse((_) => const []);
    if (!ref.mounted) return paths;
    state = result.fold(
      (failure) => AsyncError(failure, StackTrace.current),
      (_) => const AsyncData(null),
    );
    return paths;
  }
}
