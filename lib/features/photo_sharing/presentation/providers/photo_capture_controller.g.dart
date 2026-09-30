// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'photo_capture_controller.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// Prise ou choix des photos d'un envoi ; une failure passe en `AsyncError`.

@ProviderFor(PhotoCaptureController)
final photoCaptureControllerProvider = PhotoCaptureControllerProvider._();

/// Prise ou choix des photos d'un envoi ; une failure passe en `AsyncError`.
final class PhotoCaptureControllerProvider
    extends $AsyncNotifierProvider<PhotoCaptureController, void> {
  /// Prise ou choix des photos d'un envoi ; une failure passe en `AsyncError`.
  PhotoCaptureControllerProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'photoCaptureControllerProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$photoCaptureControllerHash();

  @$internal
  @override
  PhotoCaptureController create() => PhotoCaptureController();
}

String _$photoCaptureControllerHash() =>
    r'a3b50afff353c979f27836bbfa9927951405b5ae';

/// Prise ou choix des photos d'un envoi ; une failure passe en `AsyncError`.

abstract class _$PhotoCaptureController extends $AsyncNotifier<void> {
  FutureOr<void> build();
  @$mustCallSuper
  @override
  WhenComplete runBuild() {
    final ref = this.ref as $Ref<AsyncValue<void>, void>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<AsyncValue<void>, void>,
              AsyncValue<void>,
              Object?,
              Object?
            >;
    return element.handleCreate(ref, build);
  }
}
