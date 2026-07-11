import FamilyControls
import SwiftUI

struct AppPicker: View {
  @EnvironmentObject private var themeManager: ThemeManager

  let stateUpdateTimer = Timer.publish(every: 1, on: .main, in: .common)
    .autoconnect()

  @Binding var selection: FamilyActivitySelection
  @Binding var isPresented: Bool

  var allowMode: Bool = false

  @State private var updateFlag: Bool = false
  @State private var refreshID: UUID = UUID()
  @State private var showLimitInfo: Bool = false
  @State private var showLimitAlert: Bool = false

  private var selectedCount: Int {
    return FamilyActivityUtil.countSelectedActivities(selection, allowMode: allowMode)
  }

  private var detailedMessage: String {
    return allowMode
      ? "Apps inside selected categories each count toward Apple's 50-app limit."
      : "Select up to 50 apps or categories. Each category counts as one item."
  }

  private var isOverLimit: Bool {
    return selectedCount > 50
  }

  private func handleDone() {
    if isOverLimit {
      showLimitAlert = true
    } else {
      isPresented = false
    }
  }

  var body: some View {
    NavigationStack {
      ZStack {
        Text(verbatim: "Updating view state because of bug in iOS...")
          .foregroundStyle(.clear)
          .accessibilityHidden(true)
          .opacity(updateFlag ? 1 : 0)

        FamilyActivityPicker(selection: $selection)
          .id(refreshID)
      }
      .background(Color(.systemGroupedBackground).ignoresSafeArea())
      .tint(themeManager.themeColor)
      .onReceive(stateUpdateTimer) { _ in
        updateFlag.toggle()
      }
      .navigationBarTitleDisplayMode(.inline)
      .toolbarBackground(Color(.systemGroupedBackground), for: .navigationBar)
      .toolbarBackground(.visible, for: .navigationBar)
      .toolbar {
        ToolbarItem(placement: .topBarLeading) {
          Button(action: { refreshID = UUID() }) {
            Image(systemName: "arrow.clockwise")
          }
          .accessibilityLabel("Refresh")
        }

        ToolbarItem(placement: .principal) {
          Button(action: { showLimitInfo = true }) {
            HStack(spacing: 5) {
              Text("\(selectedCount)")
                .fontWeight(.semibold)
                .foregroundStyle(isOverLimit ? Color.red : themeManager.themeColor)

              Text("/ 50")
                .foregroundStyle(.secondary)

              Image(systemName: "info.circle")
                .font(.caption)
                .foregroundStyle(isOverLimit ? Color.red : themeManager.themeColor)
            }
            .font(.subheadline)
            .monospacedDigit()
          }
          .accessibilityLabel("\(selectedCount) of 50 items selected")
          .accessibilityHint("Shows selection limit details")
        }

        ToolbarItem(placement: .topBarTrailing) {
          Button(action: handleDone) {
            Image(systemName: "checkmark")
          }
          .accessibilityLabel("Done")
        }
      }
      .alert("Apple's 50-App Limit", isPresented: $showLimitInfo) {
        Button("OK", role: .cancel) {}
      } message: {
        Text(detailedMessage)
      }
      .alert("Over 50 App Limit", isPresented: $showLimitAlert) {
        Button("Cancel", role: .cancel) {}
        Button("OK") {
          isPresented = false
        }
      } message: {
        Text(
          "You have selected more than 50 apps and sites. This can lead to issues due to Apple's hard limit of 50."
        )
      }
    }
  }
}

#if DEBUG
  struct AppPicker_Previews: PreviewProvider {
    static var previews: some View {
      AppPicker(
        selection: .constant(FamilyActivitySelection()),
        isPresented: .constant(true)
      )
      .environmentObject(ThemeManager.shared)
    }
  }
#endif
