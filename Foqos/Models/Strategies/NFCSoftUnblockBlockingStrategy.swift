import SwiftData
import SwiftUI

final class NFCSoftUnblockBlockingStrategy: BlockingStrategy {
  static var id: String = "NFCSoftUnblockBlockingStrategy"

  var name: String = "Soft Unblock + NFC"
  var description: String =
    "Choose limited temporary app or category unblocks. To stop, scan an NFC tag. Use Strict Unlocks if you want only selected tags to work."
  var iconAssetName: String = "Soft Unblock + NFC"
  var color: Color = .purple

  var usesNFC: Bool = true
  var startsManually: Bool = true
  var isBeta: Bool = true
  var startViewPresentationDetents: Set<PresentationDetent> = [.large]

  var onSessionCreation: ((SessionStatus) -> Void)?
  var onErrorMessage: ((String) -> Void)?

  private let nfcScanner = NFCScannerUtil()
  private let appBlocker = AppBlockerUtil()

  func getIdentifier() -> String {
    Self.id
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
          withTag: Self.id,
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
    nfcScanner.onTagScanned = { tag in
      let code = tag.url ?? tag.id

      if session.blockedProfile.hasPhysicalUnblockItem(ofType: .nfc)
        && !session.blockedProfile.canUnblock(withCode: code, type: .nfc)
      {
        self.onErrorMessage?(
          "This NFC tag is not allowed to unblock this profile."
        )
        return
      }

      self.endSession(context: context, session: session)
    }

    nfcScanner.scan(profileName: session.blockedProfile.name)
    return nil
  }

  private func endSession(context: ModelContext, session: BlockedProfileSession) {
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
  }
}
