import AppIntents

enum WidgetActivityPeriod: String, AppEnum {
  case week
  case month

  static var typeDisplayRepresentation = TypeDisplayRepresentation(name: "Activity view")
  static var caseDisplayRepresentations: [Self: DisplayRepresentation] = [
    .week: "Weekly chart",
    .month: "Monthly grid",
  ]
}
