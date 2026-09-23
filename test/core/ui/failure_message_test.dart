import 'package:colette/core/result/failure.dart';
import 'package:colette/core/ui/failure_message.dart';
import 'package:colette/l10n/generated/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  late S s;

  setUpAll(() async => s = await S.delegate.load(const Locale('fr')));

  test('chaque raison de validation a un message distinct et non vide', () {
    final messages = ValidationReason.values
        .map((reason) => failureMessage(ValidationFailure(reason), s))
        .toList();
    expect(messages.every((m) => m.isNotEmpty), isTrue);
    expect(messages.toSet().length, ValidationReason.values.length);
  });

  test('les autres échecs ont leur message', () {
    expect(failureMessage(const NetworkFailure(), s), s.errorNetwork);
    expect(failureMessage(const NotFoundFailure(), s), s.errorNotFound);
    expect(failureMessage(const UnknownFailure('x'), s), s.errorUnknown);
    expect(failureMessage(Exception('x'), s), s.errorUnknown);
  });

  test('chevauchement de sommeil', () {
    expect(
      failureMessage(
        SleepOverlapFailure(
          startAt: DateTime(2026, 9, 23, 14, 10),
          endAt: DateTime(2026, 9, 23, 15, 30),
        ),
        s,
      ),
      'Chevauche le sommeil de 14h10 à 15h30.',
    );
    expect(
      failureMessage(
        SleepOverlapFailure(startAt: DateTime(2026, 9, 23, 14, 10)),
        s,
      ),
      'Chevauche le sommeil en cours depuis 14h10.',
    );
    expect(
      failureMessage(const ValidationFailure(ValidationReason.sleepTooLong), s),
      'Un sommeil ne peut pas dépasser 24 h.',
    );
  });
}
