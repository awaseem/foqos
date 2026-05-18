import SwiftUI

struct StrategyPickerHorizontalSection: View {
  let section: StrategyPickerSection
  let selectedStrategyId: String?
  let onSelect: (BlockingStrategy) -> Void

  var body: some View {
    VStack(alignment: .leading, spacing: 14) {
      VStack(alignment: .leading, spacing: 4) {
        Text(section.title)
          .font(.title3.weight(.bold))
          .foregroundStyle(.primary)

        Text(section.description)
          .font(.subheadline)
          .foregroundStyle(.secondary)
          .fixedSize(horizontal: false, vertical: true)
      }
      .padding(.trailing)
      .padding(.horizontal)

      ScrollView(.horizontal) {
        LazyHStack(spacing: 10) {
          ForEach(section.strategies, id: \.name) { strategy in
            StrategyPickerCard(
              strategy: strategy,
              isSelected: selectedStrategyId == strategy.getIdentifier(),
              onTap: {
                onSelect(strategy)
              }
            )
          }
        }
        .padding(.horizontal)
        .padding(.vertical, 2)
      }
      .scrollIndicators(.hidden)
    }
  }
}
