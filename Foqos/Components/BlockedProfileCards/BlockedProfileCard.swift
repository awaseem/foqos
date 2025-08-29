import FamilyControls
import SwiftUI

struct BlockedProfileCard: View {
  let profile: BlockedProfiles

  var isActive: Bool = false
  var isBreakAvailable: Bool = false
  var isBreakActive: Bool = false

  var elapsedTime: TimeInterval? = nil

  var onStartTapped: () -> Void
  var onStopTapped: () -> Void
  var onEditTapped: () -> Void
  var onBreakTapped: () -> Void

  // Keep a reference to the CardBackground to access color
  private var cardBackground: CardBackground {
    CardBackground(isActive: isActive, customColor: blockingStrategyColor)
  }

  // Get blocking strategy color for the background
  private var blockingStrategyColor: Color {
    guard let strategyId = profile.blockingStrategyId else {
      return .gray
    }
    return StrategyManager.getStrategyFromId(id: strategyId).color
  }

  var body: some View {
    ZStack {
      // Use the CardBackground component
      cardBackground

      // Content
      VStack(alignment: .leading, spacing: 12) {
        // Header section - Profile name, edit button, and indicators
        HStack {
          VStack(alignment: .leading, spacing: 10) {
            Text(profile.name)
              .font(.title3)
              .fontWeight(.bold)
              .foregroundColor(.primary)

            // Using the new ProfileIndicators component
            ProfileIndicators(
              enableLiveActivity: profile.enableLiveActivity,
              hasReminders: profile.reminderTimeInSeconds != nil,
              enableBreaks: profile.enableBreaks,
              enableStrictMode: profile.enableStrictMode,
            )
          }

          Spacer()

          // Edit button moved to top right
          Button(action: {
            UIImpactFeedbackGenerator(style: .light).impactOccurred()
            onEditTapped()
          }) {
            Image(systemName: "pencil")
              .font(.system(size: 14, weight: .medium))
              .foregroundColor(.primary)
              .padding(8)
              .background(
                Circle()
                  .fill(.thinMaterial)
                  .overlay(
                    Circle()
                      .stroke(
                        Color.primary.opacity(0.2),
                        lineWidth: 1
                      )
                  )
              )
          }
        }

        // Middle section - Strategy and apps info
        VStack(alignment: .leading, spacing: 16) {
          // Strategy and schedule side-by-side with divider
          HStack(spacing: 16) {
            StrategyInfoView(strategyId: profile.blockingStrategyId)

            Divider()
              .frame(height: 24)

            ProfileScheduleRow(schedule: profile.schedule)
          }

          // Using the new ProfileStatsRow component
          ProfileStatsRow(
            selectedActivity: profile.selectedActivity,
            sessionCount: profile.sessions.count,
            domainsCount: profile.domains?.count ?? 0
          )
        }

        Spacer(minLength: 4)

        ProfileTimerButton(
          isActive: isActive,
          isBreakAvailable: isBreakAvailable,
          isBreakActive: isBreakActive,
          elapsedTime: elapsedTime,
          onStartTapped: onStartTapped,
          onStopTapped: onStopTapped,
          onBreakTapped: onBreakTapped
        )
      }
      .padding(16)
    }
  }
}

#Preview {
  ZStack {
    Color(.systemGroupedBackground).ignoresSafeArea()

    VStack(spacing: 40) {
      // Inactive card
      BlockedProfileCard(
        profile: BlockedProfiles(
          id: UUID(),
          name: "Work",
          selectedActivity: FamilyActivitySelection(),
          blockingStrategyId: NFCBlockingStrategy.id,
          enableLiveActivity: true,
          reminderTimeInSeconds: 3600
        ),
        onStartTapped: {},
        onStopTapped: {},
        onEditTapped: {},
        onBreakTapped: {}
      )

      // Active card with timer
      BlockedProfileCard(
        profile: BlockedProfiles(
          id: UUID(),
          name: "Gaming",
          selectedActivity: FamilyActivitySelection(),
          blockingStrategyId: QRCodeBlockingStrategy.id,
          enableLiveActivity: true,
          reminderTimeInSeconds: 3600
        ),
        isActive: true,
        isBreakAvailable: true,
        elapsedTime: 1845,  // 30 minutes and 45 seconds
        onStartTapped: {},
        onStopTapped: {},
        onEditTapped: {},
        onBreakTapped: {}
      )
    }
  }
}
