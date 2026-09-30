import 'package:colette/core/result/failure.dart';
import 'package:colette/features/photo_sharing/data/native_photo_sharing_system.dart';
import 'package:colette/features/photo_sharing/domain/entities/recipient.dart';
import 'package:colette/features/photo_sharing/domain/entities/send_report.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  const channel = MethodChannel(NativePhotoSharingSystem.channelName);
  final messenger =
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;
  late List<MethodCall> calls;
  late NativePhotoSharingSystem system;

  void mock(Object? Function(MethodCall call) handler) {
    messenger.setMockMethodCallHandler(channel, (call) async {
      calls.add(call);
      return handler(call);
    });
  }

  setUp(() {
    calls = [];
    system = NativePhotoSharingSystem(channel);
  });

  tearDown(() => messenger.setMockMethodCallHandler(channel, null));

  test('pickContact : null si annulé', () async {
    mock((_) => null);
    expect((await system.pickContact()).toNullable(), isNull);
    expect(calls.single.method, 'pickContact');
  });

  test('pickContact : nom et numéro', () async {
    mock((_) => {'name': 'Mamie', 'phone': '0612345678'});
    expect(
      (await system.pickContact()).toNullable(),
      const Recipient(name: 'Mamie', phone: '0612345678'),
    );
  });

  test('pickPhotos et takePhoto : chemins', () async {
    mock(
      (call) => call.method == 'pickPhotos'
          ? ['/tmp/a.jpg', '/tmp/b.jpg']
          : <String>[],
    );
    expect((await system.pickPhotos()).toNullable(), [
      '/tmp/a.jpg',
      '/tmp/b.jpg',
    ]);
    expect((await system.takePhoto()).toNullable(), isEmpty);
  });

  test('sendMessages : arguments et bilan', () async {
    mock((_) => {'sent': 2, 'cancelled': 1, 'failed': 0});
    final result = await system.sendMessages(
      phones: ['0611', '0622', '0633'],
      photoPaths: ['/tmp/a.jpg'],
      body: 'Coucou',
    );
    expect(
      result.toNullable(),
      const SendReport(sent: 2, cancelled: 1, failed: 0),
    );
    expect(calls.single.arguments, {
      'phones': ['0611', '0622', '0633'],
      'photoPaths': ['/tmp/a.jpg'],
      'body': 'Coucou',
    });
  });

  for (final (code, reason) in [
    ('messagesUnavailable', PhotoSharingReason.messagesUnavailable),
    ('cameraUnavailable', PhotoSharingReason.cameraUnavailable),
    ('busy', PhotoSharingReason.busy),
    ('io', PhotoSharingReason.io),
  ]) {
    test('code natif $code → PhotoSharingFailure($reason)', () async {
      mock((_) => throw PlatformException(code: code, message: 'détail'));
      final result = await system.sendMessages(
        phones: ['0611'],
        photoPaths: [],
        body: '',
      );
      expect(result.getLeft().toNullable(), PhotoSharingFailure(reason));
    });
  }

  test('code inconnu → UnknownFailure', () async {
    mock((_) => throw PlatformException(code: 'boom'));
    expect(
      (await system.pickPhotos()).getLeft().toNullable(),
      isA<UnknownFailure>(),
    );
  });

  test('syncReminders : dates en millisecondes', () async {
    mock((_) => null);
    final date = DateTime(2026, 9, 30, 14, 7);
    await system.syncReminders(dates: [date], title: 'T', body: 'B');
    expect(calls.single.method, 'syncReminders');
    expect(calls.single.arguments, {
      'dates': [date.millisecondsSinceEpoch],
      'title': 'T',
      'body': 'B',
    });
  });

  test('discardPhotos et takePendingRoute avalent les erreurs', () async {
    mock((_) => throw PlatformException(code: 'io'));
    await system.discardPhotos(['/tmp/a.jpg']);
    expect(await system.takePendingRoute(), isNull);
  });

  test('takePendingRoute : valeur non String → null sans exception', () async {
    mock((_) => 42);
    expect(await system.takePendingRoute(), isNull);
  });

  test('takePendingRoute rend la route', () async {
    mock((_) => '/today/photos');
    expect(await system.takePendingRoute(), '/today/photos');
  });

  test('routePending venu de Swift → signal', () async {
    final signal = system.pendingRouteSignals.first;
    await messenger.handlePlatformMessage(
      NativePhotoSharingSystem.channelName,
      const StandardMethodCodec().encodeMethodCall(
        const MethodCall('routePending'),
      ),
      (_) {},
    );
    await expectLater(signal, completes);
  });

  test('méthode venue de Swift inconnue → non implémentée', () async {
    ByteData? reply = ByteData(0);
    await messenger.handlePlatformMessage(
      NativePhotoSharingSystem.channelName,
      const StandardMethodCodec().encodeMethodCall(
        const MethodCall('inconnue'),
      ),
      (data) => reply = data,
    );
    expect(reply, isNull);
  });
}
