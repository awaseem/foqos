struct StrategyDetailsPresentation: Identifiable {
  let strategy: BlockingStrategy

  var id: String { strategy.getIdentifier() }
}
