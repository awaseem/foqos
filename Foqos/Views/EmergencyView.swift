import SwiftUI

struct EmergencyView: View {
  // TODO: Replace with real source of truth from your model/store
  @State private var emergencyUnblocksRemaining: Int = 3
  @State private var isPerformingEmergencyUnblock: Bool = false

  private var hasRemaining: Bool { emergencyUnblocksRemaining > 0 }

  var body: some View {
    ScrollView {
      VStack(spacing: 20) {
        header

        statusCard

        actionCard
      }
      .padding()
    }
  }

  private var header: some View {
    VStack(alignment: .leading, spacing: 8) {
      Text("Break Glass For Emergency Access")
        .font(.title2).bold()
      Text(
        "Tap the glass to reveal the emergency unblock button. Use only when absolutely necessary."
      )
      .font(.callout)
      .foregroundColor(.secondary)
    }
    .frame(maxWidth: .infinity, alignment: .leading)
  }

  private var statusCard: some View {
    VStack(alignment: .leading, spacing: 12) {
      HStack(spacing: 12) {
        Image(systemName: hasRemaining ? "shield.lefthalf.filled" : "shield.slash")
          .font(.title3)
          .foregroundColor(hasRemaining ? .green : .red)
        VStack(alignment: .leading, spacing: 4) {
          Text("Unblocks remaining")
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
    }
    .padding(16)
    .background(
      RoundedRectangle(cornerRadius: 16, style: .continuous)
        .fill(.thinMaterial)
    )
  }

  private var actionCard: some View {
    VStack(alignment: .leading, spacing: 12) {
      Text("Break glass to proceed")
        .font(.subheadline)
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
        Text("No emergency unblocks remaining. You're out of luck.")
          .font(.footnote)
          .foregroundColor(.red)
      } else {
        Text("This will reduce your remaining count by 1.")
          .font(.footnote)
          .foregroundColor(.secondary)
      }
    }
    .padding(16)
    .background(
      RoundedRectangle(cornerRadius: 16, style: .continuous)
        .fill(.ultraThinMaterial)
    )
  }

  private func performEmergencyUnblock() {
    // TODO: Implement real emergency unblock behavior
    // - Decrement remaining count from the shared model
    // - Trigger unblock workflow (DeviceActivity/Shield config)
    // - Start countdown/cooldown timers as needed
    // - Provide haptics/feedback and error handling
    isPerformingEmergencyUnblock = true
    DispatchQueue.main.asyncAfter(deadline: .now() + 0.6) {
      isPerformingEmergencyUnblock = false
      // TODO: Remove local decrement; wire to real state updates
      if emergencyUnblocksRemaining > 0 {
        emergencyUnblocksRemaining -= 1
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
              .presentationDetents([.medium])
          .presentationDragIndicator(.visible)
      }
  }
}

#Preview {
  EmergencyPreviewSheetHost()
}
