//
//  StrategyManagerTests.swift
//  FoqosTests
//
//  Unit tests for StrategyManager functionality
//

import XCTest
@testable import foqos

final class StrategyManagerTests: XCTestCase {

  var sut: StrategyManager!

  override func setUp() {
    super.setUp()
    sut = StrategyManager.shared
    // Reset state before each test
    sut.stopTimer()
    sut.elapsedTime = 0
  }

  override func tearDown() {
    sut.stopTimer()
    sut = nil
    super.tearDown()
  }

  // MARK: - Timer Tests

  func testStartTimer_ShouldIncrementElapsedTime() {
    // Given
    let initialTime = sut.elapsedTime

    // When
    sut.startTimer()

    // Wait for timer to tick
    let expectation = XCTestExpectation(description: "Timer increments")
    DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
      expectation.fulfill()
    }
    wait(for: [expectation], timeout: 2.0)

    // Then
    XCTAssertGreaterThan(sut.elapsedTime, initialTime, "Elapsed time should increase after timer starts")

    // Cleanup
    sut.stopTimer()
  }

  func testStopTimer_ShouldStopIncrementing() {
    // Given
    sut.startTimer()

    // Wait briefly
    let startExpectation = XCTestExpectation(description: "Timer started")
    DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
      startExpectation.fulfill()
    }
    wait(for: [startExpectation], timeout: 1.0)

    // When
    sut.stopTimer()
    let timeAfterStop = sut.elapsedTime

    // Wait and verify time doesn't change
    let stopExpectation = XCTestExpectation(description: "Timer stopped")
    DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
      stopExpectation.fulfill()
    }
    wait(for: [stopExpectation], timeout: 2.0)

    // Then
    XCTAssertEqual(sut.elapsedTime, timeAfterStop, "Elapsed time should not change after timer stops")
  }

  // MARK: - State Tests

  func testIsBlocking_WhenNoActiveSession_ShouldBeFalse() {
    // Given no active session
    sut.activeSession = nil

    // Then
    XCTAssertFalse(sut.isBlocking, "isBlocking should be false when there's no active session")
  }

  func testIsBreakAvailable_WhenSessionInactive_ShouldBeFalse() {
    // Given no active session
    sut.activeSession = nil

    // Then
    XCTAssertFalse(sut.isBreakAvailable, "Break should not be available when session is inactive")
  }

  // MARK: - Break Duration Calculation Tests

  func testCalculateBreakDuration_WhenNoBreak_ShouldReturnZero() {
    // Given no break times set

    // When
    let duration = sut.calculateBreakDuration()

    // Then
    XCTAssertEqual(duration, 0, "Break duration should be 0 when no break has occurred")
  }

  // MARK: - Error Handling Tests

  func testErrorMessage_ShouldBeNilByDefault() {
    // Then
    XCTAssertNil(sut.errorMessage, "Error message should be nil by default")
  }

  // MARK: - Singleton Tests

  func testShared_ShouldReturnSameInstance() {
    // When
    let instance1 = StrategyManager.shared
    let instance2 = StrategyManager.shared

    // Then
    XCTAssertTrue(instance1 === instance2, "Shared should return the same instance")
  }
}

// MARK: - FocusStreak Tests

final class FocusStreakTests: XCTestCase {

  func testStreakLevel_ForBeginner_ShouldReturnBeginner() {
    // Given
    let streak = 2

    // When
    let level = StreakLevel.level(for: streak)

    // Then
    XCTAssertEqual(level, .beginner, "Streak of 2 should be beginner level")
  }

  func testStreakLevel_ForDeveloping_ShouldReturnDeveloping() {
    // Given
    let streak = 5

    // When
    let level = StreakLevel.level(for: streak)

    // Then
    XCTAssertEqual(level, .developing, "Streak of 5 should be developing level")
  }

  func testStreakLevel_ForCommitted_ShouldReturnCommitted() {
    // Given
    let streak = 10

    // When
    let level = StreakLevel.level(for: streak)

    // Then
    XCTAssertEqual(level, .committed, "Streak of 10 should be committed level")
  }

  func testStreakLevel_ForDedicated_ShouldReturnDedicated() {
    // Given
    let streak = 20

    // When
    let level = StreakLevel.level(for: streak)

    // Then
    XCTAssertEqual(level, .dedicated, "Streak of 20 should be dedicated level")
  }

  func testStreakLevel_ForMaster_ShouldReturnMaster() {
    // Given
    let streak = 50

    // When
    let level = StreakLevel.level(for: streak)

    // Then
    XCTAssertEqual(level, .master, "Streak of 50 should be master level")
  }

  func testStreakLevel_Title_ShouldReturnCorrectStrings() {
    XCTAssertEqual(StreakLevel.beginner.title, "Getting Started")
    XCTAssertEqual(StreakLevel.developing.title, "Building Momentum")
    XCTAssertEqual(StreakLevel.committed.title, "Committed")
    XCTAssertEqual(StreakLevel.dedicated.title, "Dedicated")
    XCTAssertEqual(StreakLevel.master.title, "Focus Master")
  }

  func testStreakLevel_NextMilestone_ShouldReturnCorrectValues() {
    XCTAssertEqual(StreakLevel.beginner.nextMilestone, 3)
    XCTAssertEqual(StreakLevel.developing.nextMilestone, 7)
    XCTAssertEqual(StreakLevel.committed.nextMilestone, 14)
    XCTAssertEqual(StreakLevel.dedicated.nextMilestone, 30)
    XCTAssertNil(StreakLevel.master.nextMilestone)
  }
}

// MARK: - HapticFeedback Tests

final class HapticFeedbackTests: XCTestCase {

  func testAllFeedbackTypes_ShouldNotCrash() {
    // This test verifies that triggering haptic feedback doesn't crash
    // Note: Actual haptic effect won't work in test environment

    // When/Then - should not throw
    HapticFeedback.light.trigger()
    HapticFeedback.medium.trigger()
    HapticFeedback.heavy.trigger()
    HapticFeedback.success.trigger()
    HapticFeedback.warning.trigger()
    HapticFeedback.error.trigger()
    HapticFeedback.selection.trigger()
  }
}

// MARK: - Design System Tests

final class DesignSystemTests: XCTestCase {

  func testSpacing_ValuesAreCorrect() {
    XCTAssertEqual(Spacing.xxs, 4)
    XCTAssertEqual(Spacing.xs, 8)
    XCTAssertEqual(Spacing.sm, 12)
    XCTAssertEqual(Spacing.md, 16)
    XCTAssertEqual(Spacing.lg, 24)
    XCTAssertEqual(Spacing.xl, 32)
    XCTAssertEqual(Spacing.xxl, 48)
  }

  func testCornerRadius_ValuesAreCorrect() {
    XCTAssertEqual(CornerRadius.xs, 6)
    XCTAssertEqual(CornerRadius.sm, 8)
    XCTAssertEqual(CornerRadius.md, 12)
    XCTAssertEqual(CornerRadius.lg, 16)
    XCTAssertEqual(CornerRadius.xl, 24)
    XCTAssertEqual(CornerRadius.full, 9999)
  }

  func testOpacity_ValuesAreInRange() {
    XCTAssertGreaterThanOrEqual(Opacity.disabled, 0)
    XCTAssertLessThanOrEqual(Opacity.disabled, 1)
    XCTAssertGreaterThanOrEqual(Opacity.secondary, 0)
    XCTAssertLessThanOrEqual(Opacity.secondary, 1)
    XCTAssertGreaterThanOrEqual(Opacity.tertiary, 0)
    XCTAssertLessThanOrEqual(Opacity.tertiary, 1)
  }

  func testTouchTarget_MeetsMinimumSize() {
    XCTAssertGreaterThanOrEqual(TouchTarget.minimum, 44, "Touch target should be at least 44pt per Apple HIG")
    XCTAssertGreaterThanOrEqual(TouchTarget.comfortable, TouchTarget.minimum)
    XCTAssertGreaterThanOrEqual(TouchTarget.large, TouchTarget.comfortable)
  }
}

// MARK: - Animation Tests

final class AnimationTests: XCTestCase {

  func testAnimationPresets_ShouldExist() {
    // Verify animation extensions exist and can be accessed
    // These are compile-time checks essentially
    _ = Animation.micro
    _ = Animation.standard
    _ = Animation.transition
    _ = Animation.entrance
    _ = Animation.snappy
    _ = Animation.bouncy
  }
}
