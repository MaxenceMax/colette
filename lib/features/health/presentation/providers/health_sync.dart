import 'dart:developer' as developer;

import 'package:colette/core/clock/app_clock.dart';
import 'package:colette/core/result/failure.dart';
import 'package:colette/features/baby/presentation/providers/baby_providers.dart';
import 'package:colette/features/health/domain/entities/calendar_action.dart';
import 'package:colette/features/health/domain/entities/medical_visit.dart';
import 'package:colette/features/health/domain/use_cases/compute_medical_reminder_snapshot.dart';
import 'package:colette/features/health/domain/use_cases/compute_medical_timeline.dart';
import 'package:colette/features/health/domain/use_cases/reconcile_calendar.dart';
import 'package:colette/features/health/presentation/providers/health_providers.dart';
import 'package:colette/features/health/presentation/providers/selected_calendar.dart';
import 'package:colette/features/health/presentation/widgets/health_labels.dart';
import 'package:colette/features/household/presentation/providers/household_providers.dart';
import 'package:colette/l10n/generated/app_localizations.dart';
import 'package:flutter/widgets.dart';
import 'package:fpdart/fpdart.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'health_sync.g.dart';

/// Réécrit le snapshot des rappels santé et réconcilie le calendrier de cet iPhone.
abstract interface class HealthSync {
  Future<void> sync();
}

/// Ne fait rien ; pour les tests.
final class NoopHealthSync implements HealthSync {
  const NoopHealthSync();

  @override
  Future<void> sync() async {}
}

/// Relit Firestore (pas les providers, qui peuvent être détruits pendant l'attente).
/// Best-effort : une erreur est journalisée, jamais propagée.
final class FirestoreHealthSync implements HealthSync {
  const FirestoreHealthSync(this._ref);

  final Ref _ref;

  @override
  Future<void> sync() async {
    final code = _ref.read(currentHouseholdCodeProvider);
    if (code == null) return;
    try {
      final profile = await _ref
          .read(babyRepositoryProvider)
          .watchProfile(code)
          .first;
      if (profile == null) return;
      final medical = _ref.read(medicalRepositoryProvider);
      final visits = await medical.watchVisits(code).first;
      final now = _ref.read(clockProvider).now();
      final timeline = const ComputeMedicalTimeline()(
        birthDate: profile.birthDate,
        visits: visits,
        now: now,
      );
      await medical.saveReminderSnapshot(
        code,
        const ComputeMedicalReminderSnapshot()(timeline: timeline, now: now),
      );
      await _syncCalendar(visits, profile.name, now);
    } catch (e, stackTrace) {
      developer.log(
        'Health sync failed',
        error: e,
        stackTrace: stackTrace,
        name: 'colette',
      );
    }
  }

  Future<void> _syncCalendar(
    List<MedicalVisit> visits,
    String babyName,
    DateTime now,
  ) async {
    final choice = _ref.read(selectedCalendarProvider);
    if (choice == null) return;
    final calendar = _ref.read(calendarRepositoryProvider);
    final found = await calendar.findEvents(
      choice.id,
      from: ReconcileCalendar.windowStart(now),
      to: ReconcileCalendar.windowEnd(now),
    );
    if (found case Left(:final value)) {
      await _failed(value);
      return;
    }
    final events = found.getOrElse((_) => const []);
    final s = lookupS(const Locale('fr'));
    final actions = const ReconcileCalendar()(
      visits: visits,
      events: events,
      titleOf: (id) => HealthLabels.eventTitle(s, id, babyName),
      now: now,
    );
    for (final action in actions) {
      final Future<Either<Failure, Object?>> pending = switch (action) {
        CreateCalendarEvent(:final draft) => calendar.upsertEvent(
          choice.id,
          draft: draft,
        ),
        UpdateCalendarEvent(:final eventId, :final draft) =>
          calendar.upsertEvent(choice.id, eventId: eventId, draft: draft),
        DeleteCalendarEvent(:final eventId) => calendar.deleteEvent(
          choice.id,
          eventId,
        ),
      };
      if ((await pending) case Left(:final value)) {
        await _failed(value);
        return;
      }
    }
  }

  /// Calendrier disparu : on oublie le choix. Autre échec : journalisé.
  Future<void> _failed(Failure failure) async {
    if (failure == const CalendarFailure(CalendarReason.calendarNotFound)) {
      await _ref.read(selectedCalendarProvider.notifier).clear();
    } else {
      developer.log('Calendar sync failed: $failure', name: 'colette');
    }
  }
}

/// `keepAlive` : lu avant un `await` par des contrôleurs autoDispose.
@Riverpod(keepAlive: true)
HealthSync healthSync(Ref ref) => FirestoreHealthSync(ref);
