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

  test('busy et io → préparation impossible', () {
    const expected = 'Impossible de préparer les photos.';
    expect(message(PhotoSharingReason.busy), expected);
    expect(message(PhotoSharingReason.io), expected);
  });

  test('égalité par raison', () {
    expect(
      const PhotoSharingFailure(PhotoSharingReason.io),
      const PhotoSharingFailure(PhotoSharingReason.io),
    );
  });
}
