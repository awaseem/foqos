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
        var elapsedTime: TimeInterval
    }

    // Fixed non-changing properties about your activity go here!
    var name: String
    var message: String
}

struct FoqosWidgetLiveActivity: Widget {
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
            HStack(alignment: .center) {
                // Left side - App info
                VStack(alignment: .leading, spacing: 10) {
                    HStack(spacing: 4) {
                        Text("Foqos")
                            .font(.headline)
                            .fontWeight(.bold)
                            .foregroundColor(.primary)
                        Image(systemName: "hourglass")
                            .foregroundColor(.purple)
                    }
                    
                    Text(context.attributes.name)
                        .font(.subheadline)
                        .foregroundColor(.primary)
                        
                    Text(context.attributes.message)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                // Right side - Timer
                Text(formatElapsedTime(context.state.elapsedTime))
                    .font(.title)
                    .fontWeight(.semibold)
                    .foregroundColor(.secondary)
            }
            .padding()

        } dynamicIsland: { context in
            DynamicIsland {
                // Expanded state
                DynamicIslandExpandedRegion(.leading) {
                    VStack(alignment: .leading, spacing: 4) {
                        HStack(spacing: 4) {
                            Text("Foqos")
                                .font(.headline)
                                .fontWeight(.bold)
                            Image(systemName: "hourglass")
                                .foregroundColor(.purple)
                        }
                    }
                    .padding(.leading)
                }
                
                DynamicIslandExpandedRegion(.center) {
                    VStack(spacing: 8) {
                        Text(context.attributes.name)
                            .font(.subheadline)
                        
                        Text(context.attributes.message)
                            .font(.caption2)
                            .foregroundColor(.secondary)
                    }
                    .padding()
                }
                
                DynamicIslandExpandedRegion(.trailing) {
                    Text(formatElapsedTime(context.state.elapsedTime))
                        .font(.title2)
                        .fontWeight(.semibold)
                        .foregroundColor(.secondary)
                        .padding(.trailing)
                }
            } compactLeading: {
                // Compact leading state
                HStack(spacing: 2) {
                    Image(systemName: "hourglass")
                        .font(.caption2)
                        .foregroundColor(.purple)
                }
            } compactTrailing: {
                // Compact trailing state
                Text(formatElapsedTimeShort(context.state.elapsedTime))
                    .font(.caption)
                    .fontWeight(.semibold)
                    .foregroundColor(.secondary)
            } minimal: {
                // Minimal state
                Image(systemName: "hourglass")
                    .font(.caption2)
                    .foregroundColor(.purple)
            }
            .widgetURL(URL(string: "http://www.foqos.app"))
            .keylineTint(Color.purple)
        }
    }
}

extension FoqosWidgetAttributes {
    fileprivate static var preview: FoqosWidgetAttributes {
        FoqosWidgetAttributes(name: "Focus Session", message: "Stay focused and avoid distractions")
    }
}

extension FoqosWidgetAttributes.ContentState {
    fileprivate static var shortTime: FoqosWidgetAttributes.ContentState {
        FoqosWidgetAttributes.ContentState(elapsedTime: 60)
     }
     
     fileprivate static var longTime: FoqosWidgetAttributes.ContentState {
         FoqosWidgetAttributes.ContentState(elapsedTime: 300)
     }
}

#Preview("Notification", as: .content, using: FoqosWidgetAttributes.preview) {
   FoqosWidgetLiveActivity()
} contentStates: {
    FoqosWidgetAttributes.ContentState.shortTime
    FoqosWidgetAttributes.ContentState.longTime
}
