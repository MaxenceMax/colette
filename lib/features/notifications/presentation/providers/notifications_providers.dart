import 'dart:async';

import 'package:colette/core/firebase/firebase_providers.dart';
import 'package:colette/features/household/domain/entities/device_info.dart';
import 'package:colette/features/household/presentation/providers/household_providers.dart';
import 'package:colette/features/notifications/data/firebase_push_token_source.dart';
import 'package:colette/features/notifications/domain/push_token_source.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'notifications_providers.g.dart';

@Riverpod(keepAlive: true)
PushTokenSource pushTokenSource(Ref ref) =>
    FirebasePushTokenSource(ref.watch(firebaseMessagingProvider));

/// Enregistre le token FCM de cet iPhone dans le foyer et suit ses renouvellements.
@Riverpod(keepAlive: true)
class PushRegistration extends _$PushRegistration {
  StreamSubscription<String>? _refreshSubscription;

  @override
  FutureOr<void> build() {
    ref.onDispose(() => _refreshSubscription?.cancel());
  }

  Future<void> register() async {
    final code = ref.read(currentHouseholdCodeProvider);
    if (code == null) return;
    final source = ref.read(pushTokenSourceProvider);
    if (!await source.requestPermission()) return;
    final token = await source.getToken();
    if (token != null) await _saveToken(code, token);
    await _refreshSubscription?.cancel();
    _refreshSubscription = source.onTokenRefresh.listen(
      (newToken) => _saveToken(code, newToken),
    );
  }

  Future<void> _saveToken(String code, String token) => ref
      .read(deviceRepositoryProvider)
      .updateFcmToken(code, ref.read(deviceIdProvider), token);
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
