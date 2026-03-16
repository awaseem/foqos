import ActivityKit
import Foundation
import SwiftUI

class LiveActivityManager: ObservableObject {
  private static let timerStrategyIds: Set<String> = [
    "NFCTimerBlockingStrategy",
    "QRTimerBlockingStrategy",
    "ShortcutTimerBlockingStrategy",
  ]

  // Published property for live activity reference
  @Published var currentActivity: Activity<FoqosWidgetAttributes>?

  // Use AppStorage for persisting the activity ID across app launches
  @AppStorage("com.foqos.currentActivityId") private var storedActivityId: String = ""

  static let shared = LiveActivityManager()

  private init() {
    // Try to restore existing activity on initialization
    restoreExistingActivity()
  }

  private var isSupported: Bool {
    if #available(iOS 16.1, *) {
      return ActivityAuthorizationInfo().areActivitiesEnabled
    }
    return false
  }

  // Save activity ID using AppStorage
  private func saveActivityId(_ id: String) {
    storedActivityId = id
  }

  // Remove activity ID from AppStorage
  private func removeActivityId() {
    storedActivityId = ""
  }

  // Restore existing activity from system if available
  private func restoreExistingActivity() {
    guard isSupported else { return }

    // Check if we have a saved activity ID
    if !storedActivityId.isEmpty {
      if let existingActivity = Activity<FoqosWidgetAttributes>.activities.first(where: {
        $0.id == storedActivityId
      }) {
        // Found the existing activity
        self.currentActivity = existingActivity
        print("Restored existing Live Activity with ID: \(existingActivity.id)")
      } else {
        // The activity no longer exists, clean up the stored ID
        print("No existing activity found with saved ID, removing reference")
        removeActivityId()
      }
    }
  }

  func startSessionActivity(session: BlockedProfileSession) {
    // Check if Live Activities are supported
    guard isSupported else {
      print("Live Activities are not supported on this device")
      return
    }

    // Check if we can restore an existing activity first
    if currentActivity == nil {
      restoreExistingActivity()
    }

    // Check if we already have an activity running
    if currentActivity != nil {
      print("Live Activity is already running, will update instead")
      updateSessionActivity(session: session)
      return
    }

    if session.blockedProfile.enableLiveActivity == false {
      print("Activity is disabled for profile")
      return
    }

    // Create and start the activity
    let profileName = session.blockedProfile.name
    let message = FocusMessages.getRandomMessage()
    let attributes = FoqosWidgetAttributes(name: profileName, message: message)
    let contentState = makeContentState(for: session)
    let activityContent = ActivityContent(
      state: contentState,
      staleDate: contentState.expectedEndTime
    )

    do {
      let activity = try Activity.request(
        attributes: attributes,
        content: activityContent,
        pushType: nil
      )
      currentActivity = activity

      saveActivityId(activity.id)
      print("Started Live Activity with ID: \(activity.id) for profile: \(profileName)")
      return
    } catch {
      print("Error starting Live Activity: \(error.localizedDescription)")
      return
    }
  }

  func updateSessionActivity(session: BlockedProfileSession) {
    guard let activity = currentActivity else {
      print("No Live Activity to update")
      return
    }

    let updatedState = makeContentState(for: session)
    let updatedContent = ActivityContent(
      state: updatedState,
      staleDate: updatedState.expectedEndTime
    )

    Task {
      await activity.update(updatedContent)
      print("Updated Live Activity with ID: \(activity.id)")
    }
  }

  func updateBreakState(session: BlockedProfileSession) {
    guard let activity = currentActivity else {
      print("No Live Activity to update for break state")
      return
    }

    let updatedState = makeContentState(for: session)
    let updatedContent = ActivityContent(
      state: updatedState,
      staleDate: updatedState.expectedEndTime
    )

    Task {
      await activity.update(updatedContent)
      print("Updated Live Activity break state: \(session.isBreakActive)")
    }
  }

  func updatePauseState(session: BlockedProfileSession) {
    guard let activity = currentActivity else {
      print("No Live Activity to update for pause state")
      return
    }

    let updatedState = makeContentState(for: session)
    let updatedContent = ActivityContent(
      state: updatedState,
      staleDate: updatedState.expectedEndTime
    )

    Task {
      await activity.update(updatedContent)
      print("Updated Live Activity pause state: \(session.isPauseActive)")
    }
  }

  func endSessionActivity() {
    guard let activity = currentActivity else {
      print("No Live Activity to end")
      return
    }

    // End the activity
    let completedState = FoqosWidgetAttributes.ContentState(
      startTime: Date.now
    )

    Task {
      await activity.end(
        ActivityContent(state: completedState, staleDate: nil),
        dismissalPolicy: .immediate
      )
      print("Ended Live Activity")
    }

    // Remove the stored activity ID when ending the activity
    removeActivityId()
    currentActivity = nil
  }

  private func makeContentState(for session: BlockedProfileSession)
    -> FoqosWidgetAttributes.ContentState
  {
    FoqosWidgetAttributes.ContentState(
      startTime: session.startTime,
      expectedEndTime: expectedEndTime(for: session),
      isBreakActive: session.isBreakActive,
      breakStartTime: session.breakStartTime,
      breakEndTime: session.breakEndTime,
      isPauseActive: session.isPauseActive,
      pauseStartTime: session.pauseStartTime,
      pauseEndTime: session.pauseEndTime
    )
  }

  private func expectedEndTime(for session: BlockedProfileSession) -> Date? {
    if let pauseStartTime = session.pauseStartTime, session.isPauseActive {
      return pauseStartTime.addingTimeInterval(getPauseDurationInSeconds(for: session))
    }

    if let breakStartTime = session.breakStartTime, session.isBreakActive {
      return breakStartTime.addingTimeInterval(
        TimeInterval(session.blockedProfile.breakTimeInMinutes * 60))
    }

    if isScheduledSession(session), let schedule = session.blockedProfile.schedule {
      let durationInSeconds = schedule.totalDurationInSeconds

      guard durationInSeconds > 0 else {
        return nil
      }

      return session.startTime.addingTimeInterval(TimeInterval(durationInSeconds))
    }

    if isTimerSession(session) {
      return session.startTime.addingTimeInterval(getStrategyDurationInSeconds(for: session))
    }

    return nil
  }

  private func isScheduledSession(_ session: BlockedProfileSession) -> Bool {
    session.blockedProfile.schedule?.isActive == true && UUID(uuidString: session.tag) != nil
  }

  private func isTimerSession(_ session: BlockedProfileSession) -> Bool {
    Self.timerStrategyIds.contains(session.tag)
      || Self.timerStrategyIds.contains(session.blockedProfile.blockingStrategyId ?? "")
  }

  private func getStrategyDurationInSeconds(for session: BlockedProfileSession) -> TimeInterval {
    guard let strategyData = session.blockedProfile.strategyData else {
      return 0
    }

    let timerData = StrategyTimerData.toStrategyTimerData(from: strategyData)
    return TimeInterval(timerData.durationInMinutes * 60)
  }

  private func getPauseDurationInSeconds(for session: BlockedProfileSession) -> TimeInterval {
    guard let strategyData = session.blockedProfile.strategyData else {
      return TimeInterval(15 * 60)
    }

    let pauseData = StrategyPauseTimerData.toStrategyPauseTimerData(from: strategyData)
    return TimeInterval(pauseData.pauseDurationInMinutes * 60)
  }
}
