import SwiftUI

struct CustomToggle: View {
  @EnvironmentObject var themeManager: ThemeManager

  let title: String
  let description: String
  @Binding var isOn: Bool
  var isDisabled: Bool = false
  var errorMessage: String? = nil
  var learnMoreURL: URL? = nil

  private var attributedDescription: AttributedString {
    var attributedDescription = AttributedString(description)

    guard let learnMoreURL else {
      return attributedDescription
    }

    attributedDescription.append(AttributedString(" "))

    var learnMore = AttributedString("Learn more")
    learnMore.link = learnMoreURL
    learnMore.foregroundColor = themeManager.themeColor
    attributedDescription.append(learnMore)

    return attributedDescription
  }

  var body: some View {
    VStack(alignment: .leading, spacing: 0) {
      Toggle(title, isOn: $isOn)
        .disabled(isDisabled)
        .tint(themeManager.themeColor)

      Text(attributedDescription)
        .font(.caption)
        .foregroundColor(.secondary)
        .padding(.vertical, 4)
        .fixedSize(horizontal: false, vertical: true)
        .lineLimit(nil)
        .padding(.trailing, 80)

      if isDisabled && errorMessage != nil {
        Text(errorMessage!)
          .font(.caption)
          .foregroundColor(.red)
      }
    }
  }
}

#Preview {
  VStack(alignment: .leading, spacing: 16) {
    CustomToggle(
      title: "Enable Feature",
      description: "This is a description of what this toggle does.",
      isOn: .constant(true)
    )

    CustomToggle(
      title: "Enable Feature",
      description:
        "This is a toggle with a really long description so that it doesn't look so weird and super strange",
      isOn: .constant(false)
    )

    CustomToggle(
      title: "Disabled Toggle",
      description: "This toggle is currently disabled.",
      isOn: .constant(false),
      isDisabled: true
    )
  }
  .padding()
}
