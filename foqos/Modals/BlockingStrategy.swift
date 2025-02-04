struct BlockingStrategyInputs {
    var tag: String?
}

protocol BlockingStrategy {
    var id: String { get }
    var name: String { get }
    var description: String { get }
    var iconType: String { get } 
        
    func startBlocking(data: BlockingStrategyInputs, profile: BlockedProfiles)
    func stopBlocking(data: BlockingStrategyInputs, session: BlockedProfileSession)
}
