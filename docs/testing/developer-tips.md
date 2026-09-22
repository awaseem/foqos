# Developer tips

The Support screen fetches its amounts from StoreKit and uses `Product.displayPrice` for both the segmented amount picker and purchase button. Apple supplies the price and currency for the customer's App Store storefront; the app does not convert USD or format prices using the device locale.

## App Store Connect setup before release

The checked-in `.storekit` file configures local testing only. Keep the existing approved product and create the two new products in App Store Connect with these exact IDs:

| Product ID | Type | US base price | Display name |
| --- | --- | --- | --- |
| `tip_developer_support` | Existing approved consumable; preserve | $1.99 | Small Tip |
| `tip_developer_support_5` | Consumable | $4.99 | Generous Tip |
| `tip_developer_support_10` | Consumable | $9.99 | Extra Generous Tip |

For the two new products, select the United States as the base country, set the exact USD prices, review Apple's generated regional prices, select availability, add localizations and App Review information, and submit them for review. All three products are consumable and allow repeat tips, including the existing approved `tip_developer_support`. Completing a tip does not remove or disable its amount in the picker.

Only products returned by StoreKit appear in the picker, so unavailable or unapproved products are not offered with made-up prices.

Apple references: [Create in-app purchases](https://developer.apple.com/help/app-store-connect/manage-in-app-purchases/create-consumable-or-non-consumable-in-app-purchases), [Set in-app purchase prices](https://developer.apple.com/help/app-store-connect/manage-in-app-purchases/set-a-price-for-an-in-app-purchase), [Localized display price](https://developer.apple.com/documentation/storekit/product/displayprice).

## Validation

Run `make test UNIT_TEST_TARGET=foqosTests/TipManagerTests` for StoreKit integration coverage of the catalog, selected amount, repeat purchases at every amount, returning supporters, localized euro prices, cancellation, pending approval, product loading failures, and purchase retry.

Validated on iOS 18.6. The installed iOS 26.4.1 runtime rejects command-line `SKTestSession` configuration changes ([Apple's known issue](https://developer.apple.com/forums/thread/826971)). To use the validated runtime, run `make test UNIT_TEST_TARGET=foqosTests/TipManagerTests TEST_DESTINATION='platform=iOS Simulator,name=iPhone 16 Pro,OS=18.6'`. Run these tests serially because StoreKit's test environment is shared.

For manual testing, use the foqos scheme's "Tip for developer" StoreKit configuration. On Support, change the selected amount and verify the button and Apple confirmation sheet agree. Cancel a purchase, complete a purchase, and test Ask to Buy approval. Test a different storefront and locale in the StoreKit configuration; verify the picker and button match Apple's price formatting. Check larger accessibility text sizes and light/dark appearance.

Before shipping, disable the local StoreKit configuration and verify the real catalog and regional prices with an App Store sandbox account or TestFlight. Local test prices do not validate App Store Connect price equalization or product availability.
