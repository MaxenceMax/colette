import Flutter
import UIKit
import os.log

/// Canal `colette/photo-sharing` : contacts, photos, feuilles Messages et
/// notifications quotidiennes du rappel photo.
final class PhotoSharingPlugin: NSObject {
  static let channelName = "colette/photo-sharing"
  static let photosRoute = "/today/photos"

  /// Instance enregistrée, pour signaler à Flutter l'appui sur une notification.
  private static var shared: PhotoSharingPlugin?

  /// Route demandée par une notification, en attente de lecture par Flutter.
  /// Statique : l'appui peut arriver avant l'enregistrement du canal.
  private static var pendingRoute: String?

  private let channel: FlutterMethodChannel
  private let presenter = PhotoSharingPresenter()

  /// Une seule présentation d'écran système à la fois. Thread principal uniquement.
  private var busy = false

  private init(channel: FlutterMethodChannel) {
    self.channel = channel
  }

  static func register(with registry: FlutterPluginRegistry) {
    guard let messenger = registry.registrar(forPlugin: "PhotoSharingPlugin")?.messenger() else {
      os_log("PhotoSharingPlugin : registrar indisponible, canal non enregistré", type: .error)
      return
    }
    let channel = FlutterMethodChannel(name: channelName, binaryMessenger: messenger)
    let plugin = PhotoSharingPlugin(channel: channel)
    channel.setMethodCallHandler { call, result in plugin.handle(call, result: result) }
    shared = plugin
    PhotoSharingImages.discardAll()
  }

  /// Appui sur une notification du rappel photo (depuis l'AppDelegate).
  static func notificationOpened() {
    pendingRoute = photosRoute
    shared?.channel.invokeMethod("routePending", arguments: nil)
  }

  private func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
    let args = call.arguments as? [String: Any] ?? [:]
    switch call.method {
    case "pickContact", "takePhoto", "pickPhotos", "sendMessages":
      exclusive(call.method, args: args, result: result)
    case "discardPhotos":
      PhotoSharingImages.discard(args["photoPaths"] as? [String] ?? [])
      result(nil)
    case "syncReminders":
      let dates = (args["dates"] as? [NSNumber] ?? []).map {
        Date(timeIntervalSince1970: $0.doubleValue / 1000)
      }
      PhotoSharingReminders.sync(
        dates: dates, title: args["title"] as? String ?? "",
        body: args["body"] as? String ?? "")
      result(nil)
    case "takePendingRoute":
      result(Self.pendingRoute)
      Self.pendingRoute = nil
    default:
      result(FlutterMethodNotImplemented)
    }
  }

  private func exclusive(_ method: String, args: [String: Any], result: @escaping FlutterResult) {
    guard !busy else {
      result(PhotoSharingError.busy.flutterError)
      return
    }
    busy = true
    // Une seule réponse par appel, même si le présentateur répondait deux fois.
    var replied = false
    let reply: FlutterResult = { [weak self] value in
      guard !replied else { return }
      replied = true
      self?.busy = false
      result(value)
    }
    switch method {
    case "pickContact":
      presenter.pickContact { outcome in
        switch outcome {
        case .success(let contact): reply(contact)
        case .failure(let error): reply(error.flutterError)
        }
      }
    case "takePhoto":
      presenter.takePhoto { reply(Self.value($0)) }
    case "pickPhotos":
      presenter.pickPhotos { reply(Self.value($0)) }
    default:
      presenter.sendMessages(
        phones: args["phones"] as? [String] ?? [],
        photoPaths: args["photoPaths"] as? [String] ?? [],
        body: args["body"] as? String ?? ""
      ) { reply(Self.value($0)) }
    }
  }

  /// Valeur non optionnelle ou erreur du canal.
  private static func value<T>(_ outcome: Result<T, PhotoSharingError>) -> Any {
    switch outcome {
    case .success(let value): return value
    case .failure(let error): return error.flutterError
    }
  }
}
