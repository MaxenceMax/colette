// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'sleep_form_controller.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// Enregistrement et suppression d'un sommeil depuis le formulaire.
///
/// Séparé de `SleepController` : une erreur de saisie ne doit pas déclencher
/// la SnackBar de la carte, et un `wakeUp` en cours ne doit pas désactiver le
/// bouton Enregistrer du formulaire.

@ProviderFor(SleepFormController)
final sleepFormControllerProvider = SleepFormControllerProvider._();

/// Enregistrement et suppression d'un sommeil depuis le formulaire.
///
/// Séparé de `SleepController` : une erreur de saisie ne doit pas déclencher
/// la SnackBar de la carte, et un `wakeUp` en cours ne doit pas désactiver le
/// bouton Enregistrer du formulaire.
final class SleepFormControllerProvider
    extends $AsyncNotifierProvider<SleepFormController, void> {
  /// Enregistrement et suppression d'un sommeil depuis le formulaire.
  ///
  /// Séparé de `SleepController` : une erreur de saisie ne doit pas déclencher
  /// la SnackBar de la carte, et un `wakeUp` en cours ne doit pas désactiver le
  /// bouton Enregistrer du formulaire.
  SleepFormControllerProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'sleepFormControllerProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$sleepFormControllerHash();

  @$internal
  @override
  SleepFormController create() => SleepFormController();
}

String _$sleepFormControllerHash() =>
    r'e35dd8c4a6111e72ab64b33cc2f5c71be260e5e1';

/// Enregistrement et suppression d'un sommeil depuis le formulaire.
///
/// Séparé de `SleepController` : une erreur de saisie ne doit pas déclencher
/// la SnackBar de la carte, et un `wakeUp` en cours ne doit pas désactiver le
/// bouton Enregistrer du formulaire.

abstract class _$SleepFormController extends $AsyncNotifier<void> {
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
