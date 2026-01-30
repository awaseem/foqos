import SwiftUI

struct PhysicalUnblockColumn: View {
  @EnvironmentObject var themeManager: ThemeManager

  let title: String
  let description: String
  let systemImage: String
  let id: String?
  let disabled: Bool
  let onSet: () -> Void
  let onUnset: () -> Void

  var body: some View {
    VStack(spacing: 16) {
      // Header with icon and title
      VStack(spacing: 10) {
        Image(systemName: systemImage)
          .font(.title2)
          .foregroundColor(.gray)

        HStack(spacing: 6) {
          Text(title)
            .font(.subheadline)
            .fontWeight(.medium)
            .foregroundColor(.primary)

          if id != nil {
            Image(systemName: "checkmark.circle.fill")
              .foregroundColor(themeManager.themeColor)
              .font(.caption)
          }
        }
      }
      .frame(minHeight: 40, maxHeight: 40)

      // Description
      VStack(spacing: 8) {
        Text(description)
          .font(.caption2)
          .foregroundColor(.secondary)
          .multilineTextAlignment(.center)
          .fixedSize(horizontal: false, vertical: true)
      }
      .frame(minHeight: 50, maxHeight: 50, alignment: .center)

      // Action button
      if id != nil {
        Button(action: {
          if !disabled {
            onUnset()
          }
        }) {
          HStack(spacing: 6) {
            Image(systemName: "xmark")
              .font(.system(size: 16, weight: .medium))
            Text("Remove")
              .fontWeight(.semibold)
              .font(.subheadline)
          }
          .frame(maxWidth: .infinity)
          .padding(.vertical, 12)
          .background(
            RoundedRectangle(cornerRadius: 16)
              .fill(.thinMaterial)
              .overlay(
                RoundedRectangle(cornerRadius: 16)
                  .stroke(Color.red.opacity(0.2), lineWidth: 1)
              )
          )
          .foregroundColor(.red)
        }
        .buttonStyle(PlainButtonStyle())
      } else {
        Button(action: {
          if !disabled {
            onSet()
          }
        }) {
          HStack(spacing: 6) {
            Image(systemName: "plus")
              .font(.system(size: 16, weight: .medium))
            Text("Set")
              .fontWeight(.semibold)
              .font(.subheadline)
          }
          .frame(maxWidth: .infinity)
          .padding(.vertical, 12)
          .background(
            RoundedRectangle(cornerRadius: 16)
              .fill(.thinMaterial)
              .overlay(
                RoundedRectangle(cornerRadius: 16)
                  .stroke(Color.primary.opacity(0.2), lineWidth: 1)
              )
          )
          .foregroundColor(.primary)
        }
        .buttonStyle(PlainButtonStyle())
      }
    }
    .frame(maxWidth: .infinity)
    .padding(.top, 12)
    .padding(.bottom, 8)
    .opacity(disabled ? 0.5 : 1)
  }
}

#Preview {
  NavigationStack {
    Form {
      Section("Not Set") {
        PhysicalUnblockColumn(
          title: "DO Card",
          description: "Set a specific DO Card that can only unlock this profile when active",
          systemImage: "wave.3.right",
          id: nil,
          disabled: false,
          onSet: { print("Set DO Card") },
          onUnset: { print("Unset DO Card") }
        )
      }

      Section("Set") {
        PhysicalUnblockColumn(
          title: "DO Card",
          description: "Set a specific DO Card that can only unlock this profile when active",
          systemImage: "wave.3.right",
          id: "do_card_12345678901234567890",
          disabled: false,
          onSet: { print("Set DO Card") },
          onUnset: { print("Unset DO Card") }
        )
      }

      Section("Disabled") {
        PhysicalUnblockColumn(
          title: "DO Card",
          description: "Set a specific DO Card that can only unlock this profile when active",
          systemImage: "wave.3.right",
          id: "do_card_12345678901234567890",
          disabled: true,
          onSet: { print("Set DO Card") },
          onUnset: { print("Unset DO Card") }
        )
      }
    }
    .navigationTitle("Physical Unlock Settings")
  }
}
