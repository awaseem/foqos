import SwiftUI

struct BlockedProfileScheduleSelector: View {
  var schedule: BlockedProfileSchedule
  var buttonAction: () -> Void
  var disabled: Bool = false
  var disabledText: String?

  private var buttonText: String { "Set schedule" }

  private var daysCount: Int { schedule.days.count }

  var body: some View {
    Button(action: buttonAction) {
      HStack {
        Text(buttonText)
        Spacer()
        Image(systemName: "chevron.right")
          .foregroundStyle(.gray)
      }
    }
    .disabled(disabled)

    if let disabledText = disabledText, disabled {
      Text(disabledText)
        .foregroundStyle(.red)
        .padding(.top, 4)
        .font(.caption)
    } else if daysCount == 0 {
      Text("No schedule set")
        .foregroundStyle(.gray)
    } else {
      Text(summaryText)
        .font(.footnote)
        .foregroundStyle(.gray)
        .padding(.top, 4)
    }
  }

  private var summaryText: String {
    let days = schedule.days
      .sorted { $0.rawValue < $1.rawValue }
      .map(shortLabel(for:))
      .joined(separator: " ")

    let start = formattedTimeString(hour24: schedule.startHour, minute: schedule.startMinute)
    let end = formattedTimeString(hour24: schedule.endHour, minute: schedule.endMinute)

    if days.isEmpty {
      return "No schedule set"
    }
    return "\(days) · \(start) - \(end)"
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

  private func formattedTimeString(hour24: Int, minute: Int) -> String {
    var hour = hour24 % 12
    if hour == 0 { hour = 12 }
    let isPM = hour24 >= 12
    return "\(hour):\(String(format: "%02d", minute)) \(isPM ? "PM" : "AM")"
  }
}

#Preview {
  VStack(spacing: 20) {
    BlockedProfileScheduleSelector(
      schedule: .init(
        days: [.monday, .wednesday, .friday], startHour: 9, startMinute: 0, endHour: 17,
        endMinute: 0),
      buttonAction: {}
    )

    BlockedProfileScheduleSelector(
      schedule: .init(days: [], startHour: 9, startMinute: 0, endHour: 17, endMinute: 0),
      buttonAction: {},
      disabled: true,
      disabledText: "Disable the current session to edit schedule"
    )
  }
  .padding()
}
