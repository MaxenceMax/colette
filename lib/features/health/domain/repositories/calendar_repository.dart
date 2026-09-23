import 'package:colette/core/result/failure.dart';
import 'package:colette/features/health/domain/entities/calendar_event.dart';
import 'package:colette/features/health/domain/entities/device_calendar.dart';
import 'package:fpdart/fpdart.dart';

/// Accès au Calendrier iOS de cet iPhone.
abstract interface class CalendarRepository {
  /// Demande l'accès complet ; `false` si refusé.
  Future<Either<Failure, bool>> requestAccess();

  Future<Either<Failure, List<DeviceCalendar>>> listCalendars();

  /// Événements Colette (URL `colette://rdv/…`) du calendrier entre [from] et [to].
  Future<Either<Failure, List<CalendarEvent>>> findEvents(
    String calendarId, {
    required DateTime from,
    required DateTime to,
  });

  /// Crée l'événement, ou remplace celui de [eventId] ; renvoie son identifiant.
  Future<Either<Failure, String>> upsertEvent(
    String calendarId, {
    String? eventId,
    required CalendarEventDraft draft,
  });

  /// Supprime l'événement ; sans erreur s'il n'existe plus.
  Future<Either<Failure, void>> deleteEvent(String calendarId, String eventId);
}
