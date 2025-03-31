# Points App Guidelines

## Build Commands
- Build: `xcodebuild -scheme Points -configuration Debug`
- Run: Open `.xcodeproj` file in Xcode and use Run button (⌘R)
- Clean: `xcodebuild clean -scheme Points`

## Code Style Guidelines
- Use 4-space indentation consistently
- Follow Swift naming conventions: `camelCase` for variables/functions, `PascalCase` for types
- Organize code with `// MARK:` comments
- Use Swift's type inference where appropriate
- Implement robust error handling with `do`-`try`-`catch` blocks
- Use guard statements for early returns and unwrapping optionals
- Employ extensions to add functionality to existing types
- Prefer value types (structs) over reference types (classes) when appropriate
- Use CoreData best practices for persistent storage operations
- Maintain separation between UI and business logic
- Document complex functions with comment blocks
- Use method chaining via `apply` for fluent interfaces

## Application purpose
- To track routines and tasks attributed by points, iterations, targets, maximums, bonuses, and more.
- More to come

## Tasks
- Nothing here yet

## Notes
- Nothing here yet

## Critical instructions
- Do not make any attempts to create files that already exist in the codebase
- If you have questions where you are not sure about the implementation, ask before making any changes
- If you notice a way that we can reduce the amount of token exchange (e.g. by refactoring in an intelligent way), please point them out
