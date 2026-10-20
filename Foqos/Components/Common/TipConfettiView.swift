import SwiftUI

struct TipConfettiView: View {
  let startDate: Date

  @State private var pieces = (0..<110).map { _ in Piece() }

  var body: some View {
    TimelineView(.animation) { timeline in
      Canvas { context, size in
        let elapsed = timeline.date.timeIntervalSince(startDate)

        for piece in pieces {
          let age = elapsed - piece.delay
          let progress = age / piece.duration
          guard progress >= 0, progress <= 1 else { continue }

          let x = piece.position * size.width + sin(age * piece.sway) * 28
          let y = -30 + (size.height + 60) * progress
          var drawing = context
          drawing.opacity = min(1, (1 - progress) * 6)
          drawing.translateBy(x: x, y: y)
          drawing.rotate(by: .degrees(age * piece.spin))
          drawing.scaleBy(x: max(0.2, abs(cos(age * 4))), y: 1)
          drawing.fill(
            Path(
              roundedRect: CGRect(x: -4, y: -6, width: 8, height: 12),
              cornerRadius: piece.isRound ? 4 : 1),
            with: .color(piece.color))
        }
      }
    }
    .clipped()
  }

  private struct Piece {
    let position = Double.random(in: 0...1)
    let delay = Double.random(in: 0...1.2)
    let duration = Double.random(in: 2.5...3.6)
    let sway = Double.random(in: 1.5...4)
    let spin = Double.random(in: -240...240)
    let isRound = Bool.random()
    let color = [Color.pink, .yellow, .mint, .cyan, .purple, .orange].randomElement()!
  }
}

#Preview {
  TipConfettiView(startDate: Date())
    .allowsHitTesting(false)
}
