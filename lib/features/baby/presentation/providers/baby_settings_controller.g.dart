// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'baby_settings_controller.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// Actions de l'onglet Réglages sur le profil, les mesures de croissance et les soins attendus.

@ProviderFor(BabySettingsController)
final babySettingsControllerProvider = BabySettingsControllerProvider._();

/// Actions de l'onglet Réglages sur le profil, les mesures de croissance et les soins attendus.
final class BabySettingsControllerProvider
    extends $AsyncNotifierProvider<BabySettingsController, void> {
  /// Actions de l'onglet Réglages sur le profil, les mesures de croissance et les soins attendus.
  BabySettingsControllerProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'babySettingsControllerProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$babySettingsControllerHash();

  @$internal
  @override
  BabySettingsController create() => BabySettingsController();
}

String _$babySettingsControllerHash() =>
    r'c8380eea4c6970dc1d59b6595d4b6023d2a8299f';

/// Actions de l'onglet Réglages sur le profil, les mesures de croissance et les soins attendus.

abstract class _$BabySettingsController extends $AsyncNotifier<void> {
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
