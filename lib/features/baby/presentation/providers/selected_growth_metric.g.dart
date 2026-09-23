// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'selected_growth_metric.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// Grandeur affichée sur la page Croissance ; revient au poids à chaque ouverture.

@ProviderFor(SelectedGrowthMetric)
final selectedGrowthMetricProvider = SelectedGrowthMetricProvider._();

/// Grandeur affichée sur la page Croissance ; revient au poids à chaque ouverture.
final class SelectedGrowthMetricProvider
    extends $NotifierProvider<SelectedGrowthMetric, GrowthMetric> {
  /// Grandeur affichée sur la page Croissance ; revient au poids à chaque ouverture.
  SelectedGrowthMetricProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'selectedGrowthMetricProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$selectedGrowthMetricHash();

  @$internal
  @override
  SelectedGrowthMetric create() => SelectedGrowthMetric();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(GrowthMetric value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<GrowthMetric>(value),
    );
  }
}

String _$selectedGrowthMetricHash() =>
    r'8521a7e1107dd716c5081b1dbfbd73a98eb2ebb2';

/// Grandeur affichée sur la page Croissance ; revient au poids à chaque ouverture.

abstract class _$SelectedGrowthMetric extends $Notifier<GrowthMetric> {
  GrowthMetric build();
  @$mustCallSuper
  @override
  WhenComplete runBuild() {
    final ref = this.ref as $Ref<GrowthMetric, GrowthMetric>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<GrowthMetric, GrowthMetric>,
              GrowthMetric,
              Object?,
              Object?
            >;
    return element.handleCreate(ref, build);
  }
}
