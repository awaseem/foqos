# Foqos Developer Guidelines

This file provides guidelines for agentic coding assistants working on the Foqos iOS app codebase.

## Build & Test Commands

This project includes a `Makefile` with common development tasks. Run `make help` to see all available commands.

### Building
```bash
# Build from command line
make build

# Clean build artifacts
make clean
```

### Running Tests
This project currently does not have unit tests.

### Code Formatting
The project uses swift-format to maintain consistent code style. Run format commands before committing:
```bash
# Check formatting
make lint

# Fix formatting issues
make lint-fix

# Run both lint and build
make check
```

## Code Style Guidelines

### Formatting & Indentation
- **Indentation**: 2 spaces (no tabs)
- **Line width**: Prefer 100-120 characters max
- **Trailing whitespace**: Remove all trailing whitespace
- **Blank lines**: One blank line between functions, two between major sections

### Imports
- Place at the top of each file
- Group alphabetically (system frameworks first, then third-party)
- Separate groups with blank lines
- Remove unused imports

```swift
import DeviceActivity
import FamilyControls
import SwiftUI
import WidgetKit
```

### Naming Conventions
- **Types** (struct, class, enum): PascalCase
  - Views: PascalCase + "View" suffix (e.g., `HomeView`, `ActionButton`)
  - Managers: PascalCase + "Manager" suffix (e.g., `StrategyManager`)
  - Utilities: PascalCase + "Util" suffix (e.g., `TimersUtil`)
  - Models: PascalCase (e.g., `BlockedProfiles`)
- **Functions/Methods**: camelCase, verb-based (e.g., `startBlocking`, `stopBlocking`)
- **Variables/Properties**: camelCase
- **Constants**: camelCase (not UPPER_CASE)
- **Booleans**: Prefix with `is`, `has`, `enable`, `allow` (e.g., `isActive`, `hasPermission`)
- **Private properties**: camelCase, no underscore prefix
- **Static properties**: camelCase or PascalCase based on usage

### SwiftUI Patterns
- Use `@State` for local view state
- Use `@Binding` for parent-child data flow
- Use `@Environment(\.keyPath)` for environment values
- Use `@EnvironmentObject` for shared state managers
- Use `@Query` for SwiftData queries
- Prefer trailing closure syntax for view modifiers

```swift
@State private var isPresenting = false
@Environment(\.modelContext) private var context
@EnvironmentObject var strategyManager: StrategyManager
@Query(sort: \BlockedProfiles.order) private var profiles: [BlockedProfiles]
```

### SwiftData Patterns
- Mark models with `@Model`
- Use `@Attribute(.unique)` for unique identifiers
- Use `@Relationship` for relationships between models
- Use `#Predicate` for complex queries
- Always call `context.save()` after modifications

```swift
@Model
class BlockedProfiles {
  @Attribute(.unique) var id: UUID
  @Relationship var sessions: [BlockedProfileSession] = []
}
```

### Protocols & Strategy Pattern
- Define clear protocols for extensible behavior
- Protocol methods should be minimal and focused
- Use associated types or generic constraints when appropriate
- Strategy implementations return optional views for custom UI

```swift
protocol BlockingStrategy {
  static var id: String { get }
  var name: String { get }
  func startBlocking(context: ModelContext, profile: BlockedProfiles, forceStart: Bool?) -> (any View)?
  func stopBlocking(context: ModelContext, session: BlockedProfileSession) -> (any View)?
}
```

### Error Handling
- Use `try-catch` for throwing functions
- Provide descriptive error messages for user feedback
- Use `fatalError()` only for truly unrecoverable states (e.g., ModelContainer initialization)
- Use `print()` for debugging, remove before production

```swift
do {
  try context.save()
} catch {
  errorMessage = "Failed to save changes: \(error.localizedDescription)"
}
```

### Control Flow
- Use `guard` for early returns and validation
- Prefer early returns over nested if statements
- Use optional chaining extensively
- Use nil-coalescing operator `??` for default values

```swift
guard let profile = try? BlockedProfiles.findProfile(byID: id, in: context) else {
  errorMessage = "Profile not found"
  return
}
```

### Computed Properties
- Use computed properties instead of functions when no parameters are needed
- Keep computed properties lightweight
- Avoid side effects in computed properties

```swift
var isBlocking: Bool {
  return activeSession?.isActive == true
}
```

### Closures
- Prefer trailing closure syntax
- Mark closure parameters with `@escaping` when stored
- Use weak references in closures to avoid retain cycles in classes

```swift
strategy.onSessionCreation = { [weak self] status in
  self?.handleSessionStatus(status)
}
```

### Comments
- Comments are minimal; let code be self-documenting
- Use comments to explain "why", not "what"
- Comment sections of related functionality
- Document complex business logic or workarounds

### Previews
- Include `#Preview` blocks for SwiftUI views
- Create realistic preview data
- Use separate UserDefaults for previews

```swift
#Preview {
  HomeView()
    .environmentObject(RequestAuthorizer())
    .defaultAppStorage(UserDefaults(suiteName: "preview")!)
}
```

### Architectural Patterns
- Use singleton pattern for shared managers via `static let shared`
- Dependency injection via environment objects
- Repository-like static methods on models for data operations
- Coordinator pattern for complex flows (StrategyManager)

### File Organization
- Group related files in subdirectories (Views/, Models/, Components/, Utils/)
- One public type per file when possible
- Private types can be in same file
- Extensions on types should be in separate files or grouped logically

## Testing Best Practices (When Adding Tests)
- Test public interfaces, not private implementation
- Use async/await for async operations
- Mock dependencies for unit tests
- Test both success and failure paths
- Name tests descriptively: `testGivenX_WhenY_ThenZ()`
