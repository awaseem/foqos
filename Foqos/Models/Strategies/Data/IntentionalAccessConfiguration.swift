import Foundation

struct IntentionalAccessConfiguration: Codable, Equatable {
  enum Kind: String, Codable, CaseIterable { case confirmation, questions }
  var questions: [AccessQuestion]?
  var kind = Kind.confirmation
  var prompt =
    "You said you only wanted to check {app} if it was genuinely not getting in the way of family time. Are you sure?"
  var accessDurationInMinutes = 5
  var maximumUnblockCount = 10
  var allowanceResetIntervalInHours: Int? = 6

  var isValid: Bool {
    if kind == .questions {
      guard let questions, (1...10).contains(questions.count),
        Set(questions.map(\.id)).count == questions.count,
        questions.allSatisfy(\.isValid)
      else { return false }
    }
    return !prompt.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty && prompt.count <= 500
      && (5...60).contains(accessDurationInMinutes) && (1...10).contains(maximumUnblockCount)
      && allowanceResetIntervalInHours == 6
  }

  static func decode(_ data: Data?) -> Self? {
    guard let data else { return Self() }
    guard let config = try? JSONDecoder().decode(Self.self, from: data), config.isValid else {
      return nil
    }
    return config
  }
}
