import 'dart:ui' show Locale;

import 'package:colette/l10n/generated/app_localizations.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  late S s;

  setUpAll(() async {
    s = await S.delegate.load(const Locale('fr'));
  });

  test('photosSendTo : zéro, singulier, pluriel', () {
    expect(s.photosSendTo(0), 'Aucune personne dans la liste');
    expect(s.photosSendTo(1), 'Envoyer à 1 personne');
    expect(s.photosSendTo(3), 'Envoyer à 3 personnes');
  });

  test('bilan d\'envoi à zéro', () {
    expect(s.photosReportCancelled(0), 'Aucun annulé');
    expect(s.photosReportFailed(0), 'Aucun échec');
  });

  test('photosRecipientCount à zéro', () {
    expect(s.photosRecipientCount(0), 'Aucune personne');
  });
}
