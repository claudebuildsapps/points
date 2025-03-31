# Points App Specification

## Overview

Points is a personal productivity and habit tracking application designed to gamify daily tasks and routines through a points-based reward system. The core philosophy is to "hack your brain with points" by turning mundane daily activities into a game with tangible progress visualization, completion bonuses, and streak rewards.

## Core Concepts

### Points and Gamification

- Users complete tasks to earn points
- Points accumulate each day based on task completion
- Tasks can have target completion counts and maximum values
- Bonus points for maintaining daily streaks
- Visual feedback through progress bars and completion indicators
- Color-coding based on completion percentage

### Task Management

- Each task has a title, point value, target, and maximum count
- Tasks can be routine (recurring) or one-time
- Tasks can be completed multiple times (for habit tracking)
- Tasks are tied to specific dates for daily tracking
- Users can create, edit, delete, and duplicate tasks

### Date Navigation

- Users can navigate through different days
- Each day maintains its own set of tasks and points
- Default tasks can be created for new days
- Points are calculated and stored per day

## Architecture

### Data Model

The app uses CoreData for persistence with three main entities:

#### CoreDataDate
- `date`: The calendar date 
- `target`: Default target goal for the day
- `points`: Total points accumulated for the day
- `tasks`: Relationship to tasks for that date
- `completions`: Relationship to task completions (historical tracking)

#### CoreDataTask
- `title`: Task name
- `points`: Base point value
- `target`: Target completion count
- `completed`: Current completion count
- `max`: Maximum completions allowed
- `routine`: Boolean indicating if it's a recurring task
- `optional`: Boolean indicating if task is optional
- `position`: Display order position
- `date`: Relationship to the date entity
- `reward`: Additional points awarded upon completion
- `scalar`: Multiplier for point calculations
- `bonus`: Bonus points from streaks or other factors

#### CoreDataTaskCompletion
- `timestamp`: When the task was completed
- `task`: Relationship to the task
- `date`: Relationship to the date

### Component Architecture

The app uses SwiftUI for the UI layer with helper classes for business logic.

#### Core Logic Components

1. **GamificationEngine**
   - Calculates points and bonuses
   - Determines streak bonuses
   - Computes progress percentages
   - Handles scaling factors for point calculations

2. **TaskManager**
   - Manages CRUD operations for tasks
   - Handles batch operations (clear, reset)
   - Coordinates with DateHelper and GamificationEngine
   - Updates date point totals
   - Calculates overall progress

3. **DateHelper**
   - Manages date entity creation and retrieval
   - Ensures new dates have default tasks
   - Handles date formatting and navigation
   - Maintains consistency in date operations

4. **PersistenceController**
   - Manages CoreData stack
   - Provides access to managed object context
   - Handles data backup and restoration

#### UI Components

1. **MainView**
   - Primary container view
   - Manages tab navigation
   - Contains TaskNavigationView for the main task screen

2. **TaskNavigationView**
   - Handles date selection and navigation
   - Displays TaskListWithControls for current date
   - Shows progress bar for daily goal

3. **TaskListWithControls**
   - Container for task list
   - Provides task management controls (add, clear, reset)
   - Connects TaskListContainer with FooterDisplayView

4. **TaskListContainer**
   - Manages task data for current date
   - Handles fetching and displaying tasks
   - Updates points and progress indicators

5. **TaskListView**
   - Displays the list of tasks
   - Creates TaskCellView instances for each task
   - Handles empty state

6. **TaskCellView**
   - Displays individual task info
   - Provides interaction controls (increment, decrement, edit)
   - Shows visual feedback for task completion status
   - Handles edit mode transitions

7. **EditTaskView**
   - Form for creating/editing tasks
   - Custom numeric input
   - Field validation

8. **DateNavigationView**
   - Provides date selection controls
   - Shows current date
   - Handles date entity management

9. **FooterDisplayView**
   - Shows action buttons
   - Displays current points total
   - Animates points changes

10. **ProgressBarView**
    - Shows progress toward daily goal
    - Changes color based on completion percentage

## User Experience Flow

1. **App Launch**
   - App loads the current date
   - Fetches or creates date entity for today
   - Creates default tasks if none exist
   - Displays tasks in TaskListView

2. **Task Interaction**
   - Tap on task to increment completion count
   - Tap undo button to decrement
   - Tap edit button to modify task details
   - Visual feedback shows completion status

3. **Points Calculation**
   - Points update immediately on task completion
   - Animation indicates point changes
   - Progress bar updates to show daily goal progress
   - Completion colors change based on progress

4. **Date Navigation**
   - Change dates using arrows in DateNavigationView
   - Each date loads its specific tasks
   - Points and progress update for current date

5. **Task Management**
   - Add tasks with "+" button
   - Edit tasks with pencil icon
   - Complete routine tasks multiple times
   - Reset or clear tasks as needed

## Technical Implementation Details

### Points Calculation Logic

Points are calculated using the following formula:
1. Base points = task point value
2. If there's a bonus (from streaks, etc.), multiply by (1 + bonus)
3. For routine tasks:
   - If completed ≥ target: points × min(completion/target, max/target)
   - If completed < target: points × (completed/target)
4. For non-routine tasks:
   - All-or-nothing: points if completed ≥ target, 0 otherwise
5. Add any fixed reward points

### Streak Bonus Calculation

1. Base streak bonus = (consecutive days - 1) × 0.1
2. Cap at maximum bonus value (1.0 = 100%)
3. Apply to routine tasks only

### Progress Calculation

1. Calculate total points earned
2. Determine target points (date target × number of tasks)
3. Progress = total points / target points (capped at 1.0)

### Data Management

- Tasks are automatically associated with dates
- Default tasks created for new dates
- Points are recalculated when:
  - Task completion count changes
  - Tasks are added/removed
  - Task properties are edited
- CoreData is used for persistence with relationships between entities

## UI Styling Guidelines

### Colors

- Routines Tab: Green (0.5, 0.7, 0.6)
- Tasks Tab: Blue (0.4, 0.6, 0.8)
- Template Tab: Bluish-Purple (0.6, 0.65, 0.75)
- Summary Tab: Orange (0.7, 0.6, 0.5)
- Data Tab: Red (0.8, 0.5, 0.4)
- Progress < 50%: Yellow
- Progress 50-80%: Yellow-Green
- Progress > 80%: Green
- Task complete: Green background (opacity 0.3)
- Task partially complete: Green with proportional opacity

### Interface Elements

- Circle buttons for actions
- Rounded corners for inputs
- Clean list view with no separators
- Simple tab bar for navigation
- Clear visual feedback for actions
- Consistent padding and spacing

## Animations

- Task completion: Flash green overlay
- Points update: Animated counter
- Progress bar: Smooth transitions
- Tab navigation: Simple transitions

## Keyboard Interaction

Custom keyboards are provided for:
- Numeric input (with decimal option)
- Text input for task titles

## Further Development

Planned future enhancements:
- Stats tab to show historical data
- Settings for customization
- Different task types
- Enhanced visualization
- Achievement badges
- Cloud sync