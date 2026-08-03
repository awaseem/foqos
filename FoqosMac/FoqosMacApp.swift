import Darwin
import SwiftUI

@main
struct FoqosMacApp: App {
  @NSApplicationDelegateAdaptor(FoqosMacAppDelegate.self) private var appDelegate

  @StateObject private var controller: FoqosMacController
  @StateObject private var filterManager: FoqosFilterManager
  @StateObject private var onboardingController: FoqosOnboardingWindowController
  @StateObject private var updaterController: FoqosUpdaterController

  init() {
    let filterManager = FoqosFilterManager()
    let onboardingController = FoqosOnboardingWindowController(filterManager: filterManager)
    _filterManager = StateObject(wrappedValue: filterManager)
    _controller = StateObject(wrappedValue: FoqosMacController(filterManager: filterManager))
    _onboardingController = StateObject(wrappedValue: onboardingController)
    _updaterController = StateObject(wrappedValue: FoqosUpdaterController())
    appDelegate.configure(
      filterManager: filterManager,
      onboardingController: onboardingController
    )

    #if DEBUG
      if CommandLine.arguments.contains("--reset-network-extension") {
        Task { @MainActor in
          filterManager.resetForDevelopment { result in
            switch result {
            case .success(let requiresRestart):
              if requiresRestart {
                print("Foqos reset is pending. Restart this Mac to finish removing the extension.")
              } else {
                print(
                  "Foqos filter configuration was removed and the system extension was deactivated."
                )
              }
              exit(EXIT_SUCCESS)
            case .failure(let error):
              fputs("Unable to reset Foqos: \(error.localizedDescription)\n", stderr)
              exit(EXIT_FAILURE)
            }
          }
        }
      }
    #endif
  }

  var body: some Scene {
    MenuBarExtra {
      MenuBarContentView()
        .environmentObject(controller)
        .environmentObject(filterManager)
        .environmentObject(onboardingController)
        .environmentObject(updaterController)
    } label: {
      Label("Foqos", systemImage: menuBarSystemImage)
    }
    .menuBarExtraStyle(.window)
  }

  private var menuBarSystemImage: String {
    switch filterManager.status {
    case .approvalRequired, .disabled, .failed, .notConfigured, .requiresRestart:
      return "exclamationmark.triangle.fill"
    case .enabled:
      return controller.isBlocking ? "hourglass.circle.fill" : "hourglass"
    case .installing, .unknown:
      return "hourglass"
    }
  }
}
