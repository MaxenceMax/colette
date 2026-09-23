import EventKit
import Flutter
import UIKit
import os.log

/// Canal `colette/calendar` : accès, calendriers modifiables, et événements Colette
/// (URL `colette://rdv/…`) d'un calendrier choisi. Dates en millisecondes depuis l'epoch.
final class CalendarPlugin: NSObject {
  static let channelName = "colette/calendar"
  static let urlPrefix = "colette://rdv/"

  private let store = EKEventStore()

  static func register(with registry: FlutterPluginRegistry) {
    guard let messenger = registry.registrar(forPlugin: "CalendarPlugin")?.messenger() else {
      os_log("CalendarPlugin : registrar indisponible, canal non enregistré", type: .error)
      return
    }
    let channel = FlutterMethodChannel(name: channelName, binaryMessenger: messenger)
    let plugin = CalendarPlugin()
    channel.setMethodCallHandler { call, result in plugin.handle(call, result: result) }
  }

  private func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
    let args = call.arguments as? [String: Any] ?? [:]
    switch call.method {
    case "requestAccess": requestAccess(result)
    case "listCalendars": respond(result) { try self.listCalendars() }
    case "findEvents": respond(result) { try self.findEvents(args) }
    case "upsertEvent": respond(result) { try self.upsertEvent(args) }
    case "deleteEvent": respond(result) { try self.deleteEvent(args) }
    default: result(FlutterMethodNotImplemented)
    }
  }

  private func respond(_ result: FlutterResult, _ body: () throws -> Any?) {
    do {
      result(try body())
    } catch let error as CalendarError {
      result(error.flutterError)
    } catch {
      result(CalendarError.io(error.localizedDescription).flutterError)
    }
  }

  private func requestAccess(_ result: @escaping FlutterResult) {
    let completion: (Bool, Error?) -> Void = { granted, error in
      if let error {
        os_log(
          "CalendarPlugin : erreur requestAccess : %{public}@", type: .error,
          error.localizedDescription)
      }
      DispatchQueue.main.async {
        // Le store a été créé avant l'octroi : le rafraîchir pour que calendars(for:) ne renvoie
        // plus une liste vide.
        if granted { self.store.reset() }
        result(granted)
      }
    }
    if #available(iOS 17.0, *) {
      store.requestFullAccessToEvents(completion: completion)
    } else {
      store.requestAccess(to: .event, completion: completion)
    }
  }

  private func ensureAccess() throws {
    let status = EKEventStore.authorizationStatus(for: .event)
    if #available(iOS 17.0, *) {
      guard status == .fullAccess else { throw CalendarError.accessDenied }
    } else {
      guard status == .authorized else { throw CalendarError.accessDenied }
    }
  }

  private func calendar(_ args: [String: Any]) throws -> EKCalendar {
    guard let id = args["calendarId"] as? String,
      let calendar = store.calendar(withIdentifier: id)
    else { throw CalendarError.calendarNotFound }
    return calendar
  }

  private func date(_ args: [String: Any], _ key: String) throws -> Date {
    guard let millis = (args[key] as? NSNumber)?.doubleValue else {
      throw CalendarError.io("argument \(key) manquant")
    }
    return Date(timeIntervalSince1970: millis / 1000)
  }

  private func millis(_ date: Date) -> Int64 {
    Int64((date.timeIntervalSince1970 * 1000).rounded())
  }

  private func listCalendars() throws -> [[String: Any]] {
    try ensureAccess()
    return store.calendars(for: .event)
      // Exchange ne garde pas le champ URL et Google via CalDAV peut le perdre : on ne propose
      // que les calendriers iCloud ou locaux pour éviter les doublons à la synchronisation.
      .filter { calendar in
        calendar.allowsContentModifications
          && ((calendar.source?.sourceType == .calDAV && calendar.source?.title == "iCloud")
            || calendar.source?.sourceType == .local)
      }
      .map { calendar in
        var map: [String: Any] = [
          "id": calendar.calendarIdentifier,
          "title": calendar.title,
          "source": calendar.source?.title ?? "",
        ]
        if let colorHex = hex(calendar.cgColor) {
          map["colorHex"] = colorHex
        }
        return map
      }
  }

  private func findEvents(_ args: [String: Any]) throws -> [[String: Any]] {
    try ensureAccess()
    let calendar = try calendar(args)
    let predicate = store.predicateForEvents(
      withStart: try date(args, "from"), end: try date(args, "to"), calendars: [calendar])
    return store.events(matching: predicate).compactMap { event in
      guard let eventId = event.eventIdentifier else { return nil }
      guard let url = event.url?.absoluteString, url.hasPrefix(Self.urlPrefix) else { return nil }
      var map: [String: Any] = [
        "eventId": eventId,
        "url": url,
        "title": event.title ?? "",
        "start": millis(event.startDate),
        "end": millis(event.endDate),
      ]
      if let notes = event.notes { map["notes"] = notes }
      // Identique sur tous les appareils (UID iCloud) : départage les doublons.
      if let externalId = event.calendarItemExternalIdentifier { map["externalId"] = externalId }
      return map
    }
  }

  private func upsertEvent(_ args: [String: Any]) throws -> String {
    try ensureAccess()
    let calendar = try calendar(args)
    guard let urlString = args["url"] as? String, let url = URL(string: urlString) else {
      throw CalendarError.io("argument url manquant")
    }
    let existing = (args["eventId"] as? String).flatMap { store.event(withIdentifier: $0) }
    // Un événement d'un autre calendrier ne doit pas être déplacé silencieusement : on en crée un nouveau.
    let reusable = existing?.calendar.calendarIdentifier == calendar.calendarIdentifier
      ? existing : nil
    let event = reusable ?? EKEvent(eventStore: store)
    event.calendar = calendar
    event.title = args["title"] as? String
    event.startDate = try date(args, "start")
    event.endDate = try date(args, "end")
    event.notes = args["notes"] as? String
    event.url = url
    event.alarms = ((args["alarms"] as? [NSNumber]) ?? []).map {
      EKAlarm(absoluteDate: Date(timeIntervalSince1970: $0.doubleValue / 1000))
    }
    do {
      try store.save(event, span: .thisEvent, commit: true)
    } catch {
      throw CalendarError.io(error.localizedDescription)
    }
    guard let eventId = event.eventIdentifier, !eventId.isEmpty else {
      throw CalendarError.io("identifiant manquant")
    }
    return eventId
  }

  private func deleteEvent(_ args: [String: Any]) throws -> Any? {
    try ensureAccess()
    let calendar = try calendar(args)
    guard let id = args["eventId"] as? String else {
      throw CalendarError.io("argument eventId manquant")
    }
    guard let event = store.event(withIdentifier: id),
      event.calendar.calendarIdentifier == calendar.calendarIdentifier
    else { return nil }
    do {
      try store.remove(event, span: .thisEvent, commit: true)
    } catch {
      throw CalendarError.io(error.localizedDescription)
    }
    return nil
  }

  private func hex(_ color: CGColor?) -> String? {
    guard let color else { return nil }
    var red: CGFloat = 0, green: CGFloat = 0, blue: CGFloat = 0, alpha: CGFloat = 0
    guard UIColor(cgColor: color).getRed(&red, green: &green, blue: &blue, alpha: &alpha) else {
      return nil
    }
    func byte(_ value: CGFloat) -> Int { Int((min(max(value, 0), 1) * 255).rounded()) }
    return String(format: "#%02X%02X%02X", byte(red), byte(green), byte(blue))
  }
}
