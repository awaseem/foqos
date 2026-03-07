import Charts
import FamilyControls
import SwiftData
import SwiftUI

struct WeeklySessionChart: View {
  @StateObject private var viewModel: WeeklyProfileInsightsUtil
  @EnvironmentObject private var themeManager: ThemeManager
  @State private var selectedDay: WeeklyDayAggregate?
  @State private var selectedLabel: String?
  @State private var previousLabel: String?

  init(profile: BlockedProfiles) {
    _viewModel = StateObject(wrappedValue: WeeklyProfileInsightsUtil(profile: profile))
  }

  var body: some View {
    VStack(alignment: .leading, spacing: 20) {
      // Header with big number
      VStack(alignment: .leading, spacing: 8) {
        if let selectedDay = selectedDay {
          Text(selectedDay.date.formatted(.dateTime.weekday(.wide).month(.abbreviated).day()))
            .font(.title3)
            .fontWeight(.semibold)
            .foregroundStyle(.secondary)
          HStack(alignment: .firstTextBaseline, spacing: 8) {
            Text(viewModel.formattedDurationHHMMSS(selectedDay.totalSessionTime))
              .font(.system(size: 40, weight: .bold, design: .rounded))
              .foregroundStyle(.primary)
              .contentTransition(.numericText())

            Text("total")
              .font(.title3)
              .fontWeight(.semibold)
              .foregroundStyle(.secondary)
          }
        } else {
          Text("Avg Session")
            .font(.title3)
            .fontWeight(.semibold)
            .foregroundStyle(.secondary)
          HStack(alignment: .firstTextBaseline, spacing: 8) {
            Text(viewModel.formattedDurationHHMMSS(viewModel.weeklySummary.averageSessionDuration))
              .font(.system(size: 40, weight: .bold, design: .rounded))
              .foregroundStyle(.primary)
              .contentTransition(.numericText())
          }
        }
      }
      .animation(.spring(response: 0.3, dampingFraction: 0.8), value: selectedDay)

      // Bar Chart
      Chart(viewModel.weeklySummary.days) { day in
        BarMark(
          x: .value("Day", day.displayLabel),
          y: .value("Duration", day.totalSessionTime)
        )
        .foregroundStyle(
          selectedLabel == day.displayLabel
            ? themeManager.themeColor
            : themeManager.themeColor.opacity(0.7)
        )
        .cornerRadius(6)
      }
      .chartYAxis(.hidden)
      .chartXAxis {
        AxisMarks { value in
          AxisValueLabel {
            if let label = value.as(String.self) {
              Text(label)
                .font(.caption)
                .fontWeight(.medium)
                .foregroundStyle(.secondary)
            }
          }
        }
      }
      .chartXSelection(value: $selectedLabel)
      .onChange(of: selectedLabel) { oldValue, newValue in
        if let label = newValue {
          selectedDay = viewModel.weeklySummary.days.first { $0.displayLabel == label }
          // Haptic feedback: impact on initial selection, selection feedback on change
          if oldValue == nil {
            // Initial selection - light impact
          } else if oldValue != newValue {
            // Changed to different bar - selection feedback
          }
        } else {
          selectedDay = nil
        }
        previousLabel = newValue
      }
      .sensoryFeedback(.impact(flexibility: .soft, intensity: 0.5), trigger: selectedLabel) { old, new in
        // Trigger when transitioning from nil to a value (initial selection)
        old == nil && new != nil
      }
      .sensoryFeedback(.selection, trigger: previousLabel) { old, new in
        // Trigger when changing between different bars
        guard let oldLabel = old, let newLabel = new else { return false }
        return oldLabel != newLabel
      }
      .frame(height: 180)

      // Total time
      StatItem(
        title: "Total Time",
        value: viewModel.formattedDuration(viewModel.weeklySummary.totalFocusTime)
      )
      .padding(.top, 8)
    }
  }
}

private struct StatItem: View {
  let title: String
  let value: String

  var body: some View {
    VStack(alignment: .leading, spacing: 2) {
      Text(title)
        .font(.caption)
        .foregroundStyle(.secondary)

      Text(value)
        .font(.subheadline)
        .fontWeight(.semibold)
    }
  }
}

#Preview {
  struct PreviewWrapper: View {
    let container: ModelContainer
    let profile: BlockedProfiles

    init() {
      do {
        container = try ModelContainer(
          for: BlockedProfiles.self,
          BlockedProfileSession.self
        )
      } catch {
        fatalError("Failed to create preview container: \(error)")
      }

      let context = container.mainContext
      let profile = BlockedProfiles(
        name: "Work Focus",
        selectedActivity: FamilyActivitySelection()
      )
      context.insert(profile)

      // Create sessions for the current week
      let calendar = Calendar.current
      let today = Date()
      let weekday = calendar.component(.weekday, from: today)
      let daysToSubtract = weekday - 1

      // Add sessions across different days
      for dayOffset in 0..<7 {
        let sessionsCount = [3, 5, 2, 4, 6, 1, 2][dayOffset]
        let sessionDate = calendar.date(byAdding: .day, value: dayOffset - daysToSubtract, to: today)!

        for _ in 0..<sessionsCount {
          let session = BlockedProfileSession(
            tag: "Focus Session",
            blockedProfile: profile
          )
          let duration = TimeInterval.random(in: 1800...7200)
          session.startTime = calendar.date(byAdding: .second, value: -Int(duration), to: sessionDate)!
          session.endTime = sessionDate
          context.insert(session)
        }
      }

      self.profile = profile
    }

    var body: some View {
      WeeklySessionChart(profile: profile)
        .environmentObject(ThemeManager.shared)
        .modelContainer(container)
        .padding()
    }
  }

  return PreviewWrapper()
}
