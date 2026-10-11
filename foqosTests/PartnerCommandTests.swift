import XCTest

@testable import foqos

final class PartnerCommandTests: XCTestCase {
  func testPartnerCommandsExpireAndRejectFutureDatesAndOversizedMessages() throws {
    let now = Date(timeIntervalSince1970: 1000)
    var command = FamilyCommand(action: .start, createdAt: now)
    XCTAssertTrue(command.isFresh(at: now))
    XCTAssertTrue(command.isFresh(at: now.addingTimeInterval(300)))
    XCTAssertFalse(command.isFresh(at: now.addingTimeInterval(301)))
    XCTAssertFalse(command.isFresh(at: now.addingTimeInterval(-61)))
    command.message = String(repeating: "x", count: 201)
    XCTAssertFalse(command.isFresh(at: now))
    let decoded = try JSONDecoder().decode(FamilyCommand.self, from: JSONEncoder().encode(command))
    XCTAssertEqual(decoded.id, command.id)
    XCTAssertEqual(decoded.action, .start)
  }
}
