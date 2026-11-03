import SwiftUI

struct ProfileLockStatusSection: View {
  @EnvironmentObject private var themeManager: ThemeManager

  let isLocked: Bool
  let isBlocking: Bool
  let onUnlock: () -> Void
  let onLock: () -> Void

  var body: some View {
    Section {
      HStack(alignment: .top, spacing: 12) {
        Image(systemName: isLocked ? "lock.fill" : "lock.open.fill")
          .font(.title3)
          .foregroundStyle(isLocked ? .orange : .green)
          .padding(.top, 2)

        VStack(alignment: .leading, spacing: 4) {
          Text(isLocked ? "Profile Locked" : "Unlocked for Editing")
            .font(.headline)
          Text(
            isLocked
              ? "Unlock with your password to make changes."
              : "Your password is still on. This profile locks again when you leave."
          )
          .font(.subheadline)
          .foregroundStyle(.secondary)
        }
      }
      .padding(.vertical, 4)

      Button(isLocked ? "Unlock Profile" : "Lock Now", action: isLocked ? onUnlock : onLock)
        .foregroundStyle(themeManager.themeColor)
        .disabled(isBlocking)
        .accessibilityIdentifier("profileLockAction")
    }
  }
}

#Preview {
  Form {
    ProfileLockStatusSection(isLocked: true, isBlocking: false, onUnlock: {}, onLock: {})
    ProfileLockStatusSection(isLocked: false, isBlocking: false, onUnlock: {}, onLock: {})
  }
  .environmentObject(ThemeManager())
}
