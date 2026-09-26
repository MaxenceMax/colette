import AudioToolbox
import Flutter
import UIKit

@main
@objc class AppDelegate: FlutterAppDelegate, FlutterImplicitEngineDelegate {
  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }

  func didInitializeImplicitFlutterEngine(_ engineBridge: FlutterImplicitEngineBridge) {
    GeneratedPluginRegistrant.register(with: engineBridge.pluginRegistry)
    DocumentsPlugin.register(with: engineBridge.pluginRegistry)
    CalendarPlugin.register(with: engineBridge.pluginRegistry)
    registerDeviceChannel(with: engineBridge.pluginRegistry)
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
