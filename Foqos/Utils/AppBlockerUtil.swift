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
    let allowOnlyApps = profile.enableAllowMode
    let allowOnlyDomains = profile.enableAllowModeDomains
    let strict = profile.enableStrictMode
    let domains = BlockedProfiles.getWebDomains(from: profile)

    let applicationTokens = selection.applicationTokens
    let categoriesTokens = selection.categoryTokens
    let webTokens = selection.webDomainTokens

    if allowOnlyApps {
      store.shield.applicationCategories =
        .all(except: applicationTokens)
      store.shield.webDomainCategories = .all(except: webTokens)

    } else {
      store.shield.applications = applicationTokens
      store.shield.applicationCategories = .specific(categoriesTokens)
      store.shield.webDomainCategories = .specific(categoriesTokens)
      store.shield.webDomains = webTokens
    }

    if allowOnlyDomains {
      store.webContent.blockedByFilter = .all(except: domains)
    } else {
      store.webContent.blockedByFilter = .specific(domains)
    }

    store.application.denyAppRemoval = strict
  }

  func scheduleRestrictions(for profile: BlockedProfiles) {
    // Configure a daily schedule from 7:30 PM to 8:00 PM
    let intervalStart = DateComponents(hour: 19, minute: 30)
    let intervalEnd = DateComponents(hour: 20, minute: 0)
    let schedule = DeviceActivitySchedule(
      intervalStart: intervalStart,
      intervalEnd: intervalEnd,
      repeats: true,
    )

    let center = DeviceActivityCenter()

    // Stop any existing monitoring for the same name before starting again
    center.stopMonitoring([.daily])

    do {
      try center.startMonitoring(.daily, during: schedule)
      print("Scheduled restrictions from 7:30 PM to 8:00 PM daily")
    } catch {
      print("Failed to start monitoring: \(error.localizedDescription)")
    }
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
