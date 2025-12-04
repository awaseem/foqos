import FamilyControls
import SwiftUI

struct AppPicker: View {
  let stateUpdateTimer = Timer.publish(every: 1, on: .main, in: .common)
    .autoconnect()

  @Binding var selection: FamilyActivitySelection
  @Binding var isPresented: Bool

  var allowMode: Bool = false

  @State private var updateFlag: Bool = false
  @State private var refreshID: UUID = UUID()
  @State private var isMessageExpanded: Bool = true  // Start expanded so users see the warning
  @State private var showLimitAlert: Bool = false

  private var compactTitle: String {
    let displayText = FamilyActivityUtil.getCountDisplayText(selection, allowMode: allowMode)
    let action = allowMode ? "allowed" : "blocked"
    return "\(displayText) \(action)"
  }

  private var detailedMessage: String {
    return allowMode
      ? "⚠️ Apple enforces a 50 app limit. In Allow mode, when you select a category (like 'Social Networking'), EVERY individual app in that category counts separately toward the 50 app limit. This means selecting just a few categories can quickly exceed the limit."
      : "Apple enforces a 50 app limit. In Block mode, each category counts as only 1 item regardless of how many apps it contains. Individual apps also count as 1 item each."
  }

  private var shouldShowWarning: Bool {
    return FamilyActivityUtil.shouldShowAllowModeWarning(selection, allowMode: allowMode)
  }

  private var warningMessage: String {
    return
      "You have selected categories in Allow mode. This will expand to individual apps and may exceed the 50 app limit. Consider selecting individual apps instead of categories, or switch to Block mode where categories count as just 1 item each."
  }

  private var knownIssuesMessage: String {
    return
      "Apple's app picker may occasionally crash. We apologize for the inconvenience and are waiting for an official fix."
  }

  private var isOverLimit: Bool {
    let count = FamilyActivityUtil.countSelectedActivities(selection, allowMode: allowMode)
    return count > 50
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
      VStack(alignment: .leading, spacing: 12) {
        ZStack {
          Text(verbatim: "Updating view state because of bug in iOS...")
            .foregroundStyle(.clear)
            .accessibilityHidden(true)
            .opacity(updateFlag ? 1 : 0)

          FamilyActivityPicker(selection: $selection)
            .id(refreshID)
        }

        // Compact info section
        Button(action: {
          withAnimation(.easeInOut(duration: 0.2)) {
            isMessageExpanded.toggle()
          }
        }) {
          VStack(alignment: .leading, spacing: 10) {
            HStack {
              VStack(alignment: .leading, spacing: 4) {
                Text(compactTitle)
                  .font(.subheadline)
                  .bold()
                  .foregroundColor(.primary)

                if !isMessageExpanded {
                  Text("Tap for details")
                    .font(.caption2)
                    .foregroundColor(.secondary)
                }
              }

              Spacer()

              Image(systemName: isMessageExpanded ? "chevron.up.circle.fill" : "info.circle")
                .font(.title3)
                .foregroundColor(.secondary)
            }

            if isMessageExpanded {
              VStack(alignment: .leading, spacing: 12) {
                Divider()

                VStack(alignment: .leading, spacing: 6) {
                  Text("Apple's 50 App Limit")
                    .font(.caption)
                    .bold()
                    .foregroundColor(allowMode ? .orange : .secondary)

                  Text(detailedMessage)
                    .font(.caption)
                    .foregroundColor(.primary)
                    .fixedSize(horizontal: false, vertical: true)
                }

                if shouldShowWarning {
                  VStack(alignment: .leading, spacing: 6) {
                    Text("⚠️ Important")
                      .font(.caption)
                      .bold()
                      .foregroundColor(.orange)

                    Text(warningMessage)
                      .font(.caption)
                      .foregroundColor(.orange)
                      .fixedSize(horizontal: false, vertical: true)
                  }
                  .padding(12)
                  .background(Color.orange.opacity(0.15))
                  .cornerRadius(8)
                }

                VStack(alignment: .leading, spacing: 6) {
                  Text("Known Issues")
                    .font(.caption)
                    .bold()
                    .foregroundColor(.secondary)

                  Text(knownIssuesMessage)
                    .font(.caption)
                    .foregroundColor(.primary)
                    .fixedSize(horizontal: false, vertical: true)
                }
              }
            }
          }
          .padding(12)
          .background(Color(.systemGray6))
          .cornerRadius(10)
          .padding(.horizontal, 16)
        }
        .buttonStyle(.plain)
      }
      .onReceive(stateUpdateTimer) { _ in
        updateFlag.toggle()
      }
      .toolbar {
        ToolbarItem(placement: .topBarLeading) {
          Button(action: { refreshID = UUID() }) {
            Image(systemName: "arrow.clockwise")
          }
          .accessibilityLabel("Refresh")
        }

        ToolbarItem(placement: .topBarTrailing) {
          Button(action: handleDone) {
            Image(systemName: "checkmark")
          }
          .accessibilityLabel("Done")
        }
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
    }
  }
#endif
