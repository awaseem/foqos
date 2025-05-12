import DeviceActivity
import FamilyControls
import ManagedSettings
import SwiftUI

class AppBlockerUtil {
    let store = ManagedSettingsStore(
        named: ManagedSettingsStore.Name("foqosAppRestrictions")
    )
    let center = DeviceActivityCenter()

    func activateRestrictions(
        selection: FamilyActivitySelection,
        strict: Bool = false,
        allowOnly: Bool = false
    ) {
        print("Starting restrictions...")

        let applicationTokens = selection.applicationTokens
        let categoriesTokens = selection.categoryTokens
        let webTokens = selection.webDomainTokens

        if (allowOnly) {
            store.shield.applicationCategories =
                .all(except: applicationTokens)
            store.shield.webDomainCategories = .all(except: webTokens)
        } else {
            store.shield.applications =  applicationTokens
            store.shield.applicationCategories = .specific(categoriesTokens)
            store.shield.webDomains = webTokens
        }
        
        store.application.denyAppRemoval = strict

        // Set up a DeviceActivitySchedule
        let schedule = DeviceActivitySchedule(
            intervalStart: DateComponents(hour: 0, minute: 0),
            intervalEnd: DateComponents(hour: 23, minute: 59),
            repeats: true
        )

        let activity = DeviceActivityName("foqosDeviceActivity")
        let eventCenter = DeviceActivityCenter()
        do {
            try eventCenter.startMonitoring(activity, during: schedule)
        } catch {
            print("Error starting monitoring: \(error)")
        }
    }

    func deactivateRestrictions() {
        print("Stoping restrictions...")

        store.shield.applications = nil
        store.shield.applicationCategories = nil
        store.shield.webDomains = nil
        
        store.application.denyAppRemoval = false
        
        store.clearAllSettings()

        center.stopMonitoring([DeviceActivityName("foqosDeviceActivity")])
    }
}
