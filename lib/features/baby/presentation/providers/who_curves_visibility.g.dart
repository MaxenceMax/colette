// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'who_curves_visibility.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// Courbes OMS affichées ou non sur la courbe de poids, mémorisé sur cet iPhone.

@ProviderFor(WhoCurvesVisibility)
final whoCurvesVisibilityProvider = WhoCurvesVisibilityProvider._();

/// Courbes OMS affichées ou non sur la courbe de poids, mémorisé sur cet iPhone.
final class WhoCurvesVisibilityProvider
    extends $NotifierProvider<WhoCurvesVisibility, bool> {
  /// Courbes OMS affichées ou non sur la courbe de poids, mémorisé sur cet iPhone.
  WhoCurvesVisibilityProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'whoCurvesVisibilityProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$whoCurvesVisibilityHash();

  @$internal
  @override
  WhoCurvesVisibility create() => WhoCurvesVisibility();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(bool value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<bool>(value),
    );
  }
}

String _$whoCurvesVisibilityHash() =>
    r'7ce3693b3ca71a6a6dcfae205605513d05a08f58';

/// Courbes OMS affichées ou non sur la courbe de poids, mémorisé sur cet iPhone.

abstract class _$WhoCurvesVisibility extends $Notifier<bool> {
  bool build();
  @$mustCallSuper
  @override
  WhenComplete runBuild() {
    final ref = this.ref as $Ref<bool, bool>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<bool, bool>,
              bool,
              Object?,
              Object?
            >;
    return element.handleCreate(ref, build);
  }
}
