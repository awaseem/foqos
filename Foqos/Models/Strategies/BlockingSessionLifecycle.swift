import Foundation

struct BlockingSessionLifecycleContext {
  let strategyId: String?
  let strategyData: Data?
  let sessionId: String
  let profileId: UUID
  let startedAt: Date

  init(
    strategyId: String?,
    strategyData: Data?,
    sessionId: String,
    profileId: UUID,
    startedAt: Date
  ) {
    self.strategyId = strategyId
    self.strategyData = strategyData
    self.sessionId = sessionId
    self.profileId = profileId
    self.startedAt = startedAt
  }

  init(
    profile: SharedData.ProfileSnapshot,
    session: SharedData.SessionSnapshot
  ) {
    self.init(
      strategyId: profile.blockingStrategyId,
      strategyData: profile.strategyData,
      sessionId: session.id,
      profileId: profile.id,
      startedAt: session.startTime
    )
  }
}

protocol BlockingSessionLifecycleHandler {
  func sessionDidStart(_ context: BlockingSessionLifecycleContext)
  func sessionDidEnd(_ context: BlockingSessionLifecycleContext)
}

enum BlockingSessionLifecycleRegistry {
  private static var handlers: [any BlockingSessionLifecycleHandler] {
    [SoftUnblockSessionLifecycleHandler()]
  }

  static func sessionDidStart(_ context: BlockingSessionLifecycleContext) {
    for handler in handlers {
      handler.sessionDidStart(context)
    }
  }

  static func sessionDidEnd(_ context: BlockingSessionLifecycleContext) {
    for handler in handlers {
      handler.sessionDidEnd(context)
    }
  }
}
