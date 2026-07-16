import XCTest

@testable import foqos

final class CompanionStatusPayloadTests: XCTestCase {
  // Golden v2 payload shared byte-for-byte with the firmware decoder tests
  // (foqos-companion repo, test/test_status_model/test_main.cpp).
  private var goldenBytes: [UInt8] {
    var bytes: [UInt8] = [
      0x02,  // version
      0x01,  // flags: active
      0x00, 0xCA, 0x9A, 0x3B, 0, 0, 0, 0,  // start epoch 1000000000 LE
      0x58, 0xCC, 0x9A, 0x3B, 0, 0, 0, 0,  // end epoch 1000000600 LE
    ]
    bytes.append(contentsOf: Array("Work".utf8))
    bytes.append(contentsOf: [UInt8](repeating: 0, count: 64 - 4))
    bytes.append(contentsOf: [12, 0])  // streak 12 LE
    bytes.append(contentsOf: [0x08, 0x34, 0, 0])  // today 13320s LE
    for minutes in [30, 60, 0, 45, 90, 120, 222] as [UInt16] {
      bytes.append(UInt8(minutes & 0xFF))
      bytes.append(UInt8(minutes >> 8))
    }
    return bytes
  }

  func testEncodedLayoutMatchesGoldenVector() {
    let payload = CompanionStatusPayload(
      isActive: true,
      isBreakActive: false,
      isPauseActive: false,
      sessionStartEpoch: 1_000_000_000,
      expectedEndEpoch: 1_000_000_600,
      profileName: "Work",
      streakDays: 12,
      todayFocusSeconds: 13320,
      weekMinutes: [30, 60, 0, 45, 90, 120, 222]
    )

    XCTAssertEqual([UInt8](payload.encoded()), goldenBytes)
  }

  func testStatsDefaultToZero() {
    let bytes = [UInt8](CompanionStatusPayload.inactive.encoded())
    XCTAssertEqual(bytes.count, CompanionStatusPayload.encodedSize)
    XCTAssertTrue(bytes[82...].allSatisfy { $0 == 0 })
  }

  func testWeekMinutesPadsAndTruncatesToSevenEntries() {
    var payload = CompanionStatusPayload.inactive
    payload.weekMinutes = [1, 2]  // short: pads with zeros
    XCTAssertEqual(payload.encoded().count, CompanionStatusPayload.encodedSize)
    payload.weekMinutes = Array(repeating: 9, count: 12)  // long: truncates
    XCTAssertEqual(payload.encoded().count, CompanionStatusPayload.encodedSize)
  }

  func testEncodedSizeIsAlwaysFixed() {
    let payloads = [
      CompanionStatusPayload.inactive,
      CompanionStatusPayload(
        isActive: true,
        isBreakActive: true,
        isPauseActive: true,
        sessionStartEpoch: .max,
        expectedEndEpoch: .max,
        profileName: String(repeating: "long", count: 100)
      ),
    ]
    for payload in payloads {
      XCTAssertEqual(payload.encoded().count, CompanionStatusPayload.encodedSize)
    }
    XCTAssertEqual(CompanionStatusPayload.encodedSize, 102)
  }

  func testFlagCombinations() {
    let combos: [(Bool, Bool, Bool, UInt8)] = [
      (false, false, false, 0b000),
      (true, false, false, 0b001),
      (true, true, false, 0b011),
      (true, false, true, 0b101),
      (true, true, true, 0b111),
    ]
    for (active, breakActive, pauseActive, expectedFlags) in combos {
      let payload = CompanionStatusPayload(
        isActive: active,
        isBreakActive: breakActive,
        isPauseActive: pauseActive,
        sessionStartEpoch: 0,
        expectedEndEpoch: 0,
        profileName: ""
      )
      XCTAssertEqual([UInt8](payload.encoded())[1], expectedFlags)
    }
  }

  func testInactivePayloadIsAllZerosAfterVersion() {
    let bytes = [UInt8](CompanionStatusPayload.inactive.encoded())
    XCTAssertEqual(bytes[0], 2)
    XCTAssertTrue(bytes.dropFirst().allSatisfy { $0 == 0 })
  }

  func testNameTruncationDoesNotSplitMultibyteCharacter() {
    // 63 ASCII bytes followed by a 2-byte scalar: truncating at 64 bytes
    // blindly would leave a dangling UTF-8 continuation byte.
    let name = String(repeating: "a", count: 63) + "é"
    let payload = CompanionStatusPayload(
      isActive: true,
      isBreakActive: false,
      isPauseActive: false,
      sessionStartEpoch: 0,
      expectedEndEpoch: 0,
      profileName: name
    )

    let bytes = [UInt8](payload.encoded())
    let nameField = Array(bytes[18..<82])
    XCTAssertEqual(nameField.count, 64)
    XCTAssertEqual(nameField[62], UInt8(ascii: "a"))
    // The é must be dropped entirely, not half-written.
    XCTAssertEqual(nameField[63], 0)

    let decoded = String(decoding: nameField.prefix(while: { $0 != 0 }), as: UTF8.self)
    XCTAssertEqual(decoded, String(repeating: "a", count: 63))
  }

  func testLongNameTruncatesToSixtyFourBytes() {
    let payload = CompanionStatusPayload(
      isActive: true,
      isBreakActive: false,
      isPauseActive: false,
      sessionStartEpoch: 0,
      expectedEndEpoch: 0,
      profileName: String(repeating: "x", count: 200)
    )

    let bytes = [UInt8](payload.encoded())
    XCTAssertEqual(bytes.count, 102)
    XCTAssertTrue(bytes[18..<82].allSatisfy { $0 == UInt8(ascii: "x") })
  }

  func testNegativeEpochsRoundTripAsLittleEndianTwosComplement() {
    let payload = CompanionStatusPayload(
      isActive: true,
      isBreakActive: false,
      isPauseActive: false,
      sessionStartEpoch: -1,
      expectedEndEpoch: Int64.min,
      profileName: ""
    )

    let bytes = [UInt8](payload.encoded())
    XCTAssertTrue(bytes[2...9].allSatisfy { $0 == 0xFF })
    XCTAssertEqual(Array(bytes[10...16]), [UInt8](repeating: 0, count: 7))
    XCTAssertEqual(bytes[17], 0x80)
  }
}
