import StoreKit

@MainActor
class TipManager: ObservableObject {
  static let productIDs = [
    "tip_developer_support",
    "tip_developer_support_5",
    "tip_developer_support_10",
  ]

  @Published private(set) var products: [Product] = []
  @Published private(set) var isLoadingProducts = false
  @Published private(set) var loadingTip = false
  @Published private(set) var productLoadingError: String?
  @Published private(set) var purchaseError: String?
  @Published private(set) var purchaseMessage: String?

  private var transactionListener: Task<Void, Never>?

  init() {
    transactionListener = Task { [weak self] in
      for await result in Transaction.updates {
        guard let self else { return }
        await self.handleTransaction(result)
      }
    }
  }

  deinit {
    transactionListener?.cancel()
  }

  func loadProducts() async {
    guard !isLoadingProducts else { return }
    isLoadingProducts = true
    productLoadingError = nil
    defer { isLoadingProducts = false }

    do {
      products = try await Product.products(for: Self.productIDs)
        .sorted { $0.price < $1.price }

      if products.isEmpty {
        productLoadingError = "Tips are unavailable right now. Please try again later."
      }
    } catch {
      products = []
      productLoadingError = "Couldn't load tips. Please check your connection and try again."
    }
  }

  func tip(_ product: Product) async {
    guard !loadingTip, !isLoadingProducts,
      products.contains(where: { $0.id == product.id })
    else { return }

    loadingTip = true
    purchaseError = nil
    purchaseMessage = nil
    defer { loadingTip = false }

    do {
      switch try await product.purchase() {
      case .success(let result):
        await handleTransaction(result)
      case .userCancelled:
        break
      case .pending:
        purchaseMessage = "Your tip is awaiting approval. Thank you for your support!"
      @unknown default:
        purchaseError = "Couldn't complete your tip. Please try again."
      }
    } catch StoreKitError.userCancelled {
      return
    } catch {
      purchaseError = "Purchase failed: \(error.localizedDescription)"
    }
  }

  private func handleTransaction(_ result: VerificationResult<Transaction>) async {
    switch result {
    case .verified(let transaction):
      guard Self.productIDs.contains(transaction.productID) else { return }

      if transaction.revocationDate != nil {
        await transaction.finish()
        return
      }

      purchaseError = nil
      purchaseMessage = "Thank you for supporting Foqos ♥"
      await transaction.finish()
    case .unverified(let transaction, let error):
      guard Self.productIDs.contains(transaction.productID) else { return }
      purchaseError = "Couldn't verify your tip: \(error.localizedDescription)"
    }
  }
}
