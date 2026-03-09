import DeviceActivity
import FamilyControls
import SwiftData
import SwiftUI

struct DebugView: View {
  @Environment(\.modelContext) private var modelContext
  @Environment(\.dismiss) private var dismiss

  @EnvironmentObject var strategyManager: StrategyManager

  @Query(sort: \BlockedProfiles.order) private var allProfiles: [BlockedProfiles]

  @State private var activeProfile: BlockedProfiles?
  @State private var showCopyConfirmation = false

  private var deviceActivities: [DeviceActivityName] {
    DeviceActivityCenterUtil.getDeviceActivities()
  }

  var body: some View {
    NavigationView {
      ScrollView {
        VStack(alignment: .leading, spacing: 20) {
          // Strategy Manager Section (always shown)
          DebugSection(title: "Strategy Manager") {
            StrategyManagerDebugCard(strategyManager: strategyManager)
          }

          // Active Session Section (if available)
          if let session = strategyManager.activeSession {
            DebugSection(title: "Active Session") {
              SessionDebugCard(session: session)
            }
          }

          // Device Activities Section (always shown)
          DebugSection(title: "Device Activities (\(deviceActivities.count))") {
            DeviceActivitiesDebugCard(
              activities: deviceActivities,
              profileId: activeProfile?.id
            )
          }

          // All Profiles Section
          if !allProfiles.isEmpty {
            DebugSection(title: "All Profiles (\(allProfiles.count))") {
              VStack(alignment: .leading, spacing: 16) {
                ForEach(allProfiles) { profile in
                  VStack(alignment: .leading, spacing: 8) {
                    Text(profile.name)
                      .font(.headline)
                    
                    ProfileDebugCard(profile: profile)
                    
                    if let schedule = profile.schedule {
                      ScheduleDebugCard(schedule: schedule)
                    }
                    
                    DebugSection(title: "Selected Activity") {
                      SelectedActivityDebugCard(selection: profile.selectedActivity)
                    }
                    
                    if let domains = profile.domains, !domains.isEmpty {
                      DebugSection(title: "Domains (\(domains.count))") {
                        DomainsDebugCard(domains: domains)
                      }
                    }
                  }
                  .padding(.vertical, 8)
                  
                  if profile.id != allProfiles.last?.id {
                    Divider()
                  }
                }
              }
            }
          }
        }
        .padding()
      }
      .navigationTitle("Debug Mode")
      .toolbar {
        ToolbarItem(placement: .topBarLeading) {
          Button(action: { dismiss() }) {
            Image(systemName: "xmark")
          }
          .accessibilityLabel("Cancel")
        }

        ToolbarItem(placement: .topBarTrailing) {
          Button(action: { copyToMarkdown() }) {
            Image(systemName: "doc.on.doc")
          }
          .accessibilityLabel("Copy as Markdown")
        }
      }
      .onAppear {
        loadActiveProfile()
      }
      .refreshable {
        loadActiveProfile()
      }
      .alert("Copied to Clipboard", isPresented: $showCopyConfirmation) {
        Button("OK", role: .cancel) {}
      } message: {
        Text("Debug information has been copied as Markdown.")
      }
    }
  }

  private func loadActiveProfile() {
    if let session = strategyManager.activeSession {
      activeProfile = session.blockedProfile
    }
  }

  private func copyToMarkdown() {
    var markdown = "# Debug Information\n\n"

    // Strategy Manager Section (always shown)
    markdown += "## Strategy Manager\n\n"
    markdown += "- **Has Active Session:** \(strategyManager.activeSession != nil ? "Yes" : "No")\n"
    markdown += "- **Elapsed Time:** \(Int(strategyManager.elapsedTime)) seconds\n"
    markdown += "- **Timer Active:** \(strategyManager.timer != nil ? "Yes" : "No")\n\n"

    // Active Session Section (if available)
    if let session = strategyManager.activeSession {
      markdown += "## Active Session\n\n"
      markdown += "- **Session ID:** \(session.id)\n"
      markdown += "- **Tag:** \(session.tag)\n"
      markdown += "- **Is Active:** \(session.isActive ? "Yes" : "No")\n"
      markdown += "- **Started At:** \(DateFormatters.formatDate(session.startTime))\n"

      if let endTime = session.endTime {
        markdown += "- **Ended At:** \(DateFormatters.formatDate(endTime))\n"
      }

      markdown += "- **Break Available:** \(session.isBreakAvailable ? "Yes" : "No")\n"
      markdown += "- **Break Active:** \(session.isBreakActive ? "Yes" : "No")\n"

      if let breakStartTime = session.breakStartTime {
        markdown += "- **Break Started At:** \(DateFormatters.formatDate(breakStartTime))\n"
      }

      if let breakEndTime = session.breakEndTime {
        markdown += "- **Break Ended At:** \(DateFormatters.formatDate(breakEndTime))\n"
      }

      markdown += "- **Force Started:** \(session.forceStarted ? "Yes" : "No")\n"
      markdown += "- **Duration:** \(DateFormatters.formatDuration(session.duration))\n\n"
    }

    // Device Activities Section (always shown)
    markdown += "## Device Activities (\(deviceActivities.count))\n\n"
    if deviceActivities.isEmpty {
      markdown += "No device activities scheduled.\n\n"
    } else {
      for (index, activity) in deviceActivities.enumerated() {
        markdown += "### Activity \(index + 1)\n"
        markdown += "- **Name:** \(activity.rawValue)\n"
        markdown += "- **Type:** \(activityType(for: activity))\n"
        if let profileId = activeProfile?.id {
          markdown +=
            "- **Matches Active Profile:** \(isActivityForProfile(activity, profileId: profileId) ? "Yes" : "No")\n"
        }
        markdown += "\n"
      }
    }

    // All Profiles Section
    if !allProfiles.isEmpty {
      markdown += "## All Profiles (\(allProfiles.count))\n\n"

      for (index, profile) in allProfiles.enumerated() {
        markdown += "### Profile \(index + 1): \(profile.name)\n\n"
        markdown += "- **ID:** \(profile.id.uuidString)\n"
        markdown += "- **Created:** \(DateFormatters.formatDate(profile.createdAt))\n"
        markdown += "- **Updated:** \(DateFormatters.formatDate(profile.updatedAt))\n"
        markdown += "- **Order:** \(profile.order)\n"

        if let strategyId = profile.blockingStrategyId {
          markdown += "- **Blocking Strategy ID:** \(strategyId)\n"
        }

        markdown += "- **Allow Mode:** \(profile.enableAllowMode ? "Yes" : "No")\n"
        markdown += "- **Allow Mode Domains:** \(profile.enableAllowModeDomains ? "Yes" : "No")\n"
        markdown += "- **Live Activity:** \(profile.enableLiveActivity ? "Enabled" : "Disabled")\n"
        markdown += "- **Breaks:** \(profile.enableBreaks ? "Enabled" : "Disabled")\n"
        markdown += "- **Strict Mode:** \(profile.enableStrictMode ? "Enabled" : "Disabled")\n"
        markdown += "- **Disable Background Stops:** \(profile.disableBackgroundStops ? "Yes" : "No")\n"

        if let reminderTime = profile.reminderTimeInSeconds {
          markdown += "- **Reminder Time:** \(reminderTime / 60) minutes\n"
        }

        if let customMessage = profile.customReminderMessage, !customMessage.isEmpty {
          markdown += "- **Custom Reminder Message:** \(customMessage)\n"
        }

        if let nfcTagId = profile.physicalUnblockNFCTagId {
          markdown += "- **Physical Unlock NFC Tag ID:** \(nfcTagId)\n"
        }

        if let qrCodeId = profile.physicalUnblockQRCodeId {
          markdown += "- **Physical Unlock QR Code ID:** \(qrCodeId)\n"
        }

        markdown += "- **Total Sessions:** \(profile.sessions.count)\n"

        // Schedule Section
        if let schedule = profile.schedule {
          markdown += "\n**Schedule:**\n\n"

          if schedule.days.isEmpty {
            markdown += "- **Days:** All days\n"
          } else {
            let dayNames = schedule.days.sorted(by: { $0.rawValue < $1.rawValue }).map { $0.name }
              .joined(separator: ", ")
            markdown += "- **Days:** \(dayNames)\n"
          }

          markdown +=
            "- **Start Time:** \(String(format: "%02d:%02d", schedule.startHour, schedule.startMinute))\n"
          markdown +=
            "- **End Time:** \(String(format: "%02d:%02d", schedule.endHour, schedule.endMinute))\n"
          markdown += "- **Updated At:** \(DateFormatters.formatDate(schedule.updatedAt))\n"
        }

        // Selected Activity Section
        markdown += "\n**Selected Activity:**\n\n"
        markdown += "- **Applications:** \(profile.selectedActivity.applicationTokens.count)\n"
        markdown += "- **Categories:** \(profile.selectedActivity.categoryTokens.count)\n"
        markdown += "- **Web Domains:** \(profile.selectedActivity.webDomainTokens.count)\n"

        // Domains Section
        if let domains = profile.domains, !domains.isEmpty {
          markdown += "\n**Domains (\(domains.count)):**\n\n"
          for domain in domains {
            markdown += "- \(domain)\n"
          }
        }

        markdown += "\n"
      }
    }

    // Copy to clipboard
    UIPasteboard.general.string = markdown
    showCopyConfirmation = true
  }

  private func activityType(for activity: DeviceActivityName) -> String {
    let rawValue = activity.rawValue

    if rawValue.hasPrefix(BreakTimerActivity.id) {
      return "Break Timer"
    } else if rawValue.hasPrefix(ScheduleTimerActivity.id) {
      return "Schedule Timer"
    } else {
      // Check if it's a UUID (legacy schedule format)
      if UUID(uuidString: rawValue) != nil {
        return "Schedule Timer (Legacy)"
      }
      return "Unknown"
    }
  }

  private func isActivityForProfile(_ activity: DeviceActivityName, profileId: UUID) -> Bool {
    let rawValue = activity.rawValue
    let profileIdString = profileId.uuidString

    // Check if it's a break timer activity for this profile
    if rawValue.hasPrefix(BreakTimerActivity.id) {
      return rawValue.hasSuffix(profileIdString)
    }

    // Check if it's a schedule timer activity for this profile
    if rawValue.hasPrefix(ScheduleTimerActivity.id) {
      return rawValue.hasSuffix(profileIdString)
    }

    // Check if it's a legacy schedule format (just the UUID)
    return rawValue == profileIdString
  }
}

#Preview {
  DebugView()
    .environmentObject(StrategyManager.shared)
    .modelContainer(for: [BlockedProfiles.self, BlockedProfileSession.self], inMemory: true)
}
