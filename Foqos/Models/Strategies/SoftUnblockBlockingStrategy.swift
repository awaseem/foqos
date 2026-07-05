import SwiftData
import SwiftUI

class SoftUnblockBlockingStrategy: BlockingStrategy {
  // Preserve the prototype identifier so existing profiles continue to resolve this strategy.
  static var id: String = "PauseBlockingStrategy"

  var name: String = "Soft Unblock"
  var description: String =
    "Start manually, then request temporary access to individual blocked apps or categories from their shields."
  var iconAssetName: String = "ShieldSticker"
  var color: Color = .purple

  var startsManually: Bool = true
  var isBeta: Bool = true

  var onSessionCreation: ((SessionStatus) -> Void)?
  var onErrorMessage: ((String) -> Void)?

  private let appBlocker = AppBlockerUtil()

  func getIdentifier() -> String {
    SoftUnblockBlockingStrategy.id
  }

  func startBlocking(
    context: ModelContext,
    profile: BlockedProfiles,
    forceStart: Bool?
  ) -> (any View)? {
    PauseDurationView(
      profileName: profile.name,
      title: "Access Duration",
      description: "Select how long a shield grant should open an app or category.",
      onDurationSelected: { accessDurationInMinutes in
        let configuration = SoftUnblockStrategyData(
          accessDurationInMinutes: accessDurationInMinutes
        )

        guard let data = SoftUnblockStrategyData.encode(configuration) else {
          self.onErrorMessage?("Failed to save the soft-unblock configuration.")
          return
        }

        profile.strategyData = data
        profile.updatedAt = Date()

        do {
          try context.save()
        } catch {
          self.onErrorMessage?("Failed to save the soft-unblock configuration.")
          return
        }

        BlockedProfiles.updateSnapshot(for: profile)

        let activeSession = BlockedProfileSession.createSession(
          in: context,
          withTag: SoftUnblockBlockingStrategy.id,
          withProfile: profile,
          forceStart: forceStart ?? false
        )

        SoftUnblockGrantScheduler.stopAll()
        SoftUnblockGrantStore.beginSession(
          sessionId: activeSession.id,
          profileId: profile.id
        )
        self.appBlocker.activateRestrictions(for: BlockedProfiles.getSnapshot(for: profile))
        self.onSessionCreation?(.started(activeSession))
      }
    )
  }

  func stopBlocking(
    context: ModelContext,
    session: BlockedProfileSession
  ) -> (any View)? {
    SoftUnblockGrantScheduler.stopAll(sessionId: session.id)
    SoftUnblockGrantStore.endSession(sessionId: session.id)

    session.endSession()

    do {
      try context.save()
    } catch {
      onErrorMessage?("Failed to save the completed session.")
    }

    appBlocker.deactivateRestrictions()
    onSessionCreation?(.ended(session.blockedProfile))

    return nil
  }
}
