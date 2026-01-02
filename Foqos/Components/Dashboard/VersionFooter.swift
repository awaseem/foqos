import SwiftUI

struct VersionFooter: View {
  @EnvironmentObject var themeManager: ThemeManager

  let profileIsActive: Bool
  let tapProfileDebugHandler: () -> Void

  var body: some View {
    VStack(spacing: 10) {
      if profileIsActive {
        Button(action: tapProfileDebugHandler) {
          Text("Debug mode")
            .font(.footnote)
            .foregroundColor(themeManager.themeColor)
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
      tapProfileDebugHandler: {}
    )
    .environmentObject(ThemeManager.shared)

    VersionFooter(
      profileIsActive: true,
      tapProfileDebugHandler: {}
    )
    .environmentObject(ThemeManager.shared)
  }
}
