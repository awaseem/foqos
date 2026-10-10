import Foundation

struct FamilyOutingSettings: Codable {
  var profileID: UUID?
  var isEnabled = false
  var latitude: Double?
  var longitude: Double?
  var radius = 200.0
  var blockOutside = true
  var blockWhileMoving = false

  var hasValidRegion: Bool {
    guard let latitude, let longitude else { return false }
    return latitude.isFinite && longitude.isFinite && (-90...90).contains(latitude)
      && (-180...180).contains(longitude) && radius.isFinite && (100...1000).contains(radius)
  }
}

struct FamilyCommand: Codable {
  enum Action: String, Codable { case start, stop, remind }
  var id = UUID()
  var action: Action
  var message = "Phone away. Family time ❤️"
  var createdAt = Date()

  func isFresh(at now: Date) -> Bool {
    let age = now.timeIntervalSince(createdAt)
    return age >= -60 && age <= 300 && message.count <= 200
  }
}
