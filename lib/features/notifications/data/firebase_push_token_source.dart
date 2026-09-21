import 'package:colette/features/notifications/domain/push_token_source.dart';
import 'package:firebase_messaging/firebase_messaging.dart';

/// Implémentation Firebase Cloud Messaging.
final class FirebasePushTokenSource implements PushTokenSource {
  FirebasePushTokenSource(this._messaging);

  final FirebaseMessaging _messaging;

  static Map<String, String> _stringData(RemoteMessage message) =>
      message.data.map((key, value) => MapEntry(key, '$value'));

  @override
  Future<bool> requestPermission() async {
    final settings = await _messaging.requestPermission();
    await _messaging.setForegroundNotificationPresentationOptions(
      alert: true,
      badge: true,
      sound: true,
    );
    return switch (settings.authorizationStatus) {
      AuthorizationStatus.authorized || AuthorizationStatus.provisional => true,
      _ => false,
    };
  }

  @override
  Future<String?> getToken() => _messaging.getToken();

  @override
  Stream<String> get onTokenRefresh => _messaging.onTokenRefresh;

  @override
  Future<Map<String, String>?> getInitialMessageData() async {
    final message = await _messaging.getInitialMessage();
    return message == null ? null : _stringData(message);
  }

  @override
  Stream<Map<String, String>> get onMessageOpened =>
      FirebaseMessaging.onMessageOpenedApp.map(_stringData);
}
