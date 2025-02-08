import SwiftUI
import SwiftData

class StrategyManager: ObservableObject {
    @Published var elapsedTime: TimeInterval = 0
    @Published var timer: Timer?
    @Published var activeSession: BlockedProfileSession?
    
    @Published var errorMessage: String?
    
    var isBlocking: Bool {
        return activeSession?.isActive == true
    }
    
    func loadActiveSession(context: ModelContext) {
        activeSession = getActiveSession(context: context)
        
        if activeSession?.isActive == true {
            startTimer()
        }
    }
    
    func toggleBlocking(context: ModelContext, activeProfile: BlockedProfiles?) {
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
                self.errorMessage = "Failed to find a profile stored locally that matches the tag"
                return
            }
            
            let manualStrategy = ManualBlockingStrategy()
                        
            if let localActiveSession = getActiveSession(context: context)  {
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
    
    private func getActiveSession(context: ModelContext) -> BlockedProfileSession? {
        return BlockedProfileSession
            .mostRecentActiveSession(in: context)
    }
    
    private func resultFromURL(_ url: String) -> NFCResult {
        return NFCResult(id: url, url: url, DateScanned: Date())
    }
    
    private func startBlocking(context: ModelContext, activeProfile: BlockedProfiles?) {
        guard let definedProfile = activeProfile else {
            print(
                "No active profile found, calling stop blocking with no session"
            )
            return
        }
        
        getStrategy(id: definedProfile.blockingStrategyId).startBlocking(context: context, profile: definedProfile)
        
    }
    
    private func stopBlocking(context: ModelContext) {
        guard let session = activeSession else {
            print(
                "No active session found, calling stop blocking with no session"
            )
            return
        }
        
        getStrategy(
            id: session.blockedProfile.blockingStrategyId
        ).stopBlocking(context: context, session: session)
    }
    
    private func getStrategy(id: String) -> BlockingStrategy {
        var strategy: BlockingStrategy
        
        switch id {
        case NFCBlockingStrategy.id:
            strategy = NFCBlockingStrategy()
        case ManualBlockingStrategy.id:
            strategy = ManualBlockingStrategy()
        default:
            strategy = NFCBlockingStrategy()
        }
        
        strategy.onSessionCreation = { session in
            self.activeSession = session
            self.startTimer()
            self.errorMessage = nil
        }
        
        strategy.onErrorMessage = { message in
            self.errorMessage = message
        }
        
        return strategy
    }
}
