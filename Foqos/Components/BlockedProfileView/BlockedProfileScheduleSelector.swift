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
      Text(schedule.summaryText)
        .font(.footnote)
        .foregroundStyle(.gray)
        .padding(.top, 4)
    }
  }
}

#Preview {
  VStack(spacing: 20) {
    BlockedProfileScheduleSelector(
      schedule: .init(
        days: [.monday, .wednesday, .friday], startHour: 9, startMinute: 0, endHour: 17,
        endMinute: 0, updatedAt: Date()),
      buttonAction: {}
    )

    BlockedProfileScheduleSelector(
      schedule: .init(
        days: [], startHour: 9, startMinute: 0, endHour: 17, endMinute: 0, updatedAt: Date()),
      buttonAction: {},
      disabled: true,
      disabledText: "Disable the current session to edit schedule"
    )
  }
  .padding()
}
