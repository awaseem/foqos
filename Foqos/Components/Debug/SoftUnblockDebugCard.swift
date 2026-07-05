import DeviceActivity
import Foundation
import SwiftUI

struct SoftUnblockDiagnostics {
  struct ProfileConfiguration: Identifiable {
    let id: UUID
    let name: String
    let modelStrategyId: String?
    let modelStrategyData: Data?
    let sharedSnapshot: SharedData.ProfileSnapshot?

    var modelConfiguration: SoftUnblockStrategyData? {
      decode(modelStrategyData)
    }

    var sharedConfiguration: SoftUnblockStrategyData? {
      decode(sharedSnapshot?.strategyData)
    }

    var isInSync: Bool {
      modelStrategyId == sharedSnapshot?.blockingStrategyId
        && modelStrategyData == sharedSnapshot?.strategyData
    }

    private func decode(_ data: Data?) -> SoftUnblockStrategyData? {
      guard let data else { return nil }
      return try? JSONDecoder().decode(SoftUnblockStrategyData.self, from: data)
    }
  }

  let capturedAt: Date
  let store: SoftUnblockGrantStore.DebugSnapshot
  let sharedSession: SharedData.SessionSnapshot?
  let profileConfigurations: [ProfileConfiguration]
  let activities: [DeviceActivityName]

  var grantActivities: [DeviceActivityName] {
    activities.filter { $0.rawValue.hasPrefix("\(SoftUnblockGrantScheduler.activityId):") }
  }

  var activeGrantCount: Int {
    store.grants.filter(isEffective).count
  }

  var expiredGrantCount: Int {
    store.grants.filter { $0.isExpired(at: capturedAt) }.count
  }

  var orphanedGrantCount: Int {
    store.grants.filter { !matchesActiveGrantSession($0) }.count
  }

  func isEffective(_ grant: SoftUnblockGrant) -> Bool {
    matchesActiveGrantSession(grant) && !grant.isExpired(at: capturedAt)
  }

  func matchesActiveGrantSession(_ grant: SoftUnblockGrant) -> Bool {
    store.activeSession?.sessionId == grant.sessionId
      && store.activeSession?.profileId == grant.profileId
  }

  func activityIdentifiers(
    for activity: DeviceActivityName
  ) -> SoftUnblockGrantScheduler.ActivityIdentifiers? {
    SoftUnblockGrantScheduler.identifiers(from: activity)
  }

  func hasStoredGrant(for activity: DeviceActivityName) -> Bool {
    guard let identifiers = activityIdentifiers(for: activity) else { return false }
    return store.grants.contains {
      $0.id == identifiers.grantId
        && $0.sessionId == identifiers.sessionId
        && $0.profileId == identifiers.profileId
    }
  }

  func activitySchedule(for activity: DeviceActivityName) -> DeviceActivitySchedule? {
    DeviceActivityCenter().schedule(for: activity)
  }

  func markdown() -> String {
    var markdown = "## Soft Unblock Diagnostics\n\n"
    markdown += "- **Captured At:** \(format(capturedAt))\n"
    markdown += "- **Stored Active Session Value:** \(yesNo(store.hasStoredActiveSession))\n"
    markdown += "- **Active Session Decodable:** \(yesNo(store.activeSession != nil))\n"

    if let activeSession = store.activeSession {
      markdown += "- **Grant Session ID:** \(activeSession.sessionId)\n"
      markdown += "- **Grant Profile ID:** \(activeSession.profileId.uuidString)\n"
      markdown += "- **Maximum Unblocks:** \(activeSession.maximumUnblockCount)\n"
      markdown += "- **Used Unblocks:** \(activeSession.usedUnblockCount)\n"
      markdown += "- **Remaining Unblocks:** \(activeSession.remainingUnblockCount)\n"
      markdown +=
        "- **Allowance Reset Interval:** \(resetInterval(activeSession.allowanceResetIntervalInHours))\n"
      markdown +=
        "- **Allowance Window Started At:** \(format(activeSession.allowanceWindowStartedAt))\n"
      markdown +=
        "- **Next Allowance Reset At:** \(activeSession.nextAllowanceResetAt.map(format) ?? "Never")\n"
    }

    if let sharedSession {
      markdown += "- **Shared Session ID:** \(sharedSession.id)\n"
      markdown += "- **Shared Session Profile ID:** \(sharedSession.blockedProfileId.uuidString)\n"
      markdown += "- **Shared Session Tag:** \(sharedSession.tag)\n"
      markdown += "- **Shared Session Started At:** \(format(sharedSession.startTime))\n"
      markdown +=
        "- **Grant/Shared Session Match:** \(yesNo(store.activeSession?.sessionId == sharedSession.id && store.activeSession?.profileId == sharedSession.blockedProfileId))\n"
    } else {
      markdown += "- **Shared Session:** None\n"
    }

    markdown += "- **Stored Grant Entries:** \(store.storedGrantEntryCount)\n"
    markdown += "- **Decoded Grants:** \(store.grants.count)\n"
    markdown += "- **Effective Grants:** \(activeGrantCount)\n"
    markdown += "- **Expired Grants:** \(expiredGrantCount)\n"
    markdown += "- **Orphaned Grants:** \(orphanedGrantCount)\n"
    markdown += "- **Undecodable Grants:** \(store.undecodableGrantKeys.count)\n"
    markdown += "- **Grant Activities:** \(grantActivities.count)\n\n"

    markdown += "### Strategy Configuration\n\n"
    if profileConfigurations.isEmpty {
      markdown += "No profiles use the soft-unblock strategy.\n\n"
    } else {
      for profile in profileConfigurations {
        markdown += "#### \(profile.name)\n\n"
        markdown += "- **Profile ID:** \(profile.id.uuidString)\n"
        markdown += "- **Model Strategy ID:** \(profile.modelStrategyId ?? "None")\n"
        appendConfiguration(
          label: "Model",
          data: profile.modelStrategyData,
          configuration: profile.modelConfiguration,
          to: &markdown
        )
        markdown += "- **Shared Snapshot Present:** \(yesNo(profile.sharedSnapshot != nil))\n"
        markdown +=
          "- **Shared Strategy ID:** \(profile.sharedSnapshot?.blockingStrategyId ?? "None")\n"
        appendConfiguration(
          label: "Shared",
          data: profile.sharedSnapshot?.strategyData,
          configuration: profile.sharedConfiguration,
          to: &markdown
        )
        markdown += "- **Model/Shared Configuration Match:** \(yesNo(profile.isInSync))\n\n"
      }
    }

    markdown += "### Stored Grants\n\n"
    if store.grants.isEmpty {
      markdown += "No decodable grants are stored.\n\n"
    } else {
      for (index, grant) in store.grants.enumerated() {
        markdown += "#### Grant \(index + 1)\n\n"
        markdown += "- **Grant ID:** \(grant.id.uuidString)\n"
        markdown += "- **Session ID:** \(grant.sessionId)\n"
        markdown += "- **Profile ID:** \(grant.profileId.uuidString)\n"
        markdown += "- **Resource Type:** \(resourceType(grant.resource))\n"
        markdown += "- **Token Fingerprint:** \(tokenFingerprint(grant.resource))\n"
        markdown += "- **Created At:** \(format(grant.createdAt))\n"
        markdown += "- **Expires At:** \(format(grant.expiresAt))\n"
        markdown += "- **Expired:** \(yesNo(grant.isExpired(at: capturedAt)))\n"
        markdown +=
          "- **Matches Active Grant Session:** \(yesNo(matchesActiveGrantSession(grant)))\n"
        markdown += "- **Effective:** \(yesNo(isEffective(grant)))\n\n"
      }
    }

    if !store.undecodableGrantKeys.isEmpty {
      markdown += "### Undecodable Grant Keys\n\n"
      for key in store.undecodableGrantKeys {
        markdown += "- `\(key)`\n"
      }
      markdown += "\n"
    }

    markdown += "### Grant Activities\n\n"
    if grantActivities.isEmpty {
      markdown += "No soft-unblock grant activities are scheduled.\n\n"
    } else {
      for (index, activity) in grantActivities.enumerated() {
        markdown += "#### Grant Activity \(index + 1)\n\n"
        markdown += "- **Name:** \(activity.rawValue)\n"
        if let identifiers = activityIdentifiers(for: activity) {
          markdown += "- **Profile ID:** \(identifiers.profileId.uuidString)\n"
          markdown += "- **Session ID:** \(identifiers.sessionId)\n"
          markdown += "- **Grant ID:** \(identifiers.grantId.uuidString)\n"
          markdown += "- **Has Matching Stored Grant:** \(yesNo(hasStoredGrant(for: activity)))\n"
        } else {
          markdown += "- **Identifiers Decodable:** No\n"
        }
        if let schedule = activitySchedule(for: activity) {
          markdown += "- **Interval Start:** \(format(schedule.intervalStart))\n"
          markdown += "- **Interval End:** \(format(schedule.intervalEnd))\n"
          markdown += "- **Repeats:** \(yesNo(schedule.repeats))\n"
          if let nextInterval = schedule.nextInterval {
            markdown += "- **Resolved Start:** \(format(nextInterval.start))\n"
            markdown += "- **Resolved End:** \(format(nextInterval.end))\n"
          }
        } else {
          markdown += "- **Schedule Available:** No\n"
        }
        markdown += "\n"
      }
    }

    return markdown
  }

  private func appendConfiguration(
    label: String,
    data: Data?,
    configuration: SoftUnblockStrategyData?,
    to markdown: inout String
  ) {
    markdown += "- **\(label) Strategy Data Bytes:** \(data?.count.description ?? "None")\n"
    markdown += "- **\(label) Strategy Data Decodable:** \(yesNo(configuration != nil))\n"
    if let configuration {
      markdown +=
        "- **\(label) Access Duration:** \(configuration.accessDurationInMinutes) minutes\n"
      markdown += "- **\(label) Maximum Unblocks:** \(configuration.maximumUnblockCount)\n"
      markdown +=
        "- **\(label) Allowance Reset:** \(resetInterval(configuration.allowanceResetIntervalInHours))\n"
    }
  }

  private func format(_ date: Date) -> String {
    ISO8601DateFormatter().string(from: date)
  }

  private func format(_ components: DateComponents) -> String {
    guard let date = Calendar.current.date(from: components) else {
      return String(describing: components)
    }
    return format(date)
  }

  private func yesNo(_ value: Bool) -> String {
    value ? "Yes" : "No"
  }

  private func resetInterval(_ hours: Int?) -> String {
    hours.map { "Every \($0) hours" } ?? "Never"
  }
}

struct SoftUnblockDebugCard: View {
  let diagnostics: SoftUnblockDiagnostics

  var body: some View {
    VStack(alignment: .leading, spacing: 8) {
      DebugRow(label: "Captured At", value: format(diagnostics.capturedAt))
      DebugRow(
        label: "Stored Session Value",
        value: "\(diagnostics.store.hasStoredActiveSession)"
      )
      DebugRow(
        label: "Session Decodable",
        value: "\(diagnostics.store.activeSession != nil)"
      )

      if let activeSession = diagnostics.store.activeSession {
        DebugRow(label: "Grant Session ID", value: activeSession.sessionId)
        DebugRow(label: "Grant Profile ID", value: activeSession.profileId.uuidString)
        DebugRow(label: "Maximum Unblocks", value: "\(activeSession.maximumUnblockCount)")
        DebugRow(label: "Used Unblocks", value: "\(activeSession.usedUnblockCount)")
        DebugRow(label: "Remaining Unblocks", value: "\(activeSession.remainingUnblockCount)")
        DebugRow(
          label: "Allowance Reset",
          value: resetInterval(activeSession.allowanceResetIntervalInHours)
        )
        DebugRow(
          label: "Window Started At",
          value: format(activeSession.allowanceWindowStartedAt)
        )
        DebugRow(
          label: "Next Reset At",
          value: activeSession.nextAllowanceResetAt.map(format) ?? "Never"
        )
      }

      if let sharedSession = diagnostics.sharedSession {
        DebugRow(label: "Shared Session ID", value: sharedSession.id)
        DebugRow(label: "Shared Profile ID", value: sharedSession.blockedProfileId.uuidString)
        DebugRow(
          label: "Grant/Shared Match",
          value:
            "\(diagnostics.store.activeSession?.sessionId == sharedSession.id && diagnostics.store.activeSession?.profileId == sharedSession.blockedProfileId)"
        )
      } else {
        DebugRow(label: "Shared Session", value: "None")
      }

      DebugRow(label: "Stored Grant Entries", value: "\(diagnostics.store.storedGrantEntryCount)")
      DebugRow(label: "Decoded Grants", value: "\(diagnostics.store.grants.count)")
      DebugRow(label: "Effective Grants", value: "\(diagnostics.activeGrantCount)")
      DebugRow(label: "Expired Grants", value: "\(diagnostics.expiredGrantCount)")
      DebugRow(label: "Orphaned Grants", value: "\(diagnostics.orphanedGrantCount)")
      DebugRow(
        label: "Undecodable Grants",
        value: "\(diagnostics.store.undecodableGrantKeys.count)"
      )
      DebugRow(label: "Grant Activities", value: "\(diagnostics.grantActivities.count)")

      configurationDetails
      grantDetails
      undecodableGrantDetails
      activityDetails
    }
  }

  @ViewBuilder
  private var configurationDetails: some View {
    Divider()
    Text("Strategy Configuration")
      .font(.caption)
      .foregroundColor(.secondary)
      .bold()

    if diagnostics.profileConfigurations.isEmpty {
      Text("No profiles use the soft-unblock strategy")
        .font(.caption)
        .foregroundColor(.secondary)
    } else {
      ForEach(diagnostics.profileConfigurations) { profile in
        VStack(alignment: .leading, spacing: 4) {
          Text(profile.name)
            .font(.caption)
            .foregroundColor(.secondary)
            .bold()
          DebugRow(label: "Profile ID", value: profile.id.uuidString)
          DebugRow(label: "Model Strategy ID", value: profile.modelStrategyId ?? "None")
          DebugRow(label: "Model Data Bytes", value: byteCount(profile.modelStrategyData))
          DebugRow(
            label: "Model Duration",
            value: duration(profile.modelConfiguration)
          )
          DebugRow(
            label: "Model Unblock Limit",
            value: unblockLimit(profile.modelConfiguration)
          )
          DebugRow(
            label: "Model Allowance Reset",
            value: configurationResetInterval(profile.modelConfiguration)
          )
          DebugRow(
            label: "Shared Snapshot",
            value: "\(profile.sharedSnapshot != nil)"
          )
          DebugRow(
            label: "Shared Strategy ID",
            value: profile.sharedSnapshot?.blockingStrategyId ?? "None"
          )
          DebugRow(
            label: "Shared Data Bytes",
            value: byteCount(profile.sharedSnapshot?.strategyData)
          )
          DebugRow(
            label: "Shared Duration",
            value: duration(profile.sharedConfiguration)
          )
          DebugRow(
            label: "Shared Unblock Limit",
            value: unblockLimit(profile.sharedConfiguration)
          )
          DebugRow(
            label: "Shared Allowance Reset",
            value: configurationResetInterval(profile.sharedConfiguration)
          )
          DebugRow(label: "Model/Shared Match", value: "\(profile.isInSync)")
        }
      }
    }
  }

  @ViewBuilder
  private var grantDetails: some View {
    Divider()
    Text("Stored Grants")
      .font(.caption)
      .foregroundColor(.secondary)
      .bold()

    if diagnostics.store.grants.isEmpty {
      Text("No decodable grants are stored")
        .font(.caption)
        .foregroundColor(.secondary)
    } else {
      ForEach(diagnostics.store.grants) { grant in
        VStack(alignment: .leading, spacing: 4) {
          Text(grant.id.uuidString)
            .font(.caption)
            .foregroundColor(.secondary)
            .bold()
          DebugRow(label: "Session ID", value: grant.sessionId)
          DebugRow(label: "Profile ID", value: grant.profileId.uuidString)
          DebugRow(label: "Resource Type", value: resourceType(grant.resource))
          DebugRow(label: "Token Fingerprint", value: tokenFingerprint(grant.resource))
          DebugRow(label: "Created At", value: format(grant.createdAt))
          DebugRow(label: "Expires At", value: format(grant.expiresAt))
          DebugRow(label: "Expired", value: "\(grant.isExpired(at: diagnostics.capturedAt))")
          DebugRow(
            label: "Matches Grant Session",
            value: "\(diagnostics.matchesActiveGrantSession(grant))"
          )
          DebugRow(label: "Effective", value: "\(diagnostics.isEffective(grant))")
        }
      }
    }
  }

  @ViewBuilder
  private var undecodableGrantDetails: some View {
    if !diagnostics.store.undecodableGrantKeys.isEmpty {
      Divider()
      Text("Undecodable Grant Keys")
        .font(.caption)
        .foregroundColor(.secondary)
        .bold()

      ForEach(diagnostics.store.undecodableGrantKeys, id: \.self) { key in
        DebugRow(label: "Storage Key", value: key)
      }
    }
  }

  @ViewBuilder
  private var activityDetails: some View {
    Divider()
    Text("Grant Activities")
      .font(.caption)
      .foregroundColor(.secondary)
      .bold()

    if diagnostics.grantActivities.isEmpty {
      Text("No soft-unblock grant activities are scheduled")
        .font(.caption)
        .foregroundColor(.secondary)
    } else {
      ForEach(diagnostics.grantActivities, id: \.rawValue) { activity in
        VStack(alignment: .leading, spacing: 4) {
          DebugRow(label: "Name", value: activity.rawValue)
          if let identifiers = diagnostics.activityIdentifiers(for: activity) {
            DebugRow(label: "Profile ID", value: identifiers.profileId.uuidString)
            DebugRow(label: "Session ID", value: identifiers.sessionId)
            DebugRow(label: "Grant ID", value: identifiers.grantId.uuidString)
            DebugRow(
              label: "Has Stored Grant",
              value: "\(diagnostics.hasStoredGrant(for: activity))"
            )
          } else {
            DebugRow(label: "Identifiers Decodable", value: "false")
          }
          if let schedule = diagnostics.activitySchedule(for: activity) {
            DebugRow(label: "Interval Start", value: format(schedule.intervalStart))
            DebugRow(label: "Interval End", value: format(schedule.intervalEnd))
            DebugRow(label: "Repeats", value: "\(schedule.repeats)")
            if let nextInterval = schedule.nextInterval {
              DebugRow(label: "Resolved Start", value: format(nextInterval.start))
              DebugRow(label: "Resolved End", value: format(nextInterval.end))
            }
          } else {
            DebugRow(label: "Schedule Available", value: "false")
          }
        }
      }
    }
  }

  private func byteCount(_ data: Data?) -> String {
    data.map { "\($0.count)" } ?? "None"
  }

  private func duration(_ configuration: SoftUnblockStrategyData?) -> String {
    configuration.map { "\($0.accessDurationInMinutes) minutes" } ?? "Undecodable"
  }

  private func unblockLimit(_ configuration: SoftUnblockStrategyData?) -> String {
    configuration.map { "\($0.maximumUnblockCount)" } ?? "Undecodable"
  }

  private func configurationResetInterval(
    _ configuration: SoftUnblockStrategyData?
  ) -> String {
    guard let configuration else { return "Undecodable" }
    return resetInterval(configuration.allowanceResetIntervalInHours)
  }

  private func resetInterval(_ hours: Int?) -> String {
    hours.map { "Every \($0) hours" } ?? "Never"
  }

  private func format(_ date: Date) -> String {
    ISO8601DateFormatter().string(from: date)
  }

  private func format(_ components: DateComponents) -> String {
    guard let date = Calendar.current.date(from: components) else {
      return String(describing: components)
    }
    return format(date)
  }
}

private func resourceType(_ resource: SoftUnblockResource) -> String {
  switch resource {
  case .application:
    return "Application"
  case .category:
    return "Category"
  }
}

private func tokenFingerprint(_ resource: SoftUnblockResource) -> String {
  let data: Data?
  switch resource {
  case .application(let token):
    data = try? JSONEncoder().encode(token)
  case .category(let token):
    data = try? JSONEncoder().encode(token)
  }

  guard let data else { return "Encoding failed" }

  var hash: UInt64 = 14_695_981_039_346_656_037
  for byte in data {
    hash ^= UInt64(byte)
    hash = hash &* 1_099_511_628_211
  }

  return String(format: "%016llx (%d bytes)", hash, data.count)
}
