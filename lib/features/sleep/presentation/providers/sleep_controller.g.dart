// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'sleep_controller.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// Endormissement et réveil, déclenchés depuis la carte d'accueil.

@ProviderFor(SleepController)
final sleepControllerProvider = SleepControllerProvider._();

/// Endormissement et réveil, déclenchés depuis la carte d'accueil.
final class SleepControllerProvider
    extends $AsyncNotifierProvider<SleepController, void> {
  /// Endormissement et réveil, déclenchés depuis la carte d'accueil.
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

String _$sleepControllerHash() => r'6bd51e4fc536b593c02db277642a4719fa6e273a';

/// Endormissement et réveil, déclenchés depuis la carte d'accueil.

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
