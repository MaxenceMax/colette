import ActivityKit
import Flutter
import UserNotifications

/// Canal `colette/bottle-timer` : Live Activity (iOS 16.2+) et notifications
/// locales de fin de phase du minuteur de biberon.
enum BottleTimerChannel {
  static let notificationPrefix = "bottle-timer."
  private static let feedingId = "bottle-timer.feeding"
  private static let uprightId = "bottle-timer.upright"

  /// Dernière opération ActivityKit ; chaque nouvelle attend la précédente
  /// pour qu'un `clear` suivi d'un `sync` (ou deux `sync`) gardent leur ordre.
  /// Modifiée uniquement depuis le thread principal (handler du canal).
  private static var lastActivityTask: Task<Void, Never>?

  private static func enqueue(_ operation: @escaping () async -> Void) {
    let previous = lastActivityTask
    lastActivityTask = Task {
      await previous?.value
      await operation()
    }
  }

  static func register(with registry: FlutterPluginRegistry) {
    guard let messenger = registry.registrar(forPlugin: "BottleTimerPlugin")?.messenger() else {
      return
    }
    let channel = FlutterMethodChannel(name: "colette/bottle-timer", binaryMessenger: messenger)
    channel.setMethodCallHandler { call, result in
      switch call.method {
      case "sync":
        guard let args = call.arguments as? [String: Any],
          let startedAt = date(args["startedAt"]),
          let feedingEndsAt = date(args["feedingEndsAt"]),
          let uprightEndsAt = date(args["uprightEndsAt"])
        else {
          result(FlutterError(code: "bad-args", message: "sync: dates manquantes", details: nil))
          return
        }
        let babyName = args["babyName"] as? String ?? ""
        scheduleNotifications(feedingEndsAt: feedingEndsAt, uprightEndsAt: uprightEndsAt)
        if #available(iOS 16.2, *) {
          let state = BottleTimerAttributes.ContentState(
            startedAt: startedAt, feedingEndsAt: feedingEndsAt, uprightEndsAt: uprightEndsAt)
          enqueue { await syncActivity(babyName: babyName, state: state) }
        }
        result(nil)
      case "clear":
        clearNotifications()
        if #available(iOS 16.2, *) {
          enqueue { await endActivities() }
        }
        result(nil)
      default:
        result(FlutterMethodNotImplemented)
      }
    }
  }

  private static func date(_ value: Any?) -> Date? {
    guard let ms = value as? NSNumber else { return nil }
    return Date(timeIntervalSince1970: ms.doubleValue / 1000)
  }

  // MARK: - Notifications

  private static func scheduleNotifications(feedingEndsAt: Date, uprightEndsAt: Date) {
    UNUserNotificationCenter.current()
      .removePendingNotificationRequests(withIdentifiers: [feedingId, uprightId])
    add(
      id: feedingId, at: feedingEndsAt,
      title: NSLocalizedString("bottleTimer.feedingEnded.title", comment: ""),
      body: NSLocalizedString("bottleTimer.feedingEnded.body", comment: ""))
    add(
      id: uprightId, at: uprightEndsAt,
      title: NSLocalizedString("bottleTimer.uprightEnded.title", comment: ""),
      body: NSLocalizedString("bottleTimer.uprightEnded.body", comment: ""))
  }

  /// Rien si l'échéance est passée (minuteur repris après sa fin de phase).
  private static func add(id: String, at date: Date, title: String, body: String) {
    let interval = date.timeIntervalSinceNow
    guard interval > 1 else { return }
    let content = UNMutableNotificationContent()
    content.title = title
    content.body = body
    content.sound = .default
    let trigger = UNTimeIntervalNotificationTrigger(timeInterval: interval, repeats: false)
    UNUserNotificationCenter.current().add(
      UNNotificationRequest(identifier: id, content: content, trigger: trigger))
  }

  private static func clearNotifications() {
    let center = UNUserNotificationCenter.current()
    center.removePendingNotificationRequests(withIdentifiers: [feedingId, uprightId])
    center.removeDeliveredNotifications(withIdentifiers: [feedingId, uprightId])
  }

  // MARK: - Live Activity

  @available(iOS 16.2, *)
  private static func syncActivity(
    babyName: String, state: BottleTimerAttributes.ContentState
  ) async {
    guard ActivityAuthorizationInfo().areActivitiesEnabled else { return }
    let content = ActivityContent(state: state, staleDate: state.uprightEndsAt)
    if let activity = Activity<BottleTimerAttributes>.activities.first {
      await activity.update(content)
      return
    }
    do {
      _ = try Activity.request(
        attributes: BottleTimerAttributes(babyName: babyName), content: content)
    } catch {
      NSLog("colette: Live Activity refusée : \(error)")
    }
  }

  @available(iOS 16.2, *)
  private static func endActivities() async {
    for activity in Activity<BottleTimerAttributes>.activities {
      await activity.end(nil, dismissalPolicy: .immediate)
    }
  }
}
