import SwiftUI

struct DomainPicker: View {
  @Binding var domains: [String]
  @Binding var isPresented: Bool

  var allowMode: Bool = false

  @State private var newDomain: String = ""
  @State private var showingError: Bool = false
  @State private var errorMessage: String = ""

  private let maxDomains = 50

  private var title: String {
    let action = allowMode ? "allowed" : "blocked"
    return "\(domains.count) \(action)"
  }

  private var message: String {
    return allowMode
      ? "Up to 50 domains can be allowed. Add domains that you want to remain accessible during focus sessions."
      : "Up to 50 domains can be blocked. Add domains that you want to restrict during focus sessions."
  }

  var body: some View {
    VStack(alignment: .leading, spacing: 16) {
      // Add domain section
      VStack(alignment: .leading, spacing: 8) {
        HStack {
          TextField("Enter domain (e.g., example.com)", text: $newDomain)
            .autocapitalization(.none)
            .keyboardType(.URL)
            .textFieldStyle(RoundedBorderTextFieldStyle())
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
        .padding(.horizontal, 16)

        if showingError {
          Text(errorMessage)
            .font(.caption)
            .foregroundStyle(.red)
            .padding(.horizontal, 16)
        }
      }

      // Domain list
      List {
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
      }
      .listStyle(PlainListStyle())

      // Status and info
      VStack(alignment: .leading, spacing: 8) {
        Text(title)
          .font(.title3)
          .padding(.horizontal, 16)
          .bold()

        Text(message)
          .font(.caption)
          .padding(.horizontal, 16)

        if domains.count >= maxDomains {
          Text("Maximum number of domains reached")
            .font(.caption)
            .foregroundStyle(.orange)
            .padding(.horizontal, 16)
        }
      }

      ActionButton(title: "Done", backgroundColor: .blue) {
        isPresented = false
      }
    }
    .padding()
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
  .padding()
}
