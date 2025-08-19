import SwiftUI
import UniformTypeIdentifiers

struct CSVDocument: FileDocument {
  static var readableContentTypes: [UTType] { [.commaSeparatedText] }

  var text: String

  init(text: String) {
    self.text = text
  }

  init(configuration: ReadConfiguration) throws {
    if let data = configuration.file.regularFileContents,
      let string = String(data: data, encoding: .utf8)
    {
      self.text = string
    } else {
      self.text = ""
    }
  }

  func fileWrapper(configuration: WriteConfiguration) throws -> FileWrapper {
    let data = text.data(using: .utf8) ?? Data()
    return .init(regularFileWithContents: data)
  }
}
