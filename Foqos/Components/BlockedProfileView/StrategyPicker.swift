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
        LazyVStack(alignment: .leading, spacing: 24) {
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

private struct StrategyPickerSection: Identifiable {
  let title: String
  let description: String
  let strategies: [BlockingStrategy]

  var id: String { title }
}

private struct StrategyDetailsPresentation: Identifiable {
  let strategy: BlockingStrategy

  var id: String { strategy.getIdentifier() }
}

private struct StrategyPickerHorizontalSection: View {
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
      }
      .scrollIndicators(.hidden)
    }
  }
}

private struct StrategyPickerCard: View {
  @EnvironmentObject var themeManager: ThemeManager

  let strategy: BlockingStrategy
  let isSelected: Bool
  let onTap: () -> Void

  var body: some View {
    Button(action: onTap) {
      VStack(spacing: 8) {
        ZStack(alignment: .topTrailing) {
          BlockingStrategyIconImage(strategy: strategy)
            .font(.system(size: 28))
            .foregroundStyle(strategy.color)
            .frame(width: 54, height: 54)
            .background {
              if strategy.iconAssetName == nil {
                Circle()
                  .fill(strategy.color.opacity(0.14))
              }
            }

          if isSelected {
            Image(systemName: "checkmark.circle.fill")
              .font(.system(size: 17))
              .foregroundStyle(themeManager.themeColor)
              .background(Circle().fill(Color(.systemBackground)))
              .offset(x: 4, y: -4)
          }
        }
        .frame(width: 60, height: 60)

        Text(strategy.name)
          .font(.subheadline.weight(.semibold))
          .foregroundStyle(.primary)
          .multilineTextAlignment(.center)
          .lineLimit(2)
          .minimumScaleFactor(0.82)
          .frame(height: 38, alignment: .top)
      }
      .frame(width: 108, height: 118)
      .padding(10)
      .background(Color(.secondarySystemGroupedBackground))
      .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
      .overlay {
        RoundedRectangle(cornerRadius: 14, style: .continuous)
          .stroke(
            isSelected ? themeManager.themeColor : Color(.separator).opacity(0.45),
            lineWidth: isSelected ? 2 : 1
          )
      }
    }
    .buttonStyle(.plain)
    .accessibilityLabel(strategy.name)
    .accessibilityHint("Shows details for this blocking strategy")
  }
}

private struct StrategyDetailsSheet: View {
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
          .background {
            if strategy.iconAssetName == nil {
              Circle()
                .fill(strategy.color.opacity(0.14))
            }
          }

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

        Button(action: onSelect) {
          HStack {
            Spacer()

            Image(systemName: isSelected ? "checkmark.circle.fill" : "checkmark")
            Text(isSelected ? "Selected" : "Use this strategy")
              .fontWeight(.semibold)

            Spacer()
          }
          .padding(.vertical, 14)
          .foregroundStyle(.white)
          .background(isSelected ? Color.secondary : themeManager.themeColor)
          .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
        }
        .buttonStyle(.plain)
        .disabled(isSelected)
      }
      .padding()
      .navigationTitle("Strategy Details")
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
