import DeviceActivity
import Foundation

enum SoftUnblockGrantScheduler {
  static let activityId = "SoftUnblockGrantTimerActivity"

  struct ActivityIdentifiers: Equatable {
    let profileId: UUID
    let sessionId: String
    let grantId: UUID
  }

  static func scheduleGrant(_ grant: SoftUnblockGrant) throws {
    let center = DeviceActivityCenter()
    let activityName = activityName(for: grant)
    let calendar = Calendar.current
    let now = Date()
    let dateComponents: Set<Calendar.Component> = [
      .year, .month, .day, .hour, .minute, .second,
    ]
    let intervalStart = calendar.dateComponents(
      dateComponents,
      from: calendar.startOfDay(for: now)
    )
    let intervalEnd = intervalEnd(for: grant.expiresAt, at: now)
    let schedule = DeviceActivitySchedule(
      intervalStart: intervalStart,
      intervalEnd: intervalEnd,
      repeats: false
    )

    try center.startMonitoring(activityName, during: schedule)
  }

  static func intervalEnd(for expiresAt: Date, at date: Date = Date()) -> DateComponents {
    // DeviceActivity uses whole seconds; never schedule before the stored expiry.
    let endDate = Date(
      timeIntervalSince1970: max(expiresAt, date.addingTimeInterval(60))
        .timeIntervalSince1970.rounded(.up)
    )
    return Calendar.current.dateComponents(
      [.year, .month, .day, .hour, .minute, .second], from: endDate
    )
  }

  static func stopGrant(_ grant: SoftUnblockGrant) {
    DeviceActivityCenter().stopMonitoring([activityName(for: grant)])
  }

  static func stopAll(sessionId: String? = nil) {
    let center = DeviceActivityCenter()
    let prefix = "\(activityId):"
    let activities = center.activities.filter { activity in
      guard activity.rawValue.hasPrefix(prefix) else { return false }
      guard let sessionId else { return true }
      return identifiers(from: activity)?.sessionId == sessionId
    }

    guard !activities.isEmpty else { return }
    center.stopMonitoring(activities)
  }

  static func identifiers(from activityName: DeviceActivityName) -> ActivityIdentifiers? {
    let components = activityName.rawValue.split(separator: ":", maxSplits: 1)
    guard components.count == 2, components[0] == Substring(activityId) else { return nil }

    let payload = components[1].split(separator: "|", maxSplits: 2)
    guard payload.count == 3,
      let profileId = UUID(uuidString: String(payload[0])),
      let grantId = UUID(uuidString: String(payload[2]))
    else {
      return nil
    }

    return ActivityIdentifiers(
      profileId: profileId,
      sessionId: String(payload[1]),
      grantId: grantId
    )
  }

  private static func activityName(for grant: SoftUnblockGrant) -> DeviceActivityName {
    DeviceActivityName(
      rawValue:
        "\(activityId):\(grant.profileId.uuidString)|\(grant.sessionId)|\(grant.id.uuidString)"
    )
  }
}
