import SwiftUI

struct BlockedProfilePhysicalUnblockSelector: View {
  @EnvironmentObject private var themeManager: ThemeManager

  @Binding var physicalUnblockItems: [PhysicalUnblockItem]
  var disabled: Bool = false
  var disabledText: String?

  @State private var showingQRCodeScanner = false
  @State private var showingRenamePrompt = false
  @State private var showingError = false
  @State private var errorMessage = ""
  @State private var renameItemName = ""
  @State private var renameItemID: UUID?

  private let physicalReader = PhysicalReader()

  private var nfcItems: [PhysicalUnblockItem] {
    physicalUnblockItems.filter { $0.type == .nfc }
  }

  private var qrItems: [PhysicalUnblockItem] {
    physicalUnblockItems.filter { $0.type == .qrCode }
  }

  var body: some View {
    VStack(alignment: .leading, spacing: 12) {
      HStack(alignment: .top, spacing: 12) {
        physicalUnblockColumn(
          title: "NFC Tags",
          description: "Set one or more NFC tags that can only unblock this profile when active",
          systemImage: "wave.3.right.circle.fill",
          items: nfcItems,
          emptyButtonTitle: "Set",
          addButtonTitle: "Add Tag",
          onAdd: addNFCTag
        )

        physicalUnblockColumn(
          title: "QR/Barcode Code",
          description:
            "Set one or more QR/Barcode codes that can only unblock this profile when active",
          systemImage: "qrcode.viewfinder",
          items: qrItems,
          emptyButtonTitle: "Set",
          addButtonTitle: "Add Code",
          onAdd: { showingQRCodeScanner = true }
        )
      }.padding(0)

      if let disabledText = disabledText, disabled {
        Text(disabledText)
          .foregroundStyle(.red)
          .font(.caption)
      }
    }
    .background(
      TextFieldAlert(
        isPresented: $showingRenamePrompt,
        title: "Rename Item",
        message: nil,
        text: $renameItemName,
        placeholder: "Item Name",
        confirmTitle: "Save",
        cancelTitle: "Cancel",
        onConfirm: { _ in
          applyRename()
        }
      )
    )
    .alert("Error", isPresented: $showingError) {
      Button("OK") {}
    } message: {
      Text(errorMessage)
    }
    .sheet(isPresented: $showingQRCodeScanner) {
      BlockingStrategyActionView(
        customView: physicalReader.readQRCode(
          onSuccess: { codeValue in
            showingQRCodeScanner = false
            addItem(codeValue: codeValue, type: .qrCode)
          },
          onFailure: { _ in
            showingQRCodeScanner = false
            showError("Failed to read QR code, please try again or use a different code.")
          }
        )
      )
    }
  }

  @ViewBuilder
  private func physicalUnblockColumn(
    title: String,
    description: String,
    systemImage: String,
    items: [PhysicalUnblockItem],
    emptyButtonTitle: String,
    addButtonTitle: String,
    onAdd: @escaping () -> Void
  ) -> some View {
    VStack(spacing: 16) {
      VStack(spacing: 10) {
        Image(systemName: systemImage)
          .font(.title2)
          .foregroundColor(.gray)

        HStack(spacing: 6) {
          Text(title)
            .font(.subheadline)
            .fontWeight(.medium)
            .foregroundColor(.primary)

          if !items.isEmpty {
            Image(systemName: "checkmark.circle.fill")
              .foregroundColor(themeManager.themeColor)
              .font(.caption)
          }
        }
      }
      .frame(minHeight: 40, maxHeight: 40)

      VStack(spacing: 8) {
        Text(description)
          .font(.caption2)
          .foregroundColor(.secondary)
          .multilineTextAlignment(.center)
          .fixedSize(horizontal: false, vertical: true)
      }
      .frame(minHeight: 50, maxHeight: 50, alignment: .center)

      VStack(spacing: 10) {
        if items.isEmpty {
          addButton(title: emptyButtonTitle, action: onAdd)
        } else {
          ForEach(items) { item in
            physicalUnblockItemRow(item: item)
          }

          addButton(title: addButtonTitle, action: onAdd)
        }
      }
    }
    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
    .padding(.top, 12)
    .padding(.bottom, 8)
    .opacity(disabled ? 0.5 : 1)
  }

  @ViewBuilder
  private func physicalUnblockItemRow(item: PhysicalUnblockItem) -> some View {
    HStack(spacing: 10) {
      VStack(alignment: .leading, spacing: 2) {
        Text(item.name)
          .font(.subheadline)
          .foregroundStyle(.primary)
          .lineLimit(1)

        Text(shortCodeValue(item.codeValue))
          .font(.caption2)
          .foregroundStyle(.secondary)
          .lineLimit(1)
      }

      Spacer(minLength: 8)

      Menu {
        Button {
          renameItemName = item.name
          renameItemID = item.id
          showingRenamePrompt = true
        } label: {
          Label("Rename", systemImage: "pencil")
        }

        Button(role: .destructive) {
          removeItem(item.id)
        } label: {
          Label("Delete", systemImage: "trash")
        }
      } label: {
        Image(systemName: "ellipsis.circle")
          .font(.title3)
          .foregroundStyle(themeManager.themeColor)
      }
      .disabled(disabled)
    }
    .padding(.horizontal, 14)
    .padding(.vertical, 10)
    .frame(maxWidth: .infinity)
    .background(
      RoundedRectangle(cornerRadius: 16)
        .fill(.thinMaterial)
        .overlay(
          RoundedRectangle(cornerRadius: 16)
            .stroke(Color.primary.opacity(0.2), lineWidth: 1)
        )
    )
  }

  @ViewBuilder
  private func addButton(title: String, action: @escaping () -> Void) -> some View {
    Button(action: action) {
      HStack(spacing: 8) {
        Image(systemName: "plus")
          .font(.system(size: 16, weight: .medium))
        Text(title)
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
    }
    .buttonStyle(.plain)
    .foregroundStyle(disabled ? .secondary : .primary)
    .disabled(disabled)
  }

  private func addNFCTag() {
    physicalReader.readNFCTag(
      onSuccess: { codeValue in
        addItem(codeValue: codeValue, type: .nfc)
      }
    )
  }

  private func addItem(codeValue: String, type: PhysicalUnblockItem.PhysicalUnblockType) {
    let normalizedCodeValue = PhysicalUnblockItem.normalizedCodeValue(codeValue, type: type)

    guard !normalizedCodeValue.isEmpty else {
      showError("The scanned code was empty.")
      return
    }

    guard
      !physicalUnblockItems.contains(where: {
        $0.type == type && $0.codeValue == normalizedCodeValue
      })
    else {
      showError("That \(type.displayName.lowercased()) is already in this list.")
      return
    }

    physicalUnblockItems.append(
      PhysicalUnblockItem(
        name: defaultName(for: type),
        type: type,
        codeValue: normalizedCodeValue
      )
    )
  }

  private func removeItem(_ id: UUID) {
    physicalUnblockItems.removeAll { $0.id == id }
  }

  private func applyRename() {
    guard let renameItemID,
      let itemIndex = physicalUnblockItems.firstIndex(where: { $0.id == renameItemID })
    else {
      return
    }

    let trimmedName = renameItemName.trimmingCharacters(in: .whitespacesAndNewlines)
    physicalUnblockItems[itemIndex].name =
      trimmedName.isEmpty ? physicalUnblockItems[itemIndex].type.displayName : trimmedName

    self.renameItemID = nil
  }

  private func defaultName(for type: PhysicalUnblockItem.PhysicalUnblockType) -> String {
    let nextIndex = physicalUnblockItems.filter { $0.type == type }.count + 1
    return "\(type.displayName) \(nextIndex)"
  }

  private func shortCodeValue(_ codeValue: String) -> String {
    guard codeValue.count > 28 else { return codeValue }

    let prefix = codeValue.prefix(12)
    let suffix = codeValue.suffix(8)
    return "\(prefix)...\(suffix)"
  }

  private func showError(_ message: String) {
    errorMessage = message
    showingError = true
  }
}

#Preview {
  @Previewable @State var physicalUnblockItems: [PhysicalUnblockItem] = [
    PhysicalUnblockItem(name: "Tag 1", type: .nfc, codeValue: "04AABBCC11223344"),
    PhysicalUnblockItem(name: "Tag 2", type: .nfc, codeValue: "https://foqos.app/profile/tag-2"),
    PhysicalUnblockItem(
      name: "Office QR", type: .qrCode, codeValue: "https://foqos.app/profile/office"),
  ]

  NavigationStack {
    Form {
      BlockedProfilePhysicalUnblockSelector(
        physicalUnblockItems: $physicalUnblockItems
      )
    }
  }
  .environmentObject(ThemeManager())
}
