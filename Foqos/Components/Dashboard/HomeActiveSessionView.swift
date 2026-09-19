import SwiftData
import SwiftUI

struct HomeActiveSessionView: View {
  @Environment(\.modelContext) private var context
  @EnvironmentObject private var strategyManager: StrategyManager

  let onStopProfile: (BlockedProfiles) -> Void

  var body: some View {
    if let profile = strategyManager.activeSession?.blockedProfile {
      ActiveProfileSessionView(
        profile: profile,
        elapsedTime: strategyManager.elapsedTime,
        displayTime: strategyManager.sessionDisplayTime,
        isBreakAvailable: strategyManager.isBreakAvailable,
        isBreakActive: strategyManager.isBreakActive,
        isPauseActive: strategyManager.isPauseActive,
        isCountdownExpired: strategyManager.isCountdownExpired,
        onBreakTapped: toggleBreak,
        onStopTapped: { onStopProfile(profile) },
        onExpiredCountdownReset: resetExpiredCountdown
      )
    }
  }

  private func toggleBreak() {
    strategyManager.toggleBreak(context: context)
  }

  private func resetExpiredCountdown() {
    strategyManager.resetExpiredCountdown(context: context)
  }
}
