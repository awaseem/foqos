import SwiftUI

struct StrategyDetailsSheet: View {
  @EnvironmentObject var themeManager: ThemeManager

  let strategy: BlockingStrategy
  let isSelected: Bool
  let onCancel: () -> Void
  let onSelect: () -> Void

  var body: some View {
    NavigationStack {
      VStack(spacing: 22) {
        Spacer(minLength: 10)

        BlockingStrategyIconImage(strategy: strategy)
          .font(.system(size: 50))
          .foregroundStyle(strategy.color)
          .frame(width: 104, height: 104)

        VStack(spacing: 10) {
          Text(strategy.name)
            .font(.title2.weight(.bold))
            .foregroundStyle(.primary)
            .multilineTextAlignment(.center)

          Text(strategy.description)
            .font(.body)
            .foregroundStyle(.secondary)
            .multilineTextAlignment(.center)
            .fixedSize(horizontal: false, vertical: true)
        }
        .padding(.horizontal, 28)

        Spacer(minLength: 12)

        ActionButton(
          title: isSelected ? "Selected" : "Use this strategy",
          backgroundColor: themeManager.themeColor,
          isDisabled: isSelected,
          action: onSelect
        )
      }
      .padding()
      .navigationTitle("Details")
      .navigationBarTitleDisplayMode(.inline)
      .toolbar {
        ToolbarItem(placement: .topBarLeading) {
          Button(action: onCancel) {
            Image(systemName: "xmark")
          }
          .accessibilityLabel("Cancel")
        }
      }
    }
  }
}
