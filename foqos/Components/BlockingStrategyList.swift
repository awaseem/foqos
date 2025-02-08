import SwiftUI

struct BlockingStrategyList: View {
    let strategies: [BlockingStrategy]
    @Binding var selectedStrategy: BlockingStrategy?
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            VStack() {
                ForEach(strategies, id: \.name) { strategy in
                    StrategyRow(
                        strategy: strategy,
                        isSelected: selectedStrategy?.name == strategy.name,
                        onTap: { selectedStrategy = strategy }
                    )
                }
            }
        }.padding(0)
    }
}

#Preview {
    @Previewable @State var selectedStrategy: BlockingStrategy?
    NavigationStack {
        Form {
            Section {
                BlockingStrategyList(
                    strategies: [NFCBlockingStrategy(), ManualBlockingStrategy()],
                    selectedStrategy: $selectedStrategy
                )
            }
        }
    }
}
