import FamilyControls
import SwiftUI

struct VersionFooter: View {
  @EnvironmentObject var themeManager: ThemeManager

  let profileIsActive: Bool
  let tapProfileDebugHandler: () -> Void

  let authorizationStatus: AuthorizationStatus
  let onAuthorizationHandler: () -> Void

  private var isAuthorized: Bool {
    authorizationStatus == .approved
  }

  var body: some View {
    VStack(spacing: 10) {
      HStack(alignment: .center, spacing: 4) {
        if isAuthorized {
          HStack(spacing: 8) {
            Circle()
              .fill(.green)
              .frame(width: 8, height: 8)
            Text("All systems functional")
              .font(.footnote)
              .foregroundColor(.secondary)
          }
        } else {
          Button(action: onAuthorizationHandler) {
            HStack(spacing: 6) {
              Circle()
                .fill(.red)
                .frame(width: 8, height: 8)
              Text("Authorization required. Tap to authorize.")
                .font(.footnote)
            }
          }
          .foregroundColor(.red)
        }
      }

      Text("Made with ❤️ in Calgary, AB 🇨🇦")
        .font(.footnote)
        .foregroundColor(.secondary)

      if profileIsActive {
        Button(action: tapProfileDebugHandler) {
          Text("Debug mode")
            .font(.footnote)
            .foregroundColor(.blue)
        }
      }
    }
    .padding(.bottom, 8)
  }
}

#Preview {
  VStack(spacing: 20) {
    VersionFooter(
      profileIsActive: false,
      tapProfileDebugHandler: {},
      authorizationStatus: .approved,
      onAuthorizationHandler: {}
    )
    .environmentObject(ThemeManager.shared)

    VersionFooter(
      profileIsActive: false,
      tapProfileDebugHandler: {},
      authorizationStatus: .denied,
      onAuthorizationHandler: {}
    )
    .environmentObject(ThemeManager.shared)

    VersionFooter(
      profileIsActive: true,
      tapProfileDebugHandler: {},
      authorizationStatus: .approved,
      onAuthorizationHandler: {}
    )
    .environmentObject(ThemeManager.shared)
  }
}
