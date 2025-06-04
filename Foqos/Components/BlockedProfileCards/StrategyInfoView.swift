import SwiftUI

struct StrategyInfoView: View {
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
    
    var body: some View {
        HStack {
            Image(systemName: blockingStrategyIcon)
                .foregroundColor(blockingStrategyColor)
                .font(.system(size: 16))
                .frame(width: 28, height: 28)
                .background(
                    Circle()
                        .fill(
                            blockingStrategyColor.opacity(0.15)
                        )
                )
            
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
