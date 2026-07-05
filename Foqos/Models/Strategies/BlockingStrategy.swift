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
  var iconAssetName: String { get }
  var color: Color { get }
  var pickerCategory: BlockingStrategyPickerCategory { get }

  var usesNFC: Bool { get }
  var usesQRCode: Bool { get }
  var hasTimer: Bool { get }
  var hasPauseMode: Bool { get }
  var startsManually: Bool { get }
  var requiresSameCodeToStop: Bool { get }
  var isBeta: Bool { get }
  var startViewPresentationDetents: Set<PresentationDetent> { get }

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

enum BlockingStrategyPickerCategory: String, CaseIterable {
  case mostPopular
  case easyToStart
  case timers
  case forever
  case moreOptions

  var title: String {
    switch self {
    case .mostPopular:
      return "Most popular"
    case .easyToStart:
      return "Easy to start"
    case .timers:
      return "Timers"
    case .forever:
      return "Forever"
    case .moreOptions:
      return "More options"
    }
  }

  var description: String {
    switch self {
    case .mostPopular:
      return "Physical triggers that make starting and stopping more deliberate."
    case .easyToStart:
      return "Start from the app, then choose how intentional stopping should be."
    case .timers:
      return "Choose a duration first, then let the session end automatically."
    case .forever:
      return "Sessions that keep going until you intentionally stop."
    case .moreOptions:
      return "Additional ways to control a focus session."
    }
  }
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

struct BlockingStrategySessionAction {
  let title: String
  let systemImageName: String
  let assetImageName: String?

  static func stop(isEnabled: Bool = true) -> BlockingStrategySessionAction {
    return BlockingStrategySessionAction(
      title: isEnabled ? "Stop" : "Stop Locked",
      systemImageName: isEnabled ? "stop.fill" : "lock.fill",
      assetImageName: nil
    )
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
  var startViewPresentationDetents: Set<PresentationDetent> { [.medium, .large] }

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

  func activeSessionAction(
    isPauseActive: Bool,
    isEnabled: Bool = true
  ) -> BlockingStrategySessionAction {
    guard isEnabled else {
      return BlockingStrategySessionAction(
        title: hasPauseMode ? "Pause Locked" : "Stop Locked",
        systemImageName: "lock.fill",
        assetImageName: nil
      )
    }

    guard hasPauseMode else {
      return .stop()
    }

    return BlockingStrategySessionAction(
      title: isPauseActive ? "End" : "Pause",
      systemImageName: isPauseActive ? "stop.fill" : "pause.fill",
      assetImageName: isPauseActive ? nil : "PauseStickerIcon"
    )
  }
}

struct BlockingStrategyIconImage: View {
  let strategy: BlockingStrategy?

  var body: some View {
    Image(strategy?.iconAssetName ?? "FoqosStickerLogo")
      .resizable()
      .scaledToFit()
  }
}
