import DeviceActivity
import FamilyControls
import ManagedSettings
import SwiftUI

extension DeviceActivityName {
    static let daily = Self("daily")
}

class AppBlockerUtil {
    let store = ManagedSettingsStore(
        named: ManagedSettingsStore.Name("foqosAppRestrictions")
    )

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
        
        SharedData.selection = selection
        SharedData.strict = strict
        SharedData.allowOnly = allowOnly

        // Set up a DeviceActivitySchedule
        let schedule = DeviceActivitySchedule(
            intervalStart: DateComponents(hour: 0, minute: 0),
            intervalEnd: DateComponents(hour: 23, minute: 59),
            repeats: true
        )

        do {
            let center = DeviceActivityCenter()
            try center.startMonitoring(.daily, during: schedule)
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
        
        SharedData.selection = nil
        SharedData.strict = nil
        SharedData.allowOnly = nil

        let center = DeviceActivityCenter()
        center.stopMonitoring([.daily])
    }
}
