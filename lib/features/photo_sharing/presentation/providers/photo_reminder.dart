import 'dart:developer' as developer;

import 'package:colette/core/clock/app_clock.dart';
import 'package:colette/core/result/failure.dart';
import 'package:colette/core/result/no_retry.dart';
import 'package:colette/features/baby/presentation/providers/baby_providers.dart';
import 'package:colette/features/household/presentation/providers/household_providers.dart';
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

/// Reprogramme les notifications du rappel photo en relisant le stockage
/// (interrupteur, dernier envoi) et le profil du bébé dans Firestore, et non
/// depuis des providers qui peuvent ne pas être chargés. Best-effort : une
/// erreur est journalisée, jamais propagée.
class PhotoReminderSync {
  PhotoReminderSync(this._ref);

  final Ref _ref;

  Future<void> sync() async {
    try {
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
      final name = await _babyName();
      await _ref
          .read(photoSharingSystemProvider)
          .syncReminders(
            dates: dates,
            title: s.photoReminderTitle,
            body: name == null || name.isEmpty
                ? s.photoReminderBodyNoName
                : s.photoReminderBody(name),
          );
    } catch (error, stackTrace) {
      developer.log(
        'Photo reminder sync failed',
        error: error,
        stackTrace: stackTrace,
        name: 'colette',
      );
    }
  }

  /// Prénom du bébé du foyer courant ; `null` sans foyer ou si illisible.
  Future<String?> _babyName() async {
    final code = _ref.read(currentHouseholdCodeProvider);
    if (code == null) return null;
    try {
      final profile = await _ref
          .read(babyRepositoryProvider)
          .watchProfile(code)
          .first;
      return profile?.name;
    } catch (error, stackTrace) {
      developer.log(
        'Baby profile unreadable for photo reminder',
        error: error,
        stackTrace: stackTrace,
        name: 'colette',
      );
      return null;
    }
  }
}

/// Synchronisation du rappel photo.
@Riverpod(keepAlive: true)
PhotoReminderSync photoReminderSync(Ref ref) => PhotoReminderSync(ref);
