//
//  ShieldConfigurationExtension.swift
//  FoqosShieldConfig
//
//  Created by Ali Waseem on 2025-08-11.
//

import ManagedSettings
import ManagedSettingsUI
import SwiftUI
import UIKit

// Override the functions below to customize the shields used in various situations.
// The system provides a default appearance for any methods that your subclass doesn't override.
// Make sure that your class name matches the NSExtensionPrincipalClass in your Info.plist.
class ShieldConfigurationExtension: ShieldConfigurationDataSource {
  override init() {
    super.init()
    SharedData.debugLog(
      "ShieldConfigurationExtension init bundle=\(Bundle.main.bundleIdentifier ?? "nil") activePauseProfile=\(SharedData.activePauseModeProfileId ?? "nil")"
    )
  }

  override func configuration(shielding application: Application) -> ShieldConfiguration {
    SharedData.debugLog(
      "Shield config requested app=\(application.localizedDisplayName ?? "unknown") activePauseProfile=\(SharedData.activePauseModeProfileId ?? "nil")"
    )

    if let pauseConfiguration = pauseModeConfiguration(for: application, in: nil) {
      SharedData.debugLog(
        "Returning pause shield for app=\(application.localizedDisplayName ?? "unknown")"
      )
      return pauseConfiguration
    }

    SharedData.debugLog(
      "Returning standard shield for app=\(application.localizedDisplayName ?? "unknown")"
    )
    return createCustomShieldConfiguration(
      for: .app, title: application.localizedDisplayName ?? "App")
  }

  override func configuration(shielding application: Application, in category: ActivityCategory)
    -> ShieldConfiguration
  {
    SharedData.debugLog(
      "Shield config requested appInCategory=\(application.localizedDisplayName ?? "unknown") activePauseProfile=\(SharedData.activePauseModeProfileId ?? "nil")"
    )

    if let pauseConfiguration = pauseModeConfiguration(for: application, in: category) {
      SharedData.debugLog(
        "Returning pause shield for category-shielded app=\(application.localizedDisplayName ?? "unknown")"
      )
      return pauseConfiguration
    }

    SharedData.debugLog(
      "Returning standard shield for category-shielded app=\(application.localizedDisplayName ?? "unknown")"
    )
    return createCustomShieldConfiguration(
      for: .app, title: application.localizedDisplayName ?? "App")
  }

  override func configuration(shielding webDomain: WebDomain) -> ShieldConfiguration {
    SharedData.debugLog(
      "Shield config requested webDomain=\(webDomain.domain ?? "unknown") activePauseProfile=\(SharedData.activePauseModeProfileId ?? "nil")"
    )
    return createCustomShieldConfiguration(for: .website, title: webDomain.domain ?? "Website")
  }

  override func configuration(shielding webDomain: WebDomain, in category: ActivityCategory)
    -> ShieldConfiguration
  {
    SharedData.debugLog(
      "Shield config requested webDomainInCategory=\(webDomain.domain ?? "unknown") activePauseProfile=\(SharedData.activePauseModeProfileId ?? "nil")"
    )
    return createCustomShieldConfiguration(for: .website, title: webDomain.domain ?? "Website")
  }

  private func createCustomShieldConfiguration(for type: BlockedContentType, title: String)
    -> ShieldConfiguration
  {
    // Get user's selected theme color
    let brandColor = UIColor(ThemeManager.shared.themeColor)

    // Get random fun message
    let randomMessage = getFunBlockMessage(for: type, title: title)

    // Emoji “icon” (rendered to an image so it works with ShieldConfiguration.icon)
    let emojiIcon = makeEmojiIcon(randomMessage.emoji, size: 96)

    return ShieldConfiguration(
      backgroundBlurStyle: .dark,
      backgroundColor: brandColor,
      icon: emojiIcon,
      title: ShieldConfiguration.Label(
        text: randomMessage.title,
        color: .white
      ),
      subtitle: ShieldConfiguration.Label(
        text: randomMessage.subtitle,
        color: UIColor.white.withAlphaComponent(0.88)
      ),
      primaryButtonLabel: ShieldConfiguration.Label(
        text: randomMessage.buttonText,
        color: .black
      ),
      primaryButtonBackgroundColor: .white,
      secondaryButtonLabel: nil
    )
  }

  private func pauseModeConfiguration(
    for application: Application,
    in category: ActivityCategory?
  ) -> ShieldConfiguration? {
    guard let profileId = SharedData.activePauseModeProfileId else {
      SharedData.debugLog("Pause shield skipped: no active pause profile")
      return nil
    }

    if let token = application.token, SharedData.pauseUnlockedApplicationTokens.contains(token) {
      SharedData.debugLog(
        "Pause shield skipped: app already unlocked app=\(application.localizedDisplayName ?? "unknown") profile=\(profileId)"
      )
      return nil
    }

    if let categoryToken = category?.token,
      SharedData.pauseUnlockedCategoryTokens.contains(categoryToken)
    {
      SharedData.debugLog(
        "Pause shield skipped: category already unlocked app=\(application.localizedDisplayName ?? "unknown") profile=\(profileId)"
      )
      return nil
    }

    if application.token == nil {
      SharedData.debugLog(
        "Pause shield has no app token; using category action fallback app=\(application.localizedDisplayName ?? "unknown") category=\(category?.localizedDisplayName ?? "unknown") profile=\(profileId)"
      )
    }

    guard let snapshot = SharedData.snapshot(for: profileId) else {
      SharedData.debugLog("Pause shield skipped: snapshot missing profile=\(profileId)")
      return nil
    }

    let accessMinutes =
      snapshot.strategyData
      .map { StrategyPauseTimerData.toStrategyPauseTimerData(from: $0).pauseDurationInMinutes }
      ?? StrategyPauseTimerData(pauseDurationInMinutes: 15).pauseDurationInMinutes
    let appName = application.localizedDisplayName ?? "this app"
    let buttonText = "Open for \(accessMinutes)m"

    SharedData.debugLog(
      "Pause shield ready app=\(appName) profile=\(profileId) accessMinutes=\(accessMinutes) selectedApps=\(snapshot.selectedActivity.applicationTokens.count) selectedCategories=\(snapshot.selectedActivity.categoryTokens.count)"
    )

    return ShieldConfiguration(
      backgroundBlurStyle: .dark,
      backgroundColor: UIColor(ThemeManager.shared.themeColor),
      icon: makeEmojiIcon("⏳", size: 96),
      title: ShieldConfiguration.Label(
        text: "Timed access",
        color: .white
      ),
      subtitle: ShieldConfiguration.Label(
        text: "Temporarily open \(appName). Other blocked apps stay protected.",
        color: UIColor.white.withAlphaComponent(0.88)
      ),
      primaryButtonLabel: ShieldConfiguration.Label(
        text: buttonText,
        color: .black
      ),
      primaryButtonBackgroundColor: .white,
      secondaryButtonLabel: ShieldConfiguration.Label(
        text: "Back",
        color: .white
      )
    )
  }

  private func getFunBlockMessage(for _: BlockedContentType, title: String) -> (
    emoji: String, title: String, subtitle: String, buttonText: String
  ) {
    typealias FunMessage = (emoji: String, title: String, subtitle: String, buttonText: String)

    // Curated message "bundles" where the emoji and copy are designed to match.
    // This keeps things fun without feeling chaotic or mismatched.
    let messages: [FunMessage] = [
      ("📵", "Not right now", "\(title) can wait. You’re choosing your time on purpose.", "Back"),
      ("🧠", "Brain check", "Do you actually want \(title)… or was it autopilot?", "Return"),
      (
        "🎯", "Stay on target", "One small step toward your goal first. Then decide on \(title).",
        "Continue"
      ),
      (
        "⏳", "Give it 2 minutes", "Finish the next tiny thing. \(title) will still be there after.",
        "Keep going"
      ),
      ("🛡️", "Shield up", "Focus is protected. You’ve got this.", "Onward"),
      ("🔒", "Locked in", "This block is temporary. Your momentum isn’t.", "Stay here"),
      ("🧱", "Boundary set", "You made a plan. This is you sticking to it.", "Back"),
      ("✨", "Glow mode", "You’re building attention — that’s the real flex.", "Nice"),
      ("🫶", "Be kind to you", "No shame. Just a gentle nudge back to what matters.", "Got it"),
      (
        "🌐", "Not this detour", "\(title) isn’t part of the mission right now.", "Return"
      ),
      (
        "🕸️", "Avoid the trap", "One click turns into twenty. Let’s not.", "Back"
      ),
      ("🛡️", "Protected zone", "We’re keeping your attention where you wanted it.", "Got it"),
      ("🔒", "Locked in", "This is a temporary block for a long-term win.", "Return"),
      (
        "🎯", "Back to the task", "Close the detour. Finish the task. Then come back on purpose.",
        "Back to work"
      ),
      (
        "⏳", "Protect the time", "A few minutes can become an hour. Keep your momentum.",
        "Stay focused"
      ),
      ("📵", "Not missing anything", "You’re not missing anything important right now.", "Back"),
      ("✨", "Momentum mode", "Tiny choices like this add up fast.", "Continue"),
    ]
    guard !messages.isEmpty else { return ("🧠", "Quick pause", "Not right now.", "Back") }

    let comps = Calendar.current.dateComponents([.year, .month, .day], from: Date())
    let dayKey =
      (comps.year ?? 0) * 10_000
      + (comps.month ?? 0) * 100
      + (comps.day ?? 0)

    let seed = Int(stableSeed(for: title) % UInt64(Int.max)) ^ dayKey
    let idx = abs(seed) % messages.count

    return messages[idx]
  }

  private func stableSeed(for title: String) -> UInt64 {
    // FNV-1a 64-bit over unicode scalars (deterministic across runs/devices).
    var hash: UInt64 = 14_695_981_039_346_656_037
    for scalar in title.unicodeScalars {
      hash ^= UInt64(scalar.value)
      hash &*= 1_099_511_628_211
    }
    return hash
  }

  private func makeEmojiIcon(_ emoji: String, size: CGFloat) -> UIImage? {
    let renderer = UIGraphicsImageRenderer(size: CGSize(width: size, height: size))
    return renderer.image { _ in
      let paragraph = NSMutableParagraphStyle()
      paragraph.alignment = .center

      let attributes: [NSAttributedString.Key: Any] = [
        .font: UIFont.systemFont(ofSize: size * 0.78),
        .paragraphStyle: paragraph,
      ]

      let rect = CGRect(x: 0, y: 0, width: size, height: size)
      let attributed = NSAttributedString(string: emoji, attributes: attributes)
      let bounds = attributed.boundingRect(
        with: rect.size,
        options: [.usesLineFragmentOrigin, .usesFontLeading],
        context: nil
      )

      // Vertically center emoji
      let drawRect = CGRect(
        x: rect.minX,
        y: rect.minY + (rect.height - bounds.height) / 2,
        width: rect.width,
        height: bounds.height
      )
      attributed.draw(in: drawRect)
    }
  }
}

enum BlockedContentType {
  case app
  case website
}
