import SwiftUI

let THREADS_URL = "https://www.threads.com/@softwarecuddler"
let TWITTER_URL = "https://x.com/softwarecuddler"
let REDDIT_URL = "https://www.reddit.com/user/waseema393/"
let LINKEDIN_URL = "https://www.linkedin.com/in/aliw"
let DONATE_URL = "https://buymeacoffee.com/softwarecuddler"  // You can replace this with your actual donation URL

struct SupportView: View {
  @EnvironmentObject var donationManager: TipManager
  @EnvironmentObject var themeManager: ThemeManager

  @State private var stampScale: CGFloat = 0.1
  @State private var stampRotation: Double = 0
  @State private var stampOpacity: Double = 0.0

  var body: some View {
    // Thank you stamp image and header
    VStack(alignment: .leading, spacing: 24) {
      Spacer()

      Image("ThankYouStamp")
        .resizable()
        .aspectRatio(contentMode: .fit)
        .frame(width: 200, height: 200)
        .frame(maxWidth: .infinity, alignment: .center)
        .scaleEffect(stampScale)
        .rotationEffect(.degrees(stampRotation))
        .opacity(stampOpacity)
        .onAppear {
          withAnimation(.spring(response: 0.4, dampingFraction: 0.6, blendDuration: 0)) {
            stampScale = 1
            stampRotation = 8
            stampOpacity = 1
          }
        }
        .padding(.bottom, 20)

      Text("Thank you for being here ♥")
        .fontWeight(.bold)
        .frame(maxWidth: .infinity, alignment: .leading)
        .font(.callout)
        .foregroundColor(.secondary)
        .fadeInSlide(delay: 0.3)

      VStack(alignment: .leading, spacing: 16) {
        Text(
          "Foqos started as a small attempt to make focus feel easier and more intentional. Every person who uses it, shares it, reviews it, or supports it helps keep that idea alive."
        )

        Text(
          "If this has helped you, consider leaving a review, telling a friend, or making a small donation."
        )

        Text(
          "If you ever want to reach out with kind words, feedback, or your story, please do. Those messages mean a lot to me and help me keep going."
        )
      }
      .font(.callout)
      .multilineTextAlignment(.leading)
      .foregroundColor(.secondary)
      .frame(maxWidth: .infinity, alignment: .leading)
      .fadeInSlide(delay: 0.3)

      Text(
        "Questions? Reach out to me."
      )
      .font(.callout)
      .multilineTextAlignment(.leading)
      .foregroundColor(.secondary)
      .frame(maxWidth: .infinity, alignment: .leading)
      .fadeInSlide(delay: 0.4)

      HStack(alignment: .center, spacing: 20) {
        Link(destination: URL(string: THREADS_URL)!) {
          Image("Threads")
            .resizable()
            .aspectRatio(contentMode: .fit)
            .frame(width: 24, height: 24)
        }

        Link(destination: URL(string: TWITTER_URL)!) {
          Image("Twitter")
            .resizable()
            .aspectRatio(contentMode: .fit)
            .frame(width: 24, height: 24)
        }
        Link(destination: URL(string: REDDIT_URL)!) {
          Image("Reddit")
            .resizable()
            .aspectRatio(contentMode: .fit)
            .frame(width: 24, height: 24)
        }

        Link(destination: URL(string: LINKEDIN_URL)!) {
          Image("Linkedin")
            .resizable()
            .aspectRatio(contentMode: .fit)
            .frame(width: 24, height: 24)
        }
      }
      .frame(maxWidth: .infinity, alignment: .leading)
      .fadeInSlide(delay: 0.5)

      Spacer()

      ActionButton(
        title: donationManager.hasPurchasedTip ? "Thank you for the donation" : "Donate",
        backgroundColor: donationManager.hasPurchasedTip ? .gray : themeManager.themeColor,
        iconName: "heart.fill",
        iconColor: donationManager.hasPurchasedTip ? .red : nil,
        isLoading: donationManager.loadingTip,
        action: {
          if !donationManager.hasPurchasedTip {
            donationManager.tip()
          }
        }
      )
      .fadeInSlide(delay: 0.6)
    }
    .padding(.horizontal, 20)
  }
}

#Preview {
  NavigationView {
    SupportView()
      .environmentObject(TipManager())
  }
}
