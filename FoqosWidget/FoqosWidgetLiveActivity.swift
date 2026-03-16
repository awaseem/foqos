import ActivityKit
import SwiftUI
import WidgetKit

struct FoqosWidgetAttributes: ActivityAttributes {
  public struct ContentState: Codable, Hashable {
    var startTime: Date
    var expectedEndTime: Date?
    var isBreakActive: Bool = false
    var breakStartTime: Date?
    var breakEndTime: Date?
    var isPauseActive: Bool = false
    var pauseStartTime: Date?
    var pauseEndTime: Date?

    func getTimeIntervalSinceNow() -> Double {
      // Calculate the break duration to subtract from elapsed time
      let breakDuration = calculateBreakDuration()

      // Calculate elapsed time minus break duration
      let adjustedStartTime = startTime.addingTimeInterval(breakDuration)

      return adjustedStartTime.timeIntervalSince1970
        - Date().timeIntervalSince1970
    }

    private func calculateBreakDuration() -> TimeInterval {
      guard let breakStart = breakStartTime else {
        return 0
      }

      if let breakEnd = breakEndTime {
        // Break is complete, return the full duration
        return breakEnd.timeIntervalSince(breakStart)
      }

      // Break is not yet ended, don't count it
      return 0
    }

    var countdownRange: ClosedRange<Date>? {
      guard let expectedEndTime else {
        return nil
      }

      let now = Date.now
      let displayEndTime = max(now, expectedEndTime)
      return now...displayEndTime
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

        // Right side - Timer or break/pause indicator
        VStack(alignment: .trailing, spacing: 4) {
          if context.state.isPauseActive {
            statusView(
              label: "Paused",
              systemImage: "pause.circle.fill",
              color: .yellow,
              countdownRange: context.state.countdownRange,
              timerFont: .title,
              alignment: .trailing
            )
          } else if context.state.isBreakActive {
            statusView(
              label: "On a Break",
              systemImage: "cup.and.heat.waves.fill",
              color: .orange,
              countdownRange: context.state.countdownRange,
              timerFont: .title,
              alignment: .trailing
            )
          } else {
            timerText(for: context.state, font: .title, alignment: .trailing)
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

            if context.state.isPauseActive {
              statusView(
                label: "Paused",
                systemImage: "pause.circle.fill",
                color: .yellow,
                countdownRange: context.state.countdownRange,
                timerFont: .title2,
                alignment: .center
              )
            } else if context.state.isBreakActive {
              statusView(
                label: "On a Break",
                systemImage: "cup.and.heat.waves.fill",
                color: .orange,
                countdownRange: context.state.countdownRange,
                timerFont: .title2,
                alignment: .center
              )
            } else {
              timerText(for: context.state, font: .title2, alignment: .center)
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

  @ViewBuilder
  private func timerText(
    for state: FoqosWidgetAttributes.ContentState,
    font: Font,
    alignment: TextAlignment
  ) -> some View {
    if let countdownRange = state.countdownRange {
      Text(timerInterval: countdownRange, countsDown: true)
        .font(font)
        .fontWeight(.semibold)
        .foregroundColor(.primary)
        .multilineTextAlignment(alignment)
    } else {
      Text(
        Date(timeIntervalSinceNow: state.getTimeIntervalSinceNow()),
        style: .timer
      )
      .font(font)
      .fontWeight(.semibold)
      .foregroundColor(.primary)
      .multilineTextAlignment(alignment)
    }
  }

  @ViewBuilder
  private func statusView(
    label: String,
    systemImage: String,
    color: Color,
    countdownRange: ClosedRange<Date>?,
    timerFont: Font,
    alignment: TextAlignment
  ) -> some View {
    VStack(alignment: alignment == .trailing ? .trailing : .center, spacing: 4) {
      HStack(spacing: 6) {
        Image(systemName: systemImage)
          .font(.title2)
          .foregroundColor(color)
        Text(label)
          .font(.subheadline)
          .fontWeight(.semibold)
          .foregroundColor(color)
      }

      if let countdownRange {
        Text(timerInterval: countdownRange, countsDown: true)
          .font(timerFont)
          .fontWeight(.semibold)
          .foregroundColor(.primary)
          .multilineTextAlignment(alignment)
      }
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
        expectedEndTime: Date(timeIntervalSinceNow: 25 * 60),
        isBreakActive: false,
        breakStartTime: nil,
        breakEndTime: nil,
        isPauseActive: false,
        pauseStartTime: nil,
        pauseEndTime: nil
      )
  }

  fileprivate static var longTime: FoqosWidgetAttributes.ContentState {
    FoqosWidgetAttributes.ContentState(
      startTime: Date(timeInterval: 60, since: Date.now),
      expectedEndTime: Date(timeIntervalSinceNow: 2 * 60 * 60),
      isBreakActive: false,
      breakStartTime: nil,
      breakEndTime: nil,
      isPauseActive: false,
      pauseStartTime: nil,
      pauseEndTime: nil
    )
  }

  fileprivate static var breakActive: FoqosWidgetAttributes.ContentState {
    FoqosWidgetAttributes.ContentState(
      startTime: Date(timeInterval: 60, since: Date.now),
      expectedEndTime: Date(timeIntervalSinceNow: 5 * 60),
      isBreakActive: true,
      breakStartTime: Date.now,
      breakEndTime: nil,
      isPauseActive: false,
      pauseStartTime: nil,
      pauseEndTime: nil
    )
  }

  fileprivate static var pauseActive: FoqosWidgetAttributes.ContentState {
    FoqosWidgetAttributes.ContentState(
      startTime: Date(timeInterval: 60, since: Date.now),
      expectedEndTime: Date(timeIntervalSinceNow: 10 * 60),
      isBreakActive: false,
      breakStartTime: nil,
      breakEndTime: nil,
      isPauseActive: true,
      pauseStartTime: Date.now,
      pauseEndTime: nil
    )
  }
}

#Preview("Notification", as: .content, using: FoqosWidgetAttributes.preview) {
  FoqosWidgetLiveActivity()
} contentStates: {
  FoqosWidgetAttributes.ContentState.shortTime
  FoqosWidgetAttributes.ContentState.longTime
  FoqosWidgetAttributes.ContentState.breakActive
  FoqosWidgetAttributes.ContentState.pauseActive
}
