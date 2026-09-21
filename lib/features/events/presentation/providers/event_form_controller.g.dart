// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'event_form_controller.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// Enregistrement et suppression d'un événement. L'état porte l'échec éventuel.

@ProviderFor(EventFormController)
final eventFormControllerProvider = EventFormControllerProvider._();

/// Enregistrement et suppression d'un événement. L'état porte l'échec éventuel.
final class EventFormControllerProvider
    extends $AsyncNotifierProvider<EventFormController, void> {
  /// Enregistrement et suppression d'un événement. L'état porte l'échec éventuel.
  EventFormControllerProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'eventFormControllerProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$eventFormControllerHash();

  @$internal
  @override
  EventFormController create() => EventFormController();
}

String _$eventFormControllerHash() =>
    r'ffad9c468118b88a4d619e7e72d779041eaa9985';

/// Enregistrement et suppression d'un événement. L'état porte l'échec éventuel.

abstract class _$EventFormController extends $AsyncNotifier<void> {
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
