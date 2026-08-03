import Foundation

enum TLSClientHelloParseResult {
  case hostname(String)
  case needMoreData(Int)
  case notClientHello
}

enum TLSClientHelloParser {
  static let initialByteCount = 5
  static let maximumByteCount = 65_535

  static func parse(_ data: Data) -> TLSClientHelloParseResult {
    let bytes = [UInt8](data)

    guard bytes.count >= initialByteCount else {
      return .needMoreData(initialByteCount)
    }

    var handshakeBytes: [UInt8] = []
    var recordOffset = 0

    while recordOffset < bytes.count {
      let recordHeaderEnd = recordOffset + 5
      guard recordHeaderEnd <= bytes.count else {
        return requiredBytes(recordHeaderEnd)
      }

      guard bytes[recordOffset] == 22 else {
        return .notClientHello
      }

      let recordLength = integer(bytes[recordOffset + 3], bytes[recordOffset + 4])
      let recordEnd = recordHeaderEnd + recordLength
      guard recordEnd <= bytes.count else {
        return requiredBytes(recordEnd)
      }

      handshakeBytes.append(contentsOf: bytes[recordHeaderEnd..<recordEnd])

      if handshakeBytes.count >= 4 {
        guard handshakeBytes[0] == 1 else {
          return .notClientHello
        }

        let handshakeLength = integer(
          handshakeBytes[1],
          handshakeBytes[2],
          handshakeBytes[3]
        )
        let handshakeEnd = 4 + handshakeLength

        if handshakeBytes.count >= handshakeEnd {
          return parseServerName(Array(handshakeBytes[..<handshakeEnd]))
        }
      }

      recordOffset = recordEnd
    }

    return requiredBytes(recordOffset + 5)
  }

  private static func parseServerName(_ bytes: [UInt8]) -> TLSClientHelloParseResult {
    var offset = 4

    guard advance(&offset, by: 2 + 32, within: bytes) else {
      return .notClientHello
    }

    guard let sessionIDLength = byte(at: offset, in: bytes) else {
      return .notClientHello
    }
    offset += 1
    guard advance(&offset, by: Int(sessionIDLength), within: bytes) else {
      return .notClientHello
    }

    guard let cipherSuiteLength = uint16(at: offset, in: bytes) else {
      return .notClientHello
    }
    offset += 2
    guard advance(&offset, by: cipherSuiteLength, within: bytes) else {
      return .notClientHello
    }

    guard let compressionLength = byte(at: offset, in: bytes) else {
      return .notClientHello
    }
    offset += 1
    guard advance(&offset, by: Int(compressionLength), within: bytes) else {
      return .notClientHello
    }

    guard let extensionsLength = uint16(at: offset, in: bytes) else {
      return .notClientHello
    }
    offset += 2
    let extensionsEnd = offset + extensionsLength
    guard extensionsEnd <= bytes.count else {
      return .notClientHello
    }

    while offset + 4 <= extensionsEnd {
      guard
        let extensionType = uint16(at: offset, in: bytes),
        let extensionLength = uint16(at: offset + 2, in: bytes)
      else {
        return .notClientHello
      }
      offset += 4
      let extensionEnd = offset + extensionLength
      guard extensionEnd <= extensionsEnd else {
        return .notClientHello
      }

      if extensionType == 0 {
        return parseServerNameExtension(Array(bytes[offset..<extensionEnd]))
      }

      offset = extensionEnd
    }

    return .notClientHello
  }

  private static func parseServerNameExtension(_ bytes: [UInt8]) -> TLSClientHelloParseResult {
    guard let listLength = uint16(at: 0, in: bytes), listLength + 2 <= bytes.count else {
      return .notClientHello
    }

    var offset = 2
    let listEnd = offset + listLength

    while offset + 3 <= listEnd {
      let nameType = bytes[offset]
      guard let nameLength = uint16(at: offset + 1, in: bytes) else {
        return .notClientHello
      }
      offset += 3
      let nameEnd = offset + nameLength
      guard nameEnd <= listEnd else {
        return .notClientHello
      }

      if nameType == 0,
        let hostname = String(bytes: bytes[offset..<nameEnd], encoding: .utf8)
      {
        return .hostname(normalize(hostname))
      }

      offset = nameEnd
    }

    return .notClientHello
  }

  private static func requiredBytes(_ count: Int) -> TLSClientHelloParseResult {
    guard count <= maximumByteCount else {
      return .notClientHello
    }

    return .needMoreData(count)
  }

  private static func byte(at offset: Int, in bytes: [UInt8]) -> UInt8? {
    guard offset < bytes.count else {
      return nil
    }

    return bytes[offset]
  }

  private static func uint16(at offset: Int, in bytes: [UInt8]) -> Int? {
    guard offset + 1 < bytes.count else {
      return nil
    }

    return integer(bytes[offset], bytes[offset + 1])
  }

  private static func integer(_ high: UInt8, _ low: UInt8) -> Int {
    Int(high) << 8 | Int(low)
  }

  private static func integer(_ first: UInt8, _ second: UInt8, _ third: UInt8) -> Int {
    Int(first) << 16 | Int(second) << 8 | Int(third)
  }

  private static func advance(_ offset: inout Int, by count: Int, within bytes: [UInt8]) -> Bool {
    guard count >= 0, offset + count <= bytes.count else {
      return false
    }

    offset += count
    return true
  }

  private static func normalize(_ hostname: String) -> String {
    var normalized = hostname.lowercased()

    while normalized.hasSuffix(".") {
      normalized.removeLast()
    }

    return normalized
  }
}
