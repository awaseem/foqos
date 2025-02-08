import SwiftUI
import StoreKit

class RatingManager: ObservableObject {
    @AppStorage("launchCount") private var launchCount = 0
    @AppStorage("lastVersionPromptedForReview") private var lastVersionPromptedForReview: String?
    @Published var shouldRequestReview = false
        
    func incrementLaunchCount() {
        launchCount += 1
        checkIfShouldRequestReview()
    }
    
    private func checkIfShouldRequestReview() {
        let currentVersion = Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String ?? ""
        
        // Only prompt if we haven't for this version and have enough launches
        guard lastVersionPromptedForReview != currentVersion,
              launchCount >= 3 else { return }
        
        shouldRequestReview = true
        lastVersionPromptedForReview = currentVersion
        requestReview()
    }
    
    private func requestReview() {
        guard let scene = UIApplication.shared.connectedScenes.first(
            where: { $0.activationState == .foregroundActive }
        ) as? UIWindowScene else {
            return
        }
        
        SKStoreReviewController.requestReview(in: scene)
    }
}
