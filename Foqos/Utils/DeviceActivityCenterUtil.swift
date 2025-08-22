import DeviceActivity
import FamilyControls
import ManagedSettings
import SwiftUI

class DeviceActivityCenterUtil {
  static func scheduleRestrictions(for profile: BlockedProfiles) {
    guard let schedule = profile.schedule else { return }

    let deviceActivityName = getDeviceActivityName(from: profile)

    let intervalStart = DateComponents(hour: schedule.startHour, minute: schedule.startMinute)
    let intervalEnd = DateComponents(hour: schedule.endHour, minute: schedule.endMinute)
    let deviceActivitySchedule = DeviceActivitySchedule(
      intervalStart: intervalStart,
      intervalEnd: intervalEnd,
      repeats: true,
    )

    let center = DeviceActivityCenter()

    center.stopMonitoring([deviceActivityName])

    do {
      try center.startMonitoring(deviceActivityName, during: deviceActivitySchedule)
      print("Scheduled restrictions from \(intervalStart) to \(intervalEnd) daily")
    } catch {
      print("Failed to start monitoring: \(error.localizedDescription)")
    }
  }

  static func removeSchedule(for profile: BlockedProfiles) {
    let deviceActivityName = getDeviceActivityName(from: profile)
    let center = DeviceActivityCenter()
    center.stopMonitoring([deviceActivityName])
  }

  private static func getDeviceActivityName(from profile: BlockedProfiles) -> DeviceActivityName {
    return DeviceActivityName(rawValue: profile.id.uuidString)
  }
}
