import FamilyControls
import SwiftUI

private struct ProfileFieldDivider: View {
  var isVisible: Bool

  var body: some View {
    if isVisible {
      Divider()
    }
  }
}

struct BlockedProfileNameFields: View {
  @ObservedObject var draft: BlockedProfileDraft
  var disabled: Bool
  var showsFieldLabels: Bool = true

  var body: some View {
    TextField(
      showsFieldLabels ? "Profile Name" : "",
      text: $draft.name,
      prompt: Text("Profile Name")
    )
    .textContentType(.none)
    .disabled(disabled)
  }
}

struct BlockedProfileNameSection: View {
  @ObservedObject var draft: BlockedProfileDraft
  var disabled: Bool

  var body: some View {
    Section("Name") {
      BlockedProfileNameFields(draft: draft, disabled: disabled)
    }
  }
}

struct BlockedProfileStrategyFields: View {
  @EnvironmentObject private var themeManager: ThemeManager

  @ObservedObject var draft: BlockedProfileDraft
  @Binding var showingStrategyPicker: Bool
  var disabled: Bool
  var showsSeparators: Bool = false

  var body: some View {
    Button(action: { showingStrategyPicker = true }) {
      HStack {
        Text("Choose Strategy")
          .foregroundStyle(themeManager.themeColor)
        Spacer()
        Image(systemName: "chevron.right")
          .foregroundStyle(.gray)
      }
    }
    .disabled(disabled)

    if let selectedStrategy = draft.selectedStrategy {
      ProfileFieldDivider(isVisible: showsSeparators)

      StrategyRow(
        strategy: selectedStrategy,
        isSelected: false,
        onTap: {},
        accessoryStyle: .none
      )
      .allowsHitTesting(false)
    }
  }
}

struct BlockedProfileStrategySection: View {
  @EnvironmentObject private var themeManager: ThemeManager

  @ObservedObject var draft: BlockedProfileDraft
  @Binding var showingStrategyPicker: Bool
  var disabled: Bool
  var showsStartSettings: Bool = false
  var onUpdateStartSettings: ((StrategyStartSettingsKind) -> Void)?

  var body: some View {
    Section {
      BlockedProfileStrategyFields(
        draft: draft,
        showingStrategyPicker: $showingStrategyPicker,
        disabled: disabled
      )

      if showsStartSettings,
        let settingsKind = StrategyStartSettingsKind(strategy: draft.selectedStrategy)
      {
        Button {
          onUpdateStartSettings?(settingsKind)
        } label: {
          HStack {
            Text("Update Start Settings")
              .foregroundStyle(themeManager.themeColor)
            Spacer()
            Image(systemName: "chevron.right")
              .foregroundStyle(.secondary)
          }
        }
        .disabled(disabled)

        CustomToggle(
          title: "Ask Me Every Time",
          description: "Turn off to use the saved settings automatically.",
          isOn: $draft.askForStartSettings,
          isDisabled: disabled
        )
      }
    } header: {
      Text("Blocking Strategy")
    }
  }
}

struct BlockedProfileAppsFields: View {
  @ObservedObject var draft: BlockedProfileDraft
  @Binding var showingActivityPicker: Bool
  var disabled: Bool
  var showsSeparators: Bool = false

  var body: some View {
    BlockedProfileAppSelector(
      selection: draft.selectedActivity,
      buttonAction: { showingActivityPicker = true },
      allowMode: draft.enableAllowMode,
      disabled: disabled
    )

    ProfileFieldDivider(isVisible: showsSeparators)

    CustomToggle(
      title: "Allow Only Selected Apps",
      description:
        "Only selected apps stay available during sessions. Turning this on clears your blocked-app selection.",
      isOn: $draft.enableAllowMode,
      isDisabled: disabled || !draft.selectedStrategySupportsAllowMode,
      errorMessage: draft.selectedStrategySupportsAllowMode
        ? nil : "Allow-only mode isn't supported with Temporary Access."
    )

    ProfileFieldDivider(isVisible: showsSeparators)

    CustomToggle(
      title: "Block Websites in Safari",
      description:
        "Also block selected websites in Safari. When off, Safari stays unrestricted.",
      isOn: $draft.enableSafariBlocking,
      isDisabled: disabled
    )
    .onChange(of: draft.enableAllowMode) { _, newValue in
      draft.selectedActivity = FamilyActivitySelection(includeEntireCategory: newValue)
    }
  }
}

struct BlockedProfileAppsSection: View {
  @ObservedObject var draft: BlockedProfileDraft
  @Binding var showingActivityPicker: Bool
  var disabled: Bool

  var body: some View {
    Section((draft.enableAllowMode ? "Allowed" : "Blocked") + " Apps") {
      BlockedProfileAppsFields(
        draft: draft,
        showingActivityPicker: $showingActivityPicker,
        disabled: disabled
      )
    }
  }
}

struct BlockedProfileDomainsFields: View {
  @ObservedObject var draft: BlockedProfileDraft
  @Binding var showingDomainPicker: Bool
  var disabled: Bool
  var showsSeparators: Bool = false

  var body: some View {
    BlockedProfileDomainSelector(
      domains: draft.domains,
      buttonAction: { showingDomainPicker = true },
      allowMode: draft.enableAllowModeDomain,
      disabled: disabled
    )

    ProfileFieldDivider(isVisible: showsSeparators)

    CustomToggle(
      title: "Sync to Mac",
      description:
        "Block the same selected domains on your Mac with the Foqos for Mac app.",
      isOn: $draft.enableMacSync,
      isDisabled: disabled,
      learnMoreURL: URL(string: "https://www.foqos.app/mac.html")
    )
    .onChange(of: draft.enableMacSync) { _, newValue in
      if newValue {
        draft.enableAllowModeDomain = false
        draft.enableAdultContentBlocking = false
      }
    }

    ProfileFieldDivider(isVisible: showsSeparators)

    CustomToggle(
      title: "Allow Only Selected Domains",
      description:
        "Only selected domains stay available during sessions.",
      isOn: $draft.enableAllowModeDomain,
      isDisabled: disabled || draft.enableMacSync,
      errorMessage: draft.enableMacSync ? "Allow-only mode isn't supported on Mac." : nil
    )

    ProfileFieldDivider(isVisible: showsSeparators)

    CustomToggle(
      title: "Block Adult Websites",
      description:
        "Use Apple's adult-content filter during sessions. You can still add extra domains to block.",
      isOn: $draft.enableAdultContentBlocking,
      isDisabled: disabled || draft.enableMacSync,
      errorMessage: draft.enableMacSync ? "Adult website blocking isn't supported on Mac." : nil
    )
    .onChange(of: draft.enableAllowModeDomain) { _, newValue in
      if newValue {
        draft.enableAdultContentBlocking = false
      }
    }
    .onChange(of: draft.enableAdultContentBlocking) { _, newValue in
      if newValue {
        draft.enableAllowModeDomain = false
      }
    }
  }
}

struct BlockedProfileDomainsSection: View {
  @ObservedObject var draft: BlockedProfileDraft
  @Binding var showingDomainPicker: Bool
  var disabled: Bool

  var body: some View {
    Section((draft.enableAllowModeDomain ? "Allowed" : "Blocked") + " Domains") {
      BlockedProfileDomainsFields(
        draft: draft,
        showingDomainPicker: $showingDomainPicker,
        disabled: disabled
      )
    }
  }
}

struct BlockedProfileStrictUnlocksFields: View {
  @ObservedObject var draft: BlockedProfileDraft
  var disabled: Bool

  var body: some View {
    BlockedProfilePhysicalUnblockSelector(
      physicalUnblockItems: $draft.physicalUnblockItems,
      disabled: disabled
    )
  }
}

struct BlockedProfileStrictUnlocksSection: View {
  @ObservedObject var draft: BlockedProfileDraft
  var disabled: Bool

  var body: some View {
    Section("Physical Unlocks") {
      BlockedProfileStrictUnlocksFields(draft: draft, disabled: disabled)
    }
  }
}

struct BlockedProfileScheduleFields: View {
  @ObservedObject var draft: BlockedProfileDraft
  @Binding var showingSchedulePicker: Bool
  var disabled: Bool

  var body: some View {
    BlockedProfileScheduleSelector(
      schedule: draft.schedule,
      buttonAction: { showingSchedulePicker = true },
      disabled: disabled
    )
  }
}

struct BlockedProfileScheduleSection: View {
  @ObservedObject var draft: BlockedProfileDraft
  @Binding var showingSchedulePicker: Bool
  var disabled: Bool

  var body: some View {
    Section("Schedule") {
      BlockedProfileScheduleFields(
        draft: draft,
        showingSchedulePicker: $showingSchedulePicker,
        disabled: disabled
      )
    }
  }
}

struct BlockedProfileBreaksFields: View {
  @EnvironmentObject private var themeManager: ThemeManager

  @ObservedObject var draft: BlockedProfileDraft
  var profile: BlockedProfiles? = nil
  var disabled: Bool
  var showsSeparators: Bool = false

  @State private var showingCustomBreakLimit = false
  @State private var showingResetConfirmation = false

  @ViewBuilder
  var body: some View {
    Group {
      if draft.selectedStrategyAllowsTimedBreaks {
        CustomToggle(
          title: "Allow Timed Breaks",
          description:
            "Take a break during your session. The break will automatically end after the selected duration.",
          isOn: $draft.enableBreaks,
          isDisabled: disabled
        )

        if draft.enableBreaks {
          ProfileFieldDivider(isVisible: showsSeparators)

          allowanceModePicker

          ProfileFieldDivider(isVisible: showsSeparators)

          durationRow

          if draft.breakAllowanceMode == .perBreak {
            ProfileFieldDivider(isVisible: showsSeparators)

            breakLimitRow
          }

          if showsResetControls {
            ProfileFieldDivider(isVisible: showsSeparators)

            resetPolicyPicker

            if draft.breakResetPolicy == .daily {
              ProfileFieldDivider(isVisible: showsSeparators)

              DatePicker(
                "Reset Time",
                selection: breakResetTimeBinding,
                displayedComponents: .hourAndMinute
              )
              .disabled(disabled)
            } else if profile != nil {
              ProfileFieldDivider(isVisible: showsSeparators)

              Button("Reset Break Usage Now") {
                showingResetConfirmation = true
              }
              .disabled(disabled)
            }

            Text(resetDescription)
              .font(.caption)
              .foregroundStyle(.secondary)
          }
        }
      } else {
        ProfileFieldNotice(
          title: "Breaks are off for Temporary Access",
          message:
            "This strategy already gives short opens for blocked apps and categories, so timed breaks are not needed for this profile."
        )
      }
    }
    .navigationDestination(isPresented: $showingCustomBreakLimit) {
      BreakCountPickerView(breakCountLimit: $draft.breakCountLimit) {
        draft.isBreakCountUnlimited = false
      }
    }
    .alert("Reset Break Usage?", isPresented: $showingResetConfirmation) {
      Button("Cancel", role: .cancel) {}
      Button("Reset") {
        if let profile {
          SharedData.resetBreakAllowanceUsage(for: profile.id)
        }
      }
    } message: {
      Text("This immediately restores the full configured break allowance.")
    }
  }

  private var allowanceModePicker: some View {
    VStack(alignment: .leading, spacing: 0) {
      Text("Allowance Mode")
        .font(.subheadline)
        .fontWeight(.semibold)
        .padding(.bottom, 4)

      selectionButton(
        title: "Per Break",
        description: "Each break receives the configured duration.",
        isSelected: draft.breakAllowanceMode == .perBreak
      ) {
        draft.breakAllowanceMode = .perBreak
      }

      Divider()

      selectionButton(
        title: "Shared Budget",
        description: "All breaks consume one pool of time.",
        isSelected: draft.breakAllowanceMode == .cumulative
      ) {
        draft.breakAllowanceMode = .cumulative
      }
    }
    .disabled(disabled)
  }

  private var durationRow: some View {
    NavigationLink {
      BreakDurationSelectionView(
        mode: draft.breakAllowanceMode,
        durationInMinutes: $draft.breakTimeInMinutes
      )
    } label: {
      HStack {
        Text(draft.breakAllowanceMode == .perBreak ? "Duration Per Break" : "Total Break Budget")

        Spacer()

        Text(DateFormatters.formatMinutes(draft.breakTimeInMinutes))
          .foregroundStyle(.secondary)
          .contentTransition(.numericText())
      }
    }
    .disabled(disabled)
  }

  private var breakLimitRow: some View {
    HStack {
      Text(breakLimitTitle)

      Spacer()

      Menu {
        ForEach([1, 3, 5, 10], id: \.self) { count in
          Button {
            draft.breakCountLimit = count
            draft.isBreakCountUnlimited = false
          } label: {
            menuLabel(
              title: "\(count)",
              isSelected: !draft.isBreakCountUnlimited && draft.breakCountLimit == count
            )
          }
        }

        Divider()

        Button {
          showingCustomBreakLimit = true
        } label: {
          Label("Custom…", systemImage: "number")
        }

        Button {
          draft.isBreakCountUnlimited = true
        } label: {
          menuLabel(title: "Unlimited", isSelected: draft.isBreakCountUnlimited)
        }
      } label: {
        HStack(spacing: 4) {
          Text(breakLimitValue)
          Image(systemName: "chevron.up.chevron.down")
            .font(.caption2)
        }
        .foregroundStyle(themeManager.themeColor)
      }
      .disabled(disabled)
    }
  }

  private var resetPolicyPicker: some View {
    VStack(alignment: .leading, spacing: 0) {
      Text("Reset Schedule")
        .font(.subheadline)
        .fontWeight(.semibold)
        .padding(.bottom, 4)

      selectionButton(
        title: "Daily",
        description: "Restore the allowance at a selected local time.",
        isSelected: draft.breakResetPolicy == .daily
      ) {
        draft.breakResetPolicy = .daily
      }

      Divider()

      selectionButton(
        title: "Never",
        description: "Preserve usage until it is manually reset.",
        isSelected: draft.breakResetPolicy == .never
      ) {
        draft.breakResetPolicy = .never
      }
    }
    .disabled(disabled)
  }

  private func selectionButton(
    title: String,
    description: String,
    isSelected: Bool,
    action: @escaping () -> Void
  ) -> some View {
    Button(action: action) {
      HStack(alignment: .top, spacing: 12) {
        Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
          .foregroundStyle(isSelected ? themeManager.themeColor : Color.secondary)
          .padding(.top, 2)

        VStack(alignment: .leading, spacing: 2) {
          Text(title)
            .foregroundStyle(.primary)
          Text(description)
            .font(.caption)
            .foregroundStyle(.secondary)
            .multilineTextAlignment(.leading)
        }

        Spacer()
      }
      .padding(.vertical, 8)
    }
    .buttonStyle(.plain)
    .accessibilityAddTraits(isSelected ? .isSelected : [])
  }

  @ViewBuilder
  private func menuLabel(title: String, isSelected: Bool) -> some View {
    if isSelected {
      Label(title, systemImage: "checkmark")
    } else {
      Text(title)
    }
  }

  private var breakLimitTitle: String {
    draft.breakResetPolicy == .daily ? "Breaks Per Day" : "Total Break Limit"
  }

  private var breakLimitValue: String {
    draft.isBreakCountUnlimited ? "Unlimited" : "\(draft.breakCountLimit)"
  }

  private var showsResetControls: Bool {
    draft.breakAllowanceMode == .cumulative || !draft.isBreakCountUnlimited
  }

  private var resetDescription: String {
    switch draft.breakResetPolicy {
    case .daily:
      return "The allowance renews every day at the selected local time."
    case .never:
      return "Used break time or break counts remain consumed until manually reset."
    }
  }

  private var breakResetTimeBinding: Binding<Date> {
    Binding(
      get: {
        Calendar.current.date(
          bySettingHour: draft.breakResetHour,
          minute: draft.breakResetMinute,
          second: 0,
          of: Date()
        ) ?? Date()
      },
      set: { date in
        draft.breakResetHour = Calendar.current.component(.hour, from: date)
        draft.breakResetMinute = Calendar.current.component(.minute, from: date)
      }
    )
  }
}

private struct BreakDurationSelectionView: View {
  @Environment(\.dismiss) private var dismiss

  let mode: BreakAllowanceMode
  @Binding var durationInMinutes: Int

  var body: some View {
    List {
      Section("Recommended") {
        ForEach(durationPresets, id: \.self) { duration in
          Button {
            durationInMinutes = duration
            dismiss()
          } label: {
            HStack {
              Text(DateFormatters.formatMinutes(duration))
                .foregroundStyle(.primary)
              Spacer()
              if durationInMinutes == duration {
                Image(systemName: "checkmark")
              }
            }
          }
        }
      }

      Section {
        NavigationLink {
          BreakDurationPickerView(
            title: mode == .perBreak ? "Duration Per Break" : "Total Break Budget",
            durationInMinutes: $durationInMinutes
          )
        } label: {
          HStack {
            Text("Custom Duration")
            Spacer()
            if !durationPresets.contains(durationInMinutes) {
              Text(DateFormatters.formatMinutes(durationInMinutes))
                .foregroundStyle(.secondary)
            }
          }
        }
      } footer: {
        if durationInMinutes > 4 * 60 {
          Text("Long breaks leave blocked apps available for most or all of the allowance period.")
        } else {
          Text("Custom durations can range from 5 minutes to 24 hours.")
        }
      }
    }
    .navigationTitle(mode == .perBreak ? "Break Duration" : "Break Budget")
  }

  private var durationPresets: [Int] {
    switch mode {
    case .perBreak:
      return [5, 10, 15, 30, 45, 60]
    case .cumulative:
      return [15, 30, 45, 60, 120, 240, 480, 720, 1_440]
    }
  }
}

private struct BreakCountPickerView: View {
  @Environment(\.dismiss) private var dismiss

  @Binding var breakCountLimit: Int
  let onSave: () -> Void

  @State private var selectedCount: Int

  init(breakCountLimit: Binding<Int>, onSave: @escaping () -> Void) {
    _breakCountLimit = breakCountLimit
    self.onSave = onSave
    _selectedCount = State(initialValue: min(max(breakCountLimit.wrappedValue, 1), 100))
  }

  var body: some View {
    Form {
      Section {
        Stepper(value: $selectedCount, in: 1...100) {
          HStack {
            Text("Break Limit")
            Spacer()
            Text("\(selectedCount)")
              .foregroundStyle(.secondary)
          }
        }
      } footer: {
        Text("Choose how many breaks are available before the allowance resets.")
      }
    }
    .navigationTitle("Custom Break Limit")
    .navigationBarTitleDisplayMode(.inline)
    .toolbar {
      ToolbarItem(placement: .confirmationAction) {
        Button("Done") {
          breakCountLimit = selectedCount
          onSave()
          dismiss()
        }
      }
    }
  }
}

private struct BreakDurationPickerView: View {
  @Environment(\.dismiss) private var dismiss

  let title: String
  @Binding var durationInMinutes: Int

  @State private var hours: Int
  @State private var minutes: Int

  init(title: String, durationInMinutes: Binding<Int>) {
    self.title = title
    _durationInMinutes = durationInMinutes

    let initialDuration = min(max(durationInMinutes.wrappedValue, 5), 24 * 60)
    _hours = State(initialValue: initialDuration / 60)
    _minutes = State(initialValue: initialDuration % 60 / 5 * 5)
  }

  var body: some View {
    VStack(spacing: 12) {
      HStack(spacing: 0) {
        durationColumn(title: "Hours", selection: $hours, values: Array(0...24))
        durationColumn(title: "Minutes", selection: $minutes, values: availableMinutes)
      }
      .frame(height: 190)

      if selectedDurationInMinutes < 5 {
        Text("Choose a duration of at least 5 minutes.")
          .font(.caption)
          .foregroundStyle(.secondary)
      }

      Spacer()
    }
    .padding(.horizontal)
    .navigationTitle(title)
    .navigationBarTitleDisplayMode(.inline)
    .toolbar {
      ToolbarItem(placement: .confirmationAction) {
        Button("Done") {
          durationInMinutes = selectedDurationInMinutes
          dismiss()
        }
        .disabled(selectedDurationInMinutes < 5)
      }
    }
    .onChange(of: hours) { _, newValue in
      if newValue == 24 {
        minutes = 0
      }
    }
  }

  private var selectedDurationInMinutes: Int {
    hours * 60 + minutes
  }

  private var availableMinutes: [Int] {
    hours == 24 ? [0] : Array(stride(from: 0, through: 55, by: 5))
  }

  private func durationColumn(
    title: String,
    selection: Binding<Int>,
    values: [Int]
  ) -> some View {
    VStack(spacing: 0) {
      Text(title)
        .font(.caption)
        .foregroundStyle(.secondary)

      Picker(title, selection: selection) {
        ForEach(values, id: \.self) { value in
          Text("\(value)").tag(value)
        }
      }
      .pickerStyle(.wheel)
    }
    .frame(maxWidth: .infinity)
  }
}

struct BlockedProfileBreaksSection: View {
  @ObservedObject var draft: BlockedProfileDraft
  var profile: BlockedProfiles? = nil
  var disabled: Bool

  var body: some View {
    Section("Breaks") {
      BlockedProfileBreaksFields(draft: draft, profile: profile, disabled: disabled)
    }
  }
}

private struct ProfileFieldNotice: View {
  let title: String
  let message: String

  var body: some View {
    VStack(alignment: .leading, spacing: 6) {
      Text(title)
        .font(.subheadline)
        .fontWeight(.semibold)
        .foregroundStyle(.primary)

      Text(message)
        .font(.caption)
        .foregroundStyle(.secondary)
        .fixedSize(horizontal: false, vertical: true)
    }
    .frame(maxWidth: .infinity, alignment: .leading)
    .padding(.vertical, 4)
  }
}

struct BlockedProfileStrictSafeguardsFields: View {
  @ObservedObject var draft: BlockedProfileDraft
  var disabled: Bool
  var showsSeparators: Bool = false

  var body: some View {
    CustomToggle(
      title: "Prevent App Deletion",
      description:
        "Stop apps from being deleted during sessions, including Foqos.",
      isOn: $draft.enableStrictMode,
      isDisabled: disabled
    )

    ProfileFieldDivider(isVisible: showsSeparators)

    CustomToggle(
      title: "Prevent New App Installs",
      description:
        "Stop new apps from being installed during sessions.",
      isOn: $draft.enableBlockAppInstallation,
      isDisabled: disabled
    )
  }
}

struct BlockedProfileSessionSafeguardsFields: View {
  @ObservedObject var draft: BlockedProfileDraft
  var disabled: Bool
  var showsSeparators: Bool = false

  @State private var showingEmergencyUnblockWarning = false

  var body: some View {
    CustomToggle(
      title: "Require Foqos to Stop",
      description:
        "Prevent this profile from being stopped by Shortcuts, NFC links, or QR links outside the app.",
      isOn: $draft.disableBackgroundStops,
      isDisabled: disabled
    )

    ProfileFieldDivider(isVisible: showsSeparators)

    CustomToggle(
      title: "Emergency Unblock",
      description:
        "Allow limited emergency unblocks during active sessions.",
      isOn: emergencyUnblockBinding,
      isDisabled: disabled
    )
    .alert("You Could Lock Yourself Out", isPresented: $showingEmergencyUnblockWarning) {
      Button("Cancel", role: .cancel) {}
      Button("I Understand the Risks", role: .destructive) {
        draft.enableEmergencyUnblock = false
      }
    } message: {
      Text(
        "Turning off Emergency Unblock removes your backup way to end an active session. "
          + "If a required NFC tag, QR code, or barcode is lost, damaged, or unavailable, "
          + "you may be unable to stop the session and could be locked out of apps and "
          + "features on this phone."
      )
    }
  }

  private var emergencyUnblockBinding: Binding<Bool> {
    Binding(
      get: { draft.enableEmergencyUnblock },
      set: { newValue in
        guard !newValue, draft.enableEmergencyUnblock else {
          draft.enableEmergencyUnblock = newValue
          return
        }

        showingEmergencyUnblockWarning = true
      }
    )
  }
}

struct BlockedProfileStrictSafeguardsSection: View {
  @ObservedObject var draft: BlockedProfileDraft
  var disabled: Bool

  var body: some View {
    Section("Session Protection") {
      BlockedProfileStrictSafeguardsFields(draft: draft, disabled: disabled)
    }
  }
}

struct BlockedProfileSessionSafeguardsSection: View {
  @ObservedObject var draft: BlockedProfileDraft
  var disabled: Bool

  var body: some View {
    Section("Stop Options") {
      BlockedProfileSessionSafeguardsFields(draft: draft, disabled: disabled)
    }
  }
}

struct BlockedProfileNotificationsFields: View {
  @EnvironmentObject private var strategyManager: StrategyManager
  @EnvironmentObject private var themeManager: ThemeManager
  @FocusState private var isReminderTimeFocused: Bool

  @ObservedObject var draft: BlockedProfileDraft
  var profile: BlockedProfiles?
  var disabled: Bool
  var showsSeparators: Bool = false

  var body: some View {
    notificationFields
  }

  @ViewBuilder
  private var notificationFields: some View {
    CustomToggle(
      title: "Live Activity",
      description:
        "Show session progress on the Lock Screen.",
      isOn: $draft.enableLiveActivity,
      isDisabled: disabled
    )

    ProfileFieldDivider(isVisible: showsSeparators)

    CustomToggle(
      title: "Reminder",
      description:
        "Remind you to start this profile when it ends.",
      isOn: $draft.enableReminder,
      isDisabled: disabled
    )

    if draft.enableReminder {
      ProfileFieldDivider(isVisible: showsSeparators)

      HStack {
        Text("Reminder time")
        Spacer()
        TextField(
          "",
          value: $draft.reminderTimeInMinutes,
          format: .number
        )
        .keyboardType(.numberPad)
        .multilineTextAlignment(.center)
        .frame(width: 58)
        .padding(.horizontal, 8)
        .padding(.vertical, 6)
        .background(Color.secondary.opacity(0.12))
        .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
        .overlay {
          RoundedRectangle(cornerRadius: 8, style: .continuous)
            .stroke(
              isReminderTimeFocused
                ? themeManager.themeColor : Color.secondary.opacity(0.4),
              lineWidth: isReminderTimeFocused ? 2 : 1
            )
        }
        .focused($isReminderTimeFocused)
        .disabled(disabled)
        .font(.subheadline)
        .foregroundStyle(disabled ? Color.secondary : Color.primary)
        .accessibilityLabel("Reminder time in minutes")

        Text("minutes")
          .font(.subheadline)
          .foregroundColor(.secondary)
      }
      .listRowSeparator(.visible)

      ProfileFieldDivider(isVisible: showsSeparators)

      VStack(alignment: .leading) {
        Text("Reminder message")
        TextField(
          "Reminder message",
          text: $draft.customReminderMessage,
          prompt: Text(strategyManager.defaultReminderMessage(forProfile: profile)),
          axis: .vertical
        )
        .foregroundColor(.secondary)
        .lineLimit(...3)
        .onChange(of: draft.customReminderMessage) { _, newValue in
          if newValue.count > 178 {
            draft.customReminderMessage = String(newValue.prefix(178))
          }
        }
        .disabled(disabled)
      }
    }

    if !disabled {
      Button {
        if let url = URL(string: UIApplication.openSettingsURLString) {
          UIApplication.shared.open(url)
        }
      } label: {
        Text("Manage notification settings")
          .foregroundStyle(themeManager.themeColor)
          .font(.caption)
      }
    }
  }
}

struct BlockedProfileNotificationsSection: View {
  @ObservedObject var draft: BlockedProfileDraft
  var profile: BlockedProfiles?
  var disabled: Bool

  var body: some View {
    Section("Notifications") {
      BlockedProfileNotificationsFields(
        draft: draft,
        profile: profile,
        disabled: disabled
      )
    }
  }
}
