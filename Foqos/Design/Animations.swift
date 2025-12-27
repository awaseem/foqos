//
//  Animations.swift
//  foqos
//
//  Standardized animation presets for consistent motion across the app
//

import SwiftUI

// MARK: - Animation Presets

extension Animation {
  /// Quick feedback for taps, toggles (0.2s)
  static let micro = Animation.spring(response: 0.2, dampingFraction: 0.8)

  /// Standard state changes (0.3s)
  static let standard = Animation.spring(response: 0.3, dampingFraction: 0.75)

  /// Card/page transitions (0.4s)
  static let transition = Animation.spring(response: 0.4, dampingFraction: 0.8)

  /// Elaborate entrances (0.6s)
  static let entrance = Animation.spring(response: 0.6, dampingFraction: 0.7)

  /// Snappy feedback (0.25s)
  static let snappy = Animation.spring(response: 0.25, dampingFraction: 0.85)

  /// Bouncy animations (0.5s)
  static let bouncy = Animation.spring(response: 0.5, dampingFraction: 0.6)

  /// Continuous rotation
  static let rotate = Animation.linear(duration: 10).repeatForever(autoreverses: false)

  /// Pulsing effects
  static let pulse = Animation.easeOut(duration: 2).repeatForever(autoreverses: false)

  /// Gentle breathing effect
  static let breathe = Animation.easeInOut(duration: 1.5).repeatForever(autoreverses: true)
}

// MARK: - Animation Timing Constants

enum AnimationTiming {
  // Duration
  static let instant: Double = 0.1
  static let fast: Double = 0.2
  static let standard: Double = 0.3
  static let slow: Double = 0.5
  static let elaborate: Double = 0.8

  // Spring Damping
  static let snappyDamping: CGFloat = 0.85
  static let smoothDamping: CGFloat = 0.75
  static let bouncyDamping: CGFloat = 0.6
}

// MARK: - Reduced Motion Support

struct MotionSafeAnimationModifier<Value: Equatable>: ViewModifier {
  @Environment(\.accessibilityReduceMotion) var reduceMotion
  let animation: Animation
  let reducedAnimation: Animation?
  let value: Value

  func body(content: Content) -> some View {
    content.animation(
      reduceMotion ? (reducedAnimation ?? .none) : animation,
      value: value
    )
  }
}

extension View {
  /// Apply animation with reduced motion support
  func motionSafeAnimation<Value: Equatable>(
    _ animation: Animation,
    reduced: Animation? = nil,
    value: Value
  ) -> some View {
    modifier(MotionSafeAnimationModifier(
      animation: animation,
      reducedAnimation: reduced,
      value: value
    ))
  }

  /// Apply standard animation with automatic reduced motion fallback
  func standardAnimation<Value: Equatable>(value: Value) -> some View {
    motionSafeAnimation(.standard, reduced: .easeInOut(duration: 0.15), value: value)
  }

  /// Apply micro animation with automatic reduced motion fallback
  func microAnimation<Value: Equatable>(value: Value) -> some View {
    motionSafeAnimation(.micro, reduced: .none, value: value)
  }
}

// MARK: - Transition Presets

extension AnyTransition {
  /// Slide in from bottom with fade
  static var slideUp: AnyTransition {
    .asymmetric(
      insertion: .move(edge: .bottom).combined(with: .opacity),
      removal: .move(edge: .bottom).combined(with: .opacity)
    )
  }

  /// Scale with fade
  static var scaleAndFade: AnyTransition {
    .asymmetric(
      insertion: .scale(scale: 0.9).combined(with: .opacity),
      removal: .scale(scale: 0.9).combined(with: .opacity)
    )
  }

  /// Card flip effect
  static var cardFlip: AnyTransition {
    .asymmetric(
      insertion: .scale(scale: 0.8).combined(with: .opacity),
      removal: .scale(scale: 1.1).combined(with: .opacity)
    )
  }
}

// MARK: - Interactive Animation States

struct PressedButtonState: ViewModifier {
  let isPressed: Bool

  func body(content: Content) -> some View {
    content
      .scaleEffect(isPressed ? 0.96 : 1.0)
      .opacity(isPressed ? 0.9 : 1.0)
      .animation(.micro, value: isPressed)
  }
}

extension View {
  func pressedState(_ isPressed: Bool) -> some View {
    modifier(PressedButtonState(isPressed: isPressed))
  }
}
