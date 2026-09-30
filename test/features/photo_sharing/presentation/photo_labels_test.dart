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
    expect(
      lastSentLabel(null, now: now, s: s),
      "Aucune photo envoyée pour l'instant",
    );
  });

  test("envoi d'hier", () {
    expect(
      lastSentLabel(DateTime(2026, 9, 29, 18, 12), now: now, s: s),
      'Dernier envoi · Hier, 18h12',
    );
  });

  test('bilan : annulés et échecs omis à zéro', () {
    expect(
      sendReportLabel(const SendReport(sent: 2, cancelled: 0, failed: 0), s),
      '2 envoyés',
    );
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
