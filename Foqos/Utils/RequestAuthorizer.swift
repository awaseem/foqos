import DeviceActivity
import FamilyControls
import ManagedSettings
import SwiftUI

class RequestAuthorizer: ObservableObject {
  @Published var isAuthorized = false

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
        print("Error requesting authorization: \(error)")
        await MainActor.run {
          self.isAuthorized = false
        }
      }
    }
  }

  func getAuthorizationStatus() -> AuthorizationStatus {
    return AuthorizationCenter.shared.authorizationStatus
  }
}
