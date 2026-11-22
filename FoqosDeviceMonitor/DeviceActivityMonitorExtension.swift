//
//  DeviceActivityMonitorExtension.swift
//  FoqosDeviceMonitor
//
//  Created by Ali Waseem on 2025-05-27.
//

import DeviceActivity
import ManagedSettings
import OSLog
import UserNotifications

private let log = Logger(
  subsystem: "com.foqos.monitor",
  category: "DeviceActivity"
)

// Optionally override any of the functions below.
// Make sure that your class name matches the NSExtensionPrincipalClass in your Info.plist.
class DeviceActivityMonitorExtension: DeviceActivityMonitor {
  private let appBlocker = AppBlockerUtil()

  override init() {
    super.init()
  }

  override func intervalWillStartWarning(for activity: DeviceActivityName) {
    super.intervalWillStartWarning(for: activity)
    guard let profile = SharedData.snapshot(for: activity.rawValue),
      profile.enableBlockingWarnings == true,
      let start = profile.schedule?.startForWarning(
        at: Date(), profileCreatedAt: profile.createdAt),
      SharedData.getActiveSharedSession()?.blockedProfileId != profile.id
    else { return }

    postWarning(
      for: activity, profile: profile, deadline: start,
      message: "Scheduled blocking starts at \(start.formatted(date: .omitted, time: .shortened)).")
  }

  override func intervalWillEndWarning(for activity: DeviceActivityName) {
    super.intervalWillEndWarning(for: activity)
    let now = Date()
    guard let session = SharedData.getActiveSharedSession(), session.endTime == nil,
      let profile = SharedData.snapshot(for: session.blockedProfileId.uuidString),
      profile.enableBlockingWarnings == true,
      let name = Self.endingAccess(for: activity, session: session, at: now)
    else { return }

    let center = DeviceActivityCenter()
    guard let schedule = center.schedule(for: activity), let minutes = schedule.warningTime?.minute,
      let interval = schedule.nextInterval, interval.contains(now)
    else { return }

    let sessionEnd: Date?
    if session.tag == profile.id.uuidString {
      sessionEnd = profile.schedule?.endDate(forSessionStartingAt: session.startTime)
    } else {
      let focusTimer = StrategyTimerActivity().getDeviceActivityName(from: profile.id.uuidString)
      sessionEnd = center.schedule(for: focusTimer)?.nextInterval?.end
    }
    guard
      BlockingWarning.isEndWarningDue(
        at: now, end: interval.end, leadMinutes: minutes, sessionEnd: sessionEnd)
    else { return }

    postWarning(
      for: activity, profile: profile, deadline: interval.end,
      message: "\(name) ends at \(interval.end.formatted(date: .omitted, time: .shortened)).")
  }

  static func endingAccess(
    for activity: DeviceActivityName, session: SharedData.SessionSnapshot, at now: Date
  ) -> String? {
    let profileID = session.blockedProfileId.uuidString
    if activity == BreakTimerActivity().getDeviceActivityName(from: profileID),
      session.breakStartTime != nil, session.breakEndTime == nil
    {
      return "Break"
    }
    if activity == PauseTimerActivity().getDeviceActivityName(from: profileID),
      session.pauseStartTime != nil, session.pauseEndTime == nil
    {
      return "Pause"
    }
    guard let ids = SoftUnblockGrantScheduler.identifiers(from: activity),
      ids.profileId == session.blockedProfileId, ids.sessionId == session.id,
      let grant = SoftUnblockGrantStore.grant(id: ids.grantId, sessionId: ids.sessionId),
      !grant.isExpired(at: now)
    else { return nil }
    return "Temporary Access"
  }

  private func postWarning(
    for activity: DeviceActivityName, profile: SharedData.ProfileSnapshot, deadline: Date,
    message: String
  ) {
    let content = UNMutableNotificationContent()
    content.title = profile.name
    content.body = message
    content.sound = .default
    let id =
      "\(BlockingWarning.identifierPrefix)\(activity.rawValue).\(Int(deadline.timeIntervalSince1970))"
    let request = UNNotificationRequest(identifier: id, content: content, trigger: nil)
    UNUserNotificationCenter.current().add(request) { error in
      if let error { log.error("Could not post blocking warning: \(error.localizedDescription)") }
    }
  }

  override func intervalDidStart(for activity: DeviceActivityName) {
    super.intervalDidStart(for: activity)

    log.info("intervalDidStart for activity: \(activity.rawValue)")
    TimerActivityUtil.startTimerActivity(for: activity)
  }

  override func intervalDidEnd(for activity: DeviceActivityName) {
    super.intervalDidEnd(for: activity)

    log.info("intervalDidEnd for activity: \(activity.rawValue)")
    TimerActivityUtil.stopTimerActivity(for: activity)
  }
}
