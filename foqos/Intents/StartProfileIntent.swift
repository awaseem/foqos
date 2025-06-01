import SwiftData
import AppIntents

struct StartProfileIntent: AppIntent {
    @Dependency(key: "ModelContainer")
    private var modelContainer: ModelContainer
    
    @MainActor
    private var modelContext: ModelContext {
        return modelContainer.mainContext
    }
    
    
    @Parameter(title: "Profile") var profile: BlockedProfileEntity

    static var title: LocalizedStringResource = "Start Foqos Profile"
    
    @MainActor
    func perform() async throws -> some IntentResult {
        let strategyManager = StrategyManager.shared
        
        print(
            "Starting profile with ID: \(strategyManager.activeSession?.blockedProfile.name ?? "Unknown")"
        )
        
        let testURL = URL(string: "https://google.com")!
        
        strategyManager
            .toggleSessionFromDeeplink(
                profile.id.uuidString,
                url: testURL,
                context: modelContext
            )
        
        strategyManager.loadActiveSession(context: modelContext)

        
        return .result()
    }
}


