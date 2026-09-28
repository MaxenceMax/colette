// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'timeline_filter_controller.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// Filtre actif du Journal ; « Tout » par défaut, gardé en mémoire.

@ProviderFor(TimelineFilterController)
final timelineFilterControllerProvider = TimelineFilterControllerProvider._();

/// Filtre actif du Journal ; « Tout » par défaut, gardé en mémoire.
final class TimelineFilterControllerProvider
    extends $NotifierProvider<TimelineFilterController, TimelineFilter> {
  /// Filtre actif du Journal ; « Tout » par défaut, gardé en mémoire.
  TimelineFilterControllerProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'timelineFilterControllerProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$timelineFilterControllerHash();

  @$internal
  @override
  TimelineFilterController create() => TimelineFilterController();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(TimelineFilter value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<TimelineFilter>(value),
    );
  }
}

String _$timelineFilterControllerHash() =>
    r'e6c75621b5a204900f593d71c448814618aa7c7f';

/// Filtre actif du Journal ; « Tout » par défaut, gardé en mémoire.

abstract class _$TimelineFilterController extends $Notifier<TimelineFilter> {
  TimelineFilter build();
  @$mustCallSuper
  @override
  WhenComplete runBuild() {
    final ref = this.ref as $Ref<TimelineFilter, TimelineFilter>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<TimelineFilter, TimelineFilter>,
              TimelineFilter,
              Object?,
              Object?
            >;
    return element.handleCreate(ref, build);
  }
}
