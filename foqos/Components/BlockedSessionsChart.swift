import Charts
import SwiftUI

struct BlockedSessionsChart: View {
    let sessions: [BlockedProfileSession]
    @State private var selectedDuration: TimeInterval?
    @State private var selectedDay: String?
    @State private var selectedBarIndex: Int?
    
    private var weeklyData: [(date: Date, duration: TimeInterval)] {
        let calendar = Calendar.current
        let now = Date()
        let startOfToday = calendar.startOfDay(for: now)
        
        let dates = (0..<7).map { dayOffset in
            calendar.date(byAdding: .day, value: -dayOffset, to: startOfToday)!
        }.reversed()
        
        let dailySessions = Dictionary(grouping: sessions) { session in
            calendar.startOfDay(for: session.startTime)
        }
        
        return dates.map { date in
            let sessionsForDay = dailySessions[date, default: []]
            let totalDuration = sessionsForDay.reduce(0) { $0 + $1.duration }
            return (date: date, duration: totalDuration)
        }
    }
    
    private var averageDuration: TimeInterval {
        let total = weeklyData.reduce(0) { $0 + $1.duration }
        return total / Double(weeklyData.count)
    }
    
    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "EEE"
        return formatter.string(from: date).uppercased()
    }
    
    private func formatDuration(_ duration: TimeInterval) -> String {
        let hours = duration / 3600
        if hours < 1 {
            return String(format: "%.1f hr", hours)
        } else {
            return String(format: "%.1f hrs", hours)
        }
    }
    
    private func getBarColor(for index: Int) -> Color {
        if let selectedIndex = selectedBarIndex, selectedIndex == index {
            return .purple.opacity(1)  // Selected bar
        }
        return .purple.opacity(0.6)  // Unselected bars
    }
    
    var body: some View {
        VStack(alignment: .leading) {
            HStack(alignment: .bottom, spacing: 4) {
                Text(
                    selectedDuration.map { formatDuration($0) }
                    ?? formatDuration(averageDuration)
                )
                .font(.title2)
                .fontWeight(.bold)
                .animation(.easeInOut(duration: 0.2), value: selectedDuration)
                
                Text((selectedDay ?? "AVG") + ".")
                    .font(.footnote)
                    .fontWeight(.light)
                    .foregroundColor(.secondary)
                    .animation(.easeInOut(duration: 0.2), value: selectedDay)
                    .padding(.bottom, 1)
            }
            
            Chart(Array(weeklyData.enumerated()), id: \.element.date) {
                index, data in
                BarMark(
                    x: .value("Day", formatDate(data.date)),
                    y: .value("Duration", data.duration / 3600)
                )
                .foregroundStyle(getBarColor(for: index))
                .cornerRadius(4)
            }
            .chartXAxis {
                AxisMarks { _ in
                    AxisValueLabel()
                }
            }
            .chartYAxis {
                AxisMarks { value in
                    if let hours = value.as(Double.self) {
                        AxisValueLabel {
                            Text(String(format: "%.1f", hours))
                                .font(.caption)
                                .foregroundColor(.secondary)
                            + Text(" hrs")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }
                }
            }
            .chartPlotStyle { plotArea in
                plotArea.frame(height: 180)
            }
            .gesture(
                DragGesture(minimumDistance: 0)
                    .onChanged { value in
                        let plotWidth = UIScreen.main.bounds.width - 32
                        let barWidth = plotWidth / CGFloat(weeklyData.count)
                        let index = Int(
                            (value.location.x + barWidth / 2) / barWidth)
                        
                        if index >= 0 && index < weeklyData.count {
                            // Only trigger haptic and update if we're selecting a new bar
                            if selectedBarIndex != index {
                                let impactGenerator = UIImpactFeedbackGenerator(
                                    style: .light)
                                impactGenerator.impactOccurred()
                            }
                            
                            let dataPoint = weeklyData[index]
                            withAnimation(.easeInOut(duration: 0.2)) {
                                selectedDuration = dataPoint.duration
                                selectedDay = formatDate(dataPoint.date)
                                selectedBarIndex = index
                            }
                        }
                    }
                    .onEnded { _ in
                        withAnimation(.easeInOut(duration: 0.2)) {
                            selectedDuration = nil
                            selectedDay = nil
                            selectedBarIndex = nil
                        }
                    }
            )
        }
    }
}
