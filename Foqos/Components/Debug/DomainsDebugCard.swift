import SwiftUI

struct DomainsDebugCard: View {
  let domains: [String]

  var body: some View {
    VStack(alignment: .leading, spacing: 8) {
      ForEach(domains, id: \.self) { domain in
        HStack {
          Text("•")
            .foregroundColor(.secondary)
          Text(domain)
            .font(.caption)
            .foregroundColor(.primary)
        }
      }
    }
  }
}

#Preview {
  DomainsDebugCard(domains: [
    "facebook.com",
    "twitter.com",
    "instagram.com",
    "reddit.com",
  ])
  .padding()
}

#Preview("Empty Domains") {
  DomainsDebugCard(domains: [])
    .padding()
}

#Preview("Single Domain") {
  DomainsDebugCard(domains: ["youtube.com"])
    .padding()
}
