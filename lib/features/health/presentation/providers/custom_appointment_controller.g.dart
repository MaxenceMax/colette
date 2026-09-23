// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'custom_appointment_controller.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// Enregistre ou supprime un RDV libre, puis resynchronise rappels et calendrier.

@ProviderFor(CustomAppointmentController)
final customAppointmentControllerProvider =
    CustomAppointmentControllerProvider._();

/// Enregistre ou supprime un RDV libre, puis resynchronise rappels et calendrier.
final class CustomAppointmentControllerProvider
    extends $AsyncNotifierProvider<CustomAppointmentController, void> {
  /// Enregistre ou supprime un RDV libre, puis resynchronise rappels et calendrier.
  CustomAppointmentControllerProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'customAppointmentControllerProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$customAppointmentControllerHash();

  @$internal
  @override
  CustomAppointmentController create() => CustomAppointmentController();
}

String _$customAppointmentControllerHash() =>
    r'8a2d84ab308345f4b33c194414884872959f2272';

/// Enregistre ou supprime un RDV libre, puis resynchronise rappels et calendrier.

abstract class _$CustomAppointmentController extends $AsyncNotifier<void> {
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
