import DeviceActivity
import FamilyControls
import ManagedSettings
import SwiftUI

class RequestAuthorizer: ObservableObject {
  @Published var isAuthorized = false
  @Published var showAuthorizationError = false
  @Published var authorizationErrorMessage = ""

  func refreshAuthorizationStatus() {
    let isApproved = getAuthorizationStatus() == .approved

    Task { @MainActor in
      self.isAuthorized = isApproved
    }
  }

  func requestAuthorization() {
    Task {
      do {
        try await AuthorizationCenter.shared.requestAuthorization(for: .individual)
        print("Individual authorization successful")

        // Dispatch the update to the main thread
        await MainActor.run {
          self.isAuthorized = true
        }
      } catch {
        let authorizationError = error as NSError
        await MainActor.run {
          self.isAuthorized = false
          self.authorizationErrorMessage =
            "\(authorizationError.localizedDescription)\n\nDomain: \(authorizationError.domain)\nCode: \(authorizationError.code)"
          self.showAuthorizationError = true
        }
      }
    }
  }

  func getAuthorizationStatus() -> AuthorizationStatus {
    return AuthorizationCenter.shared.authorizationStatus
  }
}
