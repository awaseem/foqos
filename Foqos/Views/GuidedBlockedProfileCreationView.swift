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
  case safeguards
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
    case .safeguards:
      return "Safeguards"
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
      return "Choose apps"
    case .domains:
      return "Choose websites"
    case .strictUnlocks:
      return "Set unlock rules"
    case .schedule:
      return "Add a schedule"
    case .breaks:
      return "Allow breaks"
    case .safeguards:
      return "Choose safeguards"
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
      return "Pick the blocking method that fits this profile. You can change it later."
    case .apps:
      return "Select the apps or categories this profile should restrict or allow."
    case .domains:
      return "Add specific domains and decide whether Safari website blocking applies."
    case .strictUnlocks:
      return "Optional physical unlock methods can make stopping a session more intentional."
    case .schedule:
      return "Schedules can start this profile automatically on selected days."
    case .breaks:
      return "Timed breaks let you pause once during a session without ending the profile."
    case .safeguards:
      return "These settings make it harder to work around active restrictions."
    case .notifications:
      return "Live Activities and reminders can help you keep sessions visible."
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

  init(onBackFromFirst: (() -> Void)? = nil) {
    self.onBackFromFirst = onBackFromFirst
  }

  var body: some View {
    NavigationStack {
      VStack(spacing: 0) {
        stepIntroHeader

        Spacer()

        Form {
          stepContent
        }

        stepControls
      }
      .toolbar {
        ToolbarItem(placement: .topBarLeading) {
          Button(action: handleBackAction) {
            Label("Back", systemImage: "chevron.left")
          }
          .foregroundStyle(themeManager.themeColor)
        }

        ToolbarItem(placement: .topBarTrailing) {
          Button(action: { dismiss() }) {
            Image(systemName: "xmark")
          }
          .accessibilityLabel("Cancel")
          .foregroundStyle(themeManager.themeColor)
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
          strategies: StrategyManager.availableStrategies.filter { !$0.hidden },
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
  
      Text(currentStep.introTitle)
        .font(.largeTitle)
        .fontWeight(.bold)
        .foregroundStyle(.primary)

      Text(currentStep.introDescription)
        .font(.body)
        .foregroundStyle(.secondary)
        .lineSpacing(3)
    }
    .frame(maxWidth: .infinity, alignment: .leading)
    .padding(.horizontal, 20)
    .padding(.top, 18)
    .padding(.bottom, 14)
    .background(Color(.systemGroupedBackground))
  }

  @ViewBuilder
  private var stepContent: some View {
    switch currentStep {
    case .name:
      BlockedProfileNameSection(draft: draft, disabled: false)

    case .strategy:
      BlockedProfileStrategySection(
        draft: draft,
        showingStrategyPicker: $showingStrategyPicker,
        disabled: false
      )

    case .apps:
      BlockedProfileAppsSection(
        draft: draft,
        showingActivityPicker: $showingActivityPicker,
        disabled: false
      )

    case .domains:
      BlockedProfileDomainsSection(
        draft: draft,
        showingDomainPicker: $showingDomainPicker,
        disabled: false
      )

    case .strictUnlocks:
      BlockedProfileStrictUnlocksSection(draft: draft, disabled: false)

    case .schedule:
      BlockedProfileScheduleSection(
        draft: draft,
        showingSchedulePicker: $showingSchedulePicker,
        disabled: false
      )

    case .breaks:
      BlockedProfileBreaksSection(draft: draft, disabled: false)

    case .safeguards:
      BlockedProfileSafeguardsSection(draft: draft, disabled: false)

    case .notifications:
      BlockedProfileNotificationsSection(
        draft: draft,
        profile: nil,
        disabled: false
      )

    case .review:
      GuidedProfileReviewSection(draft: draft)
    }
  }

  private var stepControls: some View {
    Button(action: handlePrimaryAction) {
      Text(isLastStep ? "Create Profile" : "Next")
        .font(.headline)
        .foregroundStyle(.white)
        .frame(maxWidth: .infinity)
        .frame(height: 50)
        .background(
          RoundedRectangle(cornerRadius: 12)
            .fill(canContinue ? themeManager.themeColor : Color.gray.opacity(0.45))
        )
    }
    .disabled(!canContinue)
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
    withAnimation(.easeInOut(duration: 0.2)) {
      currentStep = steps[currentStepIndex + 1]
    }
  }

  private func goBack() {
    guard currentStepIndex > 0 else { return }
    withAnimation(.easeInOut(duration: 0.2)) {
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

private struct GuidedProfileReviewSection: View {
  @ObservedObject var draft: BlockedProfileDraft

  var body: some View {
    Section("Summary") {
      LabeledContent("Name", value: draft.name)
      LabeledContent("Strategy", value: draft.selectedStrategy?.name ?? "NFC")
      LabeledContent("Apps", value: FamilyActivityUtil.getCountDisplayText(draft.selectedActivity))
      LabeledContent("Domains", value: domainSummary)
      LabeledContent("Schedule", value: scheduleSummary)
      LabeledContent("Breaks", value: breaksSummary)
      LabeledContent("Safeguards", value: safeguardsSummary)
      LabeledContent("Notifications", value: notificationsSummary)
    }
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
    return draft.enableBreaks ? "\(draft.breakTimeInMinutes) minutes" : "Disabled"
  }

  private var safeguardsSummary: String {
    var enabled: [String] = []

    if draft.enableStrictMode {
      enabled.append("Strict")
    }

    if draft.enableBlockAppInstallation {
      enabled.append("Install blocking")
    }

    if draft.disableBackgroundStops {
      enabled.append("Background stops disabled")
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
