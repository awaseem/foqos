import SwiftUI

struct ActiveSessionAnimationSettings: Equatable {
  static let defaultValue = ActiveSessionAnimationSettings(
    petalCount: 8,
    visibility: 1.15,
    petalWidth: 0.9,
    petalLength: 1.08,
    bloomScale: 1,
    centerOpening: 44,
    breathingDuration: 18
  )

  var petalCount: Double
  var visibility: Double
  var petalWidth: Double
  var petalLength: Double
  var bloomScale: Double
  var centerOpening: Double
  var breathingDuration: Double
}

struct ActiveSessionPetalView: View {
  @Environment(\.accessibilityReduceMotion) private var accessibilityReduceMotion

  let color: Color
  let settings: ActiveSessionAnimationSettings
  var timerTick: Int? = nil

  private var petalCount: Int {
    max(Int(settings.petalCount.rounded()), 1)
  }

  var body: some View {
    GeometryReader { geometry in
      let radiusX = max(geometry.size.width / 2 - 18, 0) * CGFloat(settings.bloomScale)
      let radiusY = max(geometry.size.height / 2 - 18, 0) * CGFloat(settings.bloomScale)

      ZStack {
        ForEach(0..<petalCount, id: \.self) { index in
          let petalAngle =
            Double(index) / Double(petalCount) * 2 * Double.pi - Double.pi / 2
          let breathing = breathingProgress(for: index, at: timerTick)
          let horizontalRadius = CGFloat(cos(petalAngle)) * radiusX
          let verticalRadius = CGFloat(sin(petalAngle)) * radiusY
          let baseLength = hypot(horizontalRadius, verticalRadius)
          let centerOpening = CGFloat(settings.centerOpening)
          let restingLength = max(baseLength - centerOpening, 1)
          let petalLength =
            restingLength * CGFloat(settings.petalLength) * (0.94 + 0.12 * breathing)
          let petalWidth = (52 + 8 * breathing) * CGFloat(settings.petalWidth)
          let petalCenterRadius = centerOpening + petalLength / 2

          ActiveSessionRosePetalShape()
            .fill(
              LinearGradient(
                stops: [
                  .init(color: color.opacity(0.88), location: 0),
                  .init(color: color.opacity(0.54), location: 0.5),
                  .init(color: color.opacity(0.1), location: 1),
                ],
                startPoint: .top,
                endPoint: .bottom
              )
            )
            .frame(
              width: petalWidth,
              height: petalLength
            )
            .rotationEffect(.radians(petalAngle + Double.pi / 2))
            .position(
              x: geometry.size.width / 2
                + CGFloat(cos(petalAngle)) * petalCenterRadius,
              y: geometry.size.height / 2
                + CGFloat(sin(petalAngle)) * petalCenterRadius
            )
            .opacity(
              min((0.48 + 0.18 * Double(breathing)) * settings.visibility, 0.82)
            )
            .blur(radius: 0.8)
            .zIndex(Double(breathing))
        }
      }
      .animation(accessibilityReduceMotion || timerTick == nil ? nil : .default, value: timerTick)
    }
    .allowsHitTesting(false)
    .accessibilityHidden(true)
  }

  private func breathingProgress(for index: Int, at timerTick: Int?) -> CGFloat {
    guard let timerTick, !accessibilityReduceMotion else { return 0 }

    let cycleDuration = max(Int(settings.breathingDuration.rounded()), 1)
    let cycleTick = timerTick % cycleDuration
    let cycleProgress = Double(cycleTick) / Double(cycleDuration)
    let petalProgress = cycleProgress * Double(petalCount)
    let activePetal = min(Int(petalProgress), petalCount - 1)

    guard index == activePetal else { return 0 }

    let localProgress = petalProgress - Double(activePetal)
    return CGFloat((1 - cos(localProgress * 2 * Double.pi)) / 2)
  }
}

private struct ActiveSessionRosePetalShape: Shape {
  func path(in rect: CGRect) -> Path {
    var path = Path()
    path.move(to: CGPoint(x: rect.midX, y: rect.maxY))
    path.addCurve(
      to: CGPoint(x: rect.minX + rect.width * 0.08, y: rect.minY + rect.height * 0.38),
      control1: CGPoint(x: rect.minX + rect.width * 0.25, y: rect.minY + rect.height * 0.86),
      control2: CGPoint(x: rect.minX + rect.width * 0.02, y: rect.minY + rect.height * 0.65)
    )
    path.addCurve(
      to: CGPoint(x: rect.midX, y: rect.minY + rect.height * 0.05),
      control1: CGPoint(x: rect.minX + rect.width * 0.05, y: rect.minY + rect.height * 0.16),
      control2: CGPoint(x: rect.minX + rect.width * 0.3, y: rect.minY + rect.height * 0.02)
    )
    path.addCurve(
      to: CGPoint(x: rect.maxX - rect.width * 0.08, y: rect.minY + rect.height * 0.38),
      control1: CGPoint(x: rect.maxX - rect.width * 0.3, y: rect.minY + rect.height * 0.02),
      control2: CGPoint(x: rect.maxX - rect.width * 0.05, y: rect.minY + rect.height * 0.16)
    )
    path.addCurve(
      to: CGPoint(x: rect.midX, y: rect.maxY),
      control1: CGPoint(x: rect.maxX - rect.width * 0.02, y: rect.minY + rect.height * 0.65),
      control2: CGPoint(x: rect.maxX - rect.width * 0.25, y: rect.minY + rect.height * 0.86)
    )
    path.closeSubpath()
    return path
  }
}

#Preview("Resting petals") {
  ActiveSessionPetalView(color: .purple, settings: .defaultValue)
    .frame(width: 360, height: 300)
    .background(.black)
}
