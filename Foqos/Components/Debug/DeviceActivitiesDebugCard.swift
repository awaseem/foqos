import DeviceActivity
import SwiftUI

struct DeviceActivitiesDebugCard: View {
  let activities: [DeviceActivityName]
  let profileId: UUID?

  var body: some View {
    VStack(alignment: .leading, spacing: 8) {
      if activities.isEmpty {
        Text("No device activities scheduled")
          .font(.caption)
          .foregroundColor(.secondary)
      } else {
        DebugRow(label: "Total Activities", value: "\(activities.count)")

        Divider()

        ForEach(Array(activities.enumerated()), id: \.element.rawValue) { index, activity in
          VStack(alignment: .leading, spacing: 4) {
            Text("Activity \(index + 1)")
              .font(.caption)
              .foregroundColor(.secondary)
              .bold()

            DebugRow(label: "Name", value: activity.rawValue)
            DebugRow(label: "Type", value: activityType(for: activity))

            if let profileId = profileId {
              DebugRow(
                label: "Matches Profile",
                value: "\(isActivityForProfile(activity, profileId: profileId))"
              )
            }
          }

          if index < activities.count - 1 {
            Divider()
          }
        }
      }
    }
  }

  private func activityType(for activity: DeviceActivityName) -> String {
    let rawValue = activity.rawValue

    if rawValue.hasPrefix(BreakTimerActivity.id) {
      return "Break Timer"
    } else if rawValue.hasPrefix(ScheduleTimerActivity.id) {
      return "Schedule Timer"
    } else if rawValue.hasPrefix(StrategyTimerActivity.id) {
      return "Strategy Timer"
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

    // Check if it's a strategy timer activity for this profile
    if rawValue.hasPrefix(StrategyTimerActivity.id) {
      return rawValue.hasSuffix(profileIdString)
    }

    // Check if it's a schedule timer activity or legacy format (just the UUID)
    return rawValue == profileIdString
  }
}

#Preview {
  DeviceActivitiesDebugCard(
    activities: [
      DeviceActivityName(rawValue: "550e8400-e29b-41d4-a716-446655440000"),
      DeviceActivityName(
        rawValue: "BreakScheduleActivity:550e8400-e29b-41d4-a716-446655440000"),
      DeviceActivityName(
        rawValue: "ScheduleTimerActivity:550e8400-e29b-41d4-a716-446655440000"),
    ],
    profileId: UUID(uuidString: "550e8400-e29b-41d4-a716-446655440000")
  )
  .padding()
}

#Preview("Empty") {
  DeviceActivitiesDebugCard(
    activities: [],
    profileId: nil
  )
  .padding()
}
