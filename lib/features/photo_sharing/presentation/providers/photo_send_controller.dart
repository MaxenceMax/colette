import 'dart:developer' as developer;

import 'package:colette/core/clock/app_clock.dart';
import 'package:colette/features/photo_sharing/domain/entities/broadcast_list.dart';
import 'package:colette/features/photo_sharing/domain/entities/send_report.dart';
import 'package:colette/features/photo_sharing/presentation/providers/broadcast_lists.dart';
import 'package:colette/features/photo_sharing/presentation/providers/photo_reminder.dart';
import 'package:colette/features/photo_sharing/presentation/providers/photo_sharing_providers.dart';
import 'package:fpdart/fpdart.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'photo_send_controller.g.dart';

/// Envoi des photos à chaque personne d'une liste, une feuille Messages par
/// personne ; `AsyncData(bilan)` à la fin, `null` avant tout envoi. La date
/// d'envoi (globale et de la liste) et le rappel sont enregistrés même si
/// l'écran a été fermé entre-temps.
@riverpod
class PhotoSendController extends _$PhotoSendController {
  @override
  FutureOr<SendReport?> build() => null;

  /// Envoie [photoPaths] et [body] à chaque personne de [list].
  Future<void> send({
    required BroadcastList list,
    required List<String> photoPaths,
    required String body,
  }) async {
    state = const AsyncLoading();
    // Lus avant toute attente : le Ref peut être détruit pendant l'envoi.
    final system = ref.read(photoSharingSystemProvider);
    final lastSentAt = ref.read(lastPhotoSentAtProvider.notifier);
    final lists = ref.read(broadcastListsProvider.notifier);
    final reminderSync = ref.read(photoReminderSyncProvider);
    final clock = ref.read(clockProvider);
    final result = await system.sendMessages(
      phones: [for (final recipient in list.recipients) recipient.phone],
      photoPaths: photoPaths,
      body: body.trim(),
    );
    await system.discardPhotos(photoPaths);
    if (result case Right(value: SendReport(anySent: true))) {
      final sentAt = clock.now();
      final marked = await lastSentAt.markSent(sentAt);
      if (marked case Left(value: final failure)) {
        developer.log(
          'Photo send date not saved',
          error: failure,
          name: 'colette',
        );
      }
      final listMarked = await lists.markSent(list.id, sentAt);
      if (listMarked case Left(value: final failure)) {
        developer.log(
          'List send date not saved',
          error: failure,
          name: 'colette',
        );
      }
      await reminderSync.sync();
    }
    if (!ref.mounted) return;
    state = switch (result) {
      Left(:final value) => AsyncError(value, StackTrace.current),
      Right(:final value) => AsyncData(value),
    };
  }
}
