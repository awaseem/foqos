import ManagedSettings

class AppBlockerUtil {
  let store = ManagedSettingsStore(
    named: ManagedSettingsStore.Name("foqosAppRestrictions")
  )

  func activateRestrictions(for profile: SharedData.ProfileSnapshot) {
    let selection = profile.selectedActivity
    applyRestrictions(
      for: profile,
      applicationTokens: selection.applicationTokens,
      categoryTokens: selection.categoryTokens,
      categoryApplicationExceptions: []
    )
  }

  func activateSoftUnblockRestrictions(
    for profile: SharedData.ProfileSnapshot,
    unblockedApplicationTokens: Set<ApplicationToken>,
    unblockedCategoryTokens: Set<ActivityCategoryToken>
  ) {
    let selection = profile.selectedActivity
    let applicationTokens: Set<ApplicationToken>
    let categoryTokens: Set<ActivityCategoryToken>

    if profile.enableAllowMode {
      applicationTokens = selection.applicationTokens.union(unblockedApplicationTokens)
      categoryTokens = selection.categoryTokens
    } else {
      applicationTokens = selection.applicationTokens.subtracting(unblockedApplicationTokens)
      categoryTokens = selection.categoryTokens.subtracting(unblockedCategoryTokens)
    }

    applyRestrictions(
      for: profile,
      applicationTokens: applicationTokens,
      categoryTokens: categoryTokens,
      categoryApplicationExceptions: unblockedApplicationTokens
    )
  }

  private func applyRestrictions(
    for profile: SharedData.ProfileSnapshot,
    applicationTokens: Set<ApplicationToken>,
    categoryTokens: Set<ActivityCategoryToken>,
    categoryApplicationExceptions: Set<ApplicationToken>
  ) {
    print("Starting restrictions...")

    let selection = profile.selectedActivity
    let allowOnlyApps = profile.enableAllowMode
    let allowOnlyDomains = profile.enableAllowModeDomains
    let strict = profile.enableStrictMode
    let enableSafariBlocking = profile.enableSafariBlocking
    let enableAdultContentBlocking = profile.enableAdultContentBlocking == true
    let domains = getWebDomains(from: profile)

    let webTokens = selection.webDomainTokens

    if allowOnlyApps {
      store.shield.applicationCategories = .all(except: applicationTokens)

      if enableSafariBlocking {
        store.shield.webDomainCategories = .all(except: webTokens)
      }

    } else {
      store.shield.applications = applicationTokens.isEmpty ? nil : applicationTokens
      store.shield.applicationCategories =
        categoryTokens.isEmpty
        ? nil
        : .specific(
          categoryTokens,
          except: categoryApplicationExceptions
        )

      if enableSafariBlocking {
        store.shield.webDomainCategories = .specific(selection.categoryTokens)
        store.shield.webDomains = webTokens
      }
    }

    if allowOnlyDomains {
      store.webContent.blockedByFilter = .all(except: domains)
    } else if enableAdultContentBlocking {
      store.webContent.blockedByFilter = .auto(domains)
    } else if !domains.isEmpty {
      store.webContent.blockedByFilter = .specific(domains)
    } else {
      store.webContent.blockedByFilter = nil
    }

    store.application.denyAppRemoval = strict
    store.application.denyAppInstallation = profile.enableBlockAppInstallation
  }

  func deactivateRestrictions() {
    print("Stoping restrictions...")

    store.shield.applications = nil
    store.shield.applicationCategories = nil
    store.shield.webDomains = nil
    store.shield.webDomainCategories = nil

    store.application.denyAppRemoval = false
    store.application.denyAppInstallation = false

    store.webContent.blockedByFilter = nil

    store.clearAllSettings()
  }

  func deactivateRestrictionsForBreak(for profile: SharedData.ProfileSnapshot) {
    print("Stopping restrictions for break (strict mode: \(profile.enableStrictMode))...")

    store.shield.applications = nil
    store.shield.applicationCategories = nil
    store.shield.webDomains = nil
    store.shield.webDomainCategories = nil

    store.webContent.blockedByFilter = nil
    store.application.denyAppInstallation = false

    if !profile.enableStrictMode {
      store.application.denyAppRemoval = false
    }
  }

  func getWebDomains(from profile: SharedData.ProfileSnapshot) -> Set<WebDomain> {
    if let domains = profile.domains {
      return Set(domains.map { WebDomain(domain: $0) })
    }

    return []
  }
}
