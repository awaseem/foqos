import SwiftUI

struct BlockedProfilePhysicalUnblockSelector: View {
  let nfcTagId: String?
  let qrCodeId: String?
  var disabled: Bool = false
  var disabledText: String?

  let onSetNFC: () -> Void
  let onSetQRCode: () -> Void
  let onUnsetNFC: () -> Void
  let onUnsetQRCode: () -> Void

  var body: some View {
    VStack(alignment: .leading, spacing: 12) {
      HStack(spacing: 12) {
        // NFC Tag Column
        PhysicalUnblockColumn(
          title: "NFC Tag",
          description: "Set a specific NFC tag that can only unblock this profile when active",
          systemImage: "wave.3.right.circle.fill",
          id: nfcTagId,
          disabled: disabled,
          onSet: onSetNFC,
          onUnset: onUnsetNFC
        )

        // QR Code Column
        PhysicalUnblockColumn(
          title: "QR/Barcode Code",
          description:
            "Set a specific QR/Barcode code that can only unblock this profile when active",
          systemImage: "qrcode.viewfinder",
          id: qrCodeId,
          disabled: disabled,
          onSet: onSetQRCode,
          onUnset: onUnsetQRCode
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
          qrCodeId: nil,
          disabled: false,
          onSetNFC: { print("Set NFC") },
          onSetQRCode: { print("Set QR Code") },
          onUnsetNFC: { print("Unset NFC") },
          onUnsetQRCode: { print("Unset QR Code") }
        )
      }

      Section {
        // Example with IDs set
        BlockedProfilePhysicalUnblockSelector(
          nfcTagId: "nfc_12345678901234567890",
          qrCodeId: "qr_abcdefghijklmnopqrstuvwxyz",
          disabled: false,
          onSetNFC: { print("Set NFC") },
          onSetQRCode: { print("Set QR Code") },
          onUnsetNFC: { print("Unset NFC") },
          onUnsetQRCode: { print("Unset QR Code") }
        )
      }

      Section {
        // Example disabled
        BlockedProfilePhysicalUnblockSelector(
          nfcTagId: "nfc_12345678901234567890",
          qrCodeId: nil,
          disabled: true,
          disabledText: "Physical unblock options are locked",
          onSetNFC: { print("Set NFC") },
          onSetQRCode: { print("Set QR Code") },
          onUnsetNFC: { print("Unset NFC") },
          onUnsetQRCode: { print("Unset QR Code") }
        )
      }
    }
  }
}
