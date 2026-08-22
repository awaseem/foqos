import AppKit
import SwiftUI

@MainActor
final class FoqosOnboardingWindowController: NSObject, ObservableObject {
  private static let completionKey = "hasCompletedMacOnboarding"

  private let filterManager: FoqosFilterManager
  private var windowController: NSWindowController?

  init(filterManager: FoqosFilterManager) {
    self.filterManager = filterManager
  }

  func showIfNeeded() {
    guard !UserDefaults.standard.bool(forKey: Self.completionKey) else {
      return
    }

    show()
  }

  func show() {
    filterManager.refreshStatus()

    if let window = windowController?.window {
      windowController?.showWindow(nil)
      window.makeKeyAndOrderFront(nil)
      NSApplication.shared.activate(ignoringOtherApps: true)
      return
    }

    let onboardingView = MacOnboardingView(
      onComplete: { [weak self] in
        self?.completeOnboarding()
      },
      onDismiss: { [weak self] in
        self?.windowController?.close()
      }
    )
    .environmentObject(filterManager)

    let hostingController = NSHostingController(rootView: onboardingView)
    let window = NSWindow(
      contentRect: NSRect(x: 0, y: 0, width: 520, height: 620),
      styleMask: [.titled, .closable, .miniaturizable, .fullSizeContentView],
      backing: .buffered,
      defer: false
    )
    window.title = "Welcome to Foqos"
    window.titleVisibility = .hidden
    window.titlebarAppearsTransparent = true
    window.isMovableByWindowBackground = true
    window.isReleasedWhenClosed = false
    window.backgroundColor = .clear
    window.contentMinSize = NSSize(width: 480, height: 580)
    window.contentViewController = hostingController
    window.setContentSize(NSSize(width: 520, height: 620))
    window.center()
    window.standardWindowButton(.zoomButton)?.isHidden = true

    let windowController = NSWindowController(window: window)
    self.windowController = windowController
    windowController.showWindow(nil)
    window.makeKeyAndOrderFront(nil)
    NSApplication.shared.activate(ignoringOtherApps: true)
  }

  private func completeOnboarding() {
    UserDefaults.standard.set(true, forKey: Self.completionKey)
    windowController?.close()
  }
}

@MainActor
final class FoqosMacAppDelegate: NSObject, NSApplicationDelegate {
  private var filterManager: FoqosFilterManager?
  private var onboardingController: FoqosOnboardingWindowController?
  private var hasFinishedLaunching = false

  func configure(
    filterManager: FoqosFilterManager,
    onboardingController: FoqosOnboardingWindowController
  ) {
    self.filterManager = filterManager
    self.onboardingController = onboardingController

    if hasFinishedLaunching {
      onboardingController.showIfNeeded()
    }
  }

  func applicationDidFinishLaunching(_ notification: Notification) {
    hasFinishedLaunching = true
    onboardingController?.showIfNeeded()
  }

  func applicationDidBecomeActive(_ notification: Notification) {
    filterManager?.refreshStatus()
  }
}
