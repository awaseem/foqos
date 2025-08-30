import SwiftUI

// A wrapper that places a tappable frosted-glass layer above its content.
// Users must tap the glass three times to shatter it, revealing and enabling
// the underlying content (e.g., a button) to be interactive.
struct BreakGlassButton<Content: View>: View {
  // Number of taps required before the glass shatters
  var tapsToShatter: Int = 3

  // Optional callback when the glass finishes shattering
  var onUnlocked: (() -> Void)? = nil

  // Content to reveal once shattered (typically a Button or your own view)
  let content: () -> Content

  init(
    tapsToShatter: Int = 3,
    onUnlocked: (() -> Void)? = nil,
    @ViewBuilder content: @escaping () -> Content
  ) {
    self.tapsToShatter = tapsToShatter
    self.onUnlocked = onUnlocked
    self.content = content
  }

  @State private var tapLocations: [CGPoint] = []
  @State private var currentTapCount: Int = 0
  @State private var isShattering: Bool = false
  @State private var isShattered: Bool = false
  @State private var overlayScale: CGFloat = 1.0
  @State private var overlayOpacity: Double = 1.0
  @State private var overlayRotation: Angle = .degrees(0)
  @Environment(\.colorScheme) private var colorScheme: ColorScheme

  var body: some View {
    ZStack {
      // Underlying content. Disabled until glass shatters.
      content()
        .allowsHitTesting(isShattered)
        .opacity(isShattered ? 1 : 0.9)

      if !isShattered {
        GeometryReader { geometry in
          GlassOverlay(
            size: geometry.size,
            cracks: tapLocations,
            progress: Double(currentTapCount) / Double(max(1, tapsToShatter)),
            isDark: colorScheme == .dark
          )
          .scaleEffect(overlayScale)
          .rotationEffect(overlayRotation)
          .opacity(overlayOpacity)
          .contentShape(RoundedRectangle(cornerRadius: 16))
          .onAppear {
            overlayScale = 1.0
            overlayOpacity = 1.0
            overlayRotation = .degrees(0)
          }
          .gesture(
            DragGesture(minimumDistance: 0)
              .onEnded { value in
                guard !isShattering else { return }

                // Treat as a tap at the released location
                let p = value.location
                let clamped = CGPoint(
                  x: max(0, min(geometry.size.width, p.x)),
                  y: max(0, min(geometry.size.height, p.y))
                )
                withAnimation(.spring(response: 0.35, dampingFraction: 0.8)) {
                  tapLocations.append(clamped)
                  currentTapCount = min(currentTapCount + 1, tapsToShatter)
                }

                triggerImpactHaptic()

                if currentTapCount + 0 >= tapsToShatter {
                  triggerShatter()
                }
              }
          )
          .allowsHitTesting(true)
        }
        .clipShape(RoundedRectangle(cornerRadius: 16))
      }
    }
  }

  private func triggerShatter() {
    guard !isShattering && !isShattered else { return }
    isShattering = true
    triggerSuccessHaptic()

    // Shatter animation: quick pop + fade + slight spin
    withAnimation(.interpolatingSpring(stiffness: 180, damping: 12)) {
      overlayScale = 1.06
      overlayRotation = .degrees(Double.random(in: -6...6))
    }
    withAnimation(.easeIn(duration: 0.18).delay(0.02)) {
      overlayOpacity = 0
      overlayScale = 1.12
    }

    // Finalize state after animation completes
    DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
      isShattered = true
      isShattering = false
      onUnlocked?()
    }
  }
}

// MARK: - Overlay visuals

private struct GlassOverlay: View {
  var size: CGSize
  var cracks: [CGPoint]
  var progress: Double  // 0...1 based on taps
  var isDark: Bool

  private var borderColor: Color {
    isDark ? Color.white.opacity(0.35) : Color.black.opacity(0.2)
  }

  private var specularScale: Double {
    isDark ? 1.0 : 1.25
  }

  private var materialStyle: Material {
    isDark ? .ultraThinMaterial : .thinMaterial
  }

  private var shadowColor: Color {
    isDark ? Color.black.opacity(0.08) : Color.black.opacity(0.14)
  }

  private var borderLineWidth: CGFloat {
    isDark ? 1 : 1.2
  }

  var body: some View {
    ZStack {
      RoundedRectangle(cornerRadius: 16)
        .fill(materialStyle)
        .overlay(
          // Soft border
          RoundedRectangle(cornerRadius: 16)
            .stroke(borderColor, lineWidth: borderLineWidth)
        )
        // Subtle inner highlight for light mode to increase edge definition
        .overlay(
          RoundedRectangle(cornerRadius: 16)
            .stroke(Color.white.opacity(isDark ? 0.0 : 0.18), lineWidth: 0.6)
            .blendMode(.plusLighter)
        )
        .shadow(color: shadowColor, radius: isDark ? 8 : 10, x: 0, y: isDark ? 4 : 6)

      // Subtle specular highlight sweep tied to progress
      RoundedRectangle(cornerRadius: 16)
        .fill(
          LinearGradient(
            colors: [
              Color.white.opacity(0.08 * (1.0 - progress) * specularScale),
              Color.white.opacity(0.24 * (1.0 - progress) * specularScale),
              Color.white.opacity(0.08 * (1.0 - progress) * specularScale),
            ],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
          )
        )
        .blendMode(.plusLighter)

      // Cracks
      CrackCanvas(size: size, origins: cracks, isDark: isDark)
        .allowsHitTesting(false)
        .opacity(min(1, progress * 1.2))
    }
  }
}

private struct CrackCanvas: View {
  var size: CGSize
  var origins: [CGPoint]
  var isDark: Bool

  var body: some View {
    Canvas { context, canvasSize in
      context.blendMode = .normal

      // Draw each crack bundle
      for (index, origin) in origins.enumerated() {
        let seed = UInt64(index + 1)
        var generator = SeededRandomNumberGenerator(seed: seed)
        let rayCount = Int.random(in: 8...13, using: &generator)

        for _ in 0..<rayCount {
          let baseAngle = Double.random(in: 0..<(2 * .pi), using: &generator)
          let minDimension = Double(min(size.width, size.height))
          let minLen = minDimension * 0.12
          let maxLen = minDimension * 0.35
          let length = Double.random(in: minLen...maxLen, using: &generator)
          let jitter = Double.random(in: -0.25...0.25, using: &generator)
          let segments = Int.random(in: 3...5, using: &generator)

          var points: [CGPoint] = [origin]
          for s in 1...segments {
            let t = Double(s) / Double(segments)
            let angle = baseAngle + jitter * sin(t * 3.1415 * 2)
            let radius = length * t
            let x = origin.x + CGFloat(cos(angle) * radius)
            let y = origin.y + CGFloat(sin(angle) * radius)
            points.append(CGPoint(x: x, y: y))
          }

          var path = Path()
          path.move(to: points.first ?? origin)
          for i in 1..<points.count {
            let p0 = points[i - 1]
            let p1 = points[i]
            // Slight jaggedness using quad curves
            let mid = CGPoint(
              x: (p0.x + p1.x) / 2 + CGFloat(Double.random(in: -2...2, using: &generator)),
              y: (p0.y + p1.y) / 2 + CGFloat(Double.random(in: -2...2, using: &generator))
            )
            path.addQuadCurve(to: p1, control: mid)
          }

          // Crack color adapts to scheme: brighter in dark mode, slightly darker in light mode
          let strokeColor: Color = isDark ? Color.white.opacity(0.9) : Color.black.opacity(0.6)
          context.stroke(
            path,
            with: .color(strokeColor),
            style: StrokeStyle(lineWidth: 0.8, lineCap: .round, lineJoin: .round)
          )

          // Subtle inner shadow to enhance depth
          let shadowPath = path
          context.stroke(
            shadowPath,
            with: .color(isDark ? Color.black.opacity(0.35) : Color.black.opacity(0.18)),
            style: StrokeStyle(lineWidth: 0.4)
          )
        }
      }
    }
  }
}

// Simple seeded RNG for deterministic crack shapes per tap index
private struct SeededRandomNumberGenerator: RandomNumberGenerator {
  private var state: UInt64
  init(seed: UInt64) { self.state = seed == 0 ? 0x1234_5678 : seed }
  mutating func next() -> UInt64 {
    // Xorshift64*
    var x = state
    x ^= x << 13
    x ^= x >> 7
    x ^= x << 17
    state = x
    return x
  }
}

// MARK: - Convenience wrapper using existing GlassButton styling

// Removed convenience initializer that referenced GlassButton to avoid cross-file lint failures.

// MARK: - Haptics helpers
private func triggerImpactHaptic() {
  #if canImport(UIKit)
    UIImpactFeedbackGenerator(style: .light).impactOccurred()
  #endif
}

private func triggerSuccessHaptic() {
  #if canImport(UIKit)
    UINotificationFeedbackGenerator().notificationOccurred(.success)
  #endif
}

#Preview {
  VStack(spacing: 20) {
    BreakGlassButton(
      tapsToShatter: 3,
      onUnlocked: {
        print("Unlocked 1")
      }
    ) {
      // Your own button/content
      Button(action: { print("Primary action") }) {
        HStack(spacing: 8) {
          Image(systemName: "lock.open")
          Text("Protected Action")
        }
        .padding(.vertical, 12)
        .padding(.horizontal, 20)
        .background(
          RoundedRectangle(cornerRadius: 16)
            .fill(.thinMaterial)
            .overlay(
              RoundedRectangle(cornerRadius: 16)
                .stroke(Color.green.opacity(0.25), lineWidth: 1)
            )
        )
      }
      .buttonStyle(.plain)
    }
    .frame(height: 56)

    BreakGlassButton(tapsToShatter: 3, onUnlocked: { print("Glass shattered: ready") }) {
      Button("Begin Session") { print("Begin Session tapped") }
        .padding(.vertical, 12)
        .padding(.horizontal, 20)
        .background(
          RoundedRectangle(cornerRadius: 16)
            .fill(.thinMaterial)
            .overlay(
              RoundedRectangle(cornerRadius: 16)
                .stroke(Color.blue.opacity(0.25), lineWidth: 1)
            )
        )
    }
    .frame(height: 56)
  }
  .padding()
  .background(Color(.systemGroupedBackground))
}
