import SwiftUI

struct PhysicalUnblockColumn: View {
  @EnvironmentObject var themeManager: ThemeManager

  let title: String
  let description: String
  let systemImage: String
  let id: String? // Legacy single tag ID
  let whitelistCount: Int // New: number of whitelisted tags
  let disabled: Bool
  let onSet: () -> Void
  let onUnset: () -> Void
  let onManage: () -> Void // New: manage whitelist action

  // Computed properties for state display
  private var hasConfiguration: Bool {
    return id != nil || whitelistCount > 0
  }

  private var statusText: String {
    if let id = id {
      return "Legacy NFC Tag"
    } else if whitelistCount > 0 {
      let pluralSuffix = whitelistCount == 1 ? "" : "s"
      return "\(whitelistCount) NFC tag\(pluralSuffix)"
    }
    return "Not configured"
  }

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

          if hasConfiguration {
            Image(systemName: "checkmark.circle.fill")
              .foregroundColor(themeManager.themeColor)
              .font(.caption)
          }
        }

        Text(statusText)
          .font(.caption2)
          .foregroundStyle(.secondary)
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

      // Action buttons
      VStack(spacing: 8) {
        if hasConfiguration {
          Button(action: {
            if !disabled {
              onManage()
            }
          }) {
            HStack(spacing: 6) {
              Image(systemName: "list.bullet")
                .font(.system(size: 16, weight: .medium))
              Text("Manage")
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
                    .stroke(Color.blue.opacity(0.2), lineWidth: 1)
                )
            )
            .foregroundColor(.blue)
          }
          .buttonStyle(PlainButtonStyle())

          Button(action: {
            if !disabled {
              onUnset()
            }
          }) {
            HStack(spacing: 6) {
              Image(systemName: "xmark")
                .font(.system(size: 16, weight: .medium))
              Text("Remove All")
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
              Text("Set Tag")
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
        HStack(spacing: 12) {
          PhysicalUnblockColumn(
            title: "NFC Tag",
            description: "Set a specific NFC tag that can only unblock this profile when active",
            systemImage: "wave.3.right",
            id: nil,
            whitelistCount: 0,
            disabled: false,
            onSet: { print("Set NFC") },
            onUnset: { print("Unset NFC") },
            onManage: { print("Manage NFC") }
          )

          PhysicalUnblockColumn(
            title: "QR Code",
            description:
              "Set a specific QR/Barcode code that can only unblock this profile when active",
            systemImage: "qrcode",
            id: nil,
            whitelistCount: 0,
            disabled: false,
            onSet: { print("Set QR Code") },
            onUnset: { print("Unset QR Code") },
            onManage: { print("Manage QR Code") }
          )
        }
      }

      Section("Set") {
        HStack(spacing: 12) {
          PhysicalUnblockColumn(
            title: "NFC Tag",
            description: "Set a specific NFC tag that can only unblock this profile when active",
            systemImage: "wave.3.right",
            id: "nfc_12345678901234567890",
            whitelistCount: 0,
            disabled: false,
            onSet: { print("Set NFC") },
            onUnset: { print("Unset NFC") },
            onManage: { print("Manage NFC") }
          )

          PhysicalUnblockColumn(
            title: "QR Code",
            description:
              "Set a specific QR/Barcode code that can only unblock this profile when active",
            systemImage: "qrcode",
            id: "qr_abcdefghijklmnopqrstuvwxyz",
            whitelistCount: 0,
            disabled: false,
            onSet: { print("Set QR Code") },
            onUnset: { print("Unset QR Code") },
            onManage: { print("Manage QR Code") }
          )
        }
      }

      Section("Disabled") {
        HStack(spacing: 12) {
          PhysicalUnblockColumn(
            title: "NFC Tag",
            description: "Set a specific NFC tag that can only unblock this profile when active",
            systemImage: "wave.3.right",
            id: "nfc_12345678901234567890",
            whitelistCount: 0,
            disabled: true,
            onSet: { print("Set NFC") },
            onUnset: { print("Unset NFC") },
            onManage: { print("Manage NFC") }
          )

          PhysicalUnblockColumn(
            title: "QR Code",
            description: "Set a specific QR code that can only unblock this profile when active",
            systemImage: "qrcode",
            id: nil,
            whitelistCount: 0,
            disabled: true,
            onSet: { print("Set QR Code") },
            onUnset: { print("Unset QR Code") },
            onManage: { print("Manage QR Code") }
          )
        }
      }
    }
    .navigationTitle("Physical Unblock Columns")
  }
}
