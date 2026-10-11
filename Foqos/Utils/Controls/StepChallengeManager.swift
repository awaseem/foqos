import CoreMotion
import SwiftUI

@MainActor
final class StepChallengeManager: ObservableObject {
  @Published private(set) var steps = 0
  @Published private(set) var status = "Count new steps after you begin."
  private var pedometer: CMPedometer?
  private var startedAt: Date?

  func start() {
    stop()
    steps = 0
    guard CMPedometer.isStepCountingAvailable() else {
      status = "Step counting is unavailable. You can cancel and stop the session instead."
      return
    }
    guard CMPedometer.authorizationStatus() != .denied,
      CMPedometer.authorizationStatus() != .restricted
    else {
      status = "Motion access denied. Enable it in iOS Settings or stop the session instead."
      return
    }
    let start = Date()
    begin(at: start)
    status = "Counting new steps…"
    let pedometer = self.pedometer ?? CMPedometer()
    self.pedometer = pedometer
    pedometer.startUpdates(from: start) { [weak self] data, error in
      Task { @MainActor in
        guard let self, self.startedAt == start else { return }
        if let error {
          self.status = error.localizedDescription
          return
        }
        guard let data, data.startDate >= start.addingTimeInterval(-1) else { return }
        self.accept(steps: data.numberOfSteps.intValue, for: start)
      }
    }
  }

  func begin(at date: Date) {
    steps = 0
    startedAt = date
  }

  func stop() {
    steps = 0
    startedAt = nil
    pedometer?.stopUpdates()
  }

  func accept(steps: Int, for start: Date) {
    guard startedAt == start, steps >= 0 else { return }
    self.steps = max(self.steps, steps)
    status = "\(self.steps) new steps counted."
  }

  static func isComplete(steps: Int, goal: Int) -> Bool {
    (10...10_000).contains(goal) && steps >= goal
  }
}
