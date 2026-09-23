// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'medical_visit_controller.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// Enregistre une visite (ou la supprime si elle est vide) puis resynchronise.

@ProviderFor(MedicalVisitController)
final medicalVisitControllerProvider = MedicalVisitControllerProvider._();

/// Enregistre une visite (ou la supprime si elle est vide) puis resynchronise.
final class MedicalVisitControllerProvider
    extends $AsyncNotifierProvider<MedicalVisitController, void> {
  /// Enregistre une visite (ou la supprime si elle est vide) puis resynchronise.
  MedicalVisitControllerProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'medicalVisitControllerProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$medicalVisitControllerHash();

  @$internal
  @override
  MedicalVisitController create() => MedicalVisitController();
}

String _$medicalVisitControllerHash() =>
    r'293c7c5591e9d950aabe8232a379e352ff01d9ea';

/// Enregistre une visite (ou la supprime si elle est vide) puis resynchronise.

abstract class _$MedicalVisitController extends $AsyncNotifier<void> {
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
