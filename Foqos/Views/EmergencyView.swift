import SwiftUI

struct EmergencyView: View {
  @Environment(\.modelContext) private var context
  @Environment(\.dismiss) private var dismiss

  @EnvironmentObject var strategyManager: StrategyManager
  @StateObject private var bailoutManager = BailoutManager.shared

  private var emergencyUnblocksRemaining: Int { strategyManager.getRemainingEmergencyUnblocks() }
  private var hasRemaining: Bool { strategyManager.getRemainingEmergencyUnblocks() > 0 }
  private var isAlwaysBailoutRequired: Bool { bailoutManager.bailoutMode == .alwaysRequired }

  @State private var isPerformingEmergencyUnblock: Bool = false

  var body: some View {
    ScrollView {
      VStack(spacing: 20) {
        header

        if isAlwaysBailoutRequired {
          bailoutCard
        } else {
          statusCard

          if !hasRemaining && bailoutManager.bailoutMode != .disabled {
            bailoutCard
          }
        }
      }
      .padding()
    }
    .onAppear {
      strategyManager.checkAndResetEmergencyUnblocks()
      Task {
        await bailoutManager.loadProducts()
      }
    }
  }

  private var header: some View {
    VStack(alignment: .leading, spacing: 12) {
      HStack {
        Text("Emergency Access")
          .font(.title2).bold()

        Spacer()

        if !isAlwaysBailoutRequired {
          HStack(spacing: 8) {
            HStack(spacing: 6) {
              Image(systemName: "clock.arrow.circlepath")
                .font(.caption)
                .foregroundColor(.secondary)

              Group {
                if let nextResetDate = strategyManager.getNextResetDate() {
                  let timeUntilReset = nextResetDate.timeIntervalSinceNow
                  if timeUntilReset <= 24 * 60 * 60 {  // Less than 24 hours
                    let hoursRemaining = max(1, Int(ceil(timeUntilReset / 3600)))
                    Text("Resets in \(hoursRemaining)h")
                      .font(.caption)
                  } else {
                    Text("Resets \(nextResetDate, format: .dateTime.month().day())")
                      .font(.caption)
                  }
                }
              }
            }
            .padding(.vertical, 6)

            Menu {
              let currentPeriod = strategyManager.getResetPeriodInWeeks()

              Button {
                strategyManager.setResetPeriodInWeeks(2)
              } label: {
                if currentPeriod == 2 {
                  Label("2 weeks", systemImage: "checkmark")
                } else {
                  Text("2 weeks")
                }
              }

              Button {
                strategyManager.setResetPeriodInWeeks(4)
              } label: {
                if currentPeriod == 4 {
                  Label("4 weeks", systemImage: "checkmark")
                } else {
                  Text("4 weeks")
                }
              }

              Button {
                strategyManager.setResetPeriodInWeeks(6)
              } label: {
                if currentPeriod == 6 {
                  Label("6 weeks", systemImage: "checkmark")
                } else {
                  Text("6 weeks")
                }
              }

              Button {
                strategyManager.setResetPeriodInWeeks(8)
              } label: {
                if currentPeriod == 8 {
                  Label("8 weeks", systemImage: "checkmark")
                } else {
                  Text("8 weeks")
                }
              }
            } label: {
              Image(systemName: "gearshape.fill")
                .font(.caption)
                .foregroundColor(.secondary)
                .padding(8)
                .background(Circle().fill(Color.secondary.opacity(0.1)))
            }
          }
        }
      }

      Text(
        isAlwaysBailoutRequired
          ? "Strict Financial Stakes are enabled. Emergency unblocking requires a commitment bailout fee."
          : "Tap the glass to reveal the emergency unblock button. Use only when absolutely necessary."
      )
      .font(.callout)
      .foregroundColor(.secondary)
    }
    .padding(.top, 16)
    .frame(maxWidth: .infinity, alignment: .leading)
  }

  private var statusCard: some View {
    VStack(alignment: .leading, spacing: 12) {
      HStack(spacing: 12) {
        Image(systemName: hasRemaining ? "shield.lefthalf.filled" : "shield.slash")
          .font(.title3)
          .foregroundColor(hasRemaining ? .green : .red)
        VStack(alignment: .leading, spacing: 4) {
          Text("Free unblocks remaining")
            .font(.subheadline)
            .foregroundColor(.secondary)
          Text("\(emergencyUnblocksRemaining)")
            .font(.title2).bold()
            .foregroundColor(hasRemaining ? .primary : .red)
        }
        Spacer()
      }

      Text("You have a limited number of emergency unblocks.")
        .font(.footnote)
        .foregroundColor(.secondary)

      BreakGlassButton(tapsToShatter: 3) {
        ActionButton(
          title: "Emergency Unblock",
          backgroundColor: .red,
          iconName: "exclamationmark.triangle.fill",
          iconColor: .white,
          isLoading: isPerformingEmergencyUnblock,
          isDisabled: !hasRemaining
        ) {
          performEmergencyUnblock()
        }
      }
      .frame(height: 56)

      if !hasRemaining {
        if bailoutManager.bailoutMode == .disabled {
          Text("No emergency unblocks remaining. You're out of luck.")
            .font(.footnote)
            .foregroundColor(.red)
        } else {
          Text("Free quota exhausted. You can unlock via the commitment bailout below.")
            .font(.footnote)
            .foregroundColor(.orange)
        }
      } else {
        Text("This will reduce your remaining free count by 1.")
          .font(.footnote)
          .foregroundColor(.secondary)
      }
    }
    .padding(16)
    .background(
      RoundedRectangle(cornerRadius: 16, style: .continuous)
        .fill(.thinMaterial)
    )
  }

  private var bailoutCard: some View {
    VStack(alignment: .leading, spacing: 14) {
      HStack(spacing: 10) {
        Image(systemName: "banknote.fill")
          .font(.title3)
          .foregroundColor(.orange)

        VStack(alignment: .leading, spacing: 2) {
          Text("Emergency Bailout Stake")
            .font(.headline)
          Text("Financial commitment to stop session")
            .font(.caption)
            .foregroundColor(.secondary)
        }

        Spacer()

        Text(bailoutManager.selectedTier.emoji)
          .font(.title2)
      }

      Text(
        "Loss aversion psychology reinforces discipline. 100% of purchase proceeds fund ongoing Foqos open-source development."
      )
      .font(.footnote)
      .foregroundColor(.secondary)

      if let error = bailoutManager.purchaseError {
        Text(error)
          .font(.caption)
          .foregroundColor(.red)
      }

      Button {
        performBailout()
      } label: {
        HStack(spacing: 8) {
          if bailoutManager.isPurchasing {
            ProgressView()
              .tint(.white)
          } else {
            Image(systemName: "faceid")
              .font(.subheadline)
            Text("Unlock for \(bailoutManager.displayPrice(for: bailoutManager.selectedTier))")
              .font(.headline)
          }
        }
        .frame(maxWidth: .infinity)
        .frame(height: 52)
        .background(Color.orange)
        .foregroundColor(.white)
        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
      }
      .disabled(bailoutManager.isPurchasing)
    }
    .padding(16)
    .background(
      RoundedRectangle(cornerRadius: 16, style: .continuous)
        .fill(.thinMaterial)
    )
  }

  private func performEmergencyUnblock() {
    isPerformingEmergencyUnblock = true

    DispatchQueue.main.asyncAfter(deadline: .now() + 0.6) {
      strategyManager.emergencyUnblock(context: context)
      isPerformingEmergencyUnblock = false
      dismiss()
    }
  }

  private func performBailout() {
    let profileName = strategyManager.activeSession?.blockedProfile.name
    Task {
      let success = await bailoutManager.executeBailout(
        tier: bailoutManager.selectedTier,
        context: context,
        strategyManager: strategyManager,
        profileName: profileName
      )
      if success {
        dismiss()
      }
    }
  }
}

struct EmergencyPreviewSheetHost: View {
  @State private var show: Bool = true

  var body: some View {
    Color.clear
      .sheet(isPresented: $show) {
        NavigationView { EmergencyView() }
          .presentationDetents([.medium, .large])
          .presentationDragIndicator(.visible)
      }
  }
}

#Preview {
  EmergencyPreviewSheetHost()
    .environmentObject(StrategyManager())
    .defaultAppStorage(UserDefaults(suiteName: "preview")!)
}
