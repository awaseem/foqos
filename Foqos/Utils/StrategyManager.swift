import SwiftData
import SwiftUI
import WidgetKit

class StrategyManager: ObservableObject {
  static var shared = StrategyManager()

  static let availableStrategies: [BlockingStrategy] = [
    NFCBlockingStrategy(),
    ManualBlockingStrategy(),
    NFCManualBlockingStrategy(),
    QRCodeBlockingStrategy(),
    QRManualBlockingStrategy(),
  ]

  @Published var elapsedTime: TimeInterval = 0
  @Published var timer: Timer?
  @Published var activeSession: BlockedProfileSession?

  @Published var showCustomStrategyView: Bool = false
  @Published var customStrategyView: (any View)? = nil

  @Published var errorMessage: String?

  @AppStorage("emergencyUnblocksRemaining") private var emergencyUnblocksRemaining: Int = 3

  private let liveActivityManager = LiveActivityManager.shared

  private let timersUtil = TimersUtil()
  private let appBlocker = AppBlockerUtil()

  var isBlocking: Bool {
    return activeSession?.isActive == true
  }

  var isBreakActive: Bool {
    return activeSession?.isBreakActive == true
  }

  var isBreakAvailable: Bool {
    return activeSession?.isBreakAvailable ?? false
  }

  func defaultReminderMessage(forProfile profile: BlockedProfiles?) -> String {
    let baseMessage = "Get back to productivity"
    guard let profile else {
      return baseMessage
    }
    return baseMessage + " by enabling \(profile.name)"
  }

  func loadActiveSession(context: ModelContext) {
    activeSession = getActiveSession(context: context)

    if activeSession?.isActive == true {
      // If the session is active and the break is not active, start the timer
      if !isBreakActive {
        startTimer()
      }

      // Start live activity for existing session if one exists
      // live activities can only be started when the app is in the foreground
      if let session = activeSession {
        liveActivityManager.startSessionActivity(session: session)
      }
    } else {
      // Close live activity if no session is active and a scheduled session might have ended
      liveActivityManager.endSessionActivity()
    }
  }

  func toggleBlocking(context: ModelContext, activeProfile: BlockedProfiles?) {
    if isBlocking {
      stopBlocking(context: context)
    } else {
      startBlocking(context: context, activeProfile: activeProfile)
    }
  }

  func toggleBreak() {
    guard let session = activeSession else {
      print("active session does not exist")
      return
    }

    if session.isBreakActive {
      stopBreak()
    } else {
      startBreak()
    }
  }

  func startTimer() {
    timer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { _ in
      if let startTime = self.activeSession?.startTime {
        let rawElapsedTime = Date().timeIntervalSince(startTime)
        let breakDuration = self.calculateBreakDuration()
        self.elapsedTime = rawElapsedTime - breakDuration
      }
    }
  }

  func stopTimer() {
    timer?.invalidate()
    timer = nil
  }

  private func calculateBreakDuration() -> TimeInterval {
    guard let session = activeSession else {
      return 0
    }

    guard let breakStartTime = session.breakStartTime else {
      return 0
    }

    if let breakEndTime = session.breakEndTime {
      return breakEndTime.timeIntervalSince(breakStartTime)
    }

    return 0
  }

  func toggleSessionFromDeeplink(
    _ profileId: String,
    url: URL,
    context: ModelContext
  ) {
    guard let profileUUID = UUID(uuidString: profileId) else {
      self.errorMessage = "failed to parse profile in tag"
      return
    }

    do {
      guard
        let profile = try BlockedProfiles.findProfile(
          byID: profileUUID,
          in: context
        )
      else {
        self.errorMessage =
          "Failed to find a profile stored locally that matches the tag"
        return
      }

      let manualStrategy = getStrategy(id: ManualBlockingStrategy.id)

      if let localActiveSession = getActiveSession(context: context) {
        if profile.disableBackgroundStops {
          print(
            "profile: \(profile.name) has disable background stops enabled, not stopping it"
          )
          self.errorMessage =
            "profile: \(profile.name) has disable background stops enabled, not stopping it"
          return
        }

        _ =
          manualStrategy
          .stopBlocking(
            context: context,
            session: localActiveSession
          )
      } else {
        _ = manualStrategy.startBlocking(
          context: context,
          profile: profile,
          forceStart: true
        )
      }
    } catch {
      self.errorMessage = "Something went wrong fetching profile"
    }
  }

  func startSessionFromBackground(
    _ profileId: UUID,
    context: ModelContext
  ) {
    do {
      guard
        let profile = try BlockedProfiles.findProfile(
          byID: profileId,
          in: context
        )
      else {
        self.errorMessage =
          "Failed to find a profile stored locally that matches the tag"
        return
      }

      let manualStrategy = getStrategy(id: ManualBlockingStrategy.id)

      if let localActiveSession = getActiveSession(context: context) {
        print(
          "session is already active for profile: \(localActiveSession.blockedProfile.name), not starting a new one"
        )
        return
      }

      _ = manualStrategy.startBlocking(
        context: context,
        profile: profile,
        forceStart: true
      )
    } catch {
      self.errorMessage = "Something went wrong fetching profile"
    }
  }

  func stopSessionFromBackground(
    _ profileId: UUID,
    context: ModelContext
  ) {
    do {
      guard
        let profile = try BlockedProfiles.findProfile(
          byID: profileId,
          in: context
        )
      else {
        self.errorMessage =
          "Failed to find a profile stored locally that matches the tag"
        return
      }

      let manualStrategy = getStrategy(id: ManualBlockingStrategy.id)

      guard let localActiveSession = getActiveSession(context: context) else {
        print(
          "session is not active for profile: \(profile.name), not stopping it"
        )
        return
      }

      if localActiveSession.blockedProfile.id != profile.id {
        print(
          "session is not active for profile: \(profile.name), not stopping it"
        )
        self.errorMessage =
          "session is not active for profile: \(profile.name), not stopping it"
        return
      }

      if profile.disableBackgroundStops {
        print(
          "profile: \(profile.name) has disable background stops enabled, not stopping it"
        )
        self.errorMessage =
          "profile: \(profile.name) has disable background stops enabled, not stopping it"
        return
      }

      let _ = manualStrategy.stopBlocking(
        context: context,
        session: localActiveSession
      )
    } catch {
      self.errorMessage = "Something went wrong fetching profile"
    }
  }

  func getRemainingEmergencyUnblocks() -> Int {
    return emergencyUnblocksRemaining
  }

  func emergencyUnblock(context: ModelContext) {
    // Do not allow emergency unblocks if there are no remaining
    if emergencyUnblocksRemaining == 0 {
      return
    }

    // Do not allow emergency unblocks if there is no active session
    guard let activeSession = getActiveSession(context: context) else {
      return
    }

    // Stop the active session using the manual strategy, by passes any other strategy in view
    let manualStrategy = getStrategy(id: ManualBlockingStrategy.id)
    _ = manualStrategy.stopBlocking(
      context: context,
      session: activeSession
    )

    // Do end sections for the profile
    self.liveActivityManager.endSessionActivity()
    self.scheduleReminder(profile: activeSession.blockedProfile)
    self.stopTimer()

    // Decrement the remaining emergency unblocks
    emergencyUnblocksRemaining -= 1

    // Refresh widgets when emergency unblock ends session
    WidgetCenter.shared.reloadTimelines(ofKind: "ProfileControlWidget")
  }

  func resetEmergencyUnblocks() {
    emergencyUnblocksRemaining = 3
  }

  static func getStrategyFromId(id: String) -> BlockingStrategy {
    if let strategy = availableStrategies.first(
      where: {
        $0.getIdentifier() == id
      })
    {
      return strategy
    } else {
      return NFCBlockingStrategy()
    }
  }

  func getStrategy(id: String) -> BlockingStrategy {
    var strategy = StrategyManager.getStrategyFromId(id: id)

    strategy.onSessionCreation = { session in
      self.dismissView()

      // Remove any timers and notifications that were scheduled
      self.timersUtil.cancelAll()

      switch session {
      case .started(let session):
        self.activeSession = session
        self.startTimer()
        self.errorMessage = nil
        self.liveActivityManager
          .startSessionActivity(session: session)

        // Refresh widgets when session starts
        WidgetCenter.shared.reloadTimelines(ofKind: "ProfileControlWidget")
      case .ended(let endedProfile):
        self.activeSession = nil
        self.liveActivityManager.endSessionActivity()
        self.scheduleReminder(profile: endedProfile)

        self.stopTimer()
        self.elapsedTime = 0

        // Refresh widgets when session ends
        WidgetCenter.shared.reloadTimelines(ofKind: "ProfileControlWidget")
      }
    }

    strategy.onErrorMessage = { message in
      self.dismissView()

      self.errorMessage = message
    }

    return strategy
  }

  private func startBreak() {
    guard let session = activeSession else {
      print("Breaks only available in active session")
      return
    }

    if !session.isBreakAvailable {
      print("Breaks is not availble")
      return
    }

    appBlocker.deactivateRestrictions()
    session.startBreak()

    // Update live activity to show break state
    liveActivityManager.updateBreakState(session: session)

    // Schedule a reminder to get back to the profile after the break
    scheduleBreakReminder(profile: session.blockedProfile)

    // Pause the timer during break
    stopTimer()

    // Refresh widgets when break starts
    WidgetCenter.shared.reloadTimelines(ofKind: "ProfileControlWidget")
  }

  private func stopBreak() {
    guard let session = activeSession else {
      print("Breaks only available in active session")
      return
    }

    if !session.isBreakAvailable {
      print("Breaks is not availble")
      return
    }

    let profile = session.blockedProfile
    appBlocker.activateRestrictions(for: BlockedProfiles.getSnapshot(for: profile))

    session.endBreak()

    // Update live activity to show break has ended
    liveActivityManager.updateBreakState(session: session)

    // Cancel all notifications that were scheduled during break
    timersUtil.cancelAllNotifications()

    // Resume the timer after break ends
    startTimer()

    // Refresh widgets when break ends
    WidgetCenter.shared.reloadTimelines(ofKind: "ProfileControlWidget")
  }

  private func dismissView() {
    showCustomStrategyView = false
    customStrategyView = nil
  }

  private func getActiveSession(context: ModelContext)
    -> BlockedProfileSession?
  {
    // Before fetching the active session, sync any schedule sessions
    syncScheduleSessions(context: context)

    return
      BlockedProfileSession
      .mostRecentActiveSession(in: context)
  }

  private func syncScheduleSessions(context: ModelContext) {
    // Process any active scheduled sessions
    if let activeScheduledSession = SharedData.getActiveSharedSession() {
      BlockedProfileSession.upsertSessionFromSnapshot(
        in: context,
        withSnapshot: activeScheduledSession
      )
    }

    // Process any completed scheduled sessions
    let completedScheduleSessions = SharedData.getCompletedSessionsForSchedular()
    for completedScheduleSession in completedScheduleSessions {
      BlockedProfileSession.upsertSessionFromSnapshot(
        in: context,
        withSnapshot: completedScheduleSession
      )
    }

    // Flush completed scheduled sessions
    SharedData.flushCompletedSessionsForSchedular()
  }

  private func resultFromURL(_ url: String) -> NFCResult {
    return NFCResult(id: url, url: url, DateScanned: Date())
  }

  private func startBlocking(
    context: ModelContext,
    activeProfile: BlockedProfiles?
  ) {
    guard let definedProfile = activeProfile else {
      print(
        "No active profile found, calling stop blocking with no session"
      )
      return
    }

    if let strategyId = definedProfile.blockingStrategyId {
      let strategy = getStrategy(id: strategyId)
      let view = strategy.startBlocking(
        context: context,
        profile: definedProfile,
        forceStart: false
      )

      if let customView = view {
        showCustomStrategyView = true
        customStrategyView = customView
      }
    }
  }

  private func stopBlocking(context: ModelContext) {
    guard let session = activeSession else {
      print(
        "No active session found, calling stop blocking with no session"
      )
      return
    }

    if let strategyId = session.blockedProfile.blockingStrategyId {
      let strategy = getStrategy(id: strategyId)
      let view = strategy.stopBlocking(context: context, session: session)

      if let customView = view {
        showCustomStrategyView = true
        customStrategyView = customView
      }
    }
  }

  private func scheduleReminder(profile: BlockedProfiles) {
    guard let reminderTimeInSeconds = profile.reminderTimeInSeconds else {
      return
    }

    let profileName = profile.name
    let message = profile.customReminderMessage ?? defaultReminderMessage(forProfile: profile)
    timersUtil
      .scheduleNotification(
        title: profileName + " time!",
        message: message,
        seconds: TimeInterval(reminderTimeInSeconds)
      )
  }

  private func scheduleBreakReminder(profile: BlockedProfiles) {
    let profileName = profile.name
    timersUtil.scheduleNotification(
      title: "How was that break?",
      message: "Get back to  " + profileName + " and start focusing",
      seconds: TimeInterval(15 * 60)
    )
  }

  func cleanUpGhostSchedules(context: ModelContext) {
    let activities = DeviceActivityCenterUtil.getDeviceActivities()
    for activity in activities {
      let profileId = activity.rawValue
      guard let profileId = UUID(uuidString: profileId) else {
        print("failed to parse profile id from activity: \(activity.rawValue)")
        continue
      }

      if let profile = try? BlockedProfiles.findProfile(byID: profileId, in: context) {
        if profile.schedule == nil {
          print(
            "schedule is nil for profile: \(profile.name), schedule is incorrect ❌. Deleting schedule..."
          )
          DeviceActivityCenterUtil.removeScheduleRestrictions(for: profile)
        } else {
          print("schedule is not nil for profile: \(profile.name), schedule is correct ✅")
        }
      } else {
        print(
          "no profile found for activity: \(activity.rawValue), schedule is incorrect ❌. Deleting schedule..."
        )
        DeviceActivityCenterUtil.removeScheduleRestrictions(for: activity)
      }
    }
  }
}
