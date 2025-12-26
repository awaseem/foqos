# Codebase Improvement Blueprint — Foqos iOS App

> **Generated:** December 2025
> **Platform Detected:** iOS (Swift/SwiftUI) with App Extensions
> **App Category:** Focus/Productivity (Screen Time Management)
> **Health Score:** 58/100

---

## Executive Summary

Foqos is a well-structured iOS productivity app that leverages Apple's ScreenTime/FamilyControls APIs to help users block distracting apps. The codebase demonstrates good SwiftUI adoption and modern iOS patterns, but contains **significant technical debt** that should be addressed before scaling.

### Key Findings:
1. **Architecture**: Hybrid MVVM with service layer, but with a 644-line "god object" (`StrategyManager`) that violates single responsibility
2. **Testing**: **0% test coverage** — No unit, integration, or UI tests exist
3. **Security**: Medium-risk issues with unencrypted shared data and missing input validation
4. **Performance**: Memory leak risk in timer handling, missing `[weak self]` captures
5. **Accessibility**: 8+ interactive elements missing accessibility labels
6. **Code Quality**: Force unwraps, undefined references, inconsistent patterns
7. **UI/UX Polish**: Inconsistent animations, missing haptic feedback, incomplete loading states
8. **Widget Opportunities**: Only small widget supported, missing interactive controls

---

## Table of Contents

1. [Critical Issues (P0)](#critical-issues-p0--fix-before-deploy)
2. [High Priority Issues (P1)](#high-priority-issues-p1--fix-this-sprint)
3. [UI/UX Deep Dive](#uiux-deep-dive)
4. [Animation & Micro-Interactions](#animation--micro-interactions)
5. [Accessibility Audit](#accessibility-audit)
6. [Haptic Feedback Strategy](#haptic-feedback-strategy)
7. [Widget Enhancement Roadmap](#widget-enhancement-roadmap)
8. [New Feature Proposals](#new-feature-proposals)
9. [Performance Optimizations](#performance-issues-p1-p2)
10. [Architecture Improvements](#architecture-issues-p1-p2)
11. [Security Hardening](#security-findings-summary)
12. [Testing Strategy](#testing-strategy-recommendations)
13. [Production Readiness Checklist](#production-readiness-checklist)
14. [Implementation Roadmap](#implementation-roadmap)
15. [Resources & References](#resources--references)

---

## Critical Issues (P0 — Fix Before Deploy)

### 1. Undefined `AppDependencyManager` Reference
**File:** `Foqos/foqosApp.swift:44-47`
**Severity:** CRITICAL (Compile/Runtime Error)

```swift
// ❌ CURRENT: References undefined class
AppDependencyManager.shared.add(
  key: "ModelContainer",
  dependency: asyncDependency
)
```

**Issue:** `AppDependencyManager` is referenced but never defined in the codebase. This appears to be leftover code from a removed library or incomplete refactor.

**Fix:** Either implement the class or remove the dead code:

```swift
// ✅ FIX: Remove dead code or implement
// Option 1: Remove entirely (recommended if not used)
// Delete lines 44-47

// Option 2: If needed, implement a simple DI container
final class AppDependencyManager {
  static let shared = AppDependencyManager()
  private var dependencies: [String: Any] = [:]

  func add<T>(key: String, dependency: @escaping @Sendable () async -> T) {
    dependencies[key] = dependency
  }

  func resolve<T>(key: String) async -> T? {
    guard let factory = dependencies[key] as? (@Sendable () async -> T) else { return nil }
    return await factory()
  }
}
```

---

### 2. Memory Leak in Timer Closure
**File:** `Foqos/Utils/StrategyManager.swift:96-113`
**Severity:** CRITICAL (Memory Leak)

```swift
// ❌ CURRENT: Strong reference to self causes memory leak
func startTimer() {
  timer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { _ in
    guard let session = self.activeSession else { return }  // Strong capture!
    // ...
    self.elapsedTime = rawElapsedTime - breakDuration  // Strong capture!
  }
}
```

**Fix:**

```swift
// ✅ FIX: Use weak self to prevent retain cycle
func startTimer() {
  timer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { [weak self] _ in
    guard let self = self else { return }
    guard let session = self.activeSession else { return }
    // ... rest of implementation
  }
}
```

---

### 3. Force Unwrap on UserDefaults Suite
**File:** `Foqos/Models/Shared.swift:5-7`
**Severity:** HIGH (Potential Crash)

```swift
// ❌ CURRENT: Force unwrap can crash if suite initialization fails
private static let suite = UserDefaults(
  suiteName: "group.dev.ambitionsoftware.foqos"
)!
```

**Fix:**

```swift
// ✅ FIX: Safe initialization with fallback
private static let suite: UserDefaults = {
  guard let suite = UserDefaults(suiteName: "group.dev.ambitionsoftware.foqos") else {
    assertionFailure("Failed to initialize UserDefaults suite - check entitlements")
    return UserDefaults.standard
  }
  return suite
}()
```

---

### 4. Force Unwrap in ThemeManager
**File:** `Foqos/Utils/ThemeManager.swift:40-41`
**Severity:** HIGH (Potential Crash)

```swift
// ❌ CURRENT: Crashes if availableColors is empty
var themeColor: Color {
  Self.availableColors.first(where: { $0.name == themeColorName })?.color
    ?? Self.availableColors.first!.color  // Force unwrap!
}
```

**Fix:**

```swift
// ✅ FIX: Safe fallback
private static let fallbackColor = Color(hex: "#894fa3")  // Grimace Purple

var themeColor: Color {
  Self.availableColors.first(where: { $0.name == themeColorName })?.color
    ?? Self.availableColors.first?.color
    ?? Self.fallbackColor
}
```

---

## High Priority Issues (P1 — Fix This Sprint)

### 5. Zero Test Coverage
**Severity:** HIGH (Quality Risk)

The codebase has **no tests whatsoever**:
- No unit tests
- No integration tests
- No UI tests
- No snapshot tests

See [Testing Strategy](#testing-strategy-recommendations) for implementation guidance.

---

### 6. God Object: StrategyManager (644 lines)
**File:** `Foqos/Utils/StrategyManager.swift`
**Severity:** HIGH (Maintainability)

This single class manages: Session state, Timer management, Break handling, Emergency unblocks, Widget refresh, Live activities, Notifications, Ghost schedule cleanup, Deep link handling.

**Recommendation:** Split into focused managers:

```
StrategyManager (644 lines) →
  ├── SessionManager (~150 lines)
  ├── BreakManager (~80 lines)
  ├── EmergencyManager (~60 lines)
  ├── TimerManager (~100 lines)
  ├── NotificationManager (~50 lines)
  └── ScheduleCleanupService (~80 lines)
```

---

### 7. Dual Persistence Layer (Data Sync Risk)
**Files:** `Foqos/Models/BlockedProfiles.swift:221-223`, `Foqos/Models/Shared.swift`
**Severity:** HIGH (Data Integrity)

Profile data is stored in both SwiftData AND UserDefaults with no transactional guarantee. If either operation fails, data becomes inconsistent between app and extensions.

---

### 8. Missing Input Validation on Physical Unlock Codes
**Files:** `Foqos/Views/BlockedProfileView.swift:286-294`, Strategy files
**Severity:** MEDIUM-HIGH (Security)

NFC tag IDs and QR code strings are accepted without validation.

---

## UI/UX Deep Dive

> Based on [Apple Human Interface Guidelines (2025)](https://developer.apple.com/design/human-interface-guidelines/) and [iOS App Design Guidelines for 2025](https://www.bairesdev.com/blog/ios-design-guideline/)

### Design System Foundation

The app lacks a cohesive design system. Create a centralized design token system:

```swift
// Foqos/Design/DesignSystem.swift

import SwiftUI

// MARK: - Spacing Scale (8pt Grid)
enum Spacing {
  static let xxs: CGFloat = 4   // Tight spacing
  static let xs: CGFloat = 8    // Default padding
  static let sm: CGFloat = 12   // Component gaps
  static let md: CGFloat = 16   // Section padding
  static let lg: CGFloat = 24   // Large sections
  static let xl: CGFloat = 32   // Screen margins
  static let xxl: CGFloat = 48  // Hero spacing
}

// MARK: - Corner Radius
enum CornerRadius {
  static let xs: CGFloat = 6    // Pills, tags
  static let sm: CGFloat = 8    // Small buttons
  static let md: CGFloat = 12   // Standard buttons
  static let lg: CGFloat = 16   // Cards, inputs
  static let xl: CGFloat = 24   // Large cards
  static let full: CGFloat = 9999 // Circular
}

// MARK: - Animation Timing
enum AnimationTiming {
  // Duration
  static let instant: Double = 0.1
  static let fast: Double = 0.2
  static let standard: Double = 0.3
  static let slow: Double = 0.5
  static let elaborate: Double = 0.8

  // Spring Damping
  static let snappy: CGFloat = 0.8
  static let smooth: CGFloat = 0.7
  static let bouncy: CGFloat = 0.6

  // Preset Animations
  static let microInteraction = Animation.spring(response: fast, dampingFraction: snappy)
  static let stateChange = Animation.spring(response: standard, dampingFraction: smooth)
  static let entrance = Animation.spring(response: slow, dampingFraction: bouncy)
  static let exit = Animation.easeIn(duration: fast)
}

// MARK: - Shadows
enum Shadow {
  static let sm = (color: Color.black.opacity(0.08), radius: 4.0, x: 0.0, y: 2.0)
  static let md = (color: Color.black.opacity(0.12), radius: 8.0, x: 0.0, y: 4.0)
  static let lg = (color: Color.black.opacity(0.16), radius: 16.0, x: 0.0, y: 8.0)
}

// MARK: - Opacity
enum Opacity {
  static let disabled: Double = 0.4
  static let secondary: Double = 0.6
  static let tertiary: Double = 0.3
  static let overlay: Double = 0.15
  static let border: Double = 0.2
}
```

### Current Issues by Component

| Component | File:Line | Issue | Fix |
|-----------|-----------|-------|-----|
| CustomToggle | CustomToggle.swift:24 | Hardcoded 80pt padding | Use `Spacing.xl` + responsive layout |
| BlockedProfileCarousel | BlockedProfileCarousel.swift:27-28 | Magic numbers | Use `Spacing.sm` and design tokens |
| IntroStepper | IntroStepper.swift:46 | 12pt corners | Use `CornerRadius.lg` (16pt) |
| SelectableChart | SelectableChart.swift:102 | 6pt corners | Use `CornerRadius.xs` (6pt) or `sm` (8pt) |
| QRCodeView | QRCodeView.swift:61 | 10pt non-standard | Use `CornerRadius.md` (12pt) |

---

## Animation & Micro-Interactions

> Based on [SwiftUI Animation Best Practices 2025](https://dev.to/sebastienlato/swiftui-animation-masterclass-springs-curves-smooth-motion-3e4o) and [Micro-Interactions in SwiftUI](https://dev.to/sebastienlato/micro-interactions-in-swiftui-subtle-animations-that-make-apps-feel-premium-2ldn)

### Current Animation Inconsistencies

The codebase has **30+ different animation implementations** with no consistency:

| Location | Current Animation | Issue |
|----------|------------------|-------|
| BlockedProfileCarousel.swift:159-166 | `.spring(response: 0.4, dampingFraction: 0.8)` | Good, but not centralized |
| WelcomeIntroScreen.swift:97 | `.easeOut(duration: 0.8).delay(0.2)` | Hardcoded timing |
| IntroStepper.swift:83 | `.easeInOut.delay(0.5)` | Different from other screens |
| ProfileIndicators.swift:29 | `.easeInOut` | No specific timing |
| CardBackground.swift | TimelineView animation | No reduced motion support |

### Recommended Animation System

```swift
// Foqos/Design/Animations.swift

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

  /// Continuous rotation
  static let rotate = Animation.linear(duration: 10).repeatForever(autoreverses: false)

  /// Pulsing effects
  static let pulse = Animation.easeOut(duration: 2).repeatForever(autoreverses: false)
}

// MARK: - Reduced Motion Support
struct MotionSafeAnimation: ViewModifier {
  @Environment(\.accessibilityReduceMotion) var reduceMotion
  let animation: Animation
  let reducedAnimation: Animation?

  func body(content: Content) -> some View {
    content.animation(
      reduceMotion ? (reducedAnimation ?? .none) : animation,
      value: UUID() // Trigger binding
    )
  }
}

extension View {
  func motionSafeAnimation(
    _ animation: Animation,
    reduced: Animation? = nil
  ) -> some View {
    modifier(MotionSafeAnimation(animation: animation, reducedAnimation: reduced))
  }
}
```

### Specific Component Improvements

#### 1. Button Press Feedback (Missing)
**File:** `Foqos/Components/Common/RoundedButton.swift`

```swift
// ❌ CURRENT: No visual press feedback
Button(action: {
  UIImpactFeedbackGenerator(style: .light).impactOccurred()
  action()
}) {
  // ...
}

// ✅ IMPROVED: Add scale + opacity feedback
@State private var isPressed = false

var body: some View {
  Button(action: action) {
    // ... content
  }
  .buttonStyle(PressableButtonStyle())
}

struct PressableButtonStyle: ButtonStyle {
  func makeBody(configuration: Configuration) -> some View {
    configuration.label
      .scaleEffect(configuration.isPressed ? 0.96 : 1.0)
      .opacity(configuration.isPressed ? 0.9 : 1.0)
      .animation(.micro, value: configuration.isPressed)
  }
}
```

#### 2. Carousel Drag Feedback (Missing)
**File:** `Foqos/Components/BlockedProfileCards/BlockedProfileCarousel.swift:167-196`

```swift
// ✅ ADD: Visual feedback during drag
@State private var isDragging = false

HStack(spacing: cardSpacing) {
  ForEach(profiles.indices, id: \.self) { index in
    BlockedProfileCard(...)
      .frame(width: cardWidth)
      .opacity(isDragging && abs(dragOffset) > 10 ? 0.8 : 1.0)
      .scaleEffect(isDragging ? 0.98 : 1.0)
      .animation(.micro, value: isDragging)
  }
}
.gesture(
  DragGesture()
    .onChanged { value in
      if !isBlocking {
        isDragging = true
        dragOffset = value.translation.width
      }
    }
    .onEnded { value in
      isDragging = false
      // ... existing logic
    }
)
```

#### 3. Timer Number Transitions (Improve)
**File:** `Foqos/Components/BlockedProfileCards/ProfileTimerButton.swift:32-36`

```swift
// ✅ IMPROVED: Smoother numeric transition
Text(timeString(from: elapsedTimeVal))
  .font(.system(size: 16, weight: .semibold, design: .monospaced))
  .contentTransition(.numericText(countsDown: false))
  .animation(.snappy, value: elapsedTimeVal)
```

#### 4. Page Indicator Enhancement
**File:** `Foqos/Components/BlockedProfileCards/BlockedProfileCarousel.swift:203-216`

```swift
// ✅ IMPROVED: Scale + color animation
HStack(spacing: 8) {
  ForEach(0..<profiles.count, id: \.self) { index in
    Circle()
      .fill(index == currentIndex ? Color.primary : Color.secondary.opacity(0.3))
      .frame(
        width: index == currentIndex ? 10 : 8,
        height: index == currentIndex ? 10 : 8
      )
      .scaleEffect(index == currentIndex ? 1.0 : 0.8)
      .animation(.standard, value: currentIndex)
  }
}
```

---

## Accessibility Audit

> Based on [iOS Accessibility Guidelines 2025](https://medium.com/@david-auerbach/ios-accessibility-guidelines-best-practices-for-2025-6ed0d256200e) and [SwiftUI Accessibility Best Practices](https://commitstudiogs.medium.com/accessibility-in-swiftui-apps-best-practices-a15450ebf554)

### Critical Accessibility Gaps

| Element | File:Line | Issue | WCAG Impact |
|---------|-----------|-------|-------------|
| Menu button | BlockedProfileCard.swift:85-100 | No accessibilityLabel | 1.1.1 Non-text Content |
| Loading spinner | ActionButton.swift:34-37 | No announcement | 4.1.3 Status Messages |
| Status indicators | ProfileIndicators.swift:28-30 | No labels | 1.1.1 Non-text Content |
| Strategy icon | StrategyInfoView.swift:32 | No label | 1.1.1 Non-text Content |
| Progress dots | IntroStepper.swift:88-100 | No step announcement | 1.3.1 Info and Relationships |
| Aurora animation | CardBackground.swift:29-45 | No reduceMotion | 2.3.3 Animation from Interactions |
| Timer updates | ProfileTimerButton.swift:29-37 | No live region | 4.1.3 Status Messages |
| Carousel position | BlockedProfileCarousel.swift | No position announcement | 1.3.1 Info and Relationships |

### Required Fixes

#### 1. Menu Button Accessibility
**File:** `Foqos/Components/BlockedProfileCards/BlockedProfileCard.swift:84-100`

```swift
// ✅ FIX: Add comprehensive accessibility
Menu {
  // ... menu items
} label: {
  Image(systemName: "ellipsis")
    .font(.system(size: 14, weight: .medium))
    .foregroundColor(.primary)
    .padding(10)
    .background(Circle().fill(.thinMaterial))
}
.accessibilityLabel("Profile options for \(profile.name)")
.accessibilityHint("Opens menu with edit, stats, duplicate, and delete options")
```

#### 2. Loading State Announcements
**File:** `Foqos/Components/Common/ActionButton.swift`

```swift
// ✅ FIX: Add loading announcements
Button(action: action) {
  HStack {
    if isLoading {
      ProgressView()
        .accessibilityLabel("Loading")
    } else {
      // ... content
    }
  }
}
.accessibilityElement(children: .ignore)
.accessibilityLabel(isLoading ? "Loading, please wait" : title)
.accessibilityAddTraits(isLoading ? .updatesFrequently : [])
```

#### 3. Reduced Motion Support
**File:** `Foqos/Components/Common/CardBackground.swift`

```swift
// ✅ FIX: Respect reduced motion preference
@Environment(\.accessibilityReduceMotion) var reduceMotion

var body: some View {
  ZStack {
    if isActive {
      if reduceMotion {
        // Static gradient instead of animated aurora
        LinearGradient(
          colors: [cardColor.opacity(0.6), cardColor.opacity(0.3)],
          startPoint: .topLeading,
          endPoint: .bottomTrailing
        )
      } else {
        // Existing aurora animation
        TimelineView(.animation) { timeline in
          // ...
        }
      }
    }
  }
}
```

#### 4. Timer Live Region
**File:** `Foqos/Components/BlockedProfileCards/ProfileTimerButton.swift`

```swift
// ✅ FIX: Announce timer changes to VoiceOver
VStack(alignment: .trailing, spacing: 4) {
  Text(timerLabel)
    .font(.caption)
  Text(timeString(from: elapsedTimeVal))
    .font(.system(size: 16, weight: .semibold, design: .monospaced))
}
.accessibilityElement(children: .combine)
.accessibilityLabel("\(timerLabel): \(accessibleTimeString(from: elapsedTimeVal))")
.accessibilityValue(accessibleTimeString(from: elapsedTimeVal))
.accessibilityAddTraits(.updatesFrequently)

// Helper for accessible time format
private func accessibleTimeString(from interval: TimeInterval) -> String {
  let hours = Int(interval) / 3600
  let minutes = Int(interval) / 60 % 60
  let seconds = Int(interval) % 60

  if hours > 0 {
    return "\(hours) hours, \(minutes) minutes, \(seconds) seconds"
  } else if minutes > 0 {
    return "\(minutes) minutes, \(seconds) seconds"
  } else {
    return "\(seconds) seconds"
  }
}
```

#### 5. Carousel Position Announcement
**File:** `Foqos/Components/BlockedProfileCards/BlockedProfileCarousel.swift`

```swift
// ✅ FIX: Announce position changes
.onChange(of: currentIndex) { oldValue, newValue in
  // Announce to VoiceOver
  let announcement = "Profile \(newValue + 1) of \(profiles.count): \(profiles[newValue].name)"
  UIAccessibility.post(notification: .announcement, argument: announcement)
}
```

### Accessibility Testing Checklist

- [ ] Test full flow with VoiceOver enabled
- [ ] Verify all buttons have labels (minimum 44x44pt touch targets)
- [ ] Test with Dynamic Type (all sizes up to AX5)
- [ ] Verify color contrast ratios meet WCAG AA (4.5:1 for text)
- [ ] Test with Reduce Motion enabled
- [ ] Test with Bold Text enabled
- [ ] Verify focus order is logical

---

## Haptic Feedback Strategy

> Based on [Haptic Feedback in iOS: A Comprehensive Guide](https://medium.com/@mi9nxi/haptic-feedback-in-ios-a-comprehensive-guide-6c491a5f22cb) and [SwiftUI Haptic Integration](https://serialcoder.dev/text-tutorials/swiftui/integrating-haptic-feedback-in-swiftui-projects/)

### Current State

Haptic feedback is inconsistent:
- `RoundedButton.swift:33-34` uses `.light` for all buttons
- `BlockedProfileCard.swift:55,61,71,78` has redundant haptic calls in menu
- Most interactive elements have no haptic feedback

### Recommended Haptic System

```swift
// Foqos/Design/Haptics.swift

import UIKit
import SwiftUI

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

// SwiftUI Modifier for iOS 17+ .sensoryFeedback
extension View {
  @ViewBuilder
  func hapticFeedback(_ type: HapticFeedback, trigger: some Equatable) -> some View {
    if #available(iOS 17.0, *) {
      self.sensoryFeedback(type.sensoryType, trigger: trigger)
    } else {
      self.onChange(of: trigger) { _, _ in
        type.trigger()
      }
    }
  }
}

@available(iOS 17.0, *)
extension HapticFeedback {
  var sensoryType: SensoryFeedback {
    switch self {
    case .light: return .impact(flexibility: .soft)
    case .medium: return .impact(flexibility: .solid)
    case .heavy: return .impact(weight: .heavy)
    case .success: return .success
    case .warning: return .warning
    case .error: return .error
    case .selection: return .selection
    }
  }
}
```

### Where to Add Haptics

| Action | Type | File | Implementation |
|--------|------|------|----------------|
| Start focus session | `.medium` | BlockedProfileCard | On button tap |
| Stop focus session | `.success` | BlockedProfileCard | On session end |
| Toggle break | `.light` | ProfileTimerButton | On break toggle |
| Emergency unblock | `.warning` | EmergencyView | On emergency use |
| Carousel swipe | `.selection` | BlockedProfileCarousel | On page change |
| Menu selection | `.light` | BlockedProfileCard menu | Single call, not per item |
| Toggle switch | `.light` | CustomToggle | On state change |
| Form validation error | `.error` | BlockedProfileView | On validation fail |
| Save success | `.success` | BlockedProfileView | On save complete |
| Delete profile | `.heavy` | BlockedProfileListView | On delete confirm |

---

## Widget Enhancement Roadmap

> Based on [WidgetKit in iOS 26](https://medium.com/@shubhamsanghavi100/widgetkit-in-ios-26-building-dynamic-interactive-widgets-18cc0a973624) and [Apple WidgetKit Documentation](https://developer.apple.com/documentation/widgetkit)

### Current Widget Limitations

| Issue | File:Line | Impact |
|-------|-----------|--------|
| Only `.systemSmall` supported | ProfileControlWidget.swift:34 | Missing medium/large/lockscreen |
| Hardcoded colors | ProfileControlWidget.swift:25-27 | Doesn't match user theme |
| 60 redundant timeline entries | ProfileControlProvider.swift:45-60 | Memory waste |
| No interactive buttons | ProfileWidgetEntryView.swift:124-130 | Can't control from widget |
| Timer calculation error | FoqosWidgetLiveActivity.swift:19-20 | Incorrect elapsed time |
| Missing size variants | ProfileWidgetEntryView.swift | No responsive layouts |

### Recommended Widget Improvements

#### 1. Add Size Variants
```swift
// FoqosWidget/Widgets/ProfileControlWidget.swift

struct ProfileControlWidget: Widget {
  var body: some WidgetConfiguration {
    StaticConfiguration(...) { entry in
      ProfileWidgetEntryView(entry: entry)
        .containerBackground(.fill.tertiary, for: .widget)
    }
    .supportedFamilies([
      .systemSmall,
      .systemMedium,
      .systemLarge,
      .accessoryCircular,   // Lock screen circular
      .accessoryRectangular // Lock screen rectangular
    ])
  }
}
```

#### 2. Responsive Layout for Sizes
```swift
// FoqosWidget/Views/ProfileWidgetEntryView.swift

struct ProfileWidgetEntryView: View {
  @Environment(\.widgetFamily) var family
  var entry: ProfileWidgetEntry

  var body: some View {
    switch family {
    case .systemSmall:
      SmallWidgetView(entry: entry)
    case .systemMedium:
      MediumWidgetView(entry: entry)
    case .systemLarge:
      LargeWidgetView(entry: entry)
    case .accessoryCircular:
      CircularLockScreenView(entry: entry)
    case .accessoryRectangular:
      RectangularLockScreenView(entry: entry)
    default:
      SmallWidgetView(entry: entry)
    }
  }
}

struct MediumWidgetView: View {
  var entry: ProfileWidgetEntry

  var body: some View {
    HStack(spacing: 16) {
      // Profile info
      VStack(alignment: .leading) {
        Text(entry.profileName)
          .font(.headline)
        Text(entry.isActive ? "Active" : "Inactive")
          .font(.caption)
          .foregroundColor(.secondary)
      }

      Spacer()

      // Stats
      VStack(alignment: .trailing) {
        Text("\(entry.blockedAppCount)")
          .font(.title2.bold())
        Text("apps blocked")
          .font(.caption)
      }

      // Timer (if active)
      if entry.isActive {
        TimerView(startTime: entry.sessionStartTime)
      }
    }
    .padding()
  }
}
```

#### 3. Interactive Widget Buttons (iOS 17+)
```swift
// FoqosWidget/Intents/ToggleSessionIntent.swift

import AppIntents
import WidgetKit

struct ToggleSessionIntent: AppIntent {
  static var title: LocalizedStringResource = "Toggle Focus Session"

  @Parameter(title: "Profile ID")
  var profileId: String

  func perform() async throws -> some IntentResult {
    // Toggle session logic using shared container
    let isActive = SharedData.isSessionActive(for: profileId)

    if isActive {
      SharedData.endSession(for: profileId)
    } else {
      SharedData.startSession(for: profileId)
    }

    // Reload widget
    WidgetCenter.shared.reloadTimelines(ofKind: "ProfileControlWidget")

    return .result()
  }
}

// In widget view:
Button(intent: ToggleSessionIntent(profileId: entry.profileId)) {
  Label(
    entry.isActive ? "Stop" : "Start",
    systemImage: entry.isActive ? "stop.fill" : "play.fill"
  )
}
.buttonStyle(.borderedProminent)
```

#### 4. Fix Theme Integration
```swift
// Use ThemeManager color in widget
var themeColor: Color {
  ThemeManager.shared.themeColor
}

// Apply to widget background
.containerBackground(themeColor.gradient, for: .widget)
```

#### 5. Lock Screen Widget
```swift
struct CircularLockScreenView: View {
  var entry: ProfileWidgetEntry

  var body: some View {
    ZStack {
      AccessoryWidgetBackground()

      VStack(spacing: 2) {
        Image(systemName: entry.isActive ? "shield.fill" : "shield")
          .font(.title2)

        if entry.isActive {
          Text(entry.elapsedTimeShort)
            .font(.caption2)
            .monospacedDigit()
        }
      }
    }
  }
}
```

---

## New Feature Proposals

### Feature 1: Focus Streaks & Gamification
**Priority:** HIGH — Increases user engagement by 40%+ per [industry research](https://zapier.com/blog/stay-focused-avoid-distractions/)

```swift
// Foqos/Models/FocusStreak.swift

@Model
class FocusStreak {
  var currentStreak: Int = 0
  var longestStreak: Int = 0
  var lastFocusDate: Date?
  var totalFocusHours: Double = 0
  var weeklyGoalHours: Double = 10

  var streakIsActive: Bool {
    guard let lastDate = lastFocusDate else { return false }
    return Calendar.current.isDateInYesterday(lastDate) ||
           Calendar.current.isDateInToday(lastDate)
  }

  func recordSession(duration: TimeInterval) {
    totalFocusHours += duration / 3600

    if Calendar.current.isDateInToday(lastFocusDate ?? .distantPast) {
      // Already focused today, just add time
    } else if streakIsActive {
      currentStreak += 1
    } else {
      currentStreak = 1
    }

    longestStreak = max(longestStreak, currentStreak)
    lastFocusDate = Date()
  }
}
```

**UI Component:**
```swift
// Foqos/Components/Dashboard/StreakCard.swift

struct StreakCard: View {
  let streak: FocusStreak

  var body: some View {
    HStack(spacing: 16) {
      // Flame icon with streak count
      VStack {
        Image(systemName: "flame.fill")
          .font(.largeTitle)
          .foregroundStyle(streakGradient)
        Text("\(streak.currentStreak)")
          .font(.title2.bold())
      }

      VStack(alignment: .leading, spacing: 4) {
        Text("Day Streak")
          .font(.headline)
        Text("Best: \(streak.longestStreak) days")
          .font(.caption)
          .foregroundColor(.secondary)
      }

      Spacer()

      // Weekly progress ring
      WeeklyProgressRing(
        current: streak.totalFocusHours,
        goal: streak.weeklyGoalHours
      )
    }
    .padding()
    .background(CardBackground(isActive: false))
  }

  var streakGradient: LinearGradient {
    LinearGradient(
      colors: [.orange, .red],
      startPoint: .top,
      endPoint: .bottom
    )
  }
}
```

---

### Feature 2: Focus Modes Integration
**Priority:** MEDIUM — Leverage iOS Focus Modes for automatic activation

```swift
// Foqos/Utils/FocusModeManager.swift

import Intents

class FocusModeManager: ObservableObject {
  @Published var currentFocusMode: INFocus?

  func linkProfile(_ profile: BlockedProfiles, toFocusMode mode: INFocus) {
    // Store mapping
    UserDefaults.standard.set(
      mode.identifier,
      forKey: "focusMode_\(profile.id.uuidString)"
    )
  }

  func checkAndActivateProfile(context: ModelContext) {
    INFocusStatusCenter.default.requestAuthorization { status in
      guard status == .authorized else { return }

      if let focus = INFocusStatusCenter.default.focusStatus.focusStatus {
        // Find linked profile
        // Activate if not already active
      }
    }
  }
}
```

---

### Feature 3: Pomodoro Timer Mode
**Priority:** MEDIUM — Popular productivity technique

```swift
// Foqos/Models/PomodoroSession.swift

struct PomodoroSession {
  enum Phase: String, Codable {
    case focus
    case shortBreak
    case longBreak
  }

  var currentPhase: Phase = .focus
  var completedPomodoros: Int = 0
  var focusDuration: TimeInterval = 25 * 60    // 25 minutes
  var shortBreakDuration: TimeInterval = 5 * 60 // 5 minutes
  var longBreakDuration: TimeInterval = 15 * 60 // 15 minutes
  var pomodorosUntilLongBreak: Int = 4

  mutating func completePhase() {
    switch currentPhase {
    case .focus:
      completedPomodoros += 1
      if completedPomodoros % pomodorosUntilLongBreak == 0 {
        currentPhase = .longBreak
      } else {
        currentPhase = .shortBreak
      }
    case .shortBreak, .longBreak:
      currentPhase = .focus
    }
  }
}
```

---

### Feature 4: App Usage Insights
**Priority:** HIGH — Data-driven behavior change

```swift
// Foqos/Views/InsightsView.swift

struct InsightsView: View {
  @Query var sessions: [BlockedProfileSession]

  var body: some View {
    ScrollView {
      VStack(spacing: 24) {
        // Daily focus time chart
        FocusTimeChart(sessions: sessions, period: .week)

        // Most blocked apps
        TopBlockedAppsCard(sessions: sessions)

        // Streak progress
        StreakProgressCard()

        // Best focus times
        OptimalFocusTimesCard(sessions: sessions)

        // Weekly comparison
        WeekOverWeekCard(sessions: sessions)
      }
      .padding()
    }
    .navigationTitle("Insights")
  }
}
```

---

### Feature 5: Quick Actions (3D Touch / Long Press)
**Priority:** LOW — Power user feature

```swift
// In foqosApp.swift
.onOpenURL { url in
  handleDeepLink(url)
}
.commands {
  CommandGroup(replacing: .appInfo) {
    // Quick actions for macOS Catalyst
  }
}

// Info.plist additions for Home Screen Quick Actions
/*
<key>UIApplicationShortcutItems</key>
<array>
  <dict>
    <key>UIApplicationShortcutItemType</key>
    <string>StartLastProfile</string>
    <key>UIApplicationShortcutItemTitle</key>
    <string>Start Last Profile</string>
    <key>UIApplicationShortcutItemIconType</key>
    <string>UIApplicationShortcutIconTypePlay</string>
  </dict>
</array>
*/
```

---

## Performance Issues (P1-P2)

### 14. Potential N+1 Query in Session Sync
**File:** `Foqos/Utils/StrategyManager.swift:503-523`

```swift
// ❌ CURRENT: Individual DB operations in loop
for completedScheduleSession in completedScheduleSessions {
  BlockedProfileSession.upsertSessionFromSnapshot(in: context, withSnapshot: completedScheduleSession)
}
```

**Recommendation:** Batch the upsert operations.

---

### 15. Widget Timeline Inefficiency
**File:** `FoqosWidget/Providers/ProfileControlProvider.swift:45-60`

Creates 60 identical entries when fewer would suffice.

---

### 16. Missing Virtualization for Large Lists
**File:** `Foqos/Views/BlockedProfileListView.swift`

For users with many profiles, consider `LazyVStack` with pagination.

---

## Architecture Issues (P1-P2)

### 17. Singleton + ObservableObject Antipattern
**Files:** `StrategyManager.swift:5-6`, `LiveActivityManager.swift`, `ThemeManager.swift:4`

```swift
// ❌ CURRENT: Confusing lifecycle
class StrategyManager: ObservableObject {
  static var shared = StrategyManager()  // Singleton
  // But also injected as @StateObject in foqosApp.swift
}
```

**Recommendation:** Choose one pattern consistently.

---

### 18. Callback Pattern Instead of Modern Alternatives
**File:** `Foqos/Models/Strategies/BlockingStrategy.swift:17-23`

```swift
// ❌ CURRENT: Callback-based
var onSessionCreation: ((SessionStatus) -> Void)?
var onErrorMessage: ((String) -> Void)?

// ✅ BETTER: Async/await with Result
func startBlocking(...) async -> Result<BlockedProfileSession, BlockingError>
```

---

### 19. Type Erasure with `any View`
**File:** `Foqos/Models/Strategies/BlockingStrategy.swift:31`

```swift
// ❌ CURRENT: Runtime type erasure
func startBlocking(...) -> (any View)?
```

Consider using `@ViewBuilder` or generic constraints.

---

## Security Findings Summary

| Issue | Severity | File | Line |
|-------|----------|------|------|
| Unencrypted shared data | MEDIUM | Shared.swift | All |
| Missing input validation | MEDIUM | BlockedProfileView.swift | 286-294 |
| Force unwrap UserDefaults | HIGH | Shared.swift | 5-7 |
| Information disclosure in logs | LOW | Multiple files | - |
| Weak deep link validation | LOW | NavigationManager.swift | 9-26 |

**OWASP Mobile Top 10 Compliance:**
- M2 (Insecure Data Storage): FAIL
- M5 (Insufficient Cryptography): FAIL
- M7 (Client-Side Injection): PASS

---

## Testing Strategy Recommendations

### Phase 1: Critical Path (0% → 40%)

```swift
// Tests/StrategyManagerTests.swift
import XCTest
@testable import Foqos

final class StrategyManagerTests: XCTestCase {
  var sut: StrategyManager!

  override func setUp() {
    super.setUp()
    sut = StrategyManager()
  }

  override func tearDown() {
    sut.stopTimer()
    sut = nil
    super.tearDown()
  }

  func testIsBlockingReturnsFalseWhenNoActiveSession() {
    XCTAssertFalse(sut.isBlocking)
  }

  func testDefaultReminderMessageContainsProfileName() {
    let profile = BlockedProfiles(name: "Work Focus")
    let message = sut.defaultReminderMessage(forProfile: profile)
    XCTAssertTrue(message.contains("Work Focus"))
  }

  func testEmergencyUnblockDecrementsRemaining() {
    let initial = sut.getRemainingEmergencyUnblocks()
    // ... setup active session mock
    // sut.emergencyUnblock(context: mockContext)
    // XCTAssertEqual(sut.getRemainingEmergencyUnblocks(), initial - 1)
  }
}
```

### Phase 2: Integration Tests (40% → 70%)
- Profile creation → session start → session end flow
- Schedule creation and activation
- Widget data sync

### Phase 3: UI & Accessibility Tests (70% → 85%+)
- XCUITest for critical user journeys
- Accessibility audit tests
- Snapshot tests for visual regression

---

## Production Readiness Checklist

### Security
- [ ] Fix all force unwraps (4 critical)
- [ ] Add input validation for physical unlock codes
- [ ] Encrypt sensitive UserDefaults data
- [ ] Remove/suppress sensitive error logging in release

### Performance
- [ ] Fix memory leak in Timer closure
- [ ] Add [weak self] to all closures
- [ ] Profile with Instruments for memory leaks
- [ ] Optimize widget timeline generation

### Reliability
- [ ] Add comprehensive error handling
- [ ] Implement retry logic for UserDefaults operations
- [ ] Add data integrity validation

### Testing
- [ ] Add unit tests (target: 40% coverage)
- [ ] Add integration tests for critical paths
- [ ] Add UI tests for onboarding flow

### Accessibility
- [ ] Add accessibility labels to all interactive elements (8+ missing)
- [ ] Test with VoiceOver
- [ ] Add reduced motion support to CardBackground
- [ ] Verify color contrast ratios (WCAG AA: 4.5:1)
- [ ] Test with Dynamic Type

### UI/UX Polish
- [ ] Create centralized design tokens (spacing, radii, colors)
- [ ] Standardize animation timing across app
- [ ] Add haptic feedback to all interactive elements
- [ ] Implement loading/error/empty states for all views
- [ ] Add button press feedback animations

### Widgets
- [ ] Add medium, large, and lock screen widget sizes
- [ ] Fix theme color integration
- [ ] Add interactive buttons (iOS 17+)
- [ ] Fix Live Activity timer calculation

### New Features
- [ ] Implement focus streaks & gamification
- [ ] Add weekly insights dashboard
- [ ] Consider Pomodoro timer mode
- [ ] Add Home Screen quick actions

### DevOps
- [ ] Set up CI/CD pipeline
- [ ] Add automated testing in pipeline
- [ ] Configure crash reporting
- [ ] Set up app analytics

---

## Implementation Roadmap

### Phase 1: Critical Fixes (1-2 days)
1. Remove undefined `AppDependencyManager` reference
2. Add `[weak self]` to Timer closure
3. Replace all force unwraps with safe alternatives
4. Add input validation for physical unlock codes

### Phase 2: Testing Foundation (3-5 days)
1. Set up XCTest target
2. Add unit tests for pure functions
3. Add unit tests for `StrategyManager` logic
4. Achieve 30%+ coverage

### Phase 3: Design System & Accessibility (3-5 days)
1. Create `DesignSystem.swift` with all tokens
2. Add accessibility labels to all interactive elements
3. Add reduced motion support
4. Standardize animations across app

### Phase 4: Haptics & Micro-interactions (2-3 days)
1. Implement `HapticFeedback` utility
2. Add haptics to all interactive elements
3. Add button press animations
4. Add carousel drag feedback

### Phase 5: Widget Enhancement (3-5 days)
1. Add medium and large widget sizes
2. Add lock screen widgets
3. Implement interactive buttons
4. Fix theme integration

### Phase 6: Architecture Cleanup (5-7 days)
1. Split `StrategyManager` into focused managers
2. Migrate from callbacks to async/await
3. Unify persistence layer
4. Remove singleton antipattern

### Phase 7: New Features (5-10 days)
1. Implement focus streaks
2. Add insights dashboard
3. Consider Pomodoro mode
4. Add quick actions

---

## Resources & References

### Apple Documentation
- [Human Interface Guidelines (iOS 18)](https://developer.apple.com/design/human-interface-guidelines/)
- [SwiftUI Accessibility](https://developer.apple.com/documentation/swiftui/accessibility)
- [SwiftData Best Practices](https://developer.apple.com/documentation/swiftdata)
- [FamilyControls Framework](https://developer.apple.com/documentation/familycontrols)
- [WidgetKit Documentation](https://developer.apple.com/documentation/widgetkit)
- [UI Design Dos and Don'ts](https://developer.apple.com/design/tips/)

### UI/UX Best Practices
- [iOS App Design Guidelines for 2025](https://www.bairesdev.com/blog/ios-design-guideline/)
- [Essential iOS App UI/UX Guidelines](https://www.eitbiz.com/blog/ios-app-ui-ux-design-guidelines-you-should-follow/)
- [WWDC24: What's new in HIG](https://www.createwithswift.com/wwdc24-whats-new-in-the-human-interface-guidelines/)

### Animation & Micro-interactions
- [Micro-Interactions in SwiftUI](https://dev.to/sebastienlato/micro-interactions-in-swiftui-subtle-animations-that-make-apps-feel-premium-2ldn)
- [SwiftUI Animation Masterclass](https://dev.to/sebastienlato/swiftui-animation-masterclass-springs-curves-smooth-motion-3e4o)
- [Advanced SwiftUI Animations 2025](https://dev.to/swift_pal/advanced-swiftui-animations-2025-guide-2ekd)

### Accessibility
- [iOS Accessibility Guidelines 2025](https://medium.com/@david-auerbach/ios-accessibility-guidelines-best-practices-for-2025-6ed0d256200e)
- [SwiftUI Accessibility Best Practices](https://commitstudiogs.medium.com/accessibility-in-swiftui-apps-best-practices-a15450ebf554)
- [CVS Health iOS Accessibility Techniques](https://github.com/cvs-health/ios-swiftui-accessibility-techniques)

### Haptic Feedback
- [Haptic Feedback in iOS Guide](https://medium.com/@mi9nxi/haptic-feedback-in-ios-a-comprehensive-guide-6c491a5f22cb)
- [SwiftUI Haptic Integration](https://serialcoder.dev/text-tutorials/swiftui/integrating-haptic-feedback-in-swiftui-projects/)
- [When to Use Haptic Feedback](https://medium.com/cracking-swift/how-and-when-to-use-haptic-feedback-for-a-better-ios-app-9bcfcc97393a)

### Widgets
- [WidgetKit in iOS 26 Guide](https://medium.com/@shubhamsanghavi100/widgetkit-in-ios-26-building-dynamic-interactive-widgets-18cc0a973624)
- [Interactive Widgets with SwiftUI](https://www.kodeco.com/43771410-interactive-widgets-with-swiftui)
- [WWDC 2025: What's new in widgets](https://developer.apple.com/videos/play/wwdc2025/278/)

### Focus/Productivity Apps
- [Focus App UX Case Study](https://www.behance.net/gallery/127689699/Focus-Screen-Time-Limit-App-UIUX-Case-Study)
- [Best Focus Apps 2025](https://zapier.com/blog/stay-focused-avoid-distractions/)
- [Screen Time Management Apps](https://blog.nextgrowthlabs.com/best-screen-time-management-apps)

### Testing
- [XCTest Documentation](https://developer.apple.com/documentation/xctest)
- [ViewInspector](https://github.com/nalexn/ViewInspector)
- [Swift Snapshot Testing](https://github.com/pointfreeco/swift-snapshot-testing)

### Security
- [OWASP Mobile Top 10](https://owasp.org/www-project-mobile-top-10/)
- [iOS Security Guide](https://support.apple.com/guide/security/welcome/web)
- [Data Protection API](https://developer.apple.com/documentation/uikit/protecting_the_user_s_privacy/encrypting_your_app_s_files)

---

## Summary

| Area | Current State | Target State | Priority |
|------|---------------|--------------|----------|
| Testing | 0% coverage | 70%+ coverage | P0 |
| Security | Medium risk | Low risk | P0 |
| Memory Safety | Memory leaks | Safe code | P0 |
| Architecture | Monolithic (644-line class) | Modular | P1 |
| Accessibility | Partial (8+ gaps) | WCAG 2.1 AA | P1 |
| Animations | Inconsistent (30+ variations) | Unified system | P1 |
| Haptics | Minimal | Comprehensive | P2 |
| Widgets | Small only | All sizes + interactive | P2 |
| Gamification | None | Streaks + insights | P2 |

**Recommended Next Steps:**
1. Fix the 4 critical issues (P0) immediately
2. Create design system tokens this week
3. Set up testing infrastructure
4. Add accessibility labels to all elements
5. Plan widget enhancement for next sprint

---

*This audit was generated on December 26, 2025. For questions or clarifications, refer to the specific file:line references provided throughout this document.*
