import AppIntents
import SwiftData
import XCTest

@testable import foqos

@MainActor
final class BlockedProfilesQueryTests: XCTestCase {
  private var container: ModelContainer!
  private var query: BlockedProfilesQuery!

  override func setUpWithError() throws {
    container = try ModelContainer(
      for: BlockedProfiles.self, BlockedProfileSession.self,
      configurations: ModelConfiguration(isStoredInMemoryOnly: true)
    )
    query = BlockedProfilesQuery(modelContainer: container)
  }

  override func tearDownWithError() throws {
    query = nil
    container = nil
  }

  func testExactSpokenNameTakesPrecedenceOverPartialMatches() async throws {
    let work = try insertProfile(name: "Work")
    _ = try insertProfile(name: "Deep Work")

    let matches = try await query.entities(matching: "  WORK  ")

    XCTAssertEqual(matches.map(\.id), [work.id])
  }

  func testAmbiguousNameReturnsAllCandidatesForDisambiguation() async throws {
    let first = try insertProfile(name: "Work")
    let second = try insertProfile(name: "Work")

    let matches = try await query.entities(matching: "work")

    XCTAssertEqual(Set(matches.map(\.id)), [first.id, second.id])
  }

  func testPartialNameMatchesWithoutCaseOrDiacritics() async throws {
    let profile = try insertProfile(name: "Café Study")

    let matches = try await query.entities(matching: "cafe")

    XCTAssertEqual(matches.map(\.id), [profile.id])
  }

  func testUnknownOrEmptyNameDoesNotSelectAnUnrelatedProfile() async throws {
    _ = try insertProfile(name: "Work")

    let unknown = try await query.entities(matching: "Sleep")
    let empty = try await query.entities(matching: " \n ")
    let defaultProfile = await query.defaultResult()

    XCTAssertTrue(unknown.isEmpty)
    XCTAssertTrue(empty.isEmpty)
    XCTAssertNil(defaultProfile)
  }

  func testRenamedProfileKeepsItsIdentifierAndResolvesUsingNewName() async throws {
    let profile = try insertProfile(name: "Work")
    let oldEntity = BlockedProfileEntity(profile: profile)
    profile.name = "Study"
    try container.mainContext.save()

    let restored = try await query.entities(for: [oldEntity.id])
    let oldMatches = try await query.entities(matching: "Work")
    let newMatches = try await query.entities(matching: "Study")

    XCTAssertEqual(restored.map(\.name), ["Study"])
    XCTAssertEqual(newMatches.map(\.id), [oldEntity.id])
    XCTAssertTrue(oldMatches.isEmpty)
    XCTAssertEqual(oldEntity.name, "Work")
  }

  func testDeletedProfileIsRemovedFromResolutionAndSuggestions() async throws {
    let profile = try insertProfile(name: "Work")
    let id = profile.id
    container.mainContext.delete(profile)
    try container.mainContext.save()

    let restored = try await query.entities(for: [id])
    let suggestions = try await query.suggestedEntities()

    XCTAssertTrue(restored.isEmpty)
    XCTAssertTrue(suggestions.isEmpty)
  }

  private func insertProfile(name: String) throws -> BlockedProfiles {
    let profile = BlockedProfiles(name: name)
    container.mainContext.insert(profile)
    try container.mainContext.save()
    return profile
  }
}
