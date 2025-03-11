//
//  FoqosWidgetLiveActivity.swift
//  FoqosWidget
//
//  Created by Ali Waseem on 2025-03-11.
//

import ActivityKit
import WidgetKit
import SwiftUI

struct FoqosWidgetAttributes: ActivityAttributes {
    public struct ContentState: Codable, Hashable {
        // Dynamic stateful properties about your activity go here!
        var emoji: String
        var elapsedTime: TimeInterval
    }

    // Fixed non-changing properties about your activity go here!
    var name: String
}

struct FoqosWidgetLiveActivity: Widget {
    // Helper function to format elapsed time for display
    private func formatElapsedTime(_ timeInterval: TimeInterval) -> String {
        let hours = Int(timeInterval) / 3600
        let minutes = (Int(timeInterval) % 3600) / 60
        let seconds = Int(timeInterval) % 60
        
        if hours > 0 {
            return String(format: "%d:%02d:%02d", hours, minutes, seconds)
        } else {
            return String(format: "%d:%02d", minutes, seconds)
        }
    }
    
    // Helper function for compact display of elapsed time
    private func formatElapsedTimeShort(_ timeInterval: TimeInterval) -> String {
        let hours = Int(timeInterval) / 3600
        let minutes = (Int(timeInterval) % 3600) / 60
        
        if hours > 0 {
            return String(format: "%dh%02dm", hours, minutes)
        } else {
            return String(format: "%dm", minutes)
        }
    }
    
    var body: some WidgetConfiguration {
        ActivityConfiguration(for: FoqosWidgetAttributes.self) { context in
            // Lock screen/banner UI goes here
            VStack {
                HStack {
                    Text(context.state.emoji)
                        .font(.title)
                    Spacer()
                    Text(context.attributes.name)
                        .font(.headline)
                        .foregroundColor(.primary)
                }
                .padding(.bottom, 4)
                
                HStack {
                    Image(systemName: "timer")
                        .foregroundColor(.secondary)
                    Text(formatElapsedTime(context.state.elapsedTime))
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                    Spacer()
                }
            }
            .padding()
            .activityBackgroundTint(Color.cyan)
            .activitySystemActionForegroundColor(Color.black)

        } dynamicIsland: { context in
            DynamicIsland {
                // Expanded UI goes here.  Compose the expanded UI through
                // various regions, like leading/trailing/center/bottom
                DynamicIslandExpandedRegion(.leading) {
                    HStack {
                        Text(context.state.emoji)
                        Text(context.attributes.name)
                            .font(.headline)
                            .lineLimit(1)
                    }
                }
                DynamicIslandExpandedRegion(.trailing) {
                    Text(formatElapsedTime(context.state.elapsedTime))
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                DynamicIslandExpandedRegion(.bottom) {
                    VStack {
                        Text("Blocking active")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        ProgressView(value: min(context.state.elapsedTime / 3600, 1))
                            .tint(.blue)
                    }
                    .padding(.top, 4)
                }
            } compactLeading: {
                Text(context.state.emoji)
            } compactTrailing: {
                Text(formatElapsedTimeShort(context.state.elapsedTime))
                    .font(.caption2)
                    .foregroundColor(.secondary)
            } minimal: {
                Text(context.state.emoji)
            }
            .widgetURL(URL(string: "http://www.apple.com"))
            .keylineTint(Color.red)
        }
    }
}

extension FoqosWidgetAttributes {
    fileprivate static var preview: FoqosWidgetAttributes {
        FoqosWidgetAttributes(name: "World")
    }
}

extension FoqosWidgetAttributes.ContentState {
    fileprivate static var smiley: FoqosWidgetAttributes.ContentState {
        FoqosWidgetAttributes.ContentState(emoji: "😀", elapsedTime: 60)
     }
     
     fileprivate static var starEyes: FoqosWidgetAttributes.ContentState {
         FoqosWidgetAttributes.ContentState(emoji: "🤩", elapsedTime: 300)
     }
}

#Preview("Notification", as: .content, using: FoqosWidgetAttributes.preview) {
   FoqosWidgetLiveActivity()
} contentStates: {
    FoqosWidgetAttributes.ContentState.smiley
    FoqosWidgetAttributes.ContentState.starEyes
}
