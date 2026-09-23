// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'documents_write_controller.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// Ajout d'un document (scan ou import) dans [folderPath].
///
/// Famille par dossier : la page racine et une sous-page poussée observent
/// chacune leur propre instance, sans se déclencher mutuellement.

@ProviderFor(DocumentsWriteController)
final documentsWriteControllerProvider = DocumentsWriteControllerFamily._();

/// Ajout d'un document (scan ou import) dans [folderPath].
///
/// Famille par dossier : la page racine et une sous-page poussée observent
/// chacune leur propre instance, sans se déclencher mutuellement.
final class DocumentsWriteControllerProvider
    extends $AsyncNotifierProvider<DocumentsWriteController, void> {
  /// Ajout d'un document (scan ou import) dans [folderPath].
  ///
  /// Famille par dossier : la page racine et une sous-page poussée observent
  /// chacune leur propre instance, sans se déclencher mutuellement.
  DocumentsWriteControllerProvider._({
    required DocumentsWriteControllerFamily super.from,
    required String super.argument,
  }) : super(
         retry: null,
         name: r'documentsWriteControllerProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$documentsWriteControllerHash();

  @override
  String toString() {
    return r'documentsWriteControllerProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  DocumentsWriteController create() => DocumentsWriteController();

  @override
  bool operator ==(Object other) {
    return other is DocumentsWriteControllerProvider &&
        other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$documentsWriteControllerHash() =>
    r'1ebbc4d905be21a7a5d518fd023108813af8234f';

/// Ajout d'un document (scan ou import) dans [folderPath].
///
/// Famille par dossier : la page racine et une sous-page poussée observent
/// chacune leur propre instance, sans se déclencher mutuellement.

final class DocumentsWriteControllerFamily extends $Family
    with
        $ClassFamilyOverride<
          DocumentsWriteController,
          AsyncValue<void>,
          void,
          FutureOr<void>,
          String
        > {
  DocumentsWriteControllerFamily._()
    : super(
        retry: null,
        name: r'documentsWriteControllerProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  /// Ajout d'un document (scan ou import) dans [folderPath].
  ///
  /// Famille par dossier : la page racine et une sous-page poussée observent
  /// chacune leur propre instance, sans se déclencher mutuellement.

  DocumentsWriteControllerProvider call(String folderPath) =>
      DocumentsWriteControllerProvider._(argument: folderPath, from: this);

  @override
  String toString() => r'documentsWriteControllerProvider';
}

/// Ajout d'un document (scan ou import) dans [folderPath].
///
/// Famille par dossier : la page racine et une sous-page poussée observent
/// chacune leur propre instance, sans se déclencher mutuellement.

abstract class _$DocumentsWriteController extends $AsyncNotifier<void> {
  late final _$args = ref.$arg as String;
  String get folderPath => _$args;

  FutureOr<void> build(String folderPath);
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
