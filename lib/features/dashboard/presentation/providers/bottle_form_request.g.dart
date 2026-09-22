// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'bottle_form_request.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// Demande d'ouverture du formulaire biberon sur Aujourd'hui (arrivée par notification).

@ProviderFor(BottleFormRequest)
final bottleFormRequestProvider = BottleFormRequestProvider._();

/// Demande d'ouverture du formulaire biberon sur Aujourd'hui (arrivée par notification).
final class BottleFormRequestProvider
    extends $NotifierProvider<BottleFormRequest, bool> {
  /// Demande d'ouverture du formulaire biberon sur Aujourd'hui (arrivée par notification).
  BottleFormRequestProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'bottleFormRequestProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$bottleFormRequestHash();

  @$internal
  @override
  BottleFormRequest create() => BottleFormRequest();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(bool value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<bool>(value),
    );
  }
}

String _$bottleFormRequestHash() => r'14af5df0fd6dc0416d94f3bc859c89e78c1432d8';

/// Demande d'ouverture du formulaire biberon sur Aujourd'hui (arrivée par notification).

abstract class _$BottleFormRequest extends $Notifier<bool> {
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
