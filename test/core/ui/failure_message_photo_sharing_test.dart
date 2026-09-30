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

  String message(PhotoSharingReason reason) =>
      failureMessage(PhotoSharingFailure(reason), s);

  test('Messages indisponible', () {
    expect(
      message(PhotoSharingReason.messagesUnavailable),
      "Messages n'est pas disponible sur cet appareil.",
    );
  });

  test('appareil photo indisponible', () {
    expect(
      message(PhotoSharingReason.cameraUnavailable),
      "L'appareil photo n'est pas disponible.",
    );
  });

  test('io → préparation impossible', () {
    expect(
      message(PhotoSharingReason.io),
      'Impossible de préparer les photos.',
    );
  });

  test('busy → autre action en cours', () {
    expect(message(PhotoSharingReason.busy), 'Une autre action est en cours.');
  });

  test('égalité par raison', () {
    expect(
      const PhotoSharingFailure(PhotoSharingReason.io),
      const PhotoSharingFailure(PhotoSharingReason.io),
    );
  });
}
