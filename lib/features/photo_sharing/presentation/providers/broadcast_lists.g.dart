// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'broadcast_lists.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// Listes de diffusion de cet iPhone. Chaque modification est enregistrée, à
/// la suite de la précédente ; en cas d'échec, l'état reste inchangé et la
/// failure est renvoyée.

@ProviderFor(BroadcastLists)
final broadcastListsProvider = BroadcastListsProvider._();

/// Listes de diffusion de cet iPhone. Chaque modification est enregistrée, à
/// la suite de la précédente ; en cas d'échec, l'état reste inchangé et la
/// failure est renvoyée.
final class BroadcastListsProvider
    extends $AsyncNotifierProvider<BroadcastLists, List<BroadcastList>> {
  /// Listes de diffusion de cet iPhone. Chaque modification est enregistrée, à
  /// la suite de la précédente ; en cas d'échec, l'état reste inchangé et la
  /// failure est renvoyée.
  BroadcastListsProvider._()
    : super(
        from: null,
        argument: null,
        retry: noRetry,
        name: r'broadcastListsProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$broadcastListsHash();

  @$internal
  @override
  BroadcastLists create() => BroadcastLists();
}

String _$broadcastListsHash() => r'f10b3f03d1e1727151aac8ec6d098e89f25e503d';

/// Listes de diffusion de cet iPhone. Chaque modification est enregistrée, à
/// la suite de la précédente ; en cas d'échec, l'état reste inchangé et la
/// failure est renvoyée.

abstract class _$BroadcastLists extends $AsyncNotifier<List<BroadcastList>> {
  FutureOr<List<BroadcastList>> build();
  @$mustCallSuper
  @override
  WhenComplete runBuild() {
    final ref =
        this.ref as $Ref<AsyncValue<List<BroadcastList>>, List<BroadcastList>>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<AsyncValue<List<BroadcastList>>, List<BroadcastList>>,
              AsyncValue<List<BroadcastList>>,
              Object?,
              Object?
            >;
    return element.handleCreate(ref, build);
  }
}
