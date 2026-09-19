import SwiftData
import SwiftUI

struct HomeDashboardView: View {
  @EnvironmentObject private var strategyManager: StrategyManager

  let profiles: [BlockedProfiles]
  let sessions: [BlockedProfileSession]
  let alerts: [HomeAlert]
  let onSupportTapped: () -> Void
  let onSettingsTapped: () -> Void
  let onAlertTapped: (HomeAlert) -> Void
  let onGuidedCreationTapped: () -> Void
  let onAdvancedCreationTapped: () -> Void
  let onInsightsTapped: (DashboardInsightsContext) -> Void
  let onManageProfilesTapped: () -> Void
  let onStartProfile: (BlockedProfiles) -> Void
  let onStopProfile: (BlockedProfiles) -> Void
  let onEditProfile: (BlockedProfiles) -> Void
  let onProfileInsightsTapped: (BlockedProfiles) -> Void
  let onLauncherTapped: () -> Void
  let onActiveSessionTapped: () -> Void

  var body: some View {
    ScrollView(showsIndicators: false) {
      VStack(alignment: .leading, spacing: 30) {
        HomeHeaderView(
          onSupportTapped: onSupportTapped,
          onSettingsTapped: onSettingsTapped
        )

        HomeAlertsView(alerts: alerts, onAlertTapped: onAlertTapped)
          .padding(.horizontal, 16)

        if profiles.isEmpty {
          Welcome(
            onGuidedTap: createGuidedProfile,
            onAdvancedTap: createAdvancedProfile
          )
          .padding(.horizontal, 16)
        } else {
          HomeDashboardLayout {
            BlockedSessionsHabitTracker(
              sessions: sessions,
              profiles: profiles,
              onInsightsTapped: onInsightsTapped
            )
          } profiles: {
            HomeProfilesListView(
              profiles: profiles,
              isBlocking: strategyManager.isBlocking,
              activeSessionProfileId: strategyManager.activeSession?.blockedProfile.id,
              elapsedTime: strategyManager.elapsedTime,
              isPauseActive: strategyManager.isPauseActive,
              onManageTapped: onManageProfilesTapped,
              onStartTapped: onStartProfile,
              onStopTapped: onStopProfile,
              onEditTapped: onEditProfile,
              onStatsTapped: onProfileInsightsTapped
            )
          }
          .padding(.horizontal, 16)
        }
      }
    }
    .safeAreaInset(edge: .bottom) {
      if !profiles.isEmpty {
        HomeProfileLauncher(
          activeProfile: strategyManager.isBlocking
            ? strategyManager.activeSession?.blockedProfile : nil,
          displayTime: strategyManager.sessionDisplayTime,
          isBreakActive: strategyManager.isBreakActive,
          isPauseActive: strategyManager.isPauseActive,
          onStartTapped: onLauncherTapped,
          onActiveTapped: onActiveSessionTapped
        )
      }
    }
    .padding(.top, 1)
    .frame(
      minWidth: 0,
      maxWidth: .infinity,
      minHeight: 0,
      maxHeight: .infinity,
      alignment: .topLeading
    )
  }

  private func createGuidedProfile() {
    guard !strategyManager.isBlocking else { return }
    onGuidedCreationTapped()
  }

  private func createAdvancedProfile() {
    guard !strategyManager.isBlocking else { return }
    onAdvancedCreationTapped()
  }
}

private struct HomeDashboardPreview: View {
  let hasProfiles: Bool
  private let container: ModelContainer
  private let profile: BlockedProfiles
  private let session: BlockedProfileSession

  init(hasProfiles: Bool) {
    self.hasProfiles = hasProfiles
    do {
      container = try ModelContainer(
        for: BlockedProfiles.self, BlockedProfileSession.self,
        configurations: ModelConfiguration(isStoredInMemoryOnly: true)
      )
      profile = BlockedProfiles(
        name: "Deep Work",
        blockingStrategyId: ManualBlockingStrategy.id,
        domains: ["example.com"]
      )
      session = BlockedProfileSession(tag: ManualBlockingStrategy.id, blockedProfile: profile)
      session.startTime = Date().addingTimeInterval(-3600)
      session.endTime = Date()
      container.mainContext.insert(profile)
      container.mainContext.insert(session)
      try container.mainContext.save()
    } catch {
      fatalError("Failed to create dashboard preview: \(error)")
    }
  }

  var body: some View {
    HomeDashboardView(
      profiles: hasProfiles ? [profile] : [],
      sessions: hasProfiles ? [session] : [],
      alerts: [],
      onSupportTapped: {},
      onSettingsTapped: {},
      onAlertTapped: { _ in },
      onGuidedCreationTapped: {},
      onAdvancedCreationTapped: {},
      onInsightsTapped: { _ in },
      onManageProfilesTapped: {},
      onStartProfile: { _ in },
      onStopProfile: { _ in },
      onEditProfile: { _ in },
      onProfileInsightsTapped: { _ in },
      onLauncherTapped: {},
      onActiveSessionTapped: {}
    )
    .modelContainer(container)
    .environmentObject(StrategyManager())
    .environmentObject(ThemeManager())
    .defaultAppStorage(UserDefaults(suiteName: "home-dashboard-preview")!)
  }
}

#Preview("Dashboard") {
  HomeDashboardPreview(hasProfiles: true)
}

#Preview("Empty Dashboard") {
  HomeDashboardPreview(hasProfiles: false)
}
