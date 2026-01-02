import FamilyControls
import SwiftUI

struct AuthorizationCallout: View {
  @EnvironmentObject var themeManager: ThemeManager

  let authorizationStatus: AuthorizationStatus
  let onAuthorizationHandler: () -> Void

  private var isAuthorized: Bool {
    authorizationStatus == .approved
  }

  var body: some View {
    Group {
      if !isAuthorized {
        Button(action: onAuthorizationHandler) {
          HStack(alignment: .top, spacing: 12) {
            Image(systemName: "exclamationmark.shield.fill")
              .font(.title3)
              .foregroundStyle(.red)
              .padding(10)
              .background(
                Circle()
                  .fill(Color.red.opacity(0.18))
              )

            VStack(alignment: .leading, spacing: 4) {
              Text("Authorization required")
                .font(.headline)
                .foregroundStyle(.primary)

              Text("Authorize Family Controls to enable blocking.")
                .font(.subheadline)
                .foregroundStyle(.secondary)

              HStack(spacing: 6) {
                Text("Tap to authorize")
                  .font(.caption)
                  .fontWeight(.semibold)
                  .foregroundStyle(themeManager.themeColor)

                Image(systemName: "chevron.right")
                  .font(.caption)
                  .foregroundStyle(.secondary)
              }
              .padding(.top, 6)
            }

            Spacer(minLength: 0)
          }
          .padding(16)
          .frame(maxWidth: .infinity, alignment: .leading)
          .background(calloutBackground)
        }
        .buttonStyle(.plain)
        .accessibilityLabel("Authorization required")
        .accessibilityHint("Tap to authorize Family Controls")
      }
    }
  }

  private var calloutBackground: some View {
    RoundedRectangle(cornerRadius: 24, style: .continuous)
      .fill(Color(UIColor.systemBackground))
      .overlay(
        RoundedRectangle(cornerRadius: 24, style: .continuous)
          .fill(.ultraThinMaterial.opacity(0.7))
      )
      .overlay(
        RoundedRectangle(cornerRadius: 24, style: .continuous)
          .stroke(Color.gray.opacity(0.25), lineWidth: 1)
      )
  }
}

#Preview {
  VStack(spacing: 20) {
    AuthorizationCallout(
      authorizationStatus: .denied,
      onAuthorizationHandler: {}
    )
    .environmentObject(ThemeManager.shared)

    AuthorizationCallout(
      authorizationStatus: .approved,
      onAuthorizationHandler: {}
    )
    .environmentObject(ThemeManager.shared)
  }
}
