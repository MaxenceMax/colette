// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'documents_open_in_files_controller.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// Ouverture de l'app Fichiers sur le dossier [path].

@ProviderFor(DocumentsOpenInFilesController)
final documentsOpenInFilesControllerProvider =
    DocumentsOpenInFilesControllerFamily._();

/// Ouverture de l'app Fichiers sur le dossier [path].
final class DocumentsOpenInFilesControllerProvider
    extends $AsyncNotifierProvider<DocumentsOpenInFilesController, void> {
  /// Ouverture de l'app Fichiers sur le dossier [path].
  DocumentsOpenInFilesControllerProvider._({
    required DocumentsOpenInFilesControllerFamily super.from,
    required String super.argument,
  }) : super(
         retry: null,
         name: r'documentsOpenInFilesControllerProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$documentsOpenInFilesControllerHash();

  @override
  String toString() {
    return r'documentsOpenInFilesControllerProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  DocumentsOpenInFilesController create() => DocumentsOpenInFilesController();

  @override
  bool operator ==(Object other) {
    return other is DocumentsOpenInFilesControllerProvider &&
        other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$documentsOpenInFilesControllerHash() =>
    r'a44def9c86955afd32d369518da519759af16703';

/// Ouverture de l'app Fichiers sur le dossier [path].

final class DocumentsOpenInFilesControllerFamily extends $Family
    with
        $ClassFamilyOverride<
          DocumentsOpenInFilesController,
          AsyncValue<void>,
          void,
          FutureOr<void>,
          String
        > {
  DocumentsOpenInFilesControllerFamily._()
    : super(
        retry: null,
        name: r'documentsOpenInFilesControllerProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  /// Ouverture de l'app Fichiers sur le dossier [path].

  DocumentsOpenInFilesControllerProvider call(String path) =>
      DocumentsOpenInFilesControllerProvider._(argument: path, from: this);

  @override
  String toString() => r'documentsOpenInFilesControllerProvider';
}

/// Ouverture de l'app Fichiers sur le dossier [path].

abstract class _$DocumentsOpenInFilesController extends $AsyncNotifier<void> {
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
