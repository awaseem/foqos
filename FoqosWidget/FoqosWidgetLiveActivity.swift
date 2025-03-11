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
    }

    // Fixed non-changing properties about your activity go here!
    var name: String
}

struct FoqosWidgetLiveActivity: Widget {
    var body: some WidgetConfiguration {
        ActivityConfiguration(for: FoqosWidgetAttributes.self) { context in
            // Lock screen/banner UI goes here
            VStack {
                Text("Hello \(context.state.emoji)")
            }
            .activityBackgroundTint(Color.cyan)
            .activitySystemActionForegroundColor(Color.black)

        } dynamicIsland: { context in
            DynamicIsland {
                // Expanded UI goes here.  Compose the expanded UI through
                // various regions, like leading/trailing/center/bottom
                DynamicIslandExpandedRegion(.leading) {
                    Text("Leading")
                }
                DynamicIslandExpandedRegion(.trailing) {
                    Text("Trailing")
                }
                DynamicIslandExpandedRegion(.bottom) {
                    Text("Bottom \(context.state.emoji)")
                    // more content
                }
            } compactLeading: {
                Text("L")
            } compactTrailing: {
                Text("T \(context.state.emoji)")
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
        FoqosWidgetAttributes.ContentState(emoji: "😀")
     }
     
     fileprivate static var starEyes: FoqosWidgetAttributes.ContentState {
         FoqosWidgetAttributes.ContentState(emoji: "🤩")
     }
}

#Preview("Notification", as: .content, using: FoqosWidgetAttributes.preview) {
   FoqosWidgetLiveActivity()
} contentStates: {
    FoqosWidgetAttributes.ContentState.smiley
    FoqosWidgetAttributes.ContentState.starEyes
}
