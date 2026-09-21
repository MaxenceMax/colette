import 'dart:async';

import 'package:colette/features/notifications/domain/push_token_source.dart';

/// Source de token FCM contrôlable pour les tests.
class FakePushTokenSource implements PushTokenSource {
  FakePushTokenSource({this.granted = false, this.token});

  final bool granted;
  final String? token;
  final _refresh = StreamController<String>.broadcast();
  final _opened = StreamController<Map<String, String>>.broadcast();

  @override
  Future<bool> requestPermission() async => granted;

  @override
  Future<String?> getToken() async => token;

  @override
  Stream<String> get onTokenRefresh => _refresh.stream;

  @override
  Future<Map<String, String>?> getInitialMessageData() async => null;

  @override
  Stream<Map<String, String>> get onMessageOpened => _opened.stream;

  void emitRefresh(String newToken) => _refresh.add(newToken);

  void emitOpened(Map<String, String> data) => _opened.add(data);
}
