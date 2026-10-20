import SwiftData
import SwiftUI

struct ProfileInsightsView: View {
  @Environment(\.dismiss) private var dismiss

  let profile: BlockedProfiles
  var initialViewMode: InsightsViewMode? = nil
  var initialSelectedDate: Date? = nil

  var body: some View {
    NavigationStack {
      ProfileInsightsContent(
        profile: profile,
        initialViewMode: initialViewMode,
        initialSelectedDate: initialSelectedDate
      )
      .toolbar {
        ToolbarItem(placement: .topBarLeading) {
          Button {
            dismiss()
          } label: {
            Image(systemName: "xmark")
          }
          .accessibilityLabel("Close")
        }
      }
    }
  }
}

#Preview {
  struct PreviewWrapper: View {
    let container: ModelContainer
    let profile: BlockedProfiles

    init() {
      do {
        container = try ModelContainer(for: BlockedProfiles.self, BlockedProfileSession.self)
      } catch {
        fatalError("Failed to create preview container: \(error)")
      }

      let context = container.mainContext
      let profile = BlockedProfiles(name: "Work Focus")
      context.insert(profile)

      let calendar = Calendar.current
      let weekStart = WeeklySessionAggregator.startOfWeek(for: Date(), calendar: calendar)

      for dayOffset in 0..<6 {
        let day = calendar.date(byAdding: .day, value: dayOffset, to: weekStart)!
        let session = BlockedProfileSession(
          tag: "Focus Block \(dayOffset + 1)", blockedProfile: profile)
        session.startTime = calendar.date(byAdding: .hour, value: 9 + dayOffset, to: day)!
        session.endTime = calendar.date(
          byAdding: .minute, value: 50 + dayOffset * 5, to: session.startTime)!
        context.insert(session)
      }

      self.profile = profile
    }

    var body: some View {
      ProfileInsightsView(profile: profile)
        .environmentObject(ThemeManager.shared)
        .modelContainer(container)
    }
  }

  return PreviewWrapper()
}
