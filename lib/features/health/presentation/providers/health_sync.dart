import 'dart:async';
import 'dart:developer' as developer;

import 'package:colette/core/clock/app_clock.dart';
import 'package:colette/core/result/failure.dart';
import 'package:colette/features/baby/presentation/providers/baby_providers.dart';
import 'package:colette/features/health/domain/entities/calendar_action.dart';
import 'package:colette/features/health/domain/entities/calendar_choice.dart';
import 'package:colette/features/health/domain/entities/custom_appointment.dart';
import 'package:colette/features/health/domain/entities/medical_visit.dart';
import 'package:colette/features/health/domain/use_cases/compute_medical_reminder_snapshot.dart';
import 'package:colette/features/health/domain/use_cases/compute_medical_timeline.dart';
import 'package:colette/features/health/domain/use_cases/reconcile_calendar.dart';
import 'package:colette/features/health/presentation/labels/health_labels.dart';
import 'package:colette/features/health/presentation/providers/calendar_sync_issue.dart';
import 'package:colette/features/health/presentation/providers/health_providers.dart';
import 'package:colette/features/health/presentation/providers/selected_calendar.dart';
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
/// Les visites viennent du serveur : hors ligne, rien n'est écrit.
/// Best-effort : une erreur est journalisée, jamais propagée.
///
/// Coalesce les appels concurrents : une sync déjà en cours absorbe les
/// suivants et relance exactement une fois à la fin, sans jamais laisser deux
/// passes s'exécuter en parallèle (double création d'événements sinon).
final class FirestoreHealthSync implements HealthSync {
  FirestoreHealthSync(this._ref);

  final Ref _ref;

  Future<void>? _running;
  bool _again = false;

  @override
  Future<void> sync() {
    final running = _running;
    if (running != null) {
      _again = true;
      return running;
    }
    final future = _runExclusive();
    _running = future;
    return future;
  }

  /// Relance tant qu'un appel est arrivé pendant la passe précédente.
  Future<void> _runExclusive() async {
    do {
      _again = false;
      await _doSync();
    } while (_again);
    _running = null;
  }

  Future<void> _doSync() async {
    final code = _ref.read(currentHouseholdCodeProvider);
    if (code == null) return;
    try {
      final profile = await _ref
          .read(babyRepositoryProvider)
          .watchProfile(code)
          .first;
      if (profile == null) return;
      final medical = _ref.read(medicalRepositoryProvider);
      // Jamais le cache : au démarrage à froid, il ignorerait un RDV posé ou
      // déplacé par l'autre iPhone, et la sync l'effacerait du calendrier.
      final fetched = await medical.fetchVisitsFromServer(code);
      final fetchedAppointments = await medical.fetchAppointmentsFromServer(
        code,
      );
      final unreachable = switch ((fetched, fetchedAppointments)) {
        (Left(:final value), _) || (_, Left(:final value)) => value,
        _ => null,
      };
      if (unreachable != null) {
        developer.log(
          'Health sync skipped, server unreachable: ${unreachable.runtimeType}',
          name: 'colette',
        );
        return;
      }
      final visits = fetched.getOrElse((_) => const []);
      final appointments = fetchedAppointments.getOrElse((_) => const []);
      final now = _ref.read(clockProvider).now();
      final timeline = const ComputeMedicalTimeline()(
        birthDate: profile.birthDate,
        visits: visits,
        appointments: appointments,
        now: now,
      );
      final snapshot = const ComputeMedicalReminderSnapshot()(
        timeline: timeline,
        now: now,
      );
      // Le calendrier ne doit pas attendre l'accusé serveur du snapshot.
      unawaited(
        medical.saveReminderSnapshot(code, snapshot).then((result) {
          if (result case Left(:final value)) {
            developer.log(
              'Failed to save reminder snapshot: $value',
              name: 'colette',
            );
          }
        }),
      );
      await _syncCalendar(visits, appointments, profile.name, now);
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
    List<CustomAppointment> appointments,
    String babyName,
    DateTime now,
  ) async {
    final choice = _ref.read(selectedCalendarProvider);
    if (choice == null) {
      // « Calendrier introuvable » explique pourquoi le choix a disparu :
      // l'alerte reste jusqu'au prochain choix.
      if (_ref.read(calendarSyncIssueProvider) !=
          CalendarReason.calendarNotFound) {
        _ref.read(calendarSyncIssueProvider.notifier).clear();
      }
      return;
    }
    final calendar = _ref.read(calendarRepositoryProvider);
    final found = await calendar.findEvents(
      choice.id,
      from: ReconcileCalendar.windowStart(now),
      to: ReconcileCalendar.windowEnd(now),
    );
    if (found case Left(:final value)) {
      await _handleFailure(choice, value);
      return;
    }
    final events = found.getOrElse((_) => const []);
    final s = lookupS(const Locale('fr'));
    final actions = const ReconcileCalendar()(
      visits: visits,
      appointments: appointments,
      events: events,
      titleOf: (id) => HealthLabels.eventTitle(s, id, babyName),
      titleOfAppointment: (a) => s.healthEventTitle(a.title, babyName),
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
        final stop = await _handleFailure(choice, value);
        if (stop) return;
      }
    }
    _ref.read(calendarSyncIssueProvider.notifier).clear();
  }

  /// Calendrier disparu : on oublie le choix, s'il n'a pas changé entre-temps,
  /// et on le signale. Accès refusé : on le signale et on arrête. Autre échec
  /// (`io`, inconnu) : on journalise et on continue avec les actions suivantes.
  ///
  /// Renvoie `true` si la boucle des actions doit s'arrêter.
  Future<bool> _handleFailure(CalendarChoice choice, Failure failure) async {
    switch (failure) {
      case CalendarFailure(reason: CalendarReason.calendarNotFound):
        if (_ref.read(selectedCalendarProvider)?.id == choice.id) {
          _ref
              .read(calendarSyncIssueProvider.notifier)
              .report(CalendarReason.calendarNotFound);
          await _ref.read(selectedCalendarProvider.notifier).clear();
        }
        return true;
      case CalendarFailure(reason: CalendarReason.accessDenied):
        developer.log('Calendar sync failed: $failure', name: 'colette');
        _ref
            .read(calendarSyncIssueProvider.notifier)
            .report(CalendarReason.accessDenied);
        return true;
      default:
        developer.log('Calendar sync failed: $failure', name: 'colette');
        return false;
    }
  }
}

/// `keepAlive` : lu avant un `await` par des contrôleurs autoDispose.
@Riverpod(keepAlive: true)
HealthSync healthSync(Ref ref) => FirestoreHealthSync(ref);
