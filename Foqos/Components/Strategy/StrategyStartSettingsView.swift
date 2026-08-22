import SwiftUI

enum StrategyStartSettingsKind: String, Identifiable {
  case timer
  case pauseTimer
  case temporaryAccess

  var id: String { rawValue }

  init?(strategy: BlockingStrategy?) {
    guard let strategy else {
      return nil
    }

    if strategy.hasTimer {
      self = .timer
      return
    }

    if strategy.hasPauseMode {
      self = .pauseTimer
      return
    }

    let strategyId = strategy.getIdentifier()
    if strategyId == NFCSoftUnblockBlockingStrategy.id
      || strategyId == QRSoftUnblockBlockingStrategy.id
    {
      self = .temporaryAccess
      return
    }

    return nil
  }

  var presentationDetents: Set<PresentationDetent> {
    switch self {
    case .temporaryAccess:
      return [.large]
    case .timer, .pauseTimer:
      return [.medium, .large]
    }
  }

  var defaultData: Data? {
    switch self {
    case .timer:
      return StrategyTimerData.toData(from: .defaultConfiguration)
    case .pauseTimer:
      return StrategyPauseTimerData.toData(
        from: StrategyPauseTimerData(
          pauseDurationInMinutes: StrategyPauseTimerData.defaultPauseDurationInMinutes
        )
      )
    case .temporaryAccess:
      return SoftUnblockStrategyData.encode(SoftUnblockStrategyData.decode(nil))
    }
  }
}

struct StrategyStartSettingsView: View {
  let kind: StrategyStartSettingsKind
  @ObservedObject var draft: BlockedProfileDraft

  private var profileName: String {
    draft.name.isEmpty ? "this profile" : draft.name
  }

  @ViewBuilder
  var body: some View {
    switch kind {
    case .timer:
      TimerDurationView(
        profileName: profileName,
        initialConfiguration: StrategyTimerData.decode(draft.strategyData),
        actionTitle: "Save Settings"
      ) { configuration in
        draft.strategyData = StrategyTimerData.toData(from: configuration)
      }

    case .pauseTimer:
      let configuration = StrategyPauseTimerData.toStrategyPauseTimerData(
        from: draft.strategyData
      )

      PauseDurationView(
        profileName: profileName,
        initialDurationMinutes: configuration.pauseDurationInMinutes,
        actionTitle: "Save Settings"
      ) { durationInMinutes in
        draft.strategyData = StrategyPauseTimerData.toData(
          from: StrategyPauseTimerData(
            pauseDurationInMinutes: durationInMinutes
          )
        )
      }

    case .temporaryAccess:
      SoftUnblockConfigurationView(
        profileName: profileName,
        initialConfiguration: SoftUnblockStrategyData.decode(draft.strategyData),
        actionTitle: "Save Settings"
      ) { configuration in
        draft.strategyData = SoftUnblockStrategyData.encode(configuration)
      }
    }
  }
}
