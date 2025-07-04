import ActivityKit
import Foundation
import SwiftUI

class LiveActivityManager: ObservableObject {
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
    let contentState = FoqosWidgetAttributes.ContentState(
      startTime: session.startTime,
      isBreakActive: session.isBreakActive
    )

    do {
      let activity = try Activity.request(
        attributes: attributes,
        contentState: contentState
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

    let updatedState = FoqosWidgetAttributes.ContentState(
      startTime: session.startTime,
      isBreakActive: session.isBreakActive
    )

    Task {
      await activity.update(using: updatedState)
      print("Updated Live Activity with ID: \(activity.id)")
    }
  }

  func updateBreakState(session: BlockedProfileSession) {
    guard let activity = currentActivity else {
      print("No Live Activity to update for break state")
      return
    }

    let updatedState = FoqosWidgetAttributes.ContentState(
      startTime: session.startTime,
      isBreakActive: session.isBreakActive
    )

    Task {
      await activity.update(using: updatedState)
      print("Updated Live Activity break state: \(session.isBreakActive)")
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
      await activity.end(using: completedState, dismissalPolicy: .immediate)
      print("Ended Live Activity")
    }

    // Remove the stored activity ID when ending the activity
    removeActivityId()
    currentActivity = nil
  }
}
