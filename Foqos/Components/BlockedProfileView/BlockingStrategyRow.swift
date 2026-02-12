import SwiftUI

struct StrategyRow: View {
  @EnvironmentObject var themeManager: ThemeManager

  enum AccessoryStyle {
    case selection
    case chevron
    case none
  }

  let strategy: BlockingStrategy
  let isSelected: Bool
  let onTap: () -> Void
  var accessoryStyle: AccessoryStyle = .selection

  private func backgroundColor(for tag: BlockingStrategyTag) -> Color {
    if tag == .beta {
      return .orange.opacity(0.16)
    }

    return .secondary.opacity(0.14)
  }

  private func foregroundColor(for tag: BlockingStrategyTag) -> Color {
    if tag == .beta {
      return .orange
    }

    return .secondary
  }

  var body: some View {
    Button(action: onTap) {
      VStack(alignment: .leading, spacing: 8) {
        HStack(alignment: .center, spacing: 8) {
          Image(systemName: strategy.iconType)
            .font(.subheadline)
            .foregroundStyle(.secondary)
            .frame(width: 24, height: 24)
            .background(.secondary.opacity(0.12))
            .clipShape(Circle())

          Text(strategy.name)
            .font(.headline)
            .foregroundStyle(
              accessoryStyle == .selection && isSelected ? themeManager.themeColor : .primary)

          Spacer(minLength: 8)

          if accessoryStyle == .selection {
            Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
              .foregroundStyle(isSelected ? themeManager.themeColor : .secondary)
              .font(.system(size: 20))
          } else if accessoryStyle == .chevron {
            Image(systemName: "chevron.right")
              .foregroundStyle(.secondary)
              .font(.system(size: 14, weight: .semibold))
          }
        }

        Text(strategy.description)
          .font(.subheadline)
          .foregroundStyle(.secondary)
          .lineLimit(2)

        if !strategy.tags.isEmpty {
          HStack(spacing: 6) {
            ForEach(strategy.tags, id: \.self) { tag in
              Text(tag.title)
                .font(.caption2)
                .fontWeight(tag == .beta ? .semibold : .medium)
                .foregroundStyle(foregroundColor(for: tag))
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .background(backgroundColor(for: tag))
                .clipShape(Capsule())
            }
          }
        }
      }
      .padding(.vertical, 4)
    }
    .buttonStyle(PlainButtonStyle())
  }
}

#Preview {
  StrategyRow(strategy: NFCBlockingStrategy(), isSelected: true, onTap: {})
}
