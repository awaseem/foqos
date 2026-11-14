import SwiftUI

struct SessionTimerText: View {
  let timer: SessionTimer

  var text: Text {
    if let range = timer.countdownRange {
      return Text(timerInterval: range, countsDown: true)
    }
    return Text(timerInterval: timer.startTime...Date.distantFuture, countsDown: false)
  }

  var body: some View {
    text.monospacedDigit()
  }
}

#Preview {
  VStack {
    SessionTimerText(timer: SessionTimer(startTime: .now.addingTimeInterval(-15 * 60)))
    SessionTimerText(
      timer: SessionTimer(
        startTime: .now.addingTimeInterval(-15 * 60), endTime: .now.addingTimeInterval(45 * 60)))
  }
}
