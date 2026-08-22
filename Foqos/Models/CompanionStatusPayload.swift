import Foundation

// Packed status payload written to the companion device's status
// characteristic. The byte layout is the contract documented in
// docs/companion-device-protocol.md; bump the version when it changes.
struct CompanionStatusPayload: Equatable {
  static let version: UInt8 = 2
  static let profileNameMaxBytes = 64
  static let weekDayCount = 7
  // version(1) + flags(1) + startEpoch(8) + endEpoch(8) + name(64)
  //   + streak(2) + todaySeconds(4) + weekMinutes(7*2)
  static let encodedSize = 2 + 8 + 8 + profileNameMaxBytes + 2 + 4 + weekDayCount * 2

  var isActive: Bool
  var isBreakActive: Bool
  var isPauseActive: Bool
  var sessionStartEpoch: Int64
  var expectedEndEpoch: Int64
  var profileName: String
  var streakDays: UInt16 = 0
  var todayFocusSeconds: UInt32 = 0
  var weekMinutes: [UInt16] = []  // oldest first, last entry = today

  static let inactive = CompanionStatusPayload(
    isActive: false,
    isBreakActive: false,
    isPauseActive: false,
    sessionStartEpoch: 0,
    expectedEndEpoch: 0,
    profileName: ""
  )

  func encoded() -> Data {
    var data = Data(capacity: Self.encodedSize)
    data.append(Self.version)

    var flags: UInt8 = 0
    if isActive { flags |= 1 << 0 }
    if isBreakActive { flags |= 1 << 1 }
    if isPauseActive { flags |= 1 << 2 }
    data.append(flags)

    appendLittleEndian(sessionStartEpoch, to: &data)
    appendLittleEndian(expectedEndEpoch, to: &data)
    data.append(encodedProfileName())

    withUnsafeBytes(of: streakDays.littleEndian) { data.append(contentsOf: $0) }
    withUnsafeBytes(of: todayFocusSeconds.littleEndian) { data.append(contentsOf: $0) }
    for day in 0..<Self.weekDayCount {
      let minutes = day < weekMinutes.count ? weekMinutes[day] : 0
      withUnsafeBytes(of: minutes.littleEndian) { data.append(contentsOf: $0) }
    }

    return data
  }

  // UTF-8 bytes truncated at a scalar boundary so the firmware never sees a
  // dangling continuation byte, then null-padded to the fixed field width.
  private func encodedProfileName() -> Data {
    var bytes = Data(capacity: Self.profileNameMaxBytes)
    for scalar in profileName.unicodeScalars {
      let encoded = Array(String(scalar).utf8)
      if bytes.count + encoded.count > Self.profileNameMaxBytes { break }
      bytes.append(contentsOf: encoded)
    }
    bytes.append(Data(repeating: 0, count: Self.profileNameMaxBytes - bytes.count))
    return bytes
  }

  private func appendLittleEndian(_ value: Int64, to data: inout Data) {
    withUnsafeBytes(of: value.littleEndian) { data.append(contentsOf: $0) }
  }
}
