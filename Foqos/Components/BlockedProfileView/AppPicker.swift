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
  @State private var isMessageExpanded: Bool = false

  private var compactTitle: String {
    let displayText = FamilyActivityUtil.getCountDisplayText(selection, allowMode: allowMode)
    let action = allowMode ? "allowed" : "blocked"
    return "\(displayText) \(action)"
  }

  private var detailedMessage: String {
    return allowMode
      ? "Up to 50 apps can be allowed. Categories will expand to include all individual apps within them, which may cause you to reach the 50 app limit faster than expected."
      : "Up to 50 apps can be blocked. Each category counts as one item toward the 50 limit, regardless of how many apps it contains."
  }

  private var shouldShowWarning: Bool {
    return FamilyActivityUtil.shouldShowAllowModeWarning(selection, allowMode: allowMode)
  }

  private var warningMessage: String {
    return
      "⚠️ Warning: You have selected categories in Allow mode. Each app within these categories counts toward the 50 app limit, which may cause you to exceed the limit."
  }

  private var knownIssuesMessage: String {
    return
      "Apple's app picker may occasionally crash. We apologize for the inconvenience and are waiting for an official fix."
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
                  Text("Limits")
                    .font(.caption)
                    .bold()
                    .foregroundColor(.secondary)

                  Text(detailedMessage)
                    .font(.caption)
                    .foregroundColor(.primary)
                    .fixedSize(horizontal: false, vertical: true)
                }

                if shouldShowWarning {
                  VStack(alignment: .leading, spacing: 6) {
                    Text("Warning")
                      .font(.caption)
                      .bold()
                      .foregroundColor(.orange)

                    Text(warningMessage)
                      .font(.caption)
                      .foregroundColor(.orange)
                      .fixedSize(horizontal: false, vertical: true)
                  }
                  .padding(10)
                  .background(Color.orange.opacity(0.1))
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
          Button(action: { isPresented = false }) {
            Image(systemName: "checkmark")
          }
          .accessibilityLabel("Done")
        }
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
