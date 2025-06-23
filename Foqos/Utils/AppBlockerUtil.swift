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

  func activateRestrictions(for profile: BlockedProfiles) {
    print("Starting restrictions...")

    let selection = profile.selectedActivity
    let allowOnly = profile.enableAllowMode
    let strict = profile.enableStrictMode

    let applicationTokens = selection.applicationTokens
    let categoriesTokens = selection.categoryTokens
    let webTokens = selection.webDomainTokens
    let domains = BlockedProfiles.getWebDomains(from: profile)

    if allowOnly {
      store.shield.applicationCategories =
        .all(except: applicationTokens)
      store.shield.webDomainCategories = .all(except: webTokens)

      store.webContent.blockedByFilter = .all(except: domains)
    } else {
      store.shield.applications = applicationTokens
      store.shield.applicationCategories = .specific(categoriesTokens)
      store.shield.webDomainCategories = .specific(categoriesTokens)
      store.shield.webDomains = webTokens

      store.webContent.blockedByFilter = .specific(domains)
    }

    store.application.denyAppRemoval = strict
  }

  func deactivateRestrictions() {
    print("Stoping restrictions...")

    store.shield.applications = nil
    store.shield.applicationCategories = nil
    store.shield.webDomains = nil

    store.application.denyAppRemoval = false

    store.webContent.blockedByFilter = nil

    store.clearAllSettings()
  }
}
