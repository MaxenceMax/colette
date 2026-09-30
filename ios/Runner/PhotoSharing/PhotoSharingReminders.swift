import UserNotifications
import os.log

/// Notifications du rappel photo, une par jour, identifiant `photo-reminder.AAAA-MM-JJ`.
enum PhotoSharingReminders {
  static let prefix = "photo-reminder."

  /// Retire les rappels de la veille à J+15 (retrait synchrone, donc ordonné),
  /// puis programme une notification non répétée par date.
  static func sync(dates: [Date], title: String, body: String) {
    let center = UNUserNotificationCenter.current()
    let calendar = Calendar.current
    let today = calendar.startOfDay(for: Date())
    let stale = (-1...15)
      .compactMap { calendar.date(byAdding: .day, value: $0, to: today) }
      .map(identifier)
    center.removePendingNotificationRequests(withIdentifiers: stale)
    for date in dates {
      let content = UNMutableNotificationContent()
      content.title = title
      content.body = body
      content.sound = .default
      let components = calendar.dateComponents(
        [.year, .month, .day, .hour, .minute], from: date)
      let trigger = UNCalendarNotificationTrigger(dateMatching: components, repeats: false)
      let request = UNNotificationRequest(
        identifier: identifier(date), content: content, trigger: trigger)
      center.add(request) { error in
        guard let error else { return }
        os_log(
          "Rappel photo non programmé : %{public}@", type: .error, error.localizedDescription)
      }
    }
  }

  static func identifier(_ date: Date) -> String {
    let day = Calendar.current.dateComponents([.year, .month, .day], from: date)
    return prefix
      + String(format: "%04d-%02d-%02d", day.year ?? 0, day.month ?? 0, day.day ?? 0)
  }
}
