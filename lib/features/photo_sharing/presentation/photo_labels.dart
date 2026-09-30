import 'package:colette/core/dates/day_label.dart';
import 'package:colette/core/dates/time_format.dart';
import 'package:colette/features/photo_sharing/domain/entities/send_report.dart';
import 'package:colette/l10n/generated/app_localizations.dart';

/// « Dernier envoi · Hier, 18h12 », ou l'absence d'envoi.
String lastSentLabel(DateTime? sentAt, {required DateTime now, required S s}) =>
    sentAt == null ? s.photosNeverSent : _sentLabel(sentAt, now, s);

/// Dernier envoi d'une liste : « Dernier envoi · Hier, 18h12 » ou
/// « Aucun envoi ».
String listLastSentLabel(
  DateTime? sentAt, {
  required DateTime now,
  required S s,
}) => sentAt == null ? s.photosListNeverSent : _sentLabel(sentAt, now, s);

String _sentLabel(DateTime sentAt, DateTime now, S s) => s.photosLastSent(
  dayLabel(sentAt, now: now, s: s),
  formatHourMinute(sentAt),
);

/// « 1 envoyé · 1 annulé · 2 en échec » ; annulés et échecs omis à zéro.
String sendReportLabel(SendReport report, S s) => [
  s.photosReportSent(report.sent),
  if (report.cancelled > 0) s.photosReportCancelled(report.cancelled),
  if (report.failed > 0) s.photosReportFailed(report.failed),
].join(' · ');
