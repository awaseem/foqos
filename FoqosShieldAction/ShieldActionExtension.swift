import Foundation
import ManagedSettings
import OSLog

private let log = Logger(
  subsystem: "dev.ambitionsoftware.foqos",
  category: "SoftUnblockShieldAction"
)

class ShieldActionExtension: ShieldActionDelegate {
  override func handle(
    action: ShieldAction,
    for application: ApplicationToken,
    completionHandler: @escaping (ShieldActionResponse) -> Void
  ) {
    handle(
      action: action,
      resource: .application(application),
      completionHandler: completionHandler
    )
  }

  override func handle(
    action: ShieldAction,
    for webDomain: WebDomainToken,
    completionHandler: @escaping (ShieldActionResponse) -> Void
  ) {
    completionHandler(.close)
  }

  override func handle(
    action: ShieldAction,
    for category: ActivityCategoryToken,
    completionHandler: @escaping (ShieldActionResponse) -> Void
  ) {
    handle(
      action: action,
      resource: .category(category),
      completionHandler: completionHandler
    )
  }

  private func handle(
    action: ShieldAction,
    resource: SoftUnblockResource,
    completionHandler: @escaping (ShieldActionResponse) -> Void
  ) {
    guard action == .primaryButtonPressed,
      let session = SoftUnblockGrantStore.activeSession,
      let snapshot = SharedData.snapshot(for: session.profileId.uuidString)
    else {
      completionHandler(.close)
      return
    }

    if snapshot.enableAllowMode, case .category = resource {
      completionHandler(.close)
      return
    }

    let configuration = SoftUnblockStrategyData.decode(snapshot.strategyData)
    let durationInMinutes = max(configuration.accessDurationInMinutes, 1)
    let now = Date()
    let grant = SoftUnblockGrant(
      id: UUID(),
      sessionId: session.sessionId,
      profileId: session.profileId,
      resource: resource,
      createdAt: now,
      expiresAt: now.addingTimeInterval(TimeInterval(durationInMinutes * 60))
    )

    guard SoftUnblockGrantStore.add(grant) else {
      completionHandler(.close)
      return
    }

    do {
      try SoftUnblockGrantScheduler.scheduleGrant(grant)
    } catch {
      SoftUnblockGrantStore.removeGrant(id: grant.id, sessionId: grant.sessionId)
      log.error("Failed to schedule a soft-unblock grant: \(error.localizedDescription)")
    }

    completionHandler(.close)
  }
}
