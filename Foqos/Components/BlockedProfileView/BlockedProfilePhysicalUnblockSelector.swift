import SwiftUI

struct BlockedProfilePhysicalUnblockSelector: View {
  let nfcTagId: String?
  let nfcWhitelistCount: Int // New parameter
  let qrCodeId: String?
  var disabled: Bool = false
  var disabledText: String?

  let onSetNFC: () -> Void
  let onSetQRCode: () -> Void
  let onUnsetNFC: () -> Void
  let onUnsetQRCode: () -> Void
  let onManageNFC: () -> Void // New callback

  var body: some View {
    VStack(alignment: .leading, spacing: 12) {
      HStack(spacing: 12) {
        // NFC Tag Column
        PhysicalUnblockColumn(
          title: "NFC Tags",
          description: "Set specific NFC tags that can unlock this profile when active",
          systemImage: "wave.3.right.circle.fill",
          id: nfcTagId,
          whitelistCount: nfcWhitelistCount,
          disabled: disabled,
          onSet: onSetNFC,
          onUnset: onUnsetNFC,
          onManage: onManageNFC
        )

        // QR Code Column (unchanged behavior)
        PhysicalUnblockColumn(
          title: "QR/Barcode Code",
          description: "Set a specific QR/Barcode code that can only unblock this profile when active",
          systemImage: "qrcode.viewfinder",
          id: qrCodeId,
          whitelistCount: 0, // QR codes don't support whitelist
          disabled: disabled,
          onSet: onSetQRCode,
          onUnset: onUnsetQRCode,
          onManage: {} // Not used for QR codes
        )
      }

      if let disabledText = disabledText, disabled {
        Text(disabledText)
          .foregroundStyle(.red)
          .padding(.top, 4)
          .font(.caption)
      }
    }.padding(0)
  }
}

#Preview {
  NavigationStack {
    Form {
      Section {
        // Example with no IDs set
        BlockedProfilePhysicalUnblockSelector(
          nfcTagId: nil,
          nfcWhitelistCount: 0,
          qrCodeId: nil,
          disabled: false,
          onSetNFC: { print("Set NFC") },
          onSetQRCode: { print("Set QR Code") },
          onUnsetNFC: { print("Unset NFC") },
          onUnsetQRCode: { print("Unset QR Code") },
          onManageNFC: { print("Manage NFC") }
        )
      }

      Section {
        // Example with IDs set
        BlockedProfilePhysicalUnblockSelector(
          nfcTagId: "nfc_12345678901234567890",
          nfcWhitelistCount: 3,
          qrCodeId: "qr_abcdefghijklmnopqrstuvwxyz",
          disabled: false,
          onSetNFC: { print("Set NFC") },
          onSetQRCode: { print("Set QR Code") },
          onUnsetNFC: { print("Unset NFC") },
          onUnsetQRCode: { print("Unset QR Code") },
          onManageNFC: { print("Manage NFC") }
        )
      }

      Section {
        // Example disabled
        BlockedProfilePhysicalUnblockSelector(
          nfcTagId: "nfc_12345678901234567890",
          nfcWhitelistCount: 2,
          qrCodeId: nil,
          disabled: true,
          disabledText: "Physical unblock options are locked",
          onSetNFC: { print("Set NFC") },
          onSetQRCode: { print("Set QR Code") },
          onUnsetNFC: { print("Unset NFC") },
          onUnsetQRCode: { print("Unset QR Code") },
          onManageNFC: { print("Manage NFC") }
        )
      }
    }
  }
}
