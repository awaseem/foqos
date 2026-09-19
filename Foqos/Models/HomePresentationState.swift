import Foundation

struct HomePresentationState {
  var isProfileListPresent = false
  var showNewProfileView = false
  var showGuidedProfileCreationView = false
  var showStartProfilePicker = false
  var showDonationView = false
  var showSettingsView = false
  var showActiveProfileSessionView = false

  var profileToEdit: BlockedProfiles?
  var profileToShowStats: BlockedProfiles?
  var dashboardInsightsContext: DashboardInsightsContext?
  var navigateToProfileId: UUID?

  var showingAlert = false
  var alertTitle = ""
  var alertMessage = ""
}
