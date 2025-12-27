//
//  Haptics.swift
//  foqos
//
//  Unified haptic feedback system for consistent tactile responses
//

import SwiftUI
import UIKit

// MARK: - Haptic Feedback Types

enum HapticFeedback {
  case light      // Toggles, secondary actions
  case medium     // Primary buttons, confirmations
  case heavy      // Destructive actions
  case success    // Task completed
  case warning    // Attention needed
  case error      // Action failed
  case selection  // Picker/carousel changes

  func trigger() {
    switch self {
    case .light:
      UIImpactFeedbackGenerator(style: .light).impactOccurred()
    case .medium:
      UIImpactFeedbackGenerator(style: .medium).impactOccurred()
    case .heavy:
      UIImpactFeedbackGenerator(style: .heavy).impactOccurred()
    case .success:
      UINotificationFeedbackGenerator().notificationOccurred(.success)
    case .warning:
      UINotificationFeedbackGenerator().notificationOccurred(.warning)
    case .error:
      UINotificationFeedbackGenerator().notificationOccurred(.error)
    case .selection:
      UISelectionFeedbackGenerator().selectionChanged()
    }
  }
}

// MARK: - SwiftUI Haptic Modifiers

extension View {
  /// Trigger haptic feedback when a value changes
  func hapticFeedback<Value: Equatable>(
    _ type: HapticFeedback,
    trigger value: Value
  ) -> some View {
    self.onChange(of: value) { _, _ in
      type.trigger()
    }
  }

  /// Trigger haptic feedback on tap
  func hapticOnTap(_ type: HapticFeedback = .light) -> some View {
    self.simultaneousGesture(
      TapGesture().onEnded { _ in
        type.trigger()
      }
    )
  }
}

// MARK: - iOS 17+ Sensory Feedback Bridge

@available(iOS 17.0, *)
extension HapticFeedback {
  var sensoryType: SensoryFeedback {
    switch self {
    case .light:
      return .impact(flexibility: .soft)
    case .medium:
      return .impact(flexibility: .solid)
    case .heavy:
      return .impact(weight: .heavy)
    case .success:
      return .success
    case .warning:
      return .warning
    case .error:
      return .error
    case .selection:
      return .selection
    }
  }
}

extension View {
  /// Modern sensory feedback for iOS 17+, falls back to UIKit for older versions
  @ViewBuilder
  func modernHaptic<Value: Equatable>(
    _ type: HapticFeedback,
    trigger value: Value
  ) -> some View {
    if #available(iOS 17.0, *) {
      self.sensoryFeedback(type.sensoryType, trigger: value)
    } else {
      self.hapticFeedback(type, trigger: value)
    }
  }
}

// MARK: - Haptic Feedback Presets for Common Actions

struct HapticPresets {
  /// Session started - medium impact
  static func sessionStart() {
    HapticFeedback.medium.trigger()
  }

  /// Session ended - success notification
  static func sessionEnd() {
    HapticFeedback.success.trigger()
  }

  /// Break toggled - light impact
  static func breakToggle() {
    HapticFeedback.light.trigger()
  }

  /// Emergency unblock - warning notification
  static func emergencyUnblock() {
    HapticFeedback.warning.trigger()
  }

  /// Carousel page changed - selection feedback
  static func pageChange() {
    HapticFeedback.selection.trigger()
  }

  /// Button pressed - light impact
  static func buttonPress() {
    HapticFeedback.light.trigger()
  }

  /// Form validation error - error notification
  static func validationError() {
    HapticFeedback.error.trigger()
  }

  /// Save successful - success notification
  static func saveSuccess() {
    HapticFeedback.success.trigger()
  }

  /// Delete action - heavy impact
  static func deleteAction() {
    HapticFeedback.heavy.trigger()
  }

  /// Toggle switch - light impact
  static func toggleSwitch() {
    HapticFeedback.light.trigger()
  }
}
