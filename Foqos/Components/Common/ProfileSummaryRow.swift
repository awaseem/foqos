import Foundation
import SwiftUI

enum ProfileSummaryMetadata {
  case none
  case appsAndDomains
  case updatedAt(Date)

  var isVisible: Bool {
    switch self {
    case .none:
      return false
    case .appsAndDomains, .updatedAt:
      return true
    }
  }
}

enum ProfileSummaryLayout: Equatable {
  case dashboard
  case compact
}

struct ProfileSummaryRow<Accessory: View>: View {
  let profile: BlockedProfiles
  let isActive: Bool
  let metadata: ProfileSummaryMetadata
  let showsStatusLine: Bool
  let layout: ProfileSummaryLayout
  let accessory: () -> Accessory

  init(
    profile: BlockedProfiles,
    isActive: Bool,
    metadata: ProfileSummaryMetadata,
    showsStatusLine: Bool,
    layout: ProfileSummaryLayout = .dashboard,
    @ViewBuilder accessory: @escaping () -> Accessory
  ) {
    self.profile = profile
    self.isActive = isActive
    self.metadata = metadata
    self.showsStatusLine = showsStatusLine
    self.layout = layout
    self.accessory = accessory
  }

  var body: some View {
    HStack(spacing: rowSpacing) {
      ProfileSummaryContent(
        profile: profile,
        isActive: isActive,
        metadata: metadata,
        showsStatusLine: showsStatusLine,
        layout: layout
      )

      accessory()
    }
  }

  private var rowSpacing: CGFloat {
    switch layout {
    case .dashboard:
      return 12
    case .compact:
      return 10
    }
  }
}

struct ProfileSummaryContent: View {
  @EnvironmentObject private var themeManager: ThemeManager

  let profile: BlockedProfiles
  let isActive: Bool
  let metadata: ProfileSummaryMetadata
  let showsStatusLine: Bool
  let layout: ProfileSummaryLayout

  private var blockingStrategy: BlockingStrategy? {
    guard let strategyId = profile.blockingStrategyId else {
      return nil
    }
    return StrategyManager.getStrategyFromId(id: strategyId)
  }

  private var iconSize: CGFloat {
    switch layout {
    case .dashboard:
      return 34
    case .compact:
      return 26
    }
  }

  private var iconFontSize: CGFloat {
    switch layout {
    case .dashboard:
      return 17
    case .compact:
      return 15
    }
  }

  private var contentSpacing: CGFloat {
    switch layout {
    case .dashboard:
      return 6
    case .compact:
      return 4
    }
  }

  private var titleFont: Font {
    switch layout {
    case .dashboard:
      return .headline
    case .compact:
      return .subheadline
    }
  }

  var body: some View {
    HStack(spacing: layout == .dashboard ? 12 : 10) {
      BlockingStrategyIconImage(strategy: blockingStrategy)
        .font(.system(size: iconFontSize, weight: .semibold))
        .foregroundStyle(.secondary)
        .frame(width: iconSize, height: iconSize)

      VStack(alignment: .leading, spacing: contentSpacing) {
        HStack(spacing: 7) {
          Text(profile.name)
            .font(titleFont)
            .fontWeight(.semibold)
            .foregroundStyle(.primary)
            .lineLimit(1)

          if isActive {
            activeChip
          }
        }

        if metadata.isVisible {
          ProfileSummaryMetadataLine(profile: profile, metadata: metadata)
        }

        if showsStatusLine {
          ProfileSummaryStatusLine(profile: profile)
        }
      }
      .frame(maxWidth: .infinity, alignment: .leading)
      .layoutPriority(1)
    }
  }

  private var activeChip: some View {
    Text("Active")
      .font(.caption2)
      .fontWeight(.bold)
      .foregroundStyle(themeManager.themeColor)
      .padding(.horizontal, 7)
      .padding(.vertical, 4)
      .background(themeManager.themeColor.opacity(0.13), in: Capsule())
  }
}

struct ProfileUsageMiniBarChart: View {
  @EnvironmentObject private var themeManager: ThemeManager

  let profile: BlockedProfiles

  private var weekStart: Date {
    WeeklySessionAggregator.startOfWeek(for: Date())
  }

  private var aggregation: WeeklySessionAggregation {
    let intervals = profile.sessions.compactMap { session -> WeeklySessionInterval? in
      guard let endTime = session.endTime else { return nil }
      return WeeklySessionInterval(startTime: session.startTime, endTime: endTime)
    }

    return WeeklySessionAggregator.aggregate(
      sessions: intervals,
      weekStart: weekStart
    )
  }

  private var values: [TimeInterval] {
    aggregation.dailyDurations
  }

  private var maxValue: TimeInterval {
    max(values.max() ?? 0, 1)
  }

  private var dayLabels: [String] {
    let calendar = Calendar.current

    return (0..<7).map { dayOffset in
      guard let date = calendar.date(byAdding: .day, value: dayOffset, to: weekStart) else {
        return ""
      }

      return String(date.formatted(.dateTime.weekday(.narrow)).prefix(1))
    }
  }

  var body: some View {
    VStack(spacing: 3) {
      HStack(alignment: .bottom, spacing: 4) {
        ForEach(Array(values.enumerated()), id: \.offset) { _, value in
          let normalizedValue = CGFloat(value / maxValue)

          RoundedRectangle(cornerRadius: 2, style: .continuous)
            .fill(themeManager.themeColor)
            .opacity(value > 0 ? 0.36 + (normalizedValue * 0.64) : 0.14)
            .frame(maxWidth: .infinity)
            .frame(height: value > 0 ? max(5, normalizedValue * 25) : 3)
        }
      }
      .frame(height: 45, alignment: .bottom)

      HStack(spacing: 4) {
        ForEach(Array(dayLabels.enumerated()), id: \.offset) { _, label in
          Text(label)
            .font(.system(size: 6, weight: .semibold))
            .foregroundStyle(.secondary.opacity(0.7))
            .frame(maxWidth: .infinity)
        }
      }
    }
    .accessibilityHidden(true)
  }
}

private struct ProfileSummaryMetadataLine: View {
  let profile: BlockedProfiles
  let metadata: ProfileSummaryMetadata

  private var selectedItemsCount: Int {
    FamilyActivityUtil.countSelectedActivities(
      profile.selectedActivity,
      allowMode: profile.enableAllowMode
    )
  }

  private var domainsCount: Int {
    profile.domains?.count ?? 0
  }

  private var metadataText: String {
    switch metadata {
    case .none:
      return ""
    case .appsAndDomains:
      return
        "\(countLabel(selectedItemsCount, singular: "App", plural: "Apps")) | \(countLabel(domainsCount, singular: "Domain", plural: "Domains"))"
    case .updatedAt(let date):
      let formatter = RelativeDateTimeFormatter()
      formatter.unitsStyle = .short
      return "Updated \(formatter.localizedString(for: date, relativeTo: Date()))"
    }
  }

  var body: some View {
    Text(metadataText)
      .font(.caption)
      .fontWeight(.medium)
      .foregroundStyle(.secondary)
      .lineLimit(1)
  }

  private func countLabel(_ count: Int, singular: String, plural: String) -> String {
    "\(count) \(count == 1 ? singular : plural)"
  }
}

private struct ProfileSummaryStatusLine: View {
  let profile: BlockedProfiles

  var body: some View {
    if let schedule = profile.schedule, schedule.isActive {
      ProfileSummaryNextScheduleLine(schedule: schedule)
    } else {
      ProfileSummaryCompactIndicators(
        enableLiveActivity: profile.enableLiveActivity,
        hasReminders: profile.reminderTimeInSeconds != nil,
        enableBreaks: profile.enableBreaks,
        enableStrictMode: profile.enableStrictMode
      )
    }
  }
}

private struct ProfileSummaryNextScheduleLine: View {
  let schedule: BlockedProfileSchedule

  var body: some View {
    if let message = schedule.nextStartMessage(includePrefix: false) {
      Text(message)
        .font(.caption2)
        .lineLimit(1)
        .minimumScaleFactor(0.82)
        .foregroundStyle(.secondary)
    }
  }
}

private struct ProfileSummaryCompactIndicators: View {
  let enableLiveActivity: Bool
  let hasReminders: Bool
  let enableBreaks: Bool
  let enableStrictMode: Bool

  private var indicators: [String] {
    var values: [String] = []

    if enableBreaks {
      values.append("Breaks")
    }
    if enableStrictMode {
      values.append("Strict")
    }
    if enableLiveActivity {
      values.append("Live Activity")
    }
    if hasReminders {
      values.append("Reminders")
    }

    return values
  }

  var body: some View {
    if !indicators.isEmpty {
      HStack(spacing: 12) {
        ForEach(Array(indicators.prefix(3)), id: \.self) { label in
          HStack(spacing: 5) {
            Circle()
              .fill(Color.primary.opacity(0.85))
              .frame(width: 5, height: 5)

            Text(label)
              .font(.caption2)
              .foregroundColor(.secondary)
              .lineLimit(1)
          }
        }
      }
      .minimumScaleFactor(0.78)
    }
  }
}
