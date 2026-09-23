// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'custom_food_controller.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// Création, modification et suppression d'un aliment perso.

@ProviderFor(CustomFoodController)
final customFoodControllerProvider = CustomFoodControllerProvider._();

/// Création, modification et suppression d'un aliment perso.
final class CustomFoodControllerProvider
    extends $AsyncNotifierProvider<CustomFoodController, void> {
  /// Création, modification et suppression d'un aliment perso.
  CustomFoodControllerProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'customFoodControllerProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$customFoodControllerHash();

  @$internal
  @override
  CustomFoodController create() => CustomFoodController();
}

String _$customFoodControllerHash() =>
    r'bdfa3aaf31d973f1b19ebd699eef9e48c6add4ca';

/// Création, modification et suppression d'un aliment perso.

abstract class _$CustomFoodController extends $AsyncNotifier<void> {
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
