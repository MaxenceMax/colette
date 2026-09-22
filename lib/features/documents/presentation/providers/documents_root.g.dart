// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'documents_root.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// Dossier racine choisi sur cet iPhone ; `null` tant qu'aucun n'est choisi.

@ProviderFor(DocumentsRoot)
final documentsRootProvider = DocumentsRootProvider._();

/// Dossier racine choisi sur cet iPhone ; `null` tant qu'aucun n'est choisi.
final class DocumentsRootProvider
    extends $AsyncNotifierProvider<DocumentsRoot, DocumentRoot?> {
  /// Dossier racine choisi sur cet iPhone ; `null` tant qu'aucun n'est choisi.
  DocumentsRootProvider._()
    : super(
        from: null,
        argument: null,
        retry: _noRetry,
        name: r'documentsRootProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$documentsRootHash();

  @$internal
  @override
  DocumentsRoot create() => DocumentsRoot();
}

String _$documentsRootHash() => r'b4a41496e0854f0bfe762446adc64a5223aa6ffa';

/// Dossier racine choisi sur cet iPhone ; `null` tant qu'aucun n'est choisi.

abstract class _$DocumentsRoot extends $AsyncNotifier<DocumentRoot?> {
  FutureOr<DocumentRoot?> build();
  @$mustCallSuper
  @override
  WhenComplete runBuild() {
    final ref = this.ref as $Ref<AsyncValue<DocumentRoot?>, DocumentRoot?>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<AsyncValue<DocumentRoot?>, DocumentRoot?>,
              AsyncValue<DocumentRoot?>,
              Object?,
              Object?
            >;
    return element.handleCreate(ref, build);
  }
}
