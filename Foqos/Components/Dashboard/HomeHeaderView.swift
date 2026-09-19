import SwiftUI

struct HomeHeaderView: View {
  let onSupportTapped: () -> Void
  let onSettingsTapped: () -> Void

  var body: some View {
    HStack(alignment: .center) {
      AppTitle()
      Spacer()
      HStack(spacing: 8) {
        RoundedButton("Support", action: onSupportTapped, imageName: "SupportStickerLogo")
        RoundedButton("", action: onSettingsTapped, iconName: "gear")
      }
    }
    .padding(.trailing, 16)
    .padding(.top, 16)
  }
}

#Preview {
  HomeHeaderView(onSupportTapped: {}, onSettingsTapped: {})
}
