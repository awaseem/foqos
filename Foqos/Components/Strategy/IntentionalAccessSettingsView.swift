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
      if configuration.kind == .questions {
        Section("Your questions") {
          ForEach(configuration.questions ?? []) { question in
            Text(question.question.isEmpty ? "New question" : question.question)
            TextField(
              "Question", text: questionBinding(question.id, answer: false), axis: .vertical)
            TextField("Accepted answer", text: questionBinding(question.id, answer: true))
            Button("Remove question", role: .destructive) {
              configuration.questions?.removeAll { $0.id == question.id }
            }
          }
          Button("Add question") {
            configuration.questions = (configuration.questions ?? []) + [AccessQuestion()]
          }.disabled((configuration.questions?.count ?? 0) >= 10)
          Text(
            "Every answer must match, ignoring letter case and surrounding spaces. Answers stay on this phone; this is voluntary friction, not a secret or secure quiz."
          )
          .font(.caption)
        }
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
  private func questionBinding(_ id: UUID, answer: Bool) -> Binding<String> {
    Binding {
      guard let question = configuration.questions?.first(where: { $0.id == id }) else { return "" }
      return answer ? question.answer : question.question
    } set: { value in
      guard let index = configuration.questions?.firstIndex(where: { $0.id == id }) else { return }
      if answer {
        configuration.questions?[index].answer = value
      } else {
        configuration.questions?[index].question = value
      }
    }
  }
}
