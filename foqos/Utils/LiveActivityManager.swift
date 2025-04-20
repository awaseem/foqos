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
    
    func startSessionActivity(session: BlockedProfileSession) -> Void {
        // Check if Live Activities are supported
        guard isSupported else {
            print("Live Activities are not supported on this device")
            return
        }
        
        // Check if we already have an activity running
        if currentActivity != nil {
            print("Live Activity is already running")
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
            startTime: session
                .startTime)
        
        do {
            let activity = try Activity.request(
                attributes: attributes,
                contentState: contentState
            )
            currentActivity = activity
            print("Started Live Activity with ID: \(activity.id) for profile: \(profileName)")
            return
        } catch {
            print("Error starting Live Activity: \(error.localizedDescription)")
            return
        }
    }
    
    
    func endSessionActivity() -> Void {
        guard let activity = currentActivity else {
            print("No Live Activity to end")
            return
        }
        
        // End the activity
        let completedState = FoqosWidgetAttributes.ContentState(
            startTime: Date.now
        )
        
        Task {
            await activity
                .end(using: completedState, dismissalPolicy: .immediate)
            print("Ended Live Activity")
        }
        
        currentActivity = nil
    }
}
