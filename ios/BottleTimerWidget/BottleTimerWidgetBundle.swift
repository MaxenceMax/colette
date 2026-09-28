import SwiftUI
import WidgetKit

/// Point d'entrée de l'extension : la Live Activity du minuteur de biberon.
@main
struct BottleTimerWidgetBundle: WidgetBundle {
  var body: some Widget {
    BottleTimerLiveActivity()
  }
}
