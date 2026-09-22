import StoreKit
import StoreKitTest
import XCTest

@testable import foqos

@MainActor
final class TipManagerTests: XCTestCase {
  private var session: SKTestSession!

  override func setUpWithError() throws {
    session = try SKTestSession(configurationFileNamed: "Tip for developer")
    session.resetToDefaultState()
    session.clearTransactions()
    session.disableDialogs = true
  }

  override func tearDownWithError() throws {
    session.clearTransactions()
    session.resetToDefaultState()
    session = nil
  }

  func testGivenCatalog_WhenLoaded_ThenAllThreeAmountsAreAvailableInPriceOrder() async {
    let manager = TipManager()
    await manager.loadProducts()

    XCTAssertNil(manager.productLoadingError)
    XCTAssertEqual(manager.products.map(\.id), TipManager.productIDs)
    XCTAssertEqual(
      manager.products.map(\.price),
      [Decimal(string: "1.99")!, Decimal(string: "4.99")!, Decimal(string: "9.99")!])
    XCTAssertEqual(manager.products.map(\.type), [.consumable, .consumable, .consumable])
    XCTAssertFalse(manager.isLoadingProducts)
  }

  func testGivenEachTipAmount_WhenPurchasedTwice_ThenBothTransactionsComplete() async throws {
    let manager = TipManager()
    await manager.loadProducts()
    XCTAssertEqual(manager.products.count, 3)

    for purchaseCount in 1...2 {
      for product in manager.products {
        await manager.tip(product)
        try await waitForPurchaseCount(purchaseCount, productID: product.id)

        XCTAssertNil(manager.purchaseError, product.id)
        XCTAssertNotNil(manager.purchaseMessage, product.id)
        XCTAssertFalse(manager.loadingTip)
        XCTAssertEqual(
          session.allTransactions().filter {
            $0.productIdentifier == product.id && $0.state == .purchased
          }.count, purchaseCount, product.id
        )
      }
    }
    XCTAssertEqual(session.allTransactions().count, 6)
    XCTAssertEqual(manager.products.map(\.id), TipManager.productIDs)
  }

  private func waitForPurchaseCount(_ count: Int, productID: String) async throws {
    for _ in 0..<40 {
      if session.allTransactions().filter({
        $0.productIdentifier == productID && $0.state == .purchased
      }).count == count {
        return
      }
      try await Task.sleep(for: .milliseconds(50))
    }
  }

  func testGivenFrenchStorefront_WhenLoaded_ThenPricesUseEuros() async throws {
    session.storefront = "FRA"
    session.locale = Locale(identifier: "fr_FR")
    let manager = TipManager()
    await manager.loadProducts()

    XCTAssertEqual(manager.products.count, 3)
    for product in manager.products {
      XCTAssertEqual(product.priceFormatStyle.currencyCode, "EUR")
      XCTAssertTrue(product.displayPrice.contains("€"))
      XCTAssertFalse(product.displayPrice.contains("$"))
    }
  }

  func testGivenCancelledPurchase_WhenTipping_ThenNoErrorOrThankYouIsShown() async throws {
    let manager = TipManager()
    await manager.loadProducts()
    let product = try XCTUnwrap(manager.products.first)
    try await session.setSimulatedError(.generic(.userCancelled), forAPI: .purchase)

    await manager.tip(product)

    XCTAssertNil(manager.purchaseError)
    XCTAssertNil(manager.purchaseMessage)
    XCTAssertFalse(manager.loadingTip)
    XCTAssertTrue(session.allTransactions().allSatisfy { $0.state == .failed })
  }

  func testGivenAskToBuy_WhenTipping_ThenApprovalIsPending() async throws {
    session.askToBuyEnabled = true
    let manager = TipManager()
    await manager.loadProducts()
    let product = try XCTUnwrap(manager.products.first { $0.id == "tip_developer_support_5" })

    await manager.tip(product)

    XCTAssertNil(manager.purchaseError)
    XCTAssertTrue(manager.purchaseMessage?.contains("awaiting approval") == true)
    XCTAssertFalse(manager.loadingTip)
  }

  func testGivenExistingSupporter_WhenReloading_ThenOriginalTipCanBePurchasedAgain() async throws {
    let transaction = try await session.buyProduct(identifier: "tip_developer_support")
    await transaction.finish()
    let manager = TipManager()
    await manager.loadProducts()
    let product = try XCTUnwrap(manager.products.first { $0.id == "tip_developer_support" })

    await manager.tip(product)
    await manager.loadProducts()
    await manager.tip(product)

    XCTAssertEqual(
      session.allTransactions().map(\.productIdentifier), Array(repeating: product.id, count: 3))
    XCTAssertEqual(manager.products.map(\.id), TipManager.productIDs)
    XCTAssertNil(manager.purchaseError)
    XCTAssertFalse(manager.loadingTip)
  }

  func testGivenLoadingFailure_WhenRetried_ThenProductsRecover() async throws {
    let manager = TipManager()
    try await session.setSimulatedError(
      .generic(.networkError(URLError(.notConnectedToInternet))), forAPI: .loadProducts)
    await manager.loadProducts()

    XCTAssertNotNil(manager.productLoadingError)
    XCTAssertTrue(manager.products.isEmpty)
    XCTAssertFalse(manager.isLoadingProducts)

    try await session.setSimulatedError(nil, forAPI: .loadProducts)
    await manager.loadProducts()

    XCTAssertNil(manager.productLoadingError)
    XCTAssertEqual(manager.products.count, 3)
  }

  func testGivenPurchaseFailure_WhenTipping_ThenErrorIsVisibleAndPurchaseCanBeRetried() async throws
  {
    let manager = TipManager()
    await manager.loadProducts()
    let product = try XCTUnwrap(manager.products.first { $0.id == "tip_developer_support_5" })
    try await session.setSimulatedError(.generic(.notAvailableInStorefront), forAPI: .purchase)

    await manager.tip(product)

    XCTAssertNotNil(manager.purchaseError)
    XCTAssertFalse(manager.loadingTip)
    XCTAssertTrue(session.allTransactions().allSatisfy { $0.state == .failed })

    session.resetToDefaultState()
    session.disableDialogs = true
    await manager.tip(product)

    XCTAssertNil(manager.purchaseError)
    XCTAssertEqual(
      session.allTransactions().filter { $0.state == .purchased }.map(\.productIdentifier),
      [product.id])
  }
}
