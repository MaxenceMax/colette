// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'selected_calendar.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// Calendrier des RDV santé de cet iPhone (identifiants EventKit propres à l'appareil).

@ProviderFor(SelectedCalendar)
final selectedCalendarProvider = SelectedCalendarProvider._();

/// Calendrier des RDV santé de cet iPhone (identifiants EventKit propres à l'appareil).
final class SelectedCalendarProvider
    extends $NotifierProvider<SelectedCalendar, CalendarChoice?> {
  /// Calendrier des RDV santé de cet iPhone (identifiants EventKit propres à l'appareil).
  SelectedCalendarProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'selectedCalendarProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$selectedCalendarHash();

  @$internal
  @override
  SelectedCalendar create() => SelectedCalendar();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(CalendarChoice? value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<CalendarChoice?>(value),
    );
  }
}

String _$selectedCalendarHash() => r'e6daca01854af8758dd134d80a82ec176023b19b';

/// Calendrier des RDV santé de cet iPhone (identifiants EventKit propres à l'appareil).

abstract class _$SelectedCalendar extends $Notifier<CalendarChoice?> {
  CalendarChoice? build();
  @$mustCallSuper
  @override
  WhenComplete runBuild() {
    final ref = this.ref as $Ref<CalendarChoice?, CalendarChoice?>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<CalendarChoice?, CalendarChoice?>,
              CalendarChoice?,
              Object?,
              Object?
            >;
    return element.handleCreate(ref, build);
  }
}
