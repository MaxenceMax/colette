// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'sleep_controller.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// Endormissement, réveil, saisie et suppression d'un sommeil.

@ProviderFor(SleepController)
final sleepControllerProvider = SleepControllerProvider._();

/// Endormissement, réveil, saisie et suppression d'un sommeil.
final class SleepControllerProvider
    extends $AsyncNotifierProvider<SleepController, void> {
  /// Endormissement, réveil, saisie et suppression d'un sommeil.
  SleepControllerProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'sleepControllerProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$sleepControllerHash();

  @$internal
  @override
  SleepController create() => SleepController();
}

String _$sleepControllerHash() => r'aad268891dc8fe6ae6005f8f19a83874c0c317a8';

/// Endormissement, réveil, saisie et suppression d'un sommeil.

abstract class _$SleepController extends $AsyncNotifier<void> {
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
