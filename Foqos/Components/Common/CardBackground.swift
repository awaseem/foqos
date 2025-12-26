import SwiftUI

struct CardBackground: View {
  @EnvironmentObject var themeManager: ThemeManager
  @Environment(\.accessibilityReduceMotion) var reduceMotion

  var isActive: Bool = false
  var customColor: Color? = nil

  // Metaball blob specs (randomized once for organic motion)
  @State private var blobs: [BlobSpec] = Self.makeBlobs(count: 5)

  // No position calculations needed for the simplified design

  // Select a color based on custom color or active state
  private var cardColor: Color {
    if isActive {
      return themeManager.themeColor.opacity(0.5)
    }

    return customColor ?? .blue
  }

  var body: some View {
    RoundedRectangle(cornerRadius: CornerRadius.xl)
      .fill(Color(UIColor.systemBackground))
      .overlay(
        GeometryReader { geometry in
          ZStack {
            if isActive {
              if reduceMotion {
                // Static gradient for reduced motion preference
                StaticActiveBackground(baseColor: cardColor, size: geometry.size)
              } else {
                // Animations should ONLY play when the profile is active.
                TimelineView(.animation) { timeline in
                  let t = timeline.date.timeIntervalSinceReferenceDate
                  ActiveAuroraBackground(
                    baseColor: cardColor,
                    blobs: blobs,
                    t: t,
                    size: geometry.size
                  )
                }
                .allowsHitTesting(false)
                .drawingGroup()
              }
            } else {
              // Inactive profiles get a consistent, calm, non-animated accent.
              SpotlightBlob(color: cardColor, in: geometry.size)
            }
          }
        }
      )
      .overlay(
        RoundedRectangle(cornerRadius: CornerRadius.xl)
          .stroke(Color.gray.opacity(0.3), lineWidth: 1)
      )
      .background(
        RoundedRectangle(cornerRadius: CornerRadius.xl)
          .fill(.ultraThinMaterial.opacity(0.7))
      )
      .clipShape(RoundedRectangle(cornerRadius: CornerRadius.xl))
    // TimelineView drives animation; no imperative animation triggers needed
  }

  // Utility method to get the card color for other components
  public func getCardColor() -> Color {
    return cardColor
  }

  // MARK: - Styles
  private struct ActiveAuroraBackground: View {
    let baseColor: Color
    let blobs: [BlobSpec]
    let t: TimeInterval
    let size: CGSize

    var body: some View {
      ZStack {
        // Aurora is the default active animation.
        // We keep the same gooey metaball mask so it feels as delightful as the original lava lamp.
        Rectangle()
          .fill(fillGradient)
          .mask(MetaballMaskView(blobs: blobs, t: t))
          .opacity(0.82)

        AuroraOverlays(baseColor: baseColor, t: t, size: size)
          .mask(MetaballMaskView(blobs: blobs, t: t))
          .blendMode(.plusLighter)
          .opacity(0.95)
      }
    }

    private var fillGradient: LinearGradient {
      let a = colorShift(baseColor, hue: 0.06 * Foundation.sin(t * 0.12), sat: 1.10, bri: 1.12)
      let b = colorShift(
        baseColor, hue: 0.10 * Foundation.cos(t * 0.10 + 1.4), sat: 1.18, bri: 1.00)
      let c = colorShift(
        baseColor, hue: -0.08 * Foundation.sin(t * 0.14 + 2.2), sat: 1.00, bri: 0.95)

      // Slowly drifting gradient direction feels organic.
      let sx = 0.15 + 0.70 * ((Foundation.sin(t * 0.07) + 1) / 2)
      let sy = 0.20 + 0.60 * ((Foundation.cos(t * 0.06 + 1.1) + 1) / 2)
      let ex = 1.0 - sx
      let ey = 1.0 - sy

      return LinearGradient(
        colors: [a.opacity(0.95), b.opacity(0.92), c.opacity(0.88)],
        startPoint: UnitPoint(x: sx, y: sy),
        endPoint: UnitPoint(x: ex, y: ey)
      )
    }
  }

  private struct AuroraOverlays: View {
    let baseColor: Color
    let t: TimeInterval
    let size: CGSize

    var body: some View {
      let r = min(size.width, size.height)
      let p1 = CGPoint(
        x: size.width * (0.35 + 0.18 * CGFloat(Foundation.cos(t * 0.22))),
        y: size.height * (0.35 + 0.22 * CGFloat(Foundation.sin(t * 0.18 + 1.1)))
      )
      let p2 = CGPoint(
        x: size.width * (0.72 + 0.16 * CGFloat(Foundation.cos(t * 0.19 + 2.0))),
        y: size.height * (0.55 + 0.18 * CGFloat(Foundation.sin(t * 0.24 + 0.7)))
      )
      let p3 = CGPoint(
        x: size.width * (0.50 + 0.20 * CGFloat(Foundation.cos(t * 0.16 + 4.2))),
        y: size.height * (0.80 + 0.14 * CGFloat(Foundation.sin(t * 0.20 + 2.8)))
      )

      ZStack {
        RadialGradient(
          colors: [
            colorShift(baseColor, hue: 0.14, sat: 1.25, bri: 1.15).opacity(0.55),
            .clear,
          ],
          center: .center,
          startRadius: 0,
          endRadius: r * 0.70
        )
        .frame(width: r * 1.6, height: r * 1.6)
        .position(p1)
        .blur(radius: 26)

        RadialGradient(
          colors: [
            colorShift(baseColor, hue: -0.10, sat: 1.15, bri: 1.05).opacity(0.45),
            .clear,
          ],
          center: .center,
          startRadius: 0,
          endRadius: r * 0.62
        )
        .frame(width: r * 1.45, height: r * 1.45)
        .position(p2)
        .blur(radius: 28)

        RadialGradient(
          colors: [
            colorShift(baseColor, hue: 0.04, sat: 1.05, bri: 1.25).opacity(0.35),
            .clear,
          ],
          center: .center,
          startRadius: 0,
          endRadius: r * 0.75
        )
        .frame(width: r * 1.75, height: r * 1.75)
        .position(p3)
        .blur(radius: 30)
      }
    }
  }

  private struct SpotlightBlob: View {
    let color: Color
    let size: CGSize

    init(color: Color, in size: CGSize) {
      self.color = color
      self.size = size
    }

    var body: some View {
      Circle()
        .fill(color.opacity(0.5))
        .frame(width: size.width * 0.5, height: size.width * 0.5)
        .position(
          x: size.width * 0.9,
          y: size.height / 2
        )
        .blur(radius: 15)
        .allowsHitTesting(false)
    }
  }

  // MARK: - Static background for reduced motion
  private struct StaticActiveBackground: View {
    let baseColor: Color
    let size: CGSize

    var body: some View {
      LinearGradient(
        colors: [
          baseColor.opacity(0.6),
          baseColor.opacity(0.3)
        ],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
      )
      .allowsHitTesting(false)
    }
  }

  // MARK: - Color helpers (local, to keep everything on-theme)
  private static func colorShift(
    _ color: Color,
    hue: Double,
    sat: Double,
    bri: Double
  ) -> Color {
    let ui = UIColor(color)
    var h: CGFloat = 0
    var s: CGFloat = 0
    var b: CGFloat = 0
    var a: CGFloat = 0

    if ui.getHue(&h, saturation: &s, brightness: &b, alpha: &a) {
      let nh = (h + CGFloat(hue)).truncatingRemainder(dividingBy: 1.0)
      let ns = max(0, min(1, s * CGFloat(sat)))
      let nb = max(0, min(1, b * CGFloat(bri)))
      return Color(UIColor(hue: nh < 0 ? nh + 1.0 : nh, saturation: ns, brightness: nb, alpha: a))
    }

    // Fallback: if we can't extract HSB (rare), just return original.
    return color
  }

  private func colorShift(_ color: Color, hue: Double, sat: Double, bri: Double) -> Color {
    Self.colorShift(color, hue: hue, sat: sat, bri: bri)
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
      CardBackground(isActive: true, customColor: .blue)
        .frame(height: 170)
        .padding(.horizontal)
    }
  }
  .environmentObject(ThemeManager.shared)
}
