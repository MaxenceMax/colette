// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'documents_providers.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// Sans état : `keepAlive` car consommé par `DocumentsRoot` (keepAlive).

@ProviderFor(documentsRepository)
final documentsRepositoryProvider = DocumentsRepositoryProvider._();

/// Sans état : `keepAlive` car consommé par `DocumentsRoot` (keepAlive).

final class DocumentsRepositoryProvider
    extends
        $FunctionalProvider<
          DocumentsRepository,
          DocumentsRepository,
          DocumentsRepository
        >
    with $Provider<DocumentsRepository> {
  /// Sans état : `keepAlive` car consommé par `DocumentsRoot` (keepAlive).
  DocumentsRepositoryProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'documentsRepositoryProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$documentsRepositoryHash();

  @$internal
  @override
  $ProviderElement<DocumentsRepository> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  DocumentsRepository create(Ref ref) {
    return documentsRepository(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(DocumentsRepository value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<DocumentsRepository>(value),
    );
  }
}

String _$documentsRepositoryHash() =>
    r'85ff530253486b5adf67353cf5ebf7c84fa8b82c';

/// Contenu trié d'un dossier, en direct, [path] relatif à la racine (`''` =
/// racine). Chaque liste reçue est triée ; un `Left` est relancé pour que
/// l'UI le reçoive en `AsyncError`. `retry` désactivé : une
/// `DocumentsFailure` doit remonter immédiatement.

@ProviderFor(documentsFolder)
final documentsFolderProvider = DocumentsFolderFamily._();

/// Contenu trié d'un dossier, en direct, [path] relatif à la racine (`''` =
/// racine). Chaque liste reçue est triée ; un `Left` est relancé pour que
/// l'UI le reçoive en `AsyncError`. `retry` désactivé : une
/// `DocumentsFailure` doit remonter immédiatement.

final class DocumentsFolderProvider
    extends
        $FunctionalProvider<
          AsyncValue<List<DocumentEntry>>,
          List<DocumentEntry>,
          Stream<List<DocumentEntry>>
        >
    with
        $FutureModifier<List<DocumentEntry>>,
        $StreamProvider<List<DocumentEntry>> {
  /// Contenu trié d'un dossier, en direct, [path] relatif à la racine (`''` =
  /// racine). Chaque liste reçue est triée ; un `Left` est relancé pour que
  /// l'UI le reçoive en `AsyncError`. `retry` désactivé : une
  /// `DocumentsFailure` doit remonter immédiatement.
  DocumentsFolderProvider._({
    required DocumentsFolderFamily super.from,
    required String super.argument,
  }) : super(
         retry: noRetry,
         name: r'documentsFolderProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$documentsFolderHash();

  @override
  String toString() {
    return r'documentsFolderProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  $StreamProviderElement<List<DocumentEntry>> $createElement(
    $ProviderPointer pointer,
  ) => $StreamProviderElement(pointer);

  @override
  Stream<List<DocumentEntry>> create(Ref ref) {
    final argument = this.argument as String;
    return documentsFolder(ref, argument);
  }

  @override
  bool operator ==(Object other) {
    return other is DocumentsFolderProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$documentsFolderHash() => r'f8599713615773885ebcc1e84528455ad96e5d4b';

/// Contenu trié d'un dossier, en direct, [path] relatif à la racine (`''` =
/// racine). Chaque liste reçue est triée ; un `Left` est relancé pour que
/// l'UI le reçoive en `AsyncError`. `retry` désactivé : une
/// `DocumentsFailure` doit remonter immédiatement.

final class DocumentsFolderFamily extends $Family
    with $FunctionalFamilyOverride<Stream<List<DocumentEntry>>, String> {
  DocumentsFolderFamily._()
    : super(
        retry: noRetry,
        name: r'documentsFolderProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  /// Contenu trié d'un dossier, en direct, [path] relatif à la racine (`''` =
  /// racine). Chaque liste reçue est triée ; un `Left` est relancé pour que
  /// l'UI le reçoive en `AsyncError`. `retry` désactivé : une
  /// `DocumentsFailure` doit remonter immédiatement.

  DocumentsFolderProvider call(String path) =>
      DocumentsFolderProvider._(argument: path, from: this);

  @override
  String toString() => r'documentsFolderProvider';
}
