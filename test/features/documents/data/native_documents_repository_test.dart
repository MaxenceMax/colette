import 'dart:async';

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
    repo = const NativeDocumentsRepository(channel);
  });

  const folderChannel = EventChannel('colette/documents/folder/test');

  tearDown(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
      ..setMockMethodCallHandler(channel, null)
      ..setMockStreamHandler(folderChannel, null);
  });

  /// Mock `openFolderStream` → canal de test, et le handler du flux.
  void mockFolderStream(MockStreamHandler handler) {
    mock((call) {
      if (call.method == 'openFolderStream') {
        return {'channel': folderChannel.name};
      }
      return null;
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
    'downloadProgress': ?progress,
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

  test('désabonnement pendant openFolderStream : listen puis cancel', () async {
    final opening = Completer<Map<String, Object?>>();
    var listened = false;
    final cancelled = Completer<void>();
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, (call) {
          calls.add(call);
          return opening.future;
        });
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockStreamHandler(
          folderChannel,
          MockStreamHandler.inline(
            onListen: (_, events) {
              listened = true;
              events.success(const []);
            },
            onCancel: (_) => cancelled.complete(),
          ),
        );
    final subscription = repo.watch('Ordonnances').listen((_) {});
    await Future<void>.delayed(Duration.zero);
    unawaited(subscription.cancel());
    opening.complete({'channel': folderChannel.name});
    await cancelled.future.timeout(const Duration(seconds: 2));
    expect(listened, isTrue);
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

  test('rootFolder renvoie null sans dossier', () async {
    mock((_) => null);
    final result = await repo.rootFolder();
    expect(result.toNullable(), isNull);
    expect(calls.single.method, 'rootFolder');
    expect(calls.single.arguments, isNull);
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
    expect(calls.single.arguments, isNull);
  });

  test('forgetRootFolder appelle le canal', () async {
    mock((_) => null);
    final result = await repo.forgetRootFolder();
    expect(result.isRight(), isTrue);
    expect(calls.single.method, 'forgetRootFolder');
    expect(calls.single.arguments, isNull);
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

  test('entrée malformée → UnknownFailure', () async {
    mock(
      (_) => [
        {'name': 1},
      ],
    );
    final result = await repo.list('');
    expect(result.getLeft().toNullable(), isA<UnknownFailure>());
  });

  test('list renvoie une liste vide quand le canal renvoie null', () async {
    mock((_) => null);
    final result = await repo.list('');
    expect(result.toNullable(), isEmpty);
  });
}
