import SwiftUI

struct IntentionalAccessSettingsView: View {
  @Environment(\.dismiss) private var dismiss
  @State var configuration: IntentionalAccessConfiguration
  let onSave: (IntentionalAccessConfiguration) -> Void

  var body: some View {
    Form {
      Section("Before opening an app") {
        Picker("Challenge", selection: $configuration.kind) {
          ForEach(IntentionalAccessConfiguration.Kind.allCases, id: \.self) { kind in
            Text(kind.rawValue.capitalized).tag(kind)
          }
        }
        TextField(
          "Your reminder ({app} means the selected app)", text: $configuration.prompt,
          axis: .vertical)
        Stepper(
          "Access: \(configuration.accessDurationInMinutes) minutes",
          value: $configuration.accessDurationInMinutes, in: 5...60)
        Stepper(
          "Opens per six hours: \(configuration.maximumUnblockCount)",
          value: $configuration.maximumUnblockCount, in: 1...10)
      }
      Section {
        Text(
          "Select individual apps in the profile. Each successful challenge opens one app temporarily. You can always stop the whole session without completing a challenge."
        )
        Button("Save challenge") {
          onSave(configuration)
          dismiss()
        }.disabled(!configuration.isValid)
      }
    }
    .navigationTitle("Intentional access")
  }
}
