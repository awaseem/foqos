import StoreKit
import SwiftUI

private let threadsURL = URL(string: "https://www.threads.com/@softwarecuddler")!
private let twitterURL = URL(string: "https://x.com/softwarecuddler")!
private let redditURL = URL(string: "https://www.reddit.com/user/waseema393/")!
private let linkedinURL = URL(string: "https://www.linkedin.com/in/aliw")!
private let donateURL = URL(string: "https://www.buymeacoffee.com/ambitionsoftware")!

struct SupportView: View {
  @EnvironmentObject var donationManager: TipManager
  @EnvironmentObject var themeManager: ThemeManager

  private let isUnitedStatesStorefrontOverride: Bool?

  @State private var isUnitedStatesStorefront = false
  @State private var stampScale: CGFloat = 0.1
  @State private var stampRotation: Double = 0
  @State private var stampOpacity: Double = 0.0

  init(isUnitedStatesStorefrontOverride: Bool? = nil) {
    self.isUnitedStatesStorefrontOverride = isUnitedStatesStorefrontOverride
    _isUnitedStatesStorefront = State(initialValue: isUnitedStatesStorefrontOverride ?? false)
  }

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
        .padding(.bottom, 30)

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
          "If you ever want to reach out with kind words, feedback, or your story, please do. Those messages mean a lot and help me keep going."
        )
      }
      .font(.callout)
      .multilineTextAlignment(.leading)
      .foregroundColor(.secondary)
      .frame(maxWidth: .infinity, alignment: .leading)
      .fadeInSlide(delay: 0.3)

      VStack(alignment: .leading, spacing: 18) {
        Text(
          "Questions? Reach out to me."
        )
        .font(.callout)
        .multilineTextAlignment(.leading)
        .foregroundColor(.secondary)

        HStack(alignment: .center, spacing: 20) {
          Link(destination: threadsURL) {
            Image("Threads")
              .resizable()
              .aspectRatio(contentMode: .fit)
              .frame(width: 24, height: 24)
          }

          Link(destination: twitterURL) {
            Image("Twitter")
              .resizable()
              .aspectRatio(contentMode: .fit)
              .frame(width: 24, height: 24)
          }
          Link(destination: redditURL) {
            Image("Reddit")
              .resizable()
              .aspectRatio(contentMode: .fit)
              .frame(width: 24, height: 24)
          }

          Link(destination: linkedinURL) {
            Image("Linkedin")
              .resizable()
              .aspectRatio(contentMode: .fit)
              .frame(width: 24, height: 24)
          }
        }
      }
      .frame(maxWidth: .infinity, alignment: .leading)
      .fadeInSlide(delay: 0.4)

      Spacer()

      VStack(spacing: 16) {
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

        if isUnitedStatesStorefront {
          Link("Or Buy Me a Coffee", destination: donateURL)
            .font(.subheadline.weight(.semibold))
            .foregroundColor(themeManager.themeColor)
        }
      }
      .fadeInSlide(delay: 0.6)
    }
    .padding(.horizontal, 20)
    .task {
      guard isUnitedStatesStorefrontOverride == nil else {
        return
      }

      isUnitedStatesStorefront = await Storefront.current?.countryCode == "USA"

      for await storefront in Storefront.updates {
        isUnitedStatesStorefront = storefront.countryCode == "USA"
      }
    }
  }
}

#Preview("United States") {
  NavigationView {
    SupportView(isUnitedStatesStorefrontOverride: true)
      .environmentObject(TipManager())
      .environmentObject(ThemeManager.shared)
  }
}

#Preview("Outside United States") {
  NavigationView {
    SupportView(isUnitedStatesStorefrontOverride: false)
      .environmentObject(TipManager())
      .environmentObject(ThemeManager.shared)
  }
}
