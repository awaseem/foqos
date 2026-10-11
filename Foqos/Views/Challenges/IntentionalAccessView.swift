import FamilyControls
import ManagedSettings
import SwiftUI

struct IntentionalAccessView: View {
  @Environment(\.dismiss) private var dismiss
  let profile: BlockedProfiles
  let sessionID: String
  @State private var selectedApp: ApplicationToken?
  @State private var isConfirmed = false
  @State private var first = Int.random(in: 10...49)
  @State private var second = Int.random(in: 2...9)
  @State private var answer = ""
  @State private var errorMessage: String?

  private var configuration: IntentionalAccessConfiguration? {
    IntentionalAccessConfiguration.decode(profile.strategyData)
  }

  private var isSolved: Bool { isConfirmed && Int(answer) == first + second }

  var body: some View {
    NavigationStack {
      Form {
        if let configuration {
          Section("Which app?") {
            ForEach(Array(profile.selectedActivity.applicationTokens), id: \.self) { token in
              Button {
                selectedApp = token
                isConfirmed = false
                answer = ""
              } label: {
                HStack {
                  Label(token)
                  if token == selectedApp { Image(systemName: "checkmark") }
                }
              }
            }
            if profile.selectedActivity.applicationTokens.isEmpty {
              Text("Select individual apps in your profile to use challenges.")
            }
          }
          if let selectedApp {
            Section("A moment for your intention") {
              let parts = configuration.prompt.components(separatedBy: "{app}")
              ForEach(Array(parts.enumerated()), id: \.offset) { index, part in
                Text(part)
                if index < parts.count - 1 { Label(selectedApp) }
              }
              Toggle("Yes, this fits my intention", isOn: $isConfirmed)
            }
            Section("Deliberate pause") {
              Text("What is \(first) + \(second)?")
              TextField("Answer", text: $answer).keyboardType(.numberPad)
              Text("A small local puzzle, not bot detection. No third-party CAPTCHA service.")
                .font(.caption)
            }
            Button("Open for \(configuration.accessDurationInMinutes) minutes") {
              do {
                try IntentionalAccessGrant.issue(
                  token: selectedApp, profile: profile, sessionID: sessionID)
                dismiss()
              } catch { errorMessage = error.localizedDescription }
            }.disabled(!isSolved)
          }
        } else {
          Text("Invalid challenge settings. Stop the session and edit this profile.")
        }
        if let error = errorMessage { Text(error).foregroundStyle(.red) }
      }
      .navigationTitle("Intentional access")
      .toolbar { Button("Cancel") { dismiss() } }
    }
  }
}
