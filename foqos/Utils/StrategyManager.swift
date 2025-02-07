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
    
    private var nfcStrategy = NFCBlockingStrategy()
    
    func loadActiveStrategy(context: ModelContext) {
        activeSession =
            BlockedProfileSession
            .mostRecentActiveSession(in: context)

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
//        guard let profileUUID = UUID(uuidString: profileId) else {
//            errorMessage = "failed to parse profile in tag"
//            return
//        }
//
//        do {
//            guard
//                let profile = try BlockedProfiles.findProfile(
//                    byID: profileUUID,
//                    in: context
//                )
//            else {
//                errorMessage = "Failed to find a profile stored locally that matches the tag"
//                return
//            }
//
//            let url = BlockedProfiles.getProfileDeepLink(profile)
//            let nfcResults = resultFromURL(url: url)
//
//            navigationManager.clearProfileId()
//        } catch {
//            showErrorAlert(message: "Something went wrong fetching profile")
//        }
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
        
        nfcStrategy.onSessionCreation = { session in
            self.activeSession = session
            self.startTimer()
            self.errorMessage = nil
        }
        
        nfcStrategy.onErrorMessage = { message in
            self.errorMessage = message
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
            self.errorMessage = nil
        }
        
        nfcStrategy.onErrorMessage = { message in
            self.errorMessage = message
        }

        nfcStrategy.stopBlocking(context: context, session: session)
    }
}
