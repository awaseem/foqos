import SwiftData
import SwiftUI

class StrategyManager: ObservableObject {
    static let availableStrategies: [BlockingStrategy] = [
        NFCBlockingStrategy(),
        ManualBlockingStrategy(),
        NFCManualBlockingStrategy(),
        QRCodeBlockingStrategy(),
        QRManualBlockingStrategy(),
    ]

    @Published var elapsedTime: TimeInterval = 0
    @Published var timer: Timer?
    @Published var activeSession: BlockedProfileSession?

    @Published var showCustomStrategyView: Bool = false
    @Published var customStrategyView: (any View)? = nil

    @Published var errorMessage: String?

    private let timersUtil = TimersUtil()
    private let liveActivityManager = LiveActivityManager.shared

    var isBlocking: Bool {
        return activeSession?.isActive == true
    }

    func loadActiveSession(context: ModelContext) {
        activeSession = getActiveSession(context: context)

        if activeSession?.isActive == true {
            startTimer()

            // Start live activity for existing session if one exists
            if let session = activeSession {
                liveActivityManager.startSessionActivity(session: session)
            }
        }
    }

    func toggleBlocking(context: ModelContext, activeProfile: BlockedProfiles?)
    {
        if isBlocking {
            stopBlocking(context: context)
        } else {
            startBlocking(context: context, activeProfile: activeProfile)
        }
    }

    func startTimer() {
        timer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { _ in
            if let startTime = self.activeSession?.startTime {
                self.elapsedTime = Date().timeIntervalSince(startTime)

                // Update live activity with new elapsed time
                if let profile = self.activeSession?.blockedProfile,
                    profile.enableLiveActivity
                {
                    self.liveActivityManager.updateSessionActivity(
                        elapsedTime: self.elapsedTime)
                }
            }
        }
    }

    func stopTimer() {
        timer?.invalidate()
        timer = nil
    }

    func toggleSessionFromDeeplink(_ profileId: String, context: ModelContext) {
        guard let profileUUID = UUID(uuidString: profileId) else {
            self.errorMessage = "failed to parse profile in tag"
            return
        }

        do {
            guard
                let profile = try BlockedProfiles.findProfile(
                    byID: profileUUID,
                    in: context
                )
            else {
                self.errorMessage =
                    "Failed to find a profile stored locally that matches the tag"
                return
            }

            let manualStrategy = getStrategy(id: ManualBlockingStrategy.id)

            if let localActiveSession = getActiveSession(context: context) {
                manualStrategy
                    .stopBlocking(
                        context: context,
                        session: localActiveSession
                    )
            } else {
                manualStrategy.startBlocking(context: context, profile: profile)
            }
        } catch {
            self.errorMessage = "Something went wrong fetching profile"
        }
    }

    static func getStrategyFromId(id: String) -> BlockingStrategy {
        if let strategy = availableStrategies.first(
            where: {
                $0.getIdentifier() == id
            })
        {
            return strategy
        } else {
            return NFCBlockingStrategy()
        }
    }

    func getStrategy(id: String) -> BlockingStrategy {
        var strategy = StrategyManager.getStrategyFromId(id: id)

        strategy.onSessionCreation = { session in
            self.dismissView()

            self.activeSession = session
            self.startTimer()
            self.errorMessage = nil

            // Start a live activity when a new session is created
            if let activeSession = session {
                self.liveActivityManager
                    .startSessionActivity(session: activeSession)
            } else {
                // End the live activity when blocking stops
                self.liveActivityManager.endSessionActivity()
                self.timersUtil.cancelAll()
            }
        }

        strategy.onErrorMessage = { message in
            self.dismissView()

            self.errorMessage = message
        }

        return strategy
    }

    private func dismissView() {
        showCustomStrategyView = false
        customStrategyView = nil
    }

    private func getActiveSession(context: ModelContext)
        -> BlockedProfileSession?
    {
        return
            BlockedProfileSession
            .mostRecentActiveSession(in: context)
    }

    private func resultFromURL(_ url: String) -> NFCResult {
        return NFCResult(id: url, url: url, DateScanned: Date())
    }

    private func startBlocking(
        context: ModelContext, activeProfile: BlockedProfiles?
    ) {
        guard let definedProfile = activeProfile else {
            print(
                "No active profile found, calling stop blocking with no session"
            )
            return
        }

        if let strategyId = definedProfile.blockingStrategyId {
            let strategy = getStrategy(id: strategyId)
            let view = strategy.startBlocking(
                context: context,
                profile: definedProfile
            )

            if let customView = view {
                showCustomStrategyView = true
                customStrategyView = customView
            }
        }
    }

    private func stopBlocking(context: ModelContext) {
        guard let session = activeSession else {
            print(
                "No active session found, calling stop blocking with no session"
            )
            return
        }

        if let strategyId = session.blockedProfile.blockingStrategyId {
            let strategy = getStrategy(id: strategyId)
            let view = strategy.stopBlocking(context: context, session: session)

            if let customView = view {
                showCustomStrategyView = true
                customStrategyView = customView
            }
        }

        // Reset timer and session
        stopTimer()
        elapsedTime = 0
    }
}
