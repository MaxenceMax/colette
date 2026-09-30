import 'dart:async';
import 'dart:developer' as developer;

import 'package:colette/core/clock/app_clock.dart';
import 'package:colette/core/result/failure.dart';
import 'package:colette/core/result/no_retry.dart';
import 'package:colette/features/baby/domain/entities/baby_profile.dart';
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
/// depuis des providers qui peuvent ne pas être chargés. Sans foyer, retire
/// les rappels. Les synchronisations passent en file : une plus ancienne ne
/// se termine jamais après une plus récente. Best-effort : une erreur est
/// journalisée, jamais propagée.
class PhotoReminderSync {
  PhotoReminderSync(this._ref);

  final Ref _ref;

  /// File des synchronisations : chacune attend la fin de la précédente.
  Future<void> _queue = Future.value();

  /// Lecture du profil en cours, annulée (avec son délai) à la destruction.
  StreamSubscription<BabyProfile?>? _profileRead;

  /// Abandonne la lecture du profil en cours.
  void dispose() => unawaited(_profileRead?.cancel());

  Future<void> sync() => _queue = _queue.then((_) => _syncNow());

  Future<void> _syncNow() async {
    try {
      final s = lookupS(const Locale('fr'));
      final dates = await _plannedDates();
      final name = dates.isEmpty ? null : await _babyName();
      // Le foyer a pu être quitté pendant les lectures.
      final hasHousehold = _ref.read(currentHouseholdCodeProvider) != null;
      await _ref
          .read(photoSharingSystemProvider)
          .syncReminders(
            dates: hasHousehold ? dates : const [],
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

  /// Dates à programmer ; aucune sans foyer ou rappel désactivé.
  Future<List<DateTime>> _plannedDates() async {
    if (_ref.read(currentHouseholdCodeProvider) == null) return const [];
    final repository = _ref.read(photoSharingRepositoryProvider);
    final enabled = (await repository.loadReminderEnabled()).getOrElse(
      (_) => true,
    );
    if (!enabled) return const [];
    final lastSentAt = (await repository.loadLastSentAt()).getOrElse(
      (_) => null,
    );
    return planPhotoReminders(
      now: _ref.read(clockProvider).now(),
      lastSentAt: lastSentAt,
    );
  }

  /// Prénom du bébé du foyer courant ; `null` sans foyer, si illisible ou
  /// sans réponse sous 5 s.
  Future<String?> _babyName() async {
    final code = _ref.read(currentHouseholdCodeProvider);
    if (code == null) return null;
    try {
      return (await _firstProfile(code))?.name;
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

  /// Premier profil émis, ou [TimeoutException] au bout de 5 s. Le délai
  /// vit dans l'abonnement : [dispose] l'annule avec la lecture.
  Future<BabyProfile?> _firstProfile(String code) {
    final completer = Completer<BabyProfile?>();
    void finish(void Function() complete) {
      if (completer.isCompleted) return;
      complete();
      unawaited(_profileRead?.cancel());
      _profileRead = null;
    }

    _profileRead = _ref
        .read(babyRepositoryProvider)
        .watchProfile(code)
        .timeout(const Duration(seconds: 5))
        .listen(
          (profile) => finish(() => completer.complete(profile)),
          onError: (Object error, StackTrace stackTrace) =>
              finish(() => completer.completeError(error, stackTrace)),
          onDone: () => finish(() => completer.complete(null)),
        );
    return completer.future;
  }
}

/// Synchronisation du rappel photo.
@Riverpod(keepAlive: true)
PhotoReminderSync photoReminderSync(Ref ref) {
  final sync = PhotoReminderSync(ref);
  ref.onDispose(sync.dispose);
  return sync;
}
