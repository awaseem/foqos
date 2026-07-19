import XCTest

@testable import foqos

// Locks the toggle dedup semantics documented in
// docs/companion-device-protocol.md: 1.5 s debounce, and same-counter
// retransmits dropped within 30 s (counters can repeat after device reboots).
final class CompanionToggleDedupTests: XCTestCase {
  private let epoch = Date(timeIntervalSinceReferenceDate: 1_000)

  private func accepts(
    counter: UInt8?, secondsAfterLast: TimeInterval, lastCounter: UInt8?
  ) -> Bool {
    CompanionDeviceManager.shouldAcceptToggle(
      counter: counter,
      at: epoch.addingTimeInterval(secondsAfterLast),
      lastAcceptedAt: epoch,
      lastCounter: lastCounter
    )
  }

  func testRejectsRapidDoubleTapRegardlessOfCounter() {
    XCTAssertFalse(accepts(counter: 5, secondsAfterLast: 1.0, lastCounter: 4))
    XCTAssertFalse(accepts(counter: nil, secondsAfterLast: 0.2, lastCounter: nil))
  }

  func testRejectsSameCounterRetransmitWithinWindow() {
    XCTAssertFalse(accepts(counter: 7, secondsAfterLast: 10, lastCounter: 7))
    XCTAssertFalse(accepts(counter: 7, secondsAfterLast: 29.9, lastCounter: 7))
  }

  func testAcceptsSameCounterAfterWindowExpires() {
    // A rebooted device restarts its counter; a match after 30 s is a new tap.
    XCTAssertTrue(accepts(counter: 7, secondsAfterLast: 30.1, lastCounter: 7))
  }

  func testAcceptsNewCounterAfterDebounce() {
    XCTAssertTrue(accepts(counter: 8, secondsAfterLast: 2.0, lastCounter: 7))
  }

  func testAcceptsMissingCounterAfterDebounce() {
    // Devices that send no counter byte still get the time debounce only.
    XCTAssertTrue(accepts(counter: nil, secondsAfterLast: 2.0, lastCounter: nil))
  }
}
