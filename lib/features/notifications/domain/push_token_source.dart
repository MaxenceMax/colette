/// Accès au système de push : permission, token, ouvertures par notification.
abstract interface class PushTokenSource {
  /// Demande la permission iOS ; `true` si accordée (ou provisoire).
  Future<bool> requestPermission();

  Future<String?> getToken();

  Stream<String> get onTokenRefresh;

  /// Données de la notification qui a lancé l'app depuis l'état terminé.
  Future<Map<String, String>?> getInitialMessageData();

  /// Données des notifications ouvertes pendant que l'app était en arrière-plan.
  Stream<Map<String, String>> get onMessageOpened;
}
