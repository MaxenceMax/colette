// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'documents_delete_controller.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// Suppression d'un fichier de [folderPath]. Famille par dossier : la page
/// racine et une sous-page poussée observent chacune leur instance.

@ProviderFor(DocumentsDeleteController)
final documentsDeleteControllerProvider = DocumentsDeleteControllerFamily._();

/// Suppression d'un fichier de [folderPath]. Famille par dossier : la page
/// racine et une sous-page poussée observent chacune leur instance.
final class DocumentsDeleteControllerProvider
    extends $AsyncNotifierProvider<DocumentsDeleteController, void> {
  /// Suppression d'un fichier de [folderPath]. Famille par dossier : la page
  /// racine et une sous-page poussée observent chacune leur instance.
  DocumentsDeleteControllerProvider._({
    required DocumentsDeleteControllerFamily super.from,
    required String super.argument,
  }) : super(
         retry: null,
         name: r'documentsDeleteControllerProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$documentsDeleteControllerHash();

  @override
  String toString() {
    return r'documentsDeleteControllerProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  DocumentsDeleteController create() => DocumentsDeleteController();

  @override
  bool operator ==(Object other) {
    return other is DocumentsDeleteControllerProvider &&
        other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$documentsDeleteControllerHash() =>
    r'1c1342ce9bcd73254003f5f1f7a8a76163f3d03c';

/// Suppression d'un fichier de [folderPath]. Famille par dossier : la page
/// racine et une sous-page poussée observent chacune leur instance.

final class DocumentsDeleteControllerFamily extends $Family
    with
        $ClassFamilyOverride<
          DocumentsDeleteController,
          AsyncValue<void>,
          void,
          FutureOr<void>,
          String
        > {
  DocumentsDeleteControllerFamily._()
    : super(
        retry: null,
        name: r'documentsDeleteControllerProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  /// Suppression d'un fichier de [folderPath]. Famille par dossier : la page
  /// racine et une sous-page poussée observent chacune leur instance.

  DocumentsDeleteControllerProvider call(String folderPath) =>
      DocumentsDeleteControllerProvider._(argument: folderPath, from: this);

  @override
  String toString() => r'documentsDeleteControllerProvider';
}

/// Suppression d'un fichier de [folderPath]. Famille par dossier : la page
/// racine et une sous-page poussée observent chacune leur instance.

abstract class _$DocumentsDeleteController extends $AsyncNotifier<void> {
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
