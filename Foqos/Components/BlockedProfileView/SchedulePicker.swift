import SwiftUI

struct SchedulePicker: View {
  @EnvironmentObject var themeManager: ThemeManager

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

  private var durationMinutes: Int {
    // If end is before start, it's a cross-day schedule
    if endTotalMinutes <= startTotalMinutes {
      // Duration spans to next day: (minutes until midnight) + (minutes from midnight to end)
      return (24 * 60 - startTotalMinutes) + endTotalMinutes
    }
    return endTotalMinutes - startTotalMinutes
  }

  private var isValid: Bool {
    !selectedDays.isEmpty && durationMinutes >= minimumDurationMinutes
  }

  private var validationMessage: String? {
    guard !isValid else { return nil }

    if selectedDays.isEmpty {
      return ""
    }

    return "Schedule must be at least 1 hour long."
  }

  private var nextScheduleStart: Date? {
    guard !selectedDays.isEmpty else { return nil }

    let calendar = Calendar.current
    let now = Date()
    let bufferTime = now.addingTimeInterval(15 * 60)  // 15 minute buffer

    // Get the start time components
    let startHour24 = hour12To24(startDisplayHour, isPM: startIsPM)

    // Try to find the next occurrence within the next 7 days
    for daysAhead in 0..<7 {
      guard let candidateDate = calendar.date(byAdding: .day, value: daysAhead, to: bufferTime)
      else {
        continue
      }

      // Check if this day is in our selected days
      let candidateWeekdayRaw = calendar.component(.weekday, from: candidateDate)
      guard let candidateWeekday = Weekday(rawValue: candidateWeekdayRaw),
        selectedDays.contains(candidateWeekday)
      else {
        continue
      }

      // Create the actual start time for this candidate day
      guard
        let scheduleStartTime = calendar.date(
          bySettingHour: startHour24,
          minute: startMinute,
          second: 0,
          of: candidateDate
        )
      else {
        continue
      }

      // If this schedule start time is after our buffer time, we found it
      if scheduleStartTime >= bufferTime {
        return scheduleStartTime
      }
    }

    return nil
  }

  private var nextStartMessage: String? {
    guard let nextStart = nextScheduleStart else { return nil }

    let calendar = Calendar.current
    let formatter = DateFormatter()

    // Check if it's today or within this week for better formatting
    if calendar.isDateInToday(nextStart) {
      formatter.dateFormat = "'Today at' h:mm a"
    } else if calendar.isDateInTomorrow(nextStart) {
      formatter.dateFormat = "'Tomorrow at' h:mm a"
    } else {
      formatter.dateFormat = "EEEE, MMM d 'at' h:mm a"
    }

    return "Next start: \(formatter.string(from: nextStart))"
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

            if let message = nextStartMessage {
              HStack(spacing: 8) {
                Image(systemName: "info.circle")
                  .foregroundStyle(.secondary)
                  .font(.subheadline)

                Text(message)
                  .font(.subheadline)
                  .foregroundStyle(.secondary)
              }
              .frame(maxWidth: .infinity, alignment: .center)
              .padding(.vertical, 4)
            }
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
                  .background(isSelected ? themeManager.themeColor : Color.clear)
                  .foregroundStyle(isSelected ? Color.white : Color.primary)
                  .overlay(
                    Circle()
                      .stroke(isSelected ? themeManager.themeColor : Color.secondary, lineWidth: 1)
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
              "If you're looking for more granularity, you can use Shortcuts. \(Text("[Here is a quick video](https://youtube.com/shorts/1xZeO9lg5f8)").foregroundStyle(themeManager.themeColor))"
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
