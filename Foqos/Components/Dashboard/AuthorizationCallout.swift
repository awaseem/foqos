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
    if !isAuthorized {
      VStack(spacing: 16) {
        Image(systemName: "exclamationmark.shield.fill")
          .font(.system(size: 48))
          .foregroundColor(.orange)

        VStack(spacing: 8) {
          Text("Authorization Required")
            .font(.headline)
            .fontWeight(.semibold)

          Text(
            "Foqos needs permission to block apps and websites. Please authorize to continue."
          )
          .font(.subheadline)
          .foregroundColor(.secondary)
          .multilineTextAlignment(.center)
        }

        Button(action: onAuthorizationHandler) {
          HStack(spacing: 8) {
            Image(systemName: "checkmark.shield.fill")
            Text("Authorize Now")
              .fontWeight(.semibold)
          }
          .frame(maxWidth: .infinity)
          .padding()
        }
        .buttonStyle(.borderedProminent)
      }
      .padding(20)
      .background(Color(UIColor.systemBackground))
      .overlay(
        RoundedRectangle(cornerRadius: 24)
          .stroke(Color.gray.opacity(0.3), lineWidth: 1)
      )
      .clipShape(RoundedRectangle(cornerRadius: 24))
    }
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
