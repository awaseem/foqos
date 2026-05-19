import DeviceActivity
import Foundation
import ManagedSettings

class ShieldActionExtension: ShieldActionDelegate, NSExtensionRequestHandling {
  private let appAccessActivityId = "ShieldAppAccessTimerActivity"

  override init() {
    super.init()
    SharedData.debugLog(
      "ShieldActionExtension init bundle=\(Bundle.main.bundleIdentifier ?? "nil") activePauseProfile=\(SharedData.activePauseModeProfileId ?? "nil")"
    )
  }

  func beginRequest(with context: NSExtensionContext) {
    SharedData.debugLog(
      "ShieldActionExtension beginRequest context=\(String(describing: context)) activePauseProfile=\(SharedData.activePauseModeProfileId ?? "nil")"
    )
  }

  override func handle(
    action: ShieldAction,
    for application: ApplicationToken,
    completionHandler: @escaping (ShieldActionResponse) -> Void
  ) {
    SharedData.debugLog(
      "Shield action received action=\(action.rawValue) activePauseProfile=\(SharedData.activePauseModeProfileId ?? "nil") tokenKey=\(String(SharedData.tokenKey(application).prefix(12)))"
    )

    guard action == .primaryButtonPressed else {
      SharedData.debugLog("Shield action ignored non-primary action=\(action.rawValue)")
      completionHandler(.close)
      return
    }

    guard let profileId = SharedData.activePauseModeProfileId else {
      SharedData.debugLog("Shield action closing: no active pause profile")
      completionHandler(.close)
      return
    }

    guard let snapshot = SharedData.snapshot(for: profileId) else {
      SharedData.debugLog("Shield action closing: snapshot missing profile=\(profileId)")
      completionHandler(.close)
      return
    }

    guard let strategyData = snapshot.strategyData else {
      SharedData.debugLog("Shield action closing: strategyData missing profile=\(profileId)")
      completionHandler(.close)
      return
    }

    let pauseData = StrategyPauseTimerData.toStrategyPauseTimerData(from: strategyData)

    let tokenKey = SharedData.tokenKey(application)
    SharedData.debugLog(
      "Unlocking app from shield profile=\(profileId) minutes=\(pauseData.pauseDurationInMinutes) tokenKey=\(String(tokenKey.prefix(12)))"
    )
    SharedData.addPauseUnlockedApplicationToken(application)
    startAccessTimer(
      profileId: profileId,
      tokenKey: tokenKey,
      durationInMinutes: pauseData.pauseDurationInMinutes
    )
    AppBlockerUtil().activateRestrictions(for: snapshot)

    SharedData.debugLog(
      "Shield action completed profile=\(profileId) unlockedCount=\(SharedData.pauseUnlockedApplicationTokens.count)"
    )
    completionHandler(.close)
  }

  override func handle(
    action: ShieldAction,
    for webDomain: WebDomainToken,
    completionHandler: @escaping (ShieldActionResponse) -> Void
  ) {
    SharedData.debugLog("Shield action webDomain action=\(action.rawValue); closing")
    completionHandler(.close)
  }

  override func handle(
    action: ShieldAction,
    for category: ActivityCategoryToken,
    completionHandler: @escaping (ShieldActionResponse) -> Void
  ) {
    SharedData.debugLog(
      "Shield action category received action=\(action.rawValue) activePauseProfile=\(SharedData.activePauseModeProfileId ?? "nil") tokenKey=\(String(SharedData.tokenKey(category).prefix(12)))"
    )

    guard action == .primaryButtonPressed else {
      SharedData.debugLog("Shield action category ignored non-primary action=\(action.rawValue)")
      completionHandler(.close)
      return
    }

    guard let profileId = SharedData.activePauseModeProfileId else {
      SharedData.debugLog("Shield action category closing: no active pause profile")
      completionHandler(.close)
      return
    }

    guard let snapshot = SharedData.snapshot(for: profileId) else {
      SharedData.debugLog("Shield action category closing: snapshot missing profile=\(profileId)")
      completionHandler(.close)
      return
    }

    guard let strategyData = snapshot.strategyData else {
      SharedData.debugLog(
        "Shield action category closing: strategyData missing profile=\(profileId)"
      )
      completionHandler(.close)
      return
    }

    let pauseData = StrategyPauseTimerData.toStrategyPauseTimerData(from: strategyData)
    let tokenKey = SharedData.tokenKey(category)
    SharedData.debugLog(
      "Unlocking category from shield profile=\(profileId) minutes=\(pauseData.pauseDurationInMinutes) tokenKey=\(String(tokenKey.prefix(12)))"
    )
    SharedData.addPauseUnlockedCategoryToken(category)
    startAccessTimer(
      profileId: profileId,
      resourceKind: "category",
      tokenKey: tokenKey,
      durationInMinutes: pauseData.pauseDurationInMinutes
    )
    AppBlockerUtil().activateRestrictions(for: snapshot)

    SharedData.debugLog(
      "Shield category action completed profile=\(profileId) unlockedCategoryCount=\(SharedData.pauseUnlockedCategoryTokens.count)"
    )
    completionHandler(.close)
  }

  private func startAccessTimer(
    profileId: String,
    resourceKind: String = "app",
    tokenKey: String,
    durationInMinutes: Int
  ) {
    let center = DeviceActivityCenter()
    let activityName = DeviceActivityName(
      rawValue: "\(appAccessActivityId):\(profileId)|\(resourceKind)|\(tokenKey)"
    )
    let now = Date()
    let calendar = Calendar.current
    let intervalStart = calendar.dateComponents([.hour, .minute, .second], from: now)
    let endDate =
      calendar.date(
        byAdding: .minute,
        value: max(durationInMinutes, 1),
        to: now
      ) ?? now.addingTimeInterval(60)
    let intervalEnd = calendar.dateComponents([.hour, .minute, .second], from: endDate)
    let schedule = DeviceActivitySchedule(
      intervalStart: intervalStart,
      intervalEnd: intervalEnd,
      repeats: false
    )

    center.stopMonitoring([activityName])

    do {
      try center.startMonitoring(activityName, during: schedule)
      SharedData.debugLog(
        "Started app access timer activity=\(activityName.rawValue) minutes=\(max(durationInMinutes, 1))"
      )
    } catch {
      SharedData.debugLog(
        "Failed to start app access timer activity=\(activityName.rawValue) error=\(error.localizedDescription)"
      )
      if resourceKind == "category" {
        SharedData.removePauseUnlockedCategoryToken(matching: tokenKey)
      } else {
        SharedData.removePauseUnlockedApplicationToken(matching: tokenKey)
      }
    }
  }
}
