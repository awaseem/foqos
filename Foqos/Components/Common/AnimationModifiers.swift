import SwiftUI

struct FadeInSlideAnimation: ViewModifier {
    let delay: Double
    let slideOffset: CGFloat
    let duration: Double

    @State private var opacity: Double = 0.0
    @State private var offset: CGFloat

    init(delay: Double, slideOffset: CGFloat = 30, duration: Double = 0.4) {
        self.delay = delay
        self.slideOffset = slideOffset
        self.duration = duration
        self._offset = State(initialValue: slideOffset)
    }

    func body(content: Content) -> some View {
        content
            .opacity(opacity)
            .offset(y: offset)
            .onAppear {
                withAnimation(
                    .spring(
                        response: duration,
                        dampingFraction: 0.6,
                        blendDuration: 0
                    ).delay(delay)
                ) {
                    opacity = 1.0
                    offset = 0
                }
            }
    }
}

extension View {
    func fadeInSlide(delay: Double, slideOffset: CGFloat = 30, duration: Double = 0.4) -> some View {
        modifier(FadeInSlideAnimation(delay: delay, slideOffset: slideOffset, duration: duration))
    }
}
