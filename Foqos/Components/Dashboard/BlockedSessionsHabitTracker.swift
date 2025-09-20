import SwiftData
import SwiftUI

struct BlockedSessionsHabitTracker: View {
  let sessions: [BlockedProfileSession]
  @State private var selectedDate: Date?
  @State private var selectedSessions: [BlockedProfileSession] = []
  @State private var showingSessionDetails = false
  @AppStorage("showHabitTracker") private var showHabitTracker = true

  // Number of days to show in the tracker
  private let daysToShow = 28  // 4 weeks (7 days x 4)

  // MARK: - Lazy Multi-Day Session Support
  
  /// Calculates total session hours for a specific date by checking overlap with all sessions
  private func sessionHoursForDate(_ date: Date) -> Double {
    let calendar = Calendar.current
    let dayStart = calendar.startOfDay(for: date)
    guard let dayEnd = calendar.date(byAdding: .day, value: 1, to: dayStart) else { return 0 }
    
    let totalSeconds = sessions.reduce(0.0) { total, session in
      // Calculate overlap between session and this specific day
      let sessionStart = session.startTime
      let sessionEnd = session.endTime ?? Date()
      
      // Find intersection between session time range and day time range
      let overlapStart = max(sessionStart, dayStart)
      let overlapEnd = min(sessionEnd, dayEnd)
      
      // Only count positive overlap
      let overlapDuration = max(0, overlapEnd.timeIntervalSince(overlapStart))
      return total + overlapDuration
    }
    
    return totalSeconds / 3600 // Convert to hours
  }
  
  /// Gets sessions that have any overlap with the specified date
  private func sessionsForDate(_ date: Date) -> [BlockedProfileSession] {
    let calendar = Calendar.current
    let dayStart = calendar.startOfDay(for: date)
    guard let dayEnd = calendar.date(byAdding: .day, value: 1, to: dayStart) else { return [] }
    
    return sessions.filter { session in
      let sessionStart = session.startTime
      let sessionEnd = session.endTime ?? Date()
      
      // Check if session overlaps with this day
      return sessionStart < dayEnd && sessionEnd > dayStart
    }.sorted { $0.duration > $1.duration }
  }
  
  /// Determines if a session spans multiple days (for display purposes)
  private func isMultiDaySession(_ session: BlockedProfileSession) -> Bool {
    guard let endTime = session.endTime else { return false }
    let calendar = Calendar.current
    let startDay = calendar.startOfDay(for: session.startTime)
    let endDay = calendar.startOfDay(for: endTime)
    return startDay != endDay
  }
  
  /// Calculates how much of a session occurred on a specific date
  private func sessionDurationForDate(_ session: BlockedProfileSession, date: Date) -> TimeInterval {
    let calendar = Calendar.current
    let dayStart = calendar.startOfDay(for: date)
    guard let dayEnd = calendar.date(byAdding: .day, value: 1, to: dayStart) else { return 0 }
    
    let sessionStart = session.startTime
    let sessionEnd = session.endTime ?? Date()
    
    let overlapStart = max(sessionStart, dayStart)
    let overlapEnd = min(sessionEnd, dayEnd)
    
    return max(0, overlapEnd.timeIntervalSince(overlapStart))
  }

  private func dates() -> [Date] {
    let calendar = Calendar.current
    let today = calendar.startOfDay(for: Date())

    return (0..<daysToShow).map { day in
      calendar.date(byAdding: .day, value: -day, to: today)!
    }.reversed()
  }


  private func colorForHours(_ hours: Double) -> Color {
    switch hours {
    case 0:
      return Color.gray.opacity(0.15)
    case 0..<1:
      return Color.purple.opacity(0.3)
    case 1..<3:
      return Color.purple.opacity(0.5)
    case 3..<5:
      return Color.purple.opacity(0.7)
    default:
      return Color.purple.opacity(0.9)
    }
  }

  private func formatDate(_ date: Date) -> String {
    let formatter = DateFormatter()
    formatter.dateFormat = "MMM d, yyyy"
    return formatter.string(from: date)
  }

  private func formatDay(_ date: Date) -> String {
    let formatter = DateFormatter()
    formatter.dateFormat = "d"
    return formatter.string(from: date)
  }

  // MARK: - Computed Properties
  private var legendData: [(String, Double)] {
    [("<1h", 0.3), ("1-3h", 0.5), ("3-5h", 0.7), (">5h", 0.9)]
  }
  
  private var weeklyDates: [[Date]] {
    let allDates = dates()
    return stride(from: 0, to: allDates.count, by: 7).map { startIndex in
      let endIndex = min(startIndex + 7, allDates.count)
      return Array(allDates[startIndex..<endIndex])
    }
  }

  // MARK: - View Helpers
  private func handleDateTap(_ date: Date) {
    let isCurrentlySelected = selectedDate == date
    
    if isCurrentlySelected {
      // Deselect if already selected
      selectedDate = nil
      selectedSessions = []
      showingSessionDetails = false
    } else {
      // Select a new date
      selectedDate = date
      selectedSessions = sessionsForDate(date)
      showingSessionDetails = true
    }
  }
  
  private func legendView() -> some View {
    HStack {
      Spacer()
      HStack(spacing: 12) {
        ForEach(legendData, id: \.0) { label, opacity in
          HStack(spacing: 4) {
            Rectangle()
              .fill(Color.purple.opacity(opacity))
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
      Text(formatDay(date))
        .font(.system(size: 10))
        .foregroundColor(.secondary)
      
      Rectangle()
        .fill(colorForHours(hours))
        .aspectRatio(1, contentMode: .fit)
        .cornerRadius(4)
        .overlay(
          RoundedRectangle(cornerRadius: 4)
            .stroke(
              isSelected ? Color.purple : Color.clear,
              lineWidth: 2
            )
        )
        .onTapGesture {
          handleDateTap(date)
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
  
  private func sessionDetailsView(for date: Date) -> some View {
    VStack(alignment: .leading, spacing: 10) {
      Text(formatDate(date))
        .font(.subheadline)
        .fontWeight(.medium)
      
      if selectedSessions.isEmpty {
        Text("No sessions on this day")
          .font(.caption)
          .foregroundColor(.secondary)
      } else {
        sessionListView(for: date)
      }
    }
    .padding(.top, 8)
    .transition(.move(edge: .bottom).combined(with: .opacity))
    .animation(.easeInOut, value: showingSessionDetails)
  }
  
  private func sessionListView(for date: Date) -> some View {
    VStack(alignment: .leading, spacing: 8) {
      let displayedSessions = Array(selectedSessions.prefix(3))
      
      ForEach(displayedSessions, id: \.id) { session in
        sessionRowView(for: session, on: date)
        
        if session != displayedSessions.last {
          Divider()
        }
      }
      
      if selectedSessions.count > 3 {
        Text("+ \(selectedSessions.count - 3) more sessions")
          .font(.caption)
          .foregroundColor(.secondary)
          .padding(.top, 4)
      }
    }
  }
  
  private func sessionRowView(for session: BlockedProfileSession, on date: Date) -> some View {
    let dailyDuration = sessionDurationForDate(session, date: date)
    let isMultiDay = isMultiDaySession(session)
    
    return HStack {
      VStack(alignment: .leading, spacing: 2) {
        Text(session.blockedProfile.name)
          .font(.subheadline)
          .foregroundColor(.primary)
        
        if isMultiDay {
          Text("(spans multiple days)")
            .font(.caption2)
            .foregroundColor(.secondary)
        }
      }
      
      Spacer()
      
      Text(String(format: "%.1f hrs", dailyDuration / 3600))
        .font(.subheadline)
        .fontWeight(.medium)
        .foregroundColor(.secondary)
    }
    .padding(.vertical, 4)
  }

  var body: some View {
    VStack(alignment: .leading, spacing: 10) {
      HStack(alignment: .center) {
        SectionTitle(
          "4 Week Activity", 
          buttonText: showHabitTracker ? "Hide" : "Show",
          buttonAction: { showHabitTracker.toggle() }, 
          buttonIcon: showHabitTracker ? "eye.slash" : "eye"
        )
      }

      ZStack {
        if showHabitTracker {
          RoundedRectangle(cornerRadius: 24)
            .fill(Color(.systemBackground))

          VStack(alignment: .leading, spacing: 12) {
            legendView()
            
            LazyVStack(spacing: 8) {
              ForEach(weeklyDates.indices, id: \.self) { weekIndex in
                weekRowView(for: weeklyDates[weekIndex])
              }
            }
            .frame(maxWidth: .infinity)

            if showingSessionDetails, let date = selectedDate {
              sessionDetailsView(for: date)
            }
          }
          .padding(16)
        }
      }
      .overlay(
        RoundedRectangle(cornerRadius: 24)
          .stroke(Color.gray.opacity(0.3), lineWidth: 1)
      )
      .animation(.easeInOut(duration: 0.3), value: showHabitTracker)
      .frame(height: showHabitTracker ? nil : 0, alignment: .top)
      .clipped()
    }
  }
}

#Preview {
  BlockedSessionsHabitTracker(sessions: [])
}
