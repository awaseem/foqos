import SwiftUI

struct StrategyInfoView: View {
  @EnvironmentObject var themeManager: ThemeManager

  let strategyId: String?

  // Get blocking strategy name
  private var blockingStrategyName: String {
    guard let strategyId = strategyId else { return "None" }
    return StrategyManager.getStrategyFromId(id: strategyId).name
  }

  private var blockingStrategy: BlockingStrategy? {
    guard let strategyId = strategyId else { return nil }
    return StrategyManager.getStrategyFromId(id: strategyId)
  }

  // Get blocking strategy color
  private var blockingStrategyColor: Color {
    guard let strategyId = strategyId else {
      return .gray
    }
    return StrategyManager.getStrategyFromId(id: strategyId).color
  }

  var body: some View {
    HStack {
      BlockingStrategyIconImage(strategy: blockingStrategy)
        .foregroundColor(themeManager.themeColor)
        .font(.system(size: 13))
        .frame(width: 28, height: 28)
        .background {
          if blockingStrategy?.iconAssetName == nil {
            Circle()
              .fill(themeManager.themeColor.opacity(0.15))
          }
        }

      VStack(alignment: .leading, spacing: 2) {
        Text(blockingStrategyName)
          .foregroundColor(.primary)
          .font(.subheadline)
          .fontWeight(.medium)
      }
    }
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
