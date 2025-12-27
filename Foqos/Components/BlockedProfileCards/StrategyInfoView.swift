import SwiftUI

struct StrategyInfoView: View {
  @EnvironmentObject var themeManager: ThemeManager

  let strategyId: String?

  // Get blocking strategy name
  private var blockingStrategyName: String {
    guard let strategyId = strategyId else { return "None" }
    return StrategyManager.getStrategyFromId(id: strategyId).name
  }

  // Get blocking strategy icon
  private var blockingStrategyIcon: String {
    guard let strategyId = strategyId else {
      return "questionmark.circle.fill"
    }
    return StrategyManager.getStrategyFromId(id: strategyId).iconType
  }

  // Get blocking strategy color
  private var blockingStrategyColor: Color {
    guard let strategyId = strategyId else {
      return .gray
    }
    return StrategyManager.getStrategyFromId(id: strategyId).color
  }

  // Accessibility description for strategy
  private var accessibilityDescription: String {
    guard strategyId != nil else {
      return "No blocking strategy selected"
    }
    return "Blocking strategy: \(blockingStrategyName)"
  }

  var body: some View {
    HStack(spacing: Spacing.xs) {
      Image(systemName: blockingStrategyIcon)
        .foregroundColor(themeManager.themeColor)
        .font(.system(size: 13))
        .frame(width: 28, height: 28)
        .background(
          Circle()
            .fill(
              themeManager.themeColor.opacity(Opacity.tertiary)
            )
        )
        .accessibilityHidden(true)

      VStack(alignment: .leading, spacing: 2) {
        Text(blockingStrategyName)
          .foregroundColor(.primary)
          .font(.subheadline)
          .fontWeight(.medium)
      }
    }
    .accessibilityElement(children: .ignore)
    .accessibilityLabel(accessibilityDescription)
    .accessibilityHint("The method used to unlock this focus profile")
  }
}

#Preview {
  VStack(spacing: 20) {
    StrategyInfoView(strategyId: NFCBlockingStrategy.id)
    StrategyInfoView(strategyId: QRCodeBlockingStrategy.id)
    StrategyInfoView(strategyId: nil)
  }
  .padding()
  .background(Color(.systemGroupedBackground))
}
