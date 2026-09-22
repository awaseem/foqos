import StoreKit
import SwiftUI

private let threadsURL = URL(string: "https://www.threads.com/@softwarecuddler")!
private let twitterURL = URL(string: "https://x.com/softwarecuddler")!
private let redditURL = URL(string: "https://www.reddit.com/user/waseema393/")!
private let linkedinURL = URL(string: "https://www.linkedin.com/in/aliw")!

struct SupportView: View {
  @Environment(\.dismiss) private var dismiss
  @Environment(\.accessibilityReduceMotion) private var reduceMotion
  @Environment(\.colorScheme) private var colorScheme
  @EnvironmentObject var donationManager: TipManager
  @EnvironmentObject var themeManager: ThemeManager

  @State private var stampScale: CGFloat = 0.1
  @State private var stampRotation: Double = 0
  @State private var stampOpacity: Double = 0.0
  @State private var selectedProductID: String?

  private var selectedProduct: Product? {
    donationManager.products.first { $0.id == selectedProductID } ?? donationManager.products.first
  }

  private var selectedTipEmoji: String {
    switch selectedProduct?.id {
    case "tip_developer_support_5": "🤑"
    case "tip_developer_support_10": "😱"
    default: "❤️"
    }
  }

  var body: some View {
    NavigationStack {
      GeometryReader { geometry in
        ScrollView {
          supportContent
            .frame(maxWidth: 600)
            .frame(minHeight: max(0, geometry.size.height - 40))
            .frame(maxWidth: .infinity)
            .padding(20)
        }
      }
      .navigationTitle("Support")
      .navigationBarTitleDisplayMode(.inline)
      .toolbar {
        ToolbarItem(placement: .topBarLeading) {
          Button("Close", systemImage: "xmark") { dismiss() }
        }
      }
    }
    .task {
      await donationManager.loadProducts()
      for await _ in Storefront.updates {
        await donationManager.loadProducts()
      }
    }
  }

  private var supportContent: some View {
    VStack(alignment: .leading, spacing: 24) {
      Spacer()

      Image("ThankYouStamp")
        .resizable()
        .aspectRatio(contentMode: .fit)
        .frame(width: 140, height: 140)
        .frame(maxWidth: .infinity, alignment: .center)
        .scaleEffect(stampScale)
        .rotationEffect(.degrees(stampRotation))
        .opacity(stampOpacity)
        .onAppear {
          withAnimation(reduceMotion ? nil : .spring(response: 0.4, dampingFraction: 0.6)) {
            stampScale = 1
            stampRotation = 8
            stampOpacity = 1
          }
        }
        .padding(.bottom, 12)

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
      }
      .font(.callout)
      .multilineTextAlignment(.leading)
      .foregroundColor(.secondary)
      .frame(maxWidth: .infinity, alignment: .leading)
      .fadeInSlide(delay: 0.3)

      VStack(alignment: .leading, spacing: 18) {
        Text(
          "Questions, feedback, or a story to share? Reach out to me. Your messages mean a lot and help me keep going."
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

      tipSection
        .fadeInSlide(delay: 0.6)
    }
  }

  private var tipSection: some View {
    VStack(spacing: 24) {
      if donationManager.isLoadingProducts {
        ProgressView("Loading tips…")
          .padding()
      } else if let error = donationManager.productLoadingError {
        Text(error)
          .font(.subheadline)
          .foregroundStyle(.secondary)
          .multilineTextAlignment(.center)
        Button("Try again") {
          Task { await donationManager.loadProducts() }
        }
        .tint(themeManager.themeColor)
      } else if !donationManager.products.isEmpty {
        HStack(spacing: 0) {
          ForEach(donationManager.products) { product in
            Button {
              selectedProductID = product.id
            } label: {
              Text(product.displayPrice)
                .font(.subheadline.weight(.semibold))
                .lineLimit(1)
                .minimumScaleFactor(0.75)
                .padding(.horizontal, 8)
                .frame(maxWidth: .infinity, minHeight: 44)
                .background {
                  if selectedProduct?.id == product.id {
                    Capsule()
                      .fill(colorScheme == .dark ? Color(.systemGray3) : .white)
                  }
                }
                .contentShape(Capsule())
            }
            .buttonStyle(.plain)
            .accessibilityAddTraits(selectedProduct?.id == product.id ? .isSelected : [])
          }
        }
        .padding(3)
        .background(Color(.quaternarySystemFill), in: Capsule())
        .accessibilityElement(children: .contain)
        .accessibilityLabel("Tip amount")
        .disabled(donationManager.loadingTip)
      }

      ActionButton(
        title: selectedProduct.map { "Tip \($0.displayPrice) \(selectedTipEmoji)" }
          ?? "Leave a tip",
        backgroundColor: themeManager.themeColor,
        isLoading: donationManager.loadingTip,
        isDisabled: selectedProduct == nil || donationManager.isLoadingProducts
      ) {
        guard let product = selectedProduct else { return }
        Task { await donationManager.tip(product) }
      }

      if let error = donationManager.purchaseError {
        Text(error)
          .font(.subheadline)
          .foregroundStyle(.red)
          .multilineTextAlignment(.center)
      }

      if let message = donationManager.purchaseMessage {
        Text(message)
          .font(.subheadline)
          .foregroundStyle(.secondary)
          .multilineTextAlignment(.center)
      }

    }
    .frame(maxWidth: .infinity)
  }

}

#Preview("Support") {
  SupportView()
    .environmentObject(TipManager())
    .environmentObject(ThemeManager.shared)
}

#Preview("Dark") {
  SupportView()
    .environmentObject(TipManager())
    .environmentObject(ThemeManager.shared)
    .preferredColorScheme(.dark)
}
