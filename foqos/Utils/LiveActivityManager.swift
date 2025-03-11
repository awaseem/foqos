//
//  LiveActivityManager.swift
//  foqos
//
//  Created by Ali Waseem on 2025-03-11.
//

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
    
    /// Starts a new Live Activity for a blocking session
    /// - Parameter session: The active blocking session
    /// - Returns: Boolean indicating if the activity was started successfully
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
        let contentState = FoqosWidgetAttributes.ContentState(emoji: "🔒", elapsedTime: 0)
        
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
    
    /// Updates the current Live Activity with the elapsed time
    /// - Parameter elapsedTime: The elapsed time of the blocking session
    /// - Returns: Boolean indicating if the update was successful
    func updateSessionActivity(elapsedTime: TimeInterval) -> Bool {
        guard let activity = currentActivity else {
            print("No Live Activity to update")
            return false
        }
        
        // You could use different emojis based on elapsed time
        let emoji = getEmojiForElapsedTime(elapsedTime)
        let updatedContentState = FoqosWidgetAttributes.ContentState(emoji: emoji, elapsedTime: elapsedTime)
        
        Task {
            await activity.update(using: updatedContentState)
        }
        
        return true
    }
    
    /// Ends the current Live Activity
    /// - Returns: Boolean indicating if the activity was ended successfully
    func endSessionActivity() -> Bool {
        guard let activity = currentActivity else {
            print("No Live Activity to end")
            return false
        }
        
        // Use a "completed" emoji
        let completedState = FoqosWidgetAttributes.ContentState(emoji: "✅", elapsedTime: 0)
        
        Task {
            await activity
                .end(using: completedState, dismissalPolicy: .immediate)
            print("Ended Live Activity")
        }
        
        currentActivity = nil
        return true
    }
    
    /// Helper method to get an emoji based on elapsed time
    private func getEmojiForElapsedTime(_ elapsedTime: TimeInterval) -> String {
        // Different emojis based on how long the session has been active
        let minutes = Int(elapsedTime / 60)
        
        switch minutes {
        case 0...5:
            return "🔒"
        case 6...15:
            return "🕒"
        case 16...30:
            return "⏱️"
        case 31...60:
            return "🏆"
        default:
            return "🌟"
        }
    }
}
