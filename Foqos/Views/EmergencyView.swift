import SwiftData
import SwiftUI

struct EmergencyView: View {
  @Environment(\.modelContext) private var context
  @Environment(\.dismiss) private var dismiss
  @Environment(\.scenePhase) private var scenePhase
  @EnvironmentObject var strategyManager: StrategyManager

  @State private var remainingUnblocks = 0
  @State private var resetPeriodInWeeks = 4
  @State private var nextResetDate: Date?
  @State private var isPerformingEmergencyUnblock = false

  var body: some View {
    EmergencyAccessContent(
      remainingUnblocks: remainingUnblocks,
      resetPeriodInWeeks: resetPeriodInWeeks,
      nextResetDate: nextResetDate,
      isPerformingEmergencyUnblock: isPerformingEmergencyUnblock,
      onResetPeriodChange: { weeks in
        strategyManager.setResetPeriodInWeeks(weeks)
        refreshStatus()
      },
      onUnblock: performEmergencyUnblock
    )
    .onAppear(perform: refreshStatus)
    .onChange(of: scenePhase) { _, phase in
      if phase == .active {
        refreshStatus()
      }
    }
  }

  private func refreshStatus() {
    strategyManager.checkAndResetEmergencyUnblocks()
    remainingUnblocks = strategyManager.getRemainingEmergencyUnblocks()
    resetPeriodInWeeks = strategyManager.getResetPeriodInWeeks()
    nextResetDate = strategyManager.getNextResetDate()
  }

  private func performEmergencyUnblock() {
    guard !isPerformingEmergencyUnblock else { return }
    refreshStatus()
    guard remainingUnblocks > 0 else { return }
    isPerformingEmergencyUnblock = true

    strategyManager.emergencyUnblock(context: context)
    dismiss()
  }
}

private struct EmergencyAccessContent: View {
  let remainingUnblocks: Int
  let resetPeriodInWeeks: Int
  let nextResetDate: Date?
  var isPerformingEmergencyUnblock = false
  var onResetPeriodChange: (Int) -> Void = { _ in }
  var onUnblock: () -> Void = {}

  @State private var confirmation: Confirmation?

  private enum Confirmation: Identifiable {
    case lastUnblock
    case changeInterval(Int)

    var id: String {
      switch self {
      case .lastUnblock: return "lastUnblock"
      case .changeInterval(let weeks): return "changeInterval-\(weeks)"
      }
    }
  }

  var body: some View {
    ScrollView {
      VStack(alignment: .leading, spacing: 16) {
        HStack(spacing: 8) {
          Image("FireAlarmSticker")
            .resizable()
            .scaledToFit()
            .frame(width: 44, height: 44)
            .accessibilityHidden(true)

          Text("Emergency Access")
            .font(.title2.bold())
        }

        VStack(alignment: .leading, spacing: 20) {
          HStack(alignment: .firstTextBaseline, spacing: 12) {
            VStack(alignment: .leading, spacing: 6) {
              Text(remainingText)
                .font(.title3.weight(.semibold))

              resetDate
            }

            Spacer(minLength: 0)

            intervalMenu
              .fixedSize()
          }

          if remainingUnblocks > 0 {
            BreakGlassButton {
              unblockButton
            }
            .frame(height: 56)
          }
        }
        .padding(16)
      }
      .padding(.horizontal, 16)
      .padding(.top, 24)
      .padding(.bottom, 16)
    }
    .alert(item: $confirmation, content: confirmationAlert)
  }

  private var remainingText: String {
    switch remainingUnblocks {
    case 0: return "No unblocks left"
    case 1: return "1 unblock left"
    default: return "\(remainingUnblocks) unblocks left"
    }
  }

  private var unblockButton: some View {
    ActionButton(
      title: "Emergency Unblock",
      backgroundColor: .red,
      iconName: "exclamationmark.triangle.fill",
      iconColor: .white,
      isLoading: isPerformingEmergencyUnblock
    ) {
      if remainingUnblocks == 1 {
        confirmation = .lastUnblock
      } else {
        onUnblock()
      }
    }
    .lineLimit(1)
    .minimumScaleFactor(0.7)
    .accessibilityHint("Ends your current session.")
  }

  private var resetDate: some View {
    Group {
      if let nextResetDate {
        Text("Next reset: \(nextResetDate, format: .dateTime.month(.abbreviated).day())")
      }
    }
    .font(.subheadline)
    .foregroundStyle(.secondary)
    .fixedSize(horizontal: false, vertical: true)
  }

  private var intervalMenu: some View {
    Menu {
      ForEach([2, 4, 6, 8], id: \.self) { weeks in
        Button {
          guard weeks != resetPeriodInWeeks else { return }
          confirmation = .changeInterval(weeks)
        } label: {
          if weeks == resetPeriodInWeeks {
            Label("\(weeks) weeks", systemImage: "checkmark")
          } else {
            Text("\(weeks) weeks")
          }
        }
      }
    } label: {
      HStack(spacing: 4) {
        Text("\(resetPeriodInWeeks) weeks")
        Image(systemName: "chevron.down")
          .font(.caption2.weight(.semibold))
      }
      .font(.subheadline.weight(.medium))
      .foregroundStyle(.secondary)
      .padding(.horizontal, 12)
      .padding(.vertical, 8)
      .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 16))
      .overlay {
        RoundedRectangle(cornerRadius: 16)
          .strokeBorder(.white.opacity(0.15))
      }
      .padding(.vertical, 4)
      .contentShape(Rectangle())
    }
    .tint(.primary)
    .disabled(isPerformingEmergencyUnblock)
    .accessibilityLabel("Reset interval")
    .accessibilityValue("\(resetPeriodInWeeks) weeks")
  }

  private func confirmationAlert(_ confirmation: Confirmation) -> Alert {
    switch confirmation {
    case .lastUnblock:
      let message =
        nextResetDate.map {
          "This ends your session. No emergency unblocks until \($0.formatted(date: .abbreviated, time: .shortened))."
        } ?? "This ends your session and uses your last emergency unblock."

      return Alert(
        title: Text("Use your last unblock?"),
        message: Text(message),
        primaryButton: .destructive(Text("Use last unblock"), action: onUnblock),
        secondaryButton: .cancel(Text("Keep it"))
      )

    case .changeInterval(let weeks):
      return Alert(
        title: Text("Reset in \(weeks) weeks?"),
        message: Text("This restarts the wait from today."),
        primaryButton: .default(Text("Change interval")) { onResetPeriodChange(weeks) },
        secondaryButton: .cancel()
      )
    }
  }
}

#Preview("Available") {
  EmergencyAccessContent(
    remainingUnblocks: 3, resetPeriodInWeeks: 4,
    nextResetDate: .now.addingTimeInterval(14 * 24 * 60 * 60)
  )
}

#Preview("Last unblock") {
  EmergencyAccessContent(
    remainingUnblocks: 1, resetPeriodInWeeks: 4,
    nextResetDate: .now.addingTimeInterval(14 * 24 * 60 * 60)
  )
}

#Preview("Empty") {
  EmergencyAccessContent(
    remainingUnblocks: 0, resetPeriodInWeeks: 4,
    nextResetDate: .now.addingTimeInterval(14 * 24 * 60 * 60)
  )
}
