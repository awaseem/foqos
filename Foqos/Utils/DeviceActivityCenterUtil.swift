import DeviceActivity
import FamilyControls
import ManagedSettings
import SwiftUI

class DeviceActivityCenterUtil {
  static func scheduleRestrictions(for profile: BlockedProfiles) {
    // Only schedule if the schedule is active
    let center = DeviceActivityCenter()
    guard let schedule = profile.schedule else { return }

    let deviceActivityName = getDeviceActivityName(from: profile)

    // If the schedule is not active, remove any existing schedule
    if !schedule.isActive {
      center.stopMonitoring([deviceActivityName])
      return
    }

    let intervalStart = DateComponents(hour: schedule.startHour, minute: schedule.startMinute)
    let intervalEnd = DateComponents(hour: schedule.endHour, minute: schedule.endMinute)
    let deviceActivitySchedule = DeviceActivitySchedule(
      intervalStart: intervalStart,
      intervalEnd: intervalEnd,
      repeats: true,
    )

    do {
      // Remove any existing schedule and create a new one
      center.stopMonitoring([deviceActivityName])
      try center.startMonitoring(deviceActivityName, during: deviceActivitySchedule)
      print("Scheduled restrictions from \(intervalStart) to \(intervalEnd) daily")
    } catch {
      print("Failed to start monitoring: \(error.localizedDescription)")
    }
  }

  static func removeScheduleRestrictions(for profile: BlockedProfiles) {
    let center = DeviceActivityCenter()
    let deviceActivityName = getDeviceActivityName(from: profile)
    center.stopMonitoring([deviceActivityName])
  }

  static func removeScheduleRestrictions(for activity: DeviceActivityName) {
    let center = DeviceActivityCenter()
    center.stopMonitoring([activity])
  }

  static func getActiveDeviceActivity(for profile: BlockedProfiles) -> DeviceActivityName? {
    let center = DeviceActivityCenter()
    let activities = center.activities

    return activities.first(where: { $0 == getDeviceActivityName(from: profile) })
  }

  static func getDeviceActivities() -> [DeviceActivityName] {
    let center = DeviceActivityCenter()
    return center.activities
  }

  private static func getDeviceActivityName(from profile: BlockedProfiles) -> DeviceActivityName {
    return DeviceActivityName(rawValue: profile.id.uuidString)
  }
}
