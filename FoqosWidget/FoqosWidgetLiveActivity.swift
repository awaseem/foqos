//
//  FoqosWidgetLiveActivity.swift
//  FoqosWidget
//
//  Created by Ali Waseem on 2025-03-11.
//

import ActivityKit
import SwiftUI
import WidgetKit

struct FoqosWidgetAttributes: ActivityAttributes {
    public struct ContentState: Codable, Hashable {
        var startTime: Date

        func getTimeIntervalSinceNow() -> Double {
            return startTime.timeIntervalSince1970
                - Date().timeIntervalSince1970
        }
    }

    // Fixed non-changing properties about your activity go here!
    var name: String
    var message: String
}

struct FoqosWidgetLiveActivity: Widget {
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
                
                
                    Text(
                        Date(
                            timeIntervalSinceNow: context.state
                                .getTimeIntervalSinceNow()
                        ),
                        style: .timer
                    )
                    .font(.title)
                    .fontWeight(.semibold)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.trailing)
                

            }
            .padding()

        } dynamicIsland: { context in
            DynamicIsland {
                DynamicIslandExpandedRegion(.center) {
                    VStack(spacing: 8) {
                        Image(systemName: "hourglass")
                            .foregroundColor(.purple)

                        Text(context.attributes.name)
                            .font(.headline)
                            .fontWeight(.medium)

                        Text(context.attributes.message)
                            .font(.headline)
                            .foregroundColor(.secondary)

                        Text(
                            Date(
                                timeIntervalSinceNow: context.state
                                    .getTimeIntervalSinceNow()
                            ),
                            style: .timer
                        )
                        .font(.title2)
                        .fontWeight(.semibold)
                        .multilineTextAlignment(.center)
                    }
                }
            } compactLeading: {
                // Compact leading state
                Image(systemName: "hourglass")
                    .foregroundColor(.purple)
            } compactTrailing: {
                // Compact trailing state
                Text(
                    context.attributes.name
                )
                .font(.caption)
                .fontWeight(.semibold)
            } minimal: {
                // Minimal state
                Image(systemName: "hourglass")
                    .foregroundColor(.purple)
            }
            .widgetURL(URL(string: "http://www.foqos.app"))
            .keylineTint(Color.purple)
        }
    }
}

extension FoqosWidgetAttributes {
    fileprivate static var preview: FoqosWidgetAttributes {
        FoqosWidgetAttributes(
            name: "Focus Session",
            message: "Stay focused and avoid distractions")
    }
}

extension FoqosWidgetAttributes.ContentState {
    fileprivate static var shortTime: FoqosWidgetAttributes.ContentState {
        FoqosWidgetAttributes
            .ContentState(startTime: Date(timeInterval: 60, since: Date.now))
    }

    fileprivate static var longTime: FoqosWidgetAttributes.ContentState {
        FoqosWidgetAttributes.ContentState(startTime: Date(timeInterval: 60, since: Date.now))
    }
}

#Preview("Notification", as: .content, using: FoqosWidgetAttributes.preview) {
    FoqosWidgetLiveActivity()
} contentStates: {
    FoqosWidgetAttributes.ContentState.shortTime
    FoqosWidgetAttributes.ContentState.longTime
}
