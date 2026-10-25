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
    var usedBreakDurationInSeconds: TimeInterval = 0
    var isPauseActive: Bool = false
    var pauseStartTime: Date?
    var pauseEndTime: Date?

    // Optional so activities started before appearance customization still decode.
    var themeColorName: String?
    var appIconName: String?

    var themeColor: Color {
      ThemeManager.color(named: themeColorName)
    }

    var appIcon: AppIconOption {
      AppIconOption.allCases.first { $0.alternateIconName == appIconName } ?? .defaultIcon
    }

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
        return usedBreakDurationInSeconds
      }

      if let breakEnd = breakEndTime {
        return usedBreakDurationInSeconds + breakEnd.timeIntervalSince(breakStart)
      }

      return usedBreakDurationInSeconds
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

@available(iOS 18.0, *)
struct FoqosWidgetLiveActivity: Widget {
  private let compactLogoSize: CGFloat = 24
  private let compactTimerWidth: CGFloat = 48
  private let compactTimerFontSize: CGFloat = 16
  private let expandedLogoSize: CGFloat = 30
  private let expandedTimerWidth: CGFloat = 76
  private let expandedTimerFontSize: CGFloat = 24
  private let minimalLogoSize: CGFloat = 18

  var body: some WidgetConfiguration {
    ActivityConfiguration(for: FoqosWidgetAttributes.self) { context in
      FoqosLiveActivityContentView(attributes: context.attributes, state: context.state)

    } dynamicIsland: { context in
      DynamicIsland {
        DynamicIslandExpandedRegion(.leading) {
          expandedIslandTitle(name: context.attributes.name, state: context.state)
        }

        DynamicIslandExpandedRegion(.trailing) {
          expandedIslandStatusView(for: context.state)
        }
      } compactLeading: {
        activityIcon(for: context.state, size: compactLogoSize)
      } compactTrailing: {
        #if compiler(>=6.4)
          if #available(iOS 27.0, *) {
            WidthAwareCompactIslandContent { isWidthLimited in
              compactIslandStatusView(for: context.state, isWidthLimited: isWidthLimited)
            }
          } else {
            compactIslandStatusView(for: context.state)
          }
        #else
          compactIslandStatusView(for: context.state)
        #endif
      } minimal: {
        activityIcon(for: context.state, size: minimalLogoSize)
      }
      .widgetURL(URL(string: "http://www.foqos.app"))
      .keylineTint(context.state.themeColor)
    }
    .supplementalActivityFamilies([.medium])
  }

  private func activityIcon(for state: FoqosWidgetAttributes.ContentState, size: CGFloat)
    -> some View
  {
    Image(state.appIcon.liveActivityAssetName)
      .resizable()
      .scaledToFit()
      .frame(width: size, height: size)
      .accessibilityLabel("Foqos")
  }

  private func expandedIslandTitle(name: String, state: FoqosWidgetAttributes.ContentState)
    -> some View
  {
    HStack(alignment: .center, spacing: 8) {
      activityIcon(for: state, size: expandedLogoSize)

      VStack(alignment: .leading, spacing: 1) {
        Text("Foqos")
          .font(.system(size: 18, weight: .bold, design: .rounded))
          .foregroundColor(.primary)
          .lineLimit(1)

        Text(name)
          .font(.system(size: 14, weight: .medium, design: .rounded))
          .foregroundColor(.secondary)
          .lineLimit(1)
      }
    }
  }

  @ViewBuilder
  private func expandedIslandStatusView(
    for state: FoqosWidgetAttributes.ContentState
  ) -> some View {
    if state.isPauseActive {
      stickerStatusView(assetName: "PauseStickerIcon", size: 30)
        .frame(width: expandedTimerWidth, alignment: .center)
    } else if state.isBreakActive {
      stickerStatusView(assetName: "CoffeeStickerIcon", size: 30)
        .frame(width: expandedTimerWidth, alignment: .center)
    } else {
      expandedElapsedTimerText(for: state)
    }
  }

  @ViewBuilder
  private func compactIslandStatusView(
    for state: FoqosWidgetAttributes.ContentState,
    isWidthLimited: Bool = false
  ) -> some View {
    if state.isPauseActive {
      stickerStatusView(assetName: "PauseStickerIcon", size: 20)
        .frame(width: isWidthLimited ? 20 : compactTimerWidth, alignment: .center)
        .accessibilityLabel("Paused")
    } else if state.isBreakActive {
      stickerStatusView(assetName: "CoffeeStickerIcon", size: 20)
        .frame(width: isWidthLimited ? 20 : compactTimerWidth, alignment: .center)
        .accessibilityLabel("On a break")
    } else if isWidthLimited {
      Image(systemName: "timer")
        .font(.system(size: 18, weight: .semibold))
        .foregroundStyle(state.themeColor)
        .frame(width: 20, height: 20)
        .accessibilityLabel("Focus session active")
        .accessibilityValue(
          Text(Date(timeIntervalSinceNow: state.getTimeIntervalSinceNow()), style: .timer)
        )
    } else {
      compactElapsedTimerText(for: state)
    }
  }

  private func stickerStatusView(assetName: String, size: CGFloat) -> some View {
    Image(assetName)
      .resizable()
      .scaledToFit()
      .frame(width: size, height: size)
  }

  private func expandedElapsedTimerText(
    for state: FoqosWidgetAttributes.ContentState
  ) -> some View {
    Text(
      Date(timeIntervalSinceNow: state.getTimeIntervalSinceNow()),
      style: .timer
    )
    .font(.system(size: expandedTimerFontSize, weight: .semibold, design: .rounded))
    .monospacedDigit()
    .lineLimit(1)
    .minimumScaleFactor(0.76)
    .allowsTightening(true)
    .foregroundColor(state.themeColor)
    .frame(width: expandedTimerWidth, alignment: .center)
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
    .foregroundColor(state.themeColor)
    .frame(width: compactTimerWidth, alignment: .center)
    .contentTransition(.numericText())
  }
}

private struct FoqosLiveActivityContentView: View {
  @Environment(\.isActivityFullscreen) private var isFullscreen

  let attributes: FoqosWidgetAttributes
  let state: FoqosWidgetAttributes.ContentState

  var body: some View {
    Group {
      if isFullscreen {
        FoqosStandByActivityView(
          profileName: attributes.name, message: attributes.message, state: state
        )
      } else {
        lockScreenContent
      }
    }
    .activityBackgroundTint(isFullscreen ? .black : nil)
  }

  private var lockScreenContent: some View {
    HStack(alignment: .center, spacing: 16) {
      VStack(alignment: .leading, spacing: 8) {
        HStack(spacing: 4) {
          Text("Foqos")
            .font(.headline)
            .fontWeight(.bold)
            .foregroundColor(.primary)
          Image(state.appIcon.liveActivityAssetName)
            .resizable()
            .scaledToFit()
            .frame(width: 20, height: 20)
            .accessibilityHidden(true)
        }

        Text(attributes.name)
          .font(.subheadline)
          .foregroundColor(.primary)

        Text(attributes.message)
          .font(.caption)
          .foregroundColor(.secondary)
      }

      Spacer()

      VStack(alignment: .trailing, spacing: 4) {
        if state.isPauseActive {
          statusView(
            label: "Paused",
            assetName: "PauseStickerIcon",
            countdownRange: state.countdownRange,
            tint: state.themeColor,
            timerFont: .title,
            alignment: .trailing
          )
        } else if state.isBreakActive {
          statusView(
            label: "On a Break",
            assetName: "CoffeeStickerIcon",
            countdownRange: state.countdownRange,
            tint: state.themeColor,
            timerFont: .title,
            alignment: .trailing
          )
        } else {
          timerText(for: state, font: .title, alignment: .trailing)
        }
      }
    }
    .padding(.horizontal, 16)
    .padding(.vertical, 12)
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
        .foregroundColor(state.themeColor)
        .multilineTextAlignment(alignment)
    } else {
      Text(
        Date(timeIntervalSinceNow: state.getTimeIntervalSinceNow()),
        style: .timer
      )
      .font(font)
      .fontWeight(.semibold)
      .foregroundColor(state.themeColor)
      .multilineTextAlignment(alignment)
    }
  }

  @ViewBuilder
  private func statusView(
    label: String,
    assetName: String,
    countdownRange: ClosedRange<Date>?,
    tint: Color,
    timerFont: Font,
    alignment: TextAlignment
  ) -> some View {
    VStack(alignment: alignment == .trailing ? .trailing : .center, spacing: 4) {
      HStack(spacing: 6) {
        Image(assetName)
          .resizable()
          .scaledToFit()
          .frame(width: 28, height: 28)
        Text(label)
          .font(.subheadline)
          .fontWeight(.semibold)
          .foregroundColor(.primary)
      }

      if let countdownRange {
        Text(timerInterval: countdownRange, countsDown: true)
          .font(timerFont)
          .fontWeight(.semibold)
          .foregroundColor(tint)
          .multilineTextAlignment(alignment)
      }
    }
  }
}

private struct FoqosStandByActivityView: View {
  let profileName: String
  let message: String
  let state: FoqosWidgetAttributes.ContentState

  var body: some View {
    VStack(spacing: 0) {
      timerPresentation

      VStack(spacing: 3) {
        Text(profileName)
          .font(.system(size: 15, weight: .bold))
          .lineLimit(1)
          .minimumScaleFactor(0.75)

        Text(message)
          .font(.system(size: 11))
          .foregroundStyle(.white.opacity(0.65))
          .lineLimit(1)
      }
    }
    .foregroundStyle(.white)
    .padding(.horizontal, 20)
    .padding(.vertical, 2)
    .frame(maxWidth: .infinity)
  }

  private var timerPresentation: some View {
    ZStack {
      // Use the active screen's resting artwork; Live Activities don't run its breathing timer.
      ActiveSessionPetalView(color: state.themeColor, settings: .defaultValue)
        .frame(width: 360, height: 300)
        .scaleEffect(0.4)
        .frame(width: 144, height: 120)

      VStack(spacing: 4) {
        timer
          .font(.system(size: 48, weight: .bold, design: .monospaced))
          .monospacedDigit()
          .lineLimit(1)
          .minimumScaleFactor(0.5)
          .multilineTextAlignment(.center)
          .frame(maxWidth: .infinity)

        timerDetail
          .font(.system(size: 11, weight: .medium))
          .foregroundStyle(.white.opacity(0.65))
      }
    }
    .frame(height: 120)
  }

  @ViewBuilder
  private var timer: some View {
    if let countdownRange = state.countdownRange {
      Text(timerInterval: countdownRange, countsDown: true)
    } else if state.isPauseActive || state.isBreakActive {
      Image(systemName: state.isPauseActive ? "pause.fill" : "cup.and.saucer.fill")
        .font(.system(size: 54, weight: .medium))
        .accessibilityHidden(true)
    } else {
      Text(Date(timeIntervalSinceNow: state.getTimeIntervalSinceNow()), style: .timer)
    }
  }

  @ViewBuilder
  private var timerDetail: some View {
    if state.isPauseActive || state.isBreakActive {
      HStack(spacing: 4) {
        Image(state.isPauseActive ? "PauseStickerIcon" : "CoffeeStickerIcon")
          .resizable()
          .scaledToFit()
          .frame(width: 13, height: 13)
          .accessibilityHidden(true)
        Text(state.isPauseActive ? "Paused" : "On a Break")
      }
    } else if let endTime = state.expectedEndTime {
      Text("Ends at \(endTime, style: .time)")
    }
  }
}

// The width environment value requires the iOS 27 SDK bundled with Xcode 27 / Swift 6.4.
#if compiler(>=6.4)
  @available(iOS 27.0, *)
  private struct WidthAwareCompactIslandContent<Content: View>: View {
    @Environment(\.isDynamicIslandLimitedInWidth) private var isWidthLimited
    @ViewBuilder let content: (Bool) -> Content

    var body: some View {
      content(isWidthLimited)
    }
  }
#endif

extension FoqosWidgetAttributes {
  fileprivate static var preview: FoqosWidgetAttributes {
    FoqosWidgetAttributes(
      name: "Focus Session",
      message: "Stay focused and avoid distractions")
  }
}

extension FoqosWidgetAttributes.ContentState {
  fileprivate static var mintCat: FoqosWidgetAttributes.ContentState {
    var state = shortTime
    state.themeColorName = "Mint Fresh"
    state.appIconName = AppIconOption.cat.alternateIconName
    return state
  }

  fileprivate static var shortTime: FoqosWidgetAttributes.ContentState {
    FoqosWidgetAttributes
      .ContentState(
        startTime: Date(timeIntervalSinceNow: -60),
        expectedEndTime: Date(timeIntervalSinceNow: 25 * 60),
        isBreakActive: false,
        breakStartTime: nil,
        breakEndTime: nil,
        usedBreakDurationInSeconds: 0,
        isPauseActive: false,
        pauseStartTime: nil,
        pauseEndTime: nil
      )
  }

  fileprivate static var longTime: FoqosWidgetAttributes.ContentState {
    FoqosWidgetAttributes.ContentState(
      startTime: Date(timeIntervalSinceNow: -60),
      expectedEndTime: Date(timeIntervalSinceNow: 2 * 60 * 60),
      isBreakActive: false,
      breakStartTime: nil,
      breakEndTime: nil,
      usedBreakDurationInSeconds: 0,
      isPauseActive: false,
      pauseStartTime: nil,
      pauseEndTime: nil
    )
  }

  fileprivate static var breakActive: FoqosWidgetAttributes.ContentState {
    FoqosWidgetAttributes.ContentState(
      startTime: Date(timeIntervalSinceNow: -60),
      expectedEndTime: Date(timeIntervalSinceNow: 5 * 60),
      isBreakActive: true,
      breakStartTime: Date.now,
      breakEndTime: nil,
      usedBreakDurationInSeconds: 0,
      isPauseActive: false,
      pauseStartTime: nil,
      pauseEndTime: nil
    )
  }

  fileprivate static var pauseActive: FoqosWidgetAttributes.ContentState {
    FoqosWidgetAttributes.ContentState(
      startTime: Date(timeIntervalSinceNow: -60),
      expectedEndTime: Date(timeIntervalSinceNow: 10 * 60),
      isBreakActive: false,
      breakStartTime: nil,
      breakEndTime: nil,
      usedBreakDurationInSeconds: 0,
      isPauseActive: true,
      pauseStartTime: Date.now,
      pauseEndTime: nil
    )
  }
}

@available(iOS 18.0, *)
#Preview("Notification", as: .content, using: FoqosWidgetAttributes.preview) {
  FoqosWidgetLiveActivity()
} contentStates: {
  FoqosWidgetAttributes.ContentState.mintCat
  FoqosWidgetAttributes.ContentState.shortTime
  FoqosWidgetAttributes.ContentState.longTime
  FoqosWidgetAttributes.ContentState.breakActive
  FoqosWidgetAttributes.ContentState.pauseActive
}

@available(iOS 18.0, *)
#Preview("Mint Dynamic Island", as: .dynamicIsland(.compact), using: FoqosWidgetAttributes.preview)
{
  FoqosWidgetLiveActivity()
} contentStates: {
  FoqosWidgetAttributes.ContentState.mintCat
}

#Preview("StandBy · Focus", traits: .fixedLayout(width: 390, height: 180)) {
  FoqosStandByActivityView(
    profileName: "💪 Work",
    message: FoqosWidgetAttributes.preview.message,
    state: FoqosWidgetAttributes.ContentState.mintCat
  )
  .background(.black)
}

#Preview("StandBy · Long timer", traits: .fixedLayout(width: 320, height: 180)) {
  FoqosStandByActivityView(
    profileName: "A long profile name for a deep focus session",
    message: FoqosWidgetAttributes.preview.message,
    state: FoqosWidgetAttributes.ContentState.longTime
  )
  .background(.black)
}

#Preview("StandBy · Break", traits: .fixedLayout(width: 390, height: 180)) {
  FoqosStandByActivityView(
    profileName: "💪 Work",
    message: FoqosWidgetAttributes.preview.message,
    state: FoqosWidgetAttributes.ContentState.breakActive
  )
  .background(.black)
}

#Preview("StandBy · Paused", traits: .fixedLayout(width: 390, height: 180)) {
  FoqosStandByActivityView(
    profileName: "💪 Work",
    message: FoqosWidgetAttributes.preview.message,
    state: FoqosWidgetAttributes.ContentState.pauseActive
  )
  .background(.black)
}

#Preview("StandBy · Elapsed", traits: .fixedLayout(width: 320, height: 180)) {
  FoqosStandByActivityView(
    profileName: "Reading",
    message: FoqosWidgetAttributes.preview.message,
    state: FoqosWidgetAttributes.ContentState(startTime: Date(timeIntervalSinceNow: -7_800))
  )
  .background(.black)
}

#Preview("StandBy · Open-ended pause", traits: .fixedLayout(width: 320, height: 180)) {
  FoqosStandByActivityView(
    profileName: "Reading",
    message: FoqosWidgetAttributes.preview.message,
    state: FoqosWidgetAttributes.ContentState(
      startTime: Date(timeIntervalSinceNow: -7_800), isPauseActive: true
    )
  )
  .background(.black)
}
