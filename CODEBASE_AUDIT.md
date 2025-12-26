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

    if session.isBreakActive {
      guard let breakStartTime = session.breakStartTime else { return }
      let timeSinceBreakStart = Date().timeIntervalSince(breakStartTime)
      let breakDurationInSeconds = TimeInterval(session.blockedProfile.breakTimeInMinutes * 60)
      self.elapsedTime = max(0, breakDurationInSeconds - timeSinceBreakStart)  // Strong capture!
    } else {
      let rawElapsedTime = Date().timeIntervalSince(session.startTime)
      let breakDuration = self.calculateBreakDuration()  // Strong capture!
      self.elapsedTime = rawElapsedTime - breakDuration
    }
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

    if session.isBreakActive {
      guard let breakStartTime = session.breakStartTime else { return }
      let timeSinceBreakStart = Date().timeIntervalSince(breakStartTime)
      let breakDurationInSeconds = TimeInterval(session.blockedProfile.breakTimeInMinutes * 60)
      self.elapsedTime = max(0, breakDurationInSeconds - timeSinceBreakStart)
    } else {
      let rawElapsedTime = Date().timeIntervalSince(session.startTime)
      let breakDuration = self.calculateBreakDuration()
      self.elapsedTime = rawElapsedTime - breakDuration
    }
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
    return UserDefaults.standard  // Fallback to standard (data won't sync with extensions)
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

**Recommendation:** Implement testing in phases:

**Phase 1 — Critical Path Unit Tests:**
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
    // Test emergency unblock logic
  }
}
```

**Phase 2 — SwiftUI View Tests with ViewInspector**

**Phase 3 — Integration Tests for Data Flow**

---

### 6. God Object: StrategyManager (644 lines)
**File:** `Foqos/Utils/StrategyManager.swift`
**Severity:** HIGH (Maintainability)

This single class manages:
- Session state
- Timer management
- Break handling
- Emergency unblocks
- Widget refresh
- Live activities
- Notifications
- Ghost schedule cleanup
- Deep link handling

**Recommendation:** Split into focused managers:

```
StrategyManager (644 lines) →
  ├── SessionManager (~150 lines) — Active session lifecycle
  ├── BreakManager (~80 lines) — Break start/stop logic
  ├── EmergencyManager (~60 lines) — Emergency unblock handling
  ├── TimerManager (~100 lines) — Timer lifecycle
  ├── NotificationManager (~50 lines) — Reminder scheduling
  └── ScheduleCleanupService (~80 lines) — Ghost schedule cleanup
```

---

### 7. Dual Persistence Layer (Data Sync Risk)
**Files:** `Foqos/Models/BlockedProfiles.swift:221-223`, `Foqos/Models/Shared.swift`
**Severity:** HIGH (Data Integrity)

Profile data is stored in both SwiftData AND UserDefaults with no transactional guarantee:

```swift
// BlockedProfiles.swift:221-224
// Update the snapshot
updateSnapshot(for: profile)  // Writes to UserDefaults

try context.save()  // Saves to SwiftData
```

If either operation fails, data becomes inconsistent between app and extensions.

**Recommendation:**
1. Make SwiftData the single source of truth
2. Treat UserDefaults snapshots as a cache
3. Add validation when reading from cache
4. Consider using Core Data's `NSPersistentCloudKitContainer` for cross-process sync

---

### 8. Missing Input Validation on Physical Unlock Codes
**Files:** `Foqos/Views/BlockedProfileView.swift:286-294`, Strategy files
**Severity:** MEDIUM-HIGH (Security)

NFC tag IDs and QR code strings are accepted without validation:

```swift
// ❌ CURRENT: No validation on scanned data
physicalReader.readNFCTag(
  onSuccess: { physicalUnblockNFCTagId = $0 }  // Stored directly
)
```

**Fix:**

```swift
// ✅ FIX: Add validation
func validatePhysicalUnlockCode(_ code: String) -> Result<String, ValidationError> {
  // Check length bounds
  guard code.count >= 4 && code.count <= 256 else {
    return .failure(.invalidLength)
  }

  // Check for malicious characters
  let allowedCharacters = CharacterSet.alphanumerics.union(.init(charactersIn: "-_"))
  guard code.unicodeScalars.allSatisfy({ allowedCharacters.contains($0) }) else {
    return .failure(.invalidCharacters)
  }

  return .success(code)
}

physicalReader.readNFCTag { rawId in
  switch validatePhysicalUnlockCode(rawId) {
  case .success(let validId):
    physicalUnblockNFCTagId = validId
  case .failure(let error):
    showError("Invalid code: \(error.localizedDescription)")
  }
}
```

---

### 9. Unencrypted Shared Data
**File:** `Foqos/Models/Shared.swift`
**Severity:** MEDIUM (Security)

Sensitive profile data stored in plaintext UserDefaults:
- Physical unlock codes (NFC/QR)
- Custom reminder messages
- Domain allowlists/blocklists
- Strategy configurations

**Recommendation:** Use Data Protection:

```swift
// ✅ Add file protection to app group container
private static let suite: UserDefaults = {
  guard let containerURL = FileManager.default.containerURL(
    forSecurityApplicationGroupIdentifier: "group.dev.ambitionsoftware.foqos"
  ) else {
    return UserDefaults.standard
  }

  // Set file protection
  try? FileManager.default.setAttributes(
    [.protectionKey: FileProtectionType.completeUntilFirstUserAuthentication],
    ofItemAtPath: containerURL.path
  )

  return UserDefaults(suiteName: "group.dev.ambitionsoftware.foqos") ?? .standard
}()
```

---

## UI/UX Issues (P1-P2)

### 10. Missing Accessibility Labels (8+ Elements)
**Severity:** HIGH (Accessibility/Legal)

| File | Line | Element | Issue |
|------|------|---------|-------|
| `BlockedProfileCard.swift` | 85-86 | Menu button (ellipsis) | No label |
| `ProfileIndicators.swift` | 28-30 | Status indicator dots | No label |
| `StrategyInfoView.swift` | 32 | Strategy icon | No label |
| `ActionButton.swift` | 36 | Loading spinner | No label |
| `RoundedButton.swift` | 40 | Icon in button | No context |
| `IntroStepper.swift` | 37-38, 58-59 | Nav buttons | No labels |

**Fix Example:**

```swift
// ❌ CURRENT
Image(systemName: "ellipsis")
  .font(.title2)

// ✅ FIX
Image(systemName: "ellipsis")
  .font(.title2)
  .accessibilityLabel("More options")
  .accessibilityHint("Opens menu with edit, duplicate, and delete actions")
```

---

### 11. Inconsistent Corner Radii
**Severity:** MEDIUM (Visual Polish)

| Value | Location | Issue |
|-------|----------|-------|
| 6pt | SelectableChart.swift:102 | Too small |
| 10pt | QRCodeView.swift:61 | Non-standard |
| 12pt | IntroStepper.swift:46 | Should be 16 |
| 16pt | Most buttons | Standard |
| 24pt | Cards | Standard |

**Recommendation:** Create design constants:

```swift
// Design/DesignConstants.swift
enum DesignConstants {
  enum CornerRadius {
    static let small: CGFloat = 8
    static let medium: CGFloat = 12
    static let large: CGFloat = 16
    static let extraLarge: CGFloat = 24
  }

  enum Spacing {
    static let xxs: CGFloat = 4
    static let xs: CGFloat = 8
    static let sm: CGFloat = 12
    static let md: CGFloat = 16
    static let lg: CGFloat = 24
    static let xl: CGFloat = 32
  }
}
```

---

### 12. Hardcoded Magic Numbers
**File:** `Foqos/Components/Common/CustomToggle.swift:24`
**Severity:** MEDIUM

```swift
// ❌ CURRENT: Hardcoded, not responsive
.padding(.trailing, 80)  // Why 80? Clips on small screens
```

---

### 13. Button Height Inconsistency During Loading
**File:** `Foqos/Components/Common/ActionButton.swift:50,72`
**Severity:** LOW (Visual Jump)

```swift
// Line 50: height = 40 (normal)
.frame(height: 40)

// Line 72: height = 50 (in GlassProminentIfAvailable)
.frame(height: 50)
```

This causes visual jumping when loading state toggles.

---

## Performance Issues (P1-P2)

### 14. Potential N+1 Query in Session Sync
**File:** `Foqos/Utils/StrategyManager.swift:503-523`

```swift
private func syncScheduleSessions(context: ModelContext) {
  // ...
  let completedScheduleSessions = SharedData.getCompletedSessionsForSchedular()
  for completedScheduleSession in completedScheduleSessions {  // Loop
    BlockedProfileSession.upsertSessionFromSnapshot(
      in: context,
      withSnapshot: completedScheduleSession  // Individual DB operation
    )
  }
}
```

**Recommendation:** Batch the upsert operations or use background context.

---

### 15. Missing Virtualization for Large Lists
**File:** `Foqos/Views/BlockedProfileListView.swift`

For users with many profiles, `List` should use `LazyVStack` with pagination or `List` should have `.listStyle(.plain)` for better performance.

---

## Architecture Issues (P1-P2)

### 16. Singleton + ObservableObject Antipattern
**Files:** `StrategyManager.swift:5-6`, `LiveActivityManager.swift`, `ThemeManager.swift:4`

```swift
// ❌ CURRENT: Confusing lifecycle
class StrategyManager: ObservableObject {
  static var shared = StrategyManager()  // Singleton
  // But also injected as @StateObject in foqosApp.swift
}
```

This creates confusion:
- Is it a singleton (one instance)?
- Or an ObservableObject (instance per view hierarchy)?

**Recommendation:** Choose one pattern consistently.

---

### 17. Callback Pattern Instead of Modern Alternatives
**File:** `Foqos/Models/Strategies/BlockingStrategy.swift:17-23`

```swift
// ❌ CURRENT: Callback-based
var onSessionCreation: ((SessionStatus) -> Void)?
var onErrorMessage: ((String) -> Void)?
```

**Recommendation:** Use async/await or Combine:

```swift
// ✅ BETTER: Async/await with Result
func startBlocking(
  context: ModelContext,
  profile: BlockedProfiles,
  forceStart: Bool
) async -> Result<BlockedProfileSession, BlockingError>
```

---

### 18. Type Erasure with `any View`
**File:** `Foqos/Models/Strategies/BlockingStrategy.swift:31`

```swift
// ❌ CURRENT: Runtime type erasure
func startBlocking(...) -> (any View)?
```

This loses compile-time type safety. Consider using `@ViewBuilder` or generic constraints.

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
- M2 (Insecure Data Storage): FAIL — Unencrypted UserDefaults
- M5 (Insufficient Cryptography): FAIL — No encryption on sensitive data
- M7 (Client-Side Injection): PASS — UUID format limits impact

---

## Testing Strategy Recommendations

### Immediate (0% → 40% Coverage)

1. **Unit Tests for Pure Functions:**
   - `DateFormatters.swift`
   - `FocusMessages.swift`
   - Timer calculations in `StrategyManager`

2. **Unit Tests for Business Logic:**
   - `BlockedProfiles` CRUD operations (mock SwiftData context)
   - `StrategyManager` state transitions
   - Emergency unblock logic

### Short-term (40% → 70% Coverage)

3. **Integration Tests:**
   - Profile creation → session start → session end flow
   - Schedule creation and activation
   - Widget data sync

4. **SwiftUI Preview Tests:**
   - Use ViewInspector for component testing
   - Snapshot tests for key screens

### Long-term (70% → 85%+ Coverage)

5. **UI Tests:**
   - Critical user journeys with XCUITest
   - Accessibility audit tests

---

## Production Readiness Checklist

### Security
- [ ] Fix all force unwraps (3 critical)
- [ ] Add input validation for physical unlock codes
- [ ] Encrypt sensitive UserDefaults data
- [ ] Remove/suppress sensitive error logging in release

### Performance
- [ ] Fix memory leak in Timer closure
- [ ] Add [weak self] to all closures
- [ ] Profile with Instruments for memory leaks
- [ ] Test with 50+ profiles for list performance

### Reliability
- [ ] Add comprehensive error handling
- [ ] Implement retry logic for UserDefaults operations
- [ ] Add data integrity validation between persistence layers

### Testing
- [ ] Add unit tests (target: 40% coverage)
- [ ] Add integration tests for critical paths
- [ ] Add UI tests for onboarding flow

### Accessibility
- [ ] Add accessibility labels to all interactive elements
- [ ] Test with VoiceOver
- [ ] Verify color contrast ratios
- [ ] Test with Dynamic Type

### DevOps
- [ ] Set up CI/CD pipeline (GitHub Actions or Xcode Cloud)
- [ ] Add automated testing in pipeline
- [ ] Configure crash reporting (Sentry/Firebase Crashlytics)
- [ ] Set up app analytics

### Documentation
- [ ] Add inline documentation to public APIs
- [ ] Create architecture decision records (ADRs)
- [ ] Document data flow between app and extensions
- [ ] Create runbook for common issues

---

## Priority Matrix

```
                    HIGH IMPACT
                        │
    ┌───────────────────┼───────────────────┐
    │                   │                   │
    │  P1: QUICK WINS   │  P0: DO FIRST     │
    │                   │                   │
    │  • A11y labels    │  • Fix force      │
    │  • Design tokens  │    unwraps        │
    │                   │  • Memory leak    │
    │                   │  • Add tests      │
LOW ├───────────────────┼───────────────────┤ HIGH
EFFORT                  │                   EFFORT
    │                   │                   │
    │  P3: BACKLOG      │  P2: PLAN IT      │
    │                   │                   │
    │  • Doc updates    │  • Refactor       │
    │  • Code cleanup   │    StrategyMgr    │
    │                   │  • Unify          │
    │                   │    persistence    │
    │                   │                   │
    └───────────────────┼───────────────────┘
                        │
                    LOW IMPACT
```

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

### Phase 3: Accessibility & UX (2-3 days)
1. Add accessibility labels to all interactive elements
2. Create design constants file
3. Standardize corner radii and spacing
4. Fix button height inconsistency

### Phase 4: Architecture Cleanup (5-7 days)
1. Split `StrategyManager` into focused managers
2. Migrate from callbacks to async/await
3. Evaluate unifying persistence layer
4. Remove singleton + ObservableObject antipattern

### Phase 5: Security Hardening (2-3 days)
1. Add encryption for sensitive UserDefaults data
2. Implement proper deep link validation
3. Add security review for all external inputs

---

## Resources & References

### Apple Documentation
- [Human Interface Guidelines (iOS 18)](https://developer.apple.com/design/human-interface-guidelines/)
- [SwiftUI Accessibility](https://developer.apple.com/documentation/swiftui/accessibility)
- [SwiftData Best Practices](https://developer.apple.com/documentation/swiftdata)
- [FamilyControls Framework](https://developer.apple.com/documentation/familycontrols)

### Testing
- [XCTest Documentation](https://developer.apple.com/documentation/xctest)
- [ViewInspector](https://github.com/nalexn/ViewInspector) — SwiftUI testing
- [Swift Snapshot Testing](https://github.com/pointfreeco/swift-snapshot-testing)

### Security
- [OWASP Mobile Top 10](https://owasp.org/www-project-mobile-top-10/)
- [iOS Security Guide](https://support.apple.com/guide/security/welcome/web)
- [Data Protection API](https://developer.apple.com/documentation/uikit/protecting_the_user_s_privacy/encrypting_your_app_s_files)

### Architecture
- [Modern Swift Concurrency](https://developer.apple.com/swift/blog/?id=38)
- [SwiftUI App Architecture](https://developer.apple.com/documentation/swiftui/model-data)

---

## Summary

Foqos is a functional iOS app with a solid feature set, but requires significant work before production scaling:

| Area | Current State | Target State | Priority |
|------|---------------|--------------|----------|
| Testing | 0% coverage | 70%+ coverage | P0 |
| Security | Medium risk | Low risk | P0 |
| Architecture | Monolithic | Modular | P1 |
| Accessibility | Partial | WCAG 2.1 AA | P1 |
| Performance | Memory leaks | Optimized | P0 |
| Code Quality | Force unwraps | Safe code | P0 |

**Recommended Next Steps:**
1. Fix the 4 critical issues (P0) immediately
2. Set up testing infrastructure this week
3. Plan architecture refactoring for next sprint
4. Schedule accessibility audit

---

*This audit was generated on December 26, 2025. For questions or clarifications, refer to the specific file:line references provided throughout this document.*
