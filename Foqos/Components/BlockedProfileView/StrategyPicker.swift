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
          VStack(alignment: .leading, spacing: 12) {
            HStack {
              Spacer()
              Image(systemName: "shield.fill")
                .font(.largeTitle)
                .foregroundStyle(.secondary)
              Spacer()
            }
            .padding(.vertical, 12)

            Text(
              "Blocking strategies control how this profile activates and deactivates. Choose a method that works best for your workflow."
            )
            .font(.subheadline)
            .foregroundStyle(.primary)
            .multilineTextAlignment(.center)
          }
          .padding(.horizontal, 8)
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
          ToolbarItem(placement: .topBarLeading) {
          Menu {
            ForEach(StrategyFilter.allCases) { filter in
              Button {
                selectedFilter = filter
              } label: {
                Label(
                  filter.title,
                  systemImage: selectedFilter == filter ? "checkmark" : ""
                )
              }
            }
          } label: {
            Image(systemName: "slider.horizontal.3")
              .foregroundStyle(selectedFilter == .all ? Color.primary : themeManager.themeColor)
          }
          .accessibilityLabel("Filter")
        }

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
