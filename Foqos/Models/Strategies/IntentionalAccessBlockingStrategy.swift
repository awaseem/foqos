import SwiftData
import SwiftUI

final class IntentionalAccessBlockingStrategy: BlockingStrategy {
  static let id = "IntentionalAccessBlockingStrategy"
  var name = "Intentional access"
  var description =
    "Pause before opening one app. Complete your challenge for temporary access, or stop the session whenever you choose."
  var color: Color = .blue
  var pickerCategory: BlockingStrategyPickerCategory = .easyToStart
  var startsManually: Bool = true
  var allowsTimedBreaks: Bool = false
  var supportsAllowMode: Bool = false
  var startViewPresentationDetents: Set<PresentationDetent> = [.large]
  var onSessionCreation: ((SessionStatus) -> Void)?
  var onErrorMessage: ((String) -> Void)?
  private let appBlocker = AppBlockerUtil()

  func getIdentifier() -> String { Self.id }

  func startBlocking(context: ModelContext, profile: BlockedProfiles, forceStart: Bool?) -> (
    any View
  )? {
    guard let configuration = IntentionalAccessConfiguration.decode(profile.strategyData) else {
      onErrorMessage?("Save valid challenge settings before starting.")
      return nil
    }
    if profile.shouldAskForStartSettings {
      return IntentionalAccessSettingsView(configuration: configuration) { config in
        do {
          profile.strategyData = try JSONEncoder().encode(config)
          try context.save()
          BlockedProfiles.updateSnapshot(for: profile)
          self.start(context: context, profile: profile, force: forceStart ?? false)
        } catch { self.onErrorMessage?(error.localizedDescription) }
      }
    }
    start(context: context, profile: profile, force: forceStart ?? false)
    return nil
  }

  private func start(context: ModelContext, profile: BlockedProfiles, force: Bool) {
    let session = BlockedProfileSession.createSession(
      in: context,
      withTag: Self.id, withProfile: profile, forceStart: force)
    appBlocker.activateRestrictions(for: BlockedProfiles.getSnapshot(for: profile))
    onSessionCreation?(.started(session))
  }

  func stopBlocking(context: ModelContext, session: BlockedProfileSession) -> (any View)? {
    session.endSession()
    do { try context.save() } catch {
      onErrorMessage?(error.localizedDescription)
      return nil
    }
    appBlocker.deactivateRestrictions()
    onSessionCreation?(.ended(session.blockedProfile))
    return nil
  }
}
