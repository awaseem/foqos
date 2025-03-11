import Foundation
import ActivityKit
import SwiftUI

class LiveActivityManager: ObservableObject {
    @Published var currentActivity: Activity<FoqosWidgetAttributes>?
    
    static let shared = LiveActivityManager()
    
    private init() {}
    
    private var isSupported: Bool {
        if #available(iOS 16.1, *) {
            return ActivityAuthorizationInfo().areActivitiesEnabled
        }
        return false
    }
    
    func startSessionActivity(session: BlockedProfileSession) -> Bool {
        // Check if Live Activities are supported
        guard isSupported else {
            print("Live Activities are not supported on this device")
            return false
        }
        
        // Check if we already have an activity running
        if currentActivity != nil {
            print("Live Activity is already running")
            return false
        }
        
        // Create and start the activity
        let profileName = session.blockedProfile.name
        let attributes = FoqosWidgetAttributes(name: profileName)
        let contentState = FoqosWidgetAttributes.ContentState(elapsedTime: 0)
        
        do {
            let activity = try Activity.request(
                attributes: attributes,
                contentState: contentState
            )
            currentActivity = activity
            print("Started Live Activity with ID: \(activity.id) for profile: \(profileName)")
            return true
        } catch {
            print("Error starting Live Activity: \(error.localizedDescription)")
            return false
        }
    }
    
    func updateSessionActivity(elapsedTime: TimeInterval) -> Bool {
        guard let activity = currentActivity else {
            print("No Live Activity to update")
            return false
        }
        
        // Update with elapsed time
        let updatedContentState = FoqosWidgetAttributes.ContentState(elapsedTime: elapsedTime)
        
        Task {
            await activity.update(using: updatedContentState)
        }
        
        return true
    }
    
    func endSessionActivity() -> Bool {
        guard let activity = currentActivity else {
            print("No Live Activity to end")
            return false
        }
        
        // End the activity
        let completedState = FoqosWidgetAttributes.ContentState(elapsedTime: 0)
        
        Task {
            await activity
                .end(using: completedState, dismissalPolicy: .immediate)
            print("Ended Live Activity")
        }
        
        currentActivity = nil
        return true
    }
}
