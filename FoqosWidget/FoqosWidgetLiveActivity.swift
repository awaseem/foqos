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
  private let compactLogoSize: CGFloat = 24
  private let compactTimerWidth: CGFloat = 48
  private let compactTimerFontSize: CGFloat = 16
  private let minimalLogoSize: CGFloat = 18

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
        DynamicIslandExpandedRegion(.leading) {
          HStack(spacing: 8) {
            foqosLogo(size: 36)
            VStack(alignment: .leading, spacing: 2) {
              Text("Foqos")
                .font(.headline)
                .fontWeight(.bold)
              Text(context.attributes.name)
                .font(.caption)
                .foregroundColor(.secondary)
                .lineLimit(1)
            }
          }
          .padding(.leading, 4)
        }

        DynamicIslandExpandedRegion(.trailing) {
          expandedIslandStatusView(for: context.state)
            .padding(.trailing, 4)
        }
      } compactLeading: {
        foqosLogo(size: compactLogoSize)
          .frame(width: compactLogoSize, height: compactLogoSize)
      } compactTrailing: {
        compactIslandStatusView(for: context.state)
      } minimal: {
        foqosLogo(size: minimalLogoSize)
          .frame(width: minimalLogoSize, height: minimalLogoSize)
      }
      .widgetURL(URL(string: "http://www.foqos.app"))
      .keylineTint(Color.purple)
    }
  }

  private func foqosLogo(size: CGFloat) -> some View {
    Image("FoqosStickerLogo")
      .resizable()
      .scaledToFit()
      .frame(width: size, height: size)
  }

  @ViewBuilder
  private func expandedIslandStatusView(
    for state: FoqosWidgetAttributes.ContentState
  ) -> some View {
    if state.isPauseActive {
      compactStatusView(
        systemImage: "pause.fill",
        color: .yellow,
        font: .title2
      )
    } else if state.isBreakActive {
      compactStatusView(
        systemImage: "cup.and.heat.waves.fill",
        color: .orange,
        font: .title2
      )
    } else {
      elapsedTimerText(for: state, font: .title2)
    }
  }

  @ViewBuilder
  private func compactIslandStatusView(
    for state: FoqosWidgetAttributes.ContentState
  ) -> some View {
    if state.isPauseActive {
      compactStatusView(
        systemImage: "pause.fill",
        color: .yellow,
        font: .system(size: compactTimerFontSize, weight: .semibold)
      )
      .frame(width: compactTimerWidth, alignment: .center)
    } else if state.isBreakActive {
      compactStatusView(
        systemImage: "cup.and.heat.waves.fill",
        color: .orange,
        font: .system(size: compactTimerFontSize, weight: .semibold)
      )
      .frame(width: compactTimerWidth, alignment: .center)
    } else {
      compactElapsedTimerText(for: state)
    }
  }

  private func compactStatusView(
    systemImage: String,
    color: Color,
    font: Font
  ) -> some View {
    Image(systemName: systemImage)
      .font(font)
      .fontWeight(.semibold)
      .foregroundColor(color)
  }

  private func elapsedTimerText(
    for state: FoqosWidgetAttributes.ContentState,
    font: Font
  ) -> some View {
    Text(
      Date(timeIntervalSinceNow: state.getTimeIntervalSinceNow()),
      style: .timer
    )
    .font(font)
    .fontWeight(.semibold)
    .monospacedDigit()
    .foregroundColor(.purple)
    .contentTransition(.numericText())
  }

  private func compactElapsedTimerText(for state: FoqosWidgetAttributes.ContentState) -> some View {
    Text(
      Date(timeIntervalSinceNow: state.getTimeIntervalSinceNow()),
      style: .timer
    )
    .font(.system(size: compactTimerFontSize, weight: .semibold, design: .rounded))
    .monospacedDigit()
    .lineLimit(1)
    .minimumScaleFactor(0.68)
    .allowsTightening(true)
    .foregroundColor(.purple)
    .frame(width: compactTimerWidth, alignment: .center)
    .contentTransition(.numericText())
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
