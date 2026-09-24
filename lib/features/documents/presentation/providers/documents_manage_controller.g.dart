// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'documents_manage_controller.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// Création de dossier, renommage, déplacement et suppression dans
/// [folderPath]. Famille par dossier : la page racine et une sous-page
/// poussée observent chacune leur instance. Pas d'invalidation après un
/// succès : Swift reliste les flux des dossiers touchés.

@ProviderFor(DocumentsManageController)
final documentsManageControllerProvider = DocumentsManageControllerFamily._();

/// Création de dossier, renommage, déplacement et suppression dans
/// [folderPath]. Famille par dossier : la page racine et une sous-page
/// poussée observent chacune leur instance. Pas d'invalidation après un
/// succès : Swift reliste les flux des dossiers touchés.
final class DocumentsManageControllerProvider
    extends $AsyncNotifierProvider<DocumentsManageController, void> {
  /// Création de dossier, renommage, déplacement et suppression dans
  /// [folderPath]. Famille par dossier : la page racine et une sous-page
  /// poussée observent chacune leur instance. Pas d'invalidation après un
  /// succès : Swift reliste les flux des dossiers touchés.
  DocumentsManageControllerProvider._({
    required DocumentsManageControllerFamily super.from,
    required String super.argument,
  }) : super(
         retry: null,
         name: r'documentsManageControllerProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$documentsManageControllerHash();

  @override
  String toString() {
    return r'documentsManageControllerProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  DocumentsManageController create() => DocumentsManageController();

  @override
  bool operator ==(Object other) {
    return other is DocumentsManageControllerProvider &&
        other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$documentsManageControllerHash() =>
    r'2232040fd28692da215bed82154222c40b4958d2';

/// Création de dossier, renommage, déplacement et suppression dans
/// [folderPath]. Famille par dossier : la page racine et une sous-page
/// poussée observent chacune leur instance. Pas d'invalidation après un
/// succès : Swift reliste les flux des dossiers touchés.

final class DocumentsManageControllerFamily extends $Family
    with
        $ClassFamilyOverride<
          DocumentsManageController,
          AsyncValue<void>,
          void,
          FutureOr<void>,
          String
        > {
  DocumentsManageControllerFamily._()
    : super(
        retry: null,
        name: r'documentsManageControllerProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  /// Création de dossier, renommage, déplacement et suppression dans
  /// [folderPath]. Famille par dossier : la page racine et une sous-page
  /// poussée observent chacune leur instance. Pas d'invalidation après un
  /// succès : Swift reliste les flux des dossiers touchés.

  DocumentsManageControllerProvider call(String folderPath) =>
      DocumentsManageControllerProvider._(argument: folderPath, from: this);

  @override
  String toString() => r'documentsManageControllerProvider';
}

/// Création de dossier, renommage, déplacement et suppression dans
/// [folderPath]. Famille par dossier : la page racine et une sous-page
/// poussée observent chacune leur instance. Pas d'invalidation après un
/// succès : Swift reliste les flux des dossiers touchés.

abstract class _$DocumentsManageController extends $AsyncNotifier<void> {
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
