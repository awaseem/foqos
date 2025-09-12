import SwiftUI

struct SchedulePicker: View {
  @Binding var schedule: BlockedProfileSchedule
  @Binding var isPresented: Bool

  private let hours12: [Int] = Array(1...12)
  private let minutes: [Int] = Array(stride(from: 0, through: 55, by: 5))

  @State private var startDisplayHour: Int = 9
  @State private var startMinute: Int = 0
  @State private var startIsPM: Bool = false
  @State private var endDisplayHour: Int = 10
  @State private var endMinute: Int = 0
  @State private var endIsPM: Bool = false
  @State private var selectedDays: [Weekday] = []
  @State private var showStartPicker: Bool = false
  @State private var showEndPicker: Bool = false

  private let minimumDurationMinutes: Int = 60

  private var startTotalMinutes: Int {
    hour12To24(startDisplayHour, isPM: startIsPM) * 60 + startMinute
  }
  private var endTotalMinutes: Int { hour12To24(endDisplayHour, isPM: endIsPM) * 60 + endMinute }

  private var latestMinuteOfDay: Int { 23 * 60 + 55 }

  private var isValid: Bool {
    !selectedDays.isEmpty && endTotalMinutes - startTotalMinutes >= minimumDurationMinutes
  }

  private var validationMessage: String? {
    guard !isValid else { return nil }

    if selectedDays.isEmpty {
      return ""
    }

    if startTotalMinutes > latestMinuteOfDay - minimumDurationMinutes {
      return "Start time must be at least 1 hour before the end of the day."
    }

    return "End time must be at least 1 hour after start time."
  }

  var body: some View {
    NavigationStack {
      Form {
        Section {
          VStack(alignment: .leading, spacing: 12) {
            HStack {
              Spacer()
              Image(systemName: "calendar.badge.clock")
                .font(.largeTitle)
                .foregroundStyle(.secondary)
              Spacer()
            }
            .padding(.vertical, 12)

            Text(
              "Choose when this profile starts and ends. To end early, use the strategy you set up earlier. The schedule must be at least 1 hour long."
            )
            .font(.subheadline)
            .foregroundStyle(.primary)
            .multilineTextAlignment(.center)

            Text(
              "This feature is still in development. If you notice any issues, please let us know."
            )
            .font(.caption)
            .foregroundStyle(.secondary)
            .multilineTextAlignment(.center)
          }
          .padding(.horizontal, 8)
        }

        Section {
          HStack(spacing: 12) {
            ForEach(Weekday.allCases, id: \.rawValue) { day in
              let isSelected = selectedDays.contains(day)
              Button(action: {
                if isSelected {
                  selectedDays.removeAll { $0 == day }
                } else {
                  selectedDays.append(day)
                }

                // Hide time pickers when no days are selected
                if selectedDays.isEmpty {
                  showStartPicker = false
                  showEndPicker = false
                }
              }) {
                Text(shortLabel(for: day))
                  .font(.subheadline)
                  .fontWeight(.semibold)
                  .frame(width: 40, height: 40)
                  .background(isSelected ? Color.blue : Color.clear)
                  .foregroundStyle(isSelected ? Color.white : Color.primary)
                  .overlay(
                    Circle()
                      .stroke(isSelected ? Color.blue : Color.secondary, lineWidth: 1)
                  )
                  .clipShape(Circle())
                  .accessibilityLabel(day.name)
                  .accessibilityAddTraits(isSelected ? .isSelected : [])
              }
              .buttonStyle(.plain)
            }
          }
          .frame(maxWidth: .infinity, alignment: .center)
        } header: {
          Text("Days")
        } footer: {
          if !selectedDays.isEmpty {
            Text("Schedules take 15 minutes to update")
              .font(.caption)
              .foregroundStyle(.secondary)
          }
        }

        Section {
          Button(action: toggleStartPicker) {
            HStack {
              Text("When to start")
              Spacer()
              Text(
                formattedTimeString(hour: startDisplayHour, minute: startMinute, isPM: startIsPM)
              )
              .foregroundStyle(.secondary)
            }
          }
          .buttonStyle(.plain)
          .disabled(selectedDays.isEmpty)

          if showStartPicker {
            timePickers(hour: $startDisplayHour, minute: $startMinute, isPM: $startIsPM)
          }
        } header: {
          Text("Start Time")
        }

        Section {
          Button(action: toggleEndPicker) {
            HStack {
              Text("When to end")
              Spacer()
              Text(formattedTimeString(hour: endDisplayHour, minute: endMinute, isPM: endIsPM))
                .foregroundStyle(.secondary)
            }
          }
          .buttonStyle(.plain)
          .disabled(selectedDays.isEmpty)

          if showEndPicker {
            timePickers(hour: $endDisplayHour, minute: $endMinute, isPM: $endIsPM)
          }
        } header: {
          Text("End Time")
        } footer: {
          if let validationMessage {
            Text(validationMessage)
              .font(.caption)
              .foregroundStyle(.orange)
          }
        }

        Section {
          Button("Remove Schedule") {
            resetToDefault()

            applySelection()
            isPresented = false
          }
          .foregroundStyle(.red)
          .frame(maxWidth: .infinity, alignment: .center)
        } footer: {
          VStack(alignment: .center, spacing: 4) {
            Text(
              "If you're looking for more granularity, you can use Shortcuts. \(Text("[Here is a quick video](https://youtube.com/shorts/1xZeO9lg5f8)").foregroundStyle(.blue))"
            )
            .font(.caption)
            .foregroundStyle(.secondary)
          }
        }
      }
      .navigationTitle("Schedule")
      .navigationBarTitleDisplayMode(.inline)
      .toolbar {
        ToolbarItem(placement: .topBarLeading) {
          Button(action: { isPresented = false }) {
            Image(systemName: "xmark")
          }
          .accessibilityLabel("Cancel")
        }

        ToolbarItem(placement: .topBarTrailing) {
          Button(action: {
            applySelection()
            isPresented = false
          }) {
            Image(systemName: "checkmark")
          }
          .disabled(!isValid)
          .accessibilityLabel("Save")
        }
      }
      .onAppear(perform: loadFromBinding)
      .onChange(of: startDisplayHour) { _, _ in adjustEndIfNeededForStartChange() }
      .onChange(of: startMinute) { _, _ in adjustEndIfNeededForStartChange() }
      .onChange(of: startIsPM) { _, _ in adjustEndIfNeededForStartChange() }
      .onChange(of: endDisplayHour) { _, _ in clampToValidEndIfNeeded() }
      .onChange(of: endMinute) { _, _ in clampToValidEndIfNeeded() }
      .onChange(of: endIsPM) { _, _ in clampToValidEndIfNeeded() }
    }
  }

  @ViewBuilder
  private func timePickers(hour: Binding<Int>, minute: Binding<Int>, isPM: Binding<Bool>)
    -> some View
  {
    HStack {
      Picker("Hour", selection: hour) {
        ForEach(hours12, id: \.self) { h in
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

      Picker("AM/PM", selection: isPM) {
        Text("AM").tag(false)
        Text("PM").tag(true)
      }
      .labelsHidden()
      .pickerStyle(.wheel)
      .frame(maxWidth: .infinity)
    }
    .font(.title3)
  }

  private func loadFromBinding() {
    // Days
    selectedDays = schedule.days

    // Start time
    setDisplay(from24Hour: schedule.startHour, forStart: true)
    startMinute = roundedToFive(schedule.startMinute)

    // End time
    setDisplay(from24Hour: schedule.endHour, forStart: false)
    endMinute = roundedToFive(schedule.endMinute)

    // Ensure constraints on initial load
    adjustEndIfNeededForStartChange()
  }

  private func applySelection() {
    schedule.days = selectedDays.sorted { $0.rawValue < $1.rawValue }

    schedule.startHour = hour12To24(startDisplayHour, isPM: startIsPM)
    schedule.startMinute = startMinute
    schedule.endHour = hour12To24(endDisplayHour, isPM: endIsPM)
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
      let hour24 = target / 60
      endMinute = target % 60
      let converted = from24ToDisplay(hour24)
      endDisplayHour = converted.hour
      endIsPM = converted.isPM
    }
  }

  private func clampToValidEndIfNeeded() {
    // Keep minutes on 5-minute grid (defensive)
    endMinute = roundedToFive(endMinute)

    // If user tries to set an end earlier than allowed, snap to minimum allowed when possible
    let minimumEnd = startTotalMinutes + minimumDurationMinutes
    if minimumEnd <= latestMinuteOfDay && endTotalMinutes < minimumEnd {
      let hour24 = minimumEnd / 60
      endMinute = minimumEnd % 60
      let converted = from24ToDisplay(hour24)
      endDisplayHour = converted.hour
      endIsPM = converted.isPM
    }
  }

  private func setDisplay(from24Hour hour24: Int, forStart: Bool) {
    let converted = from24ToDisplay(hour24)
    if forStart {
      startDisplayHour = converted.hour
      startIsPM = converted.isPM
    } else {
      endDisplayHour = converted.hour
      endIsPM = converted.isPM
    }
  }

  private func from24ToDisplay(_ hour24: Int) -> (hour: Int, isPM: Bool) {
    let isPM = hour24 >= 12
    var hour = hour24 % 12
    if hour == 0 { hour = 12 }
    return (hour, isPM)
  }

  private func hour12To24(_ hour12: Int, isPM: Bool) -> Int {
    if hour12 == 12 { return isPM ? 12 : 0 }
    return isPM ? hour12 + 12 : hour12
  }

  private func shortLabel(for day: Weekday) -> String {
    switch day {
    case .sunday: return "Su"
    case .monday: return "Mo"
    case .tuesday: return "Tu"
    case .wednesday: return "We"
    case .thursday: return "Th"
    case .friday: return "Fr"
    case .saturday: return "Sa"
    }
  }

  private func formattedTimeString(hour: Int, minute: Int, isPM: Bool) -> String {
    "\(hour):\(String(format: "%02d", minute)) \(isPM ? "PM" : "AM")"
  }

  private func toggleStartPicker() {
    withAnimation(.easeInOut) {
      showStartPicker.toggle()
      if showStartPicker { showEndPicker = false }
    }
  }

  private func toggleEndPicker() {
    withAnimation(.easeInOut) {
      showEndPicker.toggle()
      if showEndPicker { showStartPicker = false }
    }
  }

  private func resetToDefault() {
    // Reset to default values: empty days, 9AM-5PM
    selectedDays = []
    startDisplayHour = 9
    startMinute = 0
    startIsPM = false
    endDisplayHour = 5
    endMinute = 0
    endIsPM = true
  }
}

#Preview {
  @Previewable @State var isPresented: Bool = true
  @Previewable @State var schedule: BlockedProfileSchedule = .init(
    days: [],
    startHour: 9,
    startMinute: 0,
    endHour: 11,
    endMinute: 0,
    updatedAt: Date()
  )

  return SchedulePicker(schedule: $schedule, isPresented: $isPresented)
}
