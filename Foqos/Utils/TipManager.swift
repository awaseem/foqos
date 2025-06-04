import StoreKit

class TipManager: ObservableObject {
    @Published var products: [Product] = []
    @Published var purchasedProductIDs = Set<String>()
    @Published var purchaseError: String?
    
    private let productID = "tip_developer_support"
    
    init() {
        Task {
            await loadProducts()
            await setupTransactionListener()
        }
    }
    
    @MainActor
    private func setupTransactionListener() async {
        // Start a transaction listener as soon as the app launches
        let updates = Transaction.updates
        for await result in updates {
            do {
                switch result {
                case .verified(let transaction):
                    // Handle a verified transaction
                    await handleVerifiedTransaction(transaction)
                case .unverified(let transaction, let error):
                    // Log the unverified transaction for debugging
                    purchaseError = "Verification failed: \(error.localizedDescription)"
                    print("Unverified transaction: \(transaction.id), Error: \(error)")
                }
            }
        }
    }
    
    @MainActor
    private func handleVerifiedTransaction(_ transaction: Transaction) async {
        // Add the purchased product identifier to the purchased set
        purchasedProductIDs.insert(transaction.productID)
        
        // Always finish a transaction once you've delivered the content
        await transaction.finish()
        
        // Update any UI or app state based on the purchase
        NotificationCenter.default.post(name: NSNotification.Name("PurchaseSuccessful"), object: nil)
    }
    
    @MainActor
    func loadProducts() async {
        do {
            // Request products from the App Store
            products = try await Product.products(for: [productID])
            
            // Check current entitlements
            await checkEntitlements()
            
            // Debug logging
            print("Available products: \(products.map { $0.id }.joined(separator: ", "))")
        } catch {
            purchaseError = "Failed to load products: \(error.localizedDescription)"
            print("Product loading error: \(error)")
        }
    }
    
    @MainActor
    private func checkEntitlements() async {
        // Verify existing purchases
        for await result in Transaction.currentEntitlements {
            switch result {
            case .verified(let transaction):
                purchasedProductIDs.insert(transaction.productID)
            case .unverified:
                continue
            }
        }
    }
    
    func purchase() async throws {
        guard let product = products.first else {
            throw StoreError.noProduct
        }
        
        // Begin a purchase
        let result = try await product.purchase()
        
        await MainActor.run {
            switch result {
            case .success(let verificationResult):
                switch verificationResult {
                case .verified(let transaction):
                    // Handle successful purchase
                    purchasedProductIDs.insert(transaction.productID)
                    Task {
                        await transaction.finish()
                    }
                case .unverified(_, let error):
                    purchaseError = "Purchase verification failed: \(error.localizedDescription)"
                }
            case .userCancelled:
                purchaseError = "Purchase was cancelled"
            case .pending:
                purchaseError = "Purchase is pending"
            @unknown default:
                purchaseError = "Unknown purchase result"
            }
        }
    }
    
    func tip() {
        Task {
            do {
                try await purchase()
            } catch StoreError.noProduct {
                await MainActor.run {
                    purchaseError = "No product available for purchase"
                }
            } catch {
                await MainActor.run {
                    purchaseError = "Purchase failed: \(error.localizedDescription)"
                }
            }
        }
    }
}

enum StoreError: Error {
    case noProduct
}
