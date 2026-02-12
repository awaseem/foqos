import SwiftData
import SwiftUI

enum SessionStatus {
  case started(BlockedProfileSession)
  case ended(BlockedProfiles)
  case paused
}

protocol BlockingStrategy {
  static var id: String { get }
  var name: String { get }
  var description: String { get }
  var iconType: String { get }
  var color: Color { get }

  var usesNFC: Bool { get }
  var usesQRCode: Bool { get }
  var hasTimer: Bool { get }
  var hasPauseMode: Bool { get }
  var startsManually: Bool { get }
  var requiresSameCodeToStop: Bool { get }
  var isBeta: Bool { get }

  var hidden: Bool { get }

  // Callback closures session creation
  var onSessionCreation: ((SessionStatus) -> Void)? {
    get set
  }

  var onErrorMessage: ((String) -> Void)? {
    get set
  }

  func getIdentifier() -> String
  func startBlocking(
    context: ModelContext,
    profile: BlockedProfiles,
    forceStart: Bool?
  ) -> (any View)?
  func stopBlocking(context: ModelContext, session: BlockedProfileSession)
    -> (any View)?
}

enum BlockingStrategyTag: String, Hashable {
  case nfc
  case qr
  case timer
  case pause
  case manualStart
  case beta

  var title: String {
    switch self {
    case .nfc:
      return "NFC"
    case .qr:
      return "QR"
    case .timer:
      return "Timer"
    case .pause:
      return "Pause"
    case .manualStart:
      return "Manual Start"
    case .beta:
      return "Beta"
    }
  }
}

extension BlockingStrategy {
  var usesNFC: Bool { false }
  var usesQRCode: Bool { false }
  var hasTimer: Bool { false }
  var hasPauseMode: Bool { false }
  var startsManually: Bool { false }
  var requiresSameCodeToStop: Bool { false }
  var isBeta: Bool { false }

  var tags: [BlockingStrategyTag] {
    var tags: [BlockingStrategyTag] = []

    if usesNFC {
      tags.append(.nfc)
    }

    if usesQRCode {
      tags.append(.qr)
    }

    if hasTimer {
      tags.append(.timer)
    }

    if hasPauseMode {
      tags.append(.pause)
    }

    if startsManually {
      tags.append(.manualStart)
    }

    if isBeta {
      tags.append(.beta)
    }

    return tags
  }
}
