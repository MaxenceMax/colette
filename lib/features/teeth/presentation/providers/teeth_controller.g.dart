// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'teeth_controller.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// Enregistre une dent (ou la supprime si elle est vide), ou l'efface.

@ProviderFor(TeethController)
final teethControllerProvider = TeethControllerProvider._();

/// Enregistre une dent (ou la supprime si elle est vide), ou l'efface.
final class TeethControllerProvider
    extends $AsyncNotifierProvider<TeethController, void> {
  /// Enregistre une dent (ou la supprime si elle est vide), ou l'efface.
  TeethControllerProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'teethControllerProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$teethControllerHash();

  @$internal
  @override
  TeethController create() => TeethController();
}

String _$teethControllerHash() => r'20ce3df8bb9973888b328825843c68b285ac22c7';

/// Enregistre une dent (ou la supprime si elle est vide), ou l'efface.

abstract class _$TeethController extends $AsyncNotifier<void> {
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
