//
//  DeviceActivityMonitorExtension.swift
//  FoqosDeviceMonitor
//
//  Created by Ali Waseem on 2025-05-27.
//

import DeviceActivity
import ManagedSettings
import OSLog

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
    log.info("foqosDeviceActivityMonitorExtension initialized")
  }

  override func intervalDidStart(for activity: DeviceActivityName) {
    super.intervalDidStart(for: activity)

    guard let profile = getProfileForDeviceActivity(for: activity),
      let schedule = profile.schedule
    else {
      log.info("intervalDidStart for \(activity.rawValue), no profile found")
      return
    }

    guard schedule.isTodayScheduled() else {
      log.info("intervalDidStart for \(activity.rawValue), schedule not scheduled for today")
      return
    }

    log.info("intervalDidStart for \(activity.rawValue), profile: \(profile.name)")

    // If there is an existing active session, end it
    if SharedData.getActiveSharedSession() != nil {
      SharedData.endActiveSharedSession()
    }

    // Create a new active scheduled session for the profile
    SharedData.createSessionForSchedular(for: profile.id)

    // Start restrictions
    appBlocker.activateRestrictions(for: profile)
  }

  override func intervalDidEnd(for activity: DeviceActivityName) {
    guard let profile = getProfileForDeviceActivity(for: activity) else {
      log.info("intervalDidEnd for \(activity.rawValue), no profile found")
      return
    }

    guard let activeSession = SharedData.getActiveSharedSession() else {
      log.info("intervalDidEnd for \(activity.rawValue), no active session found")
      return
    }

    // Check to make sure the active session is the same as the profile before disabling restrictions
    if activeSession.blockedProfileId != profile.id {
      log.info(
        "intervalDidEnd for \(activity.rawValue), active session profile does not match device activity profile"
      )
      return
    }

    // End restrictions
    appBlocker.deactivateRestrictions()

    // End the active scheduled session
    SharedData.endActiveSharedSession()
  }

  private func getProfileForDeviceActivity(for activity: DeviceActivityName) -> SharedData
    .ProfileSnapshot?
  {
    let deviceRawName = activity.rawValue
    let sharedDataProfile = SharedData.snapshot(for: deviceRawName)

    if let profile = sharedDataProfile {
      return profile
    }

    return nil
  }
}
