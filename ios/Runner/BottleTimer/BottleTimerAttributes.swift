import ActivityKit
import Foundation

/// Live Activity du minuteur de biberon : prénom fixe, dates dynamiques.
/// Partagé entre Runner et l'extension `BottleTimerWidget`.
@available(iOS 16.2, *)
struct BottleTimerAttributes: ActivityAttributes {
  struct ContentState: Codable, Hashable {
    var startedAt: Date
    var feedingEndsAt: Date
    var uprightEndsAt: Date
  }

  var babyName: String
}
