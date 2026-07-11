import FamilyControls
import SwiftData
import SwiftUI

private enum GuidedProfileStep: Int, CaseIterable, Identifiable {
  case name
  case strategy
  case apps
  case domains
  case strictUnlocks
  case schedule
  case breaks
  case strictSafeguards
  case sessionSafeguards
  case notifications
  case review

  var id: Int { rawValue }

  var title: String {
    switch self {
    case .name:
      return "Name"
    case .strategy:
      return "Method"
    case .apps:
      return "Apps"
    case .domains:
      return "Websites"
    case .strictUnlocks:
      return "Unlocks"
    case .schedule:
      return "Schedule"
    case .breaks:
      return "Breaks"
    case .strictSafeguards:
      return "Protection"
    case .sessionSafeguards:
      return "Session"
    case .notifications:
      return "Notifications"
    case .review:
      return "Review"
    }
  }

  var introTitle: String {
    switch self {
    case .name:
      return "Name this profile"
    case .strategy:
      return "Choose how it starts and stops"
    case .apps:
      return "Choose apps and how to block them"
    case .domains:
      return "Choose domains and how to block them"
    case .strictUnlocks:
      return "Set physical unlocks"
    case .schedule:
      return "Add a schedule"
    case .breaks:
      return "Allow breaks"
    case .strictSafeguards:
      return "Choose session protection"
    case .sessionSafeguards:
      return "Choose session controls"
    case .notifications:
      return "Set notifications"
    case .review:
      return "Review your profile"
    }
  }

  var introDescription: String {
    switch self {
    case .name:
      return "Profiles group the apps, websites, schedules, and rules you want to use together."
    case .strategy:
      return
        "Pick the blocking method that fits this profile. "
        + "You can mix and match how you want to start and stop."
    case .apps:
      return "Select the apps or categories this profile should restrict or allow."
    case .domains:
      return "Add specific domains and decide whether Safari website blocking applies."
    case .strictUnlocks:
      return
        "Some strategies let any NFC tag, QR code, or barcode unlock profiles. "
        + "Physical unlocks require a specific tag or code. You can add more than one."
    case .schedule:
      return "Schedules can start this profile automatically on selected days."
    case .breaks:
      return "Timed breaks let you pause once during a session without ending the profile."
    case .strictSafeguards:
      return
        "These settings make it harder to work around restrictions "
        + "by deleting or installing apps."
    case .sessionSafeguards:
      return
        "Control how active sessions can be stopped and whether emergency unblocks are allowed."
    case .notifications:
      return "Live Activities and reminders can help you manage your session."
    case .review:
      return "Create the profile now, or go back to adjust any section."
    }
  }
}

struct GuidedBlockedProfileCreationView: View {
  @Environment(\.modelContext) private var modelContext
  @Environment(\.dismiss) private var dismiss
  @EnvironmentObject private var themeManager: ThemeManager

  let onBackFromFirst: (() -> Void)?

  @StateObject private var draft = BlockedProfileDraft()

  @State private var currentStep: GuidedProfileStep = .name
  @State private var showingActivityPicker = false
  @State private var showingDomainPicker = false
  @State private var showingSchedulePicker = false
  @State private var showingStrategyPicker = false
  @State private var alertIdentifier: AlertIdentifier?
  @State private var navigationDirection: CGFloat = 1

  private let steps = GuidedProfileStep.allCases

  private var currentStepIndex: Int {
    return steps.firstIndex(of: currentStep) ?? 0
  }

  private var isFirstStep: Bool {
    return currentStepIndex == 0
  }

  private var isLastStep: Bool {
    return currentStepIndex == steps.count - 1
  }

  private var canContinue: Bool {
    return currentStep != .name || draft.isValid
  }

  private var stepAnimation: Animation {
    .spring(response: 0.28, dampingFraction: 0.84, blendDuration: 0.04)
  }

  private var stepTransition: AnyTransition {
    let insertionEdge: Edge = navigationDirection > 0 ? .bottom : .top
    let removalEdge: Edge = navigationDirection > 0 ? .top : .bottom

    return .asymmetric(
      insertion: .move(edge: insertionEdge)
        .combined(with: .opacity)
        .combined(with: .scale(scale: 0.985, anchor: .top)),
      removal: .move(edge: removalEdge)
        .combined(with: .opacity)
    )
  }

  init(onBackFromFirst: (() -> Void)? = nil) {
    self.onBackFromFirst = onBackFromFirst
  }

  var body: some View {
    NavigationStack {
      VStack(spacing: 0) {
        ScrollView {
          VStack(alignment: .leading, spacing: 0) {
            stepIntroHeader
              .id("header-\(currentStep.id)")
              .transition(stepTransition)

            stepContent
              .id("content-\(currentStep.id)")
              .transition(stepTransition)
          }
        }
        .animation(stepAnimation, value: currentStep)
        .frame(maxWidth: .infinity)
        .background(Color(.systemGroupedBackground))

        stepControls
      }
      .background(Color(.systemGroupedBackground).ignoresSafeArea())
      .toolbar {
        ToolbarItem(placement: .topBarLeading) {
          Button(action: handleBackAction) {
            Label("Back", systemImage: "chevron.left")
          }
        }

        ToolbarItem(placement: .topBarTrailing) {
          Button(action: { dismiss() }) {
            Image(systemName: "xmark")
          }
          .accessibilityLabel("Cancel")
        }
      }
      .sheet(isPresented: $showingActivityPicker) {
        AppPicker(
          selection: $draft.selectedActivity,
          isPresented: $showingActivityPicker,
          allowMode: draft.enableAllowMode
        )
      }
      .sheet(isPresented: $showingDomainPicker) {
        DomainPicker(
          domains: $draft.domains,
          isPresented: $showingDomainPicker,
          allowMode: draft.enableAllowModeDomain
        )
      }
      .sheet(isPresented: $showingSchedulePicker) {
        SchedulePicker(
          schedule: $draft.schedule,
          isPresented: $showingSchedulePicker
        )
      }
      .sheet(isPresented: $showingStrategyPicker) {
        StrategyPicker(
          strategies: StrategyManager.availableStrategies,
          selectedStrategy: $draft.selectedStrategy,
          isPresented: $showingStrategyPicker
        )
      }
      .alert(item: $alertIdentifier) { alert in
        Alert(
          title: Text("Error"),
          message: Text(alert.errorMessage ?? "An unknown error occurred"),
          dismissButton: .default(Text("OK"))
        )
      }
    }
  }

  private var stepIntroHeader: some View {
    VStack(alignment: .leading, spacing: 10) {
      Text("Step \(currentStepIndex + 1) of \(steps.count)")
        .font(.caption)
        .fontWeight(.semibold)
        .foregroundStyle(.primary)
        .padding(.leading, 1)
        .contentTransition(.numericText())
        .animation(.easeInOut(duration: 0.16), value: currentStepIndex)

      Text(currentStepIntroTitle)
        .font(.largeTitle)
        .fontWeight(.bold)
        .foregroundStyle(.primary)
        .contentTransition(.interpolate)

      Text(currentStepIntroDescription)
        .font(.body)
        .foregroundStyle(.secondary)
        .lineSpacing(3)
        .contentTransition(.interpolate)
    }
    .frame(maxWidth: .infinity, alignment: .leading)
    .padding(.horizontal, 20)
    .padding(.top, 20)
    .padding(.bottom, 28)
  }

  private var currentStepIntroTitle: String {
    if currentStep == .breaks && !draft.selectedStrategyAllowsTimedBreaks {
      return "Breaks are off"
    }

    return currentStep.introTitle
  }

  private var currentStepIntroDescription: String {
    if currentStep == .breaks && !draft.selectedStrategyAllowsTimedBreaks {
      return
        "Temporary Access already gives short opens for blocked apps and categories, so timed breaks are not needed."
    }

    return currentStep.introDescription
  }

  @ViewBuilder
  private var stepContent: some View {
    switch currentStep {
    case .name:
      guidedCard(title: "Name") {
        BlockedProfileNameFields(
          draft: draft,
          disabled: false,
          showsFieldLabels: false
        )
      }

    case .strategy:
      guidedCard(title: "Blocking Strategy") {
        BlockedProfileStrategyFields(
          draft: draft,
          showingStrategyPicker: $showingStrategyPicker,
          disabled: false,
          showsSeparators: true
        )
      }

    case .apps:
      guidedCard(title: (draft.enableAllowMode ? "Allowed" : "Blocked") + " Apps") {
        BlockedProfileAppsFields(
          draft: draft,
          showingActivityPicker: $showingActivityPicker,
          disabled: false,
          showsSeparators: true
        )
      }

    case .domains:
      guidedCard(title: (draft.enableAllowModeDomain ? "Allowed" : "Blocked") + " Domains") {
        BlockedProfileDomainsFields(
          draft: draft,
          showingDomainPicker: $showingDomainPicker,
          disabled: false,
          showsSeparators: true
        )
      }

    case .strictUnlocks:
      guidedCard(title: "Physical Unlocks") {
        BlockedProfileStrictUnlocksFields(draft: draft, disabled: false)
      }

    case .schedule:
      guidedCard(title: "Schedule") {
        BlockedProfileScheduleFields(
          draft: draft,
          showingSchedulePicker: $showingSchedulePicker,
          disabled: false
        )
      }

    case .breaks:
      guidedCard(title: "Breaks") {
        BlockedProfileBreaksFields(
          draft: draft,
          disabled: false,
          showsSeparators: true
        )
      }

    case .strictSafeguards:
      guidedCard(title: "Session Protection") {
        BlockedProfileStrictSafeguardsFields(
          draft: draft,
          disabled: false,
          showsSeparators: true
        )
      }

    case .sessionSafeguards:
      guidedCard(title: "Stop Options") {
        BlockedProfileSessionSafeguardsFields(
          draft: draft,
          disabled: false,
          showsSeparators: true
        )
      }

    case .notifications:
      guidedCard(title: "Notifications") {
        BlockedProfileNotificationsFields(
          draft: draft,
          profile: nil,
          disabled: false,
          showsSeparators: true
        )
      }

    case .review:
      guidedCard(title: "Summary") {
        GuidedProfileReviewContent(draft: draft)
      }
    }
  }

  private func guidedCard<Content: View>(
    title: String,
    @ViewBuilder content: () -> Content
  ) -> some View {
    VStack(alignment: .leading, spacing: 14) {
      VStack(alignment: .leading, spacing: 16) {
        content()
      }
      .frame(maxWidth: .infinity, alignment: .leading)
      .padding(.horizontal, 20)
      .padding(.vertical, 18)
      .background(Color(.secondarySystemGroupedBackground))
      .clipShape(RoundedRectangle(cornerRadius: 28, style: .continuous))
    }
    .padding(.horizontal, 20)
    .padding(.bottom, 28)
  }

  private var stepControls: some View {
    ActionButton(
      title: isLastStep ? "Create Profile" : "Next",
      backgroundColor: themeManager.themeColor,
      isDisabled: !canContinue
    ) {
      handlePrimaryAction()
    }
    .padding(.horizontal, 20)
    .padding(.top, 12)
    .padding(.bottom, 16)
  }

  private func handlePrimaryAction() {
    if isLastStep {
      createProfile()
    } else {
      goNext()
    }
  }

  private func goNext() {
    guard currentStepIndex < steps.count - 1 else { return }
    navigationDirection = 1
    withAnimation(stepAnimation) {
      currentStep = steps[currentStepIndex + 1]
    }
  }

  private func goBack() {
    guard currentStepIndex > 0 else { return }
    navigationDirection = -1
    withAnimation(stepAnimation) {
      currentStep = steps[currentStepIndex - 1]
    }
  }

  private func handleBackAction() {
    if isFirstStep {
      onBackFromFirst?() ?? dismiss()
    } else {
      goBack()
    }
  }

  private func createProfile() {
    do {
      _ = try draft.save(existingProfile: nil, in: modelContext)
      dismiss()
    } catch {
      alertIdentifier = AlertIdentifier(id: .error, errorMessage: error.localizedDescription)
    }
  }
}

private struct GuidedProfileReviewContent: View {
  @ObservedObject var draft: BlockedProfileDraft

  var body: some View {
    VStack(spacing: 0) {
      reviewRow(title: "Name", value: draft.name)
      reviewDivider
      reviewRow(title: "Strategy", value: draft.selectedStrategy?.name ?? "NFC")
      reviewDivider
      reviewRow(
        title: "Apps", value: FamilyActivityUtil.getCountDisplayText(draft.selectedActivity))
      reviewDivider
      reviewRow(title: "Domains", value: domainSummary)
      reviewDivider
      reviewRow(title: "Schedule", value: scheduleSummary)
      reviewDivider
      reviewRow(title: "Breaks", value: breaksSummary)
      reviewDivider
      reviewRow(title: "Safeguards", value: safeguardsSummary)
      reviewDivider
      reviewRow(title: "Notifications", value: notificationsSummary)
    }
  }

  private func reviewRow(title: String, value: String) -> some View {
    HStack(alignment: .firstTextBaseline, spacing: 16) {
      Text(title)
        .font(.body)
        .fontWeight(.medium)
        .foregroundStyle(.primary)
        .frame(width: 118, alignment: .leading)

      Text(value)
        .font(.body)
        .foregroundStyle(.secondary)
        .multilineTextAlignment(.trailing)
        .lineLimit(2)
        .minimumScaleFactor(0.85)
        .frame(maxWidth: .infinity, alignment: .trailing)
    }
    .padding(.vertical, 12)
  }

  private var reviewDivider: some View {
    Divider()
      .padding(.leading, 118)
  }

  private var domainSummary: String {
    if draft.domains.isEmpty {
      return "No domains selected"
    }

    return "\(draft.domains.count) \(draft.domains.count == 1 ? "domain" : "domains")"
  }

  private var scheduleSummary: String {
    return draft.schedule.days.isEmpty ? "No schedule set" : draft.schedule.summaryText
  }

  private var breaksSummary: String {
    if !draft.selectedStrategyAllowsTimedBreaks {
      return "Not needed"
    }

    guard draft.enableBreaks else {
      return "Disabled"
    }

    if draft.allowMultipleBreaks {
      return "\(draft.breakTimeInMinutes) minutes, reusable"
    }

    return "\(draft.breakTimeInMinutes) minutes"
  }

  private var safeguardsSummary: String {
    var enabled: [String] = []

    if draft.enableStrictMode {
      enabled.append("App deletion blocked")
    }

    if draft.enableBlockAppInstallation {
      enabled.append("New app installs blocked")
    }

    if draft.disableBackgroundStops {
      enabled.append("Foqos required to stop")
    }

    if !draft.enableEmergencyUnblock {
      enabled.append("Emergency unblock disabled")
    }

    return enabled.isEmpty ? "Default" : enabled.joined(separator: ", ")
  }

  private var notificationsSummary: String {
    var enabled: [String] = []

    if draft.enableLiveActivity {
      enabled.append("Live Activity")
    }

    if draft.enableReminder {
      enabled.append("Reminder")
    }

    return enabled.isEmpty ? "Disabled" : enabled.joined(separator: ", ")
  }
}

#Preview {
  GuidedBlockedProfileCreationView()
    .environmentObject(NFCWriter())
    .environmentObject(StrategyManager())
    .modelContainer(for: BlockedProfiles.self, inMemory: true)
}
