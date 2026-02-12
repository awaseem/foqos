import SwiftUI

struct BlockedProfileStrategySelector: View {
  @EnvironmentObject var themeManager: ThemeManager

  let selectedStrategy: BlockingStrategy?
  var buttonAction: () -> Void
  var disabled: Bool = false
  var disabledText: String?

  private var buttonText: String {
    return "Select Blocking Strategy"
  }

  var body: some View {
    Button(action: buttonAction) {
      HStack {
        Text(buttonText)
          .foregroundStyle(themeManager.themeColor)
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
    } else if let strategy = selectedStrategy {
      HStack(spacing: 8) {
        Image(systemName: strategy.iconType)
          .foregroundColor(.gray)
        Text(strategy.name)
          .font(.footnote)
          .foregroundStyle(.gray)
      }
      .padding(.top, 4)
    } else {
      Text("No strategy selected")
        .foregroundStyle(.gray)
        .font(.footnote)
        .padding(.top, 4)
    }
  }
}

#Preview {
  VStack(spacing: 20) {
    BlockedProfileStrategySelector(
      selectedStrategy: NFCBlockingStrategy(),
      buttonAction: {}
    )

    BlockedProfileStrategySelector(
      selectedStrategy: nil,
      buttonAction: {}
    )

    BlockedProfileStrategySelector(
      selectedStrategy: ManualBlockingStrategy(),
      buttonAction: {},
      disabled: true,
      disabledText: "Disable the current session to edit strategy"
    )
  }
  .padding()
}
