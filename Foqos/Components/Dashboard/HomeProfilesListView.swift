import SwiftUI

struct HomeProfilesListView: View {
  let profiles: [BlockedProfiles]
  let isBlocking: Bool
  let activeSessionProfileId: UUID?
  let elapsedTime: TimeInterval
  let onManageTapped: () -> Void
  let onStartTapped: (BlockedProfiles) -> Void
  let onStopTapped: (BlockedProfiles) -> Void
  let onEditTapped: (BlockedProfiles) -> Void
  let onStatsTapped: (BlockedProfiles) -> Void
  let onActiveTapped: () -> Void

  var body: some View {
    VStack(alignment: .leading, spacing: 10) {
      SectionTitle(
        "Profiles",
        buttonText: "Manage",
        buttonAction: onManageTapped,
        buttonIcon: "slider.horizontal.3"
      )

      VStack(spacing: 0) {
        ForEach(Array(profiles.enumerated()), id: \.element.id) { index, profile in
          HomeProfileRow(
            profile: profile,
            isBlocking: isBlocking,
            isActive: profile.id == activeSessionProfileId,
            elapsedTime: elapsedTime,
            onStartTapped: {
              onStartTapped(profile)
            },
            onStopTapped: {
              onStopTapped(profile)
            },
            onEditTapped: {
              onEditTapped(profile)
            },
            onStatsTapped: {
              onStatsTapped(profile)
            },
            onActiveTapped: onActiveTapped
          )

          if index < profiles.count - 1 {
            Divider()
              .padding(.leading, 64)
          }
        }
      }
      .background(
        Color(.systemBackground),
        in: RoundedRectangle(cornerRadius: 20, style: .continuous)
      )
      .overlay(
        RoundedRectangle(cornerRadius: 20, style: .continuous)
          .strokeBorder(Color.primary.opacity(0.1), lineWidth: 1)
      )
    }
  }
}

private struct HomeProfileRow: View {
  @EnvironmentObject private var themeManager: ThemeManager

  let profile: BlockedProfiles
  let isBlocking: Bool
  let isActive: Bool
  let elapsedTime: TimeInterval
  let onStartTapped: () -> Void
  let onStopTapped: () -> Void
  let onEditTapped: () -> Void
  let onStatsTapped: () -> Void
  let onActiveTapped: () -> Void

  private var canStart: Bool {
    !isBlocking
  }

  private var canStop: Bool {
    profile.showStopButton(elapsedTime: elapsedTime)
  }

  private var strategyIconName: String {
    guard let strategyId = profile.blockingStrategyId else {
      return "questionmark.circle.fill"
    }
    return StrategyManager.getStrategyFromId(id: strategyId).iconType
  }

  var body: some View {
    HStack(spacing: 12) {
      Button(action: rowTapped) {
        HStack(spacing: 12) {
          strategyIcon

          VStack(alignment: .leading, spacing: 6) {
            HStack(spacing: 7) {
              Text(profile.name)
                .font(.headline)
                .fontWeight(.semibold)
                .foregroundStyle(.primary)
                .lineLimit(1)

              if isActive {
                activeChip
              }
            }

            HomeProfileMetadataLine(profile: profile)

            HomeProfileStatusLine(profile: profile)
          }
          .frame(maxWidth: .infinity, alignment: .leading)
          .layoutPriority(1)

          Spacer(minLength: 12)

          HomeProfileUsageMiniBarChart(profile: profile)
            .frame(width: 118, height: 62)
        }
      }
      .buttonStyle(.plain)
      .accessibilityLabel(
        isActive ? "Open active profile \(profile.name)" : "Show \(profile.name) insights"
      )

      actionMenu
    }
    .padding(16)
  }

  private var strategyIcon: some View {
    Image(systemName: strategyIconName)
      .font(.system(size: 17, weight: .semibold))
      .foregroundStyle(.secondary)
      .frame(width: 30, height: 30)
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

  private var actionMenu: some View {
    Menu {

      Button(action: onStatsTapped) {
        Label("Insights", systemImage: "chart.line.uptrend.xyaxis")
      }

      Button(action: onEditTapped) {
        Label("Edit", systemImage: "pencil")
      }

      if isActive {
        Button(action: onActiveTapped) {
          Label("Active Session", systemImage: "timer")
        }

        Button(action: onStopTapped) {
          Label(canStop ? "Stop" : "Stop Locked", systemImage: canStop ? "stop.fill" : "lock.fill")
        }
        .disabled(!canStop)
      } else {
        Button(action: onStartTapped) {
          Label("Start", systemImage: "play.fill")
        }
        .disabled(!canStart)
      }
    } label: {
      Image(systemName: "ellipsis")
        .font(.system(size: 16, weight: .semibold))
        .foregroundStyle(.secondary)
        .frame(width: 32, height: 44)
        .contentShape(Rectangle())
    }
    .accessibilityLabel("More actions for \(profile.name)")
  }

  private func rowTapped() {
    if isActive {
      onActiveTapped()
    } else {
      onStatsTapped()
    }
  }
}

private struct HomeProfileMetadataLine: View {
  let profile: BlockedProfiles

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
    "\(countLabel(selectedItemsCount, singular: "App", plural: "Apps")) | \(countLabel(domainsCount, singular: "Domain", plural: "Domains"))"
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

private struct HomeProfileStatusLine: View {
  let profile: BlockedProfiles

  var body: some View {
    if let schedule = profile.schedule, schedule.isActive {
      HomeProfileNextScheduleLine(schedule: schedule)
    } else {
      HomeProfileCompactIndicators(
        enableLiveActivity: profile.enableLiveActivity,
        hasReminders: profile.reminderTimeInSeconds != nil,
        enableBreaks: profile.enableBreaks,
        enableStrictMode: profile.enableStrictMode
      )
    }
  }
}

private struct HomeProfileNextScheduleLine: View {
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

private struct HomeProfileCompactIndicators: View {
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

private struct HomeProfileUsageMiniBarChart: View {
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
