enum AppIconOption: String, CaseIterable, Identifiable {
  case defaultIcon
  case blue
  case cat
  case pop
  case original

  var id: String { rawValue }

  var displayName: String {
    switch self {
    case .defaultIcon: "Default"
    case .blue: "Blue"
    case .cat: "Cat"
    case .pop: "Pop"
    case .original: "Original"
    }
  }

  var alternateIconName: String? {
    switch self {
    case .defaultIcon: nil
    case .blue: "foqos-icon-blue"
    case .cat: "foqos-icon-cat"
    case .pop: "foqos-icon-pop"
    case .original: "foqos-icon-original"
    }
  }

  var previewAssetName: String {
    switch self {
    case .defaultIcon: "AppIconDefaultPreview"
    case .blue: "AppIconBluePreview"
    case .cat: "AppIconCatPreview"
    case .pop: "AppIconPopPreview"
    case .original: "AppIconOriginalPreview"
    }
  }

  var liveActivityAssetName: String {
    switch self {
    case .defaultIcon: "FoqosStickerLogo"
    case .blue: "LiveActivityAppIconBlue"
    case .cat: "LiveActivityAppIconCat"
    case .pop: "LiveActivityAppIconPop"
    case .original: "LiveActivityAppIconOriginal"
    }
  }
}
