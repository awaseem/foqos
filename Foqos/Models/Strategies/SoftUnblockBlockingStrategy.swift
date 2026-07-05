import SwiftData
import SwiftUI

class SoftUnblockBlockingStrategy: BlockingStrategy {
  static var id: String = "SoftUnblockBlockingStrategy"

  var name: String = "Soft Unblock"
  var description: String =
    "Choose a limited number of temporary app or category unblocks, then request them directly from their shields."
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
    SoftUnblockConfigurationView(
      profileName: profile.name,
      initialConfiguration: SoftUnblockStrategyData.decode(profile.strategyData),
      onStart: { configuration in
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
          profileId: profile.id,
          maximumUnblockCount: configuration.maximumUnblockCount,
          allowanceResetIntervalInHours: configuration.allowanceResetIntervalInHours,
          startedAt: activeSession.startTime
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
