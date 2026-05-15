//
//  ShieldActionExtension.swift
//  FoqosShieldAction
//
//  Handles button taps on the system shield for profiles using PauseBlockingStrategy.
//
//  When the countdown has elapsed: removes only the tapped app from the blocked set
//  (all other profile apps remain blocked) and opens the app via .defer.
//
//  When tapped too early: calls .close so the shield dismisses and the user can
//  re-tap the app to see the updated remaining time.
//

import ManagedSettings

class ShieldActionExtension: ShieldActionDelegate {
  override func handle(
    action: ShieldAction,
    for application: ApplicationToken,
    completionHandler: @escaping (ShieldActionResponse) -> Void
  ) {
    guard action == .primaryButtonPressed else {
      completionHandler(.close)
      return
    }

    // ApplicationToken.description returns the bundle identifier in practice.
    // This must match the key used in ShieldConfigurationExtension (application.bundleIdentifier).
    let bundleId = application.description

    guard
      let profileId = SharedData.pauseModeActiveProfileId,
      let snapshot = SharedData.snapshot(for: profileId),
      let data = snapshot.strategyData
    else {
      completionHandler(.close)
      return
    }

    let delay = StrategyPauseDelayData.toStrategyPauseDelayData(from: data)
    let elapsed = SharedData.elapsedPauseTime(for: bundleId)

    // Grace window: 0.5s tolerance for extension timer drift.
    // Also guard against stale timers (>120s) — ShieldConfig resets those on re-appearance.
    guard elapsed >= Double(delay.delaySeconds) - 0.5, elapsed < 120 else {
      // Tapped too early — dismiss shield; timer persists so re-tapping shows updated countdown.
      completionHandler(.close)
      return
    }

    // Countdown complete — diff the blocked set to remove only this specific app.
    // All other apps in the profile remain blocked.
    let store = ManagedSettingsStore(named: ManagedSettingsStore.Name("foqosAppRestrictions"))
    var currentBlocked = store.shield.applications ?? []
    currentBlocked.remove(application)
    store.shield.applications = currentBlocked.isEmpty ? nil : currentBlocked

    // Record unlock so ShieldConfig shows the normal shield if this app is tapped again
    var unlocked = SharedData.pauseUnlockedApps
    unlocked.insert(bundleId)
    SharedData.pauseUnlockedApps = unlocked

    // Clean up this app's pause timer
    SharedData.clearPauseTimer(for: bundleId)

    // Open the app
    completionHandler(.defer)
  }

  override func handle(
    action: ShieldAction,
    for webDomain: WebDomainToken,
    completionHandler: @escaping (ShieldActionResponse) -> Void
  ) {
    completionHandler(.close)
  }

  override func handle(
    action: ShieldAction,
    for category: ActivityCategoryToken,
    completionHandler: @escaping (ShieldActionResponse) -> Void
  ) {
    completionHandler(.close)
  }
}
