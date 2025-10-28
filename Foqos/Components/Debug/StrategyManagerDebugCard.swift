import SwiftUI

struct StrategyManagerDebugCard: View {
  @ObservedObject var strategyManager: StrategyManager

  var body: some View {
    VStack(alignment: .leading, spacing: 8) {
      // Blocking Status
      Group {
        DebugRow(label: "Is Blocking", value: "\(strategyManager.isBlocking)")
        DebugRow(label: "Is Break Active", value: "\(strategyManager.isBreakActive)")
        DebugRow(label: "Is Break Available", value: "\(strategyManager.isBreakAvailable)")
      }

      Divider()

      // Timer Info
      Group {
        DebugRow(
          label: "Elapsed Time",
          value: DateFormatters.formatDuration(strategyManager.elapsedTime)
        )
        DebugRow(label: "Timer Active", value: "\(strategyManager.timer != nil)")
      }

      Divider()

      // UI State
      Group {
        DebugRow(
          label: "Show Custom Strategy View",
          value: "\(strategyManager.showCustomStrategyView)"
        )
        DebugRow(label: "Error Message", value: strategyManager.errorMessage ?? "nil")
      }

      Divider()

      // Emergency Unblocks
      DebugRow(
        label: "Emergency Unblocks Remaining",
        value: "\(strategyManager.getRemainingEmergencyUnblocks())"
      )

      Divider()

      // Available Strategies
      VStack(alignment: .leading, spacing: 4) {
        Text("Available Strategies:")
          .font(.caption)
          .foregroundColor(.secondary)

        ForEach(Array(StrategyManager.availableStrategies.enumerated()), id: \.offset) {
          _, strategy in
          Text("• \(strategy.getIdentifier())")
            .font(.caption)
            .foregroundColor(.primary)
        }
      }
    }
  }
}

#Preview {
  let strategyManager = StrategyManager.shared

  return StrategyManagerDebugCard(strategyManager: strategyManager)
    .padding()
}

#Preview("With Active Session") {
  let strategyManager = StrategyManager.shared
  strategyManager.elapsedTime = 3665  // 1 hour, 1 minute, 5 seconds

  return StrategyManagerDebugCard(strategyManager: strategyManager)
    .padding()
}

#Preview("With Error") {
  let strategyManager = StrategyManager.shared
  strategyManager.errorMessage = "Failed to scan NFC tag"

  return StrategyManagerDebugCard(strategyManager: strategyManager)
    .padding()
}
