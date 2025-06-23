import FamilyControls
import SwiftUI

struct DomainSelector: View {
  @Binding var domains: [String]
  var allowMode: Bool = false
  var disabled: Bool = false
  var disabledText: String?

  @State private var newDomain: String = ""
  @State private var showingError: Bool = false
  @State private var errorMessage: String = ""

  private let maxDomains = 50

  private var title: String {
    return allowMode ? "Allowed Domains" : "Blocked Domains"
  }

  private var addButtonText: String {
    return allowMode ? "Add allowed domain" : "Add blocked domain"
  }

  var body: some View {
    Form {
      // Add domain section
      if !disabled {
        Section("Add Domain") {
          HStack {
            TextField("Enter domain (e.g., example.com)", text: $newDomain)
              .autocapitalization(.none)
              .keyboardType(.URL)
              .onSubmit {
                addDomain()
              }

            Button(action: addDomain) {
              Image(systemName: "plus.circle.fill")
                .foregroundStyle(.blue)
            }
            .disabled(newDomain.isEmpty || domains.count >= maxDomains)
          }

          if showingError {
            Text(errorMessage)
              .font(.caption)
              .foregroundStyle(.red)
          }
        }
      }

      // Domain list section
      Section {
        // Disabled text
        if let disabledText = disabledText, disabled {
          Text(disabledText)
            .foregroundStyle(.red)
            .font(.caption)
        }

        // Domain list
        if domains.isEmpty {
          Text("No domains added")
            .foregroundStyle(.secondary)
            .font(.subheadline)
        } else {
          ForEach(domains, id: \.self) { domain in
            Text(domain)
              .font(.subheadline)
          }
          .onDelete(perform: disabled ? nil : deleteDomains)
        }

        // Domain count limit warning
        if domains.count >= maxDomains {
          Text("Maximum number of domains reached")
            .font(.caption)
            .foregroundStyle(.orange)
        }
      } header: {
        HStack {
          Text(title)
          Spacer()
          Text("\(domains.count)/\(maxDomains)")
            .font(.caption)
            .foregroundStyle(.secondary)
        }
      }
    }
    .animation(.easeInOut(duration: 0.2), value: domains.count)
    .animation(.easeInOut(duration: 0.2), value: showingError)
  }

  private func addDomain() {
    let trimmedDomain = newDomain.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()

    guard !trimmedDomain.isEmpty else {
      showError("Please enter a domain")
      return
    }

    guard domains.count < maxDomains else {
      showError("Maximum number of domains (\(maxDomains)) reached")
      return
    }

    guard !domains.contains(trimmedDomain) else {
      showError("Domain already exists")
      return
    }

    guard isValidDomain(trimmedDomain) else {
      showError("Please enter a valid domain (e.g., example.com)")
      return
    }

    domains.append(trimmedDomain)
    newDomain = ""
    hideError()
  }

  private func deleteDomains(at offsets: IndexSet) {
    domains.remove(atOffsets: offsets)
  }

  private func showError(_ message: String) {
    errorMessage = message
    showingError = true

    DispatchQueue.main.asyncAfter(deadline: .now() + 3) {
      hideError()
    }
  }

  private func hideError() {
    showingError = false
    errorMessage = ""
  }

  private func isValidDomain(_ domain: String) -> Bool {
    // Basic domain validation
    let domainRegex =
      #"^[a-zA-Z0-9]([a-zA-Z0-9-]{0,61}[a-zA-Z0-9])?(\.[a-zA-Z0-9]([a-zA-Z0-9-]{0,61}[a-zA-Z0-9])?)*$"#
    let predicate = NSPredicate(format: "SELF MATCHES %@", domainRegex)

    // Additional checks
    guard domain.count <= 253 else { return false }  // Max domain length
    guard !domain.hasPrefix(".") && !domain.hasSuffix(".") else { return false }
    guard !domain.contains("..") else { return false }  // No consecutive dots
    guard domain.contains(".") else { return false }  // Must have at least one dot

    return predicate.evaluate(with: domain)
  }
}

#Preview {
  @State var domains: [String] = ["example.com", "test.org"]

  VStack(spacing: 20) {
    DomainSelector(
      domains: $domains
    )

    DomainSelector(
      domains: $domains,
      allowMode: true
    )

    DomainSelector(
      domains: $domains,
      disabled: true,
      disabledText: "Disable the current session to edit domains"
    )
  }
  .padding()
}
