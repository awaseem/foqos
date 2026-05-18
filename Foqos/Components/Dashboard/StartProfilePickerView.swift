import SwiftUI
import UIKit

struct StartProfilePickerView: View {
  @Environment(\.dismiss) private var dismiss
  @Environment(\.accessibilityReduceMotion) private var reduceMotion
  @EnvironmentObject private var themeManager: ThemeManager

  let profiles: [BlockedProfiles]
  let isBlocking: Bool
  let activeSessionProfileId: UUID?
  let startingProfileId: UUID?
  let onGoTapped: (BlockedProfiles) -> Void

  @State private var selectedProfileId: UUID?
  @State private var isShimmering = false

  private let shimmerAnimationDuration = 1.15
  private let shimmerRepeatDelay = 2.5

  init(
    profiles: [BlockedProfiles],
    isBlocking: Bool,
    activeSessionProfileId: UUID?,
    startingProfileId: UUID? = nil,
    onGoTapped: @escaping (BlockedProfiles) -> Void
  ) {
    self.profiles = profiles
    self.isBlocking = isBlocking
    self.activeSessionProfileId = activeSessionProfileId
    self.startingProfileId = startingProfileId
    self.onGoTapped = onGoTapped
    _selectedProfileId = State(
      initialValue: profiles.first(where: { $0.id == startingProfileId })?.id ?? profiles.first?.id)
  }

  private var selectedProfile: BlockedProfiles? {
    guard let selectedProfileId else { return nil }
    return profiles.first(where: { $0.id == selectedProfileId })
  }

  private var canGo: Bool {
    selectedProfile != nil && !isBlocking
  }

  var body: some View {
    NavigationStack {
      VStack(spacing: 0) {
        if profiles.isEmpty {
          EmptyView(
            iconName: "person.crop.circle.badge.plus",
            headingText: "Create a profile before starting a focus session"
          )
          .frame(maxWidth: .infinity, maxHeight: .infinity)
        } else {
          ScrollView {
            VStack(spacing: 10) {
              if isBlocking {
                activeSessionNotice
              }

              ForEach(profiles) { profile in
                StartProfilePickerRow(
                  profile: profile,
                  isSelected: profile.id == selectedProfileId,
                  isActive: profile.id == activeSessionProfileId,
                  onTap: {
                    UIImpactFeedbackGenerator(style: .light).impactOccurred()
                    withAnimation(.spring(response: 0.28, dampingFraction: 0.74)) {
                      selectedProfileId = profile.id
                    }
                  }
                )
              }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
          }
        }

        goButton
      }
      .background(Color(.systemGroupedBackground))
      .navigationTitle("Start Profile")
      .navigationBarTitleDisplayMode(.inline)
      .toolbar {
        ToolbarItem(placement: .topBarLeading) {
          Button(action: { dismiss() }) {
            Image(systemName: "xmark")
          }
        }
      }
      .onChange(of: profiles) { _, newProfiles in
        if selectedProfile == nil {
          withAnimation(.spring(response: 0.28, dampingFraction: 0.74)) {
            selectedProfileId = newProfiles.first?.id
          }
        }
      }
      .onChange(of: startingProfileId) { _, newValue in
        if let newValue, profiles.contains(where: { $0.id == newValue }) {
          withAnimation(.spring(response: 0.28, dampingFraction: 0.74)) {
            selectedProfileId = newValue
          }
        }
      }
      .onAppear {
        guard !reduceMotion else { return }
        isShimmering = true
      }
    }
  }

  private var activeSessionNotice: some View {
    HStack(spacing: 10) {
      Image(systemName: "lock.fill")
        .foregroundStyle(themeManager.themeColor)

      Text("A profile is already active. Stop it before starting another one.")
        .font(.subheadline)
        .foregroundStyle(.secondary)
        .fixedSize(horizontal: false, vertical: true)

      Spacer(minLength: 0)
    }
    .padding(14)
    .background(
      RoundedRectangle(cornerRadius: 14, style: .continuous)
        .fill(Color(.secondarySystemGroupedBackground))
    )
  }

  private var goButton: some View {
    VStack(spacing: 8) {
      Button(action: goTapped) {
        HStack(spacing: 8) {
          Image(systemName: "arrow.right.circle.fill")
          Text("Go")
        }
        .font(.headline)
        .fontWeight(.semibold)
        .frame(maxWidth: .infinity)
        .frame(height: 52)
        .background(goButtonBackground)
      }
      .buttonStyle(GoButtonStyle())
      .foregroundStyle(.white)
      .disabled(!canGo)
    }
    .padding(.horizontal, 16)
    .padding(.top, 10)
    .padding(.bottom, 16)
  }

  private var goButtonBackground: some View {
    Capsule()
      .fill(themeManager.themeColor)
      .opacity(canGo ? 1 : 0.45)
      .overlay {
        if canGo && !reduceMotion {
          GeometryReader { geometry in
            LinearGradient(
              colors: [
                .clear,
                .white.opacity(0.12),
                .white.opacity(0.38),
                .white.opacity(0.12),
                .clear,
              ],
              startPoint: .top,
              endPoint: .bottom
            )
            .frame(width: geometry.size.width * 0.34, height: geometry.size.height * 2.2)
            .rotationEffect(.degrees(18))
            .offset(
              x: isShimmering ? geometry.size.width * 1.15 : -geometry.size.width * 0.55,
              y: -geometry.size.height * 0.55
            )
            .animation(
              .linear(duration: shimmerAnimationDuration)
                .delay(shimmerRepeatDelay)
                .repeatForever(autoreverses: false),
              value: isShimmering
            )
          }
          .clipShape(Capsule())
          .blendMode(.screen)
        }
      }
  }

  private func goTapped() {
    guard let selectedProfile, !isBlocking else { return }
    UIImpactFeedbackGenerator(style: .medium).impactOccurred()
    onGoTapped(selectedProfile)
    dismiss()
  }
}

private struct GoButtonStyle: ButtonStyle {
  func makeBody(configuration: Configuration) -> some View {
    configuration.label
      .scaleEffect(configuration.isPressed ? 0.95 : 1)
      .animation(
        .spring(response: 0.22, dampingFraction: 0.72),
        value: configuration.isPressed
      )
  }
}

private struct PickerRowButtonStyle: ButtonStyle {
  let isSelected: Bool

  func makeBody(configuration: Configuration) -> some View {
    configuration.label
      .scaleEffect(configuration.isPressed ? 0.97 : (isSelected ? 1.015 : 1))
      .animation(
        .spring(response: 0.22, dampingFraction: 0.72),
        value: configuration.isPressed
      )
      .animation(
        .spring(response: 0.28, dampingFraction: 0.78),
        value: isSelected
      )
  }
}

private struct StartProfilePickerRow: View {
  @EnvironmentObject private var themeManager: ThemeManager

  let profile: BlockedProfiles
  let isSelected: Bool
  let isActive: Bool
  let onTap: () -> Void

  var body: some View {
    Button(action: onTap) {
      ProfileSummaryRow(
        profile: profile,
        isActive: isActive,
        metadata: .appsAndDomains,
        showsStatusLine: true
      ) {
        Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
          .font(.system(size: 22, weight: .semibold))
          .foregroundStyle(isSelected ? themeManager.themeColor : .secondary.opacity(0.5))
      }
      .padding(14)
      .background(
        RoundedRectangle(cornerRadius: 16, style: .continuous)
          .fill(Color(.secondarySystemGroupedBackground))
          .overlay(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
              .strokeBorder(
                isSelected ? themeManager.themeColor.opacity(0.45) : Color.primary.opacity(0.06),
                lineWidth: isSelected ? 2 : 1
              )
          )
      )
    }
    .buttonStyle(PickerRowButtonStyle(isSelected: isSelected))
    .animation(.spring(response: 0.28, dampingFraction: 0.78), value: isSelected)
  }
}

#Preview {
  StartProfilePickerView(
    profiles: [
      BlockedProfiles(name: "Work"),
      BlockedProfiles(name: "Study"),
    ],
    isBlocking: false,
    activeSessionProfileId: nil,
    onGoTapped: { _ in }
  )
  .environmentObject(ThemeManager.shared)
}
