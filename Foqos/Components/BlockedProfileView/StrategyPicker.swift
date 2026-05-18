import SwiftUI

struct StrategyPicker: View {
  @EnvironmentObject var themeManager: ThemeManager

  let strategies: [BlockingStrategy]
  @Binding var selectedStrategy: BlockingStrategy?
  @Binding var isPresented: Bool

  @State private var strategyDetails: StrategyDetailsPresentation?

  private var sections: [StrategyPickerSection] {
    let mostPopularIds = [NFCBlockingStrategy.id, QRCodeBlockingStrategy.id]
    let mostPopular = orderedStrategies(withIds: mostPopularIds)

    var usedIds = Set(mostPopular.map { $0.getIdentifier() })

    let easyToStart = strategies.filter { strategy in
      strategy.startsManually && !strategy.hasTimer && !strategy.hasPauseMode
    }
    usedIds.formUnion(easyToStart.map { $0.getIdentifier() })

    let timers = strategies.filter { strategy in
      strategy.hasTimer && !strategy.hasPauseMode
    }
    usedIds.formUnion(timers.map { $0.getIdentifier() })

    let forever = strategies.filter { strategy in
      strategy.hasPauseMode
    }
    usedIds.formUnion(forever.map { $0.getIdentifier() })

    let moreOptions = strategies.filter { strategy in
      !usedIds.contains(strategy.getIdentifier())
    }

    return [
      StrategyPickerSection(
        title: "Most Popular",
        description: "Physical triggers that make starting and stopping more deliberate.",
        strategies: mostPopular
      ),
      StrategyPickerSection(
        title: "Easy to start",
        description: "Start from the app, then choose how intentional stopping should be.",
        strategies: easyToStart
      ),
      StrategyPickerSection(
        title: "Timers",
        description: "Choose a duration first, then let the session end automatically.",
        strategies: timers
      ),
      StrategyPickerSection(
        title: "Forever",
        description: "Pause strategies for sessions that keep going until you intentionally stop.",
        strategies: forever
      ),
      StrategyPickerSection(
        title: "More options",
        description: "Additional ways to control a focus session.",
        strategies: moreOptions
      ),
    ]
    .filter { !$0.strategies.isEmpty }
  }

  var body: some View {
    NavigationStack {
      ScrollView {
        LazyVStack(alignment: .leading, spacing: 30) {
          ForEach(sections) { section in
            StrategyPickerHorizontalSection(
              section: section,
              selectedStrategyId: selectedStrategy?.getIdentifier(),
              onSelect: { strategy in
                strategyDetails = StrategyDetailsPresentation(strategy: strategy)
              }
            )
          }
        }
        .padding(.vertical, 18)
      }
      .background(Color(.systemGroupedBackground))
      .navigationTitle("Blocking Strategy")
      .navigationBarTitleDisplayMode(.inline)
      .toolbar {
        ToolbarItem(placement: .topBarTrailing) {
          Button {
            isPresented = false
          } label: {
            Image(systemName: "checkmark")
          }
          .accessibilityLabel("Done")
        }
      }
      .sheet(item: $strategyDetails) { details in
        StrategyDetailsSheet(
          strategy: details.strategy,
          isSelected: selectedStrategy?.getIdentifier() == details.id,
          onCancel: {
            strategyDetails = nil
          },
          onSelect: {
            selectedStrategy = details.strategy
            strategyDetails = nil
            isPresented = false
          }
        )
        .presentationDetents([.medium])
      }
    }
  }

  private func orderedStrategies(withIds ids: [String]) -> [BlockingStrategy] {
    return ids.compactMap { id in
      strategies.first { $0.getIdentifier() == id }
    }
  }
}

#Preview {
  @Previewable @State var selectedStrategy: BlockingStrategy? = NFCBlockingStrategy()
  @Previewable @State var isPresented = true

  StrategyPicker(
    strategies: [
      NFCBlockingStrategy(),
      QRCodeBlockingStrategy(),
      ManualBlockingStrategy(),
      NFCManualBlockingStrategy(),
      QRManualBlockingStrategy(),
      NFCTimerBlockingStrategy(),
      QRTimerBlockingStrategy(),
      NFCPauseTimerBlockingStrategy(),
      QRPauseTimerBlockingStrategy(),
    ],
    selectedStrategy: $selectedStrategy,
    isPresented: $isPresented
  )
  .environmentObject(ThemeManager())
}
