import SwiftData
import SwiftUI

class ManualBlockingStrategy: BlockingStrategy {
  static var id: String = "ManualBlockingStrategy"

  var name: String = "Manual"
  var description: String =
    "Block and unblock profiles manually through the app"
  var iconType: String = "button.horizontal.top.press.fill"
  var color: Color = .blue

  var onSessionCreation: ((SessionStatus) -> Void)?
  var onErrorMessage: ((String) -> Void)?

  private let appBlocker: AppBlockerUtil = AppBlockerUtil()

  func getIdentifier() -> String {
    return ManualBlockingStrategy.id
  }

  func startBlocking(
    context: ModelContext,
    profile: BlockedProfiles,
    forceStart: Bool?
  ) -> (any View)? {
    self.appBlocker
      .activateRestrictions(for: BlockedProfiles.getSnapshot(for: profile))

    let activeSession =
      BlockedProfileSession
      .createSession(
        in: context,
        withTag: ManualBlockingStrategy.id,
        withProfile: profile,
        forceStart: forceStart ?? false
      )

    self.onSessionCreation?(.started(activeSession))

    return nil
  }

  func stopBlocking(
    context: ModelContext,
    session: BlockedProfileSession
  ) -> (any View)? {
    session.endSession()
    self.appBlocker.deactivateRestrictions()

    self.onSessionCreation?(.ended(session.blockedProfile))

    return nil
  }
}
