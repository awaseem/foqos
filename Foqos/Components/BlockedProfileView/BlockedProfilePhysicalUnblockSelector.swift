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
      // DO Card Column (NFC-based unlock)
      PhysicalUnblockColumn(
        title: "DO Card",
        description: "Set a specific DO Card that can only unlock this profile when active",
        systemImage: "wave.3.right.circle.fill",
        id: nfcTagId,
        disabled: disabled,
        onSet: onSetNFC,
        onUnset: onUnsetNFC
      )

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
        // Example with no ID set
        BlockedProfilePhysicalUnblockSelector(
          nfcTagId: nil,
          qrCodeId: nil,
          disabled: false,
          onSetNFC: { print("Set DO Card") },
          onSetQRCode: { },
          onUnsetNFC: { print("Unset DO Card") },
          onUnsetQRCode: { }
        )
      }

      Section {
        // Example with ID set
        BlockedProfilePhysicalUnblockSelector(
          nfcTagId: "do_card_12345678901234567890",
          qrCodeId: nil,
          disabled: false,
          onSetNFC: { print("Set DO Card") },
          onSetQRCode: { },
          onUnsetNFC: { print("Unset DO Card") },
          onUnsetQRCode: { }
        )
      }

      Section {
        // Example disabled
        BlockedProfilePhysicalUnblockSelector(
          nfcTagId: "do_card_12345678901234567890",
          qrCodeId: nil,
          disabled: true,
          disabledText: "Physical unlock options are locked",
          onSetNFC: { print("Set DO Card") },
          onSetQRCode: { },
          onUnsetNFC: { print("Unset DO Card") },
          onUnsetQRCode: { }
        )
      }
    }
  }
}
