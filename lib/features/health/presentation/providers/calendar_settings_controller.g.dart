// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'calendar_settings_controller.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// Accès au Calendrier et choix du calendrier des RDV santé sur cet iPhone.

@ProviderFor(CalendarSettingsController)
final calendarSettingsControllerProvider =
    CalendarSettingsControllerProvider._();

/// Accès au Calendrier et choix du calendrier des RDV santé sur cet iPhone.
final class CalendarSettingsControllerProvider
    extends $AsyncNotifierProvider<CalendarSettingsController, void> {
  /// Accès au Calendrier et choix du calendrier des RDV santé sur cet iPhone.
  CalendarSettingsControllerProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'calendarSettingsControllerProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$calendarSettingsControllerHash();

  @$internal
  @override
  CalendarSettingsController create() => CalendarSettingsController();
}

String _$calendarSettingsControllerHash() =>
    r'12a9997f15233439ce60c1df7ef5b15bac51414a';

/// Accès au Calendrier et choix du calendrier des RDV santé sur cet iPhone.

abstract class _$CalendarSettingsController extends $AsyncNotifier<void> {
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
