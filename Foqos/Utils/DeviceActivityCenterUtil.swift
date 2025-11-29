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
      stopActivities(for: [deviceActivityName], with: center)
      return
    }

    let (intervalStart, intervalEnd) = scheduleTimerActivity.getScheduleInterval(from: schedule)
    let deviceActivitySchedule = DeviceActivitySchedule(
      intervalStart: intervalStart,
      intervalEnd: intervalEnd,
      repeats: true,
    )

    do {
      // Remove any existing schedule and create a new one
      stopActivities(for: [deviceActivityName], with: center)
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

    let (intervalStart, intervalEnd) = getTimeIntervalStartAndEnd(
      from: profile.breakTimeInMinutes)
    let deviceActivitySchedule = DeviceActivitySchedule(
      intervalStart: intervalStart,
      intervalEnd: intervalEnd,
      repeats: false,
    )

    do {
      // Remove any existing schedule and create a new one
      stopActivities(for: [deviceActivityName], with: center)
      try center.startMonitoring(deviceActivityName, during: deviceActivitySchedule)
      print("Scheduled break timer activity from \(intervalStart) to \(intervalEnd) daily")
    } catch {
      print("Failed to start break timer activity: \(error.localizedDescription)")
    }
  }

  static func startStrategyTimerActivity(for profile: BlockedProfiles) {
    guard let strategyData = profile.strategyData else {
      print("No strategy data found for profile: \(profile.id.uuidString)")
      return
    }
    let timerData = StrategyTimerData.toStrategyTimerData(from: strategyData)

    let center = DeviceActivityCenter()
    let strategyTimerActivity = StrategyTimerActivity()
    let deviceActivityName = strategyTimerActivity.getDeviceActivityName(
      from: profile.id.uuidString)

    let (intervalStart, intervalEnd) = getTimeIntervalStartAndEnd(
      from: timerData.durationInMinutes)

    let deviceActivitySchedule = DeviceActivitySchedule(
      intervalStart: intervalStart,
      intervalEnd: intervalEnd,
      repeats: false,
    )

    do {
      // Remove any existing activity and create a new one
      stopActivities(for: [deviceActivityName], with: center)
      try center.startMonitoring(deviceActivityName, during: deviceActivitySchedule)
      print("Scheduled strategy timer activity from \(intervalStart) to \(intervalEnd) daily")
    } catch {
      print("Failed to start strategy timer activity: \(error.localizedDescription)")
    }
  }

  static func removeScheduleTimerActivities(for profile: BlockedProfiles) {
    let scheduleTimerActivity = ScheduleTimerActivity()
    let deviceActivityName = scheduleTimerActivity.getDeviceActivityName(
      from: profile.id.uuidString)
    stopActivities(for: [deviceActivityName])
  }

  static func removeScheduleTimerActivities(for activity: DeviceActivityName) {
    stopActivities(for: [activity])
  }

  static func removeAllBreakTimerActivities() {
    let center = DeviceActivityCenter()
    let activities = center.activities
    let breakTimerActivity = BreakTimerActivity()
    let breakTimerActivities = breakTimerActivity.getAllBreakTimerActivities(from: activities)
    stopActivities(for: breakTimerActivities, with: center)
  }

  static func removeBreakTimerActivity(for profile: BlockedProfiles) {
    let breakTimerActivity = BreakTimerActivity()
    let deviceActivityName = breakTimerActivity.getDeviceActivityName(from: profile.id.uuidString)
    stopActivities(for: [deviceActivityName])
  }

  static func removeAllStrategyTimerActivities() {
    let center = DeviceActivityCenter()
    let activities = center.activities
    let strategyTimerActivity = StrategyTimerActivity()
    let strategyTimerActivities = strategyTimerActivity.getAllStrategyTimerActivities(
      from: activities)
    stopActivities(for: strategyTimerActivities, with: center)
  }

  static func getActiveScheduleTimerActivity(for profile: BlockedProfiles) -> DeviceActivityName? {
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

  private static func stopActivities(
    for activities: [DeviceActivityName], with center: DeviceActivityCenter? = nil
  ) {
    let center = center ?? DeviceActivityCenter()

    if activities.isEmpty {
      // No activities to stop
      print("No activities to stop")
      return
    }

    center.stopMonitoring(activities)
  }

  private static func getTimeIntervalStartAndEnd(from minutes: Int) -> (
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
