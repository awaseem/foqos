//
//  StreakCard.swift
//  foqos
//
//  Component for displaying focus streak progress
//

import SwiftUI

struct StreakCard: View {
  let currentStreak: Int
  let longestStreak: Int
  let weeklyProgress: Double
  let weeklyGoalHours: Double
  let weeklyFocusHours: Double

  @EnvironmentObject var themeManager: ThemeManager

  private var streakLevel: StreakLevel {
    StreakLevel.level(for: currentStreak)
  }

  private var nextMilestone: Int? {
    streakLevel.nextMilestone
  }

  private var daysToNextMilestone: Int? {
    guard let milestone = nextMilestone else { return nil }
    return milestone - currentStreak
  }

  var body: some View {
    VStack(alignment: .leading, spacing: Spacing.md) {
      // Header
      HStack {
        VStack(alignment: .leading, spacing: Spacing.xxs) {
          Text("Focus Streak")
            .font(.headline)
            .foregroundColor(.primary)

          Text(streakLevel.title)
            .font(.caption)
            .foregroundColor(Color(hex: streakLevel.color))
        }

        Spacer()

        // Streak flame icon
        ZStack {
          Circle()
            .fill(Color(hex: streakLevel.color).opacity(0.2))
            .frame(width: 44, height: 44)

          Image(systemName: "flame.fill")
            .font(.title2)
            .foregroundColor(Color(hex: streakLevel.color))
        }
      }

      // Main streak number
      HStack(alignment: .lastTextBaseline, spacing: Spacing.xs) {
        Text("\(currentStreak)")
          .font(.system(size: 48, weight: .bold, design: .rounded))
          .foregroundColor(.primary)

        Text(currentStreak == 1 ? "day" : "days")
          .font(.title3)
          .foregroundColor(.secondary)
      }

      // Progress to next milestone
      if let milestone = nextMilestone, let daysRemaining = daysToNextMilestone {
        VStack(alignment: .leading, spacing: Spacing.xs) {
          HStack {
            Text("Next milestone: \(milestone) days")
              .font(.caption)
              .foregroundColor(.secondary)

            Spacer()

            Text("\(daysRemaining) to go")
              .font(.caption)
              .fontWeight(.medium)
              .foregroundColor(Color(hex: streakLevel.color))
          }

          // Progress bar
          GeometryReader { geometry in
            ZStack(alignment: .leading) {
              RoundedRectangle(cornerRadius: CornerRadius.xs)
                .fill(Color.secondary.opacity(0.2))

              RoundedRectangle(cornerRadius: CornerRadius.xs)
                .fill(Color(hex: streakLevel.color))
                .frame(width: geometry.size.width * milestoneProgress)
                .animation(.standard, value: milestoneProgress)
            }
          }
          .frame(height: 6)
        }
      } else {
        // Master level badge
        HStack(spacing: Spacing.xs) {
          Image(systemName: "crown.fill")
            .foregroundColor(.orange)
          Text("You've reached the highest level!")
            .font(.caption)
            .foregroundColor(.secondary)
        }
      }

      Divider()
        .padding(.vertical, Spacing.xs)

      // Weekly progress
      VStack(alignment: .leading, spacing: Spacing.xs) {
        HStack {
          Text("Weekly Goal")
            .font(.subheadline)
            .fontWeight(.medium)

          Spacer()

          Text("\(String(format: "%.1f", weeklyFocusHours)) / \(String(format: "%.0f", weeklyGoalHours))h")
            .font(.subheadline)
            .foregroundColor(.secondary)
        }

        // Weekly progress bar
        GeometryReader { geometry in
          ZStack(alignment: .leading) {
            RoundedRectangle(cornerRadius: CornerRadius.xs)
              .fill(Color.secondary.opacity(0.2))

            RoundedRectangle(cornerRadius: CornerRadius.xs)
              .fill(themeManager.themeColor)
              .frame(width: geometry.size.width * min(1.0, weeklyProgress))
              .animation(.standard, value: weeklyProgress)
          }
        }
        .frame(height: 8)

        // Progress percentage
        HStack {
          Text("\(Int(weeklyProgress * 100))% complete")
            .font(.caption)
            .foregroundColor(.secondary)

          Spacer()

          if weeklyProgress >= 1.0 {
            HStack(spacing: Spacing.xxs) {
              Image(systemName: "checkmark.circle.fill")
                .foregroundColor(.green)
              Text("Goal achieved!")
                .font(.caption)
                .fontWeight(.medium)
                .foregroundColor(.green)
            }
          }
        }
      }

      // Stats row
      HStack(spacing: Spacing.lg) {
        StatItem(title: "Longest", value: "\(longestStreak)", unit: "days")
        Divider().frame(height: 30)
        StatItem(title: "This Week", value: String(format: "%.1f", weeklyFocusHours), unit: "hours")
      }
      .padding(.top, Spacing.xs)
    }
    .padding(Spacing.md)
    .background(
      RoundedRectangle(cornerRadius: CornerRadius.lg)
        .fill(Color(.secondarySystemBackground))
    )
  }

  private var milestoneProgress: Double {
    guard let milestone = nextMilestone else { return 1.0 }
    let previousMilestone = StreakLevel.allCases
      .filter { $0.rawValue < streakLevel.rawValue }
      .last?.nextMilestone ?? 0
    let range = milestone - previousMilestone
    let progress = currentStreak - previousMilestone
    return Double(progress) / Double(range)
  }
}

// MARK: - Stat Item
private struct StatItem: View {
  let title: String
  let value: String
  let unit: String

  var body: some View {
    VStack(alignment: .leading, spacing: Spacing.xxs) {
      Text(title)
        .font(.caption)
        .foregroundColor(.secondary)

      HStack(alignment: .lastTextBaseline, spacing: 2) {
        Text(value)
          .font(.title3)
          .fontWeight(.semibold)

        Text(unit)
          .font(.caption)
          .foregroundColor(.secondary)
      }
    }
  }
}

#Preview {
  VStack(spacing: 20) {
    StreakCard(
      currentStreak: 12,
      longestStreak: 15,
      weeklyProgress: 0.65,
      weeklyGoalHours: 10,
      weeklyFocusHours: 6.5
    )
    .environmentObject(ThemeManager.shared)

    StreakCard(
      currentStreak: 35,
      longestStreak: 35,
      weeklyProgress: 1.2,
      weeklyGoalHours: 10,
      weeklyFocusHours: 12
    )
    .environmentObject(ThemeManager.shared)
  }
  .padding()
  .background(Color(.systemGroupedBackground))
}
