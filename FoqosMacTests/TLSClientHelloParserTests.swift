import Network
import Security
import XCTest

final class TLSClientHelloParserTests: XCTestCase {
  func testParsesClientHelloFromSupportedTLSVersions() throws {
    let configurations: [(name: String, version: tls_protocol_version_t)] = [
      ("TLS 1.2", .TLSv12),
      ("TLS 1.3", .TLSv13),
    ]

    for configuration in configurations {
      let clientHello = try captureClientHello(
        serverName: "Blocked.Example.com",
        version: configuration.version
      )

      guard case .hostname(let hostname) = TLSClientHelloParser.parse(clientHello) else {
        XCTFail("Failed to parse the \(configuration.name) ClientHello")
        continue
      }

      XCTAssertEqual(hostname, "blocked.example.com", configuration.name)
    }
  }

  func testPopularSiteClientHellosMatchBlockingRules() throws {
    let rules = FilterRules(
      isEnabled: true,
      domains: ["youtube.com", "x.com", "facebook.com"]
    )
    let hostnames = [
      "www.youtube.com",
      "x.com",
      "m.facebook.com",
    ]

    for hostname in hostnames {
      let clientHello = try captureClientHello(
        serverName: hostname,
        version: .TLSv13
      )

      guard case .hostname(let parsedHostname) = TLSClientHelloParser.parse(clientHello) else {
        XCTFail("Failed to parse the ClientHello for \(hostname)")
        continue
      }

      XCTAssertTrue(rules.shouldBlock(parsedHostname), hostname)
    }

    XCTAssertFalse(rules.shouldBlock("notyoutube.com"))
    XCTAssertFalse(rules.shouldBlock("example.com"))
  }

  func testRequestsMoreBytesForFragmentedClientHello() throws {
    let clientHello = try captureClientHello(
      serverName: "fragmented.example.com",
      version: .TLSv13
    )

    for byteCount in [0, 1, 4, clientHello.count - 1] {
      guard
        case .needMoreData(let requiredByteCount) =
          TLSClientHelloParser.parse(clientHello.prefix(byteCount))
      else {
        XCTFail("Expected \(byteCount) bytes to be treated as an incomplete ClientHello")
        continue
      }

      XCTAssertGreaterThan(requiredByteCount, byteCount)
    }
  }

  func testRejectsPlainTCPData() {
    let request = Data("GET / HTTP/1.1\r\nHost: example.com\r\n\r\n".utf8)

    guard case .notClientHello = TLSClientHelloParser.parse(request) else {
      XCTFail("Expected plain TCP data not to be treated as a TLS ClientHello")
      return
    }
  }

  private func captureClientHello(
    serverName: String,
    version: tls_protocol_version_t
  ) throws -> Data {
    let queue = DispatchQueue(label: "TLSClientHelloParserTests.capture")
    let listener = try NWListener(using: .tcp, on: .any)
    let completion = expectation(description: "Capture \(serverName) ClientHello")
    let lock = NSLock()
    var capturedData: Data?
    var capturedError: Error?
    var clientConnection: NWConnection?
    var serverConnection: NWConnection?
    var isComplete = false

    func finish(data: Data? = nil, error: Error? = nil) {
      lock.lock()
      defer {
        lock.unlock()
      }

      guard !isComplete else {
        return
      }

      isComplete = true
      capturedData = data
      capturedError = error
      completion.fulfill()
    }

    func receiveClientHello(from connection: NWConnection, data: Data = Data()) {
      connection.receive(minimumIncompleteLength: 1, maximumLength: 65_535) {
        content, _, isComplete, error in
        var receivedData = data
        if let content {
          receivedData.append(content)
        }

        switch TLSClientHelloParser.parse(receivedData) {
        case .hostname, .notClientHello:
          finish(data: receivedData)
        case .needMoreData:
          if let error {
            finish(error: error)
          } else if isComplete {
            finish(error: CaptureError.connectionClosed)
          } else {
            receiveClientHello(from: connection, data: receivedData)
          }
        }
      }
    }

    listener.newConnectionHandler = { connection in
      serverConnection = connection
      connection.start(queue: queue)
      receiveClientHello(from: connection)
    }

    listener.stateUpdateHandler = { state in
      switch state {
      case .ready:
        guard let port = listener.port else {
          finish(error: CaptureError.listenerHasNoPort)
          return
        }

        let tlsOptions = NWProtocolTLS.Options()
        sec_protocol_options_set_tls_server_name(
          tlsOptions.securityProtocolOptions,
          serverName
        )
        sec_protocol_options_set_min_tls_protocol_version(
          tlsOptions.securityProtocolOptions,
          version
        )
        sec_protocol_options_set_max_tls_protocol_version(
          tlsOptions.securityProtocolOptions,
          version
        )

        let parameters = NWParameters(
          tls: tlsOptions,
          tcp: NWProtocolTCP.Options()
        )
        let connection = NWConnection(
          host: .ipv4(.loopback),
          port: port,
          using: parameters
        )
        clientConnection = connection
        connection.stateUpdateHandler = { state in
          if case .failed(let error) = state {
            finish(error: error)
          }
        }
        connection.start(queue: queue)

      case .failed(let error):
        finish(error: error)
      default:
        break
      }
    }

    listener.start(queue: queue)
    let waitResult = XCTWaiter.wait(for: [completion], timeout: 5)

    clientConnection?.cancel()
    serverConnection?.cancel()
    listener.cancel()

    guard waitResult == .completed else {
      throw CaptureError.timedOut
    }

    if let capturedError {
      throw capturedError
    }

    guard let capturedData else {
      throw CaptureError.noData
    }

    return capturedData
  }
}

private enum CaptureError: Error {
  case connectionClosed
  case listenerHasNoPort
  case noData
  case timedOut
}
