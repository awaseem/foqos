import SwiftUI
import WidgetKit

struct ProfileWidgetEntryView: View {
  let entry: ProfileWidgetEntry
  var previewFamily: WidgetFamily? = nil
  @Environment(\.widgetFamily) private var widgetFamily
  private var family: WidgetFamily { previewFamily ?? widgetFamily }

  private var isMonthly: Bool { entry.activityPeriod == .month }
  private var duration: TimeInterval {
    isMonthly ? entry.activity.monthlyDuration : entry.activity.weeklyDuration
  }

  var body: some View {
    Group {
      switch family {
      case .accessoryInline:
        Label {
          if let start = entry.sessionStartTime, !entry.isPauseActive, !entry.isBreakActive {
            Text(start, style: .timer)
          } else {
            Text(entry.isSessionActive ? entry.statusLabel : entry.profileName ?? "Foqos")
          }
        } icon: {
          Image(systemName: statusSymbol)
        }
      case .accessoryRectangular:
        VStack(alignment: .leading, spacing: 3) {
          Text(entry.profileName ?? "Foqos").font(.headline).lineLimit(1)
          Text("\(WidgetActivitySummary.durationLabel(entry.activity.weeklyDuration)) this week")
            .font(.caption)
          status(compact: false)
        }
      case .systemMedium:
        medium
      default:
        small
      }
    }
    .widgetURL(entry.destination)
  }

  private var small: some View {
    VStack(alignment: .leading, spacing: 6) {
      profileHeader(compact: true)
      metric(size: 29)
      if isMonthly {
        WidgetMonthGrid(entry: entry, showsNumbers: false, showsWeekdays: false)
      } else {
        WidgetWeekChart(entry: entry)
      }
      status(compact: true)
    }
  }

  private var medium: some View {
    VStack(alignment: .leading, spacing: 12) {
      profileHeader(compact: false)
      HStack(alignment: .top, spacing: 20) {
        VStack(alignment: .leading, spacing: 7) {
          metric(size: 32)
          Spacer(minLength: 0)
          status(compact: true)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        Group {
          if isMonthly {
            WidgetMonthGrid(entry: entry, showsNumbers: false, showsWeekdays: true)
          } else {
            WidgetWeekChart(entry: entry)
          }
        }
        .frame(maxWidth: .infinity)
      }
    }
  }

  private func profileHeader(compact: Bool) -> some View {
    HStack(spacing: 6) {
      Image(systemName: "scope")
        .font(.system(size: compact ? 13 : 15, weight: .semibold))
        .foregroundStyle(entry.themeColor)
        .widgetAccentable()
      Text(entry.profileName ?? "Your focus")
        .font(.system(size: compact ? 12 : 14, weight: .semibold))
        .lineLimit(1)
      Spacer(minLength: 0)
      if !compact {
        Text(profileDetail)
          .font(.system(size: 10, weight: .medium))
          .foregroundStyle(.secondary)
          .lineLimit(1)
          .layoutPriority(-1)
      }
    }
  }

  private var profileDetail: String {
    guard let profile = entry.profileInfo else { return "FOQOS" }
    if profile.enableStrictMode { return "Strict mode" }
    if profile.enableAllowMode { return "Allow mode" }
    return "\(profile.selectedItemCount) selected"
  }

  private func metric(size: CGFloat) -> some View {
    VStack(alignment: .leading, spacing: 1) {
      Text(
        WidgetActivitySummary.durationLabel(
          duration)
      )
      .font(.system(size: size, weight: .semibold, design: .rounded))
      .tracking(-1.2)
      .minimumScaleFactor(0.65)
      .lineLimit(1)
      .foregroundStyle(.primary)
      Text(isMonthly ? "focused this month" : "focused this week")
        .font(.system(size: 10, weight: .medium))
        .foregroundStyle(.secondary)
    }
    .accessibilityElement(children: .combine)
  }

  private var statusSymbol: String {
    if entry.isPauseActive { return "pause.fill" }
    if entry.isBreakActive { return "cup.and.saucer.fill" }
    if entry.isSessionActive { return "circle.fill" }
    return "arrow.up.right"
  }

  private func status(compact: Bool) -> some View {
    HStack(spacing: 5) {
      Image(systemName: statusSymbol)
        .font(.system(size: entry.isSessionActive ? 7 : 9, weight: .bold))
        .foregroundStyle(entry.themeColor)
        .widgetAccentable()
      if let start = entry.sessionStartTime, !entry.isBreakActive, !entry.isPauseActive {
        if !compact { Text("Focusing").foregroundStyle(.secondary) }
        Text(start, style: .timer).monospacedDigit()
          .frame(maxWidth: .infinity, alignment: .leading)
      } else {
        Text(entry.statusLabel).lineLimit(1).minimumScaleFactor(0.75)
      }
      if !compact {
        Spacer(minLength: 0)
        Text("foqos").font(.system(size: 11, weight: .bold, design: .rounded))
          .foregroundStyle(.tertiary)
      }
    }
    .font(.system(size: 10, weight: .medium))
  }
}

struct WidgetWeekChart: View {
  let entry: ProfileWidgetEntry

  var body: some View {
    GeometryReader { geometry in
      let maxDuration = max(entry.activity.week.map(\.duration).max() ?? 0, 3600)
      let plotHeight = max(0, geometry.size.height - 16)
      HStack(alignment: .bottom, spacing: 5) {
        ForEach(entry.activity.week) { day in
          let isToday = Calendar.current.isDate(day.date, inSameDayAs: entry.date)
          VStack(spacing: 5) {
            ZStack(alignment: .bottom) {
              RoundedRectangle(cornerRadius: 4)
                .fill(entry.themeColor.opacity(0.07))
              if day.duration > 0 {
                RoundedRectangle(cornerRadius: 4)
                  .fill(entry.themeColor.opacity(isToday ? 1 : 0.55))
                  .frame(height: max(3, plotHeight * day.duration / maxDuration))
                  .widgetAccentable()
              }
            }
            .frame(height: plotHeight)
            Text(day.date.formatted(.dateTime.weekday(.narrow)))
              .font(.system(size: 9, weight: isToday ? .bold : .medium))
              .foregroundStyle(isToday ? .primary : .secondary)
          }
          .frame(maxWidth: .infinity)
          .accessibilityElement(children: .ignore)
          .accessibilityLabel(
            "\(day.date.formatted(.dateTime.weekday(.wide))), \(WidgetActivitySummary.durationLabel(day.duration))"
          )
        }
      }
    }
    .accessibilityElement(children: .contain)
    .accessibilityLabel("Weekly focus")
  }
}

struct WidgetMonthGrid: View {
  let entry: ProfileWidgetEntry
  let showsNumbers: Bool
  let showsWeekdays: Bool
  @Environment(\.colorScheme) private var colorScheme

  private var cellCount: Int {
    ((entry.activity.monthLeadingDays + entry.activity.month.count + 6) / 7) * 7
  }

  var body: some View {
    GeometryReader { geometry in
      let rows = max(1, cellCount / 7)
      let headerHeight: CGFloat = showsWeekdays ? 13 : 0
      let cellHeight = max(
        0, (geometry.size.height - headerHeight - CGFloat(rows - 1) * 3) / CGFloat(rows))
      VStack(spacing: 3) {
        if showsWeekdays {
          HStack(spacing: 3) {
            ForEach(0..<7) { index in
              let symbols = Calendar.current.veryShortStandaloneWeekdaySymbols
              Text(symbols[(index + Calendar.current.firstWeekday - 1) % 7])
                .font(.system(size: 8, weight: .medium))
                .foregroundStyle(.secondary)
                .frame(maxWidth: .infinity)
            }
          }
          .frame(height: 10)
        }
        ForEach(0..<rows, id: \.self) { row in
          HStack(spacing: 3) {
            ForEach(0..<7) { column in
              let index = row * 7 + column - entry.activity.monthLeadingDays
              if entry.activity.month.indices.contains(index) {
                dayCell(entry.activity.month[index])
                  .frame(maxWidth: .infinity)
              } else {
                Color.clear.frame(maxWidth: .infinity)
              }
            }
          }
          .frame(height: cellHeight)
        }
      }
    }
    .accessibilityElement(children: .contain)
    .accessibilityLabel("Monthly focus. Darker cells show more time focused.")
  }

  private func dayCell(_ day: WidgetActivityDay) -> some View {
    let isToday = Calendar.current.isDate(day.date, inSameDayAs: entry.date)
    let isFuture = day.date > entry.date
    let level = day.duration == 0 ? 0 : min(0.8, 0.2 + day.duration / (6 * 3600) * 0.6)
    return RoundedRectangle(cornerRadius: 3)
      .fill(
        day.duration == 0
          ? Color.primary.opacity(isFuture ? 0.025 : 0.055)
          : entry.themeColor.opacity(level * (colorScheme == .dark ? 0.5 : 1))
      )
      .overlay {
        if showsNumbers {
          Text(day.date.formatted(.dateTime.day()))
            .font(.system(size: 8, weight: isToday ? .bold : .medium))
            .foregroundStyle(.primary.opacity(isFuture ? 0.25 : 0.9))
        }
      }
      .overlay {
        RoundedRectangle(cornerRadius: 3)
          .strokeBorder(isToday ? entry.themeColor : .clear, lineWidth: 1.5)
      }
      .widgetAccentable()
      .accessibilityLabel(
        "\(day.date.formatted(.dateTime.month().day())), \(WidgetActivitySummary.durationLabel(day.duration))"
      )
  }
}

struct ProfileWidgetBackground: View {
  var body: some View {
    Color(uiColor: .systemBackground)
  }
}
