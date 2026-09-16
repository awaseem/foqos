import AppKit
import SwiftUI

@MainActor
final class FoqosOnboardingWindowController: NSObject, ObservableObject, NSWindowDelegate {
  private static let completionKey = "hasCompletedMacOnboarding"

  private let filterManager: FoqosFilterManager
  private var windowController: NSWindowController?

  init(filterManager: FoqosFilterManager) {
    self.filterManager = filterManager
  }

  func showIfNeeded() {
    let completed = UserDefaults.standard.bool(forKey: Self.completionKey)
    MacDiagnostics.shared.updateState(
      "onboarding", fields: ["completed": String(completed), "visible": "false"])
    MacDiagnostics.shared.record(
      "onboarding.launch_check", "Checked whether onboarding was completed previously.",
      fields: ["completed": String(completed)]
    )
    guard !UserDefaults.standard.bool(forKey: Self.completionKey) else {
      return
    }

    show()
  }

  func show() {
    MacDiagnostics.shared.record(
      "onboarding.opened", "Showing onboarding.",
      fields: ["status": filterManager.status.diagnosticName])
    MacDiagnostics.shared.updateState(
      "onboarding",
      fields: [
        "completed": String(UserDefaults.standard.bool(forKey: Self.completionKey)),
        "visible": "true",
      ])
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
    window.delegate = self
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
    MacDiagnostics.shared.record(
      "onboarding.completed", "User completed onboarding with the filter enabled.")
    UserDefaults.standard.set(true, forKey: Self.completionKey)
    windowController?.close()
  }

  func windowWillClose(_ notification: Notification) {
    let completed = UserDefaults.standard.bool(forKey: Self.completionKey)
    MacDiagnostics.shared.record(
      "onboarding.closed", "Onboarding window closed.",
      fields: ["completed": String(completed), "status": filterManager.status.diagnosticName]
    )
    MacDiagnostics.shared.updateState(
      "onboarding", fields: ["completed": String(completed), "visible": "false"])
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

  func applicationWillTerminate(_ notification: Notification) {
    MacDiagnostics.shared.record("app.terminating", "Foqos Mac is terminating.")
    MacDiagnostics.shared.flush()
  }
}
