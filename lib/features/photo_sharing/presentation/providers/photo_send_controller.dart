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

  /// Envoie [photoPaths] et [body] à chaque personne de [list].
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
