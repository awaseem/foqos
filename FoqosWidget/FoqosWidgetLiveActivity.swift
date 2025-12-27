import ActivityKit
import SwiftUI
import WidgetKit

struct FoqosWidgetAttributes: ActivityAttributes {
  public struct ContentState: Codable, Hashable {
    var startTime: Date
    var isBreakActive: Bool = false
    var breakStartTime: Date?
    var breakEndTime: Date?

    /// Returns the adjusted start time for use with SwiftUI's .timer style
    /// The timer style counts up from this date, so we need to return the effective start time
    /// accounting for any break durations
    var adjustedStartTime: Date {
      // Subtract break duration from the start time to effectively "pause" the timer during breaks
      let breakDuration = calculateBreakDuration()
      return startTime.addingTimeInterval(breakDuration)
    }

    /// Returns the elapsed time since the session started (excluding breaks)
    func getElapsedTime() -> TimeInterval {
      let breakDuration = calculateBreakDuration()
      return Date().timeIntervalSince(startTime) - breakDuration
    }

    /// Legacy method for compatibility - returns time interval for timer display
    /// Note: For SwiftUI .timer style, use adjustedStartTime directly
    func getTimeIntervalSinceNow() -> Double {
      return Date().timeIntervalSince(adjustedStartTime)
    }

    private func calculateBreakDuration() -> TimeInterval {
      guard let breakStart = breakStartTime else {
        return 0
      }

      if let breakEnd = breakEndTime {
        // Break is complete, return the full duration
        return breakEnd.timeIntervalSince(breakStart)
      }

      // Break is currently active, calculate duration so far
      // This pauses the timer during the break
      if isBreakActive {
        return Date().timeIntervalSince(breakStart)
      }

      return 0
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
            // Use adjustedStartTime for accurate elapsed time display
            // The .timer style counts up from the provided date
            Text(context.state.adjustedStartTime, style: .timer)
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
              // Use adjustedStartTime for accurate elapsed time display
              Text(context.state.adjustedStartTime, style: .timer)
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
      .ContentState(
        startTime: Date(timeInterval: 60, since: Date.now),
        isBreakActive: false,
        breakStartTime: nil,
        breakEndTime: nil
      )
  }

  fileprivate static var longTime: FoqosWidgetAttributes.ContentState {
    FoqosWidgetAttributes.ContentState(
      startTime: Date(timeInterval: 60, since: Date.now),
      isBreakActive: false,
      breakStartTime: nil,
      breakEndTime: nil
    )
  }

  fileprivate static var breakActive: FoqosWidgetAttributes.ContentState {
    FoqosWidgetAttributes.ContentState(
      startTime: Date(timeInterval: 60, since: Date.now),
      isBreakActive: true,
      breakStartTime: Date.now,
      breakEndTime: nil
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
