import SwiftUI

struct BlockingStrategyList: View {
    let strategies: [BlockingStrategy]
    
    @Binding var selectedStrategy: BlockingStrategy?
    var onExecute: (BlockingStrategy) -> Void
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            VStack(spacing: 12) {
                ForEach(strategies, id: \.name) { strategy in
                    StrategyRow(
                        strategy: strategy,
                        isSelected: selectedStrategy?.name == strategy.name,
                        onTap: { selectedStrategy = strategy }
                    )
                }
            }
            .padding(.vertical, 2)
            
            if let selected = selectedStrategy {
                Button(action: { onExecute(selected) }) {
                    HStack {
                        Text("Execute Now")
                        Spacer()
                        Image(systemName: "arrow.right.circle.fill")
                    }
                    .padding()
                    .background(Color.accentColor)
                    .foregroundColor(.white)
                    .cornerRadius(10)
                }
                .padding(.top, 8)
            }
        }
        .padding()
    }
}

#Preview {
    @Previewable @State var selectedStrategy: BlockingStrategy?
    
    BlockingStrategyList(
        strategies: [NFCBlockingStrategy(), ManualBlockingStrategy()],
        selectedStrategy: $selectedStrategy,
        onExecute: {
            strategy in print(strategy.name)
        }
    )
}
