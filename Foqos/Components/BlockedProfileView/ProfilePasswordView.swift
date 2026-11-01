import SwiftData
import SwiftUI

enum ProfilePasswordMode: String, Identifiable {
  case setup
  case unlock
  case change

  var id: String { rawValue }

  var title: String {
    switch self {
    case .setup: return "Protect Your Profile"
    case .unlock: return "A Little Help from a Friend"
    case .change: return "Choose a New Password"
    }
  }

  var buttonTitle: String {
    switch self {
    case .setup: return "Protect Profile"
    case .unlock: return "Unlock Profile"
    case .change: return "Update Password"
    }
  }
}

struct ProfilePasswordView: View {
  @Environment(\.dismiss) private var dismiss
  @Environment(\.modelContext) private var modelContext
  @Environment(\.scenePhase) private var scenePhase
  @EnvironmentObject private var themeManager: ThemeManager
  @EnvironmentObject private var strategyManager: StrategyManager

  let profile: BlockedProfiles
  let mode: ProfilePasswordMode
  var authorization: ProfileEditAuthorization? = nil
  var onUnlock: (ProfileEditAuthorization) -> Void = { _ in }

  @State private var password = ""
  @State private var confirmation = ""
  @State private var errorMessage: String?
  @State private var operation: Task<Void, Never>?
  @FocusState private var focusedField: Field?

  private enum Field {
    case password
    case confirmation
  }

  private var isUnlocking: Bool { mode == .unlock }
  private var isWorking: Bool { operation != nil }
  private var isBlocking: Bool { strategyManager.activeSession?.isActive == true }
  private var canSubmit: Bool {
    ProfileLockUtil.isValidPassword(password)
      && (isUnlocking || password == confirmation)
      && !isBlocking
  }

  var body: some View {
    NavigationStack {
      Form {
        Section {
          VStack(spacing: 12) {
            Image("ProfileLockSticker")
              .resizable()
              .scaledToFit()
              .frame(maxWidth: 140)
              .rotationEffect(.degrees(-4))
              .frame(maxWidth: .infinity)
              .accessibilityHidden(true)

            Text(mode.title)
              .font(.headline)
              .multilineTextAlignment(.center)

            Text(description)
              .font(.subheadline)
              .foregroundStyle(.primary)
              .multilineTextAlignment(.center)
              .fixedSize(horizontal: false, vertical: true)
          }
          .padding(.horizontal, 8)
          .padding(.vertical, 12)
        }

        passwordFields

        if let errorMessage {
          Section {
            Text(errorMessage)
              .font(.subheadline)
              .foregroundStyle(.red)
              .accessibilityIdentifier("profilePasswordError")
          }
        }

        Section {
          ActionButton(
            title: mode.buttonTitle,
            backgroundColor: themeManager.themeColor,
            iconName: isUnlocking ? "lock.open" : "lock",
            isLoading: isWorking,
            isDisabled: !canSubmit,
            action: submit
          )
          .accessibilityIdentifier("profilePasswordSubmit")
          .listRowInsets(EdgeInsets())
          .listRowBackground(Color.clear)
        } footer: {
          Text(protectionNote)
            .font(.footnote)
            .foregroundStyle(.secondary)
            .multilineTextAlignment(.center)
            .frame(maxWidth: .infinity)
            .fixedSize(horizontal: false, vertical: true)
        }
      }
      .scrollDismissesKeyboard(.interactively)
      .navigationTitle(isUnlocking ? "Unlock Profile" : "Profile Password")
      .navigationBarTitleDisplayMode(.inline)
      .toolbar {
        ToolbarItem(placement: .topBarLeading) {
          Button(action: { dismiss() }) {
            Image(systemName: "xmark")
          }
          .accessibilityLabel("Cancel")
        }

      }
      .onChange(of: password) { _, _ in errorMessage = nil }
      .onChange(of: confirmation) { _, _ in errorMessage = nil }
      .onChange(of: scenePhase) { _, phase in
        if phase == .background {
          cancelOperation()
          dismiss()
        }
      }
      .onChange(of: isBlocking) { _, blocking in
        if blocking {
          cancelOperation()
          dismiss()
        }
      }
      .onDisappear { cancelOperation() }
    }
  }

  private var description: String {
    if isUnlocking {
      return "Enter the password for \(profile.name) to make changes. Your trusted person can help."
    }
    return
      "Let someone you trust choose a password for \(profile.name). You’ll need it to edit, duplicate, or delete this profile."
  }

  private var protectionNote: String {
    isUnlocking
      ? "Your profile locks again when you close the editor or leave the app."
      : "There’s no password recovery. Make sure someone you trust keeps it safe."
  }

  private var passwordFields: some View {
    Group {
      Section {
        SecureField("Password", text: $password)
          .textContentType(.none)
          .textInputAutocapitalization(.never)
          .autocorrectionDisabled()
          .focused($focusedField, equals: .password)
          .submitLabel(isUnlocking ? .go : .next)
          .onSubmit {
            if isUnlocking { submit() } else { focusedField = .confirmation }
          }
          .accessibilityIdentifier("profilePassword")
      } header: {
        Text(isUnlocking ? "Password" : "Choose a password")
      } footer: {
        Text("\(password.count)/\(ProfileLockUtil.maximumPasswordLength) characters")
          .font(.caption)
          .foregroundStyle(
            password.count > ProfileLockUtil.maximumPasswordLength ? .red : .secondary)
      }

      if !isUnlocking {
        Section {
          SecureField("Enter it again", text: $confirmation)
            .textContentType(.none)
            .textInputAutocapitalization(.never)
            .autocorrectionDisabled()
            .focused($focusedField, equals: .confirmation)
            .submitLabel(.go)
            .onSubmit { submit() }
            .accessibilityIdentifier("profilePasswordConfirmation")
        } header: {
          Text("Confirm password")
        } footer: {
          if !confirmation.isEmpty && password != confirmation {
            Text("Passwords don’t match yet.")
              .font(.caption)
              .foregroundStyle(.secondary)
          }
        }
      }
    }
    .disabled(isWorking)
    .privacySensitive()
  }

  private func submit() {
    guard canSubmit, !isWorking else { return }
    focusedField = nil
    errorMessage = nil
    let enteredPassword = password
    let previousCredential = profile.editLockCredential

    operation = Task { @MainActor in
      defer { operation = nil }
      do {
        if isUnlocking {
          let unlocked = try await ProfileLockUtil.unlock(profile, password: enteredPassword)
          guard !isBlocking else { return }
          onUnlock(unlocked)
        } else {
          let credential = try await Task.detached(priority: .userInitiated) {
            try ProfileLockUtil.createCredential(password: enteredPassword)
          }.value
          try Task.checkCancellation()
          guard !isBlocking, profile.editLockCredential == previousCredential else {
            throw ProfileLockError.unlockRequired
          }
          try ProfileLockUtil.setCredential(
            credential, for: profile, in: modelContext, authorization: authorization
          )
        }
        password = ""
        confirmation = ""
        dismiss()
      } catch is CancellationError {
        return
      } catch {
        errorMessage = error.localizedDescription
      }
    }
  }

  private func cancelOperation() {
    operation?.cancel()
    password = ""
    confirmation = ""
  }
}

#Preview("Protect Profile") {
  ProfilePasswordView(profile: BlockedProfiles(name: "Deep Work"), mode: .setup)
    .environmentObject(ThemeManager())
    .environmentObject(StrategyManager())
    .modelContainer(for: BlockedProfiles.self, inMemory: true)
}

#Preview("Unlock Profile") {
  ProfilePasswordView(profile: BlockedProfiles(name: "Deep Work"), mode: .unlock)
    .environmentObject(ThemeManager())
    .environmentObject(StrategyManager())
    .modelContainer(for: BlockedProfiles.self, inMemory: true)
}
