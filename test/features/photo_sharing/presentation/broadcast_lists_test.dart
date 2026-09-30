import 'package:colette/core/ids/id_generator.dart';
import 'package:colette/core/result/failure.dart';
import 'package:colette/features/photo_sharing/domain/entities/broadcast_list.dart';
import 'package:colette/features/photo_sharing/domain/entities/recipient.dart';
import 'package:colette/features/photo_sharing/presentation/providers/broadcast_lists.dart';
import 'package:colette/features/photo_sharing/presentation/providers/photo_sharing_providers.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../helpers/fake_photo_sharing_system.dart';
import '../../../helpers/in_memory_photo_sharing_repository.dart';

void main() {
  const mamie = Recipient(name: 'Mamie', phone: '0612345678');
  const papi = Recipient(name: 'Papi', phone: '0698765432');
  late InMemoryPhotoSharingRepository repo;
  late FakePhotoSharingSystem system;
  late ProviderContainer container;

  setUp(() {
    repo = InMemoryPhotoSharingRepository(
      lists: const [BroadcastList(id: 'l1', name: 'Famille', recipients: [])],
    );
    system = FakePhotoSharingSystem();
    container = ProviderContainer(
      overrides: [
        photoSharingRepositoryProvider.overrideWithValue(repo),
        photoSharingSystemProvider.overrideWithValue(system),
        idGeneratorProvider.overrideWithValue(const FixedIdGenerator('l2')),
      ],
    );
    addTearDown(container.dispose);
  });

  BroadcastLists notifier() => container.read(broadcastListsProvider.notifier);

  Future<List<BroadcastList>> lists() =>
      container.read(broadcastListsProvider.future);

  test('charge les listes enregistrées', () async {
    expect((await lists()).single.name, 'Famille');
  });

  test('create : nom nettoyé, identifiant généré, enregistré', () async {
    await lists();
    final id = await notifier().create('  Amis ');
    expect(id.toNullable(), 'l2');
    expect(
      (await lists()).last,
      const BroadcastList(id: 'l2', name: 'Amis', recipients: []),
    );
    expect(repo.lists, hasLength(2));
  });

  test('rename et delete', () async {
    await lists();
    await notifier().rename('l1', 'Grands-parents');
    expect((await lists()).single.name, 'Grands-parents');
    await notifier().delete('l1');
    expect(await lists(), isEmpty);
    expect(repo.lists, isEmpty);
  });

  test('addFromContacts : ajoute le contact choisi', () async {
    system.contact = mamie;
    await lists();
    await notifier().addFromContacts('l1');
    expect((await lists()).single.recipients, [mamie]);
    expect(repo.lists.single.recipients, [mamie]);
  });

  test('addFromContacts en échec : failure renvoyée, rien ne change', () async {
    system.contact = mamie;
    system.contactFailure = const PhotoSharingFailure(PhotoSharingReason.busy);
    await lists();
    final result = await notifier().addFromContacts('l1');
    expect(
      result.getLeft().toNullable(),
      const PhotoSharingFailure(PhotoSharingReason.busy),
    );
    expect((await lists()).single.recipients, isEmpty);
    expect(repo.lists.single.recipients, isEmpty);
  });

  test('addFromContacts annulé : rien ne change', () async {
    await lists();
    final result = await notifier().addFromContacts('l1');
    expect(result.isRight(), isTrue);
    expect((await lists()).single.recipients, isEmpty);
  });

  test('removeRecipient', () async {
    repo.lists = const [
      BroadcastList(id: 'l1', name: 'Famille', recipients: [mamie]),
    ];
    await lists();
    await notifier().removeRecipient('l1', mamie.phone);
    expect((await lists()).single.recipients, isEmpty);
  });

  test('markSent : date posée sur la liste et enregistrée', () async {
    final sentAt = DateTime(2026, 9, 30, 15, 20);
    await lists();
    await notifier().markSent('l1', sentAt);
    expect((await lists()).single.lastSentAt, sentAt);
    expect(repo.lists.single.lastSentAt, sentAt);
  });

  test('markSent sur une liste supprimée : rien ne change', () async {
    await lists();
    await notifier().markSent('absente', DateTime(2026, 9, 30));
    expect((await lists()).single.lastSentAt, isNull);
  });

  test('deux retraits simultanés : les deux sont appliqués', () async {
    repo.lists = const [
      BroadcastList(id: 'l1', name: 'Famille', recipients: [mamie, papi]),
    ];
    await lists();
    final results = await Future.wait([
      notifier().removeRecipient('l1', mamie.phone),
      notifier().removeRecipient('l1', papi.phone),
    ]);
    expect(results.every((result) => result.isRight()), isTrue);
    expect((await lists()).single.recipients, isEmpty);
    expect(repo.lists.single.recipients, isEmpty);
  });

  test('listes illisibles puis create : la nouvelle liste est seule', () async {
    repo.failLoads = true;
    await expectLater(lists(), throwsA(isA<UnknownFailure>()));
    final id = await notifier().create('Amis');
    expect(id.toNullable(), 'l2');
    const created = BroadcastList(id: 'l2', name: 'Amis', recipients: []);
    expect(await lists(), [created]);
    expect(repo.lists, [created]);
  });

  test(
    "create avec écriture en échec : failure, aucune liste ajoutée",
    () async {
      await lists();
      repo.failSaves = true;
      final result = await notifier().create('Amis');
      expect(result.getLeft().toNullable(), isA<UnknownFailure>());
      expect((await lists()).single.id, 'l1');
      expect(repo.lists.single.id, 'l1');
    },
  );

  test("échec d'écriture : état inchangé, failure renvoyée", () async {
    await lists();
    repo.failSaves = true;
    final result = await notifier().rename('l1', 'X');
    expect(result.getLeft().toNullable(), isA<UnknownFailure>());
    expect((await lists()).single.name, 'Famille');
  });
}
