import Foundation
import StoreKit
import SwiftData
import SwiftUI

@MainActor
class BailoutManager: ObservableObject {
  static let shared = BailoutManager()

  @AppStorage("bailoutMode") var bailoutMode: BailoutMode = .exhaustedQuota
  @AppStorage("bailoutSelectedTier") var selectedTier: BailoutTier = .tier2
  @AppStorage("bailoutWebhookUrl") var webhookUrlString: String = ""
  @AppStorage("bailoutWebhookSecret") var webhookSecret: String = ""
  @AppStorage("totalBailoutsCompleted") var totalBailoutsCompleted: Int = 0

  @Published private(set) var products: [Product] = []
  @Published private(set) var isLoadingProducts: Bool = false
  @Published private(set) var isPurchasing: Bool = false
  @Published var purchaseError: String?
  @Published var lastWebhookStatusMessage: String?

  private var isTestingMode: Bool = false

  init(isTestingMode: Bool = false) {
    self.isTestingMode = isTestingMode
  }

  func loadProducts() async {
    guard !isLoadingProducts, !isTestingMode else { return }
    isLoadingProducts = true
    defer { isLoadingProducts = false }

    let productIDs = BailoutTier.allCases.map(\.id)
    do {
      products = try await Product.products(for: productIDs)
        .sorted { $0.price < $1.price }
    } catch {
      products = []
    }
  }

  func product(for tier: BailoutTier) -> Product? {
    products.first { $0.id == tier.id }
  }

  func displayPrice(for tier: BailoutTier) -> String {
    if let product = product(for: tier) {
      return product.displayPrice
    }
    return tier.defaultPriceString
  }

  func executeBailout(
    tier: BailoutTier,
    context: ModelContext,
    strategyManager: StrategyManager,
    profileName: String? = nil
  ) async -> Bool {
    guard !isPurchasing else { return false }
    isPurchasing = true
    purchaseError = nil
    defer { isPurchasing = false }

    if isTestingMode {
      recordSuccessfulBailout(tier: tier, profileName: profileName)
      strategyManager.emergencyUnblockWithBailout(context: context)
      return true
    }

    do {
      let targetProduct = product(for: tier)
        ?? (try await Product.products(for: [tier.id]).first)

      guard let productToPurchase = targetProduct else {
        // Fallback for offline/simulator without StoreKit configuration
        purchaseError = "StoreKit product unavailable. Please check your connection."
        return false
      }

      let result = try await productToPurchase.purchase()
      switch result {
      case .success(let verification):
        switch verification {
        case .verified(let transaction):
          await transaction.finish()
          recordSuccessfulBailout(tier: tier, profileName: profileName)
          strategyManager.emergencyUnblockWithBailout(context: context)
          return true
        case .unverified(_, let error):
          purchaseError = "Transaction unverified: \(error.localizedDescription)"
          return false
        }
      case .userCancelled:
        return false
      case .pending:
        purchaseError = "Purchase is awaiting family or bank approval."
        return false
      @unknown default:
        purchaseError = "Unknown purchase result."
        return false
      }
    } catch StoreKitError.userCancelled {
      return false
    } catch {
      purchaseError = "Purchase failed: \(error.localizedDescription)"
      return false
    }
  }

  func recordSuccessfulBailout(tier: BailoutTier, profileName: String? = nil) {
    totalBailoutsCompleted += 1
    UIImpactFeedbackGenerator(style: .heavy).impactOccurred()

    Task {
      await sendBailoutWebhook(tier: tier, profileName: profileName)
    }
  }

  func sendBailoutWebhook(
    tier: BailoutTier,
    profileName: String? = nil
  ) async -> Bool {
    let cleanUrlString = webhookUrlString.trimmingCharacters(in: .whitespacesAndNewlines)
    guard !cleanUrlString.isEmpty, let url = URL(string: cleanUrlString) else {
      return false
    }

    let payload = BailoutWebhookPayload(tier: tier, profileName: profileName)

    do {
      var request = URLRequest(url: url)
      request.httpMethod = "POST"
      request.setValue("application/json", forHTTPHeaderField: "Content-Type")
      request.setValue("Foqos-App/2.5.0", forHTTPHeaderField: "User-Agent")

      let cleanSecret = webhookSecret.trimmingCharacters(in: .whitespacesAndNewlines)
      if !cleanSecret.isEmpty {
        request.setValue("Bearer \(cleanSecret)", forHTTPHeaderField: "Authorization")
        request.setValue(cleanSecret, forHTTPHeaderField: "X-Foqos-Secret")
      }

      let encoder = JSONEncoder()
      encoder.dateEncodingStrategy = .iso8601
      request.httpBody = try encoder.encode(payload)
      request.timeoutInterval = 10

      let (_, response) = try await URLSession.shared.data(for: request)
      if let httpResponse = response as? HTTPURLResponse,
        (200...299).contains(httpResponse.statusCode)
      {
        lastWebhookStatusMessage = "Webhook delivered (\(httpResponse.statusCode))"
        return true
      } else {
        lastWebhookStatusMessage = "Webhook failed with non-200 status"
        return false
      }
    } catch {
      lastWebhookStatusMessage = "Webhook delivery error: \(error.localizedDescription)"
      return false
    }
  }
}
