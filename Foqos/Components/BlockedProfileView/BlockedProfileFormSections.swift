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
        Text("Set Strategy")
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
  @ObservedObject var draft: BlockedProfileDraft
  @Binding var showingStrategyPicker: Bool
  var disabled: Bool

  var body: some View {
    Section("Blocking Strategy") {
      BlockedProfileStrategyFields(
        draft: draft,
        showingStrategyPicker: $showingStrategyPicker,
        disabled: disabled
      )
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
      title: "Apps Allow Mode",
      description:
        "Pick apps to allow and block everything else. This will erase any other selection you've made.",
      isOn: $draft.enableAllowMode,
      isDisabled: disabled
    )

    ProfileFieldDivider(isVisible: showsSeparators)

    CustomToggle(
      title: "Block Safari",
      description:
        "Block Safari websites that are selected in the app selector above. When disabled, Safari will remain unrestricted regardless of the websites you pick.",
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
      title: "Domain Allow Mode",
      description:
        "Pick domains to allow and block everything else. This will erase any other selection you've made.",
      isOn: $draft.enableAllowModeDomain,
      isDisabled: disabled
    )

    ProfileFieldDivider(isVisible: showsSeparators)

    CustomToggle(
      title: "Block Adult Websites",
      description:
        "Use Apple's adult-content filter during sessions. You can still add extra domains to block.",
      isOn: $draft.enableAdultContentBlocking,
      isDisabled: disabled
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
    Section("Strict Unlocks") {
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
  @ObservedObject var draft: BlockedProfileDraft
  var disabled: Bool
  var showsSeparators: Bool = false

  var body: some View {
    CustomToggle(
      title: "Allow Timed Breaks",
      description:
        "Take a single break during your session. The break will automatically end after the selected duration.",
      isOn: $draft.enableBreaks,
      isDisabled: disabled
    )

    if draft.enableBreaks {
      ProfileFieldDivider(isVisible: showsSeparators)

      breakDurationPicker
    }
  }

  private var breakDurationPicker: some View {
    Picker("Break Duration", selection: $draft.breakTimeInMinutes) {
      Text("5 minutes").tag(5)
      Text("10 minutes").tag(10)
      Text("15 minutes").tag(15)
      Text("30 minutes").tag(30)
    }
    .disabled(disabled)
  }
}

struct BlockedProfileBreaksSection: View {
  @ObservedObject var draft: BlockedProfileDraft
  var disabled: Bool

  var body: some View {
    Section("Breaks") {
      BlockedProfileBreaksFields(draft: draft, disabled: disabled)
    }
  }
}

struct BlockedProfileStrictSafeguardsFields: View {
  @ObservedObject var draft: BlockedProfileDraft
  var disabled: Bool
  var showsSeparators: Bool = false

  var body: some View {
    CustomToggle(
      title: "Strict",
      description:
        "Block deleting apps from your phone, stops you from deleting Foqos to access apps",
      isOn: $draft.enableStrictMode,
      isDisabled: disabled
    )

    ProfileFieldDivider(isVisible: showsSeparators)

    CustomToggle(
      title: "Prevent App Installation",
      description:
        "Block installing new apps, including via Spotlight search and the App Store.",
      isOn: $draft.enableBlockAppInstallation,
      isDisabled: disabled
    )
  }
}

struct BlockedProfileSessionSafeguardsFields: View {
  @ObservedObject var draft: BlockedProfileDraft
  var disabled: Bool
  var showsSeparators: Bool = false

  var body: some View {
    CustomToggle(
      title: "Disable Background Stops",
      description:
        "Disable the ability to stop a profile from the background, this includes shortcuts and scanning links from NFC tags or QR codes.",
      isOn: $draft.disableBackgroundStops,
      isDisabled: disabled
    )

    ProfileFieldDivider(isVisible: showsSeparators)

    CustomToggle(
      title: "Allow Emergency Unblock",
      description:
        "Enable the emergency unblock feature for this profile. When disabled, you won't be able to use emergency unblocks during active sessions.",
      isOn: $draft.enableEmergencyUnblock,
      isDisabled: disabled
    )
  }
}

struct BlockedProfileStrictSafeguardsSection: View {
  @ObservedObject var draft: BlockedProfileDraft
  var disabled: Bool

  var body: some View {
    Section("Strict Safeguards") {
      BlockedProfileStrictSafeguardsFields(draft: draft, disabled: disabled)
    }
  }
}

struct BlockedProfileSessionSafeguardsSection: View {
  @ObservedObject var draft: BlockedProfileDraft
  var disabled: Bool

  var body: some View {
    Section("Session Safeguards") {
      BlockedProfileSessionSafeguardsFields(draft: draft, disabled: disabled)
    }
  }
}

struct BlockedProfileNotificationsFields: View {
  @EnvironmentObject private var strategyManager: StrategyManager
  @EnvironmentObject private var themeManager: ThemeManager

  @ObservedObject var draft: BlockedProfileDraft
  var profile: BlockedProfiles?
  var disabled: Bool
  var showsSeparators: Bool = false

  var body: some View {
    CustomToggle(
      title: "Live Activity",
      description:
        "Shows a live activity on your lock screen with some inspirational quote",
      isOn: $draft.enableLiveActivity,
      isDisabled: disabled
    )

    ProfileFieldDivider(isVisible: showsSeparators)

    CustomToggle(
      title: "Reminder",
      description:
        "Sends a reminder to start this profile when its ended",
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
        .multilineTextAlignment(.trailing)
        .frame(width: 50)
        .disabled(disabled)
        .font(.subheadline)
        .foregroundColor(.secondary)

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
        Text("Go to settings to disable globally")
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
