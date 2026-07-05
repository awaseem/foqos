import SwiftData
import SwiftUI

struct HomeView: View {
  @Environment(\.modelContext) private var context
  @Environment(\.openURL) var openURL

  @Environment(\.scenePhase) private var scenePhase

  @EnvironmentObject var requestAuthorizer: RequestAuthorizer
  @EnvironmentObject var strategyManager: StrategyManager
  @EnvironmentObject var alertsManager: AlertsManager
  @EnvironmentObject var navigationManager: NavigationManager
  @EnvironmentObject var ratingManager: RatingManager

  // Profile management
  @Query(sort: [
    SortDescriptor(\BlockedProfiles.order, order: .forward),
    SortDescriptor(\BlockedProfiles.createdAt, order: .reverse),
  ]) private
    var profiles: [BlockedProfiles]
  @State private var isProfileListPresent = false

  // New profile view
  @State private var showNewProfileView = false
  @State private var showGuidedProfileCreationView = false
  @State private var showStartProfilePicker = false

  // Edit profile
  @State private var profileToEdit: BlockedProfiles? = nil

  // Stats sheet
  @State private var profileToShowStats: BlockedProfiles? = nil

  // Dashboard insights sheet
  @State private var dashboardInsightsContext: DashboardInsightsContext? = nil

  // Donation View
  @State private var showDonationView = false

  // Settings View
  @State private var showSettingsView = false

  // Active session view
  @State private var showActiveProfileSessionView = false

  // Navigate to profile
  @State private var navigateToProfileId: UUID? = nil

  // Activity sessions
  @Query(
    filter: #Predicate<BlockedProfileSession> { $0.endTime != nil },
    sort: \BlockedProfileSession.endTime,
    order: .reverse
  ) private var recentCompletedSessions: [BlockedProfileSession]

  // Alerts
  @State private var showingAlert = false
  @State private var alertTitle = ""
  @State private var alertMessage = ""

  // Intro sheet
  @AppStorage("showIntroScreen") private var showIntroScreen = true

  // UI States
  @State private var opacityValue = 1.0

  var isBlocking: Bool {
    return strategyManager.isBlocking
  }

  var activeSessionProfileId: UUID? {
    return strategyManager.activeSession?.blockedProfile.id
  }

  var isBreakAvailable: Bool {
    return strategyManager.isBreakAvailable
  }

  var isBreakActive: Bool {
    return strategyManager.isBreakActive
  }

  var isPauseActive: Bool {
    return strategyManager.isPauseActive
  }

  private var canCreateProfiles: Bool {
    return !isBlocking
  }

  var body: some View {
    ScrollView(showsIndicators: false) {
      VStack(alignment: .leading, spacing: 30) {
        HStack(alignment: .center) {
          AppTitle()
          Spacer()
          HStack(spacing: 8) {
            RoundedButton(
              "Support",
              action: {
                showDonationView = true
              },
              imageName: "SupportStickerLogo")
            RoundedButton(
              "",
              action: {
                showSettingsView = true
              }, iconName: "gear")
          }
        }
        .padding(.trailing, 16)
        .padding(.top, 16)

        HomeAlertsView(
          alerts: alertsManager.alerts,
          onAlertTapped: { alert in
            presentAlert(alert)
          }
        )
        .padding(.horizontal, 16)

        if profiles.isEmpty {
          Welcome(
            onGuidedTap: {
              if canCreateProfiles {
                showGuidedProfileCreationView = true
              }
            },
            onAdvancedTap: {
              if canCreateProfiles {
                showNewProfileView = true
              }
            }
          )
          .padding(.horizontal, 16)
        }

        if !profiles.isEmpty {
          BlockedSessionsHabitTracker(
            sessions: recentCompletedSessions,
            profiles: profiles,
            onInsightsTapped: { context in
              dashboardInsightsContext = context
            }
          )
          .padding(.horizontal, 16)

          HomeProfilesListView(
            profiles: profiles,
            isBlocking: isBlocking,
            activeSessionProfileId: activeSessionProfileId,
            elapsedTime: strategyManager.elapsedTime,
            isPauseActive: isPauseActive,
            onManageTapped: {
              isProfileListPresent = true
            },
            onStartTapped: { profile in
              startProfile(profile)
            },
            onStopTapped: { profile in
              strategyButtonPress(profile)
            },
            onEditTapped: { profile in
              profileToEdit = profile
            },
            onStatsTapped: { profile in
              profileToShowStats = profile
            }
          )
          .padding(.horizontal, 16)
        }
      }
    }
    .refreshable {
      loadApp()
    }
    .safeAreaInset(edge: .bottom) {
      if !profiles.isEmpty {
        HomeProfileLauncher(
          activeProfile: isBlocking ? strategyManager.activeSession?.blockedProfile : nil,
          displayTime: strategyManager.sessionDisplayTime,
          isBreakActive: isBreakActive,
          isPauseActive: isPauseActive,
          onStartTapped: {
            showStartProfilePicker = true
          },
          onActiveTapped: {
            showActiveProfileSessionView = true
          }
        )
      }
    }
    .padding(.top, 1)
    .sheet(
      isPresented: $isProfileListPresent,
    ) {
      BlockedProfileListView()
    }
    .frame(
      minWidth: 0,
      maxWidth: .infinity,
      minHeight: 0,
      maxHeight: .infinity,
      alignment: .topLeading
    )
    .onChange(of: navigationManager.profileId) { _, newValue in
      if let profileId = newValue, let url = navigationManager.link {
        toggleSessionFromDeeplink(profileId, link: url)
        navigationManager.clearNavigation()
      }
    }
    .onChange(of: navigationManager.navigateToProfileId) { _, newValue in
      if let profileId = newValue {
        navigateToProfileId = UUID(uuidString: profileId)
        showStartProfilePicker = true
        navigationManager.clearNavigation()
      }
    }
    .onChange(of: requestAuthorizer.isAuthorized) { _, newValue in
      if newValue {
        showIntroScreen = false
      }
      refreshAlerts()
    }
    .onChange(of: profiles) { oldValue, newValue in
      if !newValue.isEmpty {
        loadApp()
      }
      refreshAlerts()
    }
    .onChange(of: scenePhase) { oldPhase, newPhase in
      if newPhase == .active {
        requestAuthorizer.refreshAuthorizationStatus()
        loadApp()
        refreshAlerts()
      } else if newPhase == .background {
        unloadApp()
      }
    }
    .onChange(of: isBlocking) { _, newValue in
      if !newValue {
        showActiveProfileSessionView = false
      }
    }
    .onReceive(strategyManager.$errorMessage) { errorMessage in
      guard let message = errorMessage, !showActiveProfileSessionView else { return }
      showErrorAlert(message: message)
    }
    .onAppear {
      onAppearApp()
    }
    .sheet(item: $alertsManager.selectedAlert) { alert in
      HomeAlertDetailView(
        alert: alert,
        disabledReason: disabledReason(for: alert),
        onPrimaryAction: {
          runAlertPrimaryAction(for: alert)
        }
      )
      .presentationDetents([.medium, .large])
    }
    .fullScreenCover(isPresented: $showIntroScreen) {
      IntroView {
        requestAuthorizer.requestAuthorization()
      }.interactiveDismissDisabled()
    }
    .fullScreenCover(isPresented: $showActiveProfileSessionView) {
      if let activeProfile = strategyManager.activeSession?.blockedProfile {
        ActiveProfileSessionView(
          profile: activeProfile,
          elapsedTime: strategyManager.elapsedTime,
          displayTime: strategyManager.sessionDisplayTime,
          isBreakAvailable: isBreakAvailable,
          isBreakActive: isBreakActive,
          isPauseActive: isPauseActive,
          onBreakTapped: {
            strategyManager.toggleBreak(context: context)
          },
          onStopTapped: {
            strategyButtonPress(activeProfile)
          }
        )
      }
    }
    .sheet(item: $profileToShowStats) { profile in
      ProfileInsightsView(profile: profile)
    }
    .sheet(item: $profileToEdit) { profile in
      BlockedProfileView(profile: profile)
    }
    .sheet(item: $dashboardInsightsContext) { context in
      ProfileInsightsView(
        profile: context.profile,
        initialViewMode: context.viewMode,
        initialSelectedDate: context.selectedDate
      )
    }
    .sheet(
      isPresented: $showNewProfileView,
    ) {
      BlockedProfileView(profile: nil)
    }
    .sheet(
      isPresented: $showGuidedProfileCreationView,
    ) {
      GuidedBlockedProfileCreationView()
    }
    .sheet(isPresented: $showStartProfilePicker) {
      StartProfilePickerView(
        profiles: profiles,
        isBlocking: isBlocking,
        activeSessionProfileId: activeSessionProfileId,
        startingProfileId: navigateToProfileId,
        onGoTapped: { profile in
          startProfile(profile)
        }
      )
      .presentationDetents([.medium, .large])
    }
    .sheet(isPresented: strategyActionSheetBinding) {
      BlockingStrategyActionView(
        customView: strategyManager.customStrategyView,
        presentationDetents: strategyManager.customStrategyViewPresentationDetents
      )
    }
    .sheet(isPresented: $showDonationView) {
      SupportView()
    }
    .sheet(isPresented: $showSettingsView) {
      SettingsView()
    }
    .alert(alertTitle, isPresented: $showingAlert) {
      Button("OK", role: .cancel) { dismissAlert() }
    } message: {
      Text(alertMessage)
    }
  }

  private func toggleSessionFromDeeplink(_ profileId: String, link: URL) {
    strategyManager
      .toggleSessionFromDeeplink(profileId, url: link, context: context)
  }

  private func strategyButtonPress(_ profile: BlockedProfiles) {
    strategyManager
      .toggleBlocking(context: context, activeProfile: profile)

    ratingManager.incrementLaunchCount()
  }

  private var strategyActionSheetBinding: Binding<Bool> {
    Binding(
      get: {
        strategyManager.showCustomStrategyView && !showActiveProfileSessionView
      },
      set: { isPresented in
        if !isPresented {
          strategyManager.showCustomStrategyView = false
        }
      }
    )
  }

  private func startProfile(_ profile: BlockedProfiles) {
    guard !isBlocking else {
      showErrorAlert(message: "Stop the active profile before starting another one.")
      return
    }

    strategyButtonPress(profile)
  }

  private func loadApp() {
    strategyManager.loadActiveSession(context: context)
  }

  private func onAppearApp() {
    requestAuthorizer.refreshAuthorizationStatus()
    strategyManager.loadActiveSession(context: context)
    strategyManager.cleanUpGhostSchedules(context: context)
    refreshAlerts()
  }

  private func refreshAlerts() {
    alertsManager.refreshAlerts(
      profiles: profiles,
      authorizationStatus: requestAuthorizer.getAuthorizationStatus()
    )
  }

  private func presentAlert(_ alert: HomeAlert) {
    alertsManager.present(alert)
  }

  private func disabledReason(for alert: HomeAlert) -> String? {
    return alertsManager.disabledReason(
      for: alert,
      profiles: profiles,
      isBlocking: isBlocking
    )
  }

  private func runAlertPrimaryAction(for alert: HomeAlert) {
    alertsManager.runPrimaryAction(
      for: alert,
      profiles: profiles,
      isBlocking: isBlocking,
      requestAuthorizer: requestAuthorizer,
      onScheduleRepaired: {
        loadApp()
        refreshAlerts()
      }
    )
  }

  private func unloadApp() {
    strategyManager.stopTimer()
  }

  private func showErrorAlert(message: String) {
    alertTitle = "Whoops"
    alertMessage = message
    showingAlert = true
  }

  private func dismissAlert() {
    showingAlert = false
    strategyManager.errorMessage = nil
  }
}

#Preview {
  HomeView()
    .environmentObject(RequestAuthorizer())
    .environmentObject(TipManager())
    .environmentObject(AlertsManager())
    .environmentObject(NavigationManager())
    .environmentObject(StrategyManager())
    .defaultAppStorage(UserDefaults(suiteName: "preview")!)
    .onAppear {
      UserDefaults(suiteName: "preview")!.set(
        false,
        forKey: "showIntroScreen"
      )
    }
}
