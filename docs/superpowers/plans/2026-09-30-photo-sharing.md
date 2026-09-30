# Partage de photos aux proches — plan d'implémentation

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** listes de diffusion locales, envoi de photos (appareil ou galerie) par une feuille Messages par personne, et notification quotidienne à heure aléatoire (8 h – 21 h) désactivable.

**Architecture:** feature `lib/features/photo_sharing/` (domain / data / presentation). Stockage `shared_preferences`. Pont natif `colette/photo-sharing` sur le modèle de `DocumentsPlugin` : interface `PhotoSharingSystem` dans le domaine, `NativePhotoSharingSystem` dans data, Swift dans `ios/Runner/PhotoSharing/`. Notifications locales `UNUserNotificationCenter` programmées 14 jours à l'avance, heure tirée par jour avec une graine fixe.

**Tech Stack:** Flutter, Riverpod 3 codegen, freezed, fpdart, shared_preferences, go_router ; Swift (ContactsUI, PhotosUI, MessageUI, UserNotifications) ; gem `xcodeproj`.

**Spec :** `docs/superpowers/specs/2026-09-30-photo-sharing-design.md`.

**Règles pour chaque tâche :**
- Toutes les commandes depuis la racine du worktree `.claude/worktrees/photo-sharing`.
- `git add` de chemins explicites uniquement ; ne jamais toucher `docs/`.
- Après toute modification d'un fichier annoté (`@riverpod`, `@freezed`) : `dart run build_runner build -d`. Les `.g.dart` et `.freezed.dart` sont versionnés : les committer avec leur source.
- Après toute modification de `lib/l10n/app_fr.arb` : `flutter gen-l10n` (le dossier généré n'est pas versionné).
- Fin de tâche : `dart format lib test`, `dart analyze` (0 problème), tests ciblés verts.

## Structure des fichiers

```
lib/core/result/failure.dart                      (modifié) PhotoSharingFailure
lib/core/ui/failure_message.dart                  (modifié)
lib/l10n/app_fr.arb                               (modifié) chaînes photos…
lib/features/photo_sharing/
  domain/entities/recipient.dart                  Recipient
  domain/entities/broadcast_list.dart             BroadcastList + withRecipient/withoutRecipient
  domain/entities/send_report.dart                SendReport
  domain/entities/photo_source.dart               PhotoSource { camera, gallery }
  domain/use_cases/normalize_phone.dart           normalizePhone
  domain/use_cases/photo_reminder_schedule.dart   planPhotoReminders
  domain/repositories/photo_sharing_repository.dart
  domain/repositories/photo_sharing_system.dart
  data/dtos/broadcast_list_dto.dart
  data/repositories/prefs_photo_sharing_repository.dart
  data/native_photo_sharing_system.dart
  presentation/providers/photo_sharing_providers.dart   repository, système
  presentation/providers/broadcast_lists.dart           BroadcastLists
  presentation/providers/photo_reminder.dart            LastPhotoSentAt, PhotoReminderEnabled, PhotoReminderSync
  presentation/providers/photo_capture_controller.dart
  presentation/providers/photo_send_controller.dart
  presentation/photo_labels.dart                        lastSentLabel, sendReportLabel
  presentation/pages/photos_page.dart
  presentation/widgets/photos_card.dart
  presentation/widgets/list_name_dialog.dart
  presentation/widgets/broadcast_list_editor_sheet.dart
  presentation/widgets/photo_send_flow.dart             choix de la source + capture
  presentation/widgets/photo_send_sheet.dart
  presentation/widgets/photo_reminder_switch.dart
lib/app/photo_reminder_gate.dart
lib/app/colette_app.dart, lib/app/router/app_router.dart (modifiés)
lib/features/dashboard/presentation/pages/dashboard_page.dart (modifié)
lib/features/baby/presentation/pages/settings_page.dart (modifié)
ios/Runner/PhotoSharing/PhotoSharingError.swift, PhotoSharingImages.swift,
  PhotoSharingReminders.swift, PhotoSharingPresenter.swift, PhotoSharingPlugin.swift
ios/scripts/add_photo_sharing_sources.rb
ios/Runner/AppDelegate.swift, ios/Runner/Info.plist, ios/Runner.xcodeproj/project.pbxproj (modifiés)
test/helpers/fake_photo_sharing_system.dart, in_memory_photo_sharing_repository.dart
test/helpers/pump_app.dart, colette_app_overrides.dart (modifiés)
```

---

### Task 1 : chaînes, failure et message d'erreur

**Files:**
- Modify: `lib/l10n/app_fr.arb`
- Modify: `lib/core/result/failure.dart`
- Modify: `lib/core/ui/failure_message.dart`
- Test: `test/core/ui/failure_message_photo_sharing_test.dart`

- [ ] **Step 1 : chaînes.** Dans `lib/l10n/app_fr.arb`, remplacer la dernière entrée `"bottleTimerContinue": "Continuer"` par :

```json
  "bottleTimerContinue": "Continuer",
  "photosCardTitle": "Photos",
  "photosLastSent": "Dernier envoi · {day}, {time}",
  "@photosLastSent": { "placeholders": { "day": { "type": "String" }, "time": { "type": "String" } } },
  "photosNeverSent": "Aucune photo envoyée pour l'instant",
  "photosPageTitle": "Photos aux proches",
  "photosEmptyBody": "Crée une liste de proches pour leur envoyer des photos en quelques appuis.",
  "photosNewList": "Nouvelle liste",
  "photosListNameTitle": "Nom de la liste",
  "photosListNameLabel": "Nom",
  "photosRenameList": "Renommer la liste",
  "photosEditList": "Modifier la liste",
  "photosRecipientCount": "{count, plural, =0{Aucune personne} =1{1 personne} other{{count} personnes}}",
  "@photosRecipientCount": { "placeholders": { "count": { "type": "int" } } },
  "photosAddRecipient": "Ajouter une personne",
  "photosNoRecipients": "Aucune personne dans cette liste.",
  "photosDeleteList": "Supprimer la liste",
  "photosDeleteListTitle": "Supprimer cette liste ?",
  "photosDeleteListBody": "La liste {name} sera supprimée. Tes contacts ne sont pas modifiés.",
  "@photosDeleteListBody": { "placeholders": { "name": { "type": "String" } } },
  "photosTakePhoto": "Prendre une photo",
  "photosPickFromGallery": "Choisir dans la galerie",
  "photosMessageLabel": "Message (facultatif)",
  "photosSendTo": "{count, plural, =1{Envoyer à 1 personne} other{Envoyer à {count} personnes}}",
  "@photosSendTo": { "placeholders": { "count": { "type": "int" } } },
  "photosReportSent": "{count, plural, =0{Aucun message envoyé} =1{1 envoyé} other{{count} envoyés}}",
  "@photosReportSent": { "placeholders": { "count": { "type": "int" } } },
  "photosReportCancelled": "{count, plural, =1{1 annulé} other{{count} annulés}}",
  "@photosReportCancelled": { "placeholders": { "count": { "type": "int" } } },
  "photosReportFailed": "{count, plural, =1{1 en échec} other{{count} en échec}}",
  "@photosReportFailed": { "placeholders": { "count": { "type": "int" } } },
  "photosErrorMessagesUnavailable": "Messages n'est pas disponible sur cet appareil.",
  "photosErrorCameraUnavailable": "L'appareil photo n'est pas disponible.",
  "photosErrorIo": "Impossible de préparer les photos.",
  "photoReminderSetting": "Rappel photo quotidien",
  "photoReminderSettingSubtitle": "Une notification par jour entre 8 h et 21 h",
  "photoReminderTitle": "C'est l'heure d'une photo 📷",
  "photoReminderBody": "Envoie des nouvelles de {name} à tes proches.",
  "@photoReminderBody": { "placeholders": { "name": { "type": "String" } } },
  "photoReminderBodyNoName": "Envoie des nouvelles de bébé à tes proches."
```

Run: `flutter gen-l10n` — Expected : aucune erreur.

- [ ] **Step 2 : test rouge** `test/core/ui/failure_message_photo_sharing_test.dart` :

```dart
import 'dart:ui' show Locale;

import 'package:colette/core/result/failure.dart';
import 'package:colette/core/ui/failure_message.dart';
import 'package:colette/l10n/generated/app_localizations.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  late S s;

  setUpAll(() async {
    s = await S.delegate.load(const Locale('fr'));
  });

  String message(PhotoSharingReason reason) =>
      failureMessage(PhotoSharingFailure(reason), s);

  test('Messages indisponible', () {
    expect(
      message(PhotoSharingReason.messagesUnavailable),
      "Messages n'est pas disponible sur cet appareil.",
    );
  });

  test('appareil photo indisponible', () {
    expect(
      message(PhotoSharingReason.cameraUnavailable),
      "L'appareil photo n'est pas disponible.",
    );
  });

  test('busy et io → préparation impossible', () {
    const expected = 'Impossible de préparer les photos.';
    expect(message(PhotoSharingReason.busy), expected);
    expect(message(PhotoSharingReason.io), expected);
  });

  test('égalité par raison', () {
    expect(
      const PhotoSharingFailure(PhotoSharingReason.io),
      const PhotoSharingFailure(PhotoSharingReason.io),
    );
  });
}
```

Run: `flutter test test/core/ui/failure_message_photo_sharing_test.dart` — Expected : FAIL (`PhotoSharingFailure` inconnu).

- [ ] **Step 3 : failure.** À la fin de `lib/core/result/failure.dart` :

```dart
/// Raison d'une [PhotoSharingFailure].
enum PhotoSharingReason { messagesUnavailable, cameraUnavailable, busy, io }

/// Erreur du pont natif de partage de photos (contacts, photos, Messages).
final class PhotoSharingFailure extends Failure {
  const PhotoSharingFailure(this.reason);

  final PhotoSharingReason reason;

  @override
  bool operator ==(Object other) =>
      other is PhotoSharingFailure && other.reason == reason;

  @override
  int get hashCode => reason.hashCode;
}
```

Dans `lib/core/ui/failure_message.dart`, avant `_ => s.errorUnknown,` :

```dart
  PhotoSharingFailure(:final reason) => switch (reason) {
    PhotoSharingReason.messagesUnavailable => s.photosErrorMessagesUnavailable,
    PhotoSharingReason.cameraUnavailable => s.photosErrorCameraUnavailable,
    PhotoSharingReason.busy || PhotoSharingReason.io => s.photosErrorIo,
  },
```

- [ ] **Step 4 :** `flutter test test/core/ui/failure_message_photo_sharing_test.dart` — Expected : PASS.

- [ ] **Step 5 : commit**

```bash
dart format lib test && dart analyze
git add lib/l10n/app_fr.arb lib/core/result/failure.dart lib/core/ui/failure_message.dart test/core/ui/failure_message_photo_sharing_test.dart
git commit -m "feat: chaînes et failure du partage de photos"
```

---

### Task 2 : entités du domaine

**Files:**
- Create: `lib/features/photo_sharing/domain/entities/recipient.dart`, `broadcast_list.dart`, `send_report.dart`, `photo_source.dart`
- Create: `lib/features/photo_sharing/domain/use_cases/normalize_phone.dart`
- Test: `test/features/photo_sharing/domain/broadcast_list_test.dart`

- [ ] **Step 1 : test rouge** `test/features/photo_sharing/domain/broadcast_list_test.dart` :

```dart
import 'package:colette/features/photo_sharing/domain/entities/broadcast_list.dart';
import 'package:colette/features/photo_sharing/domain/entities/recipient.dart';
import 'package:colette/features/photo_sharing/domain/entities/send_report.dart';
import 'package:colette/features/photo_sharing/domain/use_cases/normalize_phone.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const mamie = Recipient(name: 'Mamie', phone: '06 12 34 56 78');
  const papi = Recipient(name: 'Papi', phone: '+33 6 98 76 54 32');
  const list = BroadcastList(id: 'l1', name: 'Grands-parents', recipients: [mamie]);

  group('normalizePhone', () {
    test('garde les chiffres', () {
      expect(normalizePhone(' 06.12-34 56 78 '), '0612345678');
    });

    test('garde le + initial', () {
      expect(normalizePhone('+33 6 98'), '+33698');
    });
  });

  group('BroadcastList', () {
    test('withRecipient ajoute en fin de liste', () {
      expect(list.withRecipient(papi).recipients, [mamie, papi]);
    });

    test('withRecipient ignore un numéro déjà présent, même mis en forme autrement', () {
      const again = Recipient(name: 'Maman de Max', phone: '0612345678');
      expect(list.withRecipient(again), list);
    });

    test('withoutRecipient retire par numéro exact', () {
      expect(list.withoutRecipient(mamie.phone).recipients, isEmpty);
    });
  });

  group('SendReport', () {
    test('anySent', () {
      expect(const SendReport(sent: 1, cancelled: 2, failed: 0).anySent, isTrue);
      expect(const SendReport(sent: 0, cancelled: 2, failed: 1).anySent, isFalse);
    });
  });
}
```

Run: `flutter test test/features/photo_sharing/domain/broadcast_list_test.dart` — Expected : FAIL (fichiers absents).

- [ ] **Step 2 : implémentation.**

`lib/features/photo_sharing/domain/use_cases/normalize_phone.dart` :

```dart
/// Chiffres du numéro, `+` initial conservé : « 06 12-34 » → « 061234 ».
String normalizePhone(String phone) {
  final trimmed = phone.trim();
  final digits = trimmed.replaceAll(RegExp(r'\D'), '');
  return trimmed.startsWith('+') ? '+$digits' : digits;
}
```

`lib/features/photo_sharing/domain/entities/recipient.dart` :

```dart
import 'package:freezed_annotation/freezed_annotation.dart';

part 'recipient.freezed.dart';

/// Proche qui reçoit les photos : nom affiché et numéro choisi dans les contacts.
@freezed
abstract class Recipient with _$Recipient {
  const factory Recipient({required String name, required String phone}) =
      _Recipient;
}
```

`lib/features/photo_sharing/domain/entities/broadcast_list.dart` :

```dart
import 'package:colette/features/photo_sharing/domain/entities/recipient.dart';
import 'package:colette/features/photo_sharing/domain/use_cases/normalize_phone.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

part 'broadcast_list.freezed.dart';

/// Liste de diffusion : un nom et les proches qui reçoivent chacun un message.
@freezed
abstract class BroadcastList with _$BroadcastList {
  const BroadcastList._();

  const factory BroadcastList({
    required String id,
    required String name,
    required List<Recipient> recipients,
  }) = _BroadcastList;

  /// Ajoute [recipient], sauf si son numéro (normalisé) est déjà présent.
  BroadcastList withRecipient(Recipient recipient) {
    final phone = normalizePhone(recipient.phone);
    if (recipients.any((r) => normalizePhone(r.phone) == phone)) return this;
    return copyWith(recipients: [...recipients, recipient]);
  }

  /// Retire la personne dont le numéro est exactement [phone].
  BroadcastList withoutRecipient(String phone) => copyWith(
    recipients: [
      for (final r in recipients)
        if (r.phone != phone) r,
    ],
  );
}
```

`lib/features/photo_sharing/domain/entities/send_report.dart` :

```dart
import 'package:freezed_annotation/freezed_annotation.dart';

part 'send_report.freezed.dart';

/// Bilan d'un envoi : une feuille Messages par personne.
@freezed
abstract class SendReport with _$SendReport {
  const SendReport._();

  const factory SendReport({
    required int sent,
    required int cancelled,
    required int failed,
  }) = _SendReport;

  /// Au moins un message est parti.
  bool get anySent => sent > 0;
}
```

`lib/features/photo_sharing/domain/entities/photo_source.dart` :

```dart
/// Origine des photos d'un envoi.
enum PhotoSource { camera, gallery }
```

Run: `dart run build_runner build -d`.

- [ ] **Step 3 :** `flutter test test/features/photo_sharing/domain/broadcast_list_test.dart` — Expected : PASS.

- [ ] **Step 4 : commit**

```bash
dart format lib test && dart analyze
git add lib/features/photo_sharing/domain test/features/photo_sharing/domain/broadcast_list_test.dart
git commit -m "feat: entités des listes de diffusion de photos"
```

---

### Task 3 : planification du rappel quotidien

**Files:**
- Create: `lib/features/photo_sharing/domain/use_cases/photo_reminder_schedule.dart`
- Test: `test/features/photo_sharing/domain/photo_reminder_schedule_test.dart`

- [ ] **Step 1 : test rouge**

```dart
import 'dart:math';

import 'package:colette/features/photo_sharing/domain/use_cases/photo_reminder_schedule.dart';
import 'package:flutter_test/flutter_test.dart';

/// Tire toujours la même minute dans la plage.
class _FixedMinute implements Random {
  const _FixedMinute(this.minute);

  final int minute;

  @override
  int nextInt(int max) => minute;

  @override
  double nextDouble() => 0;

  @override
  bool nextBool() => false;
}

void main() {
  final morning = DateTime(2026, 9, 30, 7);

  test('14 dates, une par jour, dans [8:00, 21:00[', () {
    final dates = planPhotoReminders(now: morning, lastSentAt: null);
    expect(dates, hasLength(photoReminderDays));
    for (var i = 0; i < dates.length; i++) {
      final day = DateTime(2026, 9, 30 + i);
      expect(DateTime(dates[i].year, dates[i].month, dates[i].day), day);
      expect(dates[i].hour, inInclusiveRange(8, 20));
    }
    expect(dates.last.month, 10);
    expect(dates.last.day, 13);
  });

  test('même jour → même heure, quelle que soit l\'heure du calcul', () {
    final early = planPhotoReminders(now: morning, lastSentAt: null);
    final later = planPhotoReminders(
      now: DateTime(2026, 9, 30, 7, 45),
      lastSentAt: null,
    );
    expect(later, early);
  });

  test('envoi fait aujourd\'hui : le jour courant est retiré', () {
    final dates = planPhotoReminders(
      now: morning,
      lastSentAt: DateTime(2026, 9, 30, 6, 30),
    );
    expect(dates, hasLength(photoReminderDays - 1));
    expect(dates.first.day, 1);
    expect(dates.first.month, 10);
  });

  test('envoi fait hier : le jour courant reste', () {
    final dates = planPhotoReminders(
      now: morning,
      lastSentAt: DateTime(2026, 9, 29, 20),
    );
    expect(dates.first.day, 30);
  });

  test('heure du jour déjà passée : retirée', () {
    final dates = planPhotoReminders(
      now: DateTime(2026, 9, 30, 10),
      lastSentAt: null,
      randomForDay: (_) => const _FixedMinute(60),
    );
    expect(dates, hasLength(photoReminderDays - 1));
    expect(dates.first, DateTime(2026, 10, 1, 9));
  });

  test('bornes de la plage', () {
    final first = planPhotoReminders(
      now: morning,
      lastSentAt: null,
      randomForDay: (_) => const _FixedMinute(0),
    ).first;
    final last = planPhotoReminders(
      now: morning,
      lastSentAt: null,
      randomForDay: (_) => const _FixedMinute(12 * 60 + 59),
    ).first;
    expect(first, DateTime(2026, 9, 30, 8));
    expect(last, DateTime(2026, 9, 30, 20, 59));
  });

  test('graine = aaaammjj', () {
    final seeds = <int>[];
    planPhotoReminders(
      now: morning,
      lastSentAt: null,
      randomForDay: (seed) {
        seeds.add(seed);
        return const _FixedMinute(0);
      },
    );
    expect(seeds.take(2), [20260930, 20261001]);
  });
}
```

Run: `flutter test test/features/photo_sharing/domain/photo_reminder_schedule_test.dart` — Expected : FAIL.

- [ ] **Step 2 : implémentation** `lib/features/photo_sharing/domain/use_cases/photo_reminder_schedule.dart` :

```dart
import 'dart:math';

import 'package:colette/core/dates/date_extensions.dart';

/// Première heure possible du rappel photo.
const photoReminderStartHour = 8;

/// Heure de fin (exclue) du rappel photo.
const photoReminderEndHour = 21;

/// Nombre de jours programmés d'avance.
const photoReminderDays = 14;

/// Dates des rappels photo des [photoReminderDays] prochains jours, à une
/// minute tirée dans `[8:00, 21:00[`.
///
/// Le tirage d'un jour ne dépend que du jour (graine `aaaammjj`) : replanifier
/// redonne la même heure. Le jour courant est exclu si [lastSentAt] tombe
/// aujourd'hui ; les dates déjà passées sont exclues.
List<DateTime> planPhotoReminders({
  required DateTime now,
  required DateTime? lastSentAt,
  Random Function(int seed) randomForDay = Random.new,
}) {
  const window = (photoReminderEndHour - photoReminderStartHour) * 60;
  final sentToday = lastSentAt != null && lastSentAt.isSameDay(now);
  final dates = <DateTime>[];
  for (var offset = 0; offset < photoReminderDays; offset++) {
    if (offset == 0 && sentToday) continue;
    final day = DateTime(now.year, now.month, now.day + offset);
    final seed = day.year * 10000 + day.month * 100 + day.day;
    final minute = randomForDay(seed).nextInt(window);
    final at = DateTime(
      day.year,
      day.month,
      day.day,
      photoReminderStartHour,
      minute,
    );
    if (at.isAfter(now)) dates.add(at);
  }
  return dates;
}
```

- [ ] **Step 3 :** relancer le test — Expected : PASS.

- [ ] **Step 4 : commit**

```bash
dart format lib test && dart analyze
git add lib/features/photo_sharing/domain/use_cases/photo_reminder_schedule.dart test/features/photo_sharing/domain/photo_reminder_schedule_test.dart
git commit -m "feat: planification du rappel photo à heure aléatoire"
```

---

### Task 4 : interfaces, DTO et repository local

**Files:**
- Create: `lib/features/photo_sharing/domain/repositories/photo_sharing_repository.dart`
- Create: `lib/features/photo_sharing/domain/repositories/photo_sharing_system.dart`
- Create: `lib/features/photo_sharing/data/dtos/broadcast_list_dto.dart`
- Create: `lib/features/photo_sharing/data/repositories/prefs_photo_sharing_repository.dart`
- Test: `test/features/photo_sharing/data/prefs_photo_sharing_repository_test.dart`

- [ ] **Step 1 : interfaces.**

`photo_sharing_repository.dart` :

```dart
import 'package:colette/core/result/failure.dart';
import 'package:colette/features/photo_sharing/domain/entities/broadcast_list.dart';
import 'package:fpdart/fpdart.dart';

/// Stockage local (propre à cet iPhone) du partage de photos.
abstract interface class PhotoSharingRepository {
  /// Liste vide si rien n'est enregistré.
  Future<Either<Failure, List<BroadcastList>>> loadLists();

  Future<Either<Failure, void>> saveLists(List<BroadcastList> lists);

  /// `null` si aucun envoi n'a réussi.
  Future<Either<Failure, DateTime?>> loadLastSentAt();

  Future<Either<Failure, void>> saveLastSentAt(DateTime sentAt);

  /// Vrai par défaut.
  Future<Either<Failure, bool>> loadReminderEnabled();

  Future<Either<Failure, void>> saveReminderEnabled(bool enabled);
}
```

`photo_sharing_system.dart` :

```dart
import 'package:colette/core/result/failure.dart';
import 'package:colette/features/photo_sharing/domain/entities/recipient.dart';
import 'package:colette/features/photo_sharing/domain/entities/send_report.dart';
import 'package:fpdart/fpdart.dart';

/// Écrans et services iOS du partage de photos. Une annulation par
/// l'utilisateur n'est pas une erreur : `null` ou liste vide.
abstract interface class PhotoSharingSystem {
  /// Sélecteur de contacts ; `null` si annulé.
  Future<Either<Failure, Recipient?>> pickContact();

  /// Appareil photo ; chemins des JPEG préparés (0 ou 1).
  Future<Either<Failure, List<String>>> takePhoto();

  /// Galerie, sélection multiple ; chemins des JPEG préparés (0 à 10).
  Future<Either<Failure, List<String>>> pickPhotos();

  /// Une feuille Messages par numéro, l'une après l'autre.
  Future<Either<Failure, SendReport>> sendMessages({
    required List<String> phones,
    required List<String> photoPaths,
    required String body,
  });

  /// Supprime les JPEG préparés ; échec seulement logué.
  Future<void> discardPhotos(List<String> photoPaths);

  /// Remplace les notifications du rappel photo par [dates] ; échec logué.
  Future<void> syncReminders({
    required List<DateTime> dates,
    required String title,
    required String body,
  });

  /// Route demandée par l'appui sur une notification, effacée à la lecture.
  Future<String?> takePendingRoute();

  /// Émis quand une route vient d'être mémorisée (app déjà lancée).
  Stream<void> get pendingRouteSignals;
}
```

- [ ] **Step 2 : test rouge** `test/features/photo_sharing/data/prefs_photo_sharing_repository_test.dart` :

```dart
import 'package:colette/features/photo_sharing/data/repositories/prefs_photo_sharing_repository.dart';
import 'package:colette/features/photo_sharing/domain/entities/broadcast_list.dart';
import 'package:colette/features/photo_sharing/domain/entities/recipient.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  const lists = [
    BroadcastList(
      id: 'l1',
      name: 'Grands-parents',
      recipients: [
        Recipient(name: 'Mamie', phone: '0612345678'),
        Recipient(name: 'Papi', phone: '+33698765432'),
      ],
    ),
    BroadcastList(id: 'l2', name: 'Amis', recipients: []),
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
}
```

Run: `flutter test test/features/photo_sharing/data/prefs_photo_sharing_repository_test.dart` — Expected : FAIL.

- [ ] **Step 3 : implémentation.**

`lib/features/photo_sharing/data/dtos/broadcast_list_dto.dart` :

```dart
import 'dart:convert';

import 'package:colette/features/photo_sharing/domain/entities/broadcast_list.dart';
import 'package:colette/features/photo_sharing/domain/entities/recipient.dart';

/// Conversion des listes de diffusion ↔ JSON local.
abstract final class BroadcastListDto {
  static String encode(List<BroadcastList> lists) => jsonEncode([
    for (final list in lists)
      {
        'id': list.id,
        'name': list.name,
        'recipients': [
          for (final r in list.recipients) {'name': r.name, 'phone': r.phone},
        ],
      },
  ]);

  /// Lève une exception si [raw] est illisible (convertie par `guard()`).
  static List<BroadcastList> decode(String raw) => [
    for (final item in jsonDecode(raw) as List<dynamic>)
      _list(item as Map<String, dynamic>),
  ];

  static BroadcastList _list(Map<String, dynamic> map) => BroadcastList(
    id: map['id'] as String,
    name: map['name'] as String,
    recipients: [
      for (final r in map['recipients'] as List<dynamic>)
        _recipient(r as Map<String, dynamic>),
    ],
  );

  static Recipient _recipient(Map<String, dynamic> map) =>
      Recipient(name: map['name'] as String, phone: map['phone'] as String);
}
```

`lib/features/photo_sharing/data/repositories/prefs_photo_sharing_repository.dart` :

```dart
import 'package:colette/core/result/failure.dart';
import 'package:colette/core/result/failure_mapper.dart';
import 'package:colette/features/photo_sharing/data/dtos/broadcast_list_dto.dart';
import 'package:colette/features/photo_sharing/domain/entities/broadcast_list.dart';
import 'package:colette/features/photo_sharing/domain/repositories/photo_sharing_repository.dart';
import 'package:fpdart/fpdart.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Partage de photos dans `shared_preferences`.
class PrefsPhotoSharingRepository implements PhotoSharingRepository {
  PrefsPhotoSharingRepository(this._prefs);

  static const listsKey = 'photo_sharing.lists';
  static const lastSentAtKey = 'photo_sharing.last_sent_at';
  static const reminderEnabledKey = 'photo_sharing.reminder_enabled';

  final SharedPreferences _prefs;

  @override
  Future<Either<Failure, List<BroadcastList>>> loadLists() => guard(() async {
    final raw = _prefs.getString(listsKey);
    return raw == null ? const <BroadcastList>[] : BroadcastListDto.decode(raw);
  });

  @override
  Future<Either<Failure, void>> saveLists(List<BroadcastList> lists) =>
      guard(() => _prefs.setString(listsKey, BroadcastListDto.encode(lists)));

  @override
  Future<Either<Failure, DateTime?>> loadLastSentAt() => guard(() async {
    final ms = _prefs.getInt(lastSentAtKey);
    return ms == null ? null : DateTime.fromMillisecondsSinceEpoch(ms);
  });

  @override
  Future<Either<Failure, void>> saveLastSentAt(DateTime sentAt) => guard(
    () => _prefs.setInt(lastSentAtKey, sentAt.millisecondsSinceEpoch),
  );

  @override
  Future<Either<Failure, bool>> loadReminderEnabled() =>
      guard(() async => _prefs.getBool(reminderEnabledKey) ?? true);

  @override
  Future<Either<Failure, void>> saveReminderEnabled(bool enabled) =>
      guard(() => _prefs.setBool(reminderEnabledKey, enabled));
}
```

- [ ] **Step 4 :** relancer le test — Expected : PASS.

- [ ] **Step 5 : commit**

```bash
dart format lib test && dart analyze
git add lib/features/photo_sharing/domain/repositories lib/features/photo_sharing/data/dtos lib/features/photo_sharing/data/repositories test/features/photo_sharing/data/prefs_photo_sharing_repository_test.dart
git commit -m "feat: stockage local des listes de diffusion et du rappel photo"
```

---

### Task 5 : pont natif côté Dart

**Files:**
- Create: `lib/features/photo_sharing/data/native_photo_sharing_system.dart`
- Test: `test/features/photo_sharing/data/native_photo_sharing_system_test.dart`

- [ ] **Step 1 : test rouge**

```dart
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
    mock((call) => call.method == 'pickPhotos' ? ['/tmp/a.jpg', '/tmp/b.jpg'] : <String>[]);
    expect((await system.pickPhotos()).toNullable(), ['/tmp/a.jpg', '/tmp/b.jpg']);
    expect((await system.takePhoto()).toNullable(), isEmpty);
  });

  test('sendMessages : arguments et bilan', () async {
    mock((_) => {'sent': 2, 'cancelled': 1, 'failed': 0});
    final result = await system.sendMessages(
      phones: ['0611', '0622', '0633'],
      photoPaths: ['/tmp/a.jpg'],
      body: 'Coucou',
    );
    expect(result.toNullable(), const SendReport(sent: 2, cancelled: 1, failed: 0));
    expect(calls.single.arguments, {
      'phones': ['0611', '0622', '0633'],
      'photoPaths': ['/tmp/a.jpg'],
      'body': 'Coucou',
    });
  });

  test('code natif connu → PhotoSharingFailure', () async {
    mock((_) => throw PlatformException(code: 'messagesUnavailable'));
    final result = await system.sendMessages(phones: ['0611'], photoPaths: [], body: '');
    expect(
      result.getLeft().toNullable(),
      const PhotoSharingFailure(PhotoSharingReason.messagesUnavailable),
    );
  });

  test('code inconnu → UnknownFailure', () async {
    mock((_) => throw PlatformException(code: 'boom'));
    expect((await system.pickPhotos()).getLeft().toNullable(), isA<UnknownFailure>());
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

  test('takePendingRoute rend la route', () async {
    mock((_) => '/today/photos');
    expect(await system.takePendingRoute(), '/today/photos');
  });

  test('routePending venu de Swift → signal', () async {
    final signal = system.pendingRouteSignals.first;
    await messenger.handlePlatformMessage(
      NativePhotoSharingSystem.channelName,
      const StandardMethodCodec().encodeMethodCall(const MethodCall('routePending')),
      (_) {},
    );
    await expectLater(signal, completes);
  });
}
```

Run: `flutter test test/features/photo_sharing/data/native_photo_sharing_system_test.dart` — Expected : FAIL.

- [ ] **Step 2 : implémentation** `lib/features/photo_sharing/data/native_photo_sharing_system.dart` :

```dart
import 'dart:async';
import 'dart:developer' as developer;

import 'package:colette/core/result/failure.dart';
import 'package:colette/features/photo_sharing/domain/entities/recipient.dart';
import 'package:colette/features/photo_sharing/domain/entities/send_report.dart';
import 'package:colette/features/photo_sharing/domain/repositories/photo_sharing_system.dart';
import 'package:flutter/services.dart';
import 'package:fpdart/fpdart.dart';

const _reasons = {
  'messagesUnavailable': PhotoSharingReason.messagesUnavailable,
  'cameraUnavailable': PhotoSharingReason.cameraUnavailable,
  'busy': PhotoSharingReason.busy,
  'io': PhotoSharingReason.io,
};

/// Pont Swift `colette/photo-sharing` (voir `PhotoSharingPlugin.swift`).
class NativePhotoSharingSystem implements PhotoSharingSystem {
  NativePhotoSharingSystem(this._channel) {
    _channel.setMethodCallHandler(_onNativeCall);
  }

  /// Nom du canal, partagé avec `PhotoSharingPlugin.swift`.
  static const channelName = 'colette/photo-sharing';

  final MethodChannel _channel;
  final _routeSignals = StreamController<void>.broadcast();

  Future<Object?> _onNativeCall(MethodCall call) async {
    if (call.method == 'routePending') _routeSignals.add(null);
    return null;
  }

  @override
  Stream<void> get pendingRouteSignals => _routeSignals.stream;

  @override
  Future<Either<Failure, Recipient?>> pickContact() => _call(() async {
    final map = await _channel.invokeMapMethod<String, Object?>('pickContact');
    if (map == null) return null;
    return Recipient(
      name: map['name']! as String,
      phone: map['phone']! as String,
    );
  });

  @override
  Future<Either<Failure, List<String>>> takePhoto() => _paths('takePhoto');

  @override
  Future<Either<Failure, List<String>>> pickPhotos() => _paths('pickPhotos');

  @override
  Future<Either<Failure, SendReport>> sendMessages({
    required List<String> phones,
    required List<String> photoPaths,
    required String body,
  }) => _call(() async {
    final map = await _channel.invokeMapMethod<String, Object?>(
      'sendMessages',
      {'phones': phones, 'photoPaths': photoPaths, 'body': body},
    );
    return SendReport(
      sent: map!['sent']! as int,
      cancelled: map['cancelled']! as int,
      failed: map['failed']! as int,
    );
  });

  @override
  Future<void> discardPhotos(List<String> photoPaths) =>
      _quiet('discardPhotos', {'photoPaths': photoPaths});

  @override
  Future<void> syncReminders({
    required List<DateTime> dates,
    required String title,
    required String body,
  }) => _quiet('syncReminders', {
    'dates': [for (final date in dates) date.millisecondsSinceEpoch],
    'title': title,
    'body': body,
  });

  @override
  Future<String?> takePendingRoute() async {
    try {
      return await _channel.invokeMethod<String>('takePendingRoute');
    } on Exception catch (error, stackTrace) {
      _log('takePendingRoute', error, stackTrace);
      return null;
    }
  }

  Future<Either<Failure, List<String>>> _paths(String method) => _call(
    () async => await _channel.invokeListMethod<String>(method) ?? const [],
  );

  /// Appel dont l'échec est seulement logué.
  Future<void> _quiet(String method, Object? arguments) async {
    try {
      await _channel.invokeMethod<void>(method, arguments);
    } on Exception catch (error, stackTrace) {
      _log(method, error, stackTrace);
    }
  }

  /// Codes du canal → [PhotoSharingFailure], sinon [UnknownFailure] logué.
  Future<Either<Failure, T>> _call<T>(Future<T> Function() action) async {
    try {
      return right(await action());
    } catch (error, stackTrace) {
      if (error is PlatformException) {
        final reason = _reasons[error.code];
        if (reason != null) return left(PhotoSharingFailure(reason));
      }
      _log('appel natif', error, stackTrace);
      return left(UnknownFailure(error, stackTrace));
    }
  }

  void _log(String what, Object error, StackTrace stackTrace) =>
      developer.log(
        'colette/photo-sharing $what a échoué',
        name: 'colette',
        error: error,
        stackTrace: stackTrace,
      );
}
```

- [ ] **Step 3 :** relancer le test — Expected : PASS.

- [ ] **Step 4 : commit**

```bash
dart format lib test && dart analyze
git add lib/features/photo_sharing/data/native_photo_sharing_system.dart test/features/photo_sharing/data/native_photo_sharing_system_test.dart
git commit -m "feat: pont Dart du partage de photos"
```

---

### Task 6 : pont Swift, notifications et AppDelegate

**Files:**
- Create: `ios/Runner/PhotoSharing/PhotoSharingError.swift`, `PhotoSharingImages.swift`, `PhotoSharingReminders.swift`, `PhotoSharingPresenter.swift`, `PhotoSharingPlugin.swift`
- Create: `ios/scripts/add_photo_sharing_sources.rb`
- Modify: `ios/Runner/AppDelegate.swift`, `ios/Runner/Info.plist`, `ios/Runner.xcodeproj/project.pbxproj` (via le script)

Pas de test automatisé côté Swift (comme Documents et BottleTimer) : la vérification est la compilation, puis le simulateur (Task 13).

- [ ] **Step 1 : `PhotoSharingError.swift`**

```swift
import Flutter

/// Erreurs du pont de partage de photos, mappées sur les codes attendus par Flutter.
enum PhotoSharingError: Error {
  case messagesUnavailable
  case cameraUnavailable
  case busy
  case io(String)

  var flutterError: FlutterError {
    switch self {
    case .messagesUnavailable:
      return FlutterError(code: "messagesUnavailable", message: nil, details: nil)
    case .cameraUnavailable:
      return FlutterError(code: "cameraUnavailable", message: nil, details: nil)
    case .busy:
      return FlutterError(code: "busy", message: nil, details: nil)
    case .io(let message):
      return FlutterError(code: "io", message: message, details: nil)
    }
  }
}
```

- [ ] **Step 2 : `PhotoSharingImages.swift`**

```swift
import UIKit

/// Photos préparées pour Messages : JPEG réduits dans `tmp/photo-sharing/`.
enum PhotoSharingImages {
  private static let maxDimension: CGFloat = 2048
  private static let quality: CGFloat = 0.8

  static var directory: URL {
    FileManager.default.temporaryDirectory
      .appendingPathComponent("photo-sharing", isDirectory: true)
  }

  /// Réduit l'image (grand côté ≤ 2048 px), l'écrit en JPEG et renvoie son chemin.
  static func write(_ image: UIImage) throws -> String {
    try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
    guard let data = resized(image).jpegData(compressionQuality: quality) else {
      throw PhotoSharingError.io("Encodage JPEG impossible")
    }
    let url = directory.appendingPathComponent(UUID().uuidString).appendingPathExtension("jpg")
    try data.write(to: url, options: .atomic)
    return url.path
  }

  /// Supprime les fichiers donnés, uniquement s'ils sont dans le dossier des photos.
  static func discard(_ paths: [String]) {
    for path in paths where path.hasPrefix(directory.path) {
      try? FileManager.default.removeItem(atPath: path)
    }
  }

  /// Vide le dossier (au lancement : restes d'un envoi interrompu).
  static func discardAll() {
    try? FileManager.default.removeItem(at: directory)
  }

  /// Dessin à l'échelle 1 : l'orientation EXIF est appliquée par `draw(in:)`.
  private static func resized(_ image: UIImage) -> UIImage {
    let pixels = CGSize(
      width: image.size.width * image.scale, height: image.size.height * image.scale)
    let ratio = min(1, maxDimension / max(pixels.width, pixels.height))
    let target = CGSize(
      width: (pixels.width * ratio).rounded(), height: (pixels.height * ratio).rounded())
    let format = UIGraphicsImageRendererFormat.default()
    format.scale = 1
    return UIGraphicsImageRenderer(size: target, format: format).image { _ in
      image.draw(in: CGRect(origin: .zero, size: target))
    }
  }
}
```

- [ ] **Step 3 : `PhotoSharingReminders.swift`**

```swift
import UserNotifications
import os.log

/// Notifications du rappel photo, une par jour, identifiant `photo-reminder.AAAA-MM-JJ`.
enum PhotoSharingReminders {
  static let prefix = "photo-reminder."

  /// Retire les rappels de la veille à J+15 (retrait synchrone, donc ordonné),
  /// puis programme une notification non répétée par date.
  static func sync(dates: [Date], title: String, body: String) {
    let center = UNUserNotificationCenter.current()
    let calendar = Calendar.current
    let today = calendar.startOfDay(for: Date())
    let stale = (-1...15)
      .compactMap { calendar.date(byAdding: .day, value: $0, to: today) }
      .map(identifier)
    center.removePendingNotificationRequests(withIdentifiers: stale)
    for date in dates {
      let content = UNMutableNotificationContent()
      content.title = title
      content.body = body
      content.sound = .default
      let components = calendar.dateComponents(
        [.year, .month, .day, .hour, .minute], from: date)
      let trigger = UNCalendarNotificationTrigger(dateMatching: components, repeats: false)
      let request = UNNotificationRequest(
        identifier: identifier(date), content: content, trigger: trigger)
      center.add(request) { error in
        guard let error else { return }
        os_log(
          "Rappel photo non programmé : %{public}@", type: .error, error.localizedDescription)
      }
    }
  }

  static func identifier(_ date: Date) -> String {
    let day = Calendar.current.dateComponents([.year, .month, .day], from: date)
    return prefix
      + String(format: "%04d-%02d-%02d", day.year ?? 0, day.month ?? 0, day.day ?? 0)
  }
}
```

- [ ] **Step 4 : `PhotoSharingPresenter.swift`**

```swift
import ContactsUI
import MessageUI
import PhotosUI
import UIKit

/// Présente les écrans système du partage de photos : contacts, appareil photo,
/// galerie, feuilles Messages successives. Thread principal uniquement.
final class PhotoSharingPresenter: NSObject {
  private struct Tally {
    var sent = 0
    var cancelled = 0
    var failed = 0
  }

  private var contactCompletion: ((Result<[String: String]?, PhotoSharingError>) -> Void)?
  private var imagesCompletion: ((Result<[String], PhotoSharingError>) -> Void)?
  private var messagesCompletion: ((Result<[String: Int], PhotoSharingError>) -> Void)?
  private var pendingPhones: [String] = []
  private var attachments: [Data] = []
  private var messageBody = ""
  private var tally = Tally()

  /// Contrôleur au sommet de la scène active, seul capable de présenter un écran système.
  private var host: UIViewController? {
    let scenes = UIApplication.shared.connectedScenes.compactMap { $0 as? UIWindowScene }
    let window =
      scenes.first { $0.activationState == .foregroundActive }?.keyWindow
      ?? scenes.compactMap(\.keyWindow).first
    var controller = window?.rootViewController
    while let presented = controller?.presentedViewController { controller = presented }
    return controller
  }

  // MARK: - Contacts

  /// Sélecteur de contacts ; un contact à plusieurs numéros fait choisir le numéro.
  func pickContact(completion: @escaping (Result<[String: String]?, PhotoSharingError>) -> Void) {
    guard let host else {
      completion(.failure(.io("Aucune fenêtre")))
      return
    }
    contactCompletion = completion
    let picker = CNContactPickerViewController()
    picker.delegate = self
    picker.displayedPropertyKeys = [CNContactPhoneNumbersKey]
    picker.predicateForEnablingContact = NSPredicate(format: "phoneNumbers.@count > 0")
    picker.predicateForSelectionOfContact = NSPredicate(format: "phoneNumbers.@count == 1")
    picker.predicateForSelectionOfProperty = NSPredicate(
      format: "key == %@", CNContactPhoneNumbersKey)
    host.present(picker, animated: true)
  }

  private func finishContact(_ contact: CNContact, phone: String?) {
    let completion = contactCompletion
    contactCompletion = nil
    guard let phone, !phone.isEmpty else {
      completion?(.success(nil))
      return
    }
    let name = CNContactFormatter.string(from: contact, style: .fullName) ?? ""
    completion?(.success(["name": name.isEmpty ? phone : name, "phone": phone]))
  }

  // MARK: - Photos

  func takePhoto(completion: @escaping (Result<[String], PhotoSharingError>) -> Void) {
    guard UIImagePickerController.isSourceTypeAvailable(.camera) else {
      completion(.failure(.cameraUnavailable))
      return
    }
    guard let host else {
      completion(.failure(.io("Aucune fenêtre")))
      return
    }
    imagesCompletion = completion
    let picker = UIImagePickerController()
    picker.sourceType = .camera
    picker.delegate = self
    host.present(picker, animated: true)
  }

  func pickPhotos(completion: @escaping (Result<[String], PhotoSharingError>) -> Void) {
    guard let host else {
      completion(.failure(.io("Aucune fenêtre")))
      return
    }
    imagesCompletion = completion
    var configuration = PHPickerConfiguration()
    configuration.filter = .images
    configuration.selectionLimit = 10
    let picker = PHPickerViewController(configuration: configuration)
    picker.delegate = self
    host.present(picker, animated: true)
  }

  /// Encode hors du thread principal, répond sur le thread principal.
  private func write(_ images: [UIImage]) {
    DispatchQueue.global(qos: .userInitiated).async { [weak self] in
      let outcome: Result<[String], PhotoSharingError>
      do {
        outcome = .success(try images.map(PhotoSharingImages.write))
      } catch let error as PhotoSharingError {
        outcome = .failure(error)
      } catch {
        outcome = .failure(.io(error.localizedDescription))
      }
      DispatchQueue.main.async { self?.finishImages(outcome) }
    }
  }

  private func finishImages(_ outcome: Result<[String], PhotoSharingError>) {
    let completion = imagesCompletion
    imagesCompletion = nil
    completion?(outcome)
  }

  // MARK: - Messages

  /// Une feuille Messages par numéro, la suivante après la fermeture de la précédente.
  func sendMessages(
    phones: [String], photoPaths: [String], body: String,
    completion: @escaping (Result<[String: Int], PhotoSharingError>) -> Void
  ) {
    guard MFMessageComposeViewController.canSendText() else {
      completion(.failure(.messagesUnavailable))
      return
    }
    do {
      attachments = try photoPaths.map { try Data(contentsOf: URL(fileURLWithPath: $0)) }
    } catch {
      completion(.failure(.io(error.localizedDescription)))
      return
    }
    pendingPhones = phones
    messageBody = body
    tally = Tally()
    messagesCompletion = completion
    presentNextMessage()
  }

  private func presentNextMessage() {
    guard !pendingPhones.isEmpty else {
      finishMessages()
      return
    }
    guard let host else {
      tally.failed += pendingPhones.count
      pendingPhones = []
      finishMessages()
      return
    }
    let composer = MFMessageComposeViewController()
    composer.messageComposeDelegate = self
    composer.recipients = [pendingPhones.removeFirst()]
    composer.body = messageBody.isEmpty ? nil : messageBody
    if MFMessageComposeViewController.canSendAttachments() {
      for (index, data) in attachments.enumerated() {
        _ = composer.addAttachmentData(
          data, typeIdentifier: "public.jpeg", filename: "photo-\(index + 1).jpg")
      }
    }
    host.present(composer, animated: true)
  }

  private func finishMessages() {
    let completion = messagesCompletion
    messagesCompletion = nil
    attachments = []
    completion?(
      .success(["sent": tally.sent, "cancelled": tally.cancelled, "failed": tally.failed]))
  }
}

extension PhotoSharingPresenter: CNContactPickerDelegate {
  func contactPicker(_ picker: CNContactPickerViewController, didSelect contact: CNContact) {
    finishContact(contact, phone: contact.phoneNumbers.first?.value.stringValue)
  }

  func contactPicker(
    _ picker: CNContactPickerViewController, didSelect contactProperty: CNContactProperty
  ) {
    finishContact(
      contactProperty.contact, phone: (contactProperty.value as? CNPhoneNumber)?.stringValue)
  }

  func contactPickerDidCancel(_ picker: CNContactPickerViewController) {
    let completion = contactCompletion
    contactCompletion = nil
    completion?(.success(nil))
  }
}

extension PhotoSharingPresenter: UIImagePickerControllerDelegate, UINavigationControllerDelegate {
  func imagePickerController(
    _ picker: UIImagePickerController,
    didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey: Any]
  ) {
    let image = info[.originalImage] as? UIImage
    picker.dismiss(animated: true) { [weak self] in
      guard let image else {
        self?.finishImages(.success([]))
        return
      }
      self?.write([image])
    }
  }

  func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
    picker.dismiss(animated: true) { [weak self] in self?.finishImages(.success([])) }
  }
}

extension PhotoSharingPresenter: PHPickerViewControllerDelegate {
  func picker(_ picker: PHPickerViewController, didFinishPicking results: [PHPickerResult]) {
    picker.dismiss(animated: true)
    guard !results.isEmpty else {
      finishImages(.success([]))
      return
    }
    // Ordre de sélection conservé ; chaque chargement répond sur le thread principal.
    var images = [UIImage?](repeating: nil, count: results.count)
    let group = DispatchGroup()
    for (index, result) in results.enumerated()
    where result.itemProvider.canLoadObject(ofClass: UIImage.self) {
      group.enter()
      result.itemProvider.loadObject(ofClass: UIImage.self) { object, _ in
        DispatchQueue.main.async {
          images[index] = object as? UIImage
          group.leave()
        }
      }
    }
    group.notify(queue: .main) { [weak self] in self?.write(images.compactMap { $0 }) }
  }
}

extension PhotoSharingPresenter: MFMessageComposeViewControllerDelegate {
  func messageComposeViewController(
    _ controller: MFMessageComposeViewController, didFinishWith result: MessageComposeResult
  ) {
    switch result {
    case .sent: tally.sent += 1
    case .cancelled: tally.cancelled += 1
    default: tally.failed += 1
    }
    controller.dismiss(animated: true) { [weak self] in self?.presentNextMessage() }
  }
}
```

- [ ] **Step 5 : `PhotoSharingPlugin.swift`**

```swift
import Flutter
import UIKit
import os.log

/// Canal `colette/photo-sharing` : contacts, photos, feuilles Messages et
/// notifications quotidiennes du rappel photo.
final class PhotoSharingPlugin: NSObject {
  static let channelName = "colette/photo-sharing"
  static let photosRoute = "/today/photos"

  /// Instance enregistrée, pour signaler à Flutter l'appui sur une notification.
  private static var shared: PhotoSharingPlugin?

  /// Route demandée par une notification, en attente de lecture par Flutter.
  /// Statique : l'appui peut arriver avant l'enregistrement du canal.
  private static var pendingRoute: String?

  private let channel: FlutterMethodChannel
  private let presenter = PhotoSharingPresenter()

  /// Une seule présentation d'écran système à la fois. Thread principal uniquement.
  private var busy = false

  private init(channel: FlutterMethodChannel) {
    self.channel = channel
  }

  static func register(with registry: FlutterPluginRegistry) {
    guard let messenger = registry.registrar(forPlugin: "PhotoSharingPlugin")?.messenger() else {
      os_log("PhotoSharingPlugin : registrar indisponible, canal non enregistré", type: .error)
      return
    }
    let channel = FlutterMethodChannel(name: channelName, binaryMessenger: messenger)
    let plugin = PhotoSharingPlugin(channel: channel)
    channel.setMethodCallHandler { call, result in plugin.handle(call, result: result) }
    shared = plugin
    PhotoSharingImages.discardAll()
  }

  /// Appui sur une notification du rappel photo (depuis l'AppDelegate).
  static func notificationOpened() {
    pendingRoute = photosRoute
    shared?.channel.invokeMethod("routePending", arguments: nil)
  }

  private func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
    let args = call.arguments as? [String: Any] ?? [:]
    switch call.method {
    case "pickContact", "takePhoto", "pickPhotos", "sendMessages":
      exclusive(call.method, args: args, result: result)
    case "discardPhotos":
      PhotoSharingImages.discard(args["photoPaths"] as? [String] ?? [])
      result(nil)
    case "syncReminders":
      let dates = (args["dates"] as? [NSNumber] ?? []).map {
        Date(timeIntervalSince1970: $0.doubleValue / 1000)
      }
      PhotoSharingReminders.sync(
        dates: dates, title: args["title"] as? String ?? "",
        body: args["body"] as? String ?? "")
      result(nil)
    case "takePendingRoute":
      result(Self.pendingRoute)
      Self.pendingRoute = nil
    default:
      result(FlutterMethodNotImplemented)
    }
  }

  private func exclusive(_ method: String, args: [String: Any], result: @escaping FlutterResult) {
    guard !busy else {
      result(PhotoSharingError.busy.flutterError)
      return
    }
    busy = true
    let reply: FlutterResult = { [weak self] value in
      self?.busy = false
      result(value)
    }
    switch method {
    case "pickContact":
      presenter.pickContact { outcome in
        switch outcome {
        case .success(let contact): reply(contact)
        case .failure(let error): reply(error.flutterError)
        }
      }
    case "takePhoto":
      presenter.takePhoto { reply(Self.value($0)) }
    case "pickPhotos":
      presenter.pickPhotos { reply(Self.value($0)) }
    default:
      presenter.sendMessages(
        phones: args["phones"] as? [String] ?? [],
        photoPaths: args["photoPaths"] as? [String] ?? [],
        body: args["body"] as? String ?? ""
      ) { reply(Self.value($0)) }
    }
  }

  /// Valeur non optionnelle ou erreur du canal.
  private static func value<T>(_ outcome: Result<T, PhotoSharingError>) -> Any {
    switch outcome {
    case .success(let value): return value
    case .failure(let error): return error.flutterError
    }
  }
}
```

- [ ] **Step 6 : AppDelegate.** Dans `ios/Runner/AppDelegate.swift` :

1. Dans `willPresent`, avant le `if` du minuteur :

```swift
    if notification.request.identifier.hasPrefix(PhotoSharingReminders.prefix) {
      completionHandler([.banner, .list, .sound])
      return
    }
```

2. Après `willPresent`, ajouter :

```swift
  /// Appui sur le rappel photo : la page Photos s'ouvre (voir `PhotoSharingPlugin`).
  override func userNotificationCenter(
    _ center: UNUserNotificationCenter,
    didReceive response: UNNotificationResponse,
    withCompletionHandler completionHandler: @escaping () -> Void
  ) {
    if response.notification.request.identifier.hasPrefix(PhotoSharingReminders.prefix) {
      PhotoSharingPlugin.notificationOpened()
      completionHandler()
      return
    }
    super.userNotificationCenter(
      center, didReceive: response, withCompletionHandler: completionHandler)
  }
```

3. Dans `didInitializeImplicitFlutterEngine`, après `BottleTimerChannel.register(...)` :

```swift
    PhotoSharingPlugin.register(with: engineBridge.pluginRegistry)
```

Si la compilation signale que `didReceive` n'existe pas dans `FlutterAppDelegate` (pas d'`override` possible), retirer `override` et remplacer l'appel à `super` par `completionHandler()` ; noter le constat dans le rapport de tâche.

- [ ] **Step 7 : Info.plist.** Remplacer la valeur de `NSCameraUsageDescription` par :

```xml
	<string>Colette utilise l'appareil photo pour scanner vos documents et photographier votre bébé.</string>
```

Aucune autre clé : `CNContactPickerViewController` et `PHPickerViewController` ne demandent pas d'autorisation.

- [ ] **Step 8 : script Xcode** `ios/scripts/add_photo_sharing_sources.rb` :

```ruby
#!/usr/bin/env ruby
# Ajoute les sources Swift de ios/Runner/PhotoSharing à la cible Runner (idempotent).
require 'xcodeproj'

project_path = File.expand_path('../Runner.xcodeproj', __dir__)
project = Xcodeproj::Project.open(project_path)
target = project.targets.find { |t| t.name == 'Runner' }
raise 'cible Runner introuvable' if target.nil?

runner_group = project.main_group['Runner']
raise 'groupe Runner introuvable' if runner_group.nil?

group = runner_group['PhotoSharing'] || runner_group.new_group('PhotoSharing', 'PhotoSharing')

Dir[File.expand_path('../Runner/PhotoSharing/*.swift', __dir__)].sort.each do |file|
  name = File.basename(file)
  next if target.source_build_phase.files_references.any? { |r| r.path == name }
  ref = group.files.find { |f| f.path == name } || group.new_file(name)
  target.add_file_references([ref])
  puts "ajouté : #{name}"
end

project.save
```

Run: `ruby ios/scripts/add_photo_sharing_sources.rb` — Expected : 5 lignes « ajouté : … ». Relancer : aucune ligne (idempotent).

- [ ] **Step 9 : compilation**

Run: `flutter build ios --simulator --debug` — Expected : `✓ Built build/ios/iphonesimulator/Runner.app`.

- [ ] **Step 10 : commit**

```bash
git add ios/Runner/PhotoSharing ios/scripts/add_photo_sharing_sources.rb ios/Runner/AppDelegate.swift ios/Runner/Info.plist ios/Runner.xcodeproj/project.pbxproj
git commit -m "feat: pont Swift du partage de photos et notifications du rappel"
```

Vérifier avec `git diff --cached --stat ios/Runner.xcodeproj/project.pbxproj` avant le commit que seules les références `PhotoSharing` sont ajoutées.

---

### Task 7 : providers d'état et helpers de test

**Files:**
- Create: `lib/features/photo_sharing/presentation/providers/photo_sharing_providers.dart`
- Create: `lib/features/photo_sharing/presentation/providers/broadcast_lists.dart`
- Create: `lib/features/photo_sharing/presentation/providers/photo_reminder.dart`
- Create: `test/helpers/fake_photo_sharing_system.dart`, `test/helpers/in_memory_photo_sharing_repository.dart`
- Modify: `test/helpers/pump_app.dart`, `test/helpers/colette_app_overrides.dart`
- Test: `test/features/photo_sharing/presentation/broadcast_lists_test.dart`, `test/features/photo_sharing/presentation/photo_reminder_test.dart`

- [ ] **Step 1 : helpers de test.**

`test/helpers/fake_photo_sharing_system.dart` :

```dart
import 'dart:async';

import 'package:colette/core/result/failure.dart';
import 'package:colette/features/photo_sharing/domain/entities/recipient.dart';
import 'package:colette/features/photo_sharing/domain/entities/send_report.dart';
import 'package:colette/features/photo_sharing/domain/repositories/photo_sharing_system.dart';
import 'package:fpdart/fpdart.dart';

/// Pont natif simulé : réponses réglables, appels enregistrés.
class FakePhotoSharingSystem implements PhotoSharingSystem {
  FakePhotoSharingSystem({this.pendingRoute});

  Recipient? contact;
  List<String> photos = const [];
  Failure? photosFailure;
  SendReport report = const SendReport(sent: 0, cancelled: 0, failed: 0);
  Failure? sendFailure;
  String? pendingRoute;

  final signals = StreamController<void>.broadcast();
  final sendCalls = <({List<String> phones, List<String> photoPaths, String body})>[];
  final discarded = <String>[];
  final syncedDates = <List<DateTime>>[];
  String? lastTitle;
  String? lastBody;

  @override
  Future<Either<Failure, Recipient?>> pickContact() async => right(contact);

  @override
  Future<Either<Failure, List<String>>> takePhoto() async =>
      photosFailure == null ? right(photos) : left(photosFailure!);

  @override
  Future<Either<Failure, List<String>>> pickPhotos() async =>
      photosFailure == null ? right(photos) : left(photosFailure!);

  @override
  Future<Either<Failure, SendReport>> sendMessages({
    required List<String> phones,
    required List<String> photoPaths,
    required String body,
  }) async {
    sendCalls.add((phones: phones, photoPaths: photoPaths, body: body));
    return sendFailure == null ? right(report) : left(sendFailure!);
  }

  @override
  Future<void> discardPhotos(List<String> photoPaths) async =>
      discarded.addAll(photoPaths);

  @override
  Future<void> syncReminders({
    required List<DateTime> dates,
    required String title,
    required String body,
  }) async {
    syncedDates.add(dates);
    lastTitle = title;
    lastBody = body;
  }

  @override
  Future<String?> takePendingRoute() async {
    final route = pendingRoute;
    pendingRoute = null;
    return route;
  }

  @override
  Stream<void> get pendingRouteSignals => signals.stream;
}
```

`test/helpers/in_memory_photo_sharing_repository.dart` :

```dart
import 'package:colette/core/result/failure.dart';
import 'package:colette/features/photo_sharing/domain/entities/broadcast_list.dart';
import 'package:colette/features/photo_sharing/domain/repositories/photo_sharing_repository.dart';
import 'package:fpdart/fpdart.dart';

/// Stockage en mémoire ; [failSaves] fait échouer toutes les écritures.
class InMemoryPhotoSharingRepository implements PhotoSharingRepository {
  InMemoryPhotoSharingRepository({
    this.lists = const [],
    this.lastSentAt,
    this.reminderEnabled = true,
  });

  List<BroadcastList> lists;
  DateTime? lastSentAt;
  bool reminderEnabled;
  bool failSaves = false;

  Future<Either<Failure, void>> _write(void Function() apply) async {
    if (failSaves) return left(const UnknownFailure('écriture refusée'));
    apply();
    return right(null);
  }

  @override
  Future<Either<Failure, List<BroadcastList>>> loadLists() async => right(lists);

  @override
  Future<Either<Failure, void>> saveLists(List<BroadcastList> lists) =>
      _write(() => this.lists = lists);

  @override
  Future<Either<Failure, DateTime?>> loadLastSentAt() async => right(lastSentAt);

  @override
  Future<Either<Failure, void>> saveLastSentAt(DateTime sentAt) =>
      _write(() => lastSentAt = sentAt);

  @override
  Future<Either<Failure, bool>> loadReminderEnabled() async =>
      right(reminderEnabled);

  @override
  Future<Either<Failure, void>> saveReminderEnabled(bool enabled) =>
      _write(() => reminderEnabled = enabled);
}
```

- [ ] **Step 2 : providers de base** `photo_sharing_providers.dart` :

```dart
import 'package:colette/core/firebase/firebase_providers.dart';
import 'package:colette/features/photo_sharing/data/native_photo_sharing_system.dart';
import 'package:colette/features/photo_sharing/data/repositories/prefs_photo_sharing_repository.dart';
import 'package:colette/features/photo_sharing/domain/repositories/photo_sharing_repository.dart';
import 'package:colette/features/photo_sharing/domain/repositories/photo_sharing_system.dart';
import 'package:flutter/services.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'photo_sharing_providers.g.dart';

/// Stockage local du partage de photos.
@Riverpod(keepAlive: true)
PhotoSharingRepository photoSharingRepository(Ref ref) =>
    PrefsPhotoSharingRepository(ref.watch(sharedPreferencesProvider));

/// Pont natif du partage de photos ; remplacé par un faux dans les tests.
@Riverpod(keepAlive: true)
PhotoSharingSystem photoSharingSystem(Ref ref) => NativePhotoSharingSystem(
  const MethodChannel(NativePhotoSharingSystem.channelName),
);
```

- [ ] **Step 3 : overrides par défaut des tests.**

Dans `test/helpers/pump_app.dart`, ajouter les imports :

```dart
import 'package:colette/features/photo_sharing/presentation/providers/photo_sharing_providers.dart';

import 'fake_photo_sharing_system.dart';
import 'in_memory_photo_sharing_repository.dart';
```

et, dans la liste `overrides` du `ProviderScope`, avant `...overrides` :

```dart
        if (!overridden(photoSharingRepositoryProvider))
          photoSharingRepositoryProvider.overrideWithValue(
            InMemoryPhotoSharingRepository(),
          ),
        if (!overridden(photoSharingSystemProvider))
          photoSharingSystemProvider.overrideWithValue(
            FakePhotoSharingSystem(),
          ),
```

Dans `test/helpers/colette_app_overrides.dart` : paramètre `PhotoSharingSystem? photoSharingSystem`, et en fin de liste :

```dart
    photoSharingSystemProvider.overrideWithValue(
      photoSharingSystem ?? FakePhotoSharingSystem(),
    ),
```

(imports : `photo_sharing_providers.dart`, `photo_sharing_system.dart`, `fake_photo_sharing_system.dart`). Le repository reste le vrai, sur les `SharedPreferences` simulées.

- [ ] **Step 4 : tests rouges.**

`test/features/photo_sharing/presentation/broadcast_lists_test.dart` :

```dart
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

  Future<List<BroadcastList>> lists() => container.read(broadcastListsProvider.future);

  test('charge les listes enregistrées', () async {
    expect((await lists()).single.name, 'Famille');
  });

  test('create : nom nettoyé, identifiant généré, enregistré', () async {
    await lists();
    final id = await notifier().create('  Amis ');
    expect(id.toNullable(), 'l2');
    expect((await lists()).last, const BroadcastList(id: 'l2', name: 'Amis', recipients: []));
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
  });

  test('addFromContacts annulé : rien ne change', () async {
    await lists();
    final result = await notifier().addFromContacts('l1');
    expect(result.isRight(), isTrue);
    expect((await lists()).single.recipients, isEmpty);
  });

  test('removeRecipient', () async {
    repo.lists = const [BroadcastList(id: 'l1', name: 'Famille', recipients: [mamie])];
    await lists();
    await notifier().removeRecipient('l1', mamie.phone);
    expect((await lists()).single.recipients, isEmpty);
  });

  test('échec d\'écriture : état inchangé, failure renvoyée', () async {
    await lists();
    repo.failSaves = true;
    final result = await notifier().rename('l1', 'X');
    expect(result.getLeft().toNullable(), isA<UnknownFailure>());
    expect((await lists()).single.name, 'Famille');
  });
}
```

`test/features/photo_sharing/presentation/photo_reminder_test.dart` :

```dart
import 'package:colette/core/clock/app_clock.dart';
import 'package:colette/features/baby/domain/entities/baby_profile.dart';
import 'package:colette/features/baby/presentation/providers/baby_providers.dart';
import 'package:colette/features/photo_sharing/domain/use_cases/photo_reminder_schedule.dart';
import 'package:colette/features/photo_sharing/presentation/providers/photo_reminder.dart';
import 'package:colette/features/photo_sharing/presentation/providers/photo_sharing_providers.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../helpers/fake_photo_sharing_system.dart';
import '../../../helpers/in_memory_photo_sharing_repository.dart';

void main() {
  final now = DateTime(2026, 9, 30, 7);
  late InMemoryPhotoSharingRepository repo;
  late FakePhotoSharingSystem system;

  ProviderContainer makeContainer({BabyProfile? profile}) {
    final container = ProviderContainer(
      overrides: [
        photoSharingRepositoryProvider.overrideWithValue(repo),
        photoSharingSystemProvider.overrideWithValue(system),
        clockProvider.overrideWithValue(FixedClock(now)),
        babyProfileProvider.overrideWith((ref) => Stream.value(profile)),
      ],
    );
    addTearDown(container.dispose);
    // Garde le profil chargé, comme le fait PhotoReminderGate.
    container.listen(babyProfileProvider, (_, _) {});
    return container;
  }

  setUp(() {
    repo = InMemoryPhotoSharingRepository();
    system = FakePhotoSharingSystem();
  });

  test('sync actif : 14 dates, texte avec le prénom', () async {
    final container = makeContainer(
      profile: BabyProfile(name: 'Colette', birthDate: DateTime(2026, 9, 1)),
    );
    await container.read(babyProfileProvider.future);
    await container.read(photoReminderSyncProvider).sync();
    expect(system.syncedDates.single, hasLength(photoReminderDays));
    expect(system.lastTitle, "C'est l'heure d'une photo 📷");
    expect(system.lastBody, 'Envoie des nouvelles de Colette à tes proches.');
  });

  test('sync sans prénom : texte générique', () async {
    final container = makeContainer();
    await container.read(babyProfileProvider.future);
    await container.read(photoReminderSyncProvider).sync();
    expect(system.lastBody, 'Envoie des nouvelles de bébé à tes proches.');
  });

  test('sync après un envoi aujourd\'hui : pas de date aujourd\'hui', () async {
    repo.lastSentAt = DateTime(2026, 9, 30, 6);
    final container = makeContainer();
    await container.read(photoReminderSyncProvider).sync();
    expect(system.syncedDates.single.first.day, 1);
  });

  test('désactiver : enregistré puis aucune date programmée', () async {
    final container = makeContainer();
    expect(await container.read(photoReminderEnabledProvider.future), isTrue);
    await container.read(photoReminderEnabledProvider.notifier).set(false);
    expect(repo.reminderEnabled, isFalse);
    expect(container.read(photoReminderEnabledProvider).value, isFalse);
    expect(system.syncedDates.single, isEmpty);
  });

  test('markSent : enregistré et exposé', () async {
    final container = makeContainer();
    expect(await container.read(lastPhotoSentAtProvider.future), isNull);
    await container.read(lastPhotoSentAtProvider.notifier).markSent(now);
    expect(repo.lastSentAt, now);
    expect(container.read(lastPhotoSentAtProvider).value, now);
  });
}
```

Run: `flutter test test/features/photo_sharing/presentation` — Expected : FAIL (providers absents).

- [ ] **Step 5 : implémentation.**

`broadcast_lists.dart` :

```dart
import 'package:colette/core/ids/id_generator.dart';
import 'package:colette/core/result/failure.dart';
import 'package:colette/core/result/no_retry.dart';
import 'package:colette/features/photo_sharing/domain/entities/broadcast_list.dart';
import 'package:colette/features/photo_sharing/presentation/providers/photo_sharing_providers.dart';
import 'package:fpdart/fpdart.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'broadcast_lists.g.dart';

/// Listes de diffusion de cet iPhone. Chaque modification est enregistrée ;
/// en cas d'échec, l'état reste inchangé et la failure est renvoyée.
@Riverpod(keepAlive: true, retry: noRetry)
class BroadcastLists extends _$BroadcastLists {
  @override
  Future<List<BroadcastList>> build() async {
    final result = await ref.watch(photoSharingRepositoryProvider).loadLists();
    return result.fold((failure) => throw failure, (lists) => lists);
  }

  /// Crée une liste vide ; renvoie son identifiant.
  Future<Either<Failure, String>> create(String name) async {
    final id = ref.read(idGeneratorProvider).newId();
    final list = BroadcastList(id: id, name: name.trim(), recipients: const []);
    final saved = await _save((lists) => [...lists, list]);
    return saved.map((_) => id);
  }

  Future<Either<Failure, void>> rename(String id, String name) =>
      _update(id, (list) => list.copyWith(name: name.trim()));

  Future<Either<Failure, void>> delete(String id) => _save(
    (lists) => [
      for (final list in lists)
        if (list.id != id) list,
    ],
  );

  /// Sélecteur de contacts puis ajout ; sans effet si annulé.
  Future<Either<Failure, void>> addFromContacts(String id) async {
    final picked = await ref.read(photoSharingSystemProvider).pickContact();
    return switch (picked) {
      Left(:final value) => left(value),
      Right(value: null) => right(null),
      Right(value: final recipient?) => _update(
        id,
        (list) => list.withRecipient(recipient),
      ),
    };
  }

  Future<Either<Failure, void>> removeRecipient(String id, String phone) =>
      _update(id, (list) => list.withoutRecipient(phone));

  Future<Either<Failure, void>> _update(
    String id,
    BroadcastList Function(BroadcastList list) edit,
  ) => _save(
    (lists) => [for (final list in lists) list.id == id ? edit(list) : list],
  );

  Future<Either<Failure, void>> _save(
    List<BroadcastList> Function(List<BroadcastList> lists) edit,
  ) async {
    final List<BroadcastList> current;
    try {
      current = await future;
    } on Failure {
      // Données illisibles : repartir d'une liste vide plutôt que bloquer.
      return _write(edit(const []));
    }
    return _write(edit(current));
  }

  Future<Either<Failure, void>> _write(List<BroadcastList> next) async {
    final result = await ref.read(photoSharingRepositoryProvider).saveLists(next);
    if (result.isRight()) state = AsyncData(next);
    return result;
  }
}
```

`photo_reminder.dart` :

```dart
import 'package:colette/core/clock/app_clock.dart';
import 'package:colette/core/result/failure.dart';
import 'package:colette/core/result/no_retry.dart';
import 'package:colette/features/baby/presentation/providers/baby_providers.dart';
import 'package:colette/features/photo_sharing/domain/use_cases/photo_reminder_schedule.dart';
import 'package:colette/features/photo_sharing/presentation/providers/photo_sharing_providers.dart';
import 'package:colette/l10n/generated/app_localizations.dart';
import 'package:flutter/widgets.dart';
import 'package:fpdart/fpdart.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'photo_reminder.g.dart';

/// Date du dernier envoi réussi sur cet iPhone ; `null` si aucun.
@Riverpod(keepAlive: true, retry: noRetry)
class LastPhotoSentAt extends _$LastPhotoSentAt {
  @override
  Future<DateTime?> build() async {
    final result = await ref
        .watch(photoSharingRepositoryProvider)
        .loadLastSentAt();
    return result.fold((failure) => throw failure, (date) => date);
  }

  Future<Either<Failure, void>> markSent(DateTime sentAt) async {
    final result = await ref
        .read(photoSharingRepositoryProvider)
        .saveLastSentAt(sentAt);
    if (result.isRight()) state = AsyncData(sentAt);
    return result;
  }
}

/// Interrupteur du rappel photo quotidien (vrai par défaut).
@Riverpod(keepAlive: true, retry: noRetry)
class PhotoReminderEnabled extends _$PhotoReminderEnabled {
  @override
  Future<bool> build() async {
    final result = await ref
        .watch(photoSharingRepositoryProvider)
        .loadReminderEnabled();
    return result.fold((failure) => throw failure, (enabled) => enabled);
  }

  /// Enregistre puis reprogramme les notifications.
  Future<Either<Failure, void>> set(bool enabled) async {
    final result = await ref
        .read(photoSharingRepositoryProvider)
        .saveReminderEnabled(enabled);
    if (result.isRight()) {
      state = AsyncData(enabled);
      await ref.read(photoReminderSyncProvider).sync();
    }
    return result;
  }
}

/// Reprogramme les notifications du rappel photo depuis le stockage :
/// interrupteur, dernier envoi, prénom du bébé.
class PhotoReminderSync {
  PhotoReminderSync(this._ref);

  final Ref _ref;

  Future<void> sync() async {
    final repository = _ref.read(photoSharingRepositoryProvider);
    final enabled = (await repository.loadReminderEnabled()).getOrElse(
      (_) => true,
    );
    final lastSentAt = (await repository.loadLastSentAt()).getOrElse(
      (_) => null,
    );
    final dates = enabled
        ? planPhotoReminders(
            now: _ref.read(clockProvider).now(),
            lastSentAt: lastSentAt,
          )
        : const <DateTime>[];
    final s = lookupS(const Locale('fr'));
    final name = _ref.read(babyProfileProvider).value?.name;
    await _ref
        .read(photoSharingSystemProvider)
        .syncReminders(
          dates: dates,
          title: s.photoReminderTitle,
          body: name == null || name.isEmpty
              ? s.photoReminderBodyNoName
              : s.photoReminderBody(name),
        );
  }
}

/// Synchronisation du rappel photo.
@Riverpod(keepAlive: true)
PhotoReminderSync photoReminderSync(Ref ref) => PhotoReminderSync(ref);
```

Run: `dart run build_runner build -d`.

- [ ] **Step 6 :** `flutter test test/features/photo_sharing/presentation` — Expected : PASS. Puis `flutter test` complet : les tests existants (pumpApp, coletteAppOverrides) restent verts.

- [ ] **Step 7 : commit**

```bash
dart format lib test && dart analyze
git add lib/features/photo_sharing/presentation/providers test/helpers/fake_photo_sharing_system.dart test/helpers/in_memory_photo_sharing_repository.dart test/helpers/pump_app.dart test/helpers/colette_app_overrides.dart test/features/photo_sharing/presentation/broadcast_lists_test.dart test/features/photo_sharing/presentation/photo_reminder_test.dart
git commit -m "feat: providers des listes de diffusion et du rappel photo"
```

---

### Task 8 : contrôleurs de capture et d'envoi

**Files:**
- Create: `lib/features/photo_sharing/presentation/providers/photo_capture_controller.dart`
- Create: `lib/features/photo_sharing/presentation/providers/photo_send_controller.dart`
- Test: `test/features/photo_sharing/presentation/photo_send_controller_test.dart`

- [ ] **Step 1 : test rouge**

```dart
import 'package:colette/core/clock/app_clock.dart';
import 'package:colette/core/result/failure.dart';
import 'package:colette/features/baby/presentation/providers/baby_providers.dart';
import 'package:colette/features/photo_sharing/domain/entities/broadcast_list.dart';
import 'package:colette/features/photo_sharing/domain/entities/photo_source.dart';
import 'package:colette/features/photo_sharing/domain/entities/recipient.dart';
import 'package:colette/features/photo_sharing/domain/entities/send_report.dart';
import 'package:colette/features/photo_sharing/presentation/providers/photo_capture_controller.dart';
import 'package:colette/features/photo_sharing/presentation/providers/photo_send_controller.dart';
import 'package:colette/features/photo_sharing/presentation/providers/photo_sharing_providers.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../helpers/fake_photo_sharing_system.dart';
import '../../../helpers/in_memory_photo_sharing_repository.dart';

void main() {
  final now = DateTime(2026, 9, 30, 15, 20);
  const list = BroadcastList(
    id: 'l1',
    name: 'Famille',
    recipients: [
      Recipient(name: 'Mamie', phone: '0611'),
      Recipient(name: 'Papi', phone: '0622'),
    ],
  );
  late InMemoryPhotoSharingRepository repo;
  late FakePhotoSharingSystem system;
  late ProviderContainer container;

  setUp(() {
    repo = InMemoryPhotoSharingRepository();
    system = FakePhotoSharingSystem();
    container = ProviderContainer(
      overrides: [
        photoSharingRepositoryProvider.overrideWithValue(repo),
        photoSharingSystemProvider.overrideWithValue(system),
        clockProvider.overrideWithValue(FixedClock(now)),
        babyProfileProvider.overrideWith((ref) => Stream.value(null)),
      ],
    );
    addTearDown(container.dispose);
    container.listen(photoSendControllerProvider, (_, _) {});
    container.listen(photoCaptureControllerProvider, (_, _) {});
  });

  Future<void> send() => container
      .read(photoSendControllerProvider.notifier)
      .send(list: list, photoPaths: ['/tmp/a.jpg'], body: '  Coucou  ');

  test('un message par personne, texte nettoyé, photos effacées', () async {
    system.report = const SendReport(sent: 2, cancelled: 0, failed: 0);
    await send();
    expect(system.sendCalls.single.phones, ['0611', '0622']);
    expect(system.sendCalls.single.body, 'Coucou');
    expect(system.discarded, ['/tmp/a.jpg']);
    expect(
      container.read(photoSendControllerProvider).value,
      const SendReport(sent: 2, cancelled: 0, failed: 0),
    );
  });

  test('au moins un envoi : date enregistrée, rappel du jour retiré', () async {
    system.report = const SendReport(sent: 1, cancelled: 1, failed: 0);
    await send();
    expect(repo.lastSentAt, now);
    expect(system.syncedDates.single.first.day, 1);
  });

  test('tout annulé : rien d\'enregistré, pas de resynchronisation', () async {
    system.report = const SendReport(sent: 0, cancelled: 2, failed: 0);
    await send();
    expect(repo.lastSentAt, isNull);
    expect(system.syncedDates, isEmpty);
  });

  test('Messages indisponible : AsyncError, photos effacées', () async {
    system.sendFailure = const PhotoSharingFailure(
      PhotoSharingReason.messagesUnavailable,
    );
    await send();
    expect(
      container.read(photoSendControllerProvider).error,
      const PhotoSharingFailure(PhotoSharingReason.messagesUnavailable),
    );
    expect(system.discarded, ['/tmp/a.jpg']);
  });

  test('capture : chemins rendus', () async {
    system.photos = ['/tmp/a.jpg', '/tmp/b.jpg'];
    final paths = await container
        .read(photoCaptureControllerProvider.notifier)
        .capture(PhotoSource.gallery);
    expect(paths, ['/tmp/a.jpg', '/tmp/b.jpg']);
  });

  test('capture en échec : liste vide et AsyncError', () async {
    system.photosFailure = const PhotoSharingFailure(
      PhotoSharingReason.cameraUnavailable,
    );
    final paths = await container
        .read(photoCaptureControllerProvider.notifier)
        .capture(PhotoSource.camera);
    expect(paths, isEmpty);
    expect(container.read(photoCaptureControllerProvider).hasError, isTrue);
  });
}
```

Run: `flutter test test/features/photo_sharing/presentation/photo_send_controller_test.dart` — Expected : FAIL.

- [ ] **Step 2 : implémentation.**

`photo_capture_controller.dart` :

```dart
import 'package:colette/features/photo_sharing/domain/entities/photo_source.dart';
import 'package:colette/features/photo_sharing/presentation/providers/photo_sharing_providers.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'photo_capture_controller.g.dart';

/// Prise ou choix des photos d'un envoi ; une failure passe en `AsyncError`.
@riverpod
class PhotoCaptureController extends _$PhotoCaptureController {
  @override
  FutureOr<void> build() {}

  /// Chemins des photos préparées ; vide si annulé ou en échec.
  Future<List<String>> capture(PhotoSource source) async {
    state = const AsyncLoading();
    final system = ref.read(photoSharingSystemProvider);
    final result = await switch (source) {
      PhotoSource.camera => system.takePhoto(),
      PhotoSource.gallery => system.pickPhotos(),
    };
    final paths = result.getOrElse((_) => const []);
    if (!ref.mounted) return paths;
    state = result.fold(
      (failure) => AsyncError(failure, StackTrace.current),
      (_) => const AsyncData(null),
    );
    return paths;
  }
}
```

`photo_send_controller.dart` :

```dart
import 'package:colette/core/clock/app_clock.dart';
import 'package:colette/features/photo_sharing/domain/entities/broadcast_list.dart';
import 'package:colette/features/photo_sharing/domain/entities/send_report.dart';
import 'package:colette/features/photo_sharing/presentation/providers/photo_reminder.dart';
import 'package:colette/features/photo_sharing/presentation/providers/photo_sharing_providers.dart';
import 'package:fpdart/fpdart.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'photo_send_controller.g.dart';

/// Envoi des photos à chaque personne d'une liste, une feuille Messages par
/// personne ; `AsyncData(bilan)` à la fin, `null` avant tout envoi.
@riverpod
class PhotoSendController extends _$PhotoSendController {
  @override
  FutureOr<SendReport?> build() => null;

  Future<void> send({
    required BroadcastList list,
    required List<String> photoPaths,
    required String body,
  }) async {
    state = const AsyncLoading();
    final system = ref.read(photoSharingSystemProvider);
    final result = await system.sendMessages(
      phones: [for (final recipient in list.recipients) recipient.phone],
      photoPaths: photoPaths,
      body: body.trim(),
    );
    await system.discardPhotos(photoPaths);
    if (!ref.mounted) return;
    switch (result) {
      case Left(:final value):
        state = AsyncError(value, StackTrace.current);
      case Right(:final value):
        if (value.anySent) {
          final now = ref.read(clockProvider).now();
          await ref.read(lastPhotoSentAtProvider.notifier).markSent(now);
          await ref.read(photoReminderSyncProvider).sync();
        }
        if (ref.mounted) state = AsyncData(value);
    }
  }
}
```

Run: `dart run build_runner build -d`.

- [ ] **Step 3 :** relancer le test — Expected : PASS.

- [ ] **Step 4 : commit**

```bash
dart format lib test && dart analyze
git add lib/features/photo_sharing/presentation/providers/photo_capture_controller.dart lib/features/photo_sharing/presentation/providers/photo_capture_controller.g.dart lib/features/photo_sharing/presentation/providers/photo_send_controller.dart lib/features/photo_sharing/presentation/providers/photo_send_controller.g.dart test/features/photo_sharing/presentation/photo_send_controller_test.dart
git commit -m "feat: contrôleurs de capture et d'envoi des photos"
```


---

### Task 9 : libellés, carte Photos, route et tableau de bord

**Files:**
- Create: `lib/features/photo_sharing/presentation/photo_labels.dart`
- Create: `lib/features/photo_sharing/presentation/widgets/photos_card.dart`
- Create: `lib/features/photo_sharing/presentation/pages/photos_page.dart` (squelette, complété en Task 11)
- Modify: `lib/app/router/app_router.dart`, `lib/features/dashboard/presentation/pages/dashboard_page.dart`
- Test: `test/features/photo_sharing/presentation/photo_labels_test.dart`, `test/features/photo_sharing/presentation/photos_card_test.dart`

- [ ] **Step 1 : tests rouges.**

`photo_labels_test.dart` :

```dart
import 'dart:ui' show Locale;

import 'package:colette/features/photo_sharing/domain/entities/send_report.dart';
import 'package:colette/features/photo_sharing/presentation/photo_labels.dart';
import 'package:colette/l10n/generated/app_localizations.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  late S s;
  final now = DateTime(2026, 9, 30, 10);

  setUpAll(() async {
    s = await S.delegate.load(const Locale('fr'));
  });

  test('aucun envoi', () {
    expect(lastSentLabel(null, now: now, s: s), "Aucune photo envoyée pour l'instant");
  });

  test('envoi d\'hier', () {
    expect(
      lastSentLabel(DateTime(2026, 9, 29, 18, 12), now: now, s: s),
      'Dernier envoi · Hier, 18h12',
    );
  });

  test('bilan : annulés et échecs omis à zéro', () {
    expect(sendReportLabel(const SendReport(sent: 2, cancelled: 0, failed: 0), s), '2 envoyés');
    expect(
      sendReportLabel(const SendReport(sent: 1, cancelled: 1, failed: 2), s),
      '1 envoyé · 1 annulé · 2 en échec',
    );
    expect(
      sendReportLabel(const SendReport(sent: 0, cancelled: 3, failed: 0), s),
      'Aucun message envoyé · 3 annulés',
    );
  });
}
```

`photos_card_test.dart` :

```dart
import 'package:colette/core/clock/app_clock.dart';
import 'package:colette/core/clock/now_providers.dart';
import 'package:colette/features/photo_sharing/presentation/providers/photo_sharing_providers.dart';
import 'package:colette/features/photo_sharing/presentation/widgets/photos_card.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../helpers/in_memory_photo_sharing_repository.dart';
import '../../../helpers/pump_app.dart';

void main() {
  final now = DateTime(2026, 9, 30, 10);

  Future<void> pumpCard(WidgetTester tester, DateTime? lastSentAt) => pumpApp(
    tester,
    const PhotosCard(),
    overrides: [
      clockProvider.overrideWithValue(FixedClock(now)),
      minuteTickerProvider.overrideWith((ref) => const Stream.empty()),
      photoSharingRepositoryProvider.overrideWithValue(
        InMemoryPhotoSharingRepository(lastSentAt: lastSentAt),
      ),
    ],
  );

  testWidgets('aucun envoi', (tester) async {
    await pumpCard(tester, null);
    expect(find.text('Photos'), findsOneWidget);
    expect(find.text("Aucune photo envoyée pour l'instant"), findsOneWidget);
  });

  testWidgets('dernier envoi affiché', (tester) async {
    await pumpCard(tester, DateTime(2026, 9, 30, 8, 5));
    expect(find.text("Dernier envoi · Aujourd'hui, 08h05"), findsOneWidget);
  });
}
```

Run: `flutter test test/features/photo_sharing/presentation/photo_labels_test.dart test/features/photo_sharing/presentation/photos_card_test.dart` — Expected : FAIL.

- [ ] **Step 2 : implémentation.**

`photo_labels.dart` :

```dart
import 'package:colette/core/dates/time_format.dart';
import 'package:colette/features/events/presentation/day_label.dart';
import 'package:colette/features/photo_sharing/domain/entities/send_report.dart';
import 'package:colette/l10n/generated/app_localizations.dart';

/// « Dernier envoi · Hier, 18h12 », ou l'absence d'envoi.
String lastSentLabel(DateTime? sentAt, {required DateTime now, required S s}) =>
    sentAt == null
    ? s.photosNeverSent
    : s.photosLastSent(dayLabel(sentAt, now: now, s: s), formatHourMinute(sentAt));

/// « 1 envoyé · 1 annulé · 2 en échec » ; annulés et échecs omis à zéro.
String sendReportLabel(SendReport report, S s) => [
  s.photosReportSent(report.sent),
  if (report.cancelled > 0) s.photosReportCancelled(report.cancelled),
  if (report.failed > 0) s.photosReportFailed(report.failed),
].join(' · ');
```

`photos_card.dart` :

```dart
import 'package:colette/app/router/app_router.dart';
import 'package:colette/core/clock/now_providers.dart';
import 'package:colette/core/theme/app_colors.dart';
import 'package:colette/core/theme/design_tokens.dart';
import 'package:colette/core/theme/text_styles.dart';
import 'package:colette/features/photo_sharing/presentation/photo_labels.dart';
import 'package:colette/features/photo_sharing/presentation/providers/photo_reminder.dart';
import 'package:colette/l10n/generated/app_localizations.dart';
import 'package:colette/shared/ui/widgets/colette_card_surface.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

/// Carte « Photos » sur Aujourd'hui : dernier envoi et accès aux listes.
class PhotosCard extends ConsumerWidget {
  const PhotosCard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final s = S.of(context);
    final styles = Theme.of(context).coletteTextStyles;
    final secondary = context.appColor(AppColors.textSecondary);
    final now = ref.watch(currentMinuteProvider);
    final lastSentAt = ref.watch(lastPhotoSentAtProvider).value;
    return ColetteCardSurface(
      onTap: () => context.push(AppRoutes.todayPhotos),
      child: Row(
        spacing: AppSpacing.sm.value,
        children: [
          Icon(
            Icons.photo_camera_outlined,
            color: context.appColor(AppColors.primary),
          ),
          Expanded(
            child: Column(
              crossAxisAlignment: .start,
              children: [
                Text(s.photosCardTitle, style: styles.bodyMedium),
                Text(
                  lastSentLabel(lastSentAt, now: now, s: s),
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
```

`photos_page.dart` (squelette, remplacé en Task 11) :

```dart
import 'package:colette/l10n/generated/app_localizations.dart';
import 'package:flutter/material.dart';

/// Listes de diffusion de cet iPhone ; un appui envoie des photos à une liste.
class PhotosPage extends StatelessWidget {
  const PhotosPage({super.key});

  @override
  Widget build(BuildContext context) =>
      Scaffold(appBar: AppBar(title: Text(S.of(context).photosPageTitle)));
}
```

Dans `lib/app/router/app_router.dart` : après `todayDocuments` dans `AppRoutes` :

```dart
  /// Page Photos, imbriquée sous Aujourd'hui pour garder la barre d'onglets.
  static const todayPhotos = '/today/photos';
```

et, dans les `routes` de `AppRoutes.today`, après la route `documents` :

```dart
                  GoRoute(
                    path: 'photos',
                    builder: (_, _) => const PhotosPage(),
                  ),
```

(import `package:colette/features/photo_sharing/presentation/pages/photos_page.dart`).

Dans `dashboard_page.dart`, après `const DocumentsCard(),` :

```dart
            AppSpacing.md.verticalSpace,
            const PhotosCard(),
```

(import `package:colette/features/photo_sharing/presentation/widgets/photos_card.dart`).

- [ ] **Step 3 :** relancer les deux tests — Expected : PASS. Puis `flutter test test/features/dashboard test/app` — Expected : PASS.

- [ ] **Step 4 : commit**

```bash
dart format lib test && dart analyze
git add lib/features/photo_sharing/presentation/photo_labels.dart lib/features/photo_sharing/presentation/widgets/photos_card.dart lib/features/photo_sharing/presentation/pages/photos_page.dart lib/app/router/app_router.dart lib/features/dashboard/presentation/pages/dashboard_page.dart test/features/photo_sharing/presentation/photo_labels_test.dart test/features/photo_sharing/presentation/photos_card_test.dart
git commit -m "feat: carte Photos sur Aujourd'hui et route de la page"
```

---

### Task 10 : flux d'envoi (source, capture, feuille d'envoi)

**Files:**
- Create: `lib/features/photo_sharing/presentation/widgets/photo_send_flow.dart`
- Create: `lib/features/photo_sharing/presentation/widgets/photo_send_sheet.dart`
- Test: `test/features/photo_sharing/presentation/photo_send_flow_test.dart`

- [ ] **Step 1 : test rouge**

```dart
import 'package:colette/core/clock/app_clock.dart';
import 'package:colette/core/result/failure.dart';
import 'package:colette/features/baby/presentation/providers/baby_providers.dart';
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

  Future<void> start(WidgetTester tester, {String source = 'Choisir dans la galerie'}) async {
    await pumpApp(
      tester,
      const _Host(),
      overrides: [
        photoSharingSystemProvider.overrideWithValue(system),
        photoSharingRepositoryProvider.overrideWithValue(repo),
        clockProvider.overrideWithValue(FixedClock(DateTime(2026, 9, 30, 15))),
        babyProfileProvider.overrideWith((ref) => Stream.value(null)),
      ],
    );
    await tester.tap(find.text('go'));
    await tester.pumpAndSettle();
    expect(find.text('Prendre une photo'), findsOneWidget);
    await tester.tap(find.text(source));
    await tester.pumpAndSettle();
  }

  testWidgets('galerie → feuille d\'envoi → un message par personne', (tester) async {
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
  });

  testWidgets('feuille fermée sans envoyer : photos effacées', (tester) async {
    await start(tester);
    await tester.tapAt(const Offset(10, 10));
    await tester.pumpAndSettle();
    expect(system.sendCalls, isEmpty);
    expect(system.discarded, ['/tmp/a.jpg', '/tmp/b.jpg']);
  });

  testWidgets('capture annulée : pas de feuille d\'envoi', (tester) async {
    system.photos = const [];
    await start(tester);
    expect(find.textContaining('Envoyer à'), findsNothing);
  });

  testWidgets('Messages indisponible : message d\'erreur', (tester) async {
    system.sendFailure = const PhotoSharingFailure(
      PhotoSharingReason.messagesUnavailable,
    );
    await start(tester, source: 'Prendre une photo');
    await tester.tap(find.text('Envoyer à 2 personnes'));
    await tester.pumpAndSettle();
    expect(find.text("Messages n'est pas disponible sur cet appareil."), findsOneWidget);
  });
}
```

Run: `flutter test test/features/photo_sharing/presentation/photo_send_flow_test.dart` — Expected : FAIL.

- [ ] **Step 2 : implémentation.**

`photo_send_flow.dart` :

```dart
import 'package:colette/core/theme/design_tokens.dart';
import 'package:colette/features/photo_sharing/domain/entities/broadcast_list.dart';
import 'package:colette/features/photo_sharing/domain/entities/photo_source.dart';
import 'package:colette/features/photo_sharing/presentation/providers/photo_capture_controller.dart';
import 'package:colette/features/photo_sharing/presentation/providers/photo_sharing_providers.dart';
import 'package:colette/features/photo_sharing/presentation/widgets/photo_send_sheet.dart';
import 'package:colette/l10n/generated/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Choix de la source, prise ou choix des photos, puis feuille d'envoi à
/// [list]. Le `build` appelant doit surveiller `photoCaptureControllerProvider`
/// (erreurs de capture affichées par son `ref.listen`).
Future<void> startPhotoSend(
  BuildContext context,
  WidgetRef ref,
  BroadcastList list,
) async {
  // Lu avant les await : le pont reste utilisable même si la page est démontée.
  final system = ref.read(photoSharingSystemProvider);
  final source = await _chooseSource(context);
  if (source == null || !context.mounted) return;
  final paths = await ref
      .read(photoCaptureControllerProvider.notifier)
      .capture(source);
  if (paths.isEmpty) return;
  if (!context.mounted) {
    await system.discardPhotos(paths);
    return;
  }
  final started = await showPhotoSendSheet(
    context,
    list: list,
    photoPaths: paths,
  );
  if (!started) await system.discardPhotos(paths);
}

Future<PhotoSource?> _chooseSource(BuildContext context) {
  final s = S.of(context);
  return showModalBottomSheet<PhotoSource>(
    context: context,
    builder: (sheetContext) => SafeArea(
      child: Padding(
        padding: AppSpacing.symmetric(vertical: AppSpacing.sm),
        child: Column(
          mainAxisSize: .min,
          children: [
            ListTile(
              leading: const Icon(Icons.photo_camera_outlined),
              title: Text(s.photosTakePhoto),
              onTap: () => Navigator.of(sheetContext).pop(PhotoSource.camera),
            ),
            ListTile(
              leading: const Icon(Icons.photo_library_outlined),
              title: Text(s.photosPickFromGallery),
              onTap: () => Navigator.of(sheetContext).pop(PhotoSource.gallery),
            ),
          ],
        ),
      ),
    ),
  );
}
```

`photo_send_sheet.dart` :

```dart
import 'dart:io';

import 'package:colette/core/theme/app_colors.dart';
import 'package:colette/core/theme/design_tokens.dart';
import 'package:colette/core/theme/text_styles.dart';
import 'package:colette/core/ui/failure_message.dart';
import 'package:colette/features/photo_sharing/domain/entities/broadcast_list.dart';
import 'package:colette/features/photo_sharing/presentation/photo_labels.dart';
import 'package:colette/features/photo_sharing/presentation/providers/photo_send_controller.dart';
import 'package:colette/l10n/generated/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Ouvre la feuille d'envoi ; `true` si l'envoi a été lancé (les photos sont
/// alors effacées par le contrôleur).
Future<bool> showPhotoSendSheet(
  BuildContext context, {
  required BroadcastList list,
  required List<String> photoPaths,
}) async {
  final started = await showModalBottomSheet<bool>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    builder: (_) => PhotoSendSheet(list: list, photoPaths: photoPaths),
  );
  return started ?? false;
}

/// Vignettes, texte facultatif commun à toute la liste et bouton d'envoi.
class PhotoSendSheet extends ConsumerStatefulWidget {
  const PhotoSendSheet({
    super.key,
    required this.list,
    required this.photoPaths,
  });

  final BroadcastList list;
  final List<String> photoPaths;

  @override
  ConsumerState<PhotoSendSheet> createState() => _PhotoSendSheetState();
}

class _PhotoSendSheetState extends ConsumerState<PhotoSendSheet> {
  final _message = TextEditingController();

  @override
  void dispose() {
    _message.dispose();
    super.dispose();
  }

  Future<void> _send() async {
    final s = S.of(context);
    final messenger = ScaffoldMessenger.of(context);
    final navigator = Navigator.of(context);
    await ref
        .read(photoSendControllerProvider.notifier)
        .send(
          list: widget.list,
          photoPaths: widget.photoPaths,
          body: _message.text,
        );
    if (!mounted) return;
    final text = switch (ref.read(photoSendControllerProvider)) {
      AsyncData(value: final report?) => sendReportLabel(report, s),
      AsyncError(:final error) => failureMessage(error, s),
      _ => null,
    };
    navigator.pop(true);
    if (text != null) messenger.showSnackBar(SnackBar(content: Text(text)));
  }

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    // Garde le contrôleur autoDispose vivant pendant l'await de send.
    final busy = ref.watch(photoSendControllerProvider).isLoading;
    final count = widget.list.recipients.length;
    return Padding(
      padding:
          AppSpacing.md.all +
          EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(context).bottom),
      child: Column(
        mainAxisSize: .min,
        crossAxisAlignment: .stretch,
        spacing: AppSpacing.md.value,
        children: [
          Text(
            widget.list.name,
            style: Theme.of(context).coletteTextStyles.heading2,
          ),
          _Thumbnails(photoPaths: widget.photoPaths),
          TextField(
            controller: _message,
            minLines: 1,
            maxLines: 4,
            textCapitalization: .sentences,
            decoration: InputDecoration(labelText: s.photosMessageLabel),
          ),
          FilledButton(
            onPressed: busy || count == 0 ? null : _send,
            child: busy
                ? SizedBox.square(
                    dimension: AppSize.xs.value,
                    child: CircularProgressIndicator(
                      strokeWidth: AppSpacing.xxs.value,
                    ),
                  )
                : Text(s.photosSendTo(count)),
          ),
        ],
      ),
    );
  }
}

/// Bande horizontale de vignettes carrées.
class _Thumbnails extends StatelessWidget {
  const _Thumbnails({required this.photoPaths});

  final List<String> photoPaths;

  @override
  Widget build(BuildContext context) => SizedBox(
    height: AppSize.massive.value,
    child: ListView.separated(
      scrollDirection: .horizontal,
      itemCount: photoPaths.length,
      separatorBuilder: (_, _) => AppSpacing.sm.horizontalSpace,
      itemBuilder: (context, index) => ClipRRect(
        borderRadius: AppRadius.md.circular,
        child: AspectRatio(
          aspectRatio: 1,
          child: Image.file(
            File(photoPaths[index]),
            fit: .cover,
            errorBuilder: (context, _, _) => ColoredBox(
              color: context.appColor(AppColors.border),
              child: Icon(
                Icons.image_outlined,
                color: context.appColor(AppColors.textSecondary),
              ),
            ),
          ),
        ),
      ),
    ),
  );
}
```

- [ ] **Step 3 :** relancer le test — Expected : PASS. Si `tapAt(Offset(10, 10))` ne touche pas la barrière (feuille plein écran), fermer par `Navigator.of(tester.element(find.byType(PhotoSendSheet))).pop()`.

- [ ] **Step 4 : commit**

```bash
dart format lib test && dart analyze
git add lib/features/photo_sharing/presentation/widgets/photo_send_flow.dart lib/features/photo_sharing/presentation/widgets/photo_send_sheet.dart test/features/photo_sharing/presentation/photo_send_flow_test.dart
git commit -m "feat: choix des photos et feuille d'envoi à une liste"
```

---

### Task 11 : page Photos et édition des listes

**Files:**
- Create: `lib/features/photo_sharing/presentation/widgets/list_name_dialog.dart`
- Create: `lib/features/photo_sharing/presentation/widgets/broadcast_list_editor_sheet.dart`
- Modify: `lib/features/photo_sharing/presentation/pages/photos_page.dart` (remplace le squelette)
- Test: `test/features/photo_sharing/presentation/photos_page_test.dart`

- [ ] **Step 1 : test rouge**

```dart
import 'package:colette/core/clock/app_clock.dart';
import 'package:colette/core/clock/now_providers.dart';
import 'package:colette/core/ids/id_generator.dart';
import 'package:colette/core/result/failure.dart';
import 'package:colette/features/baby/presentation/providers/baby_providers.dart';
import 'package:colette/features/photo_sharing/domain/entities/broadcast_list.dart';
import 'package:colette/features/photo_sharing/domain/entities/recipient.dart';
import 'package:colette/features/photo_sharing/presentation/pages/photos_page.dart';
import 'package:colette/features/photo_sharing/presentation/providers/photo_sharing_providers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../helpers/fake_photo_sharing_system.dart';
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
      babyProfileProvider.overrideWith((ref) => Stream.value(null)),
    ],
  );

  testWidgets('état vide', (tester) async {
    await pumpPage(tester);
    expect(
      find.text('Crée une liste de proches pour leur envoyer des photos en quelques appuis.'),
      findsOneWidget,
    );
  });

  testWidgets('créer une liste ouvre son édition, puis ajouter un contact', (tester) async {
    system.contact = mamie;
    await pumpPage(tester);
    await tester.tap(find.text('Nouvelle liste'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField), 'Grands-parents');
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
    final button = tester.widget<TextButton>(find.widgetWithText(TextButton, 'Créer'));
    expect(button.onPressed, isNull);
  });

  testWidgets('glisser une personne la retire', (tester) async {
    repo.lists = const [BroadcastList(id: 'l1', name: 'Famille', recipients: [mamie])];
    await pumpPage(tester);
    await tester.tap(find.byTooltip('Modifier la liste'));
    await tester.pumpAndSettle();
    await tester.drag(find.text('Mamie'), const Offset(-500, 0));
    await tester.pumpAndSettle();
    expect(repo.lists.single.recipients, isEmpty);
  });

  testWidgets('supprimer la liste après confirmation', (tester) async {
    repo.lists = const [BroadcastList(id: 'l1', name: 'Famille', recipients: [])];
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

  testWidgets('liste vide : l\'appui ouvre l\'édition', (tester) async {
    repo.lists = const [BroadcastList(id: 'l1', name: 'Famille', recipients: [])];
    await pumpPage(tester);
    await tester.tap(find.text('Famille'));
    await tester.pumpAndSettle();
    expect(find.text('Ajouter une personne'), findsOneWidget);
  });

  testWidgets('liste remplie : l\'appui propose la source des photos', (tester) async {
    repo.lists = const [BroadcastList(id: 'l1', name: 'Famille', recipients: [mamie])];
    await pumpPage(tester);
    expect(find.text('1 personne'), findsOneWidget);
    await tester.tap(find.text('Famille'));
    await tester.pumpAndSettle();
    expect(find.text('Choisir dans la galerie'), findsOneWidget);
  });

  testWidgets('appareil photo indisponible : message', (tester) async {
    repo.lists = const [BroadcastList(id: 'l1', name: 'Famille', recipients: [mamie])];
    system.photosFailure = const PhotoSharingFailure(PhotoSharingReason.cameraUnavailable);
    await pumpPage(tester);
    await tester.tap(find.text('Famille'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Prendre une photo'));
    await tester.pumpAndSettle();
    expect(find.text("L'appareil photo n'est pas disponible."), findsOneWidget);
  });

  testWidgets('en-tête : dernier envoi', (tester) async {
    repo
      ..lists = const [BroadcastList(id: 'l1', name: 'Famille', recipients: [mamie])]
      ..lastSentAt = DateTime(2026, 9, 29, 18, 12);
    await pumpPage(tester);
    expect(find.text('Dernier envoi · Hier, 18h12'), findsOneWidget);
  });
}
```

Run: `flutter test test/features/photo_sharing/presentation/photos_page_test.dart` — Expected : FAIL.

- [ ] **Step 2 : `list_name_dialog.dart`**

```dart
import 'package:colette/l10n/generated/app_localizations.dart';
import 'package:flutter/material.dart';

/// Demande le nom d'une liste ; `null` si l'utilisateur annule.
Future<String?> showListNameDialog(
  BuildContext context, {
  required String title,
  required String confirmLabel,
  String initialName = '',
}) => showDialog<String>(
  context: context,
  builder: (_) => _ListNameDialog(
    title: title,
    confirmLabel: confirmLabel,
    initialName: initialName,
  ),
);

/// Champ de nom : le bouton reste inactif tant que le nom est vide.
class _ListNameDialog extends StatefulWidget {
  const _ListNameDialog({
    required this.title,
    required this.confirmLabel,
    required this.initialName,
  });

  final String title;
  final String confirmLabel;
  final String initialName;

  @override
  State<_ListNameDialog> createState() => _ListNameDialogState();
}

class _ListNameDialogState extends State<_ListNameDialog> {
  late final _controller = TextEditingController(text: widget.initialName);

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _submit() {
    final name = _controller.text.trim();
    if (name.isNotEmpty) Navigator.of(context).pop(name);
  }

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    return AlertDialog(
      title: Text(widget.title),
      content: TextField(
        controller: _controller,
        autofocus: true,
        textCapitalization: .sentences,
        textInputAction: .done,
        onSubmitted: (_) => _submit(),
        decoration: InputDecoration(labelText: s.photosListNameLabel),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text(s.actionCancel),
        ),
        ValueListenableBuilder(
          valueListenable: _controller,
          builder: (context, value, _) => TextButton(
            onPressed: value.text.trim().isEmpty ? null : _submit,
            child: Text(widget.confirmLabel),
          ),
        ),
      ],
    );
  }
}
```

- [ ] **Step 3 : `broadcast_list_editor_sheet.dart`**

```dart
import 'package:colette/core/result/failure.dart';
import 'package:colette/core/theme/app_colors.dart';
import 'package:colette/core/theme/design_tokens.dart';
import 'package:colette/core/theme/text_styles.dart';
import 'package:colette/core/ui/failure_message.dart';
import 'package:colette/features/photo_sharing/domain/entities/broadcast_list.dart';
import 'package:colette/features/photo_sharing/presentation/providers/broadcast_lists.dart';
import 'package:colette/features/photo_sharing/presentation/widgets/list_name_dialog.dart';
import 'package:colette/l10n/generated/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fpdart/fpdart.dart';

/// Ouvre l'édition de la liste [listId].
Future<void> showBroadcastListEditor(BuildContext context, String listId) =>
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (_) => BroadcastListEditorSheet(listId: listId),
    );

/// Affiche la failure d'une modification, s'il y en a une.
void _showFailure(
  ScaffoldMessengerState messenger,
  S s,
  Either<Failure, void> result,
) {
  if (result case Left(:final value)) {
    messenger.showSnackBar(SnackBar(content: Text(failureMessage(value, s))));
  }
}

/// Édition d'une liste : nom, personnes (glisser pour retirer), ajout depuis
/// les contacts, suppression de la liste.
class BroadcastListEditorSheet extends ConsumerWidget {
  const BroadcastListEditorSheet({super.key, required this.listId});

  final String listId;

  Future<void> _rename(
    BuildContext context,
    WidgetRef ref,
    BroadcastList list,
  ) async {
    final s = S.of(context);
    final messenger = ScaffoldMessenger.of(context);
    final name = await showListNameDialog(
      context,
      title: s.photosRenameList,
      confirmLabel: s.actionSave,
      initialName: list.name,
    );
    if (name == null || !context.mounted) return;
    final result = await ref
        .read(broadcastListsProvider.notifier)
        .rename(list.id, name);
    _showFailure(messenger, s, result);
  }

  Future<void> _add(BuildContext context, WidgetRef ref) async {
    final s = S.of(context);
    final messenger = ScaffoldMessenger.of(context);
    final result = await ref
        .read(broadcastListsProvider.notifier)
        .addFromContacts(listId);
    _showFailure(messenger, s, result);
  }

  Future<void> _delete(
    BuildContext context,
    WidgetRef ref,
    BroadcastList list,
  ) async {
    final s = S.of(context);
    final messenger = ScaffoldMessenger.of(context);
    final navigator = Navigator.of(context);
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(s.photosDeleteListTitle),
        content: Text(s.photosDeleteListBody(list.name)),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: Text(s.actionCancel),
          ),
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: Text(
              s.actionDelete,
              style: Theme.of(dialogContext).coletteTextStyles.bodyMedium
                  .copyWith(color: dialogContext.appColor(AppColors.error)),
            ),
          ),
        ],
      ),
    );
    if (confirmed != true || !context.mounted) return;
    final result = await ref.read(broadcastListsProvider.notifier).delete(list.id);
    _showFailure(messenger, s, result);
    if (result.isRight()) navigator.pop();
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final lists = ref.watch(broadcastListsProvider).value ?? const [];
    final list = lists.where((l) => l.id == listId).firstOrNull;
    if (list == null) return const SizedBox.shrink();
    final s = S.of(context);
    final styles = Theme.of(context).coletteTextStyles;
    final error = context.appColor(AppColors.error);
    return Padding(
      padding: AppSpacing.md.all,
      child: Column(
        mainAxisSize: .min,
        crossAxisAlignment: .stretch,
        children: [
          Row(
            children: [
              Expanded(child: Text(list.name, style: styles.heading2)),
              IconButton(
                tooltip: s.photosRenameList,
                icon: const Icon(Icons.edit_outlined),
                onPressed: () => _rename(context, ref, list),
              ),
            ],
          ),
          Text(
            s.photosRecipientCount(list.recipients.length),
            style: styles.small.copyWith(
              color: context.appColor(AppColors.textSecondary),
            ),
          ),
          AppSpacing.sm.verticalSpace,
          Flexible(child: _Recipients(list: list)),
          TextButton.icon(
            onPressed: () => _add(context, ref),
            icon: const Icon(Icons.person_add_alt_outlined),
            label: Text(s.photosAddRecipient),
          ),
          TextButton.icon(
            onPressed: () => _delete(context, ref, list),
            icon: Icon(Icons.delete_outline, color: error),
            label: Text(
              s.photosDeleteList,
              style: styles.bodyMedium.copyWith(color: error),
            ),
          ),
        ],
      ),
    );
  }
}

/// Personnes de la liste ; un glissement vers la gauche retire la personne.
/// La ligne disparaît avec la mise à jour de l'état, jamais d'elle-même.
class _Recipients extends ConsumerWidget {
  const _Recipients({required this.list});

  final BroadcastList list;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final s = S.of(context);
    final styles = Theme.of(context).coletteTextStyles;
    final secondary = context.appColor(AppColors.textSecondary);
    if (list.recipients.isEmpty) {
      return Padding(
        padding: AppSpacing.md.vertical,
        child: Text(
          s.photosNoRecipients,
          style: styles.body.copyWith(color: secondary),
        ),
      );
    }
    return ListView.builder(
      shrinkWrap: true,
      itemCount: list.recipients.length,
      itemBuilder: (context, index) {
        final recipient = list.recipients[index];
        return Dismissible(
          key: ValueKey(recipient.phone),
          direction: .endToStart,
          confirmDismiss: (_) async {
            final messenger = ScaffoldMessenger.of(context);
            final result = await ref
                .read(broadcastListsProvider.notifier)
                .removeRecipient(list.id, recipient.phone);
            _showFailure(messenger, s, result);
            return false;
          },
          background: Container(
            alignment: .centerRight,
            padding: AppSpacing.md.horizontal,
            color: context.appColor(AppColors.error),
            child: Icon(
              Icons.delete_outline,
              color: context.appColor(AppColors.onPrimary),
            ),
          ),
          child: ListTile(
            contentPadding: EdgeInsets.zero,
            leading: Icon(Icons.person_outline, color: secondary),
            title: Text(recipient.name, style: styles.body),
            subtitle: Text(
              recipient.phone,
              style: styles.small.copyWith(color: secondary),
            ),
          ),
        );
      },
    );
  }
}
```

- [ ] **Step 4 : `photos_page.dart`** (remplace le squelette)

```dart
import 'package:colette/core/clock/now_providers.dart';
import 'package:colette/core/theme/app_colors.dart';
import 'package:colette/core/theme/design_tokens.dart';
import 'package:colette/core/theme/text_styles.dart';
import 'package:colette/core/ui/failure_message.dart';
import 'package:colette/features/photo_sharing/domain/entities/broadcast_list.dart';
import 'package:colette/features/photo_sharing/presentation/photo_labels.dart';
import 'package:colette/features/photo_sharing/presentation/providers/broadcast_lists.dart';
import 'package:colette/features/photo_sharing/presentation/providers/photo_capture_controller.dart';
import 'package:colette/features/photo_sharing/presentation/providers/photo_reminder.dart';
import 'package:colette/features/photo_sharing/presentation/widgets/broadcast_list_editor_sheet.dart';
import 'package:colette/features/photo_sharing/presentation/widgets/list_name_dialog.dart';
import 'package:colette/features/photo_sharing/presentation/widgets/photo_send_flow.dart';
import 'package:colette/l10n/generated/app_localizations.dart';
import 'package:colette/shared/ui/widgets/colette_card_surface.dart';
import 'package:colette/shared/ui/widgets/empty_state.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fpdart/fpdart.dart';

/// Listes de diffusion de cet iPhone ; un appui envoie des photos à une liste.
class PhotosPage extends ConsumerWidget {
  const PhotosPage({super.key});

  Future<void> _create(BuildContext context, WidgetRef ref) async {
    final s = S.of(context);
    final messenger = ScaffoldMessenger.of(context);
    final name = await showListNameDialog(
      context,
      title: s.photosListNameTitle,
      confirmLabel: s.actionCreate,
    );
    if (name == null || !context.mounted) return;
    final created = await ref.read(broadcastListsProvider.notifier).create(name);
    if (!context.mounted) return;
    switch (created) {
      case Left(:final value):
        messenger.showSnackBar(
          SnackBar(content: Text(failureMessage(value, s))),
        );
      case Right(:final value):
        await showBroadcastListEditor(context, value);
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final s = S.of(context);
    // Garde le contrôleur autoDispose vivant pendant la capture des photos.
    ref.watch(photoCaptureControllerProvider);
    ref.listen(photoCaptureControllerProvider, (_, next) {
      if (next case AsyncError(:final error)) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(failureMessage(error, s))));
      }
    });
    return Scaffold(
      appBar: AppBar(title: Text(s.photosPageTitle)),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _create(context, ref),
        icon: const Icon(Icons.add),
        label: Text(s.photosNewList),
      ),
      body: switch (ref.watch(broadcastListsProvider)) {
        AsyncData(:final value) when value.isEmpty => EmptyState(
          icon: Icons.photo_library_outlined,
          message: s.photosEmptyBody,
        ),
        AsyncData(:final value) => _Lists(lists: value),
        AsyncError(:final error) => EmptyState(
          icon: Icons.error_outline,
          message: failureMessage(error, s),
        ),
        _ => const Center(child: CircularProgressIndicator()),
      },
    );
  }
}

/// En-tête « dernier envoi » puis une carte par liste.
class _Lists extends ConsumerWidget {
  const _Lists({required this.lists});

  final List<BroadcastList> lists;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final s = S.of(context);
    final now = ref.watch(currentMinuteProvider);
    final lastSentAt = ref.watch(lastPhotoSentAtProvider).value;
    return ListView.builder(
      padding: AppSpacing.md.all,
      itemCount: lists.length + 1,
      itemBuilder: (context, index) {
        if (index == 0) {
          return Padding(
            padding: AppSpacing.md.bottom,
            child: Text(
              lastSentLabel(lastSentAt, now: now, s: s),
              style: Theme.of(context).coletteTextStyles.small.copyWith(
                color: context.appColor(AppColors.textSecondary),
              ),
            ),
          );
        }
        return Padding(
          padding: AppSpacing.sm.bottom,
          child: _ListCard(list: lists[index - 1]),
        );
      },
    );
  }
}

/// Carte d'une liste : appui pour envoyer (ou éditer si vide), bouton d'édition.
class _ListCard extends ConsumerWidget {
  const _ListCard({required this.list});

  final BroadcastList list;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final s = S.of(context);
    final styles = Theme.of(context).coletteTextStyles;
    final secondary = context.appColor(AppColors.textSecondary);
    return ColetteCardSurface(
      onTap: () => list.recipients.isEmpty
          ? showBroadcastListEditor(context, list.id)
          : startPhotoSend(context, ref, list),
      child: Row(
        spacing: AppSpacing.sm.value,
        children: [
          Icon(Icons.group_outlined, color: context.appColor(AppColors.primary)),
          Expanded(
            child: Column(
              crossAxisAlignment: .start,
              children: [
                Text(list.name, style: styles.bodyMedium),
                Text(
                  s.photosRecipientCount(list.recipients.length),
                  style: styles.small.copyWith(color: secondary),
                ),
              ],
            ),
          ),
          IconButton(
            tooltip: s.photosEditList,
            icon: Icon(Icons.edit_outlined, color: secondary),
            onPressed: () => showBroadcastListEditor(context, list.id),
          ),
        ],
      ),
    );
  }
}
```

- [ ] **Step 5 :** relancer le test — Expected : PASS. Vérifier que chaque fichier fait moins de 300 lignes (`wc -l lib/features/photo_sharing/presentation/**/*.dart`).

- [ ] **Step 6 : commit**

```bash
dart format lib test && dart analyze
git add lib/features/photo_sharing/presentation/widgets/list_name_dialog.dart lib/features/photo_sharing/presentation/widgets/broadcast_list_editor_sheet.dart lib/features/photo_sharing/presentation/pages/photos_page.dart test/features/photo_sharing/presentation/photos_page_test.dart
git commit -m "feat: page Photos, création et édition des listes de diffusion"
```

---

### Task 12 : interrupteur dans Paramètres et PhotoReminderGate

**Files:**
- Create: `lib/features/photo_sharing/presentation/widgets/photo_reminder_switch.dart`
- Create: `lib/app/photo_reminder_gate.dart`
- Modify: `lib/features/baby/presentation/pages/settings_page.dart`, `lib/app/colette_app.dart`
- Test: `test/features/photo_sharing/presentation/photo_reminder_switch_test.dart`, `test/app/photo_reminder_gate_test.dart`

- [ ] **Step 1 : tests rouges.**

`photo_reminder_switch_test.dart` :

```dart
import 'package:colette/core/clock/app_clock.dart';
import 'package:colette/features/baby/presentation/providers/baby_providers.dart';
import 'package:colette/features/photo_sharing/presentation/providers/photo_sharing_providers.dart';
import 'package:colette/features/photo_sharing/presentation/widgets/photo_reminder_switch.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../helpers/fake_photo_sharing_system.dart';
import '../../../helpers/in_memory_photo_sharing_repository.dart';
import '../../../helpers/pump_app.dart';

void main() {
  late InMemoryPhotoSharingRepository repo;
  late FakePhotoSharingSystem system;

  Future<void> pumpSwitch(WidgetTester tester) => pumpApp(
    tester,
    const Scaffold(body: PhotoReminderSwitch()),
    overrides: [
      photoSharingRepositoryProvider.overrideWithValue(repo),
      photoSharingSystemProvider.overrideWithValue(system),
      clockProvider.overrideWithValue(FixedClock(DateTime(2026, 9, 30, 7))),
      babyProfileProvider.overrideWith((ref) => Stream.value(null)),
    ],
  );

  setUp(() {
    repo = InMemoryPhotoSharingRepository();
    system = FakePhotoSharingSystem();
  });

  testWidgets('activé par défaut, désactivation enregistrée', (tester) async {
    await pumpSwitch(tester);
    expect(find.text('Rappel photo quotidien'), findsOneWidget);
    expect(tester.widget<Switch>(find.byType(Switch)).value, isTrue);
    await tester.tap(find.byType(Switch));
    await tester.pumpAndSettle();
    expect(repo.reminderEnabled, isFalse);
    expect(tester.widget<Switch>(find.byType(Switch)).value, isFalse);
    expect(system.syncedDates.single, isEmpty);
  });

  testWidgets('échec d\'écriture : reste activé, message', (tester) async {
    repo.failSaves = true;
    await pumpSwitch(tester);
    await tester.tap(find.byType(Switch));
    await tester.pumpAndSettle();
    expect(tester.widget<Switch>(find.byType(Switch)).value, isTrue);
    expect(find.byType(SnackBar), findsOneWidget);
  });
}
```

`test/app/photo_reminder_gate_test.dart` :

```dart
import 'package:colette/app/colette_app.dart';
import 'package:colette/core/clock/app_clock.dart';
import 'package:colette/features/photo_sharing/domain/use_cases/photo_reminder_schedule.dart';
import 'package:colette/features/photo_sharing/presentation/pages/photos_page.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import '../helpers/colette_app_overrides.dart';
import '../helpers/fake_photo_sharing_system.dart';

void main() {
  Future<void> pumpColetteApp(
    WidgetTester tester, {
    required FakePhotoSharingSystem system,
    String? code = 'ABCDEFGH',
  }) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          ...await coletteAppOverrides(
            householdCode: code,
            deviceId: 'dev-1',
            photoSharingSystem: system,
          ),
          clockProvider.overrideWithValue(FixedClock(DateTime(2026, 9, 30, 7))),
        ],
        child: const ColetteApp(),
      ),
    );
    await tester.pumpAndSettle();
  }

  testWidgets('au démarrage avec un foyer : 14 rappels programmés', (tester) async {
    final system = FakePhotoSharingSystem();
    await pumpColetteApp(tester, system: system);
    expect(system.syncedDates, isNotEmpty);
    expect(system.syncedDates.last, hasLength(photoReminderDays));
  });

  testWidgets('sans foyer : rien n\'est programmé', (tester) async {
    final system = FakePhotoSharingSystem();
    await pumpColetteApp(tester, system: system, code: null);
    expect(system.syncedDates, isEmpty);
  });

  testWidgets('retour au premier plan : reprogrammation', (tester) async {
    final system = FakePhotoSharingSystem();
    await pumpColetteApp(tester, system: system);
    final before = system.syncedDates.length;
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.inactive);
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
    await tester.pumpAndSettle();
    expect(system.syncedDates.length, before + 1);
  });

  testWidgets('lancé par la notification : page Photos', (tester) async {
    final system = FakePhotoSharingSystem(pendingRoute: '/today/photos');
    await pumpColetteApp(tester, system: system);
    expect(find.byType(PhotosPage), findsOneWidget);
  });

  testWidgets('notification ouverte app lancée : page Photos', (tester) async {
    final system = FakePhotoSharingSystem();
    await pumpColetteApp(tester, system: system);
    expect(find.byType(PhotosPage), findsNothing);
    system
      ..pendingRoute = '/today/photos'
      ..signals.add(null);
    await tester.pumpAndSettle();
    expect(find.byType(PhotosPage), findsOneWidget);
  });
}
```

Run: `flutter test test/features/photo_sharing/presentation/photo_reminder_switch_test.dart test/app/photo_reminder_gate_test.dart` — Expected : FAIL.

- [ ] **Step 2 : `photo_reminder_switch.dart`**

```dart
import 'package:colette/core/theme/app_colors.dart';
import 'package:colette/core/theme/design_tokens.dart';
import 'package:colette/core/theme/text_styles.dart';
import 'package:colette/core/ui/failure_message.dart';
import 'package:colette/features/photo_sharing/presentation/providers/photo_reminder.dart';
import 'package:colette/l10n/generated/app_localizations.dart';
import 'package:colette/shared/ui/widgets/colette_card_surface.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fpdart/fpdart.dart';

/// Interrupteur du rappel photo quotidien, propre à cet iPhone.
class PhotoReminderSwitch extends ConsumerWidget {
  const PhotoReminderSwitch({super.key});

  Future<void> _set(BuildContext context, WidgetRef ref, bool enabled) async {
    final s = S.of(context);
    final messenger = ScaffoldMessenger.of(context);
    final result = await ref
        .read(photoReminderEnabledProvider.notifier)
        .set(enabled);
    if (result case Left(:final value)) {
      messenger.showSnackBar(SnackBar(content: Text(failureMessage(value, s))));
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final s = S.of(context);
    final styles = Theme.of(context).coletteTextStyles;
    final enabled = ref.watch(photoReminderEnabledProvider).value ?? true;
    return ColetteCardSurface(
      padding: AppSpacing.sm.all,
      child: SwitchListTile(
        contentPadding: AppSpacing.sm.horizontal,
        title: Text(s.photoReminderSetting, style: styles.body),
        subtitle: Text(
          s.photoReminderSettingSubtitle,
          style: styles.small.copyWith(
            color: context.appColor(AppColors.textSecondary),
          ),
        ),
        value: enabled,
        onChanged: (value) => _set(context, ref, value),
      ),
    );
  }
}
```

Dans `settings_page.dart`, remplacer le bloc :

```dart
          if (device != null) ...[
            SectionHeader(title: s.settingsNotificationsSection),
            NotificationsSection(device: device),
          ],
```

par :

```dart
          SectionHeader(title: s.settingsNotificationsSection),
          if (device != null) ...[
            NotificationsSection(device: device),
            AppSpacing.sm.verticalSpace,
          ],
          const PhotoReminderSwitch(),
```

(import `package:colette/features/photo_sharing/presentation/widgets/photo_reminder_switch.dart`).

- [ ] **Step 3 : `lib/app/photo_reminder_gate.dart`**

```dart
import 'dart:async';

import 'package:colette/app/router/app_router.dart';
import 'package:colette/features/baby/presentation/providers/baby_providers.dart';
import 'package:colette/features/household/presentation/providers/household_providers.dart';
import 'package:colette/features/photo_sharing/presentation/providers/photo_reminder.dart';
import 'package:colette/features/photo_sharing/presentation/providers/photo_sharing_providers.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Reprogramme le rappel photo (démarrage, retour au premier plan, prénom
/// chargé ou modifié) et ouvre la page Photos à l'appui sur la notification.
class PhotoReminderGate extends ConsumerStatefulWidget {
  const PhotoReminderGate({super.key, required this.child});

  final Widget child;

  @override
  ConsumerState<PhotoReminderGate> createState() => _PhotoReminderGateState();
}

class _PhotoReminderGateState extends ConsumerState<PhotoReminderGate>
    with WidgetsBindingObserver {
  StreamSubscription<void>? _routeSignals;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    // Garde le profil chargé (le prénom sert au texte de la notification).
    ref.listenManual(
      babyProfileProvider.select((profile) => profile.value?.name),
      (_, _) => _sync(),
      fireImmediately: true,
    );
    final system = ref.read(photoSharingSystemProvider);
    _routeSignals = system.pendingRouteSignals.listen(
      (_) => unawaited(_openPendingRoute()),
    );
    unawaited(_openPendingRoute());
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) _sync();
  }

  void _sync() {
    if (ref.read(currentHouseholdCodeProvider) == null) return;
    unawaited(ref.read(photoReminderSyncProvider).sync());
  }

  Future<void> _openPendingRoute() async {
    final route = await ref.read(photoSharingSystemProvider).takePendingRoute();
    if (!mounted || route != AppRoutes.todayPhotos) return;
    if (ref.read(currentHouseholdCodeProvider) == null) return;
    ref.read(appRouterProvider).go(AppRoutes.todayPhotos);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _routeSignals?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => widget.child;
}
```

Dans `lib/app/colette_app.dart`, envelopper l'enfant de `HealthSyncGate` :

```dart
            child: HealthSyncGate(
              child: PhotoReminderGate(
                child: child ?? const SizedBox.shrink(),
              ),
            ),
```

(import `package:colette/app/photo_reminder_gate.dart`).

- [ ] **Step 4 :** relancer les deux tests — Expected : PASS. Si la notification au démarrage arrive avant que le routeur ait quitté le splash (page Photos non trouvée), différer `_openPendingRoute()` initial avec `WidgetsBinding.instance.addPostFrameCallback`, comme `NotificationsGate`, et le noter dans le rapport.

- [ ] **Step 5 :** `flutter test test/features/baby test/app` — Expected : PASS (la page Paramètres affiche maintenant l'en-tête Notifications même sans appareil enregistré ; adapter une attente existante seulement si elle vérifiait son absence).

- [ ] **Step 6 : commit**

```bash
dart format lib test && dart analyze
git add lib/features/photo_sharing/presentation/widgets/photo_reminder_switch.dart lib/app/photo_reminder_gate.dart lib/app/colette_app.dart lib/features/baby/presentation/pages/settings_page.dart test/features/photo_sharing/presentation/photo_reminder_switch_test.dart test/app/photo_reminder_gate_test.dart
git commit -m "feat: rappel photo quotidien, interrupteur et ouverture depuis la notification"
```

---

### Task 13 : vérification complète et simulateur

**Files:** aucun nouveau (correctifs éventuels dans des commits `fix:` séparés).

- [ ] **Step 1 : suite complète**

```bash
dart format lib test
dart analyze
flutter test
```

Expected : format sans changement, 0 problème d'analyse, tous les tests verts.

- [ ] **Step 2 : build simulateur**

Run: `flutter build ios --simulator --debug` — Expected : build OK.

- [ ] **Step 3 : parcours sur simulateur** (iPhone 17 Pro déjà démarré ; installer `build/ios/iphonesimulator/Runner.app` par `xcrun simctl install booted …` puis lancer `fr.montet.colette` — vérifier l'identifiant avec `plutil -extract CFBundleIdentifier raw build/ios/iphonesimulator/Runner.app/Info.plist`). Vérifier, en clair et en sombre :
  1. carte « Photos » sur Aujourd'hui, « Aucune photo envoyée pour l'instant » ;
  2. page Photos : état vide, création d'une liste, sélecteur de contacts Apple (contacts de démo du simulateur), contact à plusieurs numéros → choix du numéro ;
  3. glisser pour retirer une personne ; renommer ; supprimer ;
  4. « Choisir dans la galerie » : sélection multiple, vignettes dans la feuille d'envoi ;
  5. « Prendre une photo » : message « L'appareil photo n'est pas disponible. » (pas de caméra sur simulateur) ;
  6. « Envoyer » : message « Messages n'est pas disponible sur cet appareil. » (attendu sur simulateur) ;
  7. Paramètres › Notifications : interrupteur « Rappel photo quotidien » ;
  8. notification : non vérifiable rapidement sur simulateur (heure aléatoire, `simctl push` ne produit que des notifications distantes). À vérifier sur iPhone : interrupteur actif, attendre la notification du jour, l'ouvrir → page Photos ; faire un envoi le matin → pas de notification ce jour-là.

Noter dans le rapport ce qui n'a pas pu être vérifié sur simulateur : envoi réel via Messages, appareil photo, appui sur la notification.

- [ ] **Step 4 :** si des correctifs ont été nécessaires, les committer séparément (`fix: …`), puis relancer le Step 1.
