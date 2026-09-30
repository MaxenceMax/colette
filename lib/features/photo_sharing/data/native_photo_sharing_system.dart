import 'dart:async';
import 'dart:developer' as developer;

import 'package:colette/core/result/failure.dart';
import 'package:colette/features/photo_sharing/domain/entities/recipient.dart';
import 'package:colette/features/photo_sharing/domain/entities/send_report.dart';
import 'package:colette/features/photo_sharing/domain/repositories/photo_sharing_system.dart';
import 'package:flutter/services.dart';
import 'package:fpdart/fpdart.dart';

const _reasons = {
  'messagesUnavailable': PhotoSharingReason.messagesUnavailable,
  'cameraUnavailable': PhotoSharingReason.cameraUnavailable,
  'busy': PhotoSharingReason.busy,
  'io': PhotoSharingReason.io,
};

/// Pont Swift `colette/photo-sharing` (voir `PhotoSharingPlugin.swift`).
class NativePhotoSharingSystem implements PhotoSharingSystem {
  NativePhotoSharingSystem(this._channel) {
    _channel.setMethodCallHandler(_onNativeCall);
  }

  /// Nom du canal, partagé avec `PhotoSharingPlugin.swift`.
  static const channelName = 'colette/photo-sharing';

  final MethodChannel _channel;
  final _routeSignals = StreamController<void>.broadcast();

  Future<Object?> _onNativeCall(MethodCall call) async {
    if (call.method == 'routePending') _routeSignals.add(null);
    return null;
  }

  @override
  Stream<void> get pendingRouteSignals => _routeSignals.stream;

  @override
  Future<Either<Failure, Recipient?>> pickContact() => _call(() async {
    final map = await _channel.invokeMapMethod<String, Object?>('pickContact');
    if (map == null) return null;
    return Recipient(
      name: map['name']! as String,
      phone: map['phone']! as String,
    );
  });

  @override
  Future<Either<Failure, List<String>>> takePhoto() => _paths('takePhoto');

  @override
  Future<Either<Failure, List<String>>> pickPhotos() => _paths('pickPhotos');

  @override
  Future<Either<Failure, SendReport>> sendMessages({
    required List<String> phones,
    required List<String> photoPaths,
    required String body,
  }) => _call(() async {
    final map = await _channel.invokeMapMethod<String, Object?>(
      'sendMessages',
      {'phones': phones, 'photoPaths': photoPaths, 'body': body},
    );
    return SendReport(
      sent: map!['sent']! as int,
      cancelled: map['cancelled']! as int,
      failed: map['failed']! as int,
    );
  });

  @override
  Future<void> discardPhotos(List<String> photoPaths) =>
      _quiet('discardPhotos', {'photoPaths': photoPaths});

  @override
  Future<void> syncReminders({
    required List<DateTime> dates,
    required String title,
    required String body,
  }) => _quiet('syncReminders', {
    'dates': [for (final date in dates) date.millisecondsSinceEpoch],
    'title': title,
    'body': body,
  });

  @override
  Future<String?> takePendingRoute() async {
    try {
      return await _channel.invokeMethod<String>('takePendingRoute');
    } on Exception catch (error, stackTrace) {
      _log('takePendingRoute', error, stackTrace);
      return null;
    }
  }

  Future<Either<Failure, List<String>>> _paths(String method) => _call(
    () async => await _channel.invokeListMethod<String>(method) ?? const [],
  );

  /// Appel dont l'échec est seulement logué.
  Future<void> _quiet(String method, Object? arguments) async {
    try {
      await _channel.invokeMethod<void>(method, arguments);
    } on Exception catch (error, stackTrace) {
      _log(method, error, stackTrace);
    }
  }

  /// Codes du canal → [PhotoSharingFailure], sinon [UnknownFailure] logué.
  Future<Either<Failure, T>> _call<T>(Future<T> Function() action) async {
    try {
      return right(await action());
    } catch (error, stackTrace) {
      if (error is PlatformException) {
        final reason = _reasons[error.code];
        if (reason != null) return left(PhotoSharingFailure(reason));
      }
      _log('appel natif', error, stackTrace);
      return left(UnknownFailure(error, stackTrace));
    }
  }

  void _log(String what, Object error, StackTrace stackTrace) => developer.log(
    'colette/photo-sharing $what a échoué',
    name: 'colette',
    error: error,
    stackTrace: stackTrace,
  );
}
