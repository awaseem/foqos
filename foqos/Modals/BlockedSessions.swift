import Foundation
import SwiftData

@Model
final class BlockedSession {
    var tag: String
    
    var startTime: Date
    var endTime: Date?
    
    var isActive: Bool {
        return endTime == nil
    }
    
    var duration: TimeInterval {
        let end = endTime ?? Date()
        return end.timeIntervalSince(startTime)
    }
    
    init(tag: String) {
        self.tag = tag
        
        self.startTime = Date()
    }
    
    func endSession() {
        self.endTime = Date()
    }
    
    func endSession(at date: Date) {
        self.endTime = date
    }
    
    static func mostRecentActiveSession(in context: ModelContext) -> BlockedSession? {
        var descriptor = FetchDescriptor<BlockedSession>(
            predicate: #Predicate { $0.endTime == nil },
            sortBy: [SortDescriptor(\.startTime, order: .reverse)]
        )
        descriptor.fetchLimit = 1
        
        return try? context.fetch(descriptor).first
    }
    
    static func createSession(in context: ModelContext, withTag tag: String) -> BlockedSession {
        let newSession = BlockedSession(tag: tag)
        context.insert(newSession)
        return newSession
    }
}
