import SwiftUI

struct BlockedProfileDomainSelector: View {
  var domains: [String]
  var buttonAction: () -> Void
  var allowMode: Bool = false
  var disabled: Bool = false
  var disabledText: String?

  private var title: String {
    return allowMode ? "Allowed" : "Blocked"
  }

  private var domainCount: Int {
    return domains.count
  }

  private var buttonText: String {
    return allowMode
      ? "Select domains to allow"
      : "Select domains to restrict"
  }

  var body: some View {
    Button(action: buttonAction) {
      HStack {
        Text(buttonText)
        Spacer()
        Image(systemName: "chevron.right")
          .foregroundStyle(.gray)
      }
    }
    .disabled(disabled)

    if let disabledText = disabledText, disabled {
      Text(disabledText)
        .foregroundStyle(.red)
        .padding(.top, 4)
        .font(.caption)
    } else if domainCount == 0 {
      Text("No domains selected")
        .foregroundStyle(.gray)
    } else {
      Text("\(domainCount) \(domainCount == 1 ? "domain" : "domains") selected")
        .font(.footnote)
        .foregroundStyle(.gray)
        .padding(.top, 4)
    }
  }
}

#Preview {
  VStack(spacing: 20) {
    BlockedProfileDomainSelector(
      domains: ["example.com", "test.org"],
      buttonAction: {}
    )

    BlockedProfileDomainSelector(
      domains: [],
      buttonAction: {},
      allowMode: true
    )

    BlockedProfileDomainSelector(
      domains: ["example.com"],
      buttonAction: {},
      disabled: true,
      disabledText: "Disable the current session to edit domains"
    )
  }
  .padding()
}
