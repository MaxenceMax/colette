// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'calendar_sync_issue.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// Dernier échec bloquant de la synchronisation du calendrier ; `null` si tout va bien.

@ProviderFor(CalendarSyncIssue)
final calendarSyncIssueProvider = CalendarSyncIssueProvider._();

/// Dernier échec bloquant de la synchronisation du calendrier ; `null` si tout va bien.
final class CalendarSyncIssueProvider
    extends $NotifierProvider<CalendarSyncIssue, CalendarReason?> {
  /// Dernier échec bloquant de la synchronisation du calendrier ; `null` si tout va bien.
  CalendarSyncIssueProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'calendarSyncIssueProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$calendarSyncIssueHash();

  @$internal
  @override
  CalendarSyncIssue create() => CalendarSyncIssue();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(CalendarReason? value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<CalendarReason?>(value),
    );
  }
}

String _$calendarSyncIssueHash() => r'5f193847982b5b0e5245eb7b21f63adddae27ab7';

/// Dernier échec bloquant de la synchronisation du calendrier ; `null` si tout va bien.

abstract class _$CalendarSyncIssue extends $Notifier<CalendarReason?> {
  CalendarReason? build();
  @$mustCallSuper
  @override
  WhenComplete runBuild() {
    final ref = this.ref as $Ref<CalendarReason?, CalendarReason?>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<CalendarReason?, CalendarReason?>,
              CalendarReason?,
              Object?,
              Object?
            >;
    return element.handleCreate(ref, build);
  }
}
