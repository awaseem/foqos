import SwiftData

protocol BlockingStrategy {
    static var id: String { get }
    var name: String { get }
    var description: String { get }
    var iconType: String { get }
    
    // Callback closures session creation
    var onSessionCreation: ((BlockedProfileSession?) -> Void)? {
        get set
    }
    
    var onErrorMessage: ((String) -> Void)? {
        get set
    }
    
    func getIdentifier() -> String
    func startBlocking(context: ModelContext, profile: BlockedProfiles)
    func stopBlocking(context: ModelContext, session: BlockedProfileSession)
}
