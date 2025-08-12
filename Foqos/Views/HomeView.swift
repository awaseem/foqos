import FamilyControls
import SwiftData
import SwiftUI

struct HomeView: View {
  @Environment(\.modelContext) private var context
  @Environment(\.openURL) var openURL

  @EnvironmentObject var requestAuthorizer: RequestAuthorizer
  @EnvironmentObject var strategyManager: StrategyManager
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

  // Edit profile
  @State private var profileToEdit: BlockedProfiles? = nil

  // Donation View
  @State private var showDonationView = false

  // Activity sessions
  @Query(sort: \BlockedProfileSession.startTime, order: .reverse) private
    var sessions: [BlockedProfileSession]
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

  var body: some View {
    ScrollView(showsIndicators: false) {
      VStack(alignment: .leading, spacing: 30) {
        HStack(alignment: .center) {
          AppTitle()
          Spacer()
          RoundedButton(
            "Support",
            action: {
              showDonationView = true
            }, iconName: "heart.fill")
        }
        .padding(.trailing, 16)
        .padding(.top, 16)

        if profiles.isEmpty {
          Welcome(onTap: {
            showNewProfileView = true
          })
          .padding(.horizontal, 16)
        }

        if !profiles.isEmpty {
          BlockedSessionsHabitTracker(
            sessions: recentCompletedSessions
          )
          .padding(.horizontal, 16)

          BlockedProfileCarousel(
            profiles: profiles,
            isBlocking: isBlocking,
            isBreakAvailable: isBreakAvailable,
            isBreakActive: isBreakActive,
            activeSessionProfileId: activeSessionProfileId,
            elapsedTime: strategyManager.elapsedTime,
            onStartTapped: { profile in
              strategyButtonPress(profile)
            },
            onStopTapped: { profile in
              strategyButtonPress(profile)
            },
            onEditTapped: { profile in
              profileToEdit = profile
            },
            onBreakTapped: { _ in
              strategyManager.toggleBreak()
            },
            onManageTapped: {
              isProfileListPresent = true
            }
          )
        }

        VersionFooter(
          authorizationStatus: requestAuthorizer.getAuthorizationStatus(),
          onAuthorizationHandler: {
            requestAuthorizer.requestAuthorization()
          }
        )
        .frame(maxWidth: .infinity)
      }
    }
    .refreshable {
      loadApp()
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
    .onChange(of: requestAuthorizer.isAuthorized) { _, newValue in
      if newValue {
        showIntroScreen = false
      } else {
        showIntroScreen = true
      }
    }
    .onChange(of: profiles) { oldValue, newValue in
      if !newValue.isEmpty {
        loadApp()
      }
    }
    .onReceive(strategyManager.$errorMessage) { errorMessage in
      if let message = errorMessage {
        showErrorAlert(message: message)
      }
    }
    .onAppear {
      loadApp()
    }
    .onDisappear {
      unloadApp()
    }.sheet(isPresented: $showIntroScreen) {
      IntroView {
        requestAuthorizer.requestAuthorization()
      }.interactiveDismissDisabled()
    }.sheet(item: $profileToEdit) { profile in
      BlockedProfileView(profile: profile)
    }
    .sheet(
      isPresented: $showNewProfileView,
    ) {
      BlockedProfileView(profile: nil)
    }
    .sheet(isPresented: $strategyManager.showCustomStrategyView) {
      BlockingStrategyActionView(
        customView: strategyManager.customStrategyView
      )
    }
    .sheet(isPresented: $showDonationView) {
      SupportView()
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

  private func loadApp() {
    strategyManager.loadActiveSession(context: context)
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
  }
}

#Preview {
  HomeView()
    .environmentObject(RequestAuthorizer())
    .environmentObject(TipManager())
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
