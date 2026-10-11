import SwiftUI

struct StepChallengeView: View {
  @ObservedObject var counter: StepChallengeManager
  let goal: Int

  var body: some View {
    Section("Walk before opening") {
      Text("\(counter.steps) of \(goal) new steps")
      ProgressView(value: Double(min(counter.steps, goal)), total: Double(goal))
      Text(counter.status).font(.caption)
      Button("Begin / restart step count") { counter.start() }
      Text(
        "Carry your iPhone. Only steps after Begin count; starting again resets progress. iOS can delay updates. Cancel and stop the session if you cannot walk or Motion access is unavailable."
      )
      .font(.caption)
    }
  }
}
