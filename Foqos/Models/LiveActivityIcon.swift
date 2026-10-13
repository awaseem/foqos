enum LiveActivityIcon: String, CaseIterable, Identifiable {
  case foqos
  case hourglass
  case timer
  case leaf
  case flame
  case bolt

  var id: String { rawValue }

  var name: String {
    switch self {
    case .foqos: "Foqos"
    case .hourglass: "Hourglass"
    case .timer: "Timer"
    case .leaf: "Leaf"
    case .flame: "Flame"
    case .bolt: "Lightning"
    }
  }

  var symbolName: String? {
    switch self {
    case .foqos: nil
    case .hourglass: "hourglass"
    case .timer: "timer"
    case .leaf: "leaf.fill"
    case .flame: "flame.fill"
    case .bolt: "bolt.fill"
    }
  }
}
