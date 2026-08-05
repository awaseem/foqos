import FamilyControls
import Foundation
import SwiftUI

struct HeatmapThresholds: Equatable {
  static let defaultLowHours = 1.0
  static let defaultMediumHours = 3.0
  static let defaultHighHours = 5.0
  static let minimumHours = 0.5
  static let maximumHours = 24.0
  static let minimumGapHours = 0.5

  var lowHours: Double
  var mediumHours: Double
  var highHours: Double

  static var defaults: HeatmapThresholds {
    HeatmapThresholds(
      lowHours: defaultLowHours,
      mediumHours: defaultMediumHours,
      highHours: defaultHighHours
    )
  }

  var normalized: HeatmapThresholds {
    let lowMaximum = Self.maximumHours - (Self.minimumGapHours * 2)
    let mediumMaximum = Self.maximumHours - Self.minimumGapHours

    let low = min(max(lowHours, Self.minimumHours), lowMaximum)
    let medium = min(max(mediumHours, low + Self.minimumGapHours), mediumMaximum)
    let high = min(max(highHours, medium + Self.minimumGapHours), Self.maximumHours)

    return HeatmapThresholds(lowHours: low, mediumHours: medium, highHours: high)
  }

  var legendData: [(String, Double)] {
    [
      ("<\(Self.formattedHours(lowHours))", 0.3),
      ("\(Self.formattedHours(lowHours))-\(Self.formattedHours(mediumHours))", 0.5),
      ("\(Self.formattedHours(mediumHours))-\(Self.formattedHours(highHours))", 0.7),
      (">\(Self.formattedHours(highHours))", 0.9),
    ]
  }

  func opacity(for hours: Double) -> Double {
    switch hours {
    case 0:
      return 0.15
    case 0..<lowHours:
      return 0.3
    case lowHours..<mediumHours:
      return 0.5
    case mediumHours..<highHours:
      return 0.7
    default:
      return 0.9
    }
  }

  static func formattedHours(_ hours: Double) -> String {
    if hours.rounded(.towardZero) == hours {
      return "\(Int(hours))h"
    }

    return String(format: "%.1fh", hours)
  }
}

struct FourWeekHeatmapView: View {
  @EnvironmentObject var themeManager: ThemeManager

  let sessions: [BlockedProfileSession]
  let selectedDate: Date?
  let thresholds: HeatmapThresholds
  let onDateSelected: (Date) -> Void

  private let daysToShow = 28

  private var legendData: [(String, Double)] {
    thresholds.normalized.legendData
  }

  private var dates: [Date] {
    DashboardActivityUtil.dates(forDays: daysToShow)
  }

  private var weeklyDates: [[Date]] {
    DashboardActivityUtil.weeklyDates(from: dates)
  }

  private func sessionHoursForDate(_ date: Date) -> Double {
    DashboardActivityUtil.sessionHoursForDate(date, sessions: sessions)
  }

  private func colorForHours(_ hours: Double) -> Color {
    if hours == 0 {
      return Color.gray.opacity(0.15)
    }

    return themeManager.themeColor.opacity(thresholds.normalized.opacity(for: hours))
  }

  private var legendView: some View {
    HStack {
      Spacer()
      HStack(spacing: 12) {
        ForEach(legendData, id: \.0) { label, opacity in
          HStack(spacing: 4) {
            Rectangle()
              .fill(themeManager.themeColor.opacity(opacity))
              .frame(width: 10, height: 10)
              .cornerRadius(2)

            Text(label)
              .font(.caption2)
              .foregroundColor(.secondary)
          }
        }
      }
    }
  }

  private func daySquareView(for date: Date) -> some View {
    let hours = sessionHoursForDate(date)
    let isSelected = selectedDate == date

    return VStack(spacing: 2) {
      Text(DateFormatters.formatDayNumber(date))
        .font(.system(size: 10))
        .foregroundColor(.secondary)

      Rectangle()
        .fill(colorForHours(hours))
        .aspectRatio(1, contentMode: .fit)
        .cornerRadius(4)
        .overlay(
          RoundedRectangle(cornerRadius: 4)
            .stroke(
              isSelected ? themeManager.themeColor : Color.clear,
              lineWidth: 2
            )
        )
        .onTapGesture {
          onDateSelected(date)
        }
        .contentShape(Rectangle())
    }
  }

  private func weekRowView(for week: [Date]) -> some View {
    HStack(spacing: 4) {
      ForEach(week, id: \.timeIntervalSince1970) { date in
        daySquareView(for: date)
      }
    }
    .frame(maxWidth: .infinity)
  }

  var body: some View {
    VStack(alignment: .leading, spacing: 12) {
      legendView

      LazyVStack(spacing: 8) {
        ForEach(weeklyDates.indices, id: \.self) { weekIndex in
          weekRowView(for: weeklyDates[weekIndex])
        }
      }
      .frame(maxWidth: .infinity)
    }
    .padding(16)
  }
}

#Preview {
  struct PreviewWrapper: View {
    let profile = BlockedProfiles(name: "Work Focus", selectedActivity: FamilyActivitySelection())

    var sessions: [BlockedProfileSession] {
      let calendar = Calendar.current
      let today = Date()
      var result: [BlockedProfileSession] = []

      for dayOffset in 0..<28 {
        let date = calendar.date(byAdding: .day, value: -dayOffset, to: today)!
        if dayOffset % 3 == 0 {
          let session = BlockedProfileSession(tag: "Focus", blockedProfile: profile)
          session.startTime = calendar.date(byAdding: .hour, value: 9, to: date)!
          session.endTime = calendar.date(byAdding: .hour, value: 11, to: session.startTime)
          result.append(session)
        }
      }
      return result
    }

    var body: some View {
      FourWeekHeatmapView(
        sessions: sessions,
        selectedDate: nil,
        thresholds: .defaults,
        onDateSelected: { _ in }
      )
      .environmentObject(ThemeManager.shared)
      .padding()
    }
  }

  return PreviewWrapper()
}
