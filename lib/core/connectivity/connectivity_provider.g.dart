// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'connectivity_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// `true` tant qu'au moins une interface réseau est disponible.
/// Émet d'abord l'état courant, puis chaque changement.

@ProviderFor(isOnline)
final isOnlineProvider = IsOnlineProvider._();

/// `true` tant qu'au moins une interface réseau est disponible.
/// Émet d'abord l'état courant, puis chaque changement.

final class IsOnlineProvider
    extends $FunctionalProvider<AsyncValue<bool>, bool, Stream<bool>>
    with $FutureModifier<bool>, $StreamProvider<bool> {
  /// `true` tant qu'au moins une interface réseau est disponible.
  /// Émet d'abord l'état courant, puis chaque changement.
  IsOnlineProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'isOnlineProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$isOnlineHash();

  @$internal
  @override
  $StreamProviderElement<bool> $createElement($ProviderPointer pointer) =>
      $StreamProviderElement(pointer);

  @override
  Stream<bool> create(Ref ref) {
    return isOnline(ref);
  }
}

String _$isOnlineHash() => r'3feb5aac2ef2bf93acd29bdbb4821ed52ddec3b4';
