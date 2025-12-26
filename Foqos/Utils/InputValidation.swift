//
//  InputValidation.swift
//  foqos
//
//  Input validation utilities for secure user input handling
//

import Foundation

// MARK: - Validation Result

enum ValidationResult {
  case valid
  case invalid(String)

  var isValid: Bool {
    if case .valid = self { return true }
    return false
  }

  var errorMessage: String? {
    if case .invalid(let message) = self { return message }
    return nil
  }
}

// MARK: - Validation Rules Protocol

protocol ValidationRule {
  func validate(_ input: String) -> ValidationResult
}

// MARK: - Common Validation Rules

struct NonEmptyRule: ValidationRule {
  let fieldName: String

  func validate(_ input: String) -> ValidationResult {
    input.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
      ? .invalid("\(fieldName) cannot be empty")
      : .valid
  }
}

struct MinLengthRule: ValidationRule {
  let minLength: Int
  let fieldName: String

  func validate(_ input: String) -> ValidationResult {
    input.count >= minLength
      ? .valid
      : .invalid("\(fieldName) must be at least \(minLength) characters")
  }
}

struct MaxLengthRule: ValidationRule {
  let maxLength: Int
  let fieldName: String

  func validate(_ input: String) -> ValidationResult {
    input.count <= maxLength
      ? .valid
      : .invalid("\(fieldName) must be at most \(maxLength) characters")
  }
}

struct AlphanumericRule: ValidationRule {
  let fieldName: String

  func validate(_ input: String) -> ValidationResult {
    let alphanumericSet = CharacterSet.alphanumerics
    let inputSet = CharacterSet(charactersIn: input)
    return alphanumericSet.isSuperset(of: inputSet)
      ? .valid
      : .invalid("\(fieldName) must contain only letters and numbers")
  }
}

struct NoSpecialCharactersRule: ValidationRule {
  let fieldName: String
  let allowedCharacters: CharacterSet

  init(fieldName: String, allowing additional: CharacterSet = CharacterSet()) {
    self.fieldName = fieldName
    self.allowedCharacters = CharacterSet.alphanumerics.union(additional)
  }

  func validate(_ input: String) -> ValidationResult {
    let inputSet = CharacterSet(charactersIn: input)
    return allowedCharacters.isSuperset(of: inputSet)
      ? .valid
      : .invalid("\(fieldName) contains invalid characters")
  }
}

// MARK: - NFC Tag ID Validation

struct NFCTagIDValidator {
  static let minLength = 4
  static let maxLength = 64

  /// Validates an NFC tag ID
  /// - Parameter tagId: The NFC tag ID to validate
  /// - Returns: ValidationResult indicating if the tag ID is valid
  static func validate(_ tagId: String) -> ValidationResult {
    let trimmed = tagId.trimmingCharacters(in: .whitespacesAndNewlines)

    // Check empty
    if trimmed.isEmpty {
      return .invalid("NFC tag ID cannot be empty")
    }

    // Check length
    if trimmed.count < minLength {
      return .invalid("NFC tag ID must be at least \(minLength) characters")
    }

    if trimmed.count > maxLength {
      return .invalid("NFC tag ID must be at most \(maxLength) characters")
    }

    // NFC tag IDs should be alphanumeric with optional hyphens and colons (for UID format)
    let allowedCharacters = CharacterSet.alphanumerics.union(CharacterSet(charactersIn: "-:"))
    let inputSet = CharacterSet(charactersIn: trimmed)

    if !allowedCharacters.isSuperset(of: inputSet) {
      return .invalid("NFC tag ID contains invalid characters")
    }

    // Check for potentially malicious patterns (injection attempts)
    let dangerousPatterns = ["<", ">", "\"", "'", ";", "&", "|", "`", "$", "(", ")", "{", "}", "[", "]"]
    for pattern in dangerousPatterns {
      if trimmed.contains(pattern) {
        return .invalid("NFC tag ID contains invalid characters")
      }
    }

    return .valid
  }

  /// Sanitizes an NFC tag ID by removing invalid characters
  static func sanitize(_ tagId: String) -> String {
    let allowedCharacters = CharacterSet.alphanumerics.union(CharacterSet(charactersIn: "-:"))
    return String(tagId.unicodeScalars.filter { allowedCharacters.contains($0) })
  }
}

// MARK: - QR Code Validation

struct QRCodeValidator {
  static let minLength = 4
  static let maxLength = 256

  /// Validates a QR code string
  /// - Parameter code: The QR code content to validate
  /// - Returns: ValidationResult indicating if the QR code is valid
  static func validate(_ code: String) -> ValidationResult {
    let trimmed = code.trimmingCharacters(in: .whitespacesAndNewlines)

    // Check empty
    if trimmed.isEmpty {
      return .invalid("QR code cannot be empty")
    }

    // Check length
    if trimmed.count < minLength {
      return .invalid("QR code must be at least \(minLength) characters")
    }

    if trimmed.count > maxLength {
      return .invalid("QR code must be at most \(maxLength) characters")
    }

    // QR codes can contain URLs or alphanumeric identifiers
    // Allow alphanumeric, hyphens, underscores, dots, colons, slashes (for URLs)
    let allowedCharacters = CharacterSet.alphanumerics.union(CharacterSet(charactersIn: "-_.:/"))
    let inputSet = CharacterSet(charactersIn: trimmed)

    if !allowedCharacters.isSuperset(of: inputSet) {
      return .invalid("QR code contains invalid characters")
    }

    // Check for potentially malicious patterns
    let dangerousPatterns = ["<script", "javascript:", "data:", "vbscript:", "onclick", "onerror"]
    let lowercased = trimmed.lowercased()
    for pattern in dangerousPatterns {
      if lowercased.contains(pattern) {
        return .invalid("QR code contains potentially unsafe content")
      }
    }

    return .valid
  }

  /// Sanitizes a QR code string by removing invalid characters
  static func sanitize(_ code: String) -> String {
    let allowedCharacters = CharacterSet.alphanumerics.union(CharacterSet(charactersIn: "-_.:/"))
    return String(code.unicodeScalars.filter { allowedCharacters.contains($0) })
  }
}

// MARK: - Profile Name Validation

struct ProfileNameValidator {
  static let minLength = 1
  static let maxLength = 50

  static func validate(_ name: String) -> ValidationResult {
    let trimmed = name.trimmingCharacters(in: .whitespacesAndNewlines)

    if trimmed.isEmpty {
      return .invalid("Profile name cannot be empty")
    }

    if trimmed.count > maxLength {
      return .invalid("Profile name must be at most \(maxLength) characters")
    }

    return .valid
  }
}

// MARK: - Domain Validation

struct DomainValidator {
  static func validate(_ domain: String) -> ValidationResult {
    let trimmed = domain.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()

    if trimmed.isEmpty {
      return .invalid("Domain cannot be empty")
    }

    // Basic domain format validation
    let domainRegex = #"^[a-z0-9]([a-z0-9-]*[a-z0-9])?(\.[a-z0-9]([a-z0-9-]*[a-z0-9])?)*\.[a-z]{2,}$"#
    let predicate = NSPredicate(format: "SELF MATCHES %@", domainRegex)

    if !predicate.evaluate(with: trimmed) {
      return .invalid("Invalid domain format")
    }

    return .valid
  }

  static func sanitize(_ domain: String) -> String {
    domain
      .trimmingCharacters(in: .whitespacesAndNewlines)
      .lowercased()
      .replacingOccurrences(of: "https://", with: "")
      .replacingOccurrences(of: "http://", with: "")
      .replacingOccurrences(of: "www.", with: "")
      .components(separatedBy: "/").first ?? domain
  }
}

// MARK: - Composite Validator

struct CompositeValidator {
  let rules: [ValidationRule]

  func validate(_ input: String) -> ValidationResult {
    for rule in rules {
      let result = rule.validate(input)
      if case .invalid = result {
        return result
      }
    }
    return .valid
  }
}
