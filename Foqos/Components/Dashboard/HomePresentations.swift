import SwiftUI

struct HomePresentations: ViewModifier {
  @EnvironmentObject private var requestAuthorizer: RequestAuthorizer
  @EnvironmentObject private var strategyManager: StrategyManager
  @EnvironmentObject private var alertsManager: AlertsManager

  @Binding var presentation: HomePresentationState
  @Binding var showIntroScreen: Bool

  let profiles: [BlockedProfiles]
  let onStartProfile: (BlockedProfiles) -> Void
  let onStopProfile: (BlockedProfiles) -> Void
  let alertDisabledReason: (HomeAlert) -> String?
  let onAlertPrimaryAction: (HomeAlert) -> Void
  let onDismissError: () -> Void

  func body(content: Content) -> some View {
    content
      .sheet(isPresented: $presentation.isProfileListPresent) {
        BlockedProfileListView()
      }
      .sheet(item: $alertsManager.selectedAlert) { alert in
        HomeAlertDetailView(
          alert: alert,
          disabledReason: alertDisabledReason(alert),
          onPrimaryAction: {
            onAlertPrimaryAction(alert)
          }
        )
        .presentationDetents([.medium, .large])
      }
      .fullScreenCover(isPresented: $showIntroScreen) {
        IntroView {
          requestAuthorizer.requestAuthorization()
        }.interactiveDismissDisabled()
      }
      .fullScreenCover(isPresented: $presentation.showActiveProfileSessionView) {
        HomeActiveSessionView(onStopProfile: onStopProfile)
      }
      .sheet(item: $presentation.profileToShowStats) { profile in
        ProfileInsightsView(profile: profile)
      }
      .sheet(item: $presentation.profileToEdit) { profile in
        BlockedProfileView(profile: profile)
      }
      .sheet(item: $presentation.dashboardInsightsContext) { context in
        ProfileInsightsView(
          profile: context.profile,
          initialViewMode: context.viewMode,
          initialSelectedDate: context.selectedDate
        )
      }
      .sheet(
        isPresented: $presentation.showNewProfileView,
      ) {
        BlockedProfileView(profile: nil)
      }
      .sheet(
        isPresented: $presentation.showGuidedProfileCreationView,
      ) {
        GuidedBlockedProfileCreationView()
      }
      .sheet(isPresented: $presentation.showStartProfilePicker) {
        StartProfilePickerView(
          profiles: profiles,
          isBlocking: strategyManager.isBlocking,
          activeSessionProfileId: strategyManager.activeSession?.blockedProfile.id,
          startingProfileId: presentation.navigateToProfileId,
          onGoTapped: { profile in
            onStartProfile(profile)
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
      .sheet(isPresented: $presentation.showDonationView) {
        SupportView()
      }
      .sheet(isPresented: $presentation.showSettingsView) {
        SettingsView()
      }
      .alert(presentation.alertTitle, isPresented: $presentation.showingAlert) {
        Button("OK", role: .cancel) { onDismissError() }
      } message: {
        Text(presentation.alertMessage)
      }
  }

  private var strategyActionSheetBinding: Binding<Bool> {
    Binding(
      get: {
        strategyManager.showCustomStrategyView && !presentation.showActiveProfileSessionView
      },
      set: { isPresented in
        if !isPresented {
          strategyManager.showCustomStrategyView = false
        }
      }
    )
  }

}
