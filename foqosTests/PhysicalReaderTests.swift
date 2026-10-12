import XCTest

@testable import foqos

final class PhysicalReaderTests: XCTestCase {
  func testSuccessReleasesCapturedOwnerAndReader() {
    let scanner = TestNFCScanner()
    var owner: ReaderOwner? = ReaderOwner(scanner: scanner)
    weak var weakOwner = owner
    weak var weakReader = owner?.reader

    owner?.readTag()
    owner = nil
    XCTAssertNotNil(weakOwner)
    XCTAssertNotNil(weakReader)

    scanner.onTagScanned?(
      NFCResult(id: "tag-id", url: nil, DateScanned: Date(timeIntervalSinceReferenceDate: 0))
    )

    XCTAssertNil(weakOwner)
    XCTAssertNil(weakReader)
  }

  func testFailureReleasesCapturedOwnerAndReaderWithDefaultFailureHandler() {
    let scanner = TestNFCScanner()
    var owner: ReaderOwner? = ReaderOwner(scanner: scanner)
    weak var weakOwner = owner
    weak var weakReader = owner?.reader

    owner?.readTag()
    owner = nil
    XCTAssertNotNil(weakOwner)
    XCTAssertNotNil(weakReader)

    scanner.onError?("Session canceled")

    XCTAssertNil(weakOwner)
    XCTAssertNil(weakReader)
  }

  func testSuccessReturnsURLOrIdentifierAfterClearingCallbacks() {
    let cases: [(url: String?, expected: String)] = [
      ("https://foqos.app/profile/example", "https://foqos.app/profile/example"),
      (nil, "tag-id"),
    ]

    for testCase in cases {
      let scanner = TestNFCScanner()
      let reader = PhysicalReader(nfcScanner: scanner)
      var receivedTags: [String] = []

      reader.readNFCTag(
        onSuccess: { tag in
          XCTAssertNil(scanner.onTagScanned)
          XCTAssertNil(scanner.onError)
          receivedTags.append(tag)
        },
        onFailure: { error in
          XCTFail("Unexpected failure: \(error)")
        }
      )
      scanner.onTagScanned?(
        NFCResult(
          id: "tag-id", url: testCase.url, DateScanned: Date(timeIntervalSinceReferenceDate: 0))
      )
      scanner.onError?("Session invalidated")

      XCTAssertEqual(receivedTags, [testCase.expected])
    }
  }

  func testFailureForwardsErrorAfterClearingCallbacks() {
    let scanner = TestNFCScanner()
    let reader = PhysicalReader(nfcScanner: scanner)
    var receivedErrors: [String] = []

    reader.readNFCTag(
      onSuccess: { tag in
        XCTFail("Unexpected success: \(tag)")
      },
      onFailure: { error in
        XCTAssertNil(scanner.onTagScanned)
        XCTAssertNil(scanner.onError)
        receivedErrors.append(error)
      }
    )
    scanner.onError?("Session canceled")
    scanner.onTagScanned?(
      NFCResult(id: "tag-id", url: nil, DateScanned: Date(timeIntervalSinceReferenceDate: 0))
    )

    XCTAssertEqual(receivedErrors, ["Session canceled"])
  }

  func testSynchronousScanFailureClearsCallbacksAndForwardsError() {
    let scanner = TestNFCScanner()
    scanner.errorOnScan = "NFC scanning not available on this device"
    let reader = PhysicalReader(nfcScanner: scanner)
    var receivedErrors: [String] = []

    reader.readNFCTag(
      onSuccess: { tag in
        XCTFail("Unexpected success: \(tag)")
      },
      onFailure: { error in
        XCTAssertNil(scanner.onTagScanned)
        XCTAssertNil(scanner.onError)
        receivedErrors.append(error)
      }
    )

    XCTAssertEqual(receivedErrors, ["NFC scanning not available on this device"])
    XCTAssertEqual(scanner.scannedProfileNames, [""])
    XCTAssertNil(scanner.onTagScanned)
    XCTAssertNil(scanner.onError)
  }

  func testReadAfterCompletionDeliversNewResult() {
    let scanner = TestNFCScanner()
    let reader = PhysicalReader(nfcScanner: scanner)
    var firstTags: [String] = []
    var secondTags: [String] = []

    reader.readNFCTag(onSuccess: { firstTags.append($0) })
    scanner.onTagScanned?(
      NFCResult(id: "first-tag", url: nil, DateScanned: Date(timeIntervalSinceReferenceDate: 0))
    )

    reader.readNFCTag(onSuccess: { secondTags.append($0) })
    scanner.onTagScanned?(
      NFCResult(id: "second-tag", url: nil, DateScanned: Date(timeIntervalSinceReferenceDate: 1))
    )

    XCTAssertEqual(firstTags, ["first-tag"])
    XCTAssertEqual(secondTags, ["second-tag"])
    XCTAssertEqual(scanner.scannedProfileNames, ["", ""])
  }
}

private final class TestNFCScanner: NFCScannerUtil {
  var errorOnScan: String?
  var scannedProfileNames: [String] = []

  override func scan(profileName: String) {
    scannedProfileNames.append(profileName)
    if let errorOnScan {
      onError?(errorOnScan)
    }
  }
}

private final class ReaderOwner {
  let reader: PhysicalReader
  var lastTag: String?

  init(scanner: NFCScannerUtil) {
    reader = PhysicalReader(nfcScanner: scanner)
  }

  func readTag() {
    reader.readNFCTag(onSuccess: { self.lastTag = $0 })
  }
}
