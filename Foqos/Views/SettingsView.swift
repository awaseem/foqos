import SwiftUI

struct SettingsView: View {
  @Environment(\.dismiss) private var dismiss
  @EnvironmentObject var themeManager: ThemeManager

  // Available iOS system colors
  private let availableColors: [(name: String, color: Color)] = [
    ("Purple", .purple),
    ("Blue", .blue),
    ("Teal", .teal),
    ("Green", .green),
    ("Yellow", .yellow),
    ("Orange", .orange),
    ("Red", .red),
    ("Pink", .pink),
    ("Indigo", .indigo),
  ]

  @State private var selectedColorName: String = "Purple"

  var body: some View {
    NavigationStack {
      Form {
        Section("Theme") {
          HStack {
            Image(systemName: "paintpalette.fill")
              .foregroundStyle(themeManager.themeColor)
              .font(.title3)

            VStack(alignment: .leading, spacing: 2) {
              Text("Appearance")
                .font(.headline)
              Text("Customize the look of your app")
                .font(.caption)
                .foregroundStyle(.secondary)
            }
          }
          .padding(.vertical, 8)

          Picker("Theme Color", selection: $selectedColorName) {
            ForEach(availableColors, id: \.name) { colorOption in
              HStack {
                Circle()
                  .fill(colorOption.color)
                  .frame(width: 20, height: 20)
                Text(colorOption.name)
              }
              .tag(colorOption.name)
            }
          }
          .onChange(of: selectedColorName) { _, newColorName in
            if let selectedColor = availableColors.first(where: { $0.name == newColorName })?.color
            {
              selectColor(selectedColor)
            }
          }
        }
      }
      .navigationTitle("Settings")
      .navigationBarTitleDisplayMode(.inline)
      .toolbar {
        ToolbarItem(placement: .topBarLeading) {
          Button(action: { dismiss() }) {
            Image(systemName: "xmark")
          }
          .accessibilityLabel("Close")
        }
      }
      .onAppear {
        // Set initial selected color name based on current theme
        let currentHex = themeManager.themeColor.toHex() ?? ""
        if let matchingColor = availableColors.first(where: { $0.color.toHex() == currentHex }) {
          selectedColorName = matchingColor.name
        }
      }
    }
  }

  private func selectColor(_ color: Color) {
    UIImpactFeedbackGenerator(style: .medium).impactOccurred()
    themeManager.setTheme(color)
  }
}

#Preview {
  SettingsView()
    .environmentObject(ThemeManager.shared)
}
