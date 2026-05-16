import FamilyControls
import SwiftUI

struct BlockedProfileNameSection: View {
  @ObservedObject var draft: BlockedProfileDraft
  var disabled: Bool

  var body: some View {
    Section("Name") {
      TextField("Profile Name", text: $draft.name)
        .textContentType(.none)
        .disabled(disabled)
    }
  }
}

struct BlockedProfileStrategySection: View {
  @EnvironmentObject private var themeManager: ThemeManager

  @ObservedObject var draft: BlockedProfileDraft
  @Binding var showingStrategyPicker: Bool
  var disabled: Bool

  var body: some View {
    Section("Blocking Strategy") {
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
}

struct BlockedProfileAppsSection: View {
  @ObservedObject var draft: BlockedProfileDraft
  @Binding var showingActivityPicker: Bool
  var disabled: Bool

  var body: some View {
    Section((draft.enableAllowMode ? "Allowed" : "Blocked") + " Apps") {
      BlockedProfileAppSelector(
        selection: draft.selectedActivity,
        buttonAction: { showingActivityPicker = true },
        allowMode: draft.enableAllowMode,
        disabled: disabled
      )

      CustomToggle(
        title: "Apps Allow Mode",
        description:
          "Pick apps to allow and block everything else. This will erase any other selection you've made.",
        isOn: $draft.enableAllowMode,
        isDisabled: disabled
      )

      CustomToggle(
        title: "Block Safari",
        description:
          "Block Safari websites that are selected in the app selector above. When disabled, Safari will remain unrestricted regardless of the websites you pick.",
        isOn: $draft.enableSafariBlocking,
        isDisabled: disabled
      )
    }
    .onChange(of: draft.enableAllowMode) { _, newValue in
      draft.selectedActivity = FamilyActivitySelection(includeEntireCategory: newValue)
    }
  }
}

struct BlockedProfileDomainsSection: View {
  @ObservedObject var draft: BlockedProfileDraft
  @Binding var showingDomainPicker: Bool
  var disabled: Bool

  var body: some View {
    Section((draft.enableAllowModeDomain ? "Allowed" : "Blocked") + " Domains") {
      BlockedProfileDomainSelector(
        domains: draft.domains,
        buttonAction: { showingDomainPicker = true },
        allowMode: draft.enableAllowModeDomain,
        disabled: disabled
      )

      CustomToggle(
        title: "Domain Allow Mode",
        description:
          "Pick domains to allow and block everything else. This will erase any other selection you've made.",
        isOn: $draft.enableAllowModeDomain,
        isDisabled: disabled
      )

      CustomToggle(
        title: "Block Adult Websites",
        description:
          "Use Apple's adult-content filter during sessions. You can still add extra domains to block.",
        isOn: $draft.enableAdultContentBlocking,
        isDisabled: disabled
      )
    }
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

struct BlockedProfileStrictUnlocksSection: View {
  @ObservedObject var draft: BlockedProfileDraft
  var disabled: Bool

  var body: some View {
    Section("Strict Unlocks") {
      BlockedProfilePhysicalUnblockSelector(
        physicalUnblockItems: $draft.physicalUnblockItems,
        disabled: disabled
      )
    }
  }
}

struct BlockedProfileScheduleSection: View {
  @ObservedObject var draft: BlockedProfileDraft
  @Binding var showingSchedulePicker: Bool
  var disabled: Bool

  var body: some View {
    Section("Schedule") {
      BlockedProfileScheduleSelector(
        schedule: draft.schedule,
        buttonAction: { showingSchedulePicker = true },
        disabled: disabled
      )
    }
  }
}

struct BlockedProfileBreaksSection: View {
  @ObservedObject var draft: BlockedProfileDraft
  var disabled: Bool

  var body: some View {
    Section("Breaks") {
      CustomToggle(
        title: "Allow Timed Breaks",
        description:
          "Take a single break during your session. The break will automatically end after the selected duration.",
        isOn: $draft.enableBreaks,
        isDisabled: disabled
      )

      if draft.enableBreaks {
        Picker("Break Duration", selection: $draft.breakTimeInMinutes) {
          Text("5 minutes").tag(5)
          Text("10 minutes").tag(10)
          Text("15 minutes").tag(15)
          Text("30 minutes").tag(30)
        }
        .disabled(disabled)
      }
    }
  }
}

struct BlockedProfileSafeguardsSection: View {
  @ObservedObject var draft: BlockedProfileDraft
  var disabled: Bool

  var body: some View {
    Section("Safeguards") {
      CustomToggle(
        title: "Strict",
        description:
          "Block deleting apps from your phone, stops you from deleting Foqos to access apps",
        isOn: $draft.enableStrictMode,
        isDisabled: disabled
      )

      CustomToggle(
        title: "Prevent App Installation",
        description:
          "Block installing new apps, including via Spotlight search and the App Store.",
        isOn: $draft.enableBlockAppInstallation,
        isDisabled: disabled
      )

      CustomToggle(
        title: "Disable Background Stops",
        description:
          "Disable the ability to stop a profile from the background, this includes shortcuts and scanning links from NFC tags or QR codes.",
        isOn: $draft.disableBackgroundStops,
        isDisabled: disabled
      )

      CustomToggle(
        title: "Allow Emergency Unblock",
        description:
          "Enable the emergency unblock feature for this profile. When disabled, you won't be able to use emergency unblocks during active sessions.",
        isOn: $draft.enableEmergencyUnblock,
        isDisabled: disabled
      )
    }
  }
}

struct BlockedProfileNotificationsSection: View {
  @EnvironmentObject private var strategyManager: StrategyManager
  @EnvironmentObject private var themeManager: ThemeManager

  @ObservedObject var draft: BlockedProfileDraft
  var profile: BlockedProfiles?
  var disabled: Bool

  var body: some View {
    Section("Notifications") {
      CustomToggle(
        title: "Live Activity",
        description:
          "Shows a live activity on your lock screen with some inspirational quote",
        isOn: $draft.enableLiveActivity,
        isDisabled: disabled
      )

      CustomToggle(
        title: "Reminder",
        description:
          "Sends a reminder to start this profile when its ended",
        isOn: $draft.enableReminder,
        isDisabled: disabled
      )

      if draft.enableReminder {
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
}
