import FamilyControls
import Foundation

/// Utility functions for working with FamilyActivitySelection
struct FamilyActivityUtil {

  /// Counts the total number of selected activities (categories + applications + web domains)
  /// - Parameters:
  ///   - selection: The FamilyActivitySelection to count
  ///   - allowMode: Whether this is for allow mode (affects display but not actual count)
  /// - Returns: Total count of selected items
  static func countSelectedActivities(_ selection: FamilyActivitySelection, allowMode: Bool = false)
    -> Int
  {
    // In both allow and block modes, the API limit counts categories as 1 each
    // The difference is that in allow mode, Apple internally expands categories
    // to individual apps, which may cause hitting the 50 limit sooner
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

    if allowMode && selection.categories.count > 0 {
      return "\(count) items (categories expand to individual apps)"
    } else {
      return "\(count) items"
    }
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
