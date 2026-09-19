import SwiftUI

struct HomeHeaderView: View {
  let onSupportTapped: () -> Void
  let onSettingsTapped: () -> Void
  var showsSupportTitle = true

  var body: some View {
    HStack(alignment: .center) {
      AppTitle()
      Spacer()
      HStack(spacing: 8) {
        RoundedButton(
          showsSupportTitle ? "Support" : "",
          action: onSupportTapped,
          imageName: "SupportStickerLogo"
        )
        .accessibilityLabel("Support")
        RoundedButton("", action: onSettingsTapped, iconName: "gear")
          .accessibilityLabel("Settings")
      }
    }
    .padding(.trailing, 16)
    .padding(.top, 16)
  }
}

#Preview {
  HomeHeaderView(onSupportTapped: {}, onSettingsTapped: {})
}
