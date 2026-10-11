import Foundation

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
