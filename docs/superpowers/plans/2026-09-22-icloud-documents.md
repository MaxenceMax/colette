# Documents du dossier iCloud partagé — Plan d'implémentation

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Consulter depuis Colette un dossier iCloud Drive partagé entre les deux parents (lot 1), puis y ajouter des documents par scan ou import (lot 2).

**Architecture:** Nouvelle feature `lib/features/documents/` (domain, data, presentation). Le dossier racine est choisi une fois par iPhone via le sélecteur iOS et conservé en bookmark de sécurité dans `UserDefaults`. Tout ce qui touche au système de fichiers, à iCloud, à Quick Look, au scanner et aux sélecteurs vit dans un pont Swift interne (`ios/Runner/Documents/`) exposé par un `MethodChannel` `colette/documents`. Flutter ne manipule que des chemins relatifs à la racine. Aucune donnée Firestore.

**Tech Stack:** Flutter, Riverpod 3 codegen, freezed, fpdart, `MethodChannel`, Swift (UIKit, QuickLook, VisionKit, UniformTypeIdentifiers), `mocktail`, `pumpApp`, gem `xcodeproj`.

Spec : `docs/superpowers/specs/2026-09-22-icloud-documents-design.md`.

**Conventions du projet à respecter dans chaque tâche :**

- Après toute modification d'un fichier annoté `@freezed` ou `@riverpod` : `dart run build_runner build -d`.
- Fin de tâche : `dart format lib test`, `dart analyze` (pas `flutter analyze`), `flutter test`.
- Commits en français, préfixes `feat:` / `test:` / `docs:` / `chore:`, avec `git add` explicite des fichiers de la tâche.
- Couleurs via `context.appColor(AppColors.xxx)`, espacements via `AppSpacing`, tailles via `AppSize`, textes via `S.of(context)`. Aucun nombre en dur dans les widgets.
- `switch` sur `AsyncValue`, jamais `.when`. `ref.watch` dans `build`, `ref.read` dans les callbacks.
- Le working tree du worktree ne contient que cette feature : `git add` des fichiers listés dans chaque tâche.

**Précisions par rapport à la spec (la tâche 17 aligne la spec) :**

1. Deux contrôleurs au lieu d'un : `DocumentsPreviewController` (famille indexée par le chemin du fichier, lot 1) et `DocumentsWriteController` (lot 2). La famille permet à chaque ligne d'afficher son propre indicateur et de choisir son message d'erreur sans état supplémentaire.
2. Tests de présentation avec `mocktail` (`MockDocumentsRepository`), comme le reste du projet, plutôt qu'un `FakeDocumentsRepository` dédié.
3. Le mapping `PlatformException → DocumentsFailure` est fait dans le repository (méthode privée `_call`), pas dans `guard()` de `core`, pour ne pas coupler `core` aux codes du canal.
4. Les fichiers Swift sont enregistrés dans `Runner.xcodeproj` avec le gem `xcodeproj` (livré avec CocoaPods, version 1.27 vérifiée), pas à la main.

---

## Lot 1 — Lecture

### Task 1 : Failures, message d'erreur et clés l10n

**Files:**
- Modify: `lib/core/result/failure.dart`
- Modify: `lib/core/ui/failure_message.dart`
- Modify: `lib/l10n/app_fr.arb`
- Test: `test/core/ui/failure_message_documents_test.dart`

- [ ] **Step 1 : Écrire le test rouge**

`test/core/ui/failure_message_documents_test.dart` :

```dart
import 'package:colette/core/result/failure.dart';
import 'package:colette/core/ui/failure_message.dart';
import 'package:colette/l10n/generated/app_localizations.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  late S s;

  setUpAll(() async {
    s = await S.delegate.load(const Locale('fr'));
  });

  test('noFolder et accessDenied → message d\'accès', () {
    const expected = "Colette n'a pas accès à ce dossier";
    expect(
      failureMessage(const DocumentsFailure(DocumentsReason.noFolder), s),
      expected,
    );
    expect(
      failureMessage(const DocumentsFailure(DocumentsReason.accessDenied), s),
      expected,
    );
  });

  test('io → message d\'écriture', () {
    expect(
      failureMessage(const DocumentsFailure(DocumentsReason.io), s),
      "Impossible d'enregistrer le document",
    );
  });

  test('cancelled → message générique (jamais affiché par l\'UI)', () {
    expect(
      failureMessage(const DocumentsFailure(DocumentsReason.cancelled), s),
      'Une erreur est survenue.',
    );
  });
}
```

Ajouter `import 'dart:ui' show Locale;` en tête si `Locale` n'est pas résolu.

- [ ] **Step 2 : Vérifier l'échec**

Run: `flutter test test/core/ui/failure_message_documents_test.dart`
Expected: échec de compilation, `DocumentsFailure` inconnu.

- [ ] **Step 3 : Ajouter la failure**

À la fin de `lib/core/result/failure.dart` :

```dart
/// Raison d'une [DocumentsFailure].
enum DocumentsReason { noFolder, accessDenied, cancelled, io }

/// Erreur du pont natif documents (dossier iCloud).
final class DocumentsFailure extends Failure {
  const DocumentsFailure(this.reason);

  final DocumentsReason reason;
}
```

- [ ] **Step 4 : Ajouter les clés l10n**

Dans `lib/l10n/app_fr.arb`, avant la clé `"copied"` :

```json
  "documentsCardTitle": "Documents",
  "documentsCardEmptyBody": "Retrouvez vos ordonnances et documents",
  "documentsCardPick": "Choisir le dossier partagé",
  "documentsEmptyFolder": "Aucun document dans ce dossier",
  "documentsLostAccessBody": "Colette n'a plus accès au dossier",
  "documentsActionScan": "Scanner un document",
  "documentsActionImport": "Importer un fichier",
  "documentsErrorNotDownloaded": "Ce document n'est pas encore téléchargé sur cet iPhone",
  "documentsErrorWrite": "Impossible d'enregistrer le document",
  "documentsErrorAccess": "Colette n'a pas accès à ce dossier",
  "settingsDocumentsNone": "Aucun dossier choisi",
  "settingsDocumentsFolder": "Dossier documents",
  "settingsDocumentsChange": "Changer de dossier",
  "settingsDocumentsForget": "Oublier le dossier",
  "settingsDocumentsForgetConfirm": "Colette n'affichera plus ce dossier. Vos fichiers ne sont pas supprimés.",
```

Puis `flutter gen-l10n` (ou `flutter pub get`, qui régénère `lib/l10n/generated/`).

- [ ] **Step 5 : Traduire la failure**

Dans `lib/core/ui/failure_message.dart`, ajouter un cas avant `_ => s.errorUnknown` :

```dart
  DocumentsFailure(:final reason) => switch (reason) {
    DocumentsReason.noFolder ||
    DocumentsReason.accessDenied => s.documentsErrorAccess,
    DocumentsReason.io => s.documentsErrorWrite,
    DocumentsReason.cancelled => s.errorUnknown,
  },
```

- [ ] **Step 6 : Vérifier le succès**

Run: `flutter test test/core/ui/failure_message_documents_test.dart`
Expected: 3 tests verts.

- [ ] **Step 7 : Commit**

```bash
dart format lib test && dart analyze
git add lib/core/result/failure.dart lib/core/ui/failure_message.dart lib/l10n/app_fr.arb test/core/ui/failure_message_documents_test.dart
git commit -m "feat: DocumentsFailure et clés l10n des documents"
```

---

### Task 2 : Domaine — entités, repository et tri

**Files:**
- Create: `lib/features/documents/domain/entities/document_root.dart`
- Create: `lib/features/documents/domain/entities/download_status.dart`
- Create: `lib/features/documents/domain/entities/document_entry.dart`
- Create: `lib/features/documents/domain/repositories/documents_repository.dart`
- Create: `lib/features/documents/domain/use_cases/sort_document_entries.dart`
- Test: `test/features/documents/domain/sort_document_entries_test.dart`

- [ ] **Step 1 : Écrire le test rouge**

`test/features/documents/domain/sort_document_entries_test.dart` :

```dart
import 'package:colette/features/documents/domain/entities/document_entry.dart';
import 'package:colette/features/documents/domain/entities/download_status.dart';
import 'package:colette/features/documents/domain/use_cases/sort_document_entries.dart';
import 'package:flutter_test/flutter_test.dart';

DocumentEntry entry(
  String name, {
  bool isDirectory = false,
  DateTime? modifiedAt,
}) => DocumentEntry(
  name: name,
  path: name,
  isDirectory: isDirectory,
  size: 0,
  modifiedAt: modifiedAt ?? DateTime(2026, 9, 1),
  downloadStatus: DownloadStatus.downloaded,
);

void main() {
  test('dossiers d\'abord, triés par nom sans tenir compte de la casse', () {
    final sorted = sortDocumentEntries([
      entry('zed.pdf'),
      entry('ordonnances', isDirectory: true),
      entry('Administratif', isDirectory: true),
      entry('carnet', isDirectory: true),
    ]);
    expect(sorted.map((e) => e.name).toList(), [
      'Administratif',
      'carnet',
      'ordonnances',
      'zed.pdf',
    ]);
  });

  test('fichiers par date décroissante, puis nom croissant', () {
    final sorted = sortDocumentEntries([
      entry('b.pdf', modifiedAt: DateTime(2026, 9, 10)),
      entry('a.pdf', modifiedAt: DateTime(2026, 9, 10)),
      entry('old.pdf', modifiedAt: DateTime(2026, 8, 1)),
      entry('new.pdf', modifiedAt: DateTime(2026, 9, 20)),
    ]);
    expect(sorted.map((e) => e.name).toList(), [
      'new.pdf',
      'a.pdf',
      'b.pdf',
      'old.pdf',
    ]);
  });

  test('ne modifie pas la liste d\'entrée', () {
    final input = [entry('b.pdf'), entry('a', isDirectory: true)];
    sortDocumentEntries(input);
    expect(input.first.name, 'b.pdf');
  });
}
```

- [ ] **Step 2 : Vérifier l'échec**

Run: `flutter test test/features/documents/domain/sort_document_entries_test.dart`
Expected: échec de compilation.

- [ ] **Step 3 : Écrire les entités**

`lib/features/documents/domain/entities/document_root.dart` :

```dart
import 'package:freezed_annotation/freezed_annotation.dart';

part 'document_root.freezed.dart';

/// Dossier racine choisi par l'utilisateur dans le sélecteur iOS.
@freezed
abstract class DocumentRoot with _$DocumentRoot {
  const factory DocumentRoot({required String name}) = _DocumentRoot;
}
```

`lib/features/documents/domain/entities/download_status.dart` :

```dart
/// Statut de téléchargement iCloud d'un fichier sur cet iPhone.
enum DownloadStatus { downloaded, downloading, notDownloaded }
```

`lib/features/documents/domain/entities/document_entry.dart` :

```dart
import 'package:colette/features/documents/domain/entities/download_status.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

part 'document_entry.freezed.dart';

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
  }) = _DocumentEntry;
}
```

- [ ] **Step 4 : Écrire l'interface du repository**

`lib/features/documents/domain/repositories/documents_repository.dart` :

```dart
import 'package:colette/core/result/failure.dart';
import 'package:colette/features/documents/domain/entities/document_entry.dart';
import 'package:colette/features/documents/domain/entities/document_root.dart';
import 'package:fpdart/fpdart.dart';

/// Accès au dossier iCloud choisi. Tous les chemins sont relatifs à la racine
/// (`''` pour la racine, séparateur `/`, jamais de `/` initial).
abstract interface class DocumentsRepository {
  /// Dossier racine courant, `null` si aucun n'a été choisi.
  Future<Either<Failure, DocumentRoot?>> rootFolder();

  /// Ouvre le sélecteur iOS ; `DocumentsReason.cancelled` si l'utilisateur annule.
  Future<Either<Failure, DocumentRoot>> pickRootFolder();

  Future<Either<Failure, void>> forgetRootFolder();

  /// Contenu brut (non trié) d'un dossier.
  Future<Either<Failure, List<DocumentEntry>>> list(String path);

  /// Télécharge si besoin puis affiche l'aperçu ; revient à la fermeture.
  Future<Either<Failure, void>> preview(String path);

  /// Scanne avec l'appareil photo et écrit un PDF ; renvoie le nom final.
  Future<Either<Failure, String>> scan({
    required String folderPath,
    required String fileName,
  });

  /// Copie un fichier choisi par l'utilisateur ; renvoie le nom final.
  Future<Either<Failure, String>> importFile({required String folderPath});
}
```

- [ ] **Step 5 : Écrire le tri**

`lib/features/documents/domain/use_cases/sort_document_entries.dart` :

```dart
import 'package:colette/features/documents/domain/entities/document_entry.dart';

int _byName(DocumentEntry a, DocumentEntry b) =>
    a.name.toLowerCase().compareTo(b.name.toLowerCase());

int _byDateDescThenName(DocumentEntry a, DocumentEntry b) {
  final byDate = b.modifiedAt.compareTo(a.modifiedAt);
  return byDate != 0 ? byDate : _byName(a, b);
}

/// Sous-dossiers d'abord (nom, insensible à la casse), puis fichiers
/// (date de modification décroissante, nom croissant à égalité).
List<DocumentEntry> sortDocumentEntries(List<DocumentEntry> entries) {
  final folders = entries.where((e) => e.isDirectory).toList()..sort(_byName);
  final files = entries.where((e) => !e.isDirectory).toList()
    ..sort(_byDateDescThenName);
  return [...folders, ...files];
}
```

- [ ] **Step 6 : Générer et vérifier**

Run: `dart run build_runner build -d && flutter test test/features/documents/domain/sort_document_entries_test.dart`
Expected: 3 tests verts.

- [ ] **Step 7 : Commit**

```bash
dart format lib test && dart analyze
git add lib/features/documents/domain test/features/documents/domain/sort_document_entries_test.dart
git commit -m "feat: domaine documents, entités, repository et tri"
```

---

### Task 3 : Data — `DocumentEntryDto`

**Files:**
- Create: `lib/features/documents/data/dtos/document_entry_dto.dart`
- Test: `test/features/documents/data/document_entry_dto_test.dart`

- [ ] **Step 1 : Écrire le test rouge**

`test/features/documents/data/document_entry_dto_test.dart` :

```dart
import 'package:colette/features/documents/data/dtos/document_entry_dto.dart';
import 'package:colette/features/documents/domain/entities/download_status.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  final modifiedAt = DateTime.utc(2026, 9, 22, 12, 30);

  Map<Object?, Object?> map({String status = 'downloaded'}) => {
    'name': 'ordonnance.pdf',
    'path': 'Ordonnances/ordonnance.pdf',
    'isDirectory': false,
    'size': 1234,
    'modifiedAt': modifiedAt.millisecondsSinceEpoch,
    'downloadStatus': status,
  };

  test('fromMap mappe tous les champs', () {
    final entry = DocumentEntryDto.fromMap(map());
    expect(entry.name, 'ordonnance.pdf');
    expect(entry.path, 'Ordonnances/ordonnance.pdf');
    expect(entry.isDirectory, isFalse);
    expect(entry.size, 1234);
    expect(entry.modifiedAt.toUtc(), modifiedAt);
    expect(entry.downloadStatus, DownloadStatus.downloaded);
  });

  test('fromMap lit les trois statuts', () {
    expect(
      DocumentEntryDto.fromMap(map(status: 'downloading')).downloadStatus,
      DownloadStatus.downloading,
    );
    expect(
      DocumentEntryDto.fromMap(map(status: 'notDownloaded')).downloadStatus,
      DownloadStatus.notDownloaded,
    );
    expect(
      DocumentEntryDto.fromMap(map(status: 'autre')).downloadStatus,
      DownloadStatus.downloaded,
    );
  });

  test('fromMap applique des défauts sur les champs optionnels', () {
    final entry = DocumentEntryDto.fromMap(const {
      'name': 'Ordonnances',
      'path': 'Ordonnances',
      'isDirectory': true,
    });
    expect(entry.isDirectory, isTrue);
    expect(entry.size, 0);
    expect(entry.modifiedAt.millisecondsSinceEpoch, 0);
    expect(entry.downloadStatus, DownloadStatus.downloaded);
  });
}
```

- [ ] **Step 2 : Vérifier l'échec**

Run: `flutter test test/features/documents/data/document_entry_dto_test.dart`
Expected: échec de compilation.

- [ ] **Step 3 : Écrire le DTO**

`lib/features/documents/data/dtos/document_entry_dto.dart` :

```dart
import 'package:colette/features/documents/domain/entities/document_entry.dart';
import 'package:colette/features/documents/domain/entities/download_status.dart';

/// Mapper des maps renvoyées par le canal `colette/documents` vers [DocumentEntry].
abstract final class DocumentEntryDto {
  static DocumentEntry fromMap(Map<Object?, Object?> map) => DocumentEntry(
    name: map['name'] as String,
    path: map['path'] as String,
    isDirectory: map['isDirectory'] as bool? ?? false,
    size: (map['size'] as num?)?.toInt() ?? 0,
    modifiedAt: DateTime.fromMillisecondsSinceEpoch(
      (map['modifiedAt'] as num?)?.toInt() ?? 0,
      isUtc: true,
    ).toLocal(),
    downloadStatus: switch (map['downloadStatus']) {
      'downloading' => DownloadStatus.downloading,
      'notDownloaded' => DownloadStatus.notDownloaded,
      _ => DownloadStatus.downloaded,
    },
  );
}
```

- [ ] **Step 4 : Vérifier le succès**

Run: `flutter test test/features/documents/data/document_entry_dto_test.dart`
Expected: 3 tests verts.

- [ ] **Step 5 : Commit**

```bash
dart format lib test && dart analyze
git add lib/features/documents/data/dtos/document_entry_dto.dart test/features/documents/data/document_entry_dto_test.dart
git commit -m "feat: DocumentEntryDto depuis les maps du canal natif"
```

---

### Task 4 : Data — `NativeDocumentsRepository`

**Files:**
- Create: `lib/features/documents/data/native_documents_repository.dart`
- Test: `test/features/documents/data/native_documents_repository_test.dart`

- [ ] **Step 1 : Écrire le test rouge**

`test/features/documents/data/native_documents_repository_test.dart` :

```dart
import 'package:colette/core/result/failure.dart';
import 'package:colette/features/documents/data/native_documents_repository.dart';
import 'package:colette/features/documents/domain/entities/document_root.dart';
import 'package:colette/features/documents/domain/entities/download_status.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  const channel = MethodChannel(NativeDocumentsRepository.channelName);
  late List<MethodCall> calls;
  late NativeDocumentsRepository repo;

  void mock(Object? Function(MethodCall call) handler) {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, (call) async {
          calls.add(call);
          return handler(call);
        });
  }

  setUp(() {
    calls = [];
    repo = NativeDocumentsRepository(channel);
  });

  tearDown(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, null);
  });

  test('rootFolder renvoie null sans dossier', () async {
    mock((_) => null);
    final result = await repo.rootFolder();
    expect(result.toNullable(), isNull);
    expect(calls.single.method, 'rootFolder');
  });

  test('rootFolder mappe le nom', () async {
    mock((_) => {'name': 'Colette'});
    final result = await repo.rootFolder();
    expect(result.toNullable(), const DocumentRoot(name: 'Colette'));
  });

  test('pickRootFolder renvoie le dossier choisi', () async {
    mock((_) => {'name': 'Partagé'});
    final result = await repo.pickRootFolder();
    expect(result.toNullable(), const DocumentRoot(name: 'Partagé'));
    expect(calls.single.method, 'pickRootFolder');
  });

  test('forgetRootFolder appelle le canal', () async {
    mock((_) => null);
    final result = await repo.forgetRootFolder();
    expect(result.isRight(), isTrue);
    expect(calls.single.method, 'forgetRootFolder');
  });

  test('list transmet le chemin et mappe les entrées', () async {
    mock(
      (_) => [
        {
          'name': 'a.pdf',
          'path': 'Ordonnances/a.pdf',
          'isDirectory': false,
          'size': 10,
          'modifiedAt': 1000,
          'downloadStatus': 'notDownloaded',
        },
      ],
    );
    final result = await repo.list('Ordonnances');
    final entries = result.toNullable()!;
    expect(calls.single.arguments, {'path': 'Ordonnances'});
    expect(entries.single.name, 'a.pdf');
    expect(entries.single.downloadStatus, DownloadStatus.notDownloaded);
  });

  test('preview transmet le chemin', () async {
    mock((_) => null);
    final result = await repo.preview('a.pdf');
    expect(result.isRight(), isTrue);
    expect(calls.single.method, 'preview');
    expect(calls.single.arguments, {'path': 'a.pdf'});
  });

  test('scan transmet dossier et nom, renvoie le nom final', () async {
    mock((_) => {'name': 'Scan 22-09-2026 14h32 (2).pdf'});
    final result = await repo.scan(
      folderPath: 'Ordonnances',
      fileName: 'Scan 22-09-2026 14h32.pdf',
    );
    expect(result.toNullable(), 'Scan 22-09-2026 14h32 (2).pdf');
    expect(calls.single.arguments, {
      'path': 'Ordonnances',
      'fileName': 'Scan 22-09-2026 14h32.pdf',
    });
  });

  test('importFile transmet le dossier, renvoie le nom final', () async {
    mock((_) => {'name': 'facture.pdf'});
    final result = await repo.importFile(folderPath: '');
    expect(result.toNullable(), 'facture.pdf');
    expect(calls.single.method, 'importFile');
    expect(calls.single.arguments, {'path': ''});
  });

  for (final (code, reason) in [
    ('noFolder', DocumentsReason.noFolder),
    ('accessDenied', DocumentsReason.accessDenied),
    ('cancelled', DocumentsReason.cancelled),
    ('io', DocumentsReason.io),
  ]) {
    test('code $code → DocumentsFailure.$reason', () async {
      mock((_) => throw PlatformException(code: code));
      final result = await repo.list('');
      expect(result.getLeft().toNullable(), DocumentsFailure(reason));
    });
  }

  test('code inconnu → UnknownFailure', () async {
    mock((_) => throw PlatformException(code: 'weird'));
    final result = await repo.list('');
    expect(result.getLeft().toNullable(), isA<UnknownFailure>());
  });

  test('canal absent → UnknownFailure', () async {
    final result = await repo.list('');
    expect(result.getLeft().toNullable(), isA<UnknownFailure>());
  });
}
```

Ce test compare des `DocumentsFailure` par valeur : ajouter dans `lib/core/result/failure.dart`, dans la classe `DocumentsFailure` :

```dart
  @override
  bool operator ==(Object other) =>
      other is DocumentsFailure && other.reason == reason;

  @override
  int get hashCode => reason.hashCode;
```

- [ ] **Step 2 : Vérifier l'échec**

Run: `flutter test test/features/documents/data/native_documents_repository_test.dart`
Expected: échec de compilation.

- [ ] **Step 3 : Écrire le repository**

`lib/features/documents/data/native_documents_repository.dart` :

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

/// Repository documents adossé au pont Swift via un [MethodChannel].
class NativeDocumentsRepository implements DocumentsRepository {
  NativeDocumentsRepository(this._channel);

  static const channelName = 'colette/documents';

  final MethodChannel _channel;

  /// Comme `guard()`, avec le mapping des codes du canal en [DocumentsFailure].
  Future<Either<Failure, T>> _call<T>(Future<T> Function() action) async {
    try {
      return right(await action());
    } on PlatformException catch (e, stackTrace) {
      final reason = _reasons[e.code];
      if (reason != null) return left(DocumentsFailure(reason));
      developer.log(
        'Documents natif : ${e.code}',
        error: e,
        stackTrace: stackTrace,
        name: 'colette',
      );
      return left(UnknownFailure(e, stackTrace));
    } catch (e, stackTrace) {
      developer.log(
        'Documents natif',
        error: e,
        stackTrace: stackTrace,
        name: 'colette',
      );
      return left(UnknownFailure(e, stackTrace));
    }
  }

  DocumentRoot _root(Map<String, Object?> map) =>
      DocumentRoot(name: map['name'] as String);

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
        return [
          for (final item in raw ?? const [])
            DocumentEntryDto.fromMap(item! as Map<Object?, Object?>),
        ];
      });

  @override
  Future<Either<Failure, void>> preview(String path) =>
      _call(() => _channel.invokeMethod<void>('preview', {'path': path}));

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

- [ ] **Step 4 : Vérifier le succès**

Run: `flutter test test/features/documents/data/native_documents_repository_test.dart`
Expected: 14 tests verts.

- [ ] **Step 5 : Commit**

```bash
dart format lib test && dart analyze
git add lib/core/result/failure.dart lib/features/documents/data/native_documents_repository.dart test/features/documents/data/native_documents_repository_test.dart
git commit -m "feat: NativeDocumentsRepository sur le canal colette/documents"
```

---

### Task 5 : Providers — repository, racine, contenu d'un dossier

**Files:**
- Create: `lib/features/documents/presentation/providers/documents_providers.dart`
- Create: `lib/features/documents/presentation/providers/documents_root.dart`
- Test: `test/features/documents/presentation/documents_providers_test.dart`
- Test: `test/features/documents/presentation/documents_root_test.dart`

- [ ] **Step 1 : Écrire les tests rouges**

`test/features/documents/presentation/documents_providers_test.dart` :

```dart
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

  test('documentsFolder liste puis trie', () async {
    when(() => repo.list('Ordonnances')).thenAnswer(
      (_) async => right([entry('z.pdf'), entry('Sous', isDirectory: true)]),
    );
    final entries = await container.read(
      documentsFolderProvider('Ordonnances').future,
    );
    expect(entries.map((e) => e.name).toList(), ['Sous', 'z.pdf']);
  });

  test('documentsFolder relance la failure', () async {
    when(
      () => repo.list(''),
    ).thenAnswer((_) async => left(const DocumentsFailure(DocumentsReason.io)));
    expect(
      container.read(documentsFolderProvider('').future),
      throwsA(const DocumentsFailure(DocumentsReason.io)),
    );
  });
}
```

`test/features/documents/presentation/documents_root_test.dart` :

```dart
import 'package:colette/core/result/failure.dart';
import 'package:colette/features/documents/domain/entities/document_root.dart';
import 'package:colette/features/documents/domain/repositories/documents_repository.dart';
import 'package:colette/features/documents/presentation/providers/documents_providers.dart';
import 'package:colette/features/documents/presentation/providers/documents_root.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:mocktail/mocktail.dart';

class MockDocumentsRepository extends Mock implements DocumentsRepository {}

void main() {
  late MockDocumentsRepository repo;
  late ProviderContainer container;
  const root = DocumentRoot(name: 'Colette');

  setUp(() {
    repo = MockDocumentsRepository();
    when(() => repo.list(any())).thenAnswer((_) async => right(const []));
    container = ProviderContainer(
      overrides: [documentsRepositoryProvider.overrideWithValue(repo)],
    );
    addTearDown(container.dispose);
  });

  DocumentsRoot notifier() => container.read(documentsRootProvider.notifier);

  test('build lit le dossier racine', () async {
    when(() => repo.rootFolder()).thenAnswer((_) async => right(root));
    expect(await container.read(documentsRootProvider.future), root);
  });

  test('pick choisit le dossier et invalide les listes', () async {
    when(() => repo.rootFolder()).thenAnswer((_) async => right(null));
    when(() => repo.pickRootFolder()).thenAnswer((_) async => right(root));
    await container.read(documentsRootProvider.future);
    container.listen(documentsFolderProvider(''), (_, _) {});
    await container.read(documentsFolderProvider('').future);

    expect(await notifier().pick(), isTrue);

    expect(container.read(documentsRootProvider).value, root);
    await container.read(documentsFolderProvider('').future);
    verify(() => repo.list('')).called(2);
  });

  test('pick annulé restaure l\'état précédent', () async {
    when(() => repo.rootFolder()).thenAnswer((_) async => right(root));
    when(() => repo.pickRootFolder()).thenAnswer(
      (_) async => left(const DocumentsFailure(DocumentsReason.cancelled)),
    );
    await container.read(documentsRootProvider.future);

    expect(await notifier().pick(), isFalse);

    expect(container.read(documentsRootProvider), const AsyncData(root));
  });

  test('pick en échec passe en erreur', () async {
    when(() => repo.rootFolder()).thenAnswer((_) async => right(null));
    when(() => repo.pickRootFolder()).thenAnswer(
      (_) async => left(const DocumentsFailure(DocumentsReason.io)),
    );
    await container.read(documentsRootProvider.future);

    expect(await notifier().pick(), isFalse);

    expect(container.read(documentsRootProvider).hasError, isTrue);
  });

  test('forget oublie le dossier', () async {
    when(() => repo.rootFolder()).thenAnswer((_) async => right(root));
    when(() => repo.forgetRootFolder()).thenAnswer((_) async => right(null));
    await container.read(documentsRootProvider.future);

    await notifier().forget();

    expect(container.read(documentsRootProvider), const AsyncData(null));
    verify(() => repo.forgetRootFolder()).called(1);
  });
}
```

- [ ] **Step 2 : Vérifier l'échec**

Run: `flutter test test/features/documents/presentation/`
Expected: échec de compilation.

- [ ] **Step 3 : Écrire les providers**

`lib/features/documents/presentation/providers/documents_providers.dart` :

```dart
import 'package:colette/features/documents/data/native_documents_repository.dart';
import 'package:colette/features/documents/domain/entities/document_entry.dart';
import 'package:colette/features/documents/domain/repositories/documents_repository.dart';
import 'package:colette/features/documents/domain/use_cases/sort_document_entries.dart';
import 'package:flutter/services.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'documents_providers.g.dart';

/// Sans état : `keepAlive` car consommé par [DocumentsRoot] (keepAlive).
@Riverpod(keepAlive: true)
DocumentsRepository documentsRepository(Ref ref) => NativeDocumentsRepository(
  const MethodChannel(NativeDocumentsRepository.channelName),
);

/// Contenu trié d'un dossier, [path] relatif à la racine (`''` = racine).
@riverpod
Future<List<DocumentEntry>> documentsFolder(Ref ref, String path) async {
  final result = await ref.watch(documentsRepositoryProvider).list(path);
  return result.fold((failure) => throw failure, sortDocumentEntries);
}
```

`lib/features/documents/presentation/providers/documents_root.dart` :

```dart
import 'package:colette/core/result/failure.dart';
import 'package:colette/features/documents/domain/entities/document_root.dart';
import 'package:colette/features/documents/presentation/providers/documents_providers.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'documents_root.g.dart';

/// Dossier racine choisi sur cet iPhone ; `null` tant qu'aucun n'est choisi.
@Riverpod(keepAlive: true)
class DocumentsRoot extends _$DocumentsRoot {
  @override
  Future<DocumentRoot?> build() async {
    final result = await ref.watch(documentsRepositoryProvider).rootFolder();
    return result.fold((failure) => throw failure, (root) => root);
  }

  /// Ouvre le sélecteur iOS. Renvoie `true` si un dossier a été choisi.
  Future<bool> pick() async {
    final previous = state;
    state = const AsyncLoading();
    final result = await ref.read(documentsRepositoryProvider).pickRootFolder();
    return result.fold(
      (failure) {
        state = switch (failure) {
          DocumentsFailure(reason: DocumentsReason.cancelled) => previous,
          _ => AsyncError(failure, StackTrace.current),
        };
        return false;
      },
      (root) {
        state = AsyncData(root);
        ref.invalidate(documentsFolderProvider);
        return true;
      },
    );
  }

  /// Oublie le dossier : Colette ne l'affiche plus, rien n'est supprimé.
  Future<void> forget() async {
    final result = await ref
        .read(documentsRepositoryProvider)
        .forgetRootFolder();
    state = result.fold(
      (failure) => AsyncError(failure, StackTrace.current),
      (_) => const AsyncData(null),
    );
    ref.invalidate(documentsFolderProvider);
  }
}
```

- [ ] **Step 4 : Générer et vérifier**

Run: `dart run build_runner build -d && flutter test test/features/documents/presentation/`
Expected: 7 tests verts.

- [ ] **Step 5 : Commit**

```bash
dart format lib test && dart analyze
git add lib/features/documents/presentation/providers test/features/documents/presentation/documents_providers_test.dart test/features/documents/presentation/documents_root_test.dart
git commit -m "feat: providers documents, racine et contenu de dossier"
```

---

### Task 6 : `DocumentsPreviewController`

**Files:**
- Create: `lib/features/documents/presentation/providers/documents_preview_controller.dart`
- Test: `test/features/documents/presentation/documents_preview_controller_test.dart`

- [ ] **Step 1 : Écrire le test rouge**

```dart
import 'package:colette/core/result/failure.dart';
import 'package:colette/features/documents/domain/repositories/documents_repository.dart';
import 'package:colette/features/documents/presentation/providers/documents_preview_controller.dart';
import 'package:colette/features/documents/presentation/providers/documents_providers.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:mocktail/mocktail.dart';

class MockDocumentsRepository extends Mock implements DocumentsRepository {}

void main() {
  late MockDocumentsRepository repo;
  late ProviderContainer container;
  const path = 'Ordonnances/a.pdf';

  setUp(() {
    repo = MockDocumentsRepository();
    container = ProviderContainer(
      overrides: [documentsRepositoryProvider.overrideWithValue(repo)],
    );
    addTearDown(container.dispose);
    container.listen(documentsPreviewControllerProvider(path), (_, _) {});
  });

  test('preview appelle le repository avec le chemin', () async {
    when(() => repo.preview(path)).thenAnswer((_) async => right(null));
    await container
        .read(documentsPreviewControllerProvider(path).notifier)
        .preview();
    verify(() => repo.preview(path)).called(1);
    expect(
      container.read(documentsPreviewControllerProvider(path)),
      const AsyncData<void>(null),
    );
  });

  test('cancelled ne produit pas d\'erreur', () async {
    when(() => repo.preview(path)).thenAnswer(
      (_) async => left(const DocumentsFailure(DocumentsReason.cancelled)),
    );
    await container
        .read(documentsPreviewControllerProvider(path).notifier)
        .preview();
    expect(container.read(documentsPreviewControllerProvider(path)).hasError, isFalse);
  });

  test('io passe en erreur', () async {
    when(() => repo.preview(path)).thenAnswer(
      (_) async => left(const DocumentsFailure(DocumentsReason.io)),
    );
    await container
        .read(documentsPreviewControllerProvider(path).notifier)
        .preview();
    expect(
      container.read(documentsPreviewControllerProvider(path)).error,
      const DocumentsFailure(DocumentsReason.io),
    );
  });
}
```

- [ ] **Step 2 : Vérifier l'échec**

Run: `flutter test test/features/documents/presentation/documents_preview_controller_test.dart`
Expected: échec de compilation.

- [ ] **Step 3 : Écrire le contrôleur**

`lib/features/documents/presentation/providers/documents_preview_controller.dart` :

```dart
import 'dart:async';

import 'package:colette/core/result/failure.dart';
import 'package:colette/features/documents/presentation/providers/documents_providers.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'documents_preview_controller.g.dart';

/// Aperçu d'un fichier, une instance par chemin : chaque ligne suit la sienne.
@riverpod
class DocumentsPreviewController extends _$DocumentsPreviewController {
  @override
  FutureOr<void> build(String path) {}

  Future<void> preview() async {
    state = const AsyncLoading();
    final result = await ref.read(documentsRepositoryProvider).preview(path);
    state = result.fold(
      (failure) => switch (failure) {
        DocumentsFailure(reason: DocumentsReason.cancelled) =>
          const AsyncData(null),
        _ => AsyncError(failure, StackTrace.current),
      },
      (_) => const AsyncData(null),
    );
  }
}
```

- [ ] **Step 4 : Générer et vérifier**

Run: `dart run build_runner build -d && flutter test test/features/documents/presentation/documents_preview_controller_test.dart`
Expected: 3 tests verts.

- [ ] **Step 5 : Commit**

```bash
dart format lib test && dart analyze
git add lib/features/documents/presentation/providers/documents_preview_controller.dart lib/features/documents/presentation/providers/documents_preview_controller.g.dart test/features/documents/presentation/documents_preview_controller_test.dart
git commit -m "feat: DocumentsPreviewController par chemin de fichier"
```

---

### Task 7 : Route `/today/documents` et format de date court

**Files:**
- Modify: `lib/app/router/app_router.dart`
- Modify: `lib/core/dates/time_format.dart`
- Test: `test/app/documents_location_test.dart`
- Test: `test/core/dates/time_format_test.dart` (créer)

- [ ] **Step 1 : Écrire les tests rouges**

`test/app/documents_location_test.dart` :

```dart
import 'package:colette/app/router/app_router.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('racine', () {
    expect(AppRoutes.documentsLocation(''), '/today/documents');
  });

  test('sous-dossier encodé en paramètre de requête', () {
    expect(
      AppRoutes.documentsLocation('Ordonnances/2026'),
      '/today/documents?path=Ordonnances%2F2026',
    );
  });
}
```

`test/core/dates/time_format_test.dart` :

```dart
import 'package:colette/core/dates/time_format.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';

void main() {
  setUpAll(() => initializeDateFormatting('fr'));

  test('formatShortDate : « 22 sept. 2026 »', () {
    expect(formatShortDate(DateTime(2026, 9, 22)), '22 sept. 2026');
  });
}
```

- [ ] **Step 2 : Vérifier l'échec**

Run: `flutter test test/app/documents_location_test.dart test/core/dates/time_format_test.dart`
Expected: échec de compilation.

- [ ] **Step 3 : Ajouter la route**

Dans `lib/app/router/app_router.dart`, dans `AppRoutes` après `openBottleParam` :

```dart
  /// Page Documents, imbriquée sous Aujourd'hui pour garder la barre d'onglets.
  static const todayDocuments = '/today/documents';

  /// Paramètre de requête : chemin relatif du dossier affiché.
  static const documentsPathParam = 'path';

  /// Emplacement de la page Documents pour un dossier ([path] vide = racine).
  static String documentsLocation(String path) => path.isEmpty
      ? todayDocuments
      : Uri(
          path: todayDocuments,
          queryParameters: {documentsPathParam: path},
        ).toString();
```

Remplacer la `GoRoute` de `AppRoutes.today` par :

```dart
              GoRoute(
                path: AppRoutes.today,
                builder: (_, _) => const DashboardPage(),
                routes: [
                  GoRoute(
                    path: 'documents',
                    builder: (_, state) => DocumentsPage(
                      path:
                          state.uri.queryParameters[AppRoutes
                              .documentsPathParam] ??
                          '',
                    ),
                  ),
                ],
              ),
```

Ajouter l'import `package:colette/features/documents/presentation/pages/documents_page.dart`. La page n'existe pas encore : créer un squelette minimal dans `lib/features/documents/presentation/pages/documents_page.dart` que la tâche 9 remplacera :

```dart
import 'package:flutter/material.dart';

/// Liste d'un dossier du dossier iCloud partagé (complétée en tâche 9).
class DocumentsPage extends StatelessWidget {
  const DocumentsPage({super.key, this.path = ''});

  final String path;

  @override
  Widget build(BuildContext context) => const Scaffold();
}
```

- [ ] **Step 4 : Ajouter le format de date**

À la fin de `lib/core/dates/time_format.dart` :

```dart
/// « 22 sept. 2026 ».
String formatShortDate(DateTime day) =>
    DateFormat('d MMM yyyy', 'fr').format(day);
```

- [ ] **Step 5 : Vérifier le succès**

Run: `flutter test test/app/ test/core/dates/`
Expected: tous verts, y compris `app_router_test.dart` et `notifications_gate_test.dart` existants.

- [ ] **Step 6 : Commit**

```bash
dart format lib test && dart analyze
git add lib/app/router/app_router.dart lib/core/dates/time_format.dart lib/features/documents/presentation/pages/documents_page.dart test/app/documents_location_test.dart test/core/dates/time_format_test.dart
git commit -m "feat: route /today/documents et formatShortDate"
```

---

### Task 8 : Carte « Documents » sur Aujourd'hui

**Files:**
- Create: `lib/features/documents/presentation/widgets/documents_card.dart`
- Modify: `lib/features/dashboard/presentation/pages/dashboard_page.dart`
- Modify: `test/features/dashboard/presentation/dashboard_page_test.dart`
- Test: `test/features/documents/presentation/documents_card_test.dart`

- [ ] **Step 1 : Écrire le test rouge**

`test/features/documents/presentation/documents_card_test.dart` :

```dart
import 'package:colette/app/router/app_router.dart';
import 'package:colette/core/result/failure.dart';
import 'package:colette/core/theme/theme_service.dart';
import 'package:colette/features/documents/domain/entities/document_root.dart';
import 'package:colette/features/documents/domain/repositories/documents_repository.dart';
import 'package:colette/features/documents/presentation/providers/documents_providers.dart';
import 'package:colette/features/documents/presentation/widgets/documents_card.dart';
import 'package:colette/l10n/generated/app_localizations.dart';
import 'package:colette/shared/ui/widgets/colette_card_surface.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:go_router/go_router.dart';
import 'package:mocktail/mocktail.dart';

import '../../../helpers/pump_app.dart';

class MockDocumentsRepository extends Mock implements DocumentsRepository {}

void main() {
  late MockDocumentsRepository repo;

  setUp(() => repo = MockDocumentsRepository());

  Future<void> pumpCard(WidgetTester tester) => pumpApp(
    tester,
    const Scaffold(body: DocumentsCard()),
    overrides: [documentsRepositoryProvider.overrideWithValue(repo)],
  );

  testWidgets('sans dossier : invitation à choisir', (tester) async {
    when(() => repo.rootFolder()).thenAnswer((_) async => right(null));
    await pumpCard(tester);
    expect(find.text('Retrouvez vos ordonnances et documents'), findsOneWidget);
    expect(find.text('Choisir le dossier partagé'), findsOneWidget);
  });

  testWidgets('en erreur : même rendu que sans dossier', (tester) async {
    when(() => repo.rootFolder()).thenAnswer(
      (_) async => left(const DocumentsFailure(DocumentsReason.io)),
    );
    await pumpCard(tester);
    expect(find.text('Choisir le dossier partagé'), findsOneWidget);
  });

  testWidgets('« Choisir » ouvre le sélecteur puis affiche le dossier', (
    tester,
  ) async {
    when(() => repo.rootFolder()).thenAnswer((_) async => right(null));
    when(
      () => repo.pickRootFolder(),
    ).thenAnswer((_) async => right(const DocumentRoot(name: 'Colette')));
    await pumpCard(tester);
    await tester.tap(find.text('Choisir le dossier partagé'));
    await tester.pumpAndSettle();
    verify(() => repo.pickRootFolder()).called(1);
    expect(find.text('Documents'), findsOneWidget);
    expect(find.text('Colette'), findsOneWidget);
  });

  testWidgets('avec dossier : un tap ouvre la page Documents', (tester) async {
    when(
      () => repo.rootFolder(),
    ).thenAnswer((_) async => right(const DocumentRoot(name: 'Colette')));
    final router = GoRouter(
      routes: [
        GoRoute(
          path: '/',
          builder: (_, _) => const Scaffold(body: DocumentsCard()),
        ),
        GoRoute(
          path: AppRoutes.todayDocuments,
          builder: (_, _) => const Scaffold(body: Text('documents-marker')),
        ),
      ],
    );
    addTearDown(router.dispose);
    await tester.pumpWidget(
      ProviderScope(
        overrides: [documentsRepositoryProvider.overrideWithValue(repo)],
        child: MaterialApp.router(
          routerConfig: router,
          theme: const ThemeService().light(),
          locale: const Locale('fr'),
          localizationsDelegates: S.localizationsDelegates,
          supportedLocales: S.supportedLocales,
        ),
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.byType(ColetteCardSurface));
    await tester.pumpAndSettle();
    expect(find.text('documents-marker'), findsOneWidget);
  });
}
```

- [ ] **Step 2 : Vérifier l'échec**

Run: `flutter test test/features/documents/presentation/documents_card_test.dart`
Expected: échec de compilation.

- [ ] **Step 3 : Écrire la carte**

`lib/features/documents/presentation/widgets/documents_card.dart` :

```dart
import 'package:colette/app/router/app_router.dart';
import 'package:colette/core/theme/app_colors.dart';
import 'package:colette/core/theme/design_tokens.dart';
import 'package:colette/core/theme/text_styles.dart';
import 'package:colette/features/documents/domain/entities/document_root.dart';
import 'package:colette/features/documents/presentation/providers/documents_root.dart';
import 'package:colette/l10n/generated/app_localizations.dart';
import 'package:colette/shared/ui/widgets/colette_card_surface.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

/// Carte « Documents » sur Aujourd'hui : choix du dossier iCloud ou accès à la liste.
class DocumentsCard extends ConsumerWidget {
  const DocumentsCard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) =>
      switch (ref.watch(documentsRootProvider)) {
        AsyncData(value: final root?) => _RootCard(root: root),
        AsyncLoading() => const _LoadingCard(),
        _ => const _PickCard(),
      };
}

/// Dossier choisi : titre, nom du dossier, chevron.
class _RootCard extends StatelessWidget {
  const _RootCard({required this.root});

  final DocumentRoot root;

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    final styles = Theme.of(context).coletteTextStyles;
    final secondary = context.appColor(AppColors.textSecondary);
    return ColetteCardSurface(
      onTap: () => context.push(AppRoutes.todayDocuments),
      child: Row(
        spacing: AppSpacing.sm.value,
        children: [
          Icon(Icons.folder_shared_outlined,
              color: context.appColor(AppColors.primary)),
          Expanded(
            child: Column(
              crossAxisAlignment: .start,
              children: [
                Text(s.documentsCardTitle, style: styles.bodyMedium),
                Text(
                  root.name,
                  style: styles.small.copyWith(color: secondary),
                  maxLines: 1,
                  overflow: .ellipsis,
                ),
              ],
            ),
          ),
          Icon(Icons.chevron_right, color: secondary),
        ],
      ),
    );
  }
}

/// Aucun dossier : invitation et bouton vers le sélecteur iOS.
class _PickCard extends ConsumerWidget {
  const _PickCard();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final s = S.of(context);
    final styles = Theme.of(context).coletteTextStyles;
    return ColetteCardSurface(
      child: Column(
        crossAxisAlignment: .start,
        spacing: AppSpacing.sm.value,
        children: [
          Row(
            spacing: AppSpacing.sm.value,
            children: [
              Icon(Icons.folder_shared_outlined,
                  color: context.appColor(AppColors.primary)),
              Expanded(
                child: Text(
                  s.documentsCardEmptyBody,
                  style: styles.body.copyWith(
                    color: context.appColor(AppColors.textSecondary),
                  ),
                ),
              ),
            ],
          ),
          TextButton.icon(
            onPressed: () => ref.read(documentsRootProvider.notifier).pick(),
            icon: const Icon(Icons.folder_open_outlined),
            label: Text(s.documentsCardPick),
          ),
        ],
      ),
    );
  }
}

/// Pendant la lecture du bookmark ou le sélecteur : indicateur discret.
class _LoadingCard extends StatelessWidget {
  const _LoadingCard();

  @override
  Widget build(BuildContext context) => ColetteCardSurface(
    child: Row(
      spacing: AppSpacing.sm.value,
      children: [
        SizedBox.square(
          dimension: AppSize.xs.value,
          child: CircularProgressIndicator(strokeWidth: AppSpacing.xxs.value),
        ),
        Text(
          S.of(context).documentsCardTitle,
          style: Theme.of(context).coletteTextStyles.bodyMedium,
        ),
      ],
    ),
  );
}
```

- [ ] **Step 4 : Poser la carte sur Aujourd'hui**

Dans `lib/features/dashboard/presentation/pages/dashboard_page.dart`, importer `package:colette/features/documents/presentation/widgets/documents_card.dart` et remplacer la fin de la `ListView` :

```dart
            const DayCountersRow(),
            AppSpacing.lg.verticalSpace,
            const DocumentsCard(),
            AppSpacing.xl.verticalSpace,
```

- [ ] **Step 5 : Isoler le test de la page Aujourd'hui du canal natif**

Dans `test/features/dashboard/presentation/dashboard_page_test.dart` :

- ajouter les imports `package:colette/features/documents/domain/repositories/documents_repository.dart` et `package:colette/features/documents/presentation/providers/documents_providers.dart` ;
- ajouter `class MockDocumentsRepository extends Mock implements DocumentsRepository {}` sous `MockEventsRepository` ;
- ajouter une fonction utilitaire au niveau de `main` :

```dart
  MockDocumentsRepository documentsRepo() {
    final repo = MockDocumentsRepository();
    when(() => repo.rootFolder()).thenAnswer((_) async => right(null));
    return repo;
  }
```

- dans `overridesFor`, ajouter en tête de la liste :

```dart
    documentsRepositoryProvider.overrideWithValue(documentsRepo()),
```

- [ ] **Step 6 : Vérifier le succès**

Run: `flutter test test/features/documents/presentation/documents_card_test.dart test/features/dashboard/`
Expected: tous verts.

- [ ] **Step 7 : Commit**

```bash
dart format lib test && dart analyze
git add lib/features/documents/presentation/widgets/documents_card.dart lib/features/dashboard/presentation/pages/dashboard_page.dart test/features/dashboard/presentation/dashboard_page_test.dart test/features/documents/presentation/documents_card_test.dart
git commit -m "feat: carte Documents sur l'écran Aujourd'hui"
```

---

### Task 9 : Page Documents, tuile, vue « accès perdu »

**Files:**
- Modify: `lib/features/documents/presentation/pages/documents_page.dart` (remplacer le squelette)
- Create: `lib/features/documents/presentation/widgets/document_entry_tile.dart`
- Create: `lib/features/documents/presentation/widgets/documents_lost_access_view.dart`
- Test: `test/features/documents/presentation/documents_page_test.dart`

- [ ] **Step 1 : Écrire le test rouge**

`test/features/documents/presentation/documents_page_test.dart` :

```dart
import 'package:colette/app/router/app_router.dart';
import 'package:colette/core/result/failure.dart';
import 'package:colette/core/theme/theme_service.dart';
import 'package:colette/features/documents/domain/entities/document_entry.dart';
import 'package:colette/features/documents/domain/entities/document_root.dart';
import 'package:colette/features/documents/domain/entities/download_status.dart';
import 'package:colette/features/documents/domain/repositories/documents_repository.dart';
import 'package:colette/features/documents/presentation/pages/documents_page.dart';
import 'package:colette/features/documents/presentation/providers/documents_providers.dart';
import 'package:colette/l10n/generated/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:go_router/go_router.dart';
import 'package:mocktail/mocktail.dart';

class MockDocumentsRepository extends Mock implements DocumentsRepository {}

DocumentEntry entry(
  String name, {
  String? path,
  bool isDirectory = false,
  DownloadStatus status = DownloadStatus.downloaded,
}) => DocumentEntry(
  name: name,
  path: path ?? name,
  isDirectory: isDirectory,
  size: 0,
  modifiedAt: DateTime(2026, 9, 22),
  downloadStatus: status,
);

void main() {
  late MockDocumentsRepository repo;

  setUp(() {
    repo = MockDocumentsRepository();
    when(
      () => repo.rootFolder(),
    ).thenAnswer((_) async => right(const DocumentRoot(name: 'Colette')));
  });

  Future<void> pumpPage(WidgetTester tester) async {
    final router = GoRouter(
      initialLocation: AppRoutes.todayDocuments,
      routes: [
        GoRoute(
          path: AppRoutes.todayDocuments,
          builder: (_, state) => DocumentsPage(
            path: state.uri.queryParameters[AppRoutes.documentsPathParam] ?? '',
          ),
        ),
      ],
    );
    addTearDown(router.dispose);
    await tester.pumpWidget(
      ProviderScope(
        overrides: [documentsRepositoryProvider.overrideWithValue(repo)],
        child: MaterialApp.router(
          routerConfig: router,
          theme: const ThemeService().light(),
          locale: const Locale('fr'),
          localizationsDelegates: S.localizationsDelegates,
          supportedLocales: S.supportedLocales,
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  testWidgets('liste triée avec le nom de la racine en titre', (tester) async {
    when(() => repo.list('')).thenAnswer(
      (_) async => right([
        entry('b.pdf'),
        entry('Ordonnances', isDirectory: true),
      ]),
    );
    await pumpPage(tester);
    expect(find.text('Colette'), findsOneWidget);
    final tiles = tester.widgetList<ListTile>(find.byType(ListTile)).toList();
    expect((tiles[0].title! as Text).data, 'Ordonnances');
    expect((tiles[1].title! as Text).data, 'b.pdf');
    expect(find.text('22 sept. 2026'), findsOneWidget);
  });

  testWidgets('dossier vide', (tester) async {
    when(() => repo.list('')).thenAnswer((_) async => right(const []));
    await pumpPage(tester);
    expect(find.text('Aucun document dans ce dossier'), findsOneWidget);
  });

  testWidgets('un tap sur un dossier ouvre le sous-dossier', (tester) async {
    when(() => repo.list('')).thenAnswer(
      (_) async => right([entry('Ordonnances', isDirectory: true)]),
    );
    when(() => repo.list('Ordonnances')).thenAnswer(
      (_) async => right([entry('a.pdf', path: 'Ordonnances/a.pdf')]),
    );
    await pumpPage(tester);
    await tester.tap(find.text('Ordonnances'));
    await tester.pumpAndSettle();
    expect(find.widgetWithText(AppBar, 'Ordonnances'), findsOneWidget);
    expect(find.text('a.pdf'), findsOneWidget);
  });

  testWidgets('un tap sur un fichier ouvre l\'aperçu', (tester) async {
    when(() => repo.list('')).thenAnswer((_) async => right([entry('a.pdf')]));
    when(() => repo.preview('a.pdf')).thenAnswer((_) async => right(null));
    await pumpPage(tester);
    await tester.tap(find.text('a.pdf'));
    await tester.pumpAndSettle();
    verify(() => repo.preview('a.pdf')).called(1);
    expect(find.byType(SnackBar), findsNothing);
  });

  testWidgets('fichier nuage : icône, et échec io → SnackBar', (tester) async {
    when(() => repo.list('')).thenAnswer(
      (_) async => right([entry('a.pdf', status: DownloadStatus.notDownloaded)]),
    );
    when(() => repo.preview('a.pdf')).thenAnswer(
      (_) async => left(const DocumentsFailure(DocumentsReason.io)),
    );
    await pumpPage(tester);
    expect(find.byIcon(Icons.cloud_download_outlined), findsOneWidget);
    await tester.tap(find.text('a.pdf'));
    await tester.pumpAndSettle();
    expect(
      find.text("Ce document n'est pas encore téléchargé sur cet iPhone"),
      findsOneWidget,
    );
  });

  testWidgets('aperçu annulé : pas de SnackBar', (tester) async {
    when(() => repo.list('')).thenAnswer((_) async => right([entry('a.pdf')]));
    when(() => repo.preview('a.pdf')).thenAnswer(
      (_) async => left(const DocumentsFailure(DocumentsReason.cancelled)),
    );
    await pumpPage(tester);
    await tester.tap(find.text('a.pdf'));
    await tester.pumpAndSettle();
    expect(find.byType(SnackBar), findsNothing);
  });

  testWidgets('accès perdu : vue dédiée puis re-choix', (tester) async {
    var listCalls = 0;
    when(() => repo.list('')).thenAnswer((_) async {
      listCalls++;
      return listCalls == 1
          ? left(const DocumentsFailure(DocumentsReason.accessDenied))
          : right([entry('a.pdf')]);
    });
    when(
      () => repo.pickRootFolder(),
    ).thenAnswer((_) async => right(const DocumentRoot(name: 'Nouveau')));
    await pumpPage(tester);
    expect(find.text("Colette n'a plus accès au dossier"), findsOneWidget);
    await tester.tap(find.text('Choisir le dossier partagé'));
    await tester.pumpAndSettle();
    expect(find.text('a.pdf'), findsOneWidget);
    expect(find.widgetWithText(AppBar, 'Nouveau'), findsOneWidget);
  });

  testWidgets('autre erreur : message générique', (tester) async {
    when(
      () => repo.list(''),
    ).thenAnswer((_) async => left(UnknownFailure(Exception('x'))));
    await pumpPage(tester);
    expect(find.text('Une erreur est survenue.'), findsOneWidget);
  });
}
```

- [ ] **Step 2 : Vérifier l'échec**

Run: `flutter test test/features/documents/presentation/documents_page_test.dart`
Expected: échecs (squelette vide).

- [ ] **Step 3 : Écrire la tuile**

`lib/features/documents/presentation/widgets/document_entry_tile.dart` :

```dart
import 'package:colette/app/router/app_router.dart';
import 'package:colette/core/dates/time_format.dart';
import 'package:colette/core/result/failure.dart';
import 'package:colette/core/theme/app_colors.dart';
import 'package:colette/core/theme/design_tokens.dart';
import 'package:colette/core/ui/failure_message.dart';
import 'package:colette/features/documents/domain/entities/document_entry.dart';
import 'package:colette/features/documents/domain/entities/download_status.dart';
import 'package:colette/features/documents/presentation/providers/documents_preview_controller.dart';
import 'package:colette/features/documents/presentation/providers/documents_providers.dart';
import 'package:colette/l10n/generated/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

/// Ligne d'un dossier ou d'un fichier ; tap : navigation ou aperçu.
class DocumentEntryTile extends ConsumerWidget {
  const DocumentEntryTile({
    super.key,
    required this.entry,
    required this.folderPath,
  });

  final DocumentEntry entry;

  /// Dossier contenant [entry], pour invalider sa liste en cas d'accès perdu.
  final String folderPath;

  IconData get _icon {
    if (entry.isDirectory) return Icons.folder_outlined;
    final ext = entry.name.split('.').last.toLowerCase();
    return switch (ext) {
      'pdf' => Icons.picture_as_pdf_outlined,
      'jpg' || 'jpeg' || 'png' || 'heic' => Icons.image_outlined,
      _ => Icons.insert_drive_file_outlined,
    };
  }

  void _onPreviewError(BuildContext context, WidgetRef ref, Object error) {
    final s = S.of(context);
    final messenger = ScaffoldMessenger.of(context);
    switch (error) {
      case DocumentsFailure(reason: DocumentsReason.cancelled):
        return;
      case DocumentsFailure(reason: DocumentsReason.io):
        messenger.showSnackBar(
          SnackBar(content: Text(s.documentsErrorNotDownloaded)),
        );
      case DocumentsFailure(
        reason: DocumentsReason.noFolder || DocumentsReason.accessDenied,
      ):
        ref.invalidate(documentsFolderProvider(folderPath));
      default:
        messenger.showSnackBar(
          SnackBar(content: Text(failureMessage(error, s))),
        );
    }
  }

  Widget? _trailing(BuildContext context, bool previewing) {
    if (entry.isDirectory) return const Icon(Icons.chevron_right);
    if (previewing || entry.downloadStatus == DownloadStatus.downloading) {
      return SizedBox.square(
        dimension: AppSize.sm.value,
        child: CircularProgressIndicator(strokeWidth: AppSpacing.xxs.value),
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

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final controller = documentsPreviewControllerProvider(entry.path);
    // Garde le contrôleur autoDispose vivant pendant l'await de preview().
    final previewing = ref.watch(controller).isLoading;
    ref.listen(controller, (_, next) {
      if (next case AsyncError(:final error)) {
        _onPreviewError(context, ref, error);
      }
    });
    return ListTile(
      leading: Icon(_icon, color: context.appColor(AppColors.primary)),
      title: Text(entry.name, maxLines: 1, overflow: .ellipsis),
      subtitle: entry.isDirectory
          ? null
          : Text(formatShortDate(entry.modifiedAt)),
      trailing: _trailing(context, previewing),
      onTap: switch (entry.isDirectory) {
        true => () => context.push(AppRoutes.documentsLocation(entry.path)),
        false when previewing => null,
        false => () => ref.read(controller.notifier).preview(),
      },
    );
  }
}
```

- [ ] **Step 4 : Écrire la vue « accès perdu »**

`lib/features/documents/presentation/widgets/documents_lost_access_view.dart` :

```dart
import 'package:colette/app/router/app_router.dart';
import 'package:colette/core/theme/app_colors.dart';
import 'package:colette/core/theme/design_tokens.dart';
import 'package:colette/core/theme/text_styles.dart';
import 'package:colette/features/documents/presentation/providers/documents_root.dart';
import 'package:colette/l10n/generated/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

/// Bookmark périmé ou dossier supprimé : invite à re-choisir le dossier.
class DocumentsLostAccessView extends ConsumerWidget {
  const DocumentsLostAccessView({super.key});

  Future<void> _pick(BuildContext context, WidgetRef ref) async {
    final picked = await ref.read(documentsRootProvider.notifier).pick();
    if (picked && context.mounted) context.go(AppRoutes.todayDocuments);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final s = S.of(context);
    final secondary = context.appColor(AppColors.textSecondary);
    return Center(
      child: Padding(
        padding: AppSpacing.xl.all,
        child: Column(
          mainAxisSize: .min,
          spacing: AppSpacing.md.value,
          children: [
            Icon(Icons.folder_off_outlined,
                size: AppSize.xl.value, color: secondary),
            Text(
              s.documentsLostAccessBody,
              textAlign: .center,
              style: Theme.of(context).coletteTextStyles.body
                  .copyWith(color: secondary),
            ),
            FilledButton.icon(
              onPressed: () => _pick(context, ref),
              icon: const Icon(Icons.folder_open_outlined),
              label: Text(s.documentsCardPick),
            ),
          ],
        ),
      ),
    );
  }
}
```

- [ ] **Step 5 : Écrire la page**

Remplacer `lib/features/documents/presentation/pages/documents_page.dart` :

```dart
import 'package:colette/core/result/failure.dart';
import 'package:colette/core/ui/failure_message.dart';
import 'package:colette/features/documents/domain/entities/document_entry.dart';
import 'package:colette/features/documents/presentation/providers/documents_providers.dart';
import 'package:colette/features/documents/presentation/providers/documents_root.dart';
import 'package:colette/features/documents/presentation/widgets/document_entry_tile.dart';
import 'package:colette/features/documents/presentation/widgets/documents_lost_access_view.dart';
import 'package:colette/l10n/generated/app_localizations.dart';
import 'package:colette/shared/ui/widgets/empty_state.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Liste d'un dossier du dossier iCloud partagé, [path] relatif à la racine.
class DocumentsPage extends ConsumerWidget {
  const DocumentsPage({super.key, this.path = ''});

  final String path;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final s = S.of(context);
    final rootName = ref.watch(documentsRootProvider).value?.name;
    final title = switch (path) {
      '' => rootName ?? s.documentsCardTitle,
      _ => path.split('/').last,
    };
    return Scaffold(
      appBar: AppBar(title: Text(title)),
      body: switch (ref.watch(documentsFolderProvider(path))) {
        AsyncData(value: final entries) when entries.isEmpty => EmptyState(
          icon: Icons.folder_open_outlined,
          message: s.documentsEmptyFolder,
        ),
        AsyncData(value: final entries) => _EntriesList(
          entries: entries,
          folderPath: path,
        ),
        AsyncError(
          error: DocumentsFailure(
            reason: DocumentsReason.noFolder || DocumentsReason.accessDenied,
          ),
        ) =>
          const DocumentsLostAccessView(),
        AsyncError(:final error) => EmptyState(
          icon: Icons.error_outline,
          message: failureMessage(error, s),
        ),
        _ => const Center(child: CircularProgressIndicator()),
      },
    );
  }
}

/// Liste des entrées avec tirer-pour-rafraîchir.
class _EntriesList extends ConsumerWidget {
  const _EntriesList({required this.entries, required this.folderPath});

  final List<DocumentEntry> entries;
  final String folderPath;

  @override
  Widget build(BuildContext context, WidgetRef ref) => RefreshIndicator(
    onRefresh: () => ref.refresh(documentsFolderProvider(folderPath).future),
    child: ListView.builder(
      physics: const AlwaysScrollableScrollPhysics(),
      itemCount: entries.length,
      itemBuilder: (_, index) =>
          DocumentEntryTile(entry: entries[index], folderPath: folderPath),
    ),
  );
}
```

- [ ] **Step 6 : Vérifier le succès**

Run: `flutter test test/features/documents/`
Expected: tous verts (8 tests de page).

- [ ] **Step 7 : Commit**

```bash
dart format lib test && dart analyze
git add lib/features/documents/presentation/pages/documents_page.dart lib/features/documents/presentation/widgets/document_entry_tile.dart lib/features/documents/presentation/widgets/documents_lost_access_view.dart test/features/documents/presentation/documents_page_test.dart
git commit -m "feat: page Documents, navigation dans les sous-dossiers et aperçu"
```

---

### Task 10 : Section « Dossier documents » dans les Réglages

**Files:**
- Create: `lib/features/documents/presentation/widgets/documents_root_section.dart`
- Modify: `lib/features/household/presentation/widgets/household_section.dart`
- Modify: `test/features/household/presentation/household_section_test.dart`
- Test: `test/features/documents/presentation/documents_root_section_test.dart`

- [ ] **Step 1 : Écrire le test rouge**

`test/features/documents/presentation/documents_root_section_test.dart` :

```dart
import 'package:colette/features/documents/domain/entities/document_root.dart';
import 'package:colette/features/documents/domain/repositories/documents_repository.dart';
import 'package:colette/features/documents/presentation/providers/documents_providers.dart';
import 'package:colette/features/documents/presentation/widgets/documents_root_section.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:mocktail/mocktail.dart';

import '../../../helpers/pump_app.dart';

class MockDocumentsRepository extends Mock implements DocumentsRepository {}

void main() {
  late MockDocumentsRepository repo;

  setUp(() => repo = MockDocumentsRepository());

  Future<void> pumpSection(WidgetTester tester) => pumpApp(
    tester,
    const Scaffold(body: DocumentsRootSection()),
    overrides: [documentsRepositoryProvider.overrideWithValue(repo)],
  );

  testWidgets('sans dossier : « Aucun dossier choisi » et bouton', (
    tester,
  ) async {
    when(() => repo.rootFolder()).thenAnswer((_) async => right(null));
    await pumpSection(tester);
    expect(find.text('Aucun dossier choisi'), findsOneWidget);
    expect(find.text('Choisir le dossier partagé'), findsOneWidget);
  });

  testWidgets('avec dossier : nom, changer et oublier', (tester) async {
    when(
      () => repo.rootFolder(),
    ).thenAnswer((_) async => right(const DocumentRoot(name: 'Colette')));
    await pumpSection(tester);
    expect(find.text('Dossier documents'), findsOneWidget);
    expect(find.text('Colette'), findsOneWidget);
    expect(find.text('Changer de dossier'), findsOneWidget);
    expect(find.text('Oublier le dossier'), findsOneWidget);
  });

  testWidgets('changer ouvre le sélecteur', (tester) async {
    when(
      () => repo.rootFolder(),
    ).thenAnswer((_) async => right(const DocumentRoot(name: 'Colette')));
    when(
      () => repo.pickRootFolder(),
    ).thenAnswer((_) async => right(const DocumentRoot(name: 'Autre')));
    await pumpSection(tester);
    await tester.tap(find.text('Changer de dossier'));
    await tester.pumpAndSettle();
    expect(find.text('Autre'), findsOneWidget);
  });

  testWidgets('oublier demande confirmation puis oublie', (tester) async {
    when(
      () => repo.rootFolder(),
    ).thenAnswer((_) async => right(const DocumentRoot(name: 'Colette')));
    when(() => repo.forgetRootFolder()).thenAnswer((_) async => right(null));
    await pumpSection(tester);
    await tester.tap(find.text('Oublier le dossier'));
    await tester.pumpAndSettle();
    expect(
      find.text(
        "Colette n'affichera plus ce dossier. Vos fichiers ne sont pas supprimés.",
      ),
      findsOneWidget,
    );
    await tester.tap(find.widgetWithText(TextButton, 'Oublier le dossier').last);
    await tester.pumpAndSettle();
    verify(() => repo.forgetRootFolder()).called(1);
    expect(find.text('Aucun dossier choisi'), findsOneWidget);
  });

  testWidgets('annuler la confirmation ne fait rien', (tester) async {
    when(
      () => repo.rootFolder(),
    ).thenAnswer((_) async => right(const DocumentRoot(name: 'Colette')));
    await pumpSection(tester);
    await tester.tap(find.text('Oublier le dossier'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Annuler'));
    await tester.pumpAndSettle();
    verifyNever(() => repo.forgetRootFolder());
    expect(find.text('Colette'), findsOneWidget);
  });
}
```

- [ ] **Step 2 : Vérifier l'échec**

Run: `flutter test test/features/documents/presentation/documents_root_section_test.dart`
Expected: échec de compilation.

- [ ] **Step 3 : Écrire la section**

`lib/features/documents/presentation/widgets/documents_root_section.dart` :

```dart
import 'package:colette/core/theme/app_colors.dart';
import 'package:colette/core/theme/design_tokens.dart';
import 'package:colette/core/theme/text_styles.dart';
import 'package:colette/features/documents/domain/entities/document_root.dart';
import 'package:colette/features/documents/presentation/providers/documents_root.dart';
import 'package:colette/l10n/generated/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Réglage du dossier iCloud : nom, changer, oublier.
class DocumentsRootSection extends ConsumerWidget {
  const DocumentsRootSection({super.key});

  Future<void> _forget(BuildContext context, WidgetRef ref) async {
    final s = S.of(context);
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(s.settingsDocumentsForget),
        content: Text(s.settingsDocumentsForgetConfirm),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: Text(s.actionCancel),
          ),
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: Text(s.settingsDocumentsForget),
          ),
        ],
      ),
    );
    if (confirmed == true) {
      await ref.read(documentsRootProvider.notifier).forget();
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final s = S.of(context);
    return switch (ref.watch(documentsRootProvider)) {
      AsyncData(value: final root?) => _RootRow(
        root: root,
        onChange: () => ref.read(documentsRootProvider.notifier).pick(),
        onForget: () => _forget(context, ref),
      ),
      AsyncLoading() => const LinearProgressIndicator(),
      _ => ListTile(
        contentPadding: EdgeInsets.zero,
        leading: const Icon(Icons.folder_shared_outlined),
        title: Text(s.settingsDocumentsNone),
        trailing: TextButton(
          onPressed: () => ref.read(documentsRootProvider.notifier).pick(),
          child: Text(s.documentsCardPick),
        ),
      ),
    };
  }
}

/// Dossier choisi : nom et actions.
class _RootRow extends StatelessWidget {
  const _RootRow({
    required this.root,
    required this.onChange,
    required this.onForget,
  });

  final DocumentRoot root;
  final VoidCallback onChange;
  final VoidCallback onForget;

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    final styles = Theme.of(context).coletteTextStyles;
    return Column(
      crossAxisAlignment: .start,
      children: [
        ListTile(
          contentPadding: EdgeInsets.zero,
          leading: const Icon(Icons.folder_shared_outlined),
          title: Text(s.settingsDocumentsFolder),
          subtitle: Text(
            root.name,
            style: styles.small.copyWith(
              color: context.appColor(AppColors.textSecondary),
            ),
          ),
        ),
        Wrap(
          spacing: AppSpacing.sm.value,
          children: [
            TextButton(onPressed: onChange, child: Text(s.settingsDocumentsChange)),
            TextButton(
              onPressed: onForget,
              child: Text(
                s.settingsDocumentsForget,
                style: styles.bodyMedium.copyWith(
                  color: context.appColor(AppColors.error),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }
}
```

- [ ] **Step 4 : Insérer la section dans le foyer**

Dans `lib/features/household/presentation/widgets/household_section.dart`, importer `package:colette/features/documents/presentation/widgets/documents_root_section.dart` et, dans la `Column`, juste avant `const Divider(),` :

```dart
          const Divider(),
          const DocumentsRootSection(),
```

(Il y a alors deux `Divider` : un avant la section documents, un avant « Quitter ce foyer ».)

- [ ] **Step 5 : Isoler le test de `HouseholdSection` du canal natif**

Dans `test/features/household/presentation/household_section_test.dart`, ajouter les imports `package:colette/features/documents/domain/repositories/documents_repository.dart`, `package:colette/features/documents/presentation/providers/documents_providers.dart`, `package:fpdart/fpdart.dart`, `package:mocktail/mocktail.dart` (si absents), la classe `MockDocumentsRepository`, une fonction utilitaire au niveau de `main` :

```dart
  MockDocumentsRepository documentsRepo() {
    final repo = MockDocumentsRepository();
    when(() => repo.rootFolder()).thenAnswer((_) async => right(null));
    return repo;
  }
```

et dans chaque liste d'overrides :

```dart
        documentsRepositoryProvider.overrideWithValue(documentsRepo()),
```

- [ ] **Step 6 : Vérifier le succès**

Run: `flutter test test/features/documents/ test/features/household/ test/features/baby/`
Expected: tous verts.

- [ ] **Step 7 : Commit**

```bash
dart format lib test && dart analyze
git add lib/features/documents/presentation/widgets/documents_root_section.dart lib/features/household/presentation/widgets/household_section.dart test/features/household/presentation/household_section_test.dart test/features/documents/presentation/documents_root_section_test.dart
git commit -m "feat: réglage du dossier documents dans la section Foyer"
```

---

### Task 11 : Pont Swift, lot 1 (bookmark, listage, sélecteur, aperçu)

**Files:**
- Create: `ios/Runner/Documents/DocumentsError.swift`
- Create: `ios/Runner/Documents/DocumentsStore.swift`
- Create: `ios/Runner/Documents/DocumentsLister.swift`
- Create: `ios/Runner/Documents/DocumentsPresenter.swift`
- Create: `ios/Runner/Documents/DocumentsPlugin.swift`
- Modify: `ios/Runner/AppDelegate.swift`
- Modify: `ios/Runner.xcodeproj/project.pbxproj` (via le gem `xcodeproj`)

Pas de test automatisé : vérification par compilation puis liste de contrôle manuelle (tâche 18).

- [ ] **Step 1 : Erreurs**

`ios/Runner/Documents/DocumentsError.swift` :

```swift
import Flutter

/// Erreurs du pont documents, mappées sur les codes attendus par Flutter.
enum DocumentsError: Error {
  case noFolder
  case accessDenied
  case cancelled
  case io(String)

  var code: String {
    switch self {
    case .noFolder: return "noFolder"
    case .accessDenied: return "accessDenied"
    case .cancelled: return "cancelled"
    case .io: return "io"
    }
  }

  var flutterError: FlutterError {
    switch self {
    case .io(let message):
      return FlutterError(code: code, message: message, details: nil)
    default:
      return FlutterError(code: code, message: nil, details: nil)
    }
  }
}
```

- [ ] **Step 2 : Bookmark et portée sécurisée**

`ios/Runner/Documents/DocumentsStore.swift` :

```swift
import Foundation

/// Racine résolue, avec la portée sécurisée ouverte jusqu'à `close()` ou la destruction.
final class ScopedRoot {
  let url: URL
  private var open = true

  init(url: URL) { self.url = url }

  func close() {
    guard open else { return }
    url.stopAccessingSecurityScopedResource()
    open = false
  }

  deinit { close() }
}

/// Bookmark de sécurité du dossier racine dans `UserDefaults`.
final class DocumentsStore {
  static let bookmarkKey = "colette.documents.rootBookmark"

  private let defaults: UserDefaults

  init(defaults: UserDefaults = .standard) { self.defaults = defaults }

  var hasRoot: Bool { defaults.data(forKey: Self.bookmarkKey) != nil }

  /// Enregistre l'URL renvoyée par le sélecteur ; renvoie le nom du dossier.
  func save(rootURL: URL) throws -> String {
    let accessed = rootURL.startAccessingSecurityScopedResource()
    defer { if accessed { rootURL.stopAccessingSecurityScopedResource() } }
    do {
      let data = try rootURL.bookmarkData()
      defaults.set(data, forKey: Self.bookmarkKey)
    } catch {
      throw DocumentsError.io(error.localizedDescription)
    }
    return rootURL.lastPathComponent
  }

  func forget() { defaults.removeObject(forKey: Self.bookmarkKey) }

  /// Résout le bookmark à chaque appel ; régénère un bookmark périmé.
  func openRoot() throws -> ScopedRoot {
    guard let data = defaults.data(forKey: Self.bookmarkKey) else {
      throw DocumentsError.noFolder
    }
    var stale = false
    let url: URL
    do {
      url = try URL(resolvingBookmarkData: data, bookmarkDataIsStale: &stale)
    } catch {
      throw DocumentsError.noFolder
    }
    guard url.startAccessingSecurityScopedResource() else {
      throw DocumentsError.accessDenied
    }
    let root = ScopedRoot(url: url)
    if stale, let fresh = try? url.bookmarkData() {
      defaults.set(fresh, forKey: Self.bookmarkKey)
    }
    var isDirectory: ObjCBool = false
    guard FileManager.default.fileExists(atPath: url.path, isDirectory: &isDirectory),
      isDirectory.boolValue
    else {
      root.close()
      throw DocumentsError.accessDenied
    }
    return root
  }

  /// Chemin relatif → URL sous la racine. Refuse `..`, `.` et un `/` initial.
  static func resolve(_ relativePath: String, under root: URL) throws -> URL {
    if relativePath.isEmpty { return root }
    if relativePath.hasPrefix("/") { throw DocumentsError.accessDenied }
    let parts = relativePath.split(separator: "/").map(String.init)
    if parts.contains("..") || parts.contains(".") { throw DocumentsError.accessDenied }
    return parts.reduce(root) { $0.appendingPathComponent($1) }
  }
}
```

- [ ] **Step 3 : Listage et téléchargement**

`ios/Runner/Documents/DocumentsLister.swift` :

```swift
import Foundation

/// Listage d'un dossier et téléchargement iCloud à la demande.
enum DocumentsLister {
  private static let keys: Set<URLResourceKey> = [
    .isDirectoryKey, .fileSizeKey, .contentModificationDateKey, .isUbiquitousItemKey,
    .ubiquitousItemDownloadingStatusKey, .ubiquitousItemIsDownloadingKey,
  ]

  private static let placeholderSuffix = ".icloud"

  /// Entrées d'un dossier, au format attendu par `DocumentEntryDto`.
  static func list(folder: URL, relativePath: String) throws -> [[String: Any]] {
    let urls: [URL]
    do {
      urls = try FileManager.default.contentsOfDirectory(
        at: folder, includingPropertiesForKeys: Array(keys), options: [])
    } catch {
      throw DocumentsError.io(error.localizedDescription)
    }
    return urls.compactMap { url in
      let raw = url.lastPathComponent
      let isPlaceholder = raw.hasPrefix(".") && raw.hasSuffix(placeholderSuffix)
      if raw.hasPrefix(".") && !isPlaceholder { return nil }
      let values = try? url.resourceValues(forKeys: keys)
      let isDirectory = values?.isDirectory ?? false
      let name = isPlaceholder ? normalizedName(raw) : raw
      let modified = values?.contentModificationDate ?? Date(timeIntervalSince1970: 0)
      return [
        "name": name,
        "path": relativePath.isEmpty ? name : "\(relativePath)/\(name)",
        "isDirectory": isDirectory,
        "size": isDirectory ? 0 : (values?.fileSize ?? 0),
        "modifiedAt": Int(modified.timeIntervalSince1970 * 1000),
        "downloadStatus": status(isDirectory: isDirectory, isPlaceholder: isPlaceholder, values: values),
      ]
    }
  }

  private static func status(isDirectory: Bool, isPlaceholder: Bool, values: URLResourceValues?) -> String {
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

  private static func isAvailable(_ url: URL) -> Bool {
    guard FileManager.default.fileExists(atPath: url.path) else { return false }
    let values = try? url.resourceValues(forKeys: [.isUbiquitousItemKey, .ubiquitousItemDownloadingStatusKey])
    guard values?.isUbiquitousItem == true else { return true }
    let status = values?.ubiquitousItemDownloadingStatus
    return status == .current || status == .downloaded
  }

  /// Lance le téléchargement si besoin et attend (30 s max) que le fichier soit lisible.
  static func ensureDownloaded(
    _ located: URL, timeout: TimeInterval = 30,
    completion: @escaping (Result<URL, DocumentsError>) -> Void
  ) {
    let real = realURL(for: located)
    if isAvailable(real) {
      completion(.success(real))
      return
    }
    do {
      try FileManager.default.startDownloadingUbiquitousItem(at: real)
    } catch {
      completion(.failure(.io(error.localizedDescription)))
      return
    }
    poll(real, deadline: Date().addingTimeInterval(timeout), completion: completion)
  }

  private static func poll(
    _ url: URL, deadline: Date, completion: @escaping (Result<URL, DocumentsError>) -> Void
  ) {
    DispatchQueue.global().asyncAfter(deadline: .now() + 0.5) {
      if isAvailable(url) {
        DispatchQueue.main.async { completion(.success(url)) }
      } else if Date() > deadline {
        DispatchQueue.main.async { completion(.failure(.io("Téléchargement trop long"))) }
      } else {
        poll(url, deadline: deadline, completion: completion)
      }
    }
  }
}
```

- [ ] **Step 4 : Sélecteur de dossier et Quick Look**

`ios/Runner/Documents/DocumentsPresenter.swift` :

```swift
import QuickLook
import UIKit
import UniformTypeIdentifiers

/// Présente les écrans système : sélecteur de dossier, aperçu Quick Look.
final class DocumentsPresenter: NSObject {
  private var pickerCompletion: ((Result<URL, DocumentsError>) -> Void)?
  private var previewURL: URL?
  private var previewCompletion: (() -> Void)?

  private var host: UIViewController? {
    UIApplication.shared.connectedScenes
      .compactMap { ($0 as? UIWindowScene)?.keyWindow }
      .first?.rootViewController
  }

  func pickFolder(completion: @escaping (Result<URL, DocumentsError>) -> Void) {
    guard let host else {
      completion(.failure(.io("Aucune fenêtre")))
      return
    }
    pickerCompletion = completion
    let picker = UIDocumentPickerViewController(forOpeningContentTypes: [.folder])
    picker.allowsMultipleSelection = false
    picker.delegate = self
    host.present(picker, animated: true)
  }

  func preview(fileURL: URL, completion: @escaping () -> Void) {
    guard let host else {
      completion()
      return
    }
    previewURL = fileURL
    previewCompletion = completion
    let controller = QLPreviewController()
    controller.dataSource = self
    controller.delegate = self
    host.present(controller, animated: true)
  }
}

extension DocumentsPresenter: UIDocumentPickerDelegate {
  func documentPicker(_ controller: UIDocumentPickerViewController, didPickDocumentsAt urls: [URL]) {
    let completion = pickerCompletion
    pickerCompletion = nil
    guard let url = urls.first else {
      completion?(.failure(.cancelled))
      return
    }
    completion?(.success(url))
  }

  func documentPickerWasCancelled(_ controller: UIDocumentPickerViewController) {
    let completion = pickerCompletion
    pickerCompletion = nil
    completion?(.failure(.cancelled))
  }
}

extension DocumentsPresenter: QLPreviewControllerDataSource, QLPreviewControllerDelegate {
  func numberOfPreviewItems(in controller: QLPreviewController) -> Int {
    previewURL == nil ? 0 : 1
  }

  func previewController(_ controller: QLPreviewController, previewItemAt index: Int) -> QLPreviewItem {
    (previewURL ?? URL(fileURLWithPath: "")) as NSURL
  }

  func previewControllerDidDismiss(_ controller: QLPreviewController) {
    let completion = previewCompletion
    previewCompletion = nil
    previewURL = nil
    completion?()
  }
}
```

- [ ] **Step 5 : Plugin et canal**

`ios/Runner/Documents/DocumentsPlugin.swift` :

```swift
import Flutter
import UIKit

/// Canal `colette/documents` : dispatch des appels Flutter vers le store, le lister et le presenter.
final class DocumentsPlugin: NSObject {
  static let channelName = "colette/documents"

  private let store = DocumentsStore()
  private let presenter = DocumentsPresenter()

  /// Racine gardée ouverte pendant un aperçu (portée sécurisée).
  private var activeRoot: ScopedRoot?

  static func register(with registry: FlutterPluginRegistry) {
    guard let messenger = registry.registrar(forPlugin: "DocumentsPlugin")?.messenger() else { return }
    let channel = FlutterMethodChannel(name: channelName, binaryMessenger: messenger)
    let plugin = DocumentsPlugin()
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
      case "pickRootFolder":
        pickRootFolder(result)
      case "list":
        result(try list(path: try argument("path", of: call)))
      case "preview":
        try preview(path: try argument("path", of: call), result: result)
      default:
        result(FlutterMethodNotImplemented)
      }
    } catch let error as DocumentsError {
      result(error.flutterError)
    } catch {
      result(DocumentsError.io(error.localizedDescription).flutterError)
    }
  }

  func argument(_ name: String, of call: FlutterMethodCall) throws -> String {
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

  private func list(path: String) throws -> [[String: Any]] {
    let root = try store.openRoot()
    defer { root.close() }
    let folder = try DocumentsStore.resolve(path, under: root.url)
    return try DocumentsLister.list(folder: folder, relativePath: path)
  }

  private func preview(path: String, result: @escaping FlutterResult) throws {
    let root = try store.openRoot()
    activeRoot = root
    let located = try DocumentsLister.locate(path, under: root.url)
    DocumentsLister.ensureDownloaded(located) { [weak self] outcome in
      switch outcome {
      case .failure(let error):
        self?.activeRoot?.close()
        self?.activeRoot = nil
        result(error.flutterError)
      case .success(let url):
        self?.presenter.preview(fileURL: url) {
          self?.activeRoot?.close()
          self?.activeRoot = nil
          result(nil)
        }
      }
    }
  }
}
```

- [ ] **Step 6 : Enregistrer dans l'AppDelegate**

Dans `ios/Runner/AppDelegate.swift`, remplacer `didInitializeImplicitFlutterEngine` :

```swift
  func didInitializeImplicitFlutterEngine(_ engineBridge: FlutterImplicitEngineBridge) {
    GeneratedPluginRegistrant.register(with: engineBridge.pluginRegistry)
    DocumentsPlugin.register(with: engineBridge.pluginRegistry)
  }
```

- [ ] **Step 7 : Référencer les fichiers dans le projet Xcode**

Créer `ios/scripts/add_documents_sources.rb` :

```ruby
#!/usr/bin/env ruby
# Ajoute les sources Swift de ios/Runner/Documents à la cible Runner (idempotent).
require 'xcodeproj'

project_path = File.expand_path('../Runner.xcodeproj', __dir__)
project = Xcodeproj::Project.open(project_path)
target = project.targets.find { |t| t.name == 'Runner' }
runner_group = project.main_group['Runner']
group = runner_group['Documents'] || runner_group.new_group('Documents', 'Documents')

Dir[File.expand_path('../Runner/Documents/*.swift', __dir__)].sort.each do |file|
  name = File.basename(file)
  next if group.files.any? { |f| f.path == name }
  ref = group.new_file(name)
  target.add_file_references([ref])
  puts "ajouté : #{name}"
end

project.save
```

Run: `ruby ios/scripts/add_documents_sources.rb`
Expected : cinq lignes `ajouté : …`. Relancer une seconde fois : aucune ligne (idempotent).

Solution de repli si le gem manque : ouvrir `ios/Runner.xcworkspace` dans Xcode, clic droit sur le groupe `Runner`, « Add Files to "Runner"… », sélectionner le dossier `Documents` avec « Create groups » et la cible `Runner` cochée.

- [ ] **Step 8 : Compiler**

Run: `flutter build ios --simulator 2>&1 | tail -5`
Expected: `✓ Built build/ios/iphonesimulator/Runner.app`. Corriger toute erreur Swift avant de continuer.

- [ ] **Step 9 : Commit**

```bash
git add ios/Runner/Documents ios/Runner/AppDelegate.swift ios/Runner.xcodeproj/project.pbxproj ios/scripts/add_documents_sources.rb
git commit -m "feat: pont Swift documents, bookmark, listage et aperçu Quick Look"
```

---

## Lot 2 — Écriture

### Task 12 : Use case `buildScanFileName`

**Files:**
- Create: `lib/features/documents/domain/use_cases/build_scan_file_name.dart`
- Test: `test/features/documents/domain/build_scan_file_name_test.dart`

- [ ] **Step 1 : Écrire le test rouge**

```dart
import 'package:colette/features/documents/domain/use_cases/build_scan_file_name.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('« Scan jj-MM-aaaa HHhmm.pdf »', () {
    expect(
      buildScanFileName(DateTime(2026, 9, 22, 14, 32)),
      'Scan 22-09-2026 14h32.pdf',
    );
  });

  test('zéros de tête', () {
    expect(
      buildScanFileName(DateTime(2026, 1, 5, 8, 7)),
      'Scan 05-01-2026 08h07.pdf',
    );
  });
}
```

- [ ] **Step 2 : Vérifier l'échec**

Run: `flutter test test/features/documents/domain/build_scan_file_name_test.dart`
Expected: échec de compilation.

- [ ] **Step 3 : Écrire le use case**

`lib/features/documents/domain/use_cases/build_scan_file_name.dart` :

```dart
String _two(int value) => value.toString().padLeft(2, '0');

/// Nom du PDF produit par le scanner : « Scan 22-09-2026 14h32.pdf ».
/// Préfixe fixe : le domaine n'a pas accès à la l10n.
String buildScanFileName(DateTime now) =>
    'Scan ${_two(now.day)}-${_two(now.month)}-${now.year} '
    '${_two(now.hour)}h${_two(now.minute)}.pdf';
```

- [ ] **Step 4 : Vérifier le succès**

Run: `flutter test test/features/documents/domain/build_scan_file_name_test.dart`
Expected: 2 tests verts.

- [ ] **Step 5 : Commit**

```bash
dart format lib test && dart analyze
git add lib/features/documents/domain/use_cases/build_scan_file_name.dart test/features/documents/domain/build_scan_file_name_test.dart
git commit -m "feat: use case buildScanFileName"
```

---

### Task 13 : `DocumentsWriteController`

**Files:**
- Create: `lib/features/documents/presentation/providers/documents_write_controller.dart`
- Test: `test/features/documents/presentation/documents_write_controller_test.dart`

- [ ] **Step 1 : Écrire le test rouge**

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
    when(() => repo.list(any())).thenAnswer((_) async => right(const []));
    container = ProviderContainer(
      overrides: [
        documentsRepositoryProvider.overrideWithValue(repo),
        clockProvider.overrideWithValue(
          FixedClock(DateTime(2026, 9, 22, 14, 32)),
        ),
      ],
    );
    addTearDown(container.dispose);
    container.listen(documentsWriteControllerProvider, (_, _) {});
    container.listen(documentsFolderProvider('Ordonnances'), (_, _) {});
  });

  DocumentsWriteController controller() =>
      container.read(documentsWriteControllerProvider.notifier);

  test('scan nomme le fichier avec l\'horloge et rafraîchit la liste', () async {
    when(
      () => repo.scan(
        folderPath: 'Ordonnances',
        fileName: 'Scan 22-09-2026 14h32.pdf',
      ),
    ).thenAnswer((_) async => right('Scan 22-09-2026 14h32.pdf'));
    await container.read(documentsFolderProvider('Ordonnances').future);

    await controller().scan('Ordonnances');

    await container.read(documentsFolderProvider('Ordonnances').future);
    verify(() => repo.list('Ordonnances')).called(2);
    expect(container.read(documentsWriteControllerProvider).hasError, isFalse);
  });

  test('importFile transmet le dossier et rafraîchit la liste', () async {
    when(
      () => repo.importFile(folderPath: 'Ordonnances'),
    ).thenAnswer((_) async => right('facture.pdf'));
    await container.read(documentsFolderProvider('Ordonnances').future);

    await controller().importFile('Ordonnances');

    await container.read(documentsFolderProvider('Ordonnances').future);
    verify(() => repo.list('Ordonnances')).called(2);
  });

  test('cancelled ne rafraîchit pas et ne produit pas d\'erreur', () async {
    when(() => repo.importFile(folderPath: '')).thenAnswer(
      (_) async => left(const DocumentsFailure(DocumentsReason.cancelled)),
    );
    await controller().importFile('');
    expect(container.read(documentsWriteControllerProvider).hasError, isFalse);
  });

  test('io passe en erreur', () async {
    when(() => repo.importFile(folderPath: '')).thenAnswer(
      (_) async => left(const DocumentsFailure(DocumentsReason.io)),
    );
    await controller().importFile('');
    expect(
      container.read(documentsWriteControllerProvider).error,
      const DocumentsFailure(DocumentsReason.io),
    );
  });
}
```

- [ ] **Step 2 : Vérifier l'échec**

Run: `flutter test test/features/documents/presentation/documents_write_controller_test.dart`
Expected: échec de compilation.

- [ ] **Step 3 : Écrire le contrôleur**

`lib/features/documents/presentation/providers/documents_write_controller.dart` :

```dart
import 'dart:async';

import 'package:colette/core/clock/app_clock.dart';
import 'package:colette/core/result/failure.dart';
import 'package:colette/features/documents/domain/use_cases/build_scan_file_name.dart';
import 'package:colette/features/documents/presentation/providers/documents_providers.dart';
import 'package:fpdart/fpdart.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'documents_write_controller.g.dart';

/// Ajout d'un document (scan ou import) dans un dossier.
@riverpod
class DocumentsWriteController extends _$DocumentsWriteController {
  @override
  FutureOr<void> build() {}

  Future<void> scan(String folderPath) => _run(folderPath, (repo) {
    final fileName = buildScanFileName(ref.read(clockProvider).now());
    return repo.scan(folderPath: folderPath, fileName: fileName);
  });

  Future<void> importFile(String folderPath) =>
      _run(folderPath, (repo) => repo.importFile(folderPath: folderPath));

  Future<void> _run(
    String folderPath,
    Future<Either<Failure, String>> Function(DocumentsRepository repo) action,
  ) async {
    state = const AsyncLoading();
    final result = await action(ref.read(documentsRepositoryProvider));
    state = result.fold(
      (failure) => switch (failure) {
        DocumentsFailure(reason: DocumentsReason.cancelled) =>
          const AsyncData(null),
        _ => AsyncError(failure, StackTrace.current),
      },
      (_) {
        ref.invalidate(documentsFolderProvider(folderPath));
        return const AsyncData(null);
      },
    );
  }
}
```

Ajouter l'import `package:colette/features/documents/domain/repositories/documents_repository.dart`.

- [ ] **Step 4 : Générer et vérifier**

Run: `dart run build_runner build -d && flutter test test/features/documents/presentation/documents_write_controller_test.dart`
Expected: 4 tests verts.

- [ ] **Step 5 : Commit**

```bash
dart format lib test && dart analyze
git add lib/features/documents/presentation/providers/documents_write_controller.dart lib/features/documents/presentation/providers/documents_write_controller.g.dart test/features/documents/presentation/documents_write_controller_test.dart
git commit -m "feat: DocumentsWriteController, scan et import"
```

---

### Task 14 : Bouton « + » et menu d'ajout sur la page

**Files:**
- Create: `lib/features/documents/presentation/widgets/documents_add_menu.dart`
- Modify: `lib/features/documents/presentation/pages/documents_page.dart`
- Modify: `test/features/documents/presentation/documents_page_test.dart`

- [ ] **Step 1 : Écrire les tests rouges**

Ajouter à `test/features/documents/presentation/documents_page_test.dart` (l'import `package:colette/core/clock/app_clock.dart` et l'override `clockProvider.overrideWithValue(FixedClock(DateTime(2026, 9, 22, 14, 32)))` dans `pumpPage`) :

```dart
  testWidgets('« + » puis « Scanner » scanne dans le dossier courant', (
    tester,
  ) async {
    when(() => repo.list('')).thenAnswer((_) async => right(const []));
    when(
      () => repo.scan(folderPath: '', fileName: 'Scan 22-09-2026 14h32.pdf'),
    ).thenAnswer((_) async => right('Scan 22-09-2026 14h32.pdf'));
    await pumpPage(tester);
    await tester.tap(find.byType(FloatingActionButton));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Scanner un document'));
    await tester.pumpAndSettle();
    verify(
      () => repo.scan(folderPath: '', fileName: 'Scan 22-09-2026 14h32.pdf'),
    ).called(1);
    verify(() => repo.list('')).called(2);
  });

  testWidgets('« + » puis « Importer » importe ; échec io → SnackBar', (
    tester,
  ) async {
    when(() => repo.list('')).thenAnswer((_) async => right(const []));
    when(() => repo.importFile(folderPath: '')).thenAnswer(
      (_) async => left(const DocumentsFailure(DocumentsReason.io)),
    );
    await pumpPage(tester);
    await tester.tap(find.byType(FloatingActionButton));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Importer un fichier'));
    await tester.pumpAndSettle();
    expect(find.text("Impossible d'enregistrer le document"), findsOneWidget);
  });

  testWidgets('pas de « + » quand l\'accès est perdu', (tester) async {
    when(() => repo.list('')).thenAnswer(
      (_) async => left(const DocumentsFailure(DocumentsReason.accessDenied)),
    );
    await pumpPage(tester);
    expect(find.byType(FloatingActionButton), findsNothing);
  });
```

- [ ] **Step 2 : Vérifier l'échec**

Run: `flutter test test/features/documents/presentation/documents_page_test.dart`
Expected: les 3 nouveaux tests échouent (pas de `FloatingActionButton`).

- [ ] **Step 3 : Écrire le menu**

`lib/features/documents/presentation/widgets/documents_add_menu.dart` :

```dart
import 'package:colette/core/theme/design_tokens.dart';
import 'package:colette/features/documents/presentation/providers/documents_write_controller.dart';
import 'package:colette/l10n/generated/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Bouton « + » : scanner ou importer dans [folderPath].
class DocumentsAddButton extends ConsumerWidget {
  const DocumentsAddButton({super.key, required this.folderPath});

  final String folderPath;

  Future<void> _open(BuildContext context, WidgetRef ref) async {
    final s = S.of(context);
    final controller = ref.read(documentsWriteControllerProvider.notifier);
    final action = await showModalBottomSheet<_AddAction>(
      context: context,
      builder: (sheetContext) => SafeArea(
        child: Padding(
          padding: AppSpacing.symmetric(vertical: AppSpacing.sm),
          child: Column(
            mainAxisSize: .min,
            children: [
              ListTile(
                leading: const Icon(Icons.document_scanner_outlined),
                title: Text(s.documentsActionScan),
                onTap: () => Navigator.of(sheetContext).pop(_AddAction.scan),
              ),
              ListTile(
                leading: const Icon(Icons.upload_file_outlined),
                title: Text(s.documentsActionImport),
                onTap: () =>
                    Navigator.of(sheetContext).pop(_AddAction.importFile),
              ),
            ],
          ),
        ),
      ),
    );
    switch (action) {
      case _AddAction.scan:
        await controller.scan(folderPath);
      case _AddAction.importFile:
        await controller.importFile(folderPath);
      case null:
        break;
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Garde le contrôleur autoDispose vivant pendant l'await de l'action.
    final writing = ref.watch(documentsWriteControllerProvider).isLoading;
    return FloatingActionButton(
      onPressed: writing ? null : () => _open(context, ref),
      child: writing
          ? SizedBox.square(
              dimension: AppSize.sm.value,
              child: CircularProgressIndicator(
                strokeWidth: AppSpacing.xxs.value,
              ),
            )
          : const Icon(Icons.add),
    );
  }
}

enum _AddAction { scan, importFile }
```

- [ ] **Step 4 : Brancher sur la page**

Dans `lib/features/documents/presentation/pages/documents_page.dart` :

- importer `documents_add_menu.dart` et `documents_write_controller.dart` ;
- dans `build`, avant le `return Scaffold(` :

```dart
    ref.listen(documentsWriteControllerProvider, (_, next) {
      if (next case AsyncError(:final error)) {
        switch (error) {
          case DocumentsFailure(
            reason: DocumentsReason.noFolder || DocumentsReason.accessDenied,
          ):
            ref.invalidate(documentsFolderProvider(path));
          case DocumentsFailure(reason: DocumentsReason.cancelled):
            break;
          default:
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(failureMessage(error, s))),
            );
        }
      }
    });
    final folder = ref.watch(documentsFolderProvider(path));
```

- remplacer `ref.watch(documentsFolderProvider(path))` dans le `switch` par `folder` ;
- ajouter au `Scaffold` :

```dart
      floatingActionButton: switch (folder) {
        AsyncData() => DocumentsAddButton(folderPath: path),
        _ => null,
      },
```

- [ ] **Step 5 : Vérifier le succès**

Run: `flutter test test/features/documents/`
Expected: tous verts.

- [ ] **Step 6 : Commit**

```bash
dart format lib test && dart analyze
git add lib/features/documents/presentation/widgets/documents_add_menu.dart lib/features/documents/presentation/pages/documents_page.dart test/features/documents/presentation/documents_page_test.dart
git commit -m "feat: bouton d'ajout, scan et import depuis la page Documents"
```

---

### Task 15 : Pont Swift, lot 2 (scan, import, écriture)

**Files:**
- Create: `ios/Runner/Documents/DocumentsWriter.swift`
- Modify: `ios/Runner/Documents/DocumentsPresenter.swift`
- Modify: `ios/Runner/Documents/DocumentsPlugin.swift`
- Modify: `ios/Runner/Info.plist`
- Modify: `ios/Runner.xcodeproj/project.pbxproj` (via le script)

- [ ] **Step 1 : Écriture et collision de nom**

`ios/Runner/Documents/DocumentsWriter.swift` :

```swift
import Foundation
import UIKit

/// Écriture coordonnée dans le dossier iCloud : PDF de scan, copie d'import, collisions.
enum DocumentsWriter {
  /// `nom.ext`, puis `nom (2).ext`, `nom (3).ext`… selon le contenu du dossier.
  static func uniqueURL(for name: String, in folder: URL) -> URL {
    let base = (name as NSString).deletingPathExtension
    let ext = (name as NSString).pathExtension
    var candidate = folder.appendingPathComponent(name)
    var index = 2
    while exists(candidate) {
      let next = ext.isEmpty ? "\(base) (\(index))" : "\(base) (\(index)).\(ext)"
      candidate = folder.appendingPathComponent(next)
      index += 1
    }
    return candidate
  }

  private static func exists(_ url: URL) -> Bool {
    let placeholder = url.deletingLastPathComponent()
      .appendingPathComponent(".\(url.lastPathComponent).icloud")
    return FileManager.default.fileExists(atPath: url.path)
      || FileManager.default.fileExists(atPath: placeholder.path)
  }

  static func writePDF(pages: [UIImage], named name: String, in folder: URL) throws -> String {
    let target = uniqueURL(for: name, in: folder)
    let data = UIGraphicsPDFRenderer(bounds: .zero).pdfData { context in
      for page in pages {
        let bounds = CGRect(origin: .zero, size: page.size)
        context.beginPage(withBounds: bounds, pageInfo: [:])
        page.draw(in: bounds)
      }
    }
    try coordinatedWrite(to: target) { url in try data.write(to: url, options: .atomic) }
    return target.lastPathComponent
  }

  static func copy(_ source: URL, named name: String, in folder: URL) throws -> String {
    let target = uniqueURL(for: name, in: folder)
    try coordinatedWrite(to: target) { url in try FileManager.default.copyItem(at: source, to: url) }
    return target.lastPathComponent
  }

  private static func coordinatedWrite(to target: URL, _ body: (URL) throws -> Void) throws {
    var coordinationError: NSError?
    var writeError: Error?
    NSFileCoordinator().coordinate(writingItemAt: target, options: [], error: &coordinationError) { url in
      do { try body(url) } catch { writeError = error }
    }
    if let error = coordinationError ?? (writeError as NSError?) {
      throw DocumentsError.io(error.localizedDescription)
    }
  }
}
```

- [ ] **Step 2 : Scanner et sélecteur de fichier dans le presenter**

Dans `ios/Runner/Documents/DocumentsPresenter.swift` :

- ajouter `import VisionKit` ;
- ajouter la propriété `private var scanCompletion: ((Result<[UIImage], DocumentsError>) -> Void)?` ;
- ajouter les deux méthodes dans la classe :

```swift
  func pickFile(completion: @escaping (Result<URL, DocumentsError>) -> Void) {
    guard let host else {
      completion(.failure(.io("Aucune fenêtre")))
      return
    }
    pickerCompletion = completion
    let picker = UIDocumentPickerViewController(forOpeningContentTypes: [.item], asCopy: true)
    picker.allowsMultipleSelection = false
    picker.delegate = self
    host.present(picker, animated: true)
  }

  func scan(completion: @escaping (Result<[UIImage], DocumentsError>) -> Void) {
    guard VNDocumentCameraViewController.isSupported, let host else {
      completion(.failure(.io("Scanner indisponible")))
      return
    }
    scanCompletion = completion
    let scanner = VNDocumentCameraViewController()
    scanner.delegate = self
    host.present(scanner, animated: true)
  }
```

- ajouter l'extension :

```swift
extension DocumentsPresenter: VNDocumentCameraViewControllerDelegate {
  private func finishScan(_ controller: UIViewController, _ outcome: Result<[UIImage], DocumentsError>) {
    let completion = scanCompletion
    scanCompletion = nil
    controller.dismiss(animated: true) { completion?(outcome) }
  }

  func documentCameraViewController(
    _ controller: VNDocumentCameraViewController, didFinishWith scan: VNDocumentCameraScan
  ) {
    let pages = (0..<scan.pageCount).map { scan.imageOfPage(at: $0) }
    finishScan(controller, .success(pages))
  }

  func documentCameraViewControllerDidCancel(_ controller: VNDocumentCameraViewController) {
    finishScan(controller, .failure(.cancelled))
  }

  func documentCameraViewController(
    _ controller: VNDocumentCameraViewController, didFailWithError error: Error
  ) {
    finishScan(controller, .failure(.io(error.localizedDescription)))
  }
}
```

- [ ] **Step 3 : Handlers dans le plugin**

Dans `ios/Runner/Documents/DocumentsPlugin.swift`, ajouter au `switch` de `handle` :

```swift
      case "scan":
        try scan(path: try argument("path", of: call), fileName: try argument("fileName", of: call), result: result)
      case "importFile":
        try importFile(path: try argument("path", of: call), result: result)
```

et les méthodes :

```swift
  private func scan(path: String, fileName: String, result: @escaping FlutterResult) throws {
    let root = try store.openRoot()
    let folder = try DocumentsStore.resolve(path, under: root.url)
    presenter.scan { outcome in
      defer { root.close() }
      switch outcome {
      case .failure(let error):
        result(error.flutterError)
      case .success(let pages):
        do {
          result(["name": try DocumentsWriter.writePDF(pages: pages, named: fileName, in: folder)])
        } catch let error as DocumentsError {
          result(error.flutterError)
        } catch {
          result(DocumentsError.io(error.localizedDescription).flutterError)
        }
      }
    }
  }

  private func importFile(path: String, result: @escaping FlutterResult) throws {
    let root = try store.openRoot()
    let folder = try DocumentsStore.resolve(path, under: root.url)
    presenter.pickFile { outcome in
      defer { root.close() }
      switch outcome {
      case .failure(let error):
        result(error.flutterError)
      case .success(let source):
        do {
          result(["name": try DocumentsWriter.copy(source, named: source.lastPathComponent, in: folder)])
        } catch let error as DocumentsError {
          result(error.flutterError)
        } catch {
          result(DocumentsError.io(error.localizedDescription).flutterError)
        }
      }
    }
  }
```

- [ ] **Step 4 : Autorisation caméra**

Dans `ios/Runner/Info.plist`, dans le `<dict>` principal :

```xml
	<key>NSCameraUsageDescription</key>
	<string>Colette utilise l'appareil photo pour scanner vos documents.</string>
```

- [ ] **Step 5 : Référencer le nouveau fichier et compiler**

Run: `ruby ios/scripts/add_documents_sources.rb && flutter build ios --simulator 2>&1 | tail -5`
Expected: `ajouté : DocumentsWriter.swift` puis `✓ Built …Runner.app`.

- [ ] **Step 6 : Commit**

```bash
git add ios/Runner/Documents ios/Runner/Info.plist ios/Runner.xcodeproj/project.pbxproj
git commit -m "feat: scan VisionKit et import de fichier dans le dossier iCloud"
```

---

## Finalisation

### Task 16 : Vérification complète

- [ ] **Step 1 : Format, analyse, tests**

Run: `dart format lib test && dart analyze && flutter test 2>&1 | tail -3`
Expected: `No issues found!` puis `All tests passed!`.

- [ ] **Step 2 : Build simulateur**

Run: `flutter build ios --simulator 2>&1 | tail -3`
Expected: `✓ Built`.

- [ ] **Step 3 : Lancer sur simulateur et vérifier la carte**

Lancer l'app sur un simulateur iPhone (skill `run` ou `flutter run`). Vérifier : la carte « Documents » apparaît en bas de l'écran Aujourd'hui avec « Choisir le dossier partagé » ; le tap ouvre le sélecteur Fichiers du simulateur ; choisir « On My iPhone » ou un dossier iCloud du simulateur ; la page liste le dossier ; les Réglages montrent le dossier dans la section Foyer, en clair et en sombre.

- [ ] **Step 4 : Commit des éventuelles corrections**

```bash
git add -A lib test ios
git commit -m "fix: corrections après vérification sur simulateur"
```

(Uniquement s'il y a des corrections.)

---

### Task 17 : Aligner la spec et le README

**Files:**
- Modify: `docs/superpowers/specs/2026-09-22-icloud-documents-design.md`
- Modify: `README.md`

- [ ] **Step 1 : Spec**

Dans la section 6 « Architecture Flutter », remplacer la ligne `providers/documents_controller.dart` par :

```
    providers/documents_preview_controller.dart   DocumentsPreviewController(path) : preview()
    providers/documents_write_controller.dart     DocumentsWriteController : scan(folderPath), importFile(folderPath)
```

Dans « Providers », remplacer le paragraphe `DocumentsController` par :

```
- `DocumentsPreviewController(String path)` (`autoDispose`, famille) : `preview()`. `cancelled` remet `AsyncData(null)` ; toute autre failure passe en `AsyncError`. Chaque `DocumentEntryTile` `ref.watch`e son instance (indicateur de ligne) et `ref.listen`e ses erreurs.
- `DocumentsWriteController` (`autoDispose`) : `scan(folderPath)` (nom calculé avec `clockProvider` et `buildScanFileName`) et `importFile(folderPath)`. Après succès, `ref.invalidate(documentsFolderProvider(folderPath))`. `cancelled` remet `AsyncData(null)`. La page `ref.listen`e ses erreurs.
```

Dans la section 8 « Tests », remplacer `FakeDocumentsRepository dans test/helpers/` par `MockDocumentsRepository (mocktail)`. Dans « Repository », préciser que le mapping `PlatformException → DocumentsFailure` est fait par une méthode privée du repository et non par `guard()`.

- [ ] **Step 2 : README**

Ajouter dans la liste des fonctionnalités du `README.md` une ligne :

```
- Documents : consultation du dossier iCloud Drive partagé (choisi une fois par iPhone), aperçu Quick Look, scan et import dans le dossier.
```

et, dans la section iOS ou installation, une note : « Les sources Swift de `ios/Runner/Documents/` sont référencées dans le projet Xcode par `ruby ios/scripts/add_documents_sources.rb` (gem `xcodeproj`, livré avec CocoaPods). »

- [ ] **Step 3 : Commit**

```bash
git add docs/superpowers/specs/2026-09-22-icloud-documents-design.md README.md
git commit -m "docs: aligne la spec documents iCloud et le README"
```

---

### Task 18 : Liste de contrôle manuelle sur iPhone réel

À faire par Maxence avec le dossier partagé, sur les deux iPhones. Reporter les résultats dans la spec (section 8) sous forme de cases cochées.

- [ ] Choisir le dossier partagé ; la carte affiche son nom.
- [ ] Lister la racine et un sous-dossier ; dossiers d'abord, fichiers du plus récent au plus ancien.
- [ ] Ouvrir un fichier déjà téléchargé, puis un fichier avec l'icône nuage (téléchargement puis aperçu).
- [ ] Scanner deux pages ; le PDF apparaît dans Fichiers sur les deux iPhones.
- [ ] Importer un PDF depuis Mail, puis le même une seconde fois : suffixe `(2)`.
- [ ] Tuer et relancer l'app : le dossier est toujours accessible.
- [ ] Renommer le dossier dans Fichiers : l'accès tient ; le nom affiché suit après « Changer de dossier ».
- [ ] Supprimer le dossier : vue « accès perdu », re-choix fonctionnel.
- [ ] Mode avion : listage OK, aperçu d'un fichier nuage → `SnackBar` après 30 s.
- [ ] Thème sombre : carte, page, section Réglages lisibles.
