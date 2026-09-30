import 'dart:async';

import 'package:colette/core/clock/app_clock.dart';
import 'package:colette/core/result/failure.dart';
import 'package:colette/features/household/presentation/providers/household_providers.dart';
import 'package:colette/features/photo_sharing/domain/entities/broadcast_list.dart';
import 'package:colette/features/photo_sharing/domain/entities/recipient.dart';
import 'package:colette/features/photo_sharing/domain/entities/send_report.dart';
import 'package:colette/features/photo_sharing/presentation/providers/photo_capture_controller.dart';
import 'package:colette/features/photo_sharing/presentation/providers/photo_sharing_providers.dart';
import 'package:colette/features/photo_sharing/presentation/widgets/photo_send_flow.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../helpers/fake_photo_sharing_system.dart';
import '../../../helpers/in_memory_household_local_store.dart';
import '../../../helpers/in_memory_photo_sharing_repository.dart';
import '../../../helpers/pump_app.dart';

const _family = BroadcastList(
  id: 'l1',
  name: 'Famille',
  recipients: [
    Recipient(name: 'Mamie', phone: '0611'),
    Recipient(name: 'Papi', phone: '0622'),
  ],
);

/// Page minimale qui lance le flux, en surveillant le contrôleur de capture.
class _Host extends ConsumerWidget {
  const _Host();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    ref.watch(photoCaptureControllerProvider);
    return Scaffold(
      body: Center(
        child: TextButton(
          onPressed: () => startPhotoSend(context, ref, _family),
          child: const Text('go'),
        ),
      ),
    );
  }
}

void main() {
  late FakePhotoSharingSystem system;
  late InMemoryPhotoSharingRepository repo;

  setUp(() {
    system = FakePhotoSharingSystem()..photos = ['/tmp/a.jpg', '/tmp/b.jpg'];
    repo = InMemoryPhotoSharingRepository();
  });

  Future<void> start(
    WidgetTester tester, {
    String source = 'Choisir dans la galerie',
  }) async {
    await pumpApp(
      tester,
      const _Host(),
      overrides: [
        photoSharingSystemProvider.overrideWithValue(system),
        photoSharingRepositoryProvider.overrideWithValue(repo),
        clockProvider.overrideWithValue(FixedClock(DateTime(2026, 9, 30, 15))),
        householdLocalStoreProvider.overrideWithValue(
          InMemoryHouseholdLocalStore(),
        ),
      ],
    );
    await tester.tap(find.text('go'));
    await tester.pumpAndSettle();
    expect(find.text('Prendre une photo'), findsOneWidget);
    await tester.tap(find.text(source));
    await tester.pumpAndSettle();
  }

  testWidgets("galerie → feuille d'envoi → un message par personne", (
    tester,
  ) async {
    system.report = const SendReport(sent: 2, cancelled: 0, failed: 0);
    await start(tester);
    expect(find.text('Envoyer à 2 personnes'), findsOneWidget);
    await tester.enterText(find.byType(TextField), 'Coucou');
    await tester.tap(find.text('Envoyer à 2 personnes'));
    await tester.pumpAndSettle();
    expect(system.sendCalls.single.phones, ['0611', '0622']);
    expect(system.sendCalls.single.photoPaths, ['/tmp/a.jpg', '/tmp/b.jpg']);
    expect(system.sendCalls.single.body, 'Coucou');
    expect(find.text('2 envoyés'), findsOneWidget);
    expect(find.text('Envoyer à 2 personnes'), findsNothing);
    expect(system.discarded, ['/tmp/a.jpg', '/tmp/b.jpg']);
    expect(repo.lastSentAt, DateTime(2026, 9, 30, 15));
  });

  testWidgets("pendant l'envoi : la feuille ne se ferme pas par le fond", (
    tester,
  ) async {
    system.sendGate = Completer<void>();
    await start(tester);
    await tester.tap(find.text('Envoyer à 2 personnes'));
    await tester.pump();
    await tester.tapAt(const Offset(10, 10));
    // Indicateur de progression animé : pas de pumpAndSettle pendant l'envoi.
    await tester.pump(const Duration(seconds: 1));
    expect(find.byType(TextField), findsOneWidget);
    expect(system.discarded, isEmpty);
    system.sendGate!.complete();
    await tester.pumpAndSettle();
    expect(find.byType(TextField), findsNothing);
    expect(system.discarded, ['/tmp/a.jpg', '/tmp/b.jpg']);
  });

  testWidgets('feuille fermée sans envoyer : photos effacées', (tester) async {
    await start(tester);
    await tester.tapAt(const Offset(10, 10));
    await tester.pumpAndSettle();
    expect(system.sendCalls, isEmpty);
    expect(system.discarded, ['/tmp/a.jpg', '/tmp/b.jpg']);
  });

  testWidgets("capture annulée : pas de feuille d'envoi", (tester) async {
    system.photos = const [];
    await start(tester);
    expect(find.textContaining('Envoyer à'), findsNothing);
  });

  testWidgets("Messages indisponible : message d'erreur", (tester) async {
    system.sendFailure = const PhotoSharingFailure(
      PhotoSharingReason.messagesUnavailable,
    );
    await start(tester, source: 'Prendre une photo');
    await tester.tap(find.text('Envoyer à 2 personnes'));
    await tester.pumpAndSettle();
    expect(
      find.text("Messages n'est pas disponible sur cet appareil."),
      findsOneWidget,
    );
    expect(system.discarded, ['/tmp/a.jpg', '/tmp/b.jpg']);
    expect(repo.lastSentAt, isNull);
  });
}
