import SwiftUI
import WidgetKit

/// Écran verrouillé : en-tête (prénom, heure de lancement), puis les deux
/// phases ou l'état terminé.
struct LockScreenView: View {
  let babyName: String
  let state: BottleTimerAttributes.ContentState
  let isStale: Bool

  private var title: String {
    babyName.isEmpty
      ? NSLocalizedString("bottleTimer.feeding", comment: "")
      : String(format: NSLocalizedString("bottleTimer.titleFor", comment: ""), babyName)
  }

  var body: some View {
    VStack(alignment: .leading, spacing: 10) {
      HStack {
        Label(title, systemImage: "waterbottle")
          .font(.subheadline)
          .foregroundStyle(Color("Feeding"))
        Spacer()
        Text(state.startedAt, style: .time)
          .font(.caption)
          .foregroundStyle(Color("Secondary"))
      }
      PhasesView(state: state, isStale: isStale, onDark: false)
    }
    .padding(16)
  }
}

/// Deux décomptes côte à côte (biberon, verticale) ; « terminé » une fois
/// l'activité périmée (fin de la verticale).
struct PhasesView: View {
  let state: BottleTimerAttributes.ContentState
  let isStale: Bool
  let onDark: Bool

  var body: some View {
    if isStale {
      VStack(alignment: .leading, spacing: 2) {
        Text("bottleTimer.done")
          .font(.headline)
          .foregroundStyle(onDark ? Color.white : Color("Text"))
        Text("bottleTimer.openToSave")
          .font(.caption)
          .foregroundStyle(onDark ? Color.secondary : Color("Secondary"))
      }
      .frame(maxWidth: .infinity, alignment: .leading)
    } else {
      HStack(alignment: .top, spacing: 12) {
        phase(
          "bottleTimer.feeding", from: state.startedAt, to: state.feedingEndsAt,
          color: Color("Feeding"))
        phase(
          "bottleTimer.upright", from: state.feedingEndsAt, to: state.uprightEndsAt,
          color: Color("Upright"))
      }
    }
  }

  private func phase(
    _ title: LocalizedStringKey, from: Date, to: Date, color: Color
  ) -> some View {
    VStack(alignment: .leading, spacing: 4) {
      Text(title)
        .font(.caption)
        .foregroundStyle(onDark ? Color.secondary : Color("Secondary"))
      Text(timerInterval: from...to, countsDown: true)
        .font(.title2.weight(.semibold))
        .monospacedDigit()
        .foregroundStyle(color)
      ProgressView(timerInterval: from...to, countsDown: false) {
        EmptyView()
      } currentValueLabel: {
        EmptyView()
      }
      .tint(color)
    }
    .frame(maxWidth: .infinity, alignment: .leading)
  }
}
