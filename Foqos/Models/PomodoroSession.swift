//
//  PomodoroSession.swift
//  foqos
//
//  Model for Pomodoro technique focus sessions
//

import Foundation
import SwiftData

// MARK: - Pomodoro Session Model

@Model
class PomodoroSession {
  var id: UUID = UUID()
  var startTime: Date = Date()
  var endTime: Date?

  // Session configuration
  var focusDurationMinutes: Int = 25
  var shortBreakMinutes: Int = 5
  var longBreakMinutes: Int = 15
  var sessionsUntilLongBreak: Int = 4

  // Session state
  var completedPomodoros: Int = 0
  // Store as raw value for SwiftData compatibility
  var currentPhaseRawValue: String = PomodoroPhase.focus.rawValue
  var isActive: Bool = false

  // Associated profile
  var profileId: String?

  // Computed property for type-safe access
  var currentPhase: PomodoroPhase {
    get { PomodoroPhase(rawValue: currentPhaseRawValue) ?? .focus }
    set { currentPhaseRawValue = newValue.rawValue }
  }

  init(
    focusDuration: Int = 25,
    shortBreak: Int = 5,
    longBreak: Int = 15,
    sessionsUntilLongBreak: Int = 4,
    profileId: String? = nil
  ) {
    self.focusDurationMinutes = focusDuration
    self.shortBreakMinutes = shortBreak
    self.longBreakMinutes = longBreak
    self.sessionsUntilLongBreak = sessionsUntilLongBreak
    self.profileId = profileId
  }

  // MARK: - Computed Properties

  var currentPhaseDurationMinutes: Int {
    switch currentPhase {
    case .focus:
      return focusDurationMinutes
    case .shortBreak:
      return shortBreakMinutes
    case .longBreak:
      return longBreakMinutes
    }
  }

  var currentPhaseDurationSeconds: TimeInterval {
    TimeInterval(currentPhaseDurationMinutes * 60)
  }

  var isBreakPhase: Bool {
    currentPhase == .shortBreak || currentPhase == .longBreak
  }

  var shouldTakeLongBreak: Bool {
    completedPomodoros > 0 && completedPomodoros % sessionsUntilLongBreak == 0
  }

  var totalFocusTimeSeconds: TimeInterval {
    TimeInterval(completedPomodoros * focusDurationMinutes * 60)
  }

  // MARK: - Methods

  func startSession() {
    isActive = true
    startTime = Date()
    currentPhase = .focus
  }

  func completePhase() {
    switch currentPhase {
    case .focus:
      completedPomodoros += 1
      currentPhase = shouldTakeLongBreak ? .longBreak : .shortBreak
    case .shortBreak, .longBreak:
      currentPhase = .focus
    }
  }

  func endSession() {
    isActive = false
    endTime = Date()
  }

  func reset() {
    completedPomodoros = 0
    currentPhase = .focus
    isActive = false
    endTime = nil
  }
}

// MARK: - Pomodoro Phase

enum PomodoroPhase: String, Codable {
  case focus
  case shortBreak
  case longBreak

  var displayName: String {
    switch self {
    case .focus:
      return "Focus"
    case .shortBreak:
      return "Short Break"
    case .longBreak:
      return "Long Break"
    }
  }

  var icon: String {
    switch self {
    case .focus:
      return "brain.head.profile"
    case .shortBreak:
      return "cup.and.saucer.fill"
    case .longBreak:
      return "figure.walk"
    }
  }

  var color: String {
    switch self {
    case .focus:
      return "#8b5cf6"  // Purple
    case .shortBreak:
      return "#22c55e"  // Green
    case .longBreak:
      return "#3b82f6"  // Blue
    }
  }
}

// MARK: - Pomodoro Preset Configurations

enum PomodoroPreset: CaseIterable {
  case classic        // 25/5/15
  case short          // 15/3/10
  case long           // 50/10/30
  case custom

  var focusMinutes: Int {
    switch self {
    case .classic: return 25
    case .short: return 15
    case .long: return 50
    case .custom: return 25
    }
  }

  var shortBreakMinutes: Int {
    switch self {
    case .classic: return 5
    case .short: return 3
    case .long: return 10
    case .custom: return 5
    }
  }

  var longBreakMinutes: Int {
    switch self {
    case .classic: return 15
    case .short: return 10
    case .long: return 30
    case .custom: return 15
    }
  }

  var displayName: String {
    switch self {
    case .classic: return "Classic (25/5/15)"
    case .short: return "Short (15/3/10)"
    case .long: return "Extended (50/10/30)"
    case .custom: return "Custom"
    }
  }

  var description: String {
    switch self {
    case .classic:
      return "The original Pomodoro technique: 25 min focus, 5 min break, 15 min long break"
    case .short:
      return "Shorter sessions for those who need frequent breaks"
    case .long:
      return "Extended deep work sessions for maximum productivity"
    case .custom:
      return "Create your own custom timing"
    }
  }
}
