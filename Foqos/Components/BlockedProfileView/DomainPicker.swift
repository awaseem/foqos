import SwiftUI

struct DomainPicker: View {
  @Binding var domains: [String]
  @Binding var isPresented: Bool

  var allowMode: Bool = false

  @State private var newDomain: String = ""
  @State private var showingError: Bool = false
  @State private var errorMessage: String = ""

  private let maxDomains = 50

  private var message: String {
    return allowMode
      ? "Up to 50 domains can be allowed. Add domains that you want to remain accessible during sessions."
      : "Up to 50 domains can be blocked. Add domains that you want to restrict during sessions."
  }

  var body: some View {
    NavigationStack {
      Form {
        Section {
          HStack {
            TextField("Enter domain (e.g., example.com)", text: $newDomain)
              .autocapitalization(.none)
              .keyboardType(.URL)
              .textContentType(.URL)
              .onSubmit {
                addDomain()
              }

            Button(action: addDomain) {
              Image(systemName: "plus.circle.fill")
                .foregroundStyle(.blue)
                .font(.title2)
            }
            .disabled(newDomain.isEmpty || domains.count >= maxDomains)
          }
        } header: {
          Text("Add Domain")
        } footer: {
          Text(
            "Enter a domain (e.g., reddit.com, facebook.com, instagram.com). This will also \(allowMode ? "allow" : "block") all subpaths (e.g., reddit.com/r/popular) automatically."
          )
          .font(.caption)
        }

        Section {
          ForEach(domains, id: \.self) { domain in
            Text(domain)
              .font(.subheadline)
          }
          .onDelete(perform: deleteDomains)

          if domains.isEmpty {
            Text("No domains added")
              .foregroundStyle(.secondary)
              .font(.subheadline)
          }
        } header: {
          HStack {
            Text(allowMode ? "Allowed Domains" : "Blocked Domains")
            Spacer()
            Text("\(domains.count)/\(maxDomains)")
              .foregroundStyle(.secondary)
          }
        } footer: {
          VStack(alignment: .leading, spacing: 4) {
            Text(message)
              .font(.caption)

            if domains.count >= maxDomains {
              Text("Maximum number of domains reached")
                .font(.caption)
                .foregroundStyle(.orange)
            }
          }
        }
      }
      .navigationTitle(allowMode ? "Allow Domains" : "Block Domains")
      .navigationBarTitleDisplayMode(.inline)
      .toolbar {
        ToolbarItem(placement: .topBarTrailing) {
          Button(action: { isPresented = false }) {
            Image(systemName: "checkmark")
          }
          .accessibilityLabel("Done")
        }
      }
      .alert("Error", isPresented: $showingError) {
        Button("OK") {}
      } message: {
        Text(errorMessage)
      }
    }
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
      showError(
        "Enter a valid domain without https:// or www. (e.g., google.com, reddit.com, facebook.com)"
      )
      return
    }

    domains.append(trimmedDomain)
    newDomain = ""
  }

  private func deleteDomains(at offsets: IndexSet) {
    domains.remove(atOffsets: offsets)
  }

  private func showError(_ message: String) {
    errorMessage = message
    showingError = true
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
  @Previewable @State var domains: [String] = ["example.com", "test.org"]

  VStack(spacing: 20) {
    DomainPicker(
      domains: $domains,
      isPresented: .constant(true)
    )

    DomainPicker(
      domains: $domains,
      isPresented: .constant(true),
      allowMode: true
    )
  }
}
