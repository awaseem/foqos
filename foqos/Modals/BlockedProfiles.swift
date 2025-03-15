import FamilyControls
import Foundation
import ManagedSettings
import SwiftData

@Model
class BlockedProfiles {
    @Attribute(.unique) var id: UUID
    var name: String
    var selectedActivity: FamilyActivitySelection
    var createdAt: Date
    var updatedAt: Date
    var blockingStrategyId: String?
    var enableLiveActivity: Bool = false
    var reminderTimeInSeconds: UInt32?
    

    @Relationship var sessions: [BlockedProfileSession] = []

    init(
        id: UUID = UUID(),
        name: String,
        selectedActivity: FamilyActivitySelection = FamilyActivitySelection(),
        createdAt: Date = Date(),
        updatedAt: Date = Date(),
        blockingStrategyId: String = NFCBlockingStrategy.id,
        enableLiveActivity: Bool = false,
        reminderTimeInSeconds: UInt32? = nil
    ) {
        self.id = id
        self.name = name
        self.selectedActivity = selectedActivity
        self.createdAt = createdAt
        self.updatedAt = updatedAt
        self.blockingStrategyId = blockingStrategyId
        self.enableLiveActivity = enableLiveActivity
        self.reminderTimeInSeconds = reminderTimeInSeconds
    }

    static func fetchProfiles(in context: ModelContext) throws
        -> [BlockedProfiles]
    {
        let descriptor = FetchDescriptor<BlockedProfiles>(
            sortBy: [SortDescriptor(\.createdAt, order: .reverse)]
        )
        return try context.fetch(descriptor)
    }

    static func findProfile(byID id: UUID, in context: ModelContext) throws
        -> BlockedProfiles?
    {
        let descriptor = FetchDescriptor<BlockedProfiles>(
            predicate: #Predicate { $0.id == id }
        )
        return try context.fetch(descriptor).first
    }

    static func fetchMostRecentlyUpdatedProfile(in context: ModelContext) throws
        -> BlockedProfiles?
    {
        let descriptor = FetchDescriptor<BlockedProfiles>(
            sortBy: [SortDescriptor(\.updatedAt, order: .reverse)]
        )
        return try context.fetch(descriptor).first
    }

    static func updateProfile(
        _ profile: BlockedProfiles,
        in context: ModelContext,
        name: String? = nil,
        selection: FamilyActivitySelection? = nil,
        blockingStrategyId: String? = nil,
        enableLiveActivity: Bool? = nil,
        reminderTime: UInt32? = nil
    ) throws {
        if let newName = name {
            profile.name = newName
        }

        if let newSelection = selection {
            profile.selectedActivity = newSelection
        }
        
        if let newStrategyId = blockingStrategyId {
            profile.blockingStrategyId = newStrategyId
        }
        
        if let newEnableLiveActivity = enableLiveActivity {
            profile.enableLiveActivity = newEnableLiveActivity
        }
        
        if let newReminderTimeInSeconds = reminderTime {
            profile.reminderTimeInSeconds = newReminderTimeInSeconds
        }

        profile.updatedAt = Date()
        try context.save()
    }

    static func deleteProfile(
        _ profile: BlockedProfiles, in context: ModelContext
    ) throws {
        // First end any active sessions
        for session in profile.sessions {
            if session.endTime == nil {
                session.endSession()
            }
        }

        // Remove all sessions first
        for session in profile.sessions {
            context.delete(session)
        }

        // Then delete the profile
        context.delete(profile)
        try context.save()
    }

    static func countSelectedActivities(_ selection: FamilyActivitySelection)
        -> Int
    {
        return selection.categories.count + selection.applications.count
    }

    static func getProfileDeepLink(_ profile: BlockedProfiles) -> String {
        return "https://foqos.app/profile/" + profile.id.uuidString
    }
}
