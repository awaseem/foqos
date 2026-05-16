import SwiftUI

private enum ProfileCreationDestination {
  case choice
  case guided
  case advanced
}

struct ProfileCreationFlowView: View {
  @State private var destination: ProfileCreationDestination = .choice

  var body: some View {
    switch destination {
    case .choice:
      ProfileCreationChoiceView(
        onGuidedSetup: { destination = .guided },
        onAdvancedForm: { destination = .advanced }
      )
    case .guided:
      GuidedBlockedProfileCreationView(onBackFromFirst: { destination = .choice })
    case .advanced:
      BlockedProfileView()
    }
  }
}

struct ProfileCreationChoiceView: View {
  @Environment(\.dismiss) private var dismiss
  @EnvironmentObject private var themeManager: ThemeManager

  let onGuidedSetup: () -> Void
  let onAdvancedForm: () -> Void

  var body: some View {
    NavigationStack {
      List {
        Section {
          Button(action: onGuidedSetup) {
            creationChoiceRow(
              title: "Guided Setup",
              description: "Build a profile one step at a time with short explanations.",
              systemImage: "list.bullet.clipboard"
            )
          }

          Button(action: onAdvancedForm) {
            creationChoiceRow(
              title: "Advanced Form",
              description: "Use the full profile form and configure everything in one place.",
              systemImage: "slider.horizontal.3"
            )
          }
        }
      }
      .navigationTitle("Create Profile")
      .navigationBarTitleDisplayMode(.inline)
      .toolbar {
        ToolbarItem(placement: .topBarLeading) {
          Button(action: { dismiss() }) {
            Image(systemName: "xmark")
          }
          .accessibilityLabel("Cancel")
        }
      }
    }
  }

  private func creationChoiceRow(
    title: String,
    description: String,
    systemImage: String
  ) -> some View {
    HStack(alignment: .top, spacing: 12) {
      Image(systemName: systemImage)
        .font(.title3)
        .foregroundStyle(themeManager.themeColor)
        .frame(width: 28, height: 28)

      VStack(alignment: .leading, spacing: 4) {
        Text(title)
          .font(.headline)
          .foregroundStyle(.primary)
        Text(description)
          .font(.subheadline)
          .foregroundStyle(.secondary)
      }

      Spacer(minLength: 8)

      Image(systemName: "chevron.right")
        .font(.caption)
        .foregroundStyle(.secondary)
        .padding(.top, 6)
    }
    .padding(.vertical, 6)
  }
}

#Preview {
  ProfileCreationChoiceView(
    onGuidedSetup: {},
    onAdvancedForm: {}
  )
  .environmentObject(ThemeManager())
}
