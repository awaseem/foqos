import Foundation

// Packed status payload written to the ESP32 companion's status
// characteristic. Layout is shared byte-for-byte with the firmware decoder
// (esp32-companion/src/status_model.cpp); bump the version when it changes.
struct CompanionStatusPayload: Equatable {
  static let version: UInt8 = 1
  static let profileNameMaxBytes = 64
  // version(1) + flags(1) + startEpoch(8) + endEpoch(8) + name(64)
  static let encodedSize = 2 + 8 + 8 + profileNameMaxBytes

  var isActive: Bool
  var isBreakActive: Bool
  var isPauseActive: Bool
  var sessionStartEpoch: Int64
  var expectedEndEpoch: Int64
  var profileName: String

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
