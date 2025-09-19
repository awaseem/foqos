import SwiftUI

struct CardBackground: View {
  var isActive: Bool = false
  var customColor: Color? = nil

  // Metaball blob specs (randomized once for organic motion)
  @State private var blobs: [BlobSpec] = Self.makeBlobs(count: 5)

  // Exposed colors for easy tweaking
  public static var activeBlobColor: Color = .green.opacity(0.5)
  public static var inactiveBlobColor: Color = .blue

  // Default color if no custom color is provided (kept for API compatibility)
  @available(*, deprecated, message: "Use CardBackground.inactiveBlobColor instead")
  private let defaultColor: Color = CardBackground.inactiveBlobColor

  // No position calculations needed for the simplified design

  // Select a color based on custom color or active state
  private var cardColor: Color {
    if isActive {
      return CardBackground.activeBlobColor
    }

    return customColor ?? CardBackground.inactiveBlobColor
  }

  var body: some View {
    RoundedRectangle(cornerRadius: 24)
      .fill(Color(UIColor.systemBackground))
      .overlay(
        GeometryReader { geometry in
          ZStack {
            if isActive {
              // Gooey metaball lava-lamp effect
              TimelineView(.animation) { timeline in
                let t = timeline.date.timeIntervalSinceReferenceDate

                Rectangle()
                  .fill(cardColor)
                  .mask(MetaballMaskView(blobs: blobs, t: t))
                  .opacity(0.9)
              }
              .allowsHitTesting(false)
              .drawingGroup()
            } else {
              // Default single circle for inactive state
              Circle()
                .fill(cardColor.opacity(0.5))
                .frame(width: geometry.size.width * 0.5, height: geometry.size.width * 0.5)
                .position(
                  x: geometry.size.width * 0.9,
                  y: geometry.size.height / 2
                )
                .blur(radius: 15)
                .allowsHitTesting(false)
            }
          }
        }
      )
      .overlay(
        RoundedRectangle(cornerRadius: 24)
          .stroke(Color.gray.opacity(0.3), lineWidth: 1)
      )
      .background(
        RoundedRectangle(cornerRadius: 24)
          .fill(.ultraThinMaterial.opacity(0.7))
      )
      .clipShape(RoundedRectangle(cornerRadius: 24))
    // TimelineView drives animation; no imperative animation triggers needed
  }

  // Utility method to get the card color for other components
  public func getCardColor() -> Color {
    return cardColor
  }

  // MARK: - Metaball Specs
  private struct BlobSpec: Identifiable {
    let id = UUID()
    let speed: Double
    let baseSizeFactor: CGFloat
    let sizeJitter: CGFloat
    let xAmplitudeFactor: CGFloat
    let yAmplitudeFactor: CGFloat
    let phaseX: Double
    let phaseY: Double

    func position(at t: TimeInterval, in size: CGSize) -> CGPoint {
      let cx = size.width * 0.5
      let cy = size.height * 0.5
      let xAmp = size.width * 0.35 * xAmplitudeFactor
      let yAmp = size.height * 0.35 * yAmplitudeFactor

      let x = cx + CGFloat(cos(t * speed + phaseX)) * xAmp
      let y = cy + CGFloat(sin(t * speed * 0.9 + phaseY)) * yAmp
      return CGPoint(x: x, y: y)
    }

    func size(at t: TimeInterval, in size: CGSize) -> CGSize {
      let base = min(size.width, size.height) * baseSizeFactor
      let pulse = 1.0 + sizeJitter * CGFloat(sin(t * speed * 0.6 + (phaseX + phaseY) * 0.5))
      let w = base * pulse
      return CGSize(width: w, height: w)
    }
  }

  private static func makeBlobs(count: Int) -> [BlobSpec] {
    var generator = SystemRandomNumberGenerator()
    return (0..<max(3, count)).map { _ in
      let speed = Double.random(in: 0.18...0.32, using: &generator)
      let baseSize = CGFloat.random(in: 0.30...0.55, using: &generator)
      let jitter = CGFloat.random(in: 0.04...0.10, using: &generator)
      let xAmp = CGFloat.random(in: 0.75...1.15, using: &generator)
      let yAmp = CGFloat.random(in: 0.75...1.15, using: &generator)
      let phaseX = Double.random(in: 0...(2 * .pi), using: &generator)
      let phaseY = Double.random(in: 0...(2 * .pi), using: &generator)
      return BlobSpec(
        speed: speed,
        baseSizeFactor: baseSize,
        sizeJitter: jitter,
        xAmplitudeFactor: xAmp,
        yAmplitudeFactor: yAmp,
        phaseX: phaseX,
        phaseY: phaseY
      )
    }
  }

  // MARK: - Mask helper view (re-usable metaball mask)
  private struct MetaballMaskView: View {
    let blobs: [BlobSpec]
    let t: TimeInterval

    var body: some View {
      Canvas { context, size in
        context.addFilter(.alphaThreshold(min: 0.45))
        context.addFilter(.blur(radius: 28))

        context.drawLayer { layer in
          for blob in blobs {
            let p = blob.position(at: t, in: size)
            let s = blob.size(at: t, in: size)
            let rect = CGRect(
              x: p.x - s.width / 2, y: p.y - s.height / 2, width: s.width,
              height: s.height)
            layer.fill(Path(ellipseIn: rect), with: .color(.white))
          }
        }
      }
    }
  }
}

#Preview {
  ZStack {
    Color(.systemGroupedBackground).ignoresSafeArea()

    VStack(spacing: 16) {
      CardBackground(customColor: .blue)
        .frame(height: 170)
        .padding(.horizontal)

      CardBackground(customColor: .red)
        .frame(height: 170)
        .padding(.horizontal)

      CardBackground(customColor: .purple)
        .frame(height: 170)
        .padding(.horizontal)
    }
  }
}
