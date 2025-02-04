import SwiftUI
import SwiftData

class StrategyManager: ObservableObject {
    @Published var elapsedTime: TimeInterval = 0
    @Published var timer: Timer?
    @Published var activeSession: BlockedProfileSession?
    
    var isBlocking: Bool {
        return activeSession?.isActive == true
    }
    
    private var nfcStrategy = NFCBlockingStrategy()
    
    func toggleBlocking(context: ModelContext, activeProfile: BlockedProfiles?) {
        if isBlocking {
            stopBlocking(context: context)
        } else {
            startBlocking(context: context, activeProfile: activeProfile)
        }

    }
    
    private func startBlocking(context: ModelContext, activeProfile: BlockedProfiles?) {
        guard let definedProfile = activeProfile else {
            print(
                "No active profile found, calling stop blocking with no session"
            )
            return
        }
        
        nfcStrategy.onSessionCreation = { session in
            self.activeSession = session
            self.startTimer()
        }

        nfcStrategy.startBlocking(context: context, profile: definedProfile)
    }

    private func stopBlocking(context: ModelContext) {
        guard let session = activeSession else {
            print(
                "No active session found, calling stop blocking with no session"
            )
            return
        }

        nfcStrategy.onSessionCreation = { session in
            self.activeSession = session
            self.stopTimer()
        }

        nfcStrategy.stopBlocking(context: context, session: session)
    }
    
    private func startTimer() {
        timer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { _ in
            if let startTime = self.activeSession?.startTime {
                self.elapsedTime = Date().timeIntervalSince(startTime)
            }
        }
    }

    private func stopTimer() {
        timer?.invalidate()
        timer = nil
    }
}
