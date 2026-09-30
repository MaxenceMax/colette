import AudioToolbox
import Flutter
import UIKit
import UserNotifications

@main
@objc class AppDelegate: FlutterAppDelegate, FlutterImplicitEngineDelegate {
  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    // Delegate posé avant `super` : `firebase_messaging` le conserve et reçoit
    // ses appels via `FlutterAppDelegate` ; les notifications du minuteur sont
    // filtrées dans `willPresent`.
    UNUserNotificationCenter.current().delegate = self
    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }

  /// Au premier plan, les sons de l'app remplacent les notifications du minuteur.
  override func userNotificationCenter(
    _ center: UNUserNotificationCenter,
    willPresent notification: UNNotification,
    withCompletionHandler completionHandler:
      @escaping (UNNotificationPresentationOptions) -> Void
  ) {
    if notification.request.identifier.hasPrefix(PhotoSharingReminders.prefix) {
      completionHandler([.banner, .list, .sound])
      return
    }
    if notification.request.identifier.hasPrefix(BottleTimerChannel.notificationPrefix) {
      completionHandler([])
      return
    }
    super.userNotificationCenter(
      center, willPresent: notification, withCompletionHandler: completionHandler)
  }

  /// Appui sur le rappel photo : la page Photos s'ouvre (voir `PhotoSharingPlugin`).
  override func userNotificationCenter(
    _ center: UNUserNotificationCenter,
    didReceive response: UNNotificationResponse,
    withCompletionHandler completionHandler: @escaping () -> Void
  ) {
    if response.notification.request.identifier.hasPrefix(PhotoSharingReminders.prefix) {
      PhotoSharingPlugin.notificationOpened()
      completionHandler()
      return
    }
    super.userNotificationCenter(
      center, didReceive: response, withCompletionHandler: completionHandler)
  }

  func didInitializeImplicitFlutterEngine(_ engineBridge: FlutterImplicitEngineBridge) {
    GeneratedPluginRegistrant.register(with: engineBridge.pluginRegistry)
    DocumentsPlugin.register(with: engineBridge.pluginRegistry)
    CalendarPlugin.register(with: engineBridge.pluginRegistry)
    registerDeviceChannel(with: engineBridge.pluginRegistry)
    BottleTimerChannel.register(with: engineBridge.pluginRegistry)
    PhotoSharingPlugin.register(with: engineBridge.pluginRegistry)
  }

  /// Canal `colette/device` : écran maintenu allumé et sons système
  /// (muets en mode silencieux), pour le minuteur de biberon.
  private func registerDeviceChannel(with registry: FlutterPluginRegistry) {
    guard let messenger = registry.registrar(forPlugin: "DevicePlugin")?.messenger() else {
      return
    }
    let channel = FlutterMethodChannel(name: "colette/device", binaryMessenger: messenger)
    channel.setMethodCallHandler { call, result in
      switch call.method {
      case "setKeepScreenOn":
        UIApplication.shared.isIdleTimerDisabled = (call.arguments as? Bool) ?? false
        result(nil)
      case "playSound":
        // 1007 : « tri-tone » (fin du biberon) ; 1008 : carillon (fin de la verticale).
        let soundID: SystemSoundID = (call.arguments as? String) == "uprightEnded" ? 1008 : 1007
        AudioServicesPlaySystemSound(soundID)
        result(nil)
      default:
        result(FlutterMethodNotImplemented)
      }
    }
  }
}
