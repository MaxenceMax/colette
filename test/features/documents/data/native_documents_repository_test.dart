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

  tearDown(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, null);
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
