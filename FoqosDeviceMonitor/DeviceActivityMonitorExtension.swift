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

  let store = ManagedSettingsStore(
    named: ManagedSettingsStore.Name("foqosAppRestrictions")
  )

  override func intervalDidStart(for activity: DeviceActivityName) {
    super.intervalDidStart(for: activity)

    // Use the first stored profile options if available
    guard let options = SharedData.profiles.values.first,
      let selection = options.selection
    else {
      log.info("intervalDidStart no stored profile options, doing nothing")
      return
    }

    let allowOnly = options.allowOnly ?? false
    let applicationTokens = selection.applicationTokens
    let categoriesTokens = selection.categoryTokens
    let webTokens = selection.webDomainTokens

    log.info(
      "intervalDidStart for \(activity.rawValue), count for applications: \(applicationTokens.count), categories: \(categoriesTokens.count), web domains: \(webTokens.count)"
    )

    if allowOnly {
      store.shield.applicationCategories =
        .all(except: applicationTokens)
      store.shield.webDomainCategories = .all(except: webTokens)
    } else {
      store.shield.applications = applicationTokens
      store.shield.applicationCategories = .specific(categoriesTokens)
      store.shield.webDomains = webTokens
    }

    store.application.denyAppRemoval = options.strict ?? false

    log.info(
      "intervalDidStart for \(activity.rawValue), reapplying restrictions"
    )

  }
}
