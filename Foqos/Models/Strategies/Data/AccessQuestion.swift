import Foundation

struct AccessQuestion: Codable, Equatable, Identifiable {
  var id = UUID()
  var question = ""
  var answer = ""

  var isValid: Bool {
    !question.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
      && question.count <= 500 && !answer.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
      && answer.count <= 200
  }

  func accepts(_ response: String) -> Bool {
    isValid && response.count <= 200
      && response.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        == answer.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
  }
}
