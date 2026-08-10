import Foundation

struct SoftUnblockSessionLifecycleHandler: BlockingSessionLifecycleHandler {
  static let nfcStrategyId = "NFCSoftUnblockBlockingStrategy"
  static let qrStrategyId = "QRSoftUnblockBlockingStrategy"

  private let stopAllScheduledGrants: () -> Void
  private let stopScheduledGrantsForSession: (String) -> Void

  init(
    stopAllScheduledGrants: @escaping () -> Void = { SoftUnblockGrantScheduler.stopAll() },
    stopScheduledGrantsForSession: @escaping (String) -> Void = {
      SoftUnblockGrantScheduler.stopAll(sessionId: $0)
    }
  ) {
    self.stopAllScheduledGrants = stopAllScheduledGrants
    self.stopScheduledGrantsForSession = stopScheduledGrantsForSession
  }

  func sessionDidStart(_ context: BlockingSessionLifecycleContext) {
    stopAllScheduledGrants()
    SoftUnblockGrantStore.clearAll()

    guard supports(context.strategyId) else { return }

    let configuration = SoftUnblockStrategyData.decode(context.strategyData)
    SoftUnblockGrantStore.beginSession(
      sessionId: context.sessionId,
      profileId: context.profileId,
      maximumUnblockCount: configuration.maximumUnblockCount,
      allowanceResetIntervalInHours: configuration.allowanceResetIntervalInHours,
      startedAt: context.startedAt
    )
  }

  func sessionDidEnd(_ context: BlockingSessionLifecycleContext) {
    guard
      SoftUnblockGrantStore.isActive(
        sessionId: context.sessionId,
        profileId: context.profileId
      )
    else {
      return
    }

    stopScheduledGrantsForSession(context.sessionId)
    SoftUnblockGrantStore.endSession(sessionId: context.sessionId)
  }

  private func supports(_ strategyId: String?) -> Bool {
    strategyId == Self.nfcStrategyId || strategyId == Self.qrStrategyId
  }
}
