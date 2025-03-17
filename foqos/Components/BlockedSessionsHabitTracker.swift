import SwiftUI
import SwiftData

struct BlockedSessionsHabitTracker: View {
    let sessions: [BlockedProfileSession]
    @State private var selectedDate: Date?
    @State private var selectedSessions: [BlockedProfileSession] = []
    @State private var showingSessionDetails = false
    
    // Number of days to show in the tracker
    private let daysToShow = 28 // 4 weeks (7 days x 4)
    
    private var sessionsByDay: [Date: [BlockedProfileSession]] {
        let calendar = Calendar.current
        return Dictionary(grouping: sessions) { session in
            calendar.startOfDay(for: session.startTime)
        }
    }
    
    private func dates() -> [Date] {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        
        return (0..<daysToShow).map { day in
            calendar.date(byAdding: .day, value: -day, to: today)!
        }.reversed()
    }
    
    private func sessionHoursForDate(_ date: Date) -> Double {
        let sessionsForDay = sessionsByDay[date, default: []]
        let totalDuration = sessionsForDay.reduce(0) { $0 + $1.duration }
        return totalDuration / 3600
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
    
    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            // Header section using SectionTitle
            SectionTitle("4 Week Activity")
            
            ZStack {
                RoundedRectangle(cornerRadius: 24)
                    .fill(.ultraThinMaterial.opacity(0.7))
                
                VStack(alignment: .leading, spacing: 12) {
                    HStack {
                        Spacer()
                        
                        HStack(spacing: 12) {
                            ForEach([("<1h", 0.3), ("1-3h", 0.5), ("3-5h", 0.7), (">5h", 0.9)], id: \.0) { label, opacity in
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
                    
                    LazyVStack(spacing: 8) {
                        let allDates = dates()
                        let weeks = stride(from: 0, to: allDates.count, by: 7).map {
                            Array(allDates[min($0, allDates.count)..<min($0 + 7, allDates.count)])
                        }
                        
                        ForEach(weeks.indices, id: \.self) { weekIndex in
                            let week = weeks[weekIndex]
                            
                            HStack(spacing: 4) {
                                ForEach(week, id: \.timeIntervalSince1970) { date in
                                    let hours = sessionHoursForDate(date)
                                    let isSelected = selectedDate == date
                                    
                                    VStack(spacing: 2) {
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
                                                if isSelected {
                                                    // Deselect if already selected
                                                    selectedDate = nil
                                                    selectedSessions = []
                                                    showingSessionDetails = false
                                                } else {
                                                    // Select a new date
                                                    selectedDate = date
                                                    selectedSessions = sessionsByDay[date, default: []]
                                                        .sorted(by: { $0.duration > $1.duration })
                                                    
                                                    showingSessionDetails = true
                                                }
                                            }
                                            .contentShape(Rectangle())
                                    }
                                }
                            }
                            .frame(maxWidth: .infinity)
                        }
                    }
                    .frame(maxWidth: .infinity)
                    
                    if showingSessionDetails, let date = selectedDate {
                        VStack(alignment: .leading, spacing: 10) {
                            Text(formatDate(date))
                                .font(.subheadline)
                                .fontWeight(.medium)
                            
                            if selectedSessions.isEmpty {
                                Text("No sessions on this day")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            } else {
                                VStack(alignment: .leading, spacing: 8) {
                                    ForEach(selectedSessions.prefix(3), id: \.id) { session in
                                        HStack {
                                            Text(session.blockedProfile.name)
                                                .font(.subheadline)
                                                .foregroundColor(.primary)
                                            
                                            Spacer()
                                            
                                            Text(String(format: "%.1f hrs", session.duration / 3600))
                                                .font(.subheadline)
                                                .fontWeight(.medium)
                                                .foregroundColor(.secondary)
                                        }
                                        .padding(.vertical, 4)
                                        
                                        if session != selectedSessions.prefix(3).last {
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
                        }
                        .padding(.top, 8)
                        .transition(.move(edge: .bottom).combined(with: .opacity))
                        .animation(.easeInOut, value: showingSessionDetails)
                    }
                }
                .padding(16)
            }
        }
    }
}

#Preview {
    // Create mock data for preview
    let modelContainer = try! ModelContainer(for: BlockedProfiles.self, BlockedProfileSession.self)
    let modelContext = ModelContext(modelContainer)
    
    // Create sample profiles
    let profile1 = BlockedProfiles(name: "Work Focus")
    let profile2 = BlockedProfiles(name: "Gaming")
    modelContext.insert(profile1)
    modelContext.insert(profile2)
    
    // Create some sample sessions over the past 30 days
    let calendar = Calendar.current
    let today = Date()
    
    var sampleSessions: [BlockedProfileSession] = []
    
    // Create sessions for the last 30 days with different patterns
    for dayOffset in 0..<30 {
        let sessionDate = calendar.date(byAdding: .day, value: -dayOffset, to: today)!
        
        // Create 0-2 sessions per day with varying durations
        let sessionsPerDay = Int.random(in: 0...2)
        if sessionsPerDay > 0 {
            for _ in 0..<sessionsPerDay {
                // Alternate between profiles
                let profile = dayOffset % 2 == 0 ? profile1 : profile2
                
                // Create session with random duration
                let session = BlockedProfileSession(tag: "Sample", blockedProfile: profile)
                
                // Set start time to the session date
                let startComponents = calendar.dateComponents([.year, .month, .day], from: sessionDate)
                var startDate = calendar.date(from: startComponents)!
                
                // Add a random hour offset
                startDate = calendar.date(byAdding: .hour, value: Int.random(in: 9...17), to: startDate)!
                session.startTime = startDate
                
                // Set end time with random duration (between 30 min and 6 hours)
                let durationHours = Double.random(in: 0.5...6.0)
                session.endTime = calendar.date(byAdding: .second, value: Int(durationHours * 3600), to: startDate)
                
                sampleSessions.append(session)
                modelContext.insert(session)
            }
        }
    }
    
    return ZStack {
        Color(.systemGroupedBackground).ignoresSafeArea()
        
        BlockedSessionsHabitTracker(sessions: sampleSessions)
            .padding()
    }
}
