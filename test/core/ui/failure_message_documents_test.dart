import 'dart:ui' show Locale;

import 'package:colette/core/result/failure.dart';
import 'package:colette/core/ui/failure_message.dart';
import 'package:colette/l10n/generated/app_localizations.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  late S s;

  setUpAll(() async {
    s = await S.delegate.load(const Locale('fr'));
  });

  test('noFolder et accessDenied → message d\'accès', () {
    const expected = "Colette n'a pas accès à ce dossier";
    expect(
      failureMessage(const DocumentsFailure(DocumentsReason.noFolder), s),
      expected,
    );
    expect(
      failureMessage(const DocumentsFailure(DocumentsReason.accessDenied), s),
      expected,
    );
  });

  test('io → message d\'écriture', () {
    expect(
      failureMessage(const DocumentsFailure(DocumentsReason.io), s),
      "Impossible d'enregistrer le document",
    );
  });

  test('cancelled → message générique (jamais affiché par l\'UI)', () {
    expect(
      failureMessage(const DocumentsFailure(DocumentsReason.cancelled), s),
      'Une erreur est survenue.',
    );
  });
}
