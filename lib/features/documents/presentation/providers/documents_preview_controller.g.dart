// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'documents_preview_controller.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// Ouverture d'un fichier, une instance par chemin : chaque ligne suit la
/// sienne. Un fichier non téléchargé est d'abord téléchargé ; l'aperçu
/// s'ouvre seul dès que le flux du dossier le dit téléchargé.

@ProviderFor(DocumentsPreviewController)
final documentsPreviewControllerProvider = DocumentsPreviewControllerFamily._();

/// Ouverture d'un fichier, une instance par chemin : chaque ligne suit la
/// sienne. Un fichier non téléchargé est d'abord téléchargé ; l'aperçu
/// s'ouvre seul dès que le flux du dossier le dit téléchargé.
final class DocumentsPreviewControllerProvider
    extends $AsyncNotifierProvider<DocumentsPreviewController, void> {
  /// Ouverture d'un fichier, une instance par chemin : chaque ligne suit la
  /// sienne. Un fichier non téléchargé est d'abord téléchargé ; l'aperçu
  /// s'ouvre seul dès que le flux du dossier le dit téléchargé.
  DocumentsPreviewControllerProvider._({
    required DocumentsPreviewControllerFamily super.from,
    required String super.argument,
  }) : super(
         retry: null,
         name: r'documentsPreviewControllerProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$documentsPreviewControllerHash();

  @override
  String toString() {
    return r'documentsPreviewControllerProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  DocumentsPreviewController create() => DocumentsPreviewController();

  @override
  bool operator ==(Object other) {
    return other is DocumentsPreviewControllerProvider &&
        other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$documentsPreviewControllerHash() =>
    r'66808d19205ccaab14489d97d883ebf5059371dd';

/// Ouverture d'un fichier, une instance par chemin : chaque ligne suit la
/// sienne. Un fichier non téléchargé est d'abord téléchargé ; l'aperçu
/// s'ouvre seul dès que le flux du dossier le dit téléchargé.

final class DocumentsPreviewControllerFamily extends $Family
    with
        $ClassFamilyOverride<
          DocumentsPreviewController,
          AsyncValue<void>,
          void,
          FutureOr<void>,
          String
        > {
  DocumentsPreviewControllerFamily._()
    : super(
        retry: null,
        name: r'documentsPreviewControllerProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  /// Ouverture d'un fichier, une instance par chemin : chaque ligne suit la
  /// sienne. Un fichier non téléchargé est d'abord téléchargé ; l'aperçu
  /// s'ouvre seul dès que le flux du dossier le dit téléchargé.

  DocumentsPreviewControllerProvider call(String path) =>
      DocumentsPreviewControllerProvider._(argument: path, from: this);

  @override
  String toString() => r'documentsPreviewControllerProvider';
}

/// Ouverture d'un fichier, une instance par chemin : chaque ligne suit la
/// sienne. Un fichier non téléchargé est d'abord téléchargé ; l'aperçu
/// s'ouvre seul dès que le flux du dossier le dit téléchargé.

abstract class _$DocumentsPreviewController extends $AsyncNotifier<void> {
  late final _$args = ref.$arg as String;
  String get path => _$args;

  FutureOr<void> build(String path);
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
    return element.handleCreate(ref, () => build(_$args));
  }
}
