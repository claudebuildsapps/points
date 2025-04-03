# Points App Guidelines

## Build Commands
- Build: `xcodebuild -scheme Points -configuration Debug`
- Run: Open `.xcodeproj` file in Xcode and use Run button (⌘R)
- Clean: `xcodebuild clean -scheme Points`

## Guidance for refactoring or development
- Focus on implementing requested changes accurately and efficiently
- Only commit changes when explicitly asked with a "commit" command
- When committing, write a descriptive commit message following Git best practices
- Don't ask about committing changes unless specifically requested
- Use the iOS simulator or Xcode for testing rather than scripts

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
- Only commit changes when explicitly asked with the word "commit"
- Keep responses concise and focused on the requested task

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

## UI Elements

### Main Screen

#### Top Navigation Area
- **Date Navigator**: Left/right arrows with date text in center
- **Progress Bar**: Horizontal bar showing completion progress
- **Target Marker**: Green vertical line with pill showing target points
- **Current Points Badge**: Pill showing current points that moves along progress bar
- **Creation Tab Bar**: Three-button row (+Routine, +Task, +Critical) directly below progress bar

#### Task List
- **Task Cell**: Individual task/routine item in the list
- **Task Points Badge**: Colored badge on left side showing point value
- **Task Edit Button**: Pencil icon button next to points badge
- **Task Title**: Main text of the task
- **Completion Slider**: Circle showing completed value with swipe functionality
- **Critical Indicator**: Orange exclamation mark for critical tasks

#### Footer Area
- **Points Counter**: Shows total points earned for current day
- **Action Buttons**: Row of action buttons above tabs (+Routine, +Task, Home, ?, Clear)
- **Footer Tab Bar**: Bottom navigation tabs (Routines, Tasks, Templates, etc.)

### Task/Routine Create/Edit Screen

#### Header Area
- **Screen Title**: "New Task"/"New Routine"/"Edit Task"/"Edit Routine" text
- **Template Button**: Document icon for copying task as template (edit mode only)
- **Delete Button**: Trash icon for deleting task (edit mode only)

#### Form Fields
- **Task Name Field**: Text input for task/routine name
- **Points Field**: Numeric input for points value
- **Target Field**: Numeric input for completion target
- **Reward Field**: Numeric input for reward value
- **Max Field**: Numeric input for maximum completions
- **Routine Toggle**: Switch for routine/task type
- **Optional Toggle**: Switch for optional/required status
- **Critical Toggle**: Switch for critical priority

#### Custom Keyboard
- **Number Pad**: Custom numeric keypad for number inputs
- **Decimal Point**: Button for decimal values (in points and reward fields)
- **Clear Button**: Button to clear current value
- **Done Button**: Checkmark button to confirm input

#### Bottom Action Buttons
- **Cancel Button**: Red button to dismiss without saving
- **Save/Create Button**: Green button to save changes or create new task

## Project Structure
- Main source code is in the /Points directory
- Assets are stored in /Points/Assets.xcassets (only examine when needed for UI work)
- Core Data model is in /Points/Points.xcdatamodeld
