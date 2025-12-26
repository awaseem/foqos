//
//  FocusStreak.swift
//  foqos
//
//  Model for tracking focus streaks and gamification
//

import Foundation
import SwiftData

@Model
class FocusStreak {
  var currentStreak: Int = 0
  var longestStreak: Int = 0
  var lastFocusDate: Date?
  var totalFocusSeconds: Double = 0
  var weeklyGoalSeconds: Double = 10 * 60 * 60 // 10 hours default

  // Weekly tracking
  var weekStartDate: Date?
  var weeklyFocusSeconds: Double = 0

  init() {
    self.currentStreak = 0
    self.longestStreak = 0
    self.totalFocusSeconds = 0
    self.weeklyGoalSeconds = 10 * 60 * 60
    self.weeklyFocusSeconds = 0
  }

  // MARK: - Computed Properties

  var totalFocusHours: Double {
    totalFocusSeconds / 3600
  }

  var weeklyFocusHours: Double {
    weeklyFocusSeconds / 3600
  }

  var weeklyGoalHours: Double {
    get { weeklyGoalSeconds / 3600 }
    set { weeklyGoalSeconds = newValue * 3600 }
  }

  var weeklyProgress: Double {
    guard weeklyGoalSeconds > 0 else { return 0 }
    return min(1.0, weeklyFocusSeconds / weeklyGoalSeconds)
  }

  var streakIsActive: Bool {
    guard let lastDate = lastFocusDate else { return false }
    return Calendar.current.isDateInYesterday(lastDate) ||
           Calendar.current.isDateInToday(lastDate)
  }

  var daysUntilStreakLost: Int? {
    guard streakIsActive, let lastDate = lastFocusDate else { return nil }
    if Calendar.current.isDateInToday(lastDate) {
      return 2 // Today + tomorrow
    } else {
      return 1 // Just today
    }
  }

  // MARK: - Methods

  func recordSession(duration: TimeInterval) {
    totalFocusSeconds += duration
    weeklyFocusSeconds += duration

    let today = Date()
    let calendar = Calendar.current

    // Check if we need to reset weekly tracking
    if let weekStart = weekStartDate {
      if !calendar.isDate(weekStart, equalTo: today, toGranularity: .weekOfYear) {
        // New week, reset weekly tracking
        weekStartDate = calendar.startOfDay(for: today)
        weeklyFocusSeconds = duration
      }
    } else {
      weekStartDate = calendar.startOfDay(for: today)
    }

    // Update streak
    if calendar.isDateInToday(lastFocusDate ?? .distantPast) {
      // Already focused today, just add time
    } else if streakIsActive {
      // Focused yesterday or today, extend streak
      currentStreak += 1
    } else {
      // Streak broken, start new one
      currentStreak = 1
    }

    longestStreak = max(longestStreak, currentStreak)
    lastFocusDate = today
  }

  func resetWeeklyProgress() {
    weeklyFocusSeconds = 0
    weekStartDate = Date()
  }

  // MARK: - Static Methods

  static func fetchOrCreate(in context: ModelContext) -> FocusStreak {
    let descriptor = FetchDescriptor<FocusStreak>()
    if let existing = try? context.fetch(descriptor).first {
      return existing
    }

    let newStreak = FocusStreak()
    context.insert(newStreak)
    return newStreak
  }
}

// MARK: - Streak Level

enum StreakLevel: Int, CaseIterable {
  case beginner = 0     // 0-2 days
  case developing = 3   // 3-6 days
  case committed = 7    // 7-13 days
  case dedicated = 14   // 14-29 days
  case master = 30      // 30+ days

  static func level(for streak: Int) -> StreakLevel {
    switch streak {
    case 0...2: return .beginner
    case 3...6: return .developing
    case 7...13: return .committed
    case 14...29: return .dedicated
    default: return .master
    }
  }

  var title: String {
    switch self {
    case .beginner: return "Getting Started"
    case .developing: return "Building Momentum"
    case .committed: return "Committed"
    case .dedicated: return "Dedicated"
    case .master: return "Focus Master"
    }
  }

  var color: String {
    switch self {
    case .beginner: return "#94a3b8"     // Gray
    case .developing: return "#22c55e"   // Green
    case .committed: return "#3b82f6"    // Blue
    case .dedicated: return "#8b5cf6"    // Purple
    case .master: return "#f59e0b"       // Amber
    }
  }

  var nextMilestone: Int? {
    switch self {
    case .beginner: return 3
    case .developing: return 7
    case .committed: return 14
    case .dedicated: return 30
    case .master: return nil
    }
  }
}
