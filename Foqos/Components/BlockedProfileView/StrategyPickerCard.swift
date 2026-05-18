import SwiftUI

struct StrategyPickerCard: View {
  @EnvironmentObject var themeManager: ThemeManager

  let strategy: BlockingStrategy
  let isSelected: Bool
  let onTap: () -> Void

  var body: some View {
    Button(action: onTap) {
      VStack(spacing: 8) {
        ZStack(alignment: .topTrailing) {
          BlockingStrategyIconImage(strategy: strategy)
            .font(.system(size: 28))
            .foregroundStyle(strategy.color)
            .frame(width: 54, height: 54)
            .background {
              if strategy.iconAssetName == nil {
                Circle()
                  .fill(strategy.color.opacity(0.14))
              }
            }

          if isSelected {
            Image(systemName: "checkmark.circle.fill")
              .font(.system(size: 17))
              .foregroundStyle(themeManager.themeColor)
              .background(Circle().fill(Color(.systemBackground)))
              .offset(x: 4, y: -4)
          }
        }
        .frame(width: 60, height: 60)

        Text(strategy.name)
          .font(.subheadline.weight(.semibold))
          .foregroundStyle(.primary)
          .multilineTextAlignment(.center)
          .lineLimit(2)
          .minimumScaleFactor(0.82)
          .frame(height: 38, alignment: .top)
      }
      .frame(width: 108, height: 118)
      .padding(10)
      .background(Color(.secondarySystemGroupedBackground))
      .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
      .overlay {
        RoundedRectangle(cornerRadius: 14, style: .continuous)
          .strokeBorder(
            isSelected ? themeManager.themeColor : Color(.separator).opacity(0.45),
            lineWidth: isSelected ? 2 : 1
          )
      }
    }
    .buttonStyle(.plain)
    .accessibilityLabel(strategy.name)
    .accessibilityHint("Shows details for this blocking strategy")
  }
}
