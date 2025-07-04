import ActivityKit
import SwiftUI
import WidgetKit

struct FoqosWidgetAttributes: ActivityAttributes {
  public struct ContentState: Codable, Hashable {
    var startTime: Date
    var isBreakActive: Bool = false

    func getTimeIntervalSinceNow() -> Double {
      return startTime.timeIntervalSince1970
        - Date().timeIntervalSince1970
    }
  }

  var name: String
  var message: String
}

struct FoqosWidgetLiveActivity: Widget {
  var body: some WidgetConfiguration {
    ActivityConfiguration(for: FoqosWidgetAttributes.self) { context in
      // Lock screen/banner UI goes here
      HStack(alignment: .center, spacing: 16) {
        // Left side - App info
        VStack(alignment: .leading, spacing: 8) {
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

        // Right side - Timer or break indicator
        VStack(alignment: .trailing, spacing: 4) {
          if context.state.isBreakActive {
            HStack(spacing: 6) {
              Image(systemName: "cup.and.heat.waves.fill")
                .font(.title2)
                .foregroundColor(.orange)
              Text("On a Break")
                .font(.subheadline)
                .fontWeight(.semibold)
                .foregroundColor(.orange)
            }
          } else {
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
        }
      }
      .padding(.horizontal, 16)
      .padding(.vertical, 12)

    } dynamicIsland: { context in
      DynamicIsland {
        DynamicIslandExpandedRegion(.center) {
          VStack(spacing: 8) {
            HStack(spacing: 6) {
              Image(systemName: "hourglass")
                .foregroundColor(.purple)
              Text(context.attributes.name)
                .font(.headline)
                .fontWeight(.medium)
            }

            Text(context.attributes.message)
              .font(.subheadline)
              .foregroundColor(.secondary)
              .multilineTextAlignment(.center)

            if context.state.isBreakActive {
              VStack(spacing: 2) {
                Image(systemName: "cup.and.heat.waves.fill")
                  .font(.title2)
                  .foregroundColor(.orange)
                Text("On a Break")
                  .font(.subheadline)
                  .fontWeight(.semibold)
                  .foregroundColor(.orange)
              }
            } else {
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
          .padding(.horizontal, 16)
          .padding(.vertical, 4)
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

  fileprivate static var breakActive: FoqosWidgetAttributes.ContentState {
    FoqosWidgetAttributes.ContentState(
      startTime: Date(timeInterval: 60, since: Date.now),
      isBreakActive: true
    )
  }
}

#Preview("Notification", as: .content, using: FoqosWidgetAttributes.preview) {
  FoqosWidgetLiveActivity()
} contentStates: {
  FoqosWidgetAttributes.ContentState.shortTime
  FoqosWidgetAttributes.ContentState.longTime
  FoqosWidgetAttributes.ContentState.breakActive
}
