import FamilyControls
import SwiftUI

struct FourWeekHeatmapView: View {
  @EnvironmentObject var themeManager: ThemeManager

  let sessions: [BlockedProfileSession]
  let selectedDate: Date?
  let onDateSelected: (Date) -> Void

  private let daysToShow = 28

  private var legendData: [(String, Double)] {
    [("<1h", 0.3), ("1-3h", 0.5), ("3-5h", 0.7), (">5h", 0.9)]
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
    switch hours {
    case 0:
      return Color.gray.opacity(0.15)
    case 0..<1:
      return themeManager.themeColor.opacity(0.3)
    case 1..<3:
      return themeManager.themeColor.opacity(0.5)
    case 3..<5:
      return themeManager.themeColor.opacity(0.7)
    default:
      return themeManager.themeColor.opacity(0.9)
    }
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
        onDateSelected: { _ in }
      )
      .environmentObject(ThemeManager.shared)
      .padding()
    }
  }
  
  return PreviewWrapper()
}
