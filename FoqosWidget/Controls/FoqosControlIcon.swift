import AppIntents

enum FoqosControlIcon: String, AppEnum {
  case hourglass
  case shield
  case block
  case nfc
  case qrCode
  case timer
  case pause

  static var typeDisplayRepresentation = TypeDisplayRepresentation(name: "Icon")
  static var caseDisplayRepresentations: [Self: DisplayRepresentation] = [
    .hourglass: DisplayRepresentation(title: "Hourglass", image: .init(systemName: "hourglass")),
    .shield: DisplayRepresentation(
      title: "Shield", image: .init(systemName: "shield.lefthalf.filled")),
    .block: DisplayRepresentation(title: "Block", image: .init(systemName: "hand.raised.fill")),
    .nfc: DisplayRepresentation(title: "NFC", image: .init(systemName: "wave.3.right")),
    .qrCode: DisplayRepresentation(title: "QR Code", image: .init(systemName: "qrcode")),
    .timer: DisplayRepresentation(title: "Timer", image: .init(systemName: "timer")),
    .pause: DisplayRepresentation(title: "Pause", image: .init(systemName: "pause.circle.fill")),
  ]

  var systemImage: String {
    switch self {
    case .hourglass: "hourglass"
    case .shield: "shield.lefthalf.filled"
    case .block: "hand.raised.fill"
    case .nfc: "wave.3.right"
    case .qrCode: "qrcode"
    case .timer: "timer"
    case .pause: "pause.circle.fill"
    }
  }
}
