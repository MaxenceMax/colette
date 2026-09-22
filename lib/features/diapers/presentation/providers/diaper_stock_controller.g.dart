// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'diaper_stock_controller.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// Recomptage, ajout de paquet et seuil d'alerte. L'état porte l'échec éventuel.
/// Reçoit le stock courant en paramètre (`null` s'il n'est pas encore renseigné).

@ProviderFor(DiaperStockController)
final diaperStockControllerProvider = DiaperStockControllerProvider._();

/// Recomptage, ajout de paquet et seuil d'alerte. L'état porte l'échec éventuel.
/// Reçoit le stock courant en paramètre (`null` s'il n'est pas encore renseigné).
final class DiaperStockControllerProvider
    extends $AsyncNotifierProvider<DiaperStockController, void> {
  /// Recomptage, ajout de paquet et seuil d'alerte. L'état porte l'échec éventuel.
  /// Reçoit le stock courant en paramètre (`null` s'il n'est pas encore renseigné).
  DiaperStockControllerProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'diaperStockControllerProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$diaperStockControllerHash();

  @$internal
  @override
  DiaperStockController create() => DiaperStockController();
}

String _$diaperStockControllerHash() =>
    r'e4bda14f554cba07df269f22f62c5b2aa8cfa3d3';

/// Recomptage, ajout de paquet et seuil d'alerte. L'état porte l'échec éventuel.
/// Reçoit le stock courant en paramètre (`null` s'il n'est pas encore renseigné).

abstract class _$DiaperStockController extends $AsyncNotifier<void> {
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
