import 'package:colette/core/result/failure.dart';
import 'package:colette/features/teeth/domain/entities/tooth_record.dart';
import 'package:colette/features/teeth/domain/use_cases/validate_tooth_record.dart';
import 'package:flutter_test/flutter_test.dart';

import '../teeth_factories.dart';

void main() {
  const validate = ValidateToothRecord();
  final birth = DateTime(2026, 9, 1, 8);
  final now = DateTime(2027, 3, 10, 9);

  ValidationReason? reasonOf(ToothRecord record) => validate(
    record,
    birthDate: birth,
    now: now,
  ).fold((failure) => failure.reason, (_) => null);

  ToothRecord valid(ToothRecord record) => validate(
    record,
    birthDate: birth,
    now: now,
  ).fold((failure) => fail('invalide : ${failure.reason}'), (r) => r);

  test('accepte une sortie puis une chute le même jour', () {
    final day = DateTime(2027, 1, 10, 12);
    expect(reasonOf(makeTooth(71, eruptedAt: day, lostAt: day)), isNull);
    expect(
      reasonOf(
        makeTooth(
          71,
          eruptedAt: DateTime(2027, 1, 10, 18),
          lostAt: DateTime(2027, 1, 10, 8),
        ),
      ),
      isNull,
    );
  });

  test('accepte une dent sans date', () {
    expect(reasonOf(makeTooth(71)), isNull);
  });

  test('accepte la date du jour enregistrée à midi, le matin', () {
    expect(
      reasonOf(makeTooth(71, eruptedAt: DateTime(2027, 3, 10, 12))),
      isNull,
    );
  });

  test('accepte le jour de la naissance', () {
    expect(reasonOf(makeTooth(71, eruptedAt: DateTime(2026, 9, 1, 0))), isNull);
  });

  test('refuse une date avant la naissance', () {
    expect(
      reasonOf(makeTooth(71, eruptedAt: DateTime(2026, 8, 31, 12))),
      ValidationReason.toothDateBeforeBirth,
    );
    expect(
      reasonOf(makeTooth(71, lostAt: DateTime(2026, 8, 31, 12))),
      ValidationReason.toothDateBeforeBirth,
    );
  });

  test('refuse une date après aujourd\'hui', () {
    expect(
      reasonOf(makeTooth(71, eruptedAt: DateTime(2027, 3, 11, 12))),
      ValidationReason.toothDateInFuture,
    );
    expect(
      reasonOf(makeTooth(71, lostAt: DateTime(2027, 3, 11, 12))),
      ValidationReason.toothDateInFuture,
    );
  });

  test('refuse une chute avant la sortie', () {
    expect(
      reasonOf(
        makeTooth(
          71,
          eruptedAt: DateTime(2027, 1, 10, 12),
          lostAt: DateTime(2027, 1, 9, 12),
        ),
      ),
      ValidationReason.toothLostBeforeErupted,
    );
  });

  test('refuse une chute sur une dent définitive', () {
    expect(
      reasonOf(makeTooth(11, lostAt: DateTime(2027, 1, 10, 12))),
      ValidationReason.toothLossOnPermanent,
    );
  });

  test('rogne la note ; une note vide devient null', () {
    expect(valid(makeTooth(71, note: '  nuit agitée ')).note, 'nuit agitée');
    expect(valid(makeTooth(71, note: '   ')).note, isNull);
  });
}
