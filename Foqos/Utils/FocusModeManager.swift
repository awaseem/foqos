//
//  FocusModeManager.swift
//  foqos
//
//  Manager for iOS Focus Mode integration
//

import Foundation
import Intents
import SwiftUI

// MARK: - Focus Mode Manager

@MainActor
class FocusModeManager: ObservableObject {

  static let shared = FocusModeManager()

  @Published var currentFocusStatus: INFocusStatus?
  @Published var isAuthorized: Bool = false
  @Published var isFocusModeActive: Bool = false

  private init() {
    checkAuthorizationStatus()
  }

  // MARK: - Authorization

  func checkAuthorizationStatus() {
    let status = INFocusStatusCenter.default.authorizationStatus
    isAuthorized = (status == .authorized)
  }

  func requestAuthorization() async -> Bool {
    let center = INFocusStatusCenter.default

    return await withCheckedContinuation { continuation in
      center.requestAuthorization { status in
        Task { @MainActor in
          self.isAuthorized = (status == .authorized)
          continuation.resume(returning: self.isAuthorized)
        }
      }
    }
  }

  // MARK: - Focus Status Observation

  func startObservingFocusStatus() {
    // Get initial status
    updateFocusStatus()

    // Listen for app lifecycle to check focus status when app becomes active
    // Note: The Intents framework doesn't provide a public notification for focus status changes
    NotificationCenter.default.addObserver(
      self,
      selector: #selector(appDidBecomeActive),
      name: UIApplication.didBecomeActiveNotification,
      object: nil
    )
  }

  func stopObservingFocusStatus() {
    NotificationCenter.default.removeObserver(
      self,
      name: UIApplication.didBecomeActiveNotification,
      object: nil
    )
  }

  @objc private func appDidBecomeActive() {
    Task { @MainActor in
      updateFocusStatus()
    }
  }

  private func updateFocusStatus() {
    guard isAuthorized else { return }

    let center = INFocusStatusCenter.default
    currentFocusStatus = center.focusStatus
    isFocusModeActive = center.focusStatus.isFocused ?? false
  }

  // MARK: - Session Integration

  /// Called when a focus session starts to check if user has a Focus Mode active
  func checkFocusModeForSession() -> Bool {
    guard isAuthorized else { return false }
    updateFocusStatus()
    return isFocusModeActive
  }

  /// Provides hints for the user about Focus Mode
  var focusModeHint: String? {
    guard isAuthorized else {
      return "Enable Focus Mode integration in Settings to sync with iOS Focus"
    }

    if isFocusModeActive {
      return "iOS Focus Mode is active. Your focus session will be enhanced."
    }

    return nil
  }
}

// MARK: - Focus Session Sync Helper

extension FocusModeManager {

  /// Determines if notifications should be suppressed based on Focus Mode
  func shouldSuppressNotifications() -> Bool {
    return isFocusModeActive
  }

  /// Returns recommended session settings based on Focus Mode state
  func recommendedSessionSettings() -> FocusSessionRecommendation {
    if isFocusModeActive {
      return FocusSessionRecommendation(
        suggestStrictMode: true,
        suggestLongerSessions: true,
        reason: "iOS Focus Mode is active, enabling enhanced focus settings"
      )
    }

    return FocusSessionRecommendation(
      suggestStrictMode: false,
      suggestLongerSessions: false,
      reason: nil
    )
  }
}

// MARK: - Session Recommendation

struct FocusSessionRecommendation {
  let suggestStrictMode: Bool
  let suggestLongerSessions: Bool
  let reason: String?
}

// MARK: - Focus Mode Status View

struct FocusModeStatusView: View {
  @ObservedObject var manager: FocusModeManager

  var body: some View {
    if manager.isAuthorized {
      HStack(spacing: Spacing.xs) {
        Image(systemName: manager.isFocusModeActive ? "moon.fill" : "moon")
          .foregroundColor(manager.isFocusModeActive ? .purple : .secondary)

        if manager.isFocusModeActive {
          Text("Focus Active")
            .font(.caption)
            .foregroundColor(.purple)
        }
      }
      .accessibilityElement(children: .combine)
      .accessibilityLabel(manager.isFocusModeActive
        ? "iOS Focus Mode is active"
        : "iOS Focus Mode is not active"
      )
    }
  }
}
