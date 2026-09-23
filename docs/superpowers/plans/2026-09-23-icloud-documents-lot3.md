# Documents iCloud, lot 3 : flux en direct, suppression, ouverture dans Fichiers — plan d'implémentation

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Remplacer la liste figée d'un dossier par un flux natif alimenté par `NSMetadataQuery` (statuts et progression de téléchargement en direct), découpler le téléchargement de l'aperçu, et ajouter la suppression d'un fichier et un bouton « Ouvrir dans Fichiers ».

**Architecture:** Spec : `docs/superpowers/specs/2026-09-22-icloud-documents-design.md`, sections 3, 5, 6, 7, 8 et 11 (mentions « lot 3 »). Flutter : `DocumentsRepository.watch(path)` (flux d'`Either`) remplace `list(path)` ; `documentsFolderProvider` devient un provider de flux ; `DocumentsPreviewController.open(entry)` télécharge puis ouvre ; deux contrôleurs ajoutés (suppression, ouverture). Swift : `openFolderStream` crée un `FlutterEventChannel` par abonnement (`colette/documents/folder/{n}`) piloté par un `DocumentsFolderWatcher` ; `preview` n'attend plus ; méthodes `download`, `delete`, `openInFiles`.

**Tech Stack:** Flutter 3.47 / Dart 3.13, Riverpod 3 codegen, freezed, fpdart, mocktail, `MockStreamHandler` de `flutter_test` ; Swift : `NSMetadataQuery`, `FlutterEventChannel`, `NSFileCoordinator`, `UIApplication.open`.

**Branche :** `feat/icloud-documents`, worktree `.claude/worktrees/icloud-documents`. Toutes les commandes se lancent depuis le worktree. Après chaque fichier annoté (`@riverpod`, `@freezed`) : `dart run build_runner build -d`. Avant chaque commit : `dart format lib test`, `dart analyze`, `flutter test` (le fichier ou le dossier touché suffit en cours de tâche ; la suite complète en fin de tâche).

**Pourquoi un canal par abonnement.** Un `FlutterEventChannel` n'a qu'un abonné à la fois : un second `listen` sur le même nom annule le premier côté moteur. La page racine et une sous-page poussée observent chacune leur dossier en même temps, donc chaque abonnement a son propre canal, nommé par Swift à la demande (`openFolderStream` → `{channel: 'colette/documents/folder/3'}`). Flutter n'en voit rien : `watch(path)` reste un simple flux.

---

## Fichiers

- Domaine : `lib/features/documents/domain/entities/document_entry.dart` (champ `downloadProgress`), `lib/features/documents/domain/use_cases/parent_path.dart` (nouveau), `lib/features/documents/domain/repositories/documents_repository.dart`.
- Data : `lib/features/documents/data/dtos/document_entry_dto.dart`, `lib/features/documents/data/native_documents_repository.dart`.
- Providers : `documents_providers.dart` (flux), `documents_preview_controller.dart` (`open`), `documents_write_controller.dart` (plus d'invalidation), `documents_delete_controller.dart` (nouveau), `documents_open_in_files_controller.dart` (nouveau).
- Widgets : `document_entry_tile.dart` (progression, `open`), `document_delete_dismissible.dart` (nouveau), `documents_open_in_files_button.dart` (nouveau), `pages/documents_page.dart`.
- L10n : `lib/l10n/app_fr.arb` (5 clés).
- Swift : `ios/Runner/Documents/DocumentsFolderWatcher.swift` (nouveau), `DocumentsPlugin.swift`, `DocumentsLister.swift`, `DocumentsWriter.swift`.
- Tests : `test/features/documents/domain/parent_path_test.dart` (nouveau), `test/features/documents/data/document_entry_dto_test.dart`, `test/features/documents/data/native_documents_repository_test.dart`, `test/features/documents/presentation/documents_providers_test.dart`, `documents_preview_controller_test.dart`, `documents_write_controller_test.dart`, `documents_root_test.dart`, `documents_page_test.dart`, `documents_delete_controller_test.dart` (nouveau), `documents_open_in_files_controller_test.dart` (nouveau).
- Docs : spec (section 5), `README.md`, ce plan.

---

### Task 1 : `downloadProgress` sur l'entité, `parentPath`, DTO

**Files:**
- Modify: `lib/features/documents/domain/entities/document_entry.dart`
- Create: `lib/features/documents/domain/use_cases/parent_path.dart`
- Modify: `lib/features/documents/data/dtos/document_entry_dto.dart`
- Test: `test/features/documents/domain/parent_path_test.dart`, `test/features/documents/data/document_entry_dto_test.dart`

- [x] **Step 1 : tests rouges**

Créer `test/features/documents/domain/parent_path_test.dart` :

```dart
import 'package:colette/features/documents/domain/use_cases/parent_path.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('parentPath renvoie le dossier contenant', () {
    expect(parentPath('Ordonnances/2026/a.pdf'), 'Ordonnances/2026');
    expect(parentPath('Ordonnances/a.pdf'), 'Ordonnances');
  });

  test('parentPath renvoie la racine pour un chemin sans séparateur', () {
    expect(parentPath('a.pdf'), '');
    expect(parentPath(''), '');
  });
}
```

Ajouter à la fin de `main()` dans `test/features/documents/data/document_entry_dto_test.dart` :

```dart
  test('fromMap lit downloadProgress, borné entre 0 et 1', () {
    expect(
      DocumentEntryDto.fromMap({
        ...map(status: 'downloading'),
        'downloadProgress': 0.42,
      }).downloadProgress,
      0.42,
    );
    expect(
      DocumentEntryDto.fromMap({
        ...map(status: 'downloading'),
        'downloadProgress': 1.7,
      }).downloadProgress,
      1.0,
    );
    expect(
      DocumentEntryDto.fromMap({
        ...map(status: 'downloading'),
        'downloadProgress': -3,
      }).downloadProgress,
      0.0,
    );
  });

  test('fromMap laisse downloadProgress null quand absent', () {
    expect(DocumentEntryDto.fromMap(map()).downloadProgress, isNull);
  });
```

- [x] **Step 2 : vérifier l'échec**

Run: `flutter test test/features/documents/domain/parent_path_test.dart test/features/documents/data/document_entry_dto_test.dart`
Expected: échec de compilation (`parent_path.dart` introuvable, `downloadProgress` inconnu).

- [x] **Step 3 : implémentation**

`lib/features/documents/domain/use_cases/parent_path.dart` :

```dart
/// Dossier contenant [path] (chemin relatif à la racine) ; `''` à la racine.
String parentPath(String path) {
  final index = path.lastIndexOf('/');
  return index < 0 ? '' : path.substring(0, index);
}
```

`lib/features/documents/domain/entities/document_entry.dart` — ajouter le champ après `downloadStatus` :

```dart
/// Entrée d'un dossier : sous-dossier ou fichier, avec son chemin relatif à la racine.
@freezed
abstract class DocumentEntry with _$DocumentEntry {
  const factory DocumentEntry({
    required String name,
    required String path,
    required bool isDirectory,
    required int size,
    required DateTime modifiedAt,
    required DownloadStatus downloadStatus,

    /// Progression du téléchargement iCloud (0 à 1), `null` hors téléchargement.
    double? downloadProgress,
  }) = _DocumentEntry;
}
```

`lib/features/documents/data/dtos/document_entry_dto.dart` — ajouter dans `fromMap`, après `downloadStatus` :

```dart
    downloadProgress: switch (map['downloadProgress']) {
      final num value => value.toDouble().clamp(0.0, 1.0),
      _ => null,
    },
```

- [x] **Step 4 : régénérer et vérifier**

Run: `dart run build_runner build -d && flutter test test/features/documents`
Expected: tout passe (le champ optionnel ne casse aucun constructeur existant).

- [x] **Step 5 : commit**

```bash
git add lib/features/documents/domain lib/features/documents/data/dtos test/features/documents/domain test/features/documents/data/document_entry_dto_test.dart
git commit -m "feat: progression de téléchargement sur DocumentEntry, parentPath"
```

---

### Task 2 : repository — `watch`, `download`, `delete`, `openInFiles` (ajout, `list` conservé pour l'instant)

**Files:**
- Modify: `lib/features/documents/domain/repositories/documents_repository.dart`
- Modify: `lib/features/documents/data/native_documents_repository.dart`
- Test: `test/features/documents/data/native_documents_repository_test.dart`

- [x] **Step 1 : tests rouges**

Dans `test/features/documents/data/native_documents_repository_test.dart`, ajouter les imports :

```dart
import 'dart:async';

import 'package:colette/features/documents/domain/entities/document_entry.dart';
import 'package:fpdart/fpdart.dart';
```

Ajouter, après `tearDown`, un helper de flux et les tests suivants (avant la boucle `for (final (code, reason) …)`) :

```dart
  const folderChannel = EventChannel('colette/documents/folder/test');

  /// Mock `openFolderStream` → canal de test, et le handler du flux.
  void mockFolderStream(
    MockStreamHandler handler, {
    Object? Function(MethodCall call)? methods,
  }) {
    mock((call) {
      if (call.method == 'openFolderStream') {
        return {'channel': folderChannel.name};
      }
      return methods?.call(call);
    });
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockStreamHandler(folderChannel, handler);
  }

  Map<String, Object?> rawEntry(String name, {double? progress}) => {
    'name': name,
    'path': 'Ordonnances/$name',
    'isDirectory': false,
    'size': 10,
    'modifiedAt': 1000,
    'downloadStatus': progress == null ? 'downloaded' : 'downloading',
    if (progress != null) 'downloadProgress': progress,
  };

  test('watch ouvre un canal pour le chemin et mappe chaque liste', () async {
    mockFolderStream(
      MockStreamHandler.inline(
        onListen: (_, events) {
          events.success([rawEntry('a.pdf')]);
          events.success([rawEntry('a.pdf'), rawEntry('b.pdf', progress: 0.5)]);
          events.endOfStream();
        },
      ),
    );
    final results = await repo.watch('Ordonnances').toList();
    expect(calls.single.method, 'openFolderStream');
    expect(calls.single.arguments, {'path': 'Ordonnances'});
    expect(results, hasLength(2));
    final second = results[1].toNullable()!;
    expect(second.map((e) => e.name), ['a.pdf', 'b.pdf']);
    expect(second[1].downloadProgress, 0.5);
  });

  test('watch convertit une erreur du flux en Left puis se termine', () async {
    mockFolderStream(
      MockStreamHandler.inline(
        onListen: (_, events) {
          events.success([rawEntry('a.pdf')]);
          events.error(code: 'accessDenied');
        },
      ),
    );
    final results = await repo.watch('Ordonnances').toList();
    expect(results[0].isRight(), isTrue);
    expect(
      results[1].getLeft().toNullable(),
      const DocumentsFailure(DocumentsReason.accessDenied),
    );
  });

  test('watch renvoie Left si openFolderStream échoue', () async {
    mock((_) => throw PlatformException(code: 'noFolder'));
    final results = await repo.watch('').toList();
    expect(
      results.single.getLeft().toNullable(),
      const DocumentsFailure(DocumentsReason.noFolder),
    );
  });

  test('watch propage le désabonnement', () async {
    var cancelled = false;
    mockFolderStream(
      MockStreamHandler.inline(
        onListen: (_, events) => events.success([rawEntry('a.pdf')]),
        onCancel: (_) => cancelled = true,
      ),
    );
    final first = await repo.watch('Ordonnances').first;
    expect(first.isRight(), isTrue);
    // `first` annule l'abonnement dès le premier événement.
    await Future<void>.delayed(Duration.zero);
    expect(cancelled, isTrue);
  });

  test('watch : entrée malformée → Left UnknownFailure', () async {
    mockFolderStream(
      MockStreamHandler.inline(
        onListen: (_, events) => events.success([
          {'name': 1},
        ]),
      ),
    );
    final results = await repo.watch('').toList();
    expect(results.single.getLeft().toNullable(), isA<UnknownFailure>());
  });

  test('download transmet le chemin', () async {
    mock((_) => null);
    final result = await repo.download('a.pdf');
    expect(result.isRight(), isTrue);
    expect(calls.single.method, 'download');
    expect(calls.single.arguments, {'path': 'a.pdf'});
  });

  test('delete transmet le chemin', () async {
    mock((_) => null);
    final result = await repo.delete('Ordonnances/a.pdf');
    expect(result.isRight(), isTrue);
    expect(calls.single.method, 'delete');
    expect(calls.single.arguments, {'path': 'Ordonnances/a.pdf'});
  });

  test('openInFiles transmet le chemin', () async {
    mock((_) => null);
    final result = await repo.openInFiles('Ordonnances');
    expect(result.isRight(), isTrue);
    expect(calls.single.method, 'openInFiles');
    expect(calls.single.arguments, {'path': 'Ordonnances'});
  });

  test('delete : code io → DocumentsFailure.io', () async {
    mock((_) => throw PlatformException(code: 'io'));
    final result = await repo.delete('Ordonnances');
    expect(
      result.getLeft().toNullable(),
      const DocumentsFailure(DocumentsReason.io),
    );
  });
```

Note : `List<Either<Failure, List<DocumentEntry>>>` est le type de `results` ; l'import de `DocumentEntry` sert à l'inférence si l'analyseur le demande, sinon le retirer.

- [x] **Step 2 : vérifier l'échec**

Run: `flutter test test/features/documents/data/native_documents_repository_test.dart`
Expected: échec de compilation (`watch`, `download`, `delete`, `openInFiles` inconnus).

- [x] **Step 3 : interface**

`lib/features/documents/domain/repositories/documents_repository.dart` — ajouter après `list` :

```dart
  /// Contenu d'un dossier en direct : une liste complète (non triée) à chaque
  /// changement iCloud. Un `Left` est suivi de la fin du flux.
  Stream<Either<Failure, List<DocumentEntry>>> watch(String path);

  /// Lance le téléchargement iCloud du fichier et rend la main aussitôt.
  Future<Either<Failure, void>> download(String path);

  /// Supprime un fichier (jamais un dossier) ; iCloud le garde trente jours
  /// dans « Récemment supprimés ».
  Future<Either<Failure, void>> delete(String path);

  /// Ouvre l'app Fichiers sur ce dossier.
  Future<Either<Failure, void>> openInFiles(String path);
```

- [x] **Step 4 : implémentation native**

Remplacer `lib/features/documents/data/native_documents_repository.dart` en entier :

```dart
import 'dart:developer' as developer;

import 'package:colette/core/result/failure.dart';
import 'package:colette/features/documents/data/dtos/document_entry_dto.dart';
import 'package:colette/features/documents/domain/entities/document_entry.dart';
import 'package:colette/features/documents/domain/entities/document_root.dart';
import 'package:colette/features/documents/domain/repositories/documents_repository.dart';
import 'package:flutter/services.dart';
import 'package:fpdart/fpdart.dart';

const _reasons = {
  'noFolder': DocumentsReason.noFolder,
  'accessDenied': DocumentsReason.accessDenied,
  'cancelled': DocumentsReason.cancelled,
  'io': DocumentsReason.io,
};

/// Repository documents adossé au pont Swift : un [MethodChannel] pour les
/// appels, un [EventChannel] par dossier observé (nom fourni par Swift).
class NativeDocumentsRepository implements DocumentsRepository {
  const NativeDocumentsRepository(this._channel);

  /// Nom du canal de méthodes, partagé avec `DocumentsPlugin.swift`.
  static const channelName = 'colette/documents';

  final MethodChannel _channel;

  /// `PlatformException` → [DocumentsFailure] selon le code, sinon
  /// [UnknownFailure] avec un log.
  Failure _failure(Object error, StackTrace stackTrace) {
    if (error is PlatformException) {
      final reason = _reasons[error.code];
      if (reason != null) return DocumentsFailure(reason);
    }
    developer.log(
      'Documents natif',
      error: error,
      stackTrace: stackTrace,
      name: 'colette',
    );
    return UnknownFailure(error, stackTrace);
  }

  /// Comme `guard()`, avec le mapping des codes du canal en [DocumentsFailure].
  Future<Either<Failure, T>> _call<T>(Future<T> Function() action) async {
    try {
      return right(await action());
    } catch (e, stackTrace) {
      return left(_failure(e, stackTrace));
    }
  }

  DocumentRoot _root(Map<String, Object?> map) =>
      DocumentRoot(name: map['name'] as String);

  List<DocumentEntry> _entries(Object? raw) => [
    for (final item in (raw as List<Object?>?) ?? const [])
      DocumentEntryDto.fromMap(item! as Map<Object?, Object?>),
  ];

  @override
  Future<Either<Failure, DocumentRoot?>> rootFolder() => _call(() async {
    final map = await _channel.invokeMapMethod<String, Object?>('rootFolder');
    return map == null ? null : _root(map);
  });

  @override
  Future<Either<Failure, DocumentRoot>> pickRootFolder() => _call(() async {
    final map = await _channel.invokeMapMethod<String, Object?>(
      'pickRootFolder',
    );
    return _root(map!);
  });

  @override
  Future<Either<Failure, void>> forgetRootFolder() =>
      _call(() => _channel.invokeMethod<void>('forgetRootFolder'));

  @override
  Future<Either<Failure, List<DocumentEntry>>> list(String path) =>
      _call(() async {
        final raw = await _channel.invokeListMethod<Object?>('list', {
          'path': path,
        });
        return _entries(raw);
      });

  @override
  Stream<Either<Failure, List<DocumentEntry>>> watch(String path) async* {
    try {
      final map = await _channel.invokeMapMethod<String, Object?>(
        'openFolderStream',
        {'path': path},
      );
      final channel = EventChannel(map!['channel'] as String);
      await for (final raw in channel.receiveBroadcastStream()) {
        yield right(_entries(raw));
      }
    } catch (e, stackTrace) {
      yield left(_failure(e, stackTrace));
    }
  }

  @override
  Future<Either<Failure, void>> download(String path) =>
      _call(() => _channel.invokeMethod<void>('download', {'path': path}));

  @override
  Future<Either<Failure, void>> preview(String path) =>
      _call(() => _channel.invokeMethod<void>('preview', {'path': path}));

  @override
  Future<Either<Failure, void>> delete(String path) =>
      _call(() => _channel.invokeMethod<void>('delete', {'path': path}));

  @override
  Future<Either<Failure, void>> openInFiles(String path) =>
      _call(() => _channel.invokeMethod<void>('openInFiles', {'path': path}));

  @override
  Future<Either<Failure, String>> scan({
    required String folderPath,
    required String fileName,
  }) => _call(() async {
    final map = await _channel.invokeMapMethod<String, Object?>('scan', {
      'path': folderPath,
      'fileName': fileName,
    });
    return map!['name'] as String;
  });

  @override
  Future<Either<Failure, String>> importFile({required String folderPath}) =>
      _call(() async {
        final map = await _channel.invokeMapMethod<String, Object?>(
          'importFile',
          {'path': folderPath},
        );
        return map!['name'] as String;
      });
}
```

Le `try/catch` de `watch` couvre l'appel de méthode, l'abonnement et le mapping : une erreur du flux (`PlatformException` émise par `receiveBroadcastStream`) sort de `await for` comme une exception, devient un `Left`, et le générateur se termine. Le `EventChannel` est créé à partir du nom renvoyé par Swift ; en test, `setMockStreamHandler` sur ce même nom suffit.

- [x] **Step 5 : vérifier**

Run: `dart analyze && flutter test test/features/documents/data`
Expected: 0 problème, tout passe. Si `dart analyze` signale l'import de `DocumentEntry` inutilisé dans le test, le retirer.

- [x] **Step 6 : commit**

```bash
git add lib/features/documents/domain/repositories lib/features/documents/data test/features/documents/data
git commit -m "feat: flux d'un dossier, download, delete et openInFiles dans le repository documents"
```

---

### Task 3 : provider de dossier en flux, plus d'invalidation à l'écriture, retrait de `list`

**Files:**
- Modify: `lib/features/documents/presentation/providers/documents_providers.dart`
- Modify: `lib/features/documents/presentation/providers/documents_write_controller.dart`
- Modify: `lib/features/documents/domain/repositories/documents_repository.dart` (retirer `list`)
- Modify: `lib/features/documents/data/native_documents_repository.dart` (retirer `list`)
- Test: `test/features/documents/presentation/documents_providers_test.dart`, `documents_write_controller_test.dart`, `documents_root_test.dart`, `documents_page_test.dart`, `test/features/documents/data/native_documents_repository_test.dart`

- [x] **Step 1 : tests du provider (rouges)**

Remplacer `test/features/documents/presentation/documents_providers_test.dart` :

```dart
import 'dart:async';

import 'package:colette/core/result/failure.dart';
import 'package:colette/features/documents/domain/entities/document_entry.dart';
import 'package:colette/features/documents/domain/entities/download_status.dart';
import 'package:colette/features/documents/domain/repositories/documents_repository.dart';
import 'package:colette/features/documents/presentation/providers/documents_providers.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:mocktail/mocktail.dart';

class MockDocumentsRepository extends Mock implements DocumentsRepository {}

DocumentEntry entry(String name, {bool isDirectory = false}) => DocumentEntry(
  name: name,
  path: name,
  isDirectory: isDirectory,
  size: 0,
  modifiedAt: DateTime(2026, 9, 1),
  downloadStatus: DownloadStatus.downloaded,
);

void main() {
  late MockDocumentsRepository repo;
  late ProviderContainer container;

  setUp(() {
    repo = MockDocumentsRepository();
    container = ProviderContainer(
      overrides: [documentsRepositoryProvider.overrideWithValue(repo)],
    );
    addTearDown(container.dispose);
  });

  test('documentsFolder trie chaque liste reçue', () async {
    final events = StreamController<Either<Failure, List<DocumentEntry>>>();
    addTearDown(events.close);
    when(() => repo.watch('Ordonnances')).thenAnswer((_) => events.stream);
    final seen = <List<String>>[];
    container.listen(documentsFolderProvider('Ordonnances'), (_, next) {
      if (next case AsyncData(:final value)) {
        seen.add(value.map((e) => e.name).toList());
      }
    });

    events.add(right([entry('z.pdf'), entry('Sous', isDirectory: true)]));
    await Future<void>.delayed(Duration.zero);
    events.add(right([entry('a.pdf')]));
    await Future<void>.delayed(Duration.zero);

    expect(seen, [
      ['Sous', 'z.pdf'],
      ['a.pdf'],
    ]);
  });

  test('documentsFolder relance la failure', () async {
    when(() => repo.watch('')).thenAnswer(
      (_) => Stream.value(left(const DocumentsFailure(DocumentsReason.io))),
    );
    await expectLater(
      container.read(documentsFolderProvider('').future),
      throwsA(const DocumentsFailure(DocumentsReason.io)),
    );
  });

  test('documentsFolder garde la dernière liste après un Left', () async {
    final events = StreamController<Either<Failure, List<DocumentEntry>>>();
    addTearDown(events.close);
    when(() => repo.watch('')).thenAnswer((_) => events.stream);
    container.listen(documentsFolderProvider(''), (_, _) {});

    events.add(right([entry('a.pdf')]));
    await Future<void>.delayed(Duration.zero);
    events.add(left(const DocumentsFailure(DocumentsReason.accessDenied)));
    await Future<void>.delayed(Duration.zero);

    final state = container.read(documentsFolderProvider(''));
    expect(state.hasError, isTrue);
    expect(state.value?.single.name, 'a.pdf');
  });

  test('invalider réabonne le flux', () async {
    when(() => repo.watch('')).thenAnswer(
      (_) => Stream.value(right([entry('a.pdf')])),
    );
    container.listen(documentsFolderProvider(''), (_, _) {});
    await container.read(documentsFolderProvider('').future);
    container.invalidate(documentsFolderProvider(''));
    await container.read(documentsFolderProvider('').future);
    verify(() => repo.watch('')).called(2);
  });
}
```

- [x] **Step 2 : provider**

Dans `lib/features/documents/presentation/providers/documents_providers.dart`, remplacer `documentsFolder` :

```dart
/// Contenu trié d'un dossier, en direct, [path] relatif à la racine (`''` =
/// racine). Chaque liste reçue est triée ; un `Left` est relancé pour que
/// l'UI le reçoive en `AsyncError`. `retry` désactivé : une
/// `DocumentsFailure` doit remonter immédiatement.
@Riverpod(retry: noRetry)
Stream<List<DocumentEntry>> documentsFolder(Ref ref, String path) => ref
    .watch(documentsRepositoryProvider)
    .watch(path)
    .map(
      (result) => result.fold((failure) => throw failure, sortDocumentEntries),
    );
```

Run: `dart run build_runner build -d && flutter test test/features/documents/presentation/documents_providers_test.dart`
Expected: 4 tests verts.

- [x] **Step 3 : contrôleur d'écriture sans invalidation**

Dans `documents_write_controller.dart`, remplacer la branche succès de `_run` :

```dart
      // Pas d'invalidation : Swift force le relistage du flux du dossier
      // après chaque écriture réussie. Une invalidation créerait un second
      // abonnement concurrent.
      (_) => const AsyncData(null),
```

et retirer l'import de `documents_providers.dart` s'il devient inutilisé (il reste utilisé pour `documentsRepositoryProvider`).

Remplacer `test/features/documents/presentation/documents_write_controller_test.dart` :

```dart
import 'package:colette/core/clock/app_clock.dart';
import 'package:colette/core/result/failure.dart';
import 'package:colette/features/documents/domain/repositories/documents_repository.dart';
import 'package:colette/features/documents/presentation/providers/documents_providers.dart';
import 'package:colette/features/documents/presentation/providers/documents_write_controller.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:mocktail/mocktail.dart';

class MockDocumentsRepository extends Mock implements DocumentsRepository {}

void main() {
  late MockDocumentsRepository repo;
  late ProviderContainer container;

  setUp(() {
    repo = MockDocumentsRepository();
    when(
      () => repo.watch(any()),
    ).thenAnswer((_) => Stream.value(right(const [])));
    container = ProviderContainer(
      overrides: [
        documentsRepositoryProvider.overrideWithValue(repo),
        clockProvider.overrideWithValue(
          FixedClock(DateTime(2026, 9, 22, 14, 32)),
        ),
      ],
    );
    addTearDown(container.dispose);
    // Garde les instances utilisées par les tests vivantes (autoDispose)
    // pendant leurs await.
    container.listen(
      documentsWriteControllerProvider('Ordonnances'),
      (_, _) {},
    );
    container.listen(documentsWriteControllerProvider(''), (_, _) {});
    container.listen(documentsFolderProvider('Ordonnances'), (_, _) {});
  });

  DocumentsWriteController controller(String folderPath) =>
      container.read(documentsWriteControllerProvider(folderPath).notifier);

  test('scan nomme le fichier avec l\'horloge, sans réabonner la liste', () async {
    when(
      () => repo.scan(
        folderPath: 'Ordonnances',
        fileName: 'Scan 22-09-2026 14h32.pdf',
      ),
    ).thenAnswer((_) async => right('Scan 22-09-2026 14h32.pdf'));
    await container.read(documentsFolderProvider('Ordonnances').future);

    await controller('Ordonnances').scan();

    // Le relistage vient du flux natif, pas d'une invalidation Flutter.
    verify(() => repo.watch('Ordonnances')).called(1);
    expect(
      container
          .read(documentsWriteControllerProvider('Ordonnances'))
          .hasError,
      isFalse,
    );
  });

  test('importFile transmet le dossier', () async {
    when(() => repo.importFile(folderPath: 'Ordonnances'))
        .thenAnswer((_) async => right('facture.pdf'));
    await controller('Ordonnances').importFile();
    verify(() => repo.importFile(folderPath: 'Ordonnances')).called(1);
    expect(
      container
          .read(documentsWriteControllerProvider('Ordonnances'))
          .hasError,
      isFalse,
    );
  });

  test('cancelled ne produit pas d\'erreur', () async {
    when(() => repo.importFile(folderPath: '')).thenAnswer(
      (_) async => left(const DocumentsFailure(DocumentsReason.cancelled)),
    );
    await controller('').importFile();
    expect(
      container.read(documentsWriteControllerProvider('')).hasError,
      isFalse,
    );
  });

  test('io passe en erreur', () async {
    when(
      () => repo.importFile(folderPath: ''),
    ).thenAnswer((_) async => left(const DocumentsFailure(DocumentsReason.io)));
    await controller('').importFile();
    expect(
      container.read(documentsWriteControllerProvider('')).error,
      const DocumentsFailure(DocumentsReason.io),
    );
  });
}
```

Run: `flutter test test/features/documents/presentation/documents_write_controller_test.dart`
Expected: 4 tests verts.

- [x] **Step 4 : test de `DocumentsRoot`**

Dans `test/features/documents/presentation/documents_root_test.dart`, remplacer la ligne 22 :

```dart
    when(
      () => repo.watch(any()),
    ).thenAnswer((_) => Stream.value(right(const [])));
```

et remplacer toutes les occurrences de `verify(() => repo.list('')).called(2)` par `verify(() => repo.watch('')).called(2)`, et de `verify(() => repo.list('')).called(1)` (ou `repo.list(any())`) par l'équivalent avec `watch`. Vérifier avec `grep -n "repo.list" test/features/documents/presentation/documents_root_test.dart` qu'il n'en reste aucune.

Run: `flutter test test/features/documents/presentation/documents_root_test.dart`
Expected: vert.

- [x] **Step 5 : test de page**

Dans `test/features/documents/presentation/documents_page_test.dart` :

1. Remplacer chaque `when(() => repo.list(X)).thenAnswer((_) async => right(Y))` par `when(() => repo.watch(X)).thenAnswer((_) => Stream.value(right(Y)))`, et chaque `left(...)` de même (`Stream.value(left(...))`).
2. Les tests à compteur (`listCalls`) deviennent :

```dart
    var watchCalls = 0;
    when(() => repo.watch('')).thenAnswer((_) {
      watchCalls++;
      return Stream.value(
        watchCalls == 1
            ? left(const DocumentsFailure(DocumentsReason.accessDenied))
            : right([entry('a.pdf')]),
      );
    });
```

(même transformation pour « tirer pour rafraîchir : succès » — `expect(watchCalls, 2)` —, « tirer pour rafraîchir : échec » et « erreur d'accès sur l'aperçu invalide le dossier » — `expect(watchCalls, 2)`).

3. « tirer pour rafraîchir : la liste reste affichée pendant le chargement » : remplacer le `Completer` par un `StreamController` :

```dart
      final second = StreamController<Either<Failure, List<DocumentEntry>>>();
      addTearDown(second.close);
      var watchCalls = 0;
      when(() => repo.watch('')).thenAnswer((_) {
        watchCalls++;
        return watchCalls == 1
            ? Stream.value(right([entry('a.pdf')]))
            : second.stream;
      });
      await pumpPage(tester);
      expect(find.text('a.pdf'), findsOneWidget);

      await tester.fling(find.byType(ListView), const Offset(0, 300), 1000);
      await tester.pump();

      // Toujours affichée : `AsyncValue(:final value, hasValue: true)`
      // capte aussi l'AsyncLoading avec previousData du rafraîchissement.
      expect(find.text('a.pdf'), findsOneWidget);

      second.add(right([entry('a.pdf')]));
      await tester.pumpAndSettle();
      expect(find.text('a.pdf'), findsOneWidget);
```

4. « « + » puis « Scanner » scanne dans le dossier courant » : remplacer `verify(() => repo.list('')).called(2);` par `verify(() => repo.watch('')).called(1);`.

5. Ajouter un test de mise à jour en direct, après « dossier vide » :

```dart
  testWidgets('la liste suit le flux du dossier', (tester) async {
    final events = StreamController<Either<Failure, List<DocumentEntry>>>();
    addTearDown(events.close);
    when(() => repo.watch('')).thenAnswer((_) => events.stream);
    await pumpPage(tester, settle: false);
    events.add(right([entry('a.pdf')]));
    await tester.pump();
    expect(find.text('a.pdf'), findsOneWidget);
    events.add(right([entry('a.pdf'), entry('b.pdf')]));
    await tester.pump();
    expect(find.text('b.pdf'), findsOneWidget);
    events.add(right([entry('b.pdf')]));
    await tester.pump();
    expect(find.text('a.pdf'), findsNothing);
  });
```

Run: `flutter test test/features/documents/presentation/documents_page_test.dart`
Expected: vert. Vérifier `grep -n "repo.list" test/features/documents/presentation/documents_page_test.dart` : aucune occurrence.

- [x] **Step 6 : retirer `list`**

- Retirer la méthode `list` de `DocumentsRepository` (interface) et de `NativeDocumentsRepository`.
- Dans `test/features/documents/data/native_documents_repository_test.dart` : supprimer le test « list transmet le chemin et mappe les entrées », « list renvoie une liste vide quand le canal renvoie null », « entrée malformée → UnknownFailure » (couvert par `watch`), et remplacer `repo.list('')` par `repo.download('')` dans la boucle des codes d'erreur, « code inconnu → UnknownFailure » et « canal absent → UnknownFailure ».

Run: `grep -rn "\.list(" lib/features/documents test/features/documents` → aucune occurrence. Puis `dart analyze && flutter test`.
Expected: 0 problème ; toute la suite verte.

- [x] **Step 7 : commit**

```bash
git add lib/features/documents test/features/documents
git commit -m "feat: liste de documents en flux natif, plus d'invalidation à l'écriture"
```

---

### Task 4 : `DocumentsPreviewController.open(entry)` et progression sur la tuile

**Files:**
- Modify: `lib/features/documents/presentation/providers/documents_preview_controller.dart`
- Modify: `lib/features/documents/presentation/widgets/document_entry_tile.dart`
- Test: `test/features/documents/presentation/documents_preview_controller_test.dart`, `documents_page_test.dart`

- [x] **Step 1 : tests du contrôleur (rouges)**

Remplacer `test/features/documents/presentation/documents_preview_controller_test.dart` :

```dart
import 'dart:async';

import 'package:colette/core/result/failure.dart';
import 'package:colette/features/documents/domain/entities/document_entry.dart';
import 'package:colette/features/documents/domain/entities/download_status.dart';
import 'package:colette/features/documents/domain/repositories/documents_repository.dart';
import 'package:colette/features/documents/presentation/providers/documents_preview_controller.dart';
import 'package:colette/features/documents/presentation/providers/documents_providers.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:mocktail/mocktail.dart';

class MockDocumentsRepository extends Mock implements DocumentsRepository {}

DocumentEntry entry(DownloadStatus status, {double? progress}) =>
    DocumentEntry(
      name: 'a.pdf',
      path: 'Ordonnances/a.pdf',
      isDirectory: false,
      size: 0,
      modifiedAt: DateTime(2026, 9, 1),
      downloadStatus: status,
      downloadProgress: progress,
    );

void main() {
  late MockDocumentsRepository repo;
  late ProviderContainer container;
  late StreamController<Either<Failure, List<DocumentEntry>>> folder;
  const path = 'Ordonnances/a.pdf';

  setUp(() {
    repo = MockDocumentsRepository();
    folder = StreamController<Either<Failure, List<DocumentEntry>>>();
    addTearDown(folder.close);
    when(() => repo.watch('Ordonnances')).thenAnswer((_) => folder.stream);
    container = ProviderContainer(
      overrides: [documentsRepositoryProvider.overrideWithValue(repo)],
    );
    addTearDown(container.dispose);
    container.listen(documentsPreviewControllerProvider(path), (_, _) {});
  });

  DocumentsPreviewController controller() =>
      container.read(documentsPreviewControllerProvider(path).notifier);

  AsyncValue<void> state() =>
      container.read(documentsPreviewControllerProvider(path));

  Future<void> settle() => Future<void>.delayed(Duration.zero);

  test('fichier téléchargé : aperçu direct, sans download', () async {
    when(() => repo.preview(path)).thenAnswer((_) async => right(null));
    await controller().open(entry(DownloadStatus.downloaded));
    verify(() => repo.preview(path)).called(1);
    verifyNever(() => repo.download(any()));
    expect(state(), const AsyncData<void>(null));
  });

  test('fichier nuage : download, puis aperçu quand le flux le dit téléchargé',
      () async {
    when(() => repo.download(path)).thenAnswer((_) async => right(null));
    when(() => repo.preview(path)).thenAnswer((_) async => right(null));

    await controller().open(entry(DownloadStatus.notDownloaded));
    verify(() => repo.download(path)).called(1);
    verifyNever(() => repo.preview(any()));
    expect(state().isLoading, isTrue);

    folder.add(right([entry(DownloadStatus.downloading, progress: 0.3)]));
    await settle();
    verifyNever(() => repo.preview(any()));
    expect(state().isLoading, isTrue);

    folder.add(right([entry(DownloadStatus.downloaded)]));
    await settle();
    verify(() => repo.preview(path)).called(1);
    expect(state(), const AsyncData<void>(null));
  });

  test('retour à notDownloaded après downloading → erreur io', () async {
    when(() => repo.download(path)).thenAnswer((_) async => right(null));
    await controller().open(entry(DownloadStatus.notDownloaded));
    folder.add(right([entry(DownloadStatus.downloading)]));
    await settle();
    folder.add(right([entry(DownloadStatus.notDownloaded)]));
    await settle();
    expect(state().error, const DocumentsFailure(DocumentsReason.io));
    verifyNever(() => repo.preview(any()));
  });

  test('entrée disparue du dossier → erreur io', () async {
    when(() => repo.download(path)).thenAnswer((_) async => right(null));
    await controller().open(entry(DownloadStatus.notDownloaded));
    folder.add(right(const []));
    await settle();
    expect(state().error, const DocumentsFailure(DocumentsReason.io));
  });

  test('échec du download → erreur, sans attente', () async {
    when(() => repo.download(path)).thenAnswer(
      (_) async => left(const DocumentsFailure(DocumentsReason.accessDenied)),
    );
    await controller().open(entry(DownloadStatus.notDownloaded));
    expect(state().error, const DocumentsFailure(DocumentsReason.accessDenied));
  });

  test('aperçu refusé (cancelled) après téléchargement → repos', () async {
    when(() => repo.download(path)).thenAnswer((_) async => right(null));
    when(() => repo.preview(path)).thenAnswer(
      (_) async => left(const DocumentsFailure(DocumentsReason.cancelled)),
    );
    await controller().open(entry(DownloadStatus.notDownloaded));
    folder.add(right([entry(DownloadStatus.downloaded)]));
    await settle();
    expect(state(), const AsyncData<void>(null));
  });

  test('io sur l\'aperçu direct passe en erreur', () async {
    when(
      () => repo.preview(path),
    ).thenAnswer((_) async => left(const DocumentsFailure(DocumentsReason.io)));
    await controller().open(entry(DownloadStatus.downloaded));
    expect(state().error, const DocumentsFailure(DocumentsReason.io));
  });

  test('open est ignoré pendant qu\'un open est en vol', () async {
    when(() => repo.download(path)).thenAnswer((_) async => right(null));
    await controller().open(entry(DownloadStatus.notDownloaded));
    await controller().open(entry(DownloadStatus.notDownloaded));
    verify(() => repo.download(path)).called(1);
  });
}
```

- [x] **Step 2 : vérifier l'échec**

Run: `flutter test test/features/documents/presentation/documents_preview_controller_test.dart`
Expected: échec de compilation (`open` inconnu).

- [x] **Step 3 : contrôleur**

Remplacer `lib/features/documents/presentation/providers/documents_preview_controller.dart` :

```dart
import 'dart:async';

import 'package:colette/core/result/failure.dart';
import 'package:colette/features/documents/domain/entities/document_entry.dart';
import 'package:colette/features/documents/domain/entities/download_status.dart';
import 'package:colette/features/documents/domain/use_cases/parent_path.dart';
import 'package:colette/features/documents/presentation/providers/documents_providers.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'documents_preview_controller.g.dart';

/// Ouverture d'un fichier, une instance par chemin : chaque ligne suit la
/// sienne. Un fichier non téléchargé est d'abord téléchargé ; l'aperçu
/// s'ouvre seul dès que le flux du dossier le dit téléchargé.
@riverpod
class DocumentsPreviewController extends _$DocumentsPreviewController {
  ProviderSubscription<AsyncValue<List<DocumentEntry>>>? _waiting;

  @override
  FutureOr<void> build(String path) {
    ref.onDispose(_stopWaiting);
  }

  /// Aperçu direct si [entry] est téléchargée, sinon téléchargement puis
  /// aperçu automatique. Ignoré si une ouverture est déjà en vol.
  Future<void> open(DocumentEntry entry) async {
    if (state.isLoading) return;
    state = const AsyncLoading();
    if (entry.downloadStatus == DownloadStatus.downloaded) {
      return _preview();
    }
    final started = await ref.read(documentsRepositoryProvider).download(path);
    switch (started) {
      case Left(:final value):
        state = AsyncError(value, StackTrace.current);
      case Right():
        _waitForDownload();
    }
  }

  /// Suit le dossier parent jusqu'à ce que l'entrée soit téléchargée
  /// (→ aperçu) ou que le téléchargement retombe (→ `io`).
  void _waitForDownload() {
    var seenDownloading = false;
    _stopWaiting();
    _waiting = ref.listen(documentsFolderProvider(parentPath(path)), (
      _,
      next,
    ) {
      final entries = next.value;
      if (entries == null) return;
      final current = entries.where((e) => e.path == path).firstOrNull;
      switch (current?.downloadStatus) {
        case DownloadStatus.downloaded:
          _stopWaiting();
          unawaited(_preview());
        case DownloadStatus.downloading:
          seenDownloading = true;
        case DownloadStatus.notDownloaded when !seenDownloading:
          // iCloud n'a pas encore pris le téléchargement en compte.
          break;
        case DownloadStatus.notDownloaded || null:
          _stopWaiting();
          state = AsyncError(
            const DocumentsFailure(DocumentsReason.io),
            StackTrace.current,
          );
      }
    }, fireImmediately: true);
  }

  void _stopWaiting() {
    _waiting?.close();
    _waiting = null;
  }

  /// Ouvre Quick Look ; une annulation (ou un refus pour verrou pris) n'est
  /// pas une erreur.
  Future<void> _preview() async {
    final result = await ref.read(documentsRepositoryProvider).preview(path);
    state = result.fold(
      (failure) => switch (failure) {
        DocumentsFailure(reason: DocumentsReason.cancelled) => const AsyncData(
          null,
        ),
        _ => AsyncError(failure, StackTrace.current),
      },
      (_) => const AsyncData(null),
    );
  }
}
```

`fireImmediately: true` traite le cas d'une tuile périmée (icône nuage alors que le fichier est déjà là) : le flux courant dit `downloaded`, l'aperçu s'ouvre sans attendre. `ref.listen` dans un notifier garde le provider du dossier vivant pendant l'attente ; `_stopWaiting` ferme l'abonnement à la première issue et à la destruction du contrôleur.

Run: `dart run build_runner build -d && flutter test test/features/documents/presentation/documents_preview_controller_test.dart`
Expected: 8 tests verts. Si `riverpod_lint` refuse `ref.listen` avec `fireImmediately` dans un notifier, garder l'appel : c'est l'API publique de `Ref` en Riverpod 3.

- [x] **Step 4 : tuile**

Dans `lib/features/documents/presentation/widgets/document_entry_tile.dart` :

1. Remplacer `_trailing` :

```dart
  Widget? _trailing(BuildContext context, bool previewing) {
    if (entry.isDirectory) return const Icon(Icons.chevron_right);
    final downloading = entry.downloadStatus == DownloadStatus.downloading;
    if (previewing || downloading) {
      return SizedBox.square(
        dimension: AppSize.sm.value,
        child: CircularProgressIndicator(
          strokeWidth: AppSpacing.xxs.value,
          value: downloading ? entry.downloadProgress : null,
        ),
      );
    }
    if (entry.downloadStatus == DownloadStatus.notDownloaded) {
      return Icon(
        Icons.cloud_download_outlined,
        color: context.appColor(AppColors.textSecondary),
      );
    }
    return null;
  }
```

2. Remplacer le `onTap` fichier : `false => () => ref.read(controller.notifier).open(entry),`.

3. Ajouter dans `test/features/documents/presentation/documents_page_test.dart`, après « fichier nuage : icône, et échec io → SnackBar » (adapter ce test existant : il stubbe désormais `repo.download('a.pdf')` en `right(null)` et `repo.preview` n'est plus appelé ; le SnackBar vient d'un flux qui repasse à `notDownloaded`) :

```dart
  testWidgets('fichier nuage : download, progression, puis aperçu automatique',
      (tester) async {
    final events = StreamController<Either<Failure, List<DocumentEntry>>>();
    addTearDown(events.close);
    when(() => repo.watch('')).thenAnswer((_) => events.stream);
    when(() => repo.download('a.pdf')).thenAnswer((_) async => right(null));
    when(() => repo.preview('a.pdf')).thenAnswer((_) async => right(null));
    await pumpPage(tester, settle: false);
    events.add(right([entry('a.pdf', status: DownloadStatus.notDownloaded)]));
    await tester.pump();
    expect(find.byIcon(Icons.cloud_download_outlined), findsOneWidget);

    await tester.tap(find.text('a.pdf'));
    await tester.pump();
    verify(() => repo.download('a.pdf')).called(1);

    events.add(
      right([
        DocumentEntry(
          name: 'a.pdf',
          path: 'a.pdf',
          isDirectory: false,
          size: 0,
          modifiedAt: DateTime(2026, 9, 22),
          downloadStatus: DownloadStatus.downloading,
          downloadProgress: 0.25,
        ),
      ]),
    );
    await tester.pump();
    final indicator = tester.widget<CircularProgressIndicator>(
      find.byType(CircularProgressIndicator),
    );
    expect(indicator.value, 0.25);
    verifyNever(() => repo.preview(any()));

    events.add(right([entry('a.pdf')]));
    await tester.pump();
    await tester.pump();
    verify(() => repo.preview('a.pdf')).called(1);
  });

  testWidgets('fichier nuage : téléchargement retombé → SnackBar', (
    tester,
  ) async {
    final events = StreamController<Either<Failure, List<DocumentEntry>>>();
    addTearDown(events.close);
    when(() => repo.watch('')).thenAnswer((_) => events.stream);
    when(() => repo.download('a.pdf')).thenAnswer((_) async => right(null));
    await pumpPage(tester, settle: false);
    events.add(right([entry('a.pdf', status: DownloadStatus.notDownloaded)]));
    await tester.pump();
    await tester.tap(find.text('a.pdf'));
    await tester.pump();
    events.add(right([entry('a.pdf', status: DownloadStatus.downloading)]));
    await tester.pump();
    events.add(right([entry('a.pdf', status: DownloadStatus.notDownloaded)]));
    await tester.pump();
    await tester.pump();
    expect(
      find.text("Ce document n'est pas encore téléchargé sur cet iPhone"),
      findsOneWidget,
    );
  });
```

Le test existant « fichier nuage : icône, et échec io → SnackBar » est remplacé par ces deux-là (le supprimer). Le test « un tap sur un fichier ouvre l'aperçu » reste valable (entrée `downloaded` → `preview` direct). Le test « aperçu annulé : pas de SnackBar » reste valable. Le test « erreur d'accès sur l'aperçu invalide le dossier » reste valable (entrée `downloaded`, `preview` → `accessDenied`).

Run: `flutter test test/features/documents/presentation`
Expected: vert. Les tests avec indicateur animé utilisent `pump()` et non `pumpAndSettle()`.

- [x] **Step 5 : vérification et commit**

Run: `dart format lib test && dart analyze && flutter test`
Expected: 0 changement de format, 0 problème, suite verte.

```bash
git add lib/features/documents test/features/documents
git commit -m "feat: téléchargement puis aperçu automatique, progression sur la ligne"
```

---

### Task 5 : suppression d'un fichier (l10n, contrôleur, glissement, page)

**Files:**
- Modify: `lib/l10n/app_fr.arb`
- Create: `lib/features/documents/presentation/providers/documents_delete_controller.dart`
- Create: `lib/features/documents/presentation/widgets/document_delete_dismissible.dart`
- Modify: `lib/features/documents/presentation/widgets/document_entry_tile.dart`
- Modify: `lib/features/documents/presentation/pages/documents_page.dart`
- Test: `test/features/documents/presentation/documents_delete_controller_test.dart`, `documents_page_test.dart`

- [x] **Step 1 : l10n**

Dans `lib/l10n/app_fr.arb`, avant `"copied"` :

```json
  "documentsDeleteTitle": "Supprimer ce document ?",
  "documentsDeleteBody": "{name} restera trente jours dans « Récemment supprimés » de l'app Fichiers.",
  "@documentsDeleteBody": { "placeholders": { "name": { "type": "String" } } },
  "documentsErrorDelete": "Impossible de supprimer ce document",
```

Run: `flutter gen-l10n`
Expected: `S.documentsDeleteBody(String name)` généré.

- [x] **Step 2 : test du contrôleur (rouge)**

Créer `test/features/documents/presentation/documents_delete_controller_test.dart` :

```dart
import 'package:colette/core/result/failure.dart';
import 'package:colette/features/documents/domain/repositories/documents_repository.dart';
import 'package:colette/features/documents/presentation/providers/documents_delete_controller.dart';
import 'package:colette/features/documents/presentation/providers/documents_providers.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:mocktail/mocktail.dart';

class MockDocumentsRepository extends Mock implements DocumentsRepository {}

void main() {
  late MockDocumentsRepository repo;
  late ProviderContainer container;

  setUp(() {
    repo = MockDocumentsRepository();
    container = ProviderContainer(
      overrides: [documentsRepositoryProvider.overrideWithValue(repo)],
    );
    addTearDown(container.dispose);
    container.listen(documentsDeleteControllerProvider('Ordonnances'), (_, _) {});
  });

  test('delete transmet le chemin et revient au repos', () async {
    when(() => repo.delete('Ordonnances/a.pdf'))
        .thenAnswer((_) async => right(null));
    await container
        .read(documentsDeleteControllerProvider('Ordonnances').notifier)
        .delete('Ordonnances/a.pdf');
    verify(() => repo.delete('Ordonnances/a.pdf')).called(1);
    expect(
      container.read(documentsDeleteControllerProvider('Ordonnances')),
      const AsyncData<void>(null),
    );
  });

  test('io passe en erreur', () async {
    when(() => repo.delete('Ordonnances/a.pdf')).thenAnswer(
      (_) async => left(const DocumentsFailure(DocumentsReason.io)),
    );
    await container
        .read(documentsDeleteControllerProvider('Ordonnances').notifier)
        .delete('Ordonnances/a.pdf');
    expect(
      container.read(documentsDeleteControllerProvider('Ordonnances')).error,
      const DocumentsFailure(DocumentsReason.io),
    );
  });
}
```

- [x] **Step 3 : contrôleur**

`lib/features/documents/presentation/providers/documents_delete_controller.dart` :

```dart
import 'dart:async';

import 'package:colette/features/documents/presentation/providers/documents_providers.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'documents_delete_controller.g.dart';

/// Suppression d'un fichier de [folderPath]. Famille par dossier : la page
/// racine et une sous-page poussée observent chacune leur instance.
@riverpod
class DocumentsDeleteController extends _$DocumentsDeleteController {
  @override
  FutureOr<void> build(String folderPath) {}

  /// Supprime le fichier [path]. Pas d'invalidation : le flux natif renvoie
  /// la liste sans lui.
  Future<void> delete(String path) async {
    state = const AsyncLoading();
    final result = await ref.read(documentsRepositoryProvider).delete(path);
    state = result.fold(
      (failure) => AsyncError(failure, StackTrace.current),
      (_) => const AsyncData(null),
    );
  }
}
```

Run: `dart run build_runner build -d && flutter test test/features/documents/presentation/documents_delete_controller_test.dart`
Expected: 2 tests verts.

- [x] **Step 4 : tests de page (rouges)**

Ajouter dans `documents_page_test.dart` :

```dart
  Future<void> swipeLeft(WidgetTester tester, String name) async {
    await tester.drag(find.text(name), const Offset(-400, 0));
    await tester.pumpAndSettle();
  }

  testWidgets('glisser puis annuler : ligne conservée, rien supprimé', (
    tester,
  ) async {
    when(() => repo.watch(''))
        .thenAnswer((_) => Stream.value(right([entry('a.pdf')])));
    await pumpPage(tester);
    await swipeLeft(tester, 'a.pdf');
    expect(find.text('Supprimer ce document ?'), findsOneWidget);
    expect(
      find.text(
        "a.pdf restera trente jours dans « Récemment supprimés » de l'app Fichiers.",
      ),
      findsOneWidget,
    );
    await tester.tap(find.text('Annuler'));
    await tester.pumpAndSettle();
    expect(find.text('a.pdf'), findsOneWidget);
    verifyNever(() => repo.delete(any()));
  });

  testWidgets('glisser puis confirmer : delete appelé', (tester) async {
    when(() => repo.watch(''))
        .thenAnswer((_) => Stream.value(right([entry('a.pdf')])));
    when(() => repo.delete('a.pdf')).thenAnswer((_) async => right(null));
    await pumpPage(tester);
    await swipeLeft(tester, 'a.pdf');
    await tester.tap(find.text('Supprimer'));
    await tester.pumpAndSettle();
    verify(() => repo.delete('a.pdf')).called(1);
    expect(find.byType(SnackBar), findsNothing);
  });

  testWidgets('suppression en échec io → SnackBar', (tester) async {
    when(() => repo.watch(''))
        .thenAnswer((_) => Stream.value(right([entry('a.pdf')])));
    when(() => repo.delete('a.pdf')).thenAnswer(
      (_) async => left(const DocumentsFailure(DocumentsReason.io)),
    );
    await pumpPage(tester);
    await swipeLeft(tester, 'a.pdf');
    await tester.tap(find.text('Supprimer'));
    await tester.pumpAndSettle();
    expect(find.text('Impossible de supprimer ce document'), findsOneWidget);
  });

  testWidgets('un dossier ne se glisse pas', (tester) async {
    when(() => repo.watch('')).thenAnswer(
      (_) => Stream.value(right([entry('Ordonnances', isDirectory: true)])),
    );
    await pumpPage(tester);
    expect(find.byType(Dismissible), findsNothing);
  });
```

Run: `flutter test test/features/documents/presentation/documents_page_test.dart`
Expected: les 4 nouveaux tests échouent (pas de `Dismissible`, pas de dialogue).

- [x] **Step 5 : widget de glissement**

`lib/features/documents/presentation/widgets/document_delete_dismissible.dart` :

```dart
import 'package:colette/core/theme/app_colors.dart';
import 'package:colette/core/theme/design_tokens.dart';
import 'package:colette/features/documents/domain/entities/document_entry.dart';
import 'package:colette/features/documents/presentation/providers/documents_delete_controller.dart';
import 'package:colette/l10n/generated/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Glissement vers la gauche sur une ligne de fichier : confirmation puis
/// suppression. La ligne ne se retire pas d'elle-même, c'est le flux du
/// dossier qui la fera disparaître.
class DocumentDeleteDismissible extends ConsumerWidget {
  const DocumentDeleteDismissible({
    super.key,
    required this.entry,
    required this.folderPath,
    required this.child,
  });

  final DocumentEntry entry;
  final String folderPath;
  final Widget child;

  Future<bool> _confirm(BuildContext context, WidgetRef ref) async {
    final s = S.of(context);
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(s.documentsDeleteTitle),
        content: Text(s.documentsDeleteBody(entry.name)),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: Text(s.actionCancel),
          ),
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: Text(
              s.actionDelete,
              style: Theme.of(context).coletteTextStyles.bodyMedium.copyWith(
                color: context.appColor(AppColors.error),
              ),
            ),
          ),
        ],
      ),
    );
    if (confirmed == true) {
      await ref
          .read(documentsDeleteControllerProvider(folderPath).notifier)
          .delete(entry.path);
    }
    return false;
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Garde le contrôleur autoDispose vivant pendant l'await, et bloque un
    // second glissement pendant une suppression.
    final deleting = ref
        .watch(documentsDeleteControllerProvider(folderPath))
        .isLoading;
    return Dismissible(
      key: ValueKey(entry.path),
      direction: deleting ? DismissDirection.none : DismissDirection.endToStart,
      confirmDismiss: (_) => _confirm(context, ref),
      background: Container(
        alignment: .centerRight,
        padding: AppSpacing.md.horizontal,
        color: context.appColor(AppColors.error),
        child: Icon(
          Icons.delete_outline,
          color: context.appColor(AppColors.onPrimary),
        ),
      ),
      child: child,
    );
  }
}
```

Vérifier l'import du thème texte : `coletteTextStyles` vient de `package:colette/core/theme/text_styles.dart` (voir `documents_root_section.dart` pour l'import exact utilisé dans la feature).

- [x] **Step 6 : tuile et page**

Dans `document_entry_tile.dart`, envelopper le `ListTile` renvoyé par `build` :

```dart
    final tile = ListTile(
      // … inchangé …
    );
    if (entry.isDirectory) return tile;
    return DocumentDeleteDismissible(
      entry: entry,
      folderPath: folderPath,
      child: tile,
    );
```

avec l'import `package:colette/features/documents/presentation/widgets/document_delete_dismissible.dart`.

Dans `documents_page.dart`, après le `ref.listen` du contrôleur d'écriture, ajouter :

```dart
    ref.listen(documentsDeleteControllerProvider(path), (_, next) {
      if (next case AsyncError(:final error)) {
        switch (error) {
          case DocumentsFailure(
            reason: DocumentsReason.noFolder || DocumentsReason.accessDenied,
          ):
            ref.invalidate(documentsFolderProvider(path));
          case DocumentsFailure(reason: DocumentsReason.io):
            ScaffoldMessenger.of(
              context,
            ).showSnackBar(SnackBar(content: Text(s.documentsErrorDelete)));
          default:
            ScaffoldMessenger.of(
              context,
            ).showSnackBar(SnackBar(content: Text(failureMessage(error, s))));
        }
      }
    });
```

avec l'import `package:colette/features/documents/presentation/providers/documents_delete_controller.dart`.

Run: `flutter test test/features/documents/presentation/documents_page_test.dart`
Expected: vert. Si `tester.drag` ne déclenche pas `confirmDismiss` (seuil non atteint), remplacer par `await tester.fling(find.text(name), const Offset(-400, 0), 1000);`.

- [x] **Step 7 : vérification et commit**

Run: `dart format lib test && dart analyze && flutter test`
Expected: 0 changement, 0 problème, suite verte. `documents_page.dart` doit rester sous 300 lignes ; sinon extraire les deux `ref.listen` dans un widget privé `_DocumentsErrorListeners` (un `ConsumerWidget` qui enveloppe le `Scaffold`).

```bash
git add lib/l10n/app_fr.arb lib/features/documents test/features/documents
git commit -m "feat: suppression d'un document par glissement avec confirmation"
```

---

### Task 6 : bouton « Ouvrir dans Fichiers »

**Files:**
- Modify: `lib/l10n/app_fr.arb`
- Create: `lib/features/documents/presentation/providers/documents_open_in_files_controller.dart`
- Create: `lib/features/documents/presentation/widgets/documents_open_in_files_button.dart`
- Modify: `lib/features/documents/presentation/pages/documents_page.dart`
- Test: `test/features/documents/presentation/documents_open_in_files_controller_test.dart`, `documents_page_test.dart`

- [x] **Step 1 : l10n**

Dans `app_fr.arb`, après `documentsErrorDelete` :

```json
  "documentsOpenInFiles": "Ouvrir dans Fichiers",
  "documentsErrorOpenInFiles": "Impossible d'ouvrir Fichiers",
```

Run: `flutter gen-l10n`.

- [x] **Step 2 : test du contrôleur (rouge)**

`test/features/documents/presentation/documents_open_in_files_controller_test.dart` :

```dart
import 'package:colette/core/result/failure.dart';
import 'package:colette/features/documents/domain/repositories/documents_repository.dart';
import 'package:colette/features/documents/presentation/providers/documents_open_in_files_controller.dart';
import 'package:colette/features/documents/presentation/providers/documents_providers.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:mocktail/mocktail.dart';

class MockDocumentsRepository extends Mock implements DocumentsRepository {}

void main() {
  late MockDocumentsRepository repo;
  late ProviderContainer container;

  setUp(() {
    repo = MockDocumentsRepository();
    container = ProviderContainer(
      overrides: [documentsRepositoryProvider.overrideWithValue(repo)],
    );
    addTearDown(container.dispose);
    container.listen(
      documentsOpenInFilesControllerProvider('Ordonnances'),
      (_, _) {},
    );
  });

  test('open transmet le chemin', () async {
    when(() => repo.openInFiles('Ordonnances'))
        .thenAnswer((_) async => right(null));
    await container
        .read(documentsOpenInFilesControllerProvider('Ordonnances').notifier)
        .open();
    verify(() => repo.openInFiles('Ordonnances')).called(1);
    expect(
      container.read(documentsOpenInFilesControllerProvider('Ordonnances')),
      const AsyncData<void>(null),
    );
  });

  test('io passe en erreur', () async {
    when(() => repo.openInFiles('Ordonnances')).thenAnswer(
      (_) async => left(const DocumentsFailure(DocumentsReason.io)),
    );
    await container
        .read(documentsOpenInFilesControllerProvider('Ordonnances').notifier)
        .open();
    expect(
      container
          .read(documentsOpenInFilesControllerProvider('Ordonnances'))
          .error,
      const DocumentsFailure(DocumentsReason.io),
    );
  });
}
```

- [x] **Step 3 : contrôleur**

`lib/features/documents/presentation/providers/documents_open_in_files_controller.dart` :

```dart
import 'dart:async';

import 'package:colette/features/documents/presentation/providers/documents_providers.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'documents_open_in_files_controller.g.dart';

/// Ouverture de l'app Fichiers sur le dossier [path].
@riverpod
class DocumentsOpenInFilesController extends _$DocumentsOpenInFilesController {
  @override
  FutureOr<void> build(String path) {}

  Future<void> open() async {
    state = const AsyncLoading();
    final result = await ref.read(documentsRepositoryProvider).openInFiles(path);
    state = result.fold(
      (failure) => AsyncError(failure, StackTrace.current),
      (_) => const AsyncData(null),
    );
  }
}
```

Run: `dart run build_runner build -d && flutter test test/features/documents/presentation/documents_open_in_files_controller_test.dart`
Expected: 2 tests verts.

- [x] **Step 4 : tests de page (rouges)**

```dart
  testWidgets('bouton Fichiers : présent avec une liste, appelle openInFiles',
      (tester) async {
    when(() => repo.watch(''))
        .thenAnswer((_) => Stream.value(right([entry('a.pdf')])));
    when(() => repo.openInFiles('')).thenAnswer((_) async => right(null));
    await pumpPage(tester);
    await tester.tap(find.byTooltip('Ouvrir dans Fichiers'));
    await tester.pumpAndSettle();
    verify(() => repo.openInFiles('')).called(1);
  });

  testWidgets('bouton Fichiers : présent sur un dossier vide', (tester) async {
    when(() => repo.watch('')).thenAnswer((_) => Stream.value(right(const [])));
    await pumpPage(tester);
    expect(find.byTooltip('Ouvrir dans Fichiers'), findsOneWidget);
  });

  testWidgets('bouton Fichiers : absent quand l\'accès est perdu', (
    tester,
  ) async {
    when(() => repo.watch('')).thenAnswer(
      (_) => Stream.value(
        left(const DocumentsFailure(DocumentsReason.accessDenied)),
      ),
    );
    await pumpPage(tester);
    expect(find.byTooltip('Ouvrir dans Fichiers'), findsNothing);
  });

  testWidgets('bouton Fichiers : échec → SnackBar', (tester) async {
    when(() => repo.watch('Ordonnances')).thenAnswer(
      (_) => Stream.value(right([entry('a.pdf', path: 'Ordonnances/a.pdf')])),
    );
    when(() => repo.watch('')).thenAnswer(
      (_) => Stream.value(right([entry('Ordonnances', isDirectory: true)])),
    );
    when(() => repo.openInFiles('Ordonnances')).thenAnswer(
      (_) async => left(const DocumentsFailure(DocumentsReason.io)),
    );
    await pumpPage(tester);
    await tester.tap(find.text('Ordonnances'));
    await tester.pumpAndSettle();
    await tester.tap(find.byTooltip('Ouvrir dans Fichiers'));
    await tester.pumpAndSettle();
    expect(find.text("Impossible d'ouvrir Fichiers"), findsOneWidget);
    verify(() => repo.openInFiles('Ordonnances')).called(1);
  });
```

Run: `flutter test test/features/documents/presentation/documents_page_test.dart`
Expected: les 4 nouveaux tests échouent.

- [x] **Step 5 : bouton et page**

`lib/features/documents/presentation/widgets/documents_open_in_files_button.dart` :

```dart
import 'package:colette/features/documents/presentation/providers/documents_open_in_files_controller.dart';
import 'package:colette/l10n/generated/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Action de la barre de titre : ouvre l'app Fichiers sur le dossier [path].
class DocumentsOpenInFilesButton extends ConsumerWidget {
  const DocumentsOpenInFilesButton({super.key, required this.path});

  final String path;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final s = S.of(context);
    final controller = documentsOpenInFilesControllerProvider(path);
    // Garde le contrôleur autoDispose vivant pendant l'await de open().
    final opening = ref.watch(controller).isLoading;
    ref.listen(controller, (_, next) {
      if (next is AsyncError) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(s.documentsErrorOpenInFiles)));
      }
    });
    return IconButton(
      tooltip: s.documentsOpenInFiles,
      icon: const Icon(Icons.folder_open_outlined),
      onPressed: opening ? null : () => ref.read(controller.notifier).open(),
    );
  }
}
```

Dans `documents_page.dart`, l'`AppBar` devient :

```dart
      appBar: AppBar(
        title: Text(title),
        actions: [
          if (folder.hasValue && !folder.hasError)
            DocumentsOpenInFilesButton(path: path),
        ],
      ),
```

(`folder` est déjà lu avant le `Scaffold`), avec l'import du bouton.

Run: `flutter test test/features/documents/presentation/documents_page_test.dart`
Expected: vert.

- [x] **Step 6 : vérification et commit**

Run: `dart format lib test && dart analyze && flutter test`
Expected: propre, suite verte.

```bash
git add lib/l10n/app_fr.arb lib/features/documents test/features/documents
git commit -m "feat: bouton Ouvrir dans Fichiers sur la page Documents"
```

---

### Task 7 : pont Swift — observateur de dossier, `download`, `delete`, `openInFiles`, aperçu sans attente

**Files:**
- Create: `ios/Runner/Documents/DocumentsFolderWatcher.swift`
- Modify: `ios/Runner/Documents/DocumentsLister.swift`
- Modify: `ios/Runner/Documents/DocumentsWriter.swift`
- Modify: `ios/Runner/Documents/DocumentsPlugin.swift`
- Run: `ruby ios/scripts/add_documents_sources.rb`

Pas de test automatisé Swift : la vérification est `flutter build ios --simulator` (compilation) puis la liste de contrôle sur iPhone (Task 8).

- [x] **Step 1 : `DocumentsLister` — progression, `isAvailable` public, retrait du sondage**

Remplacer `ios/Runner/Documents/DocumentsLister.swift` :

```swift
import Foundation

/// Listage d'un dossier et état de téléchargement iCloud.
enum DocumentsLister {
  private static let keys: Set<URLResourceKey> = [
    .isDirectoryKey, .fileSizeKey, .contentModificationDateKey, .isUbiquitousItemKey,
    .ubiquitousItemDownloadingStatusKey, .ubiquitousItemIsDownloadingKey,
  ]

  private static let placeholderSuffix = ".icloud"

  private typealias Entry = (path: String, isPlaceholder: Bool, values: [String: Any])

  /// Entrées d'un dossier, au format attendu par `DocumentEntryDto`.
  /// `progress` : chemin absolu du fichier réel → progression (0 à 1) fournie
  /// par la requête de métadonnées ; un fichier qui y figure est `downloading`.
  static func list(
    folder: URL, relativePath: String, progress: [String: Double] = [:]
  ) throws -> [[String: Any]] {
    let urls: [URL]
    do {
      urls = try FileManager.default.contentsOfDirectory(
        at: folder, includingPropertiesForKeys: Array(keys), options: [])
    } catch {
      throw DocumentsError.io(error.localizedDescription)
    }
    let entries = urls.compactMap { url -> Entry? in
      let raw = url.lastPathComponent
      let isPlaceholder = raw.hasPrefix(".") && raw.hasSuffix(placeholderSuffix)
      if raw.hasPrefix(".") && !isPlaceholder { return nil }
      let values = try? url.resourceValues(forKeys: keys)
      let isDirectory = values?.isDirectory ?? false
      let name = isPlaceholder ? normalizedName(raw) : raw
      let path = relativePath.isEmpty ? name : "\(relativePath)/\(name)"
      let modified = values?.contentModificationDate ?? Date(timeIntervalSince1970: 0)
      var status = self.status(
        isDirectory: isDirectory, isPlaceholder: isPlaceholder, values: values)
      var entry: [String: Any] = [
        "name": name,
        "path": path,
        "isDirectory": isDirectory,
        "size": isDirectory ? 0 : (values?.fileSize ?? 0),
        "modifiedAt": Int(modified.timeIntervalSince1970 * 1000),
      ]
      if status != "downloaded", let percent = progress[realURL(for: url).path] {
        status = "downloading"
        entry["downloadProgress"] = percent
      }
      entry["downloadStatus"] = status
      return (path, isPlaceholder, entry)
    }
    return deduplicated(entries)
  }

  /// Une seule entrée par chemin : le fichier réel prime sur son placeholder `.x.ext.icloud`.
  private static func deduplicated(_ entries: [Entry]) -> [[String: Any]] {
    var indexByPath: [String: Int] = [:]
    var kept: [Entry] = []
    for entry in entries {
      guard let index = indexByPath[entry.path] else {
        indexByPath[entry.path] = kept.count
        kept.append(entry)
        continue
      }
      if kept[index].isPlaceholder && !entry.isPlaceholder { kept[index] = entry }
    }
    return kept.map(\.values)
  }

  private static func status(isDirectory: Bool, isPlaceholder: Bool, values: URLResourceValues?)
    -> String
  {
    if isDirectory { return "downloaded" }
    if isPlaceholder { return "notDownloaded" }
    guard values?.isUbiquitousItem == true else { return "downloaded" }
    let downloadStatus = values?.ubiquitousItemDownloadingStatus
    if downloadStatus == .current || downloadStatus == .downloaded { return "downloaded" }
    if values?.ubiquitousItemIsDownloading == true { return "downloading" }
    return "notDownloaded"
  }

  /// `.nom.ext.icloud` → `nom.ext`.
  private static func normalizedName(_ raw: String) -> String {
    String(raw.dropFirst().dropLast(placeholderSuffix.count))
  }

  /// URL réelle du fichier (sans préfixe `.` ni suffixe `.icloud`).
  static func realURL(for url: URL) -> URL {
    let raw = url.lastPathComponent
    guard raw.hasPrefix("."), raw.hasSuffix(placeholderSuffix) else { return url }
    return url.deletingLastPathComponent().appendingPathComponent(normalizedName(raw))
  }

  /// Fichier réel ou placeholder iCloud pour un chemin relatif.
  static func locate(_ relativePath: String, under root: URL) throws -> URL {
    let url = try DocumentsStore.resolve(relativePath, under: root)
    if FileManager.default.fileExists(atPath: url.path) { return url }
    let placeholder = url.deletingLastPathComponent()
      .appendingPathComponent(".\(url.lastPathComponent)\(placeholderSuffix)")
    if FileManager.default.fileExists(atPath: placeholder.path) { return placeholder }
    throw DocumentsError.io("Fichier introuvable")
  }

  /// Vrai si le fichier réel existe et est lisible localement (téléchargé, ou hors iCloud).
  static func isAvailable(_ url: URL) -> Bool {
    guard FileManager.default.fileExists(atPath: url.path) else { return false }
    let values = try? url.resourceValues(forKeys: [
      .isUbiquitousItemKey, .ubiquitousItemDownloadingStatusKey,
    ])
    guard values?.isUbiquitousItem == true else { return true }
    let status = values?.ubiquitousItemDownloadingStatus
    return status == .current || status == .downloaded
  }

  /// Lance le téléchargement iCloud du fichier réel s'il n'est pas déjà lisible.
  static func startDownload(_ located: URL) throws {
    let real = realURL(for: located)
    if isAvailable(real) { return }
    do {
      try FileManager.default.startDownloadingUbiquitousItem(at: real)
    } catch {
      throw DocumentsError.io(error.localizedDescription)
    }
  }
}
```

(`ensureDownloaded` et `poll` sont supprimés.)

- [x] **Step 2 : `DocumentsWriter.delete`**

Dans `ios/Runner/Documents/DocumentsWriter.swift`, remplacer `coordinatedWrite` et ajouter `delete` :

```swift
  /// Supprime un fichier (réel ou placeholder) sous coordination iCloud.
  static func delete(_ url: URL) throws {
    try coordinatedWrite(to: url, options: .forDeleting) { target in
      try FileManager.default.removeItem(at: target)
    }
  }

  private static func coordinatedWrite(
    to target: URL, options: NSFileCoordinator.WritingOptions = [],
    _ body: (URL) throws -> Void
  ) throws {
    var coordinationError: NSError?
    var writeError: Error?
    NSFileCoordinator().coordinate(
      writingItemAt: target, options: options, error: &coordinationError
    ) { url in
      do { try body(url) } catch { writeError = error }
    }
    let failure: Error? = writeError ?? coordinationError
    if let failure {
      throw DocumentsError.io(failure.localizedDescription)
    }
  }
```

- [x] **Step 3 : `DocumentsFolderWatcher`**

Créer `ios/Runner/Documents/DocumentsFolderWatcher.swift` :

```swift
import Flutter
import Foundation

/// Observe un dossier pour un abonnement Flutter : première liste immédiate,
/// puis relistage à chaque mise à jour iCloud (`NSMetadataQuery`) ou sur demande.
/// Tout s'exécute sur le thread principal sauf le listage lui-même.
final class DocumentsFolderWatcher {
  let relativePath: String

  private let root: ScopedRoot
  private let folder: URL
  private let query = NSMetadataQuery()
  private var observers: [NSObjectProtocol] = []
  private var sink: FlutterEventSink?
  /// Chemin absolu du fichier réel → progression (0 à 1), d'après la requête.
  private var progress: [String: Double] = [:]
  private var relisting = false
  private var relistPending = false

  init(root: ScopedRoot, folder: URL, relativePath: String) {
    self.root = root
    self.folder = folder
    self.relativePath = relativePath
  }

  /// Envoie la première liste puis démarre la requête de métadonnées.
  func start(sink: @escaping FlutterEventSink) {
    self.sink = sink
    relist()
    query.searchScopes = [NSMetadataQueryAccessibleUbiquitousExternalDocumentsScope]
    query.predicate = NSPredicate(
      format: "%K BEGINSWITH %@", NSMetadataItemPathKey, folder.path + "/")
    let center = NotificationCenter.default
    for name in [Notification.Name.NSMetadataQueryDidFinishGathering, .NSMetadataQueryDidUpdate] {
      observers.append(
        center.addObserver(forName: name, object: query, queue: .main) { [weak self] _ in
          self?.queryChanged()
        })
    }
    query.start()
  }

  /// Arrête la requête, referme la portée sécurisée ; plus aucun événement envoyé.
  func stop() {
    observers.forEach(NotificationCenter.default.removeObserver)
    observers.removeAll()
    query.stop()
    sink = nil
    root.close()
  }

  /// Relistage forcé, après une écriture ou une suppression.
  func refresh() { relist() }

  private func queryChanged() {
    query.disableUpdates()
    var next: [String: Double] = [:]
    for case let item as NSMetadataItem in query.results {
      guard let path = item.value(forAttribute: NSMetadataItemPathKey) as? String,
        (path as NSString).deletingLastPathComponent == folder.path,
        item.value(forAttribute: NSMetadataUbiquitousItemIsDownloadingKey) as? Bool == true,
        let percent = item.value(forAttribute: NSMetadataUbiquitousItemPercentDownloadedKey)
          as? Double
      else { continue }
      next[path] = min(max(percent / 100, 0), 1)
    }
    query.enableUpdates()
    progress = next
    relist()
  }

  /// Un seul listage à la fois ; une demande arrivée pendant un listage en déclenche un autre après.
  private func relist() {
    guard sink != nil else { return }
    guard !relisting else {
      relistPending = true
      return
    }
    relisting = true
    let folder = self.folder
    let path = relativePath
    let progress = self.progress
    DispatchQueue.global(qos: .userInitiated).async { [weak self] in
      let outcome = Result { try DocumentsLister.list(folder: folder, relativePath: path, progress: progress) }
      DispatchQueue.main.async {
        guard let self, let sink = self.sink else { return }
        self.relisting = false
        switch outcome {
        case .success(let entries):
          sink(entries)
        case .failure(let error):
          let documentsError = error as? DocumentsError ?? .io(error.localizedDescription)
          sink(documentsError.flutterError)
          sink(FlutterEndOfEventStream)
          self.sink = nil
        }
        if self.relistPending {
          self.relistPending = false
          self.relist()
        }
      }
    }
  }
}
```

- [x] **Step 4 : `DocumentsPlugin`**

Remplacer `ios/Runner/Documents/DocumentsPlugin.swift` en entier :

```swift
import Flutter
import UIKit
import os.log

/// Relie un canal de dossier (`colette/documents/folder/{n}`) à son observateur.
final class DocumentsFolderStreamHandler: NSObject, FlutterStreamHandler {
  private let listen: (@escaping FlutterEventSink) -> Void
  private let cancel: () -> Void

  init(onListen: @escaping (@escaping FlutterEventSink) -> Void, onCancel: @escaping () -> Void) {
    listen = onListen
    cancel = onCancel
  }

  func onListen(withArguments arguments: Any?, eventSink events: @escaping FlutterEventSink)
    -> FlutterError?
  {
    listen(events)
    return nil
  }

  func onCancel(withArguments arguments: Any?) -> FlutterError? {
    cancel()
    return nil
  }
}

/// Canal `colette/documents` : dispatch des appels Flutter vers le store, le lister,
/// le writer, le presenter et les observateurs de dossier.
final class DocumentsPlugin: NSObject {
  static let channelName = "colette/documents"
  static let folderChannelPrefix = "colette/documents/folder/"

  private let messenger: FlutterBinaryMessenger
  private let store = DocumentsStore()
  private let presenter = DocumentsPresenter()

  /// Observateurs et canaux de dossier vivants, par nom de canal.
  private var watchers: [String: DocumentsFolderWatcher] = [:]
  private var folderChannels: [String: FlutterEventChannel] = [:]
  private var nextFolderChannel = 0

  /// Verrou global : une seule opération qui présente un écran système à la fois
  /// (`pickRootFolder`, `preview`, `scan`, `importFile`), le temps où l'écran est
  /// affiché. Lu et écrit uniquement sur le thread principal.
  ///
  /// Libéré par la réponse unique fabriquée par `release(_:)`, sur chacun de ces chemins :
  /// 1. argument manquant, `openRoot` / `resolve` / `locate` en échec, fichier non
  ///    téléchargé pour un aperçu (`exclusive` répond) ;
  /// 2. opération concurrente refusée par un garde du presenter (`cancelled`) ;
  /// 3. aucune fenêtre hôte, ou scanner indisponible (`io`) ;
  /// 4. présentation impossible de l'écran système (`io`) ;
  /// 5. annulation par l'utilisateur dans le sélecteur ou le scanner (`cancelled`) ;
  /// 6. échec du scanner VisionKit (`io`) ;
  /// 7. fermeture de l'aperçu Quick Look (succès) ;
  /// 8. écriture terminée hors thread principal, réussie ou en échec (`offMainThread`).
  ///
  /// `rootFolder`, `forgetRootFolder`, `openFolderStream`, `download`, `delete` et
  /// `openInFiles` ne prennent pas le verrou.
  private var busy = false

  init(messenger: FlutterBinaryMessenger) {
    self.messenger = messenger
  }

  static func register(with registry: FlutterPluginRegistry) {
    guard let messenger = registry.registrar(forPlugin: "DocumentsPlugin")?.messenger() else {
      os_log("DocumentsPlugin : registrar indisponible, canal non enregistré", type: .error)
      return
    }
    let channel = FlutterMethodChannel(name: channelName, binaryMessenger: messenger)
    let plugin = DocumentsPlugin(messenger: messenger)
    channel.setMethodCallHandler { call, result in plugin.handle(call, result: result) }
  }

  private func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
    do {
      switch call.method {
      case "rootFolder":
        result(try rootFolder())
      case "forgetRootFolder":
        store.forget()
        result(nil)
      case "openFolderStream":
        result(try openFolderStream(path: try argument("path", of: call)))
      case "download":
        try download(path: try argument("path", of: call))
        result(nil)
      case "delete":
        try delete(path: try argument("path", of: call), result: result)
      case "openInFiles":
        try openInFiles(path: try argument("path", of: call), result: result)
      case "pickRootFolder", "preview", "scan", "importFile":
        exclusive(call, result: result)
      default:
        result(FlutterMethodNotImplemented)
      }
    } catch let error as DocumentsError {
      result(error.flutterError)
    } catch {
      result(DocumentsError.io(error.localizedDescription).flutterError)
    }
  }

  /// Opérations qui présentent un écran système : une seule à la fois.
  /// Une deuxième est refusée avec `cancelled` sans toucher au presenter ni au store.
  private func exclusive(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
    guard !busy else {
      result(DocumentsError.cancelled.flutterError)
      return
    }
    busy = true
    let reply = release(result)
    do {
      switch call.method {
      case "preview":
        try preview(path: try argument("path", of: call), result: reply)
      case "scan":
        try scan(
          path: try argument("path", of: call),
          fileName: try argument("fileName", of: call),
          result: reply)
      case "importFile":
        try importFile(path: try argument("path", of: call), result: reply)
      default:
        pickRootFolder(reply)
      }
    } catch let error as DocumentsError {
      reply(error.flutterError)
    } catch {
      reply(DocumentsError.io(error.localizedDescription).flutterError)
    }
  }

  /// Réponse unique d'une opération exclusive : libère le verrou, sur le thread principal.
  /// Les appels suivants sont ignorés, pour qu'un double rappel ne réponde jamais deux fois.
  private func release(_ result: @escaping FlutterResult) -> FlutterResult {
    var replied = false
    return { [weak self] value in
      let answer = {
        guard !replied else { return }
        replied = true
        self?.busy = false
        result(value)
      }
      if Thread.isMainThread {
        answer()
      } else {
        DispatchQueue.main.async(execute: answer)
      }
    }
  }

  /// Argument `String` obligatoire d'un appel de méthode.
  private func argument(_ name: String, of call: FlutterMethodCall) throws -> String {
    guard let args = call.arguments as? [String: Any], let value = args[name] as? String else {
      throw DocumentsError.io("Argument manquant : \(name)")
    }
    return value
  }

  private func rootFolder() throws -> [String: Any]? {
    guard store.hasRoot else { return nil }
    let root = try store.openRoot()
    defer { root.close() }
    return ["name": root.url.lastPathComponent]
  }

  private func pickRootFolder(_ result: @escaping FlutterResult) {
    presenter.pickFolder { [store = self.store] outcome in
      switch outcome {
      case .failure(let error):
        result(error.flutterError)
      case .success(let url):
        do {
          result(["name": try store.save(rootURL: url)])
        } catch let error as DocumentsError {
          result(error.flutterError)
        } catch {
          result(DocumentsError.io(error.localizedDescription).flutterError)
        }
      }
    }
  }

  // MARK: - Flux d'un dossier

  /// Crée un canal d'événements dédié et son observateur ; l'observateur démarre à
  /// l'abonnement Flutter et s'arrête (portée refermée) au désabonnement.
  private func openFolderStream(path: String) throws -> [String: Any] {
    let root = try store.openRoot()
    let folder = try resolve(path, under: root)
    nextFolderChannel += 1
    let name = Self.folderChannelPrefix + String(nextFolderChannel)
    let watcher = DocumentsFolderWatcher(root: root, folder: folder, relativePath: path)
    let channel = FlutterEventChannel(name: name, binaryMessenger: messenger)
    channel.setStreamHandler(
      DocumentsFolderStreamHandler(
        onListen: { sink in watcher.start(sink: sink) },
        onCancel: { [weak self] in self?.closeFolderStream(name) }))
    watchers[name] = watcher
    folderChannels[name] = channel
    return ["channel": name]
  }

  private func closeFolderStream(_ name: String) {
    watchers.removeValue(forKey: name)?.stop()
    folderChannels.removeValue(forKey: name)?.setStreamHandler(nil)
  }

  /// Relistage forcé de tous les abonnements au dossier `path`.
  private func refreshWatchers(of path: String) {
    for watcher in watchers.values where watcher.relativePath == path {
      watcher.refresh()
    }
  }

  /// `Ordonnances/2026/a.pdf` → `Ordonnances/2026` ; `a.pdf` → `""`.
  private static func parent(of path: String) -> String {
    path.split(separator: "/").dropLast().joined(separator: "/")
  }

  // MARK: - Téléchargement, suppression, Fichiers

  private func download(path: String) throws {
    let root = try store.openRoot()
    defer { root.close() }
    let located = try DocumentsLister.locate(path, under: root.url)
    try DocumentsLister.startDownload(located)
  }

  private func delete(path: String, result: @escaping FlutterResult) throws {
    let root = try store.openRoot()
    let located: URL
    do {
      located = try DocumentsLister.locate(path, under: root.url)
    } catch {
      root.close()
      throw error
    }
    var isDirectory: ObjCBool = false
    if FileManager.default.fileExists(atPath: located.path, isDirectory: &isDirectory),
      isDirectory.boolValue
    {
      root.close()
      throw DocumentsError.io("Un dossier ne peut pas être supprimé")
    }
    let folderPath = Self.parent(of: path)
    Self.offMainThread(root: root, result: { [weak self] value in
      if !(value is FlutterError) { self?.refreshWatchers(of: folderPath) }
      result(value)
    }) {
      try DocumentsWriter.delete(located)
      return nil
    }
  }

  private func openInFiles(path: String, result: @escaping FlutterResult) throws {
    let root = try store.openRoot()
    let folder = try resolve(path, under: root)
    root.close()
    var components = URLComponents()
    components.scheme = "shareddocuments"
    components.path = folder.path
    guard let url = components.url else { throw DocumentsError.io("Lien Fichiers invalide") }
    UIApplication.shared.open(url, options: [:]) { opened in
      result(opened ? nil : DocumentsError.io("Fichiers ne s'est pas ouvert").flutterError)
    }
  }

  // MARK: - Écriture

  private func scan(path: String, fileName: String, result: @escaping FlutterResult) throws {
    let root = try store.openRoot()
    let folder = try resolve(path, under: root)
    presenter.scan { [weak self] outcome in
      switch outcome {
      case .failure(let error):
        root.close()
        result(error.flutterError)
      case .success(let pages):
        Self.offMainThread(root: root, result: { value in
          if !(value is FlutterError) { self?.refreshWatchers(of: path) }
          result(value)
        }) {
          ["name": try DocumentsWriter.writePDF(pages: pages, named: fileName, in: folder)]
        }
      }
    }
  }

  private func importFile(path: String, result: @escaping FlutterResult) throws {
    let root = try store.openRoot()
    let folder = try resolve(path, under: root)
    presenter.pickFile { [weak self] outcome in
      switch outcome {
      case .failure(let error):
        root.close()
        result(error.flutterError)
      case .success(let source):
        Self.offMainThread(root: root, result: { value in
          if !(value is FlutterError) { self?.refreshWatchers(of: path) }
          result(value)
        }) {
          defer { try? FileManager.default.removeItem(at: source) }
          let name = source.lastPathComponent
          return ["name": try DocumentsWriter.copy(source, named: name, in: folder)]
        }
      }
    }
  }

  /// Travaille sur le disque hors du thread principal, puis referme la portée sécurisée
  /// et répond sur le thread principal, que le travail ait réussi ou échoué.
  private static func offMainThread(
    root: ScopedRoot, result: @escaping FlutterResult, _ work: @escaping () throws -> Any?
  ) {
    DispatchQueue.global(qos: .userInitiated).async {
      let outcome = Self.outcome(work)
      DispatchQueue.main.async {
        root.close()
        result(outcome)
      }
    }
  }

  /// Valeur du travail, ou l'erreur du canal ; la portée sécurisée reste ouverte autour.
  private static func outcome(_ work: () throws -> Any?) -> Any? {
    do {
      return try work()
    } catch let error as DocumentsError {
      return error.flutterError
    } catch {
      return DocumentsError.io(error.localizedDescription).flutterError
    }
  }

  /// Dossier sous la racine ; ferme la portée sécurisée si le chemin est refusé.
  private func resolve(_ path: String, under root: ScopedRoot) throws -> URL {
    do {
      return try DocumentsStore.resolve(path, under: root.url)
    } catch {
      root.close()
      throw error
    }
  }

  // MARK: - Aperçu

  /// Aperçu sans attente : le fichier doit déjà être lisible localement.
  private func preview(path: String, result: @escaping FlutterResult) throws {
    let root = try store.openRoot()
    let real: URL
    do {
      real = DocumentsLister.realURL(for: try DocumentsLister.locate(path, under: root.url))
    } catch {
      root.close()
      throw error
    }
    guard DocumentsLister.isAvailable(real) else {
      root.close()
      throw DocumentsError.io("Fichier non téléchargé")
    }
    presenter.preview(fileURL: real) { previewOutcome in
      root.close()
      switch previewOutcome {
      case .failure(let error):
        result(error.flutterError)
      case .success:
        result(nil)
      }
    }
  }
}
```

Points d'attention :
- `openInFiles` referme la portée avant d'ouvrir l'URL : le chemin absolu reste valide pour le lien, Fichiers a ses propres droits.
- `preview` lève `io` depuis `exclusive`, qui répond avec `reply` : le verrou est libéré (chemin 1 du commentaire).
- Un `openFolderStream` dont Flutter n'écoute jamais le canal (provider détruit entre l'appel et l'abonnement) laisse un observateur non démarré avec sa portée ouverte jusqu'à la fin du processus. Cas limite accepté : l'abonnement suit l'appel de méthode dans la même fonction Dart (`watch`), et un désabonnement pendant l'appel provoque quand même `listen` puis `cancel` (voir `watch` en Task 2).

- [x] **Step 5 : enregistrer le fichier et compiler**

Run: `ruby ios/scripts/add_documents_sources.rb`
Expected: `ajouté : DocumentsFolderWatcher.swift`. Le relancer : aucune sortie.

Run: `flutter build ios --simulator 2>&1 | tail -5`
Expected: `✓ Built build/ios/iphonesimulator/Runner.app`. En cas d'erreur Swift, corriger et rejouer : les noms d'API à vérifier en premier sont `NSMetadataQueryAccessibleUbiquitousExternalDocumentsScope`, `NSMetadataUbiquitousItemPercentDownloadedKey`, `NSMetadataUbiquitousItemIsDownloadingKey`, `FlutterEndOfEventStream`, `FlutterEventChannel(name:binaryMessenger:)`.

- [x] **Step 6 : commit**

```bash
git add ios/Runner/Documents ios/Runner.xcodeproj/project.pbxproj
git commit -m "feat: pont Swift, flux d'un dossier par NSMetadataQuery, download, delete, openInFiles"
```

---

### Task 8 : documentation, vérification complète, installation sur iPhone

**Files:**
- Modify: `docs/superpowers/specs/2026-09-22-icloud-documents-design.md` (section 5)
- Modify: `README.md`
- Modify: `docs/superpowers/plans/2026-09-22-icloud-documents.md` (renvoi), ce plan (cases cochées)

- [x] **Step 1 : spec, section 5**

Remplacer le paragraphe qui commence par « `EventChannel` nommé `colette/documents/folder` (lot 3, remplace l'ancienne méthode `list`) » par :

```markdown
Flux d'un dossier (lot 3, remplace l'ancienne méthode `list`). Un `FlutterEventChannel` n'accepte qu'un abonné à la fois, or la page racine et une sous-page poussée observent chacune leur dossier en même temps : chaque abonnement a donc son propre canal. Flutter appelle d'abord `openFolderStream` (`{path: String}` → `{channel: String}`, nom de la forme `colette/documents/folder/{n}`, `n` croissant) ; Swift ouvre la racine, résout le dossier (erreurs `noFolder`/`accessDenied` renvoyées ici, de façon synchrone), crée le canal et son observateur. Flutter s'abonne ensuite au canal reçu (`receiveBroadcastStream()`, sans argument). Chaque événement est la liste complète du dossier, `List<Map>` : `{name, path, isDirectory, size, modifiedAt (ms epoch UTC), downloadStatus ('downloaded' \| 'downloading' \| 'notDownloaded'), downloadProgress (double, absent hors téléchargement)}`. Une erreur est envoyée comme `FlutterError` avec les mêmes codes que le `MethodChannel`, puis le flux se termine (`FlutterEndOfEventStream`). Le premier événement part à l'abonnement, avant le démarrage de la requête de métadonnées ; les suivants à chaque mise à jour iCloud et après chaque écriture ou suppression réussie via le `MethodChannel` (le plugin garde les observateurs par nom de canal et relance ceux dont le chemin correspond). Le désabonnement arrête la requête, referme la portée sécurisée et libère le canal.
```

et, dans le tableau des méthodes, ajouter la ligne :

```markdown
| `openFolderStream` | `{path: String}` | `{channel: String}`, nom du canal d'événements à écouter |
```

Dans la section 6, paragraphe sur `watch(path)` : remplacer « s'abonne à `EventChannel('colette/documents/folder').receiveBroadcastStream(path)` » par « appelle `openFolderStream` puis s'abonne à `EventChannel(nom reçu).receiveBroadcastStream()` ».

- [x] **Step 2 : README et plans**

`README.md`, ligne « Documents : … » : remplacer par « Documents : consultation en direct du dossier iCloud Drive partagé (choisi une fois par iPhone), aperçu Quick Look avec téléchargement automatique, scan et import, suppression, ouverture dans Fichiers. »

`docs/superpowers/plans/2026-09-22-icloud-documents.md` : ajouter sous le header une ligne « Lot 3 (flux en direct, suppression, Fichiers) : voir `2026-09-23-icloud-documents-lot3.md`. »

Cocher les cases des tâches 1 à 7 de ce plan.

- [x] **Step 3 : vérification complète**

Run: `dart format lib test && dart analyze && flutter test && flutter build ios --release 2>&1 | tail -3`
Expected: 0 changement, 0 problème, suite verte, `✓ Built build/ios/iphoneos/Runner.app`.

- [x] **Step 4 : commit**

```bash
git add docs README.md
git commit -m "docs: spec, README et plans pour le lot 3 des documents iCloud"
```

- [x] **Step 5 : installation par-dessus sur l'iPhone de Maxence** (fait par la session principale, pas par un sous-agent)

```bash
xcrun devicectl device install app --device 273D8811-664A-58F7-BC07-A83762C233B9 build/ios/iphoneos/Runner.app
xcrun devicectl device process launch --device 273D8811-664A-58F7-BC07-A83762C233B9 fr.montet.colette
```

Puis liste de contrôle, points 17 à 26 de la spec (section 8), par Maxence. Si le point 22 échoue (aucune mise à jour sans rafraîchir, aucune progression), c'est que `NSMetadataQueryAccessibleUbiquitousExternalDocumentsScope` ne couvre pas le dossier partagé : appliquer le plan de repli de la section 11 (relistage sur minuterie dans `DocumentsFolderWatcher` tant qu'une entrée est `downloading`), sans toucher au contrat ni à Flutter.

---

## Auto-revue du plan

- **Couverture de la spec** : section 3 (flux, téléchargement, aperçu, suppression, Fichiers, verrou) → Tasks 7 et 4 ; section 4 (`downloadProgress`) → Task 1 ; section 5 (canal, méthodes) → Tasks 2, 7, 8 ; section 6 (repository, providers, contrôleurs) → Tasks 2, 3, 4, 5, 6 ; section 7 (tuile, glissement, bouton, erreurs, l10n) → Tasks 4, 5, 6 ; section 8 (tests, liste 17 à 26) → chaque tâche et Task 8 ; section 11 (repli) → Task 8.
- **Cohérence des noms** : `watch`, `download`, `delete`, `openInFiles`, `openFolderStream` (Dart et Swift) ; `DocumentsPreviewController.open(entry)` ; `DocumentsDeleteController.delete(path)` ; `DocumentsOpenInFilesController.open()` ; `DocumentDeleteDismissible` ; `DocumentsOpenInFilesButton` ; `parentPath` ; `DocumentsLister.startDownload` / `isAvailable` / `realURL` / `locate` ; `DocumentsWriter.delete` ; `DocumentsFolderWatcher.start(sink:)` / `stop()` / `refresh()` / `relativePath`.
- **Écart connu avec la spec initiale du lot 3** : canal par abonnement via `openFolderStream` au lieu d'un canal unique avec le chemin en argument (Task 8 met la spec à jour).

### Écarts à l'exécution

- **Task 4, `fireImmediately`** : `ref.listen(..., fireImmediately: true)` appelle l'écouteur avant de renvoyer la souscription ; une issue immédiate (fichier déjà téléchargé) laissait donc l'écoute ouverte. Corrigé : abonnement d'abord, puis évaluation à la main de la valeur courante (`handle(ref.read(folder))`), drapeau `settled` pour une seule issue.
- **Gardes `ref.mounted`** après chaque `await` dans les trois contrôleurs du lot 3 (aperçu, suppression, Fichiers), plus `if (state.isLoading) return;` en tête de `delete()` et `open()`.
- **Task 5** : garde `context.mounted` au retour de la boîte de dialogue de suppression (ligne démontée entre-temps : rien n'est supprimé) ; glissement désactivé (`DismissDirection.none`) sur toutes les lignes du dossier pendant une suppression.
- **Task 6** : branche d'erreur d'accès sur le bouton Fichiers (`noFolder`/`accessDenied` → invalidation du dossier, vue « accès perdu ») au lieu d'une `SnackBar` pour toute erreur.
- **Task 7** : chemins canoniques (`resolvingSymlinksInPath`) pour le filtre des enfants directs et les clés de progression ; prédicat en OU sur les formes `/private/var/…` et `/var/…` ; état « en téléchargement » collant jusqu'à `downloaded`, disparition de la requête, `Current` ou erreur de téléchargement ; `trashItem` tenté avant `removeItem`, coordination sur l'URL logique ; drapeau `stopped` dans l'observateur (`start` après `stop` sans effet) ; diagnostics `os_log` (échec de démarrage de la requête, nombre de résultats à la fin de la collecte).
