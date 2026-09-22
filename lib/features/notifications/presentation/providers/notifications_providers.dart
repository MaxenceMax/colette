import 'dart:async';
import 'dart:developer' as developer;

import 'package:colette/core/firebase/firebase_providers.dart';
import 'package:colette/core/result/failure.dart';
import 'package:colette/core/result/failure_mapper.dart';
import 'package:colette/features/household/domain/entities/device_info.dart';
import 'package:colette/features/household/presentation/providers/household_providers.dart';
import 'package:colette/features/notifications/data/firebase_push_token_source.dart';
import 'package:colette/features/notifications/domain/push_token_source.dart';
import 'package:fpdart/fpdart.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'notifications_providers.g.dart';

/// Source de push utilisée par l'app ; Firebase Cloud Messaging en production.
@Riverpod(keepAlive: true)
PushTokenSource pushTokenSource(Ref ref) =>
    FirebasePushTokenSource(ref.watch(firebaseMessagingProvider));

/// Enregistre le token FCM de cet iPhone dans le foyer et suit ses renouvellements.
@Riverpod(keepAlive: true)
class PushRegistration extends _$PushRegistration {
  StreamSubscription<String>? _refreshSubscription;
  Future<void>? _inFlight;

  @override
  FutureOr<void> build() {
    ref.onDispose(() => _refreshSubscription?.cancel());
  }

  /// Un appel pendant qu'un autre est en cours partage la même Future.
  Future<void> register() =>
      _inFlight ??= _register().whenComplete(() => _inFlight = null);

  Future<void> _register() async {
    final code = ref.read(currentHouseholdCodeProvider);
    if (code == null) return;
    final source = ref.read(pushTokenSourceProvider);
    state = const AsyncLoading();
    final result = await guard(() async {
      if (!await source.requestPermission()) {
        return left<Failure, void>(
          const ValidationFailure(ValidationReason.notificationsDenied),
        );
      }
      _listenRefresh(source);
      final token = await source.getToken();
      if (token == null) return right<Failure, void>(null);
      return _saveToken(code, token);
    });
    state = result
        .flatMap((inner) => inner)
        .fold(
          (f) => AsyncError(f, StackTrace.current),
          (_) => const AsyncData(null),
        );
  }

  void _listenRefresh(PushTokenSource source) {
    _refreshSubscription ??= source.onTokenRefresh.listen((token) {
      final current = ref.read(currentHouseholdCodeProvider);
      if (current != null) _saveToken(current, token);
    });
  }

  Future<Either<Failure, void>> _saveToken(String code, String token) async {
    final result = await ref
        .read(deviceRepositoryProvider)
        .updateFcmToken(code, ref.read(deviceIdProvider), token);
    result.fold(
      (failure) =>
          developer.log('Token FCM non enregistré : $failure', name: 'colette'),
      (_) {},
    );
    return result;
  }
}

/// Enregistre les préférences de notification de cet iPhone.
@riverpod
class NotificationSettingsController extends _$NotificationSettingsController {
  @override
  FutureOr<void> build() {}

  Future<bool> save(DeviceInfo device) async {
    final code = ref.read(currentHouseholdCodeProvider);
    if (code == null) return false;
    state = const AsyncLoading();
    final result = await ref
        .read(deviceRepositoryProvider)
        .saveDevice(code, device);
    state = result.fold(
      (failure) => AsyncError(failure, StackTrace.current),
      (_) => const AsyncData(null),
    );
    return result.isRight();
  }
}
