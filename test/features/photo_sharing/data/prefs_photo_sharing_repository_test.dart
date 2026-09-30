import 'package:colette/features/photo_sharing/data/repositories/prefs_photo_sharing_repository.dart';
import 'package:colette/features/photo_sharing/domain/entities/broadcast_list.dart';
import 'package:colette/features/photo_sharing/domain/entities/recipient.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  final lists = [
    BroadcastList(
      id: 'l1',
      name: 'Grands-parents',
      recipients: const [
        Recipient(name: 'Mamie', phone: '0612345678'),
        Recipient(name: 'Papi', phone: '+33698765432'),
      ],
      lastSentAt: DateTime(2026, 9, 29, 18, 12, 5, 42),
    ),
    const BroadcastList(id: 'l2', name: 'Amis', recipients: []),
  ];

  Future<PrefsPhotoSharingRepository> repoWith(
    Map<String, Object> values,
  ) async {
    SharedPreferences.setMockInitialValues(values);
    return PrefsPhotoSharingRepository(await SharedPreferences.getInstance());
  }

  test('valeurs par défaut', () async {
    final repo = await repoWith({});
    expect((await repo.loadLists()).toNullable(), isEmpty);
    expect((await repo.loadLastSentAt()).toNullable(), isNull);
    expect((await repo.loadReminderEnabled()).toNullable(), isTrue);
  });

  test('listes : aller-retour', () async {
    final repo = await repoWith({});
    await repo.saveLists(lists);
    expect((await repo.loadLists()).toNullable(), lists);
  });

  test('liste enregistrée sans dernier envoi : jamais envoyée', () async {
    final repo = await repoWith({
      PrefsPhotoSharingRepository.listsKey:
          '[{"id":"l1","name":"Amis","recipients":[]}]',
    });
    expect((await repo.loadLists()).toNullable()!.single.lastSentAt, isNull);
  });

  test('dernier envoi : aller-retour à la milliseconde', () async {
    final repo = await repoWith({});
    final sentAt = DateTime(2026, 9, 30, 18, 12, 5, 42);
    await repo.saveLastSentAt(sentAt);
    expect((await repo.loadLastSentAt()).toNullable(), sentAt);
  });

  test('interrupteur : aller-retour', () async {
    final repo = await repoWith({});
    await repo.saveReminderEnabled(false);
    expect((await repo.loadReminderEnabled()).toNullable(), isFalse);
  });

  test('JSON corrompu : Left', () async {
    final repo = await repoWith({
      PrefsPhotoSharingRepository.listsKey: '[{"id":',
    });
    expect((await repo.loadLists()).isLeft(), isTrue);
  });

  for (final raw in ['{}', '[{"id":1}]']) {
    test('JSON valide de mauvaise forme $raw : Left', () async {
      final repo = await repoWith({PrefsPhotoSharingRepository.listsKey: raw});
      expect((await repo.loadLists()).isLeft(), isTrue);
    });
  }
}
