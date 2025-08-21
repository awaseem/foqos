import SwiftUI

struct SchedulePicker: View {
  @Binding var schedule: BlockedProfileSchedule
  @Binding var isPresented: Bool

  private let hours: [Int] = Array(0...23)
  private let minutes: [Int] = Array(stride(from: 0, through: 55, by: 5))

  @State private var startHour: Int = 9
  @State private var startMinute: Int = 0
  @State private var endHour: Int = 10
  @State private var endMinute: Int = 0

  private let minimumDurationMinutes: Int = 60

  private var startTotalMinutes: Int { startHour * 60 + startMinute }
  private var endTotalMinutes: Int { endHour * 60 + endMinute }

  private var latestMinuteOfDay: Int { 23 * 60 + 55 }

  private var isValid: Bool {
    endTotalMinutes - startTotalMinutes >= minimumDurationMinutes
  }

  private var validationMessage: String? {
    guard !isValid else { return nil }

    if startTotalMinutes > latestMinuteOfDay - minimumDurationMinutes {
      return "Start time must be at least 1 hour before the end of the day."
    }

    return "End time must be at least 1 hour after start time."
  }

  var body: some View {
    NavigationStack {
      Form {
        Section {
          timePickers(hour: $startHour, minute: $startMinute)
        } header: {
          Text("Start Time")
        }

        Section {
          timePickers(hour: $endHour, minute: $endMinute)
        } header: {
          Text("End Time")
        } footer: {
          if let validationMessage {
            Text(validationMessage)
              .font(.caption)
              .foregroundStyle(.orange)
          }
        }
      }
      .navigationTitle("Schedule")
      .navigationBarTitleDisplayMode(.inline)
      .toolbar {
        ToolbarItem(placement: .topBarTrailing) {
          Button("Done") {
            applySelection()
            isPresented = false
          }
          .disabled(!isValid)
        }
      }
      .onAppear(perform: loadFromBinding)
      .onChange(of: startHour) { _, _ in adjustEndIfNeededForStartChange() }
      .onChange(of: startMinute) { _, _ in adjustEndIfNeededForStartChange() }
      .onChange(of: endHour) { _, _ in clampToValidEndIfNeeded() }
      .onChange(of: endMinute) { _, _ in clampToValidEndIfNeeded() }
    }
  }

  @ViewBuilder
  private func timePickers(hour: Binding<Int>, minute: Binding<Int>) -> some View {
    HStack {
      Picker("Hour", selection: hour) {
        ForEach(hours, id: \.self) { h in
          Text(String(format: "%02d", h)).tag(h)
        }
      }
      .labelsHidden()
      .pickerStyle(.wheel)
      .frame(maxWidth: .infinity)

      Text(":")
        .font(.headline)
        .foregroundStyle(.secondary)

      Picker("Minute", selection: minute) {
        ForEach(minutes, id: \.self) { m in
          Text(String(format: "%02d", m)).tag(m)
        }
      }
      .labelsHidden()
      .pickerStyle(.wheel)
      .frame(maxWidth: .infinity)
    }
    .font(.title3)
  }

  private func loadFromBinding() {
    startHour = schedule.startHour
    startMinute = roundedToFive(schedule.startMinute)

    endHour = schedule.endHour
    endMinute = roundedToFive(schedule.endMinute)

    // Ensure constraints on initial load
    adjustEndIfNeededForStartChange()
  }

  private func applySelection() {
    schedule.startHour = startHour
    schedule.startMinute = startMinute
    schedule.endHour = endHour
    schedule.endMinute = endMinute
  }

  private func roundedToFive(_ value: Int) -> Int {
    let remainder = value % 5
    let down = value - remainder
    let up = min(value + (5 - remainder), 55)
    // Choose the nearer multiple; tie rounds up
    if remainder == 0 { return value }
    if value - down < up - value { return down }
    return up
  }

  private func adjustEndIfNeededForStartChange() {
    // If end is before the minimum required end, try to push it forward
    let target = startTotalMinutes + minimumDurationMinutes
    if target <= latestMinuteOfDay && endTotalMinutes < target {
      endHour = target / 60
      endMinute = target % 60
    }
  }

  private func clampToValidEndIfNeeded() {
    // Keep minutes on 5-minute grid (defensive)
    endMinute = roundedToFive(endMinute)

    // If user tries to set an end earlier than allowed, snap to minimum allowed when possible
    let minimumEnd = startTotalMinutes + minimumDurationMinutes
    if minimumEnd <= latestMinuteOfDay && endTotalMinutes < minimumEnd {
      endHour = minimumEnd / 60
      endMinute = minimumEnd % 60
    }
  }
}

#Preview {
  @Previewable @State var isPresented: Bool = true
  @Previewable @State var schedule: BlockedProfileSchedule = .init(
    days: [],
    startHour: 9,
    startMinute: 0,
    endHour: 11,
    endMinute: 0
  )

  return SchedulePicker(schedule: $schedule, isPresented: $isPresented)
}
