protocol BlockingStrategy {
    static var id: String { get }
    var name: String { get }
    var description: String { get }
    var iconType: String { get }
            
    func startBlocking(profile: BlockedProfiles)
    func stopBlocking(session: BlockedProfileSession)
}
