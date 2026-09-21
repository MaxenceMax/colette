import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:colette/core/result/failure.dart';
import 'package:colette/core/result/failure_mapper.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('guard', () {
    test('renvoie Right quand l\'action réussit', () async {
      final result = await guard(() async => 42);
      expect(result.getRight().toNullable(), 42);
    });

    test('convertit FirebaseException unavailable en NetworkFailure', () async {
      final result = await guard<int>(
        () async => throw FirebaseException(
          plugin: 'cloud_firestore',
          code: 'unavailable',
        ),
      );
      expect(result.getLeft().toNullable(), isA<NetworkFailure>());
    });

    test('convertit FirebaseException not-found en NotFoundFailure', () async {
      final result = await guard<int>(
        () async => throw FirebaseException(
          plugin: 'cloud_firestore',
          code: 'not-found',
        ),
      );
      expect(result.getLeft().toNullable(), isA<NotFoundFailure>());
    });

    test('convertit toute autre exception en UnknownFailure', () async {
      final result = await guard<int>(() async => throw StateError('boom'));
      expect(result.getLeft().toNullable(), isA<UnknownFailure>());
    });

    test(
      'convertit deadline-exceeded et network-request-failed en NetworkFailure',
      () async {
        for (final code in ['deadline-exceeded', 'network-request-failed']) {
          final result = await guard<int>(
            () async =>
                throw FirebaseException(plugin: 'cloud_firestore', code: code),
          );
          expect(
            result.getLeft().toNullable(),
            isA<NetworkFailure>(),
            reason: code,
          );
        }
      },
    );
  });
}
