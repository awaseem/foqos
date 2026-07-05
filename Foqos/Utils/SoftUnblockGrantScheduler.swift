import DeviceActivity
import Foundation

enum SoftUnblockGrantScheduler {
  static let activityId = "ShieldAppAccessTimerActivity"

  struct ActivityIdentifiers: Equatable {
    let profileId: UUID
    let sessionId: String
    let grantId: UUID
  }

  static func scheduleExpiration(for grant: SoftUnblockGrant) throws {
    let center = DeviceActivityCenter()
    let activityName = activityName(for: grant)
    let calendar = Calendar.current
    let now = Date()
    let intervalStart = calendar.dateComponents([.hour, .minute, .second], from: now)
    let intervalEnd = calendar.dateComponents(
      [.hour, .minute, .second],
      from: max(grant.expiresAt, now.addingTimeInterval(60))
    )
    let schedule = DeviceActivitySchedule(
      intervalStart: intervalStart,
      intervalEnd: intervalEnd,
      repeats: false
    )

    center.stopMonitoring([activityName])
    try center.startMonitoring(activityName, during: schedule)
  }

  static func stopExpiration(for grant: SoftUnblockGrant) {
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
