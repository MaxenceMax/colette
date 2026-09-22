// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'documents_write_controller.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// Ajout d'un document (scan ou import) dans un dossier.

@ProviderFor(DocumentsWriteController)
final documentsWriteControllerProvider = DocumentsWriteControllerProvider._();

/// Ajout d'un document (scan ou import) dans un dossier.
final class DocumentsWriteControllerProvider
    extends $AsyncNotifierProvider<DocumentsWriteController, void> {
  /// Ajout d'un document (scan ou import) dans un dossier.
  DocumentsWriteControllerProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'documentsWriteControllerProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$documentsWriteControllerHash();

  @$internal
  @override
  DocumentsWriteController create() => DocumentsWriteController();
}

String _$documentsWriteControllerHash() =>
    r'd632bf7f1229c5faef80f8776c4169fe15779150';

/// Ajout d'un document (scan ou import) dans un dossier.

abstract class _$DocumentsWriteController extends $AsyncNotifier<void> {
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
