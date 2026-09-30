import 'package:colette/core/clock/app_clock.dart';
import 'package:colette/core/clock/now_providers.dart';
import 'package:colette/core/ids/id_generator.dart';
import 'package:colette/core/result/failure.dart';
import 'package:colette/features/household/presentation/providers/household_providers.dart';
import 'package:colette/features/photo_sharing/domain/entities/broadcast_list.dart';
import 'package:colette/features/photo_sharing/domain/entities/recipient.dart';
import 'package:colette/features/photo_sharing/presentation/pages/photos_page.dart';
import 'package:colette/features/photo_sharing/presentation/providers/photo_sharing_providers.dart';
import 'package:flutter/material.dart';
import 'package:flutter/semantics.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../helpers/fake_photo_sharing_system.dart';
import '../../../helpers/in_memory_household_local_store.dart';
import '../../../helpers/in_memory_photo_sharing_repository.dart';
import '../../../helpers/pump_app.dart';

void main() {
  const mamie = Recipient(name: 'Mamie', phone: '0611');
  late InMemoryPhotoSharingRepository repo;
  late FakePhotoSharingSystem system;

  setUp(() {
    repo = InMemoryPhotoSharingRepository();
    system = FakePhotoSharingSystem();
  });

  Future<void> pumpPage(WidgetTester tester) => pumpApp(
    tester,
    const PhotosPage(),
    overrides: [
      photoSharingRepositoryProvider.overrideWithValue(repo),
      photoSharingSystemProvider.overrideWithValue(system),
      idGeneratorProvider.overrideWithValue(const FixedIdGenerator('l1')),
      clockProvider.overrideWithValue(FixedClock(DateTime(2026, 9, 30, 10))),
      minuteTickerProvider.overrideWith((ref) => const Stream.empty()),
      householdLocalStoreProvider.overrideWithValue(
        InMemoryHouseholdLocalStore(),
      ),
    ],
  );

  testWidgets('état vide', (tester) async {
    await pumpPage(tester);
    expect(
      find.text(
        'Crée une liste de proches pour leur envoyer des photos en quelques appuis.',
      ),
      findsOneWidget,
    );
  });

  testWidgets('créer une liste ouvre son édition, puis ajouter un contact', (
    tester,
  ) async {
    system.contact = mamie;
    await pumpPage(tester);
    await tester.tap(find.text('Nouvelle liste'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField), 'Grands-parents');
    await tester.pump();
    await tester.tap(find.text('Créer'));
    await tester.pumpAndSettle();
    expect(find.text('Aucune personne dans cette liste.'), findsOneWidget);
    await tester.tap(find.text('Ajouter une personne'));
    await tester.pumpAndSettle();
    expect(find.text('Mamie'), findsOneWidget);
    expect(repo.lists.single.recipients, [mamie]);
  });

  testWidgets('nom vide : bouton Créer inactif', (tester) async {
    await pumpPage(tester);
    await tester.tap(find.text('Nouvelle liste'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField), '   ');
    await tester.pump();
    final button = tester.widget<TextButton>(
      find.widgetWithText(TextButton, 'Créer'),
    );
    expect(button.onPressed, isNull);
  });

  testWidgets('glisser une personne la retire', (tester) async {
    repo.lists = const [
      BroadcastList(id: 'l1', name: 'Famille', recipients: [mamie]),
    ];
    await pumpPage(tester);
    await tester.tap(find.byTooltip('Modifier la liste'));
    await tester.pumpAndSettle();
    await tester.drag(find.text('Mamie'), const Offset(-500, 0));
    await tester.pumpAndSettle();
    expect(repo.lists.single.recipients, isEmpty);
  });

  testWidgets('VoiceOver : action « Retirer de la liste »', (tester) async {
    final semantics = tester.ensureSemantics();
    repo.lists = const [
      BroadcastList(id: 'l1', name: 'Famille', recipients: [mamie]),
    ];
    await pumpPage(tester);
    await tester.tap(find.byTooltip('Modifier la liste'));
    await tester.pumpAndSettle();
    const remove = CustomSemanticsAction(label: 'Retirer de la liste');
    tester.semantics.customAction(
      find.semantics.byLabel(RegExp('Mamie')),
      remove,
    );
    await tester.pumpAndSettle();
    expect(repo.lists.single.recipients, isEmpty);
    expect(find.text('Mamie'), findsNothing);
    semantics.dispose();
  });

  testWidgets('retrait en échec : message', (tester) async {
    repo.lists = const [
      BroadcastList(id: 'l1', name: 'Famille', recipients: [mamie]),
    ];
    await pumpPage(tester);
    await tester.tap(find.byTooltip('Modifier la liste'));
    await tester.pumpAndSettle();
    repo.failSaves = true;
    await tester.drag(find.text('Mamie'), const Offset(-500, 0));
    await tester.pumpAndSettle();
    expect(find.byType(SnackBar), findsOneWidget);
    expect(repo.lists.single.recipients, [mamie]);
    expect(find.text('Mamie'), findsOneWidget);
  });

  testWidgets('renommer la liste', (tester) async {
    repo.lists = const [
      BroadcastList(id: 'l1', name: 'Famille', recipients: [mamie]),
    ];
    await pumpPage(tester);
    await tester.tap(find.byTooltip('Modifier la liste'));
    await tester.pumpAndSettle();
    await tester.tap(find.byTooltip('Renommer la liste'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField), 'Grands-parents');
    await tester.pump();
    await tester.tap(find.text('Enregistrer'));
    await tester.pumpAndSettle();
    expect(repo.lists.single.name, 'Grands-parents');
    expect(find.text('Grands-parents'), findsWidgets);
    expect(find.text('Famille'), findsNothing);
  });

  testWidgets('supprimer la liste après confirmation', (tester) async {
    repo.lists = const [
      BroadcastList(id: 'l1', name: 'Famille', recipients: []),
    ];
    await pumpPage(tester);
    await tester.tap(find.byTooltip('Modifier la liste'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Supprimer la liste'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Supprimer'));
    await tester.pumpAndSettle();
    expect(repo.lists, isEmpty);
    expect(find.text('Famille'), findsNothing);
  });

  testWidgets('suppression en échec : feuille fermée et message', (
    tester,
  ) async {
    repo.lists = const [
      BroadcastList(id: 'l1', name: 'Famille', recipients: []),
    ];
    await pumpPage(tester);
    await tester.tap(find.byTooltip('Modifier la liste'));
    await tester.pumpAndSettle();
    repo.failSaves = true;
    await tester.tap(find.text('Supprimer la liste'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Supprimer'));
    await tester.pumpAndSettle();
    expect(find.text('Ajouter une personne'), findsNothing);
    expect(find.byType(SnackBar), findsOneWidget);
    expect(find.text('Famille'), findsOneWidget);
  });

  testWidgets('dernière carte au-dessus du bouton flottant', (tester) async {
    repo.lists = [
      for (var i = 0; i < 12; i++)
        BroadcastList(id: 'l$i', name: 'Liste $i', recipients: const []),
    ];
    await pumpPage(tester);
    await tester.drag(find.byType(ListView), const Offset(0, -5000));
    await tester.pumpAndSettle();
    final card = tester.getRect(find.text('Liste 11'));
    final fab = tester.getRect(find.byType(FloatingActionButton));
    expect(card.bottom, lessThanOrEqualTo(fab.top));
  });

  testWidgets("liste vide : l'appui ouvre l'édition", (tester) async {
    repo.lists = const [
      BroadcastList(id: 'l1', name: 'Famille', recipients: []),
    ];
    await pumpPage(tester);
    await tester.tap(find.text('Famille'));
    await tester.pumpAndSettle();
    expect(find.text('Ajouter une personne'), findsOneWidget);
  });

  testWidgets("liste remplie : l'appui propose la source des photos", (
    tester,
  ) async {
    repo.lists = const [
      BroadcastList(id: 'l1', name: 'Famille', recipients: [mamie]),
    ];
    await pumpPage(tester);
    expect(find.text('1 personne'), findsOneWidget);
    await tester.tap(find.text('Famille'));
    await tester.pumpAndSettle();
    expect(find.text('Choisir dans la galerie'), findsOneWidget);
  });

  testWidgets('appareil photo indisponible : message', (tester) async {
    repo.lists = const [
      BroadcastList(id: 'l1', name: 'Famille', recipients: [mamie]),
    ];
    system.photosFailure = const PhotoSharingFailure(
      PhotoSharingReason.cameraUnavailable,
    );
    await pumpPage(tester);
    await tester.tap(find.text('Famille'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Prendre une photo'));
    await tester.pumpAndSettle();
    expect(find.text("L'appareil photo n'est pas disponible."), findsOneWidget);
  });

  testWidgets('dernier envoi affiché par liste, sans en-tête global', (
    tester,
  ) async {
    repo
      ..lists = [
        BroadcastList(
          id: 'l1',
          name: 'Famille',
          recipients: const [mamie],
          lastSentAt: DateTime(2026, 9, 29, 18, 12),
        ),
        const BroadcastList(id: 'l2', name: 'Amis', recipients: [mamie]),
      ]
      ..lastSentAt = DateTime(2026, 9, 30, 8, 5);
    await pumpPage(tester);
    expect(find.text('Dernier envoi · Hier, 18h12'), findsOneWidget);
    expect(find.text('Aucun envoi'), findsOneWidget);
    expect(find.textContaining('08h05'), findsNothing);
  });
}
