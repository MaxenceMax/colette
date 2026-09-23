// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'documents_preview_controller.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// Aperçu d'un fichier, une instance par chemin : chaque ligne suit la sienne.

@ProviderFor(DocumentsPreviewController)
final documentsPreviewControllerProvider = DocumentsPreviewControllerFamily._();

/// Aperçu d'un fichier, une instance par chemin : chaque ligne suit la sienne.
final class DocumentsPreviewControllerProvider
    extends $AsyncNotifierProvider<DocumentsPreviewController, void> {
  /// Aperçu d'un fichier, une instance par chemin : chaque ligne suit la sienne.
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
    r'bd989de6c123be64f8f7ae8f3feacc901dde0aaa';

/// Aperçu d'un fichier, une instance par chemin : chaque ligne suit la sienne.

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

  /// Aperçu d'un fichier, une instance par chemin : chaque ligne suit la sienne.

  DocumentsPreviewControllerProvider call(String path) =>
      DocumentsPreviewControllerProvider._(argument: path, from: this);

  @override
  String toString() => r'documentsPreviewControllerProvider';
}

/// Aperçu d'un fichier, une instance par chemin : chaque ligne suit la sienne.

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
