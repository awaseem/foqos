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

        log.info("intervalDidStart for \(activity.rawValue)")
        store.shield.applications = nil
    }
}
