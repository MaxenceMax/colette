import ActivityKit
import SwiftUI
import WidgetKit

/// Minuteur de biberon dans le Dynamic Island et sur l'écran verrouillé.
/// Les décomptes avancent seuls : aucune mise à jour n'est nécessaire.
struct BottleTimerLiveActivity: Widget {
  var body: some WidgetConfiguration {
    ActivityConfiguration(for: BottleTimerAttributes.self) { context in
      LockScreenView(
        babyName: context.attributes.babyName,
        state: context.state,
        isStale: context.isStale
      )
      .activityBackgroundTint(Color("Background"))
    } dynamicIsland: { context in
      DynamicIsland {
        DynamicIslandExpandedRegion(.leading) {
          Label(
            context.attributes.babyName.isEmpty
              ? NSLocalizedString("bottleTimer.feeding", comment: "")
              : context.attributes.babyName,
            systemImage: "waterbottle"
          )
          .font(.subheadline)
          .lineLimit(1)
          .foregroundStyle(Color("Feeding"))
          .padding(.leading, 6)
        }
        DynamicIslandExpandedRegion(.trailing) {
          Text(context.state.startedAt, style: .time)
            .font(.subheadline)
            .foregroundStyle(.secondary)
            .padding(.trailing, 6)
        }
        DynamicIslandExpandedRegion(.bottom) {
          PhasesView(state: context.state, isStale: context.isStale, onDark: true)
        }
      } compactLeading: {
        Image(systemName: "waterbottle")
          .foregroundStyle(Color("Feeding"))
      } compactTrailing: {
        if context.isStale {
          Image(systemName: "checkmark")
            .foregroundStyle(Color("Upright"))
        } else {
          Text(
            timerInterval: context.state.startedAt...context.state.uprightEndsAt,
            countsDown: true
          )
          .monospacedDigit()
          .multilineTextAlignment(.trailing)
          .frame(maxWidth: 48)
          .foregroundStyle(Color("Feeding"))
        }
      } minimal: {
        Image(systemName: "waterbottle")
          .foregroundStyle(Color("Feeding"))
      }
    }
  }
}
