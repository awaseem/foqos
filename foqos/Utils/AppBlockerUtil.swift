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
            store.shield.webDomainCategories = .specific(categoriesTokens)
            store.shield.webDomains = webTokens
        }
        
        store.application.denyAppRemoval = strict
    }

    func deactivateRestrictions() {
        print("Stoping restrictions...")

        store.shield.applications = nil
        store.shield.applicationCategories = nil
        store.shield.webDomains = nil
        
        store.application.denyAppRemoval = false
        
        store.clearAllSettings()
    }
}
