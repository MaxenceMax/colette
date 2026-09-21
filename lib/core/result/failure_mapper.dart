import 'dart:developer' as developer;

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:colette/core/result/failure.dart';
import 'package:fpdart/fpdart.dart';

const _networkCodes = {
  'unavailable',
  'deadline-exceeded',
  'network-request-failed',
};

/// Exécute [action] et convertit toute exception en [Failure].
Future<Either<Failure, T>> guard<T>(Future<T> Function() action) async {
  try {
    return right(await action());
  } on FirebaseException catch (e, stackTrace) {
    if (_networkCodes.contains(e.code)) return left(const NetworkFailure());
    if (e.code == 'not-found') return left(const NotFoundFailure());
    developer.log(
      'Firebase error',
      error: e,
      stackTrace: stackTrace,
      name: 'colette',
    );
    return left(UnknownFailure(e, stackTrace));
  } catch (e, stackTrace) {
    developer.log(
      'Unexpected error',
      error: e,
      stackTrace: stackTrace,
      name: 'colette',
    );
    return left(UnknownFailure(e, stackTrace));
  }
}
