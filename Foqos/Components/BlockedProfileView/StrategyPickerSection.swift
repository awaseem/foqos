struct StrategyPickerSection: Identifiable {
  let title: String
  let description: String
  let strategies: [BlockingStrategy]

  var id: String { title }
}
