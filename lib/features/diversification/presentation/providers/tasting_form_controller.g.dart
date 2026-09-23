// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'tasting_form_controller.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// Enregistrement et suppression d'une dégustation. L'état porte l'échec éventuel.

@ProviderFor(TastingFormController)
final tastingFormControllerProvider = TastingFormControllerProvider._();

/// Enregistrement et suppression d'une dégustation. L'état porte l'échec éventuel.
final class TastingFormControllerProvider
    extends $AsyncNotifierProvider<TastingFormController, void> {
  /// Enregistrement et suppression d'une dégustation. L'état porte l'échec éventuel.
  TastingFormControllerProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'tastingFormControllerProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$tastingFormControllerHash();

  @$internal
  @override
  TastingFormController create() => TastingFormController();
}

String _$tastingFormControllerHash() =>
    r'e0c6ce9837f0061a5b0c496312ad3c86a98a5bd0';

/// Enregistrement et suppression d'une dégustation. L'état porte l'échec éventuel.

abstract class _$TastingFormController extends $AsyncNotifier<void> {
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
