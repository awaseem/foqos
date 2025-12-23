import Foundation
import SwiftData

/**
 A simple model for storing multiple NFC tags per profile.
 */
@Model
class NFCTagWhitelist {
    @Attribute(.unique) var id: UUID
    var tagId: String
    var tagUrl: String?
    var name: String?
    var dateAdded: Date

    @Relationship(inverse: \BlockedProfiles.nfcWhitelist) var profile: BlockedProfiles?

    init(tagId: String, tagUrl: String? = nil, name: String? = nil, dateAdded: Date = Date()) {
        self.id = UUID()
        self.tagId = tagId
        self.tagUrl = tagUrl
        self.name = name
        self.dateAdded = dateAdded
    }
}