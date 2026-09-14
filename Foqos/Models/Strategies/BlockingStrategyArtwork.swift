// Shared by the strategy picker and widgets; contains no blocking behavior.
enum BlockingStrategyArtwork {
  static func assetName(for strategyID: String?) -> String {
    switch strategyID {
    case "ManualBlockingStrategy": return "ManualLogoSticker"
    case "NFCBlockingStrategy": return "NFCStickerLogo"
    case "NFCManualBlockingStrategy": return "Manual+NFCSticker"
    case "NFCPauseTimerBlockingStrategy": return "NFCPauseSticker"
    case "NFCSoftUnblockBlockingStrategy": return "Soft Unblock + NFC"
    case "NFCTimerBlockingStrategy": return "NFC+TimerSticker"
    case "QRCodeBlockingStrategy": return "QRStickerLogo"
    case "QRManualBlockingStrategy": return "Manual+QRSticker"
    case "QRPauseTimerBlockingStrategy": return "QRPauseSticker"
    case "QRSoftUnblockBlockingStrategy": return "Soft Unblock + QR"
    case "QRTimerBlockingStrategy": return "QR+TimerSticker"
    case "ShortcutTimerBlockingStrategy": return "Manual + Timer"
    default: return "NFCStickerLogo"
    }
  }
}
