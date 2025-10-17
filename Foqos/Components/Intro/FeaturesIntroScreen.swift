import SwiftUI

struct FeaturesIntroScreen: View {
  @State private var selectedFeature: Int = 0
  @State private var showContent: Bool = false

  let features = [
    Feature(
      icon: "hand.raised.fill",
      title: "Block Distracting Apps",
      description:
        "Select which apps you want to block during focus time. Stay in control of your digital wellbeing.",
      color: Color.purple
    ),
    Feature(
      icon: "clock.badge.checkmark.fill",
      title: "Flexible Scheduling",
      description:
        "Set up schedules that work for you. Create routines that help you maintain focus when you need it most.",
      color: Color.blue
    ),
    Feature(
      icon: "chart.line.uptrend.xyaxis",
      title: "Track Your Progress",
      description:
        "Monitor your focus sessions and see your improvement over time. Build better habits with data-driven insights.",
      color: Color.green
    ),
  ]

  var body: some View {
    VStack(spacing: 0) {
      // Header
      VStack(spacing: 8) {
        Text("Powerful Features")
          .font(.system(size: 34, weight: .bold))
          .foregroundColor(.primary)
          .opacity(showContent ? 1 : 0)
          .offset(y: showContent ? 0 : -20)

        Text("Everything you need to stay focused")
          .font(.system(size: 16))
          .foregroundColor(.secondary)
          .opacity(showContent ? 1 : 0)
          .offset(y: showContent ? 0 : -20)
      }
      .padding(.top, 40)
      .padding(.bottom, 32)

      // Feature cards with tab selector
      VStack(spacing: 20) {
        // Tab selector
        HStack(spacing: 12) {
          ForEach(0..<features.count, id: \.self) { index in
            Button(action: {
              withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                selectedFeature = index
              }
            }) {
              Image(systemName: features[index].icon)
                .font(.system(size: 20, weight: .semibold))
                .foregroundColor(selectedFeature == index ? .white : features[index].color)
                .frame(width: 50, height: 50)
                .background(
                  Circle()
                    .fill(
                      selectedFeature == index
                        ? features[index].color : features[index].color.opacity(0.15))
                )
            }
            .scaleEffect(selectedFeature == index ? 1.1 : 1.0)
            .animation(.spring(response: 0.3, dampingFraction: 0.7), value: selectedFeature)
          }
        }
        .padding(.bottom, 8)
        .opacity(showContent ? 1 : 0)

        // Feature card
        FeatureCard(feature: features[selectedFeature])
          .transition(
            .asymmetric(
              insertion: .scale.combined(with: .opacity),
              removal: .scale.combined(with: .opacity)
            )
          )
          .id(selectedFeature)
          .opacity(showContent ? 1 : 0)
      }
      .padding(.horizontal, 24)

      Spacer()

      // Swipe indicator
      HStack(spacing: 6) {
        Image(systemName: "hand.draw.fill")
          .font(.system(size: 14))
          .foregroundColor(.secondary)
        Text("Tap icons to explore features")
          .font(.system(size: 14))
          .foregroundColor(.secondary)
      }
      .opacity(showContent ? 0.7 : 0)
      .padding(.bottom, 20)
    }
    .frame(maxWidth: .infinity, maxHeight: .infinity)
    .onAppear {
      withAnimation(.easeOut(duration: 0.6).delay(0.2)) {
        showContent = true
      }
    }
  }
}

struct Feature: Identifiable {
  let id = UUID()
  let icon: String
  let title: String
  let description: String
  let color: Color
}

struct FeatureCard: View {
  let feature: Feature

  var body: some View {
    VStack(spacing: 20) {
      // Icon with animated background
      ZStack {
        Circle()
          .fill(
            LinearGradient(
              gradient: Gradient(colors: [
                feature.color.opacity(0.3),
                feature.color.opacity(0.1),
              ]),
              startPoint: .topLeading,
              endPoint: .bottomTrailing
            )
          )
          .frame(width: 100, height: 100)

        Image(systemName: feature.icon)
          .font(.system(size: 40, weight: .semibold))
          .foregroundStyle(
            LinearGradient(
              gradient: Gradient(colors: [feature.color, feature.color.opacity(0.7)]),
              startPoint: .topLeading,
              endPoint: .bottomTrailing
            )
          )
      }
      .padding(.top, 20)

      // Text content
      VStack(spacing: 12) {
        Text(feature.title)
          .font(.system(size: 24, weight: .bold))
          .foregroundColor(.primary)
          .multilineTextAlignment(.center)

        Text(feature.description)
          .font(.system(size: 16))
          .foregroundColor(.secondary)
          .multilineTextAlignment(.center)
          .lineSpacing(4)
          .fixedSize(horizontal: false, vertical: true)
      }
      .padding(.horizontal, 20)
      .padding(.bottom, 20)
    }
    .frame(maxWidth: .infinity)
    .background(
      RoundedRectangle(cornerRadius: 24)
        .fill(Color(.secondarySystemBackground))
        .shadow(color: feature.color.opacity(0.2), radius: 20, x: 0, y: 10)
    )
  }
}

#Preview {
  FeaturesIntroScreen()
    .background(Color(.systemBackground))
}
