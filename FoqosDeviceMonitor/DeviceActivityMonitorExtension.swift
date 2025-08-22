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
  override init() {
    super.init()
    log.info("foqosDeviceActivityMonitorExtension initialized")
  }

  let appBlocker = AppBlockerUtil()

  override func intervalDidStart(for activity: DeviceActivityName) {
    super.intervalDidStart(for: activity)

    let deviceRawName = activity.rawValue
    let sharedDataProfile = SharedData.snapshot(for: deviceRawName)

    guard let profile = sharedDataProfile else {
      log.info("intervalDidStart for \(deviceRawName), no profile found")
      return
    }

    log.info("intervalDidStart for \(deviceRawName), profile: \(profile.name)")

    appBlocker.activateRestrictions(for: profile)
  }

  override func intervalDidEnd(for activity: DeviceActivityName) {
    appBlocker.deactivateRestrictions()
  }
}
