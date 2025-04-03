# Points App Guidelines

## Build Commands
- Build: `xcodebuild -scheme Points -configuration Debug`
- Run: Open `.xcodeproj` file in Xcode and use Run button (⌘R) or use the `./run` script to build and deploy to a connected device
- Clean: `xcodebuild clean -scheme Points`

## Guidance for refactoring or development
- After every query is completed, run the app using the `./run` script to test changes on a physical device
- After verifying changes work, ask if I would like to commit the changes, write your own commit message, and push the code, once I approve the change

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
- The app now uses SwiftUI as the primary UI framework
- UIKit controllers (ViewController and TaskViewController) have been removed as they were duplicating functionality
- The tabs have been moved into the footer with the buttons sitting above them
- A unified architecture with the TaskControllers singleton is used to manage task actions
- The tab height has been reduced by ~30% to 42pt (from original 60pt)

## Critical instructions
- Do not make any attempts to create files that already exist in the codebase
- If you have questions where you are not sure about the implementation, ask before making any changes
- If you notice a way that we can reduce the amount of token exchange (e.g. by refactoring in an intelligent way), please point them out
- Do not examine files larger than 500kb to save compute resources (especially asset files)
- Primarily work within the /Points directory as the main source folder
- Skip parsing the Assets.xcassets contents unless specifically needed for a UI change
- After making changes, always suggest running the app using the `./run` script to test on a physical device
- The run script automates building, installing, and launching the app on a connected iOS device

## Component Reference Map

This section maps UI components to their source files, providing descriptions for each element.

### Main Screen Components

#### Main View (MainView.swift)
- **Main Container**: Root view controller that manages tab navigation and main app flow
- **Tab Selection Logic**: Handles switching between different tabs (Tasks, Stats, Templates, etc.)
- **Sheet Presentation**: Controls task creation sheet and confirmation dialogs

#### Task Navigation (TaskNavigationView.swift in MainView.swift)
- **Date Navigation Header**: Shows current date with left/right arrow controls
- **Progress Bar**: Visual indicator of daily task completion with target marker
- **Task Creation Tabs**: Three-button row (+Routine, +Task, +Critical) for creating different task types

#### Progress Bar (ProgressBarView.swift)
- **Progress Indicator**: Colored horizontal bar showing completion progress
- **Target Marker**: Green vertical line with pill showing target points value
- **Points Badge**: Current points display that moves along the progress bar

#### Task List (TaskListContainer.swift)
- **Task Filter Logic**: Handles filtering between routines/tasks/all items
- **Task List Management**: Manages loading, sorting, and displaying tasks
- **Points Calculation**: Updates progress and points based on task completion

#### Task Cell (TaskCellView.swift)
- **Task Display Card**: Individual task card with completion control
- **Points Badge**: Colored badge showing task point value
- **Edit Button**: Pencil icon to edit task details
- **Completion Slider**: Circular counter showing current completions with swipe controls
- **Critical Indicator**: Exclamation mark icon for critical tasks

#### Footer Controls (FooterDisplayView.swift)
- **Points Counter**: Shows total points earned for current day
- **Action Buttons**: +Routine, +Task, Home, Help, Clear buttons
- **Tab Bar**: Bottom navigation for app sections (Routines, Tasks, Templates, etc.)

#### Tab Bar (TabBarView.swift)
- **Tab Buttons**: Navigation tabs for main app sections
- **Tab Styling**: Handles colors and selection state

### Task Editing Components

#### Task Form (TaskFormView.swift)
- **Task Editor**: Form for creating or editing tasks
- **Points Controls**: Inputs for points, target, reward values
- **Type Toggles**: Switches for routine/task, optional/required, critical flags
- **Save/Cancel Actions**: Buttons for confirming or dismissing changes

#### Edit Task View (EditTaskView.swift)
- **Edit UI**: Sheet interface for task editing
- **Delete Controls**: Options for removing tasks
- **Template Controls**: Converting tasks to templates

#### Custom Keyboard (CustomNumericKeyboard.swift)
- **Number Pad**: Custom numeric entry keyboard
- **Value Entry**: Controls for entering point values and targets

### Data Components

#### Date Helper (DateHelper.swift)
- **Date Navigation**: Logic for moving between days
- **Date Entity Management**: Creates and retrieves CoreData date entities

#### Task Manager (TaskManager.swift)
- **Task CRUD Operations**: Create, read, update, delete task operations
- **Core Data Interface**: Manages persistent storage of tasks
- **Points Calculations**: Logic for calculating task points and progress

#### Core Data Models (Points.xcdatamodeld, Task.swift)
- **Data Schema**: Defines structure for tasks, dates, and templates
- **Relationships**: Connections between data entities
- **CoreDataTask**: Main task model with properties for all task attributes

### Utility Components

#### Theme System (UIExtensions.swift)
- **Color Schemes**: Defines colors for light and dark modes
- **Theme Values**: Maps semantic colors (routinesTab, tasksTab, criticalColor, etc.)
- **UI Extensions**: Helper methods for consistent styling

#### Constants (Constants.swift)
- **Default Values**: Standard values for new tasks and routines
- **Animation Timings**: Duration values for UI animations
- **Notification Names**: String constants for internal app notifications

#### Gamification Engine (GamificationEngine.swift)
- **Reward Logic**: Handles point calculations and bonuses
- **Progress Tracking**: Manages completion tracking across tasks

## Project Structure
- Main source code is in the /Points directory
- Assets are stored in /Points/Assets.xcassets (only examine when needed for UI work)
- Core Data model is in /Points/Points.xcdatamodeld
