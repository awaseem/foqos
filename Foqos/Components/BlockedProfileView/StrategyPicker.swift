import SwiftUI

struct StrategyPicker: View {
  @EnvironmentObject var themeManager: ThemeManager

  enum StrategyFilter: String, CaseIterable, Identifiable {
    case all
    case nfc
    case qr
    case timer
    case pause
    case manual
    case beta

    var id: String { rawValue }

    var title: String {
      switch self {
      case .all:
        return "All"
      case .nfc:
        return "NFC"
      case .qr:
        return "QR"
      case .timer:
        return "Timer"
      case .pause:
        return "Pause"
      case .manual:
        return "Manual"
      case .beta:
        return "Beta"
      }
    }

    func matches(_ strategy: BlockingStrategy) -> Bool {
      switch self {
      case .all:
        return true
      case .nfc:
        return strategy.usesNFC
      case .qr:
        return strategy.usesQRCode
      case .timer:
        return strategy.hasTimer
      case .pause:
        return strategy.hasPauseMode
      case .manual:
        return strategy.startsManually
      case .beta:
        return strategy.isBeta
      }
    }
  }

  let strategies: [BlockingStrategy]
  @Binding var selectedStrategy: BlockingStrategy?
  @Binding var isPresented: Bool

  @State private var selectedFilter: StrategyFilter = .all
  @State private var searchText: String = ""

  private var filteredStrategies: [BlockingStrategy] {
    return strategies.filter { strategy in
      let matchesFilter = selectedFilter.matches(strategy)

      let trimmedQuery = searchText.trimmingCharacters(in: .whitespacesAndNewlines)
      if trimmedQuery.isEmpty {
        return matchesFilter
      }

      let loweredQuery = trimmedQuery.lowercased()
      let matchesQuery =
        strategy.name.lowercased().contains(loweredQuery)
        || strategy.description.lowercased().contains(loweredQuery)
        || strategy.tags.contains(where: { $0.title.lowercased().contains(loweredQuery) })

      return matchesFilter && matchesQuery
    }
  }

  var body: some View {
    NavigationStack {
      Form {
        Section {
          ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
              ForEach(StrategyFilter.allCases) { filter in
                let isSelected = selectedFilter == filter

                Button {
                  selectedFilter = filter
                } label: {
                  Text(filter.title)
                    .font(.caption)
                    .fontWeight(isSelected ? .semibold : .medium)
                    .foregroundStyle(isSelected ? themeManager.themeColor : .secondary)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 6)
                    .background(Color.secondary.opacity(0.16))
                    .clipShape(Capsule())
                }
                .buttonStyle(.plain)
              }
            }
            .padding(.vertical, 2)
          }
          .listRowBackground(Color.clear)
        } header: {
          Text("Filters")
        }

        Section {
          if filteredStrategies.isEmpty {
            Text("No strategies found. Try a different filter or search term.")
              .font(.subheadline)
              .foregroundStyle(.secondary)
          } else {
            ForEach(filteredStrategies, id: \.name) { strategy in
              StrategyRow(
                strategy: strategy,
                isSelected: selectedStrategy?.name == strategy.name,
                onTap: { selectedStrategy = strategy }
              )
            }
          }
        } header: {
          Text("Available Strategies")
        }
      }
      .navigationTitle("Blocking Strategy")
      .navigationBarTitleDisplayMode(.inline)
      .searchable(text: $searchText, prompt: "Search strategies")
      .toolbar {
        ToolbarItem(placement: .topBarTrailing) {
          Button(action: { isPresented = false }) {
            Image(systemName: "checkmark")
          }
          .accessibilityLabel("Done")
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
      ManualBlockingStrategy(),
      NFCTimerBlockingStrategy(),
    ],
    selectedStrategy: $selectedStrategy,
    isPresented: $isPresented
  )
}
