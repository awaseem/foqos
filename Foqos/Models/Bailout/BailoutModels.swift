import Foundation

enum BailoutTier: String, CaseIterable, Identifiable, Codable, Sendable {
  case tier1 = "tip_developer_support"
  case tier2 = "tip_developer_support_5"
  case tier3 = "tip_developer_support_10"

  var id: String { rawValue }

  var title: String {
    switch self {
    case .tier1: return "Light Stake"
    case .tier2: return "Standard Stake"
    case .tier3: return "Hardcore Stake"
    }
  }

  var defaultPriceString: String {
    switch self {
    case .tier1: return "$0.99"
    case .tier2: return "$4.99"
    case .tier3: return "$9.99"
    }
  }

  var emoji: String {
    switch self {
    case .tier1: return "☕️"
    case .tier2: return "⚡️"
    case .tier3: return "🔥"
    }
  }

  var subtitle: String {
    switch self {
    case .tier1: return "Mild friction against impulse unblocking"
    case .tier2: return "Recommended psychological commitment"
    case .tier3: return "Maximum anti-bypass financial penalty"
    }
  }
}

enum BailoutMode: String, CaseIterable, Identifiable, Codable, Sendable {
  case exhaustedQuota = "exhaustedQuota"
  case alwaysRequired = "alwaysRequired"
  case disabled = "disabled"

  var id: String { rawValue }

  var title: String {
    switch self {
    case .exhaustedQuota: return "When Quota Runs Out"
    case .alwaysRequired: return "Always Required (Strict)"
    case .disabled: return "Disabled"
    }
  }

  var description: String {
    switch self {
    case .exhaustedQuota:
      return "Use your free emergency unblocks first. When exhausted, a bailout stake is required to unlock."
    case .alwaysRequired:
      return "Every emergency unblock requires a financial commitment stake upfront."
    case .disabled:
      return "Traditional free emergency unblocks only (resets every few weeks)."
    }
  }
}

struct BailoutWebhookPayload: Codable, Sendable {
  let event: String
  let timestamp: Date
  let tier: String
  let amountEstimate: String
  let profileName: String?

  init(
    tier: BailoutTier,
    profileName: String? = nil,
    timestamp: Date = Date()
  ) {
    self.event = "foqos_emergency_bailout"
    self.timestamp = timestamp
    self.tier = tier.id
    self.amountEstimate = tier.defaultPriceString
    self.profileName = profileName
  }
}
