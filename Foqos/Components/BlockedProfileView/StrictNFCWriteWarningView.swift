import SwiftUI

struct StrictNFCWriteWarningView: View {
  @EnvironmentObject private var themeManager: ThemeManager

  let profileName: String
  let onCancel: () -> Void
  let onContinue: () -> Void

  var body: some View {
    ScrollView {
      VStack(spacing: 24) {
        Image("StopStrictSticker")
          .resizable()
          .scaledToFit()
          .frame(width: 150, height: 150)
          .accessibilityHidden(true)

        VStack(spacing: 12) {
          Text("Before You Write")
            .font(.title2)
            .fontWeight(.bold)
            .multilineTextAlignment(.center)

          strictModeWarning
            .font(.body)
            .foregroundStyle(.secondary)
            .multilineTextAlignment(.center)
            .fixedSize(horizontal: false, vertical: true)

          Text(convenienceText)
            .font(.footnote)
            .foregroundStyle(.secondary)
            .multilineTextAlignment(.center)
            .fixedSize(horizontal: false, vertical: true)
        }

        VStack(spacing: 12) {
          ActionButton(
            title: "Never mind",
            backgroundColor: themeManager.themeColor,
            iconName: "xmark"
          ) {
            onCancel()
          }

          Button(action: onContinue) {
            Text("Continue")
              .font(.headline)
              .foregroundStyle(.primary)
              .frame(maxWidth: .infinity)
              .frame(height: 50)
          }
          .buttonStyle(.plain)
        }
      }
      .padding(24)
      .frame(maxWidth: .infinity)
    }
  }

  private var strictModeWarning: Text {
    let baseText = Text(
      "You already use an NFC tag as a physical unlock for \(profileName). "
    )

    return baseText
      + Text("Do not write over that unlock tag")
      .fontWeight(.bold)
      + Text(
        ". Rewriting it can change what Foqos reads later and may stop this profile from unlocking. You do not need to create another NFC tag for this profile."
      )
  }

  private var convenienceText: String {
    return
      "This only creates a convenience shortcut: scan the tag, tap the iOS notification, and Foqos opens this profile for you."
  }
}

#Preview {
  StrictNFCWriteWarningView(
    profileName: "Deep Work",
    onCancel: {},
    onContinue: {}
  )
  .environmentObject(ThemeManager())
}
