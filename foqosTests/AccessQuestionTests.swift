import XCTest

@testable import foqos

final class AccessQuestionTests: XCTestCase {
  func testAnswersIgnoreCaseAndEdgeWhitespaceButRejectWrongAndBlankAnswers() {
    let question = AccessQuestion(question: "Who am I spending time with?", answer: "My family")
    XCTAssertTrue(question.accepts("  MY FAMILY\n"))
    XCTAssertFalse(question.accepts("work"))
    XCTAssertFalse(question.accepts(""))
    XCTAssertFalse(AccessQuestion(question: "?", answer: " ").accepts(" "))
    XCTAssertFalse(AccessQuestion(question: "", answer: "yes").isValid)
    XCTAssertFalse(question.accepts(String(repeating: "x", count: 201)))
  }

  func testQuestionModeRequiresValidUniqueBoundedQuestionsAndRoundTrips() throws {
    var config = IntentionalAccessConfiguration()
    config.kind = .questions
    XCTAssertFalse(config.isValid)
    let question = AccessQuestion(question: "Are you present?", answer: "yes")
    config.questions = [question]
    XCTAssertTrue(config.isValid)
    XCTAssertEqual(IntentionalAccessConfiguration.decode(try JSONEncoder().encode(config)), config)
    config.questions = [question, question]
    XCTAssertFalse(config.isValid)
    config.questions = (0...10).map { _ in AccessQuestion(question: "?", answer: "yes") }
    XCTAssertFalse(config.isValid)
    config = .init()
    XCTAssertTrue(config.isValid)
    let old = try JSONEncoder().encode(config)
    XCTAssertEqual(IntentionalAccessConfiguration.decode(old)?.kind, .confirmation)
  }
}
