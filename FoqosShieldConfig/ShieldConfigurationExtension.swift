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
  override func configuration(shielding application: Application) -> ShieldConfiguration {
    if let pauseShield = pauseModeConfiguration(for: application) {
      return pauseShield
    }
    return createCustomShieldConfiguration(
      for: .app, title: application.localizedDisplayName ?? "App")
  }

  override func configuration(shielding application: Application, in category: ActivityCategory)
    -> ShieldConfiguration
  {
    if let pauseShield = pauseModeConfiguration(for: application) {
      return pauseShield
    }
    return createCustomShieldConfiguration(
      for: .app, title: application.localizedDisplayName ?? "App")
  }

  override func configuration(shielding webDomain: WebDomain) -> ShieldConfiguration {
    return createCustomShieldConfiguration(for: .website, title: webDomain.domain ?? "Website")
  }

  override func configuration(shielding webDomain: WebDomain, in category: ActivityCategory)
    -> ShieldConfiguration
  {
    return createCustomShieldConfiguration(for: .website, title: webDomain.domain ?? "Website")
  }

  // MARK: – Pause Mode Shield

  /// Returns a pause-mode `ShieldConfiguration` if the active session uses `PauseBlockingStrategy`,
  /// or `nil` if the normal blocking shield should be shown instead.
  private func pauseModeConfiguration(for application: Application) -> ShieldConfiguration? {
    guard let profileId = SharedData.pauseModeActiveProfileId else { return nil }

    // bundleIdentifier is the stable, unique key per app.
    // If nil (rare edge case), fall through to the normal shield.
    guard let bundleId = application.bundleIdentifier else { return nil }

    let brandColor = UIColor(ThemeManager.shared.themeColor)
    let appName = application.localizedDisplayName ?? "App"

    // Already unlocked this session — ManagedSettings was updated by ShieldAction,
    // but show the normal shield as a defensive fallback if it appears again.
    if SharedData.pauseUnlockedApps.contains(bundleId) {
      return nil
    }

    // Read configured delay from the profile's strategyData
    let delaySeconds: Int = {
      guard let snap = SharedData.snapshot(for: profileId),
        let data = snap.strategyData
      else { return 5 }
      return StrategyPauseDelayData.toStrategyPauseDelayData(from: data).delaySeconds
    }()

    // Start per-app timer on first appearance
    if SharedData.pauseTimer(for: bundleId) == nil {
      SharedData.startPauseTimer(for: bundleId)
    }

    let elapsed = SharedData.elapsedPauseTime(for: bundleId)
    // Use ceil so we never show "Open (in 0s)" while ShieldAction would still reject the tap
    let remaining = max(0, Int(ceil(Double(delaySeconds) - elapsed)))

    // Schedule exactly one reload for when this app's countdown expires.
    // Multiple asyncAfters across different apps are fine — system coalesces reloadConfiguration calls.
    if remaining > 0 {
      DispatchQueue.main.asyncAfter(deadline: .now() + Double(remaining) + 0.1) {
        ShieldConfigurationDataSource().reloadConfiguration()
      }
    }

    let buttonText = remaining > 0 ? "Open (in \(remaining)s)" : "Open"

    return ShieldConfiguration(
      backgroundBlurStyle: .dark,
      backgroundColor: brandColor,
      icon: makeEmojiIcon("⏳", size: 96),
      title: ShieldConfiguration.Label(text: "Why am I checking?", color: .white),
      subtitle: ShieldConfiguration.Label(
        text: appName, color: UIColor.white.withAlphaComponent(0.88)),
      primaryButtonLabel: ShieldConfiguration.Label(text: buttonText, color: .black),
      primaryButtonBackgroundColor: .white,
      secondaryButtonLabel: nil
    )
  }

  // MARK: – Standard Blocking Shield

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
