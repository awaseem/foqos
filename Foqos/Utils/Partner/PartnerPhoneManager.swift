import SwiftData
import SwiftUI
import UserNotifications

@MainActor
final class PartnerPhoneManager: ObservableObject {
  @Published var profileID: UUID? { didSet { control.profileID = profileID } }
  @Published var audit: [String]
  @Published var errorMessage: String?
  private let context: ModelContext
  private let defaults: UserDefaults
  private let control: ProfileSessionControl

  var isActive: Bool { BlockedProfileSession.mostRecentActiveSession(in: context) != nil }

  init(
    context: ModelContext, defaults: UserDefaults = .standard,
    control: ProfileSessionControl? = nil
  ) {
    self.context = context
    self.defaults = defaults
    let control =
      control ?? ProfileSessionControl(context: context, key: "partner.control", defaults: defaults)
    self.control = control
    profileID = control.profileID
    audit = defaults.stringArray(forKey: "partner.audit") ?? []
  }

  func apply(
    _ action: FamilyCommand.Action, source: String,
    message: String = "Phone away. Family time ❤️"
  ) {
    errorMessage = nil
    if action == .remind {
      let content = UNMutableNotificationContent()
      content.title = "Family time"
      content.body = String(message.prefix(200))
      content.sound = .default
      let request = UNNotificationRequest(
        identifier: UUID().uuidString, content: content, trigger: nil)
      UNUserNotificationCenter.current().add(request) { [weak self] error in
        if let error { Task { @MainActor in self?.errorMessage = error.localizedDescription } }
      }
      record("\(source): reminder received — \(content.body)")
      return
    }
    if control.setActive(action == .start) {
      record("\(source): \(action.rawValue)")
    } else if let error = control.errorMessage {
      errorMessage = error
      record("\(source): failed — \(error)")
    }
  }

  func observeSession() {
    guard profileID != nil else { return }
    let session = BlockedProfileSession.mostRecentActiveSession(in: context)
    let state = session.map { "\($0.id):\($0.isBreakActive):\($0.isPauseActive)" } ?? "inactive"
    guard state != defaults.string(forKey: "partner.observedState") else { return }
    defaults.set(state, forKey: "partner.observedState")
    record(
      session.map {
        "Observed \($0.blockedProfile.name): \($0.isBreakActive ? "break" : $0.isPauseActive ? "pause" : "active")"
      } ?? "Observed: no active session")
  }

  func snapshot() -> String {
    let session = BlockedProfileSession.mostRecentActiveSession(in: context)
    let state =
      session.map {
        "\($0.blockedProfile.name): \($0.isBreakActive ? "on break" : $0.isPauseActive ? "paused" : "active")"
      } ?? "No active session"
    return
      "Updated: \(Date().formatted())\n\(state)\n"
      + audit.suffix(30).joined(separator: "\n")
  }

  func record(_ text: String) {
    audit.append("\(Date().formatted()): \(text)")
    audit = Array(audit.suffix(100))
    defaults.set(audit, forKey: "partner.audit")
  }

}
