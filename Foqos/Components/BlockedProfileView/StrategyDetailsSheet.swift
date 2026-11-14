import SwiftUI

struct StrategyDetailsSheet: View {
  @EnvironmentObject var themeManager: ThemeManager

  let strategy: BlockingStrategy
  let isSelected: Bool
  let onCancel: () -> Void
  let onSelect: () -> Void

  var body: some View {
    NavigationStack {
      ContentSizedSheetScrollView {
        VStack(spacing: 22) {
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
          .padding(.horizontal, 8)

          ActionButton(
            title: isSelected ? "Selected" : "Use this strategy",
            backgroundColor: themeManager.themeColor,
            isDisabled: isSelected,
            action: onSelect
          )
        }
        .padding(24)
      }
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

#Preview {
  @Previewable @State var isPresented = true

  Color.clear
    .sheet(isPresented: $isPresented) {
      StrategyDetailsSheet(
        strategy: NFCSoftUnblockBlockingStrategy(),
        isSelected: false,
        onCancel: { isPresented = false },
        onSelect: { isPresented = false }
      )
      .contentSizedSheetPresentation()
      .environmentObject(ThemeManager())
    }
}
