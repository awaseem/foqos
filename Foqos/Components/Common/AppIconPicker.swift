import SwiftUI

struct AppIconPicker: View {
  @EnvironmentObject private var themeManager: ThemeManager

  @State private var selectedIconName = UIApplication.shared.alternateIconName
  @State private var isChangingIcon = false
  @State private var showError = false
  @State private var errorMessage = ""

  var body: some View {
    Section("App Icon") {
      HStack(spacing: 6) {
        ForEach(AppIconOption.allCases) { icon in
          Button {
            select(icon)
          } label: {
            VStack(spacing: 6) {
              Image(icon.previewAssetName)
                .resizable()
                .aspectRatio(contentMode: .fit)
                .frame(width: 44, height: 44)
                .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
                .overlay {
                  RoundedRectangle(cornerRadius: 10, style: .continuous)
                    .stroke(
                      isSelected(icon) ? themeManager.themeColor : .clear,
                      lineWidth: 2
                    )
                }
                .overlay(alignment: .topTrailing) {
                  if isSelected(icon) {
                    Image(systemName: "checkmark.circle.fill")
                      .symbolRenderingMode(.palette)
                      .foregroundStyle(.white, themeManager.themeColor)
                      .background(Circle().fill(.background))
                      .offset(x: 6, y: -6)
                  }
                }

              Text(icon.displayName)
                .font(.caption)
                .foregroundStyle(.primary)
                .lineLimit(1)
            }
            .frame(maxWidth: .infinity)
            .contentShape(Rectangle())
          }
          .buttonStyle(.plain)
          .disabled(isChangingIcon || isSelected(icon))
          .accessibilityLabel("Use the \(icon.displayName) app icon")
          .accessibilityAddTraits(isSelected(icon) ? .isSelected : [])
        }
      }
      .padding(.vertical, 4)

      if !UIApplication.shared.supportsAlternateIcons {
        Text("Alternate app icons are not available on this device.")
          .font(.caption)
          .foregroundStyle(.secondary)
      }
    }
    .alert("Unable to Change App Icon", isPresented: $showError) {
      Button("OK") {}
    } message: {
      Text(errorMessage)
    }
    .onAppear {
      selectedIconName = UIApplication.shared.alternateIconName
    }
  }

  private func isSelected(_ icon: AppIconOption) -> Bool {
    selectedIconName == icon.alternateIconName
  }

  private func select(_ icon: AppIconOption) {
    guard UIApplication.shared.supportsAlternateIcons else {
      errorMessage = "Alternate app icons are not available on this device."
      showError = true
      return
    }

    isChangingIcon = true
    UIApplication.shared.setAlternateIconName(icon.alternateIconName) { error in
      Task { @MainActor in
        isChangingIcon = false

        if let error {
          errorMessage = error.localizedDescription
          showError = true
          selectedIconName = UIApplication.shared.alternateIconName
          return
        }

        selectedIconName = UIApplication.shared.alternateIconName
        UIImpactFeedbackGenerator(style: .medium).impactOccurred()
      }
    }
  }
}

private enum AppIconOption: String, CaseIterable, Identifiable {
  case defaultIcon
  case blue
  case cat
  case pop
  case original

  var id: String { rawValue }

  var displayName: String {
    switch self {
    case .defaultIcon: "Default"
    case .blue: "Blue"
    case .cat: "Cat"
    case .pop: "Pop"
    case .original: "Original"
    }
  }

  var alternateIconName: String? {
    switch self {
    case .defaultIcon: nil
    case .blue: "foqos-icon-blue"
    case .cat: "foqos-icon-cat"
    case .pop: "foqos-icon-pop"
    case .original: "foqos-icon-original"
    }
  }

  var previewAssetName: String {
    switch self {
    case .defaultIcon: "AppIconDefaultPreview"
    case .blue: "AppIconBluePreview"
    case .cat: "AppIconCatPreview"
    case .pop: "AppIconPopPreview"
    case .original: "AppIconOriginalPreview"
    }
  }
}

#Preview {
  Form {
    AppIconPicker()
  }
  .environmentObject(ThemeManager.shared)
}
