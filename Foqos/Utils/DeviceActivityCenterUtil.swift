import DeviceActivity
import FamilyControls
import ManagedSettings
import SwiftUI

class DeviceActivityCenterUtil {
  static func scheduleTimerActivity(for profile: BlockedProfiles) {
    // Only schedule if the schedule is active
    guard let schedule = profile.schedule else { return }

    let center = DeviceActivityCenter()
    let scheduleTimerActivity = ScheduleTimerActivity()

    let deviceActivityName = scheduleTimerActivity.getDeviceActivityName(
      from: profile.id.uuidString)

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

  static func startBreakTimerActivity(for profile: BlockedProfiles) {
    let center = DeviceActivityCenter()
    let breakTimerActivity = BreakTimerActivity()
    let deviceActivityName = breakTimerActivity.getDeviceActivityName(from: profile.id.uuidString)

    let (intervalStart, intervalEnd) = getTimerActivityInterval(minutes: 15)
    let deviceActivitySchedule = DeviceActivitySchedule(
      intervalStart: intervalStart,
      intervalEnd: intervalEnd,
      repeats: true,
    )

    do {
      // Remove any existing schedule and create a new one
      center.stopMonitoring([deviceActivityName])
      try center.startMonitoring(deviceActivityName, during: deviceActivitySchedule)
      print("Scheduled break timer activity from \(intervalStart) to \(intervalEnd) daily")
    } catch {
      print("Failed to start break timer activity: \(error.localizedDescription)")
    }
  }

  static func removeScheduleTimerActivities(for profile: BlockedProfiles) {
    let center = DeviceActivityCenter()
    let scheduleTimerActivity = ScheduleTimerActivity()
    let deviceActivityName = scheduleTimerActivity.getDeviceActivityName(
      from: profile.id.uuidString)
    center.stopMonitoring([deviceActivityName])
  }

  static func removeScheduleTimerActivities(for activity: DeviceActivityName) {
    let center = DeviceActivityCenter()
    center.stopMonitoring([activity])
  }

  static func getActiveDeviceActivity(for profile: BlockedProfiles) -> DeviceActivityName? {
    let center = DeviceActivityCenter()
    let scheduleTimerActivity = ScheduleTimerActivity()
    let activities = center.activities

    return activities.first(where: {
      $0 == scheduleTimerActivity.getDeviceActivityName(from: profile.id.uuidString)
    })
  }

  static func getDeviceActivities() -> [DeviceActivityName] {
    let center = DeviceActivityCenter()
    return center.activities
  }

  private static func getTimerActivityInterval(minutes: Int) -> (
    intervalStart: DateComponents, intervalEnd: DateComponents
  ) {
    let intervalStart = DateComponents(hour: 0, minute: 0)

    // Get current time
    let now = Date()
    let currentComponents = Calendar.current.dateComponents([.hour, .minute], from: now)
    let currentHour = currentComponents.hour ?? 0
    let currentMinute = currentComponents.minute ?? 0

    // Calculate end time by adding minutes to current time
    let totalMinutes = currentMinute + minutes
    var endHour = currentHour + (totalMinutes / 60)
    var endMinute = totalMinutes % 60

    // Cap at 23:59 if it would roll over past midnight
    if endHour >= 24 || (endHour == 23 && endMinute >= 59) {
      endHour = 23
      endMinute = 59
    }

    let intervalEnd = DateComponents(hour: endHour, minute: endMinute)
    return (intervalStart: intervalStart, intervalEnd: intervalEnd)
  }
}
