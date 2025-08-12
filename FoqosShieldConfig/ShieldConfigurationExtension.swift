//
//  ShieldConfigurationExtension.swift
//  FoqosShieldConfig
//
//  Created by Ali Waseem on 2025-08-11.
//

import ManagedSettings
import ManagedSettingsUI
import UIKit

// Override the functions below to customize the shields used in various situations.
// The system provides a default appearance for any methods that your subclass doesn't override.
// Make sure that your class name matches the NSExtensionPrincipalClass in your Info.plist.
class ShieldConfigurationExtension: ShieldConfigurationDataSource {
  override func configuration(shielding application: Application) -> ShieldConfiguration {
    return createCustomShieldConfiguration(
      for: .app, title: application.localizedDisplayName ?? "App")
  }

  override func configuration(shielding application: Application, in category: ActivityCategory)
    -> ShieldConfiguration
  {
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

  private func createCustomShieldConfiguration(for type: BlockedContentType, title: String)
    -> ShieldConfiguration
  {
    // Create custom icon - use SF Symbol for app/website
    let iconImage: UIImage?
    if type == .app {
      iconImage = UIImage(systemName: "app.badge.fill")?.withRenderingMode(.alwaysTemplate)
    } else {
      iconImage = UIImage(systemName: "globe")?.withRenderingMode(.alwaysTemplate)
    }

    // Foqos brand color - purple
    let brandColor = UIColor(red: 0.643, green: 0.204, blue: 0.922, alpha: 1.0)

    return ShieldConfiguration(
      backgroundBlurStyle: .systemUltraThinMaterial,
      backgroundColor: UIColor.systemBackground,
      icon: iconImage,
      title: ShieldConfiguration.Label(
        text: "Focus Active",
        color: UIColor.label
      ),
      subtitle: ShieldConfiguration.Label(
        text:
          "You're in a focus session. \(title) is blocked to help you stay productive. Stay focused!",
        color: UIColor.secondaryLabel
      ),
      primaryButtonLabel: ShieldConfiguration.Label(
        text: "Stay Focused",
        color: .white
      ),
      primaryButtonBackgroundColor: brandColor,
      secondaryButtonLabel: nil
    )
  }
}

enum BlockedContentType {
  case app
  case website
}
