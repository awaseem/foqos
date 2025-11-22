import FamilyControls
import Foundation

/// Utility functions for working with FamilyActivitySelection
struct FamilyActivityUtil {

  /// Counts the total number of selected activities (categories + applications + web domains)
  /// - Parameters:
  ///   - selection: The FamilyActivitySelection to count
  ///   - allowMode: Whether this is for allow mode (affects display but not actual count)
  /// - Returns: Total count of selected items
  /// - Note: This shows the count as displayed to users. In ALLOW mode, Apple internally expands
  ///         categories to individual apps when enforcing the 50 app limit, so selecting a few
  ///         categories may exceed the limit. In BLOCK mode, categories count as 1 item each.
  static func countSelectedActivities(_ selection: FamilyActivitySelection, allowMode: Bool = false)
    -> Int
  {
    // This count shows categories + apps + domains as displayed
    // IMPORTANT: In Allow mode, Apple enforces the 50 limit AFTER expanding categories to individual apps
    // In Block mode, categories count as 1 regardless of how many apps they contain
    return selection.categories.count + selection.applications.count + selection.webDomains.count
  }

  /// Gets display text for the count with appropriate warnings for allow mode
  /// - Parameters:
  ///   - selection: The FamilyActivitySelection to display
  ///   - allowMode: Whether this is for allow mode
  /// - Returns: Formatted display text with warnings if needed
  static func getCountDisplayText(_ selection: FamilyActivitySelection, allowMode: Bool = false)
    -> String
  {
    let count = countSelectedActivities(selection, allowMode: allowMode)

    return "\(count) items"
  }

  /// Determines if a warning should be shown for allow mode category selection
  /// - Parameters:
  ///   - selection: The FamilyActivitySelection to check
  ///   - allowMode: Whether this is for allow mode
  /// - Returns: True if warning should be shown
  static func shouldShowAllowModeWarning(
    _ selection: FamilyActivitySelection, allowMode: Bool = false
  ) -> Bool {
    return allowMode && selection.categories.count > 0
  }

  /// Gets a detailed breakdown of the selection for debugging/stats
  /// - Parameter selection: The FamilyActivitySelection to analyze
  /// - Returns: A breakdown of categories, apps, and domains
  static func getSelectionBreakdown(_ selection: FamilyActivitySelection) -> (
    categories: Int, applications: Int, webDomains: Int
  ) {
    return (
      categories: selection.categories.count,
      applications: selection.applications.count,
      webDomains: selection.webDomains.count
    )
  }
}
