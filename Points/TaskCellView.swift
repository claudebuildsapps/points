import SwiftUI
import CoreData

struct TaskCellView: View {
    @Environment(\.managedObjectContext) private var context
    @Environment(\.theme) private var theme
    @ObservedObject var task: CoreDataTask
    @State private var isExpanded = false
    @State private var isEditMode = false
    @State private var flashBackground = false
    @State private var isSwipeInProgress = false
    @State private var swipeOffset: CGFloat = 0
    @State private var isPointsEditMode = false
    @State private var editablePoints = ""
    @State private var isFirstDigit = true // Track if this is the first digit entered
    
    // Dark green color for target completion
    private let darkGreenColor = Color(red: 0.2, green: 0.6, blue: 0.4)

    // Callback closures
    var onDecrement: () -> Void
    var onDelete: () -> Void
    var onDuplicate: () -> Void
    var onCopyToTemplate: (() -> Void)?
    var onSaveEdit: ([String: Any]) -> Void
    var onCancelEdit: () -> Void
    var onIncrement: () -> Void

    var body: some View {
        Button(action: {
            // Only process tap if not currently swiping
            if !isSwipeInProgress {
                let previousCompleted = Int(task.completed)
                
                // If target and max are both 1, and task is completed, toggle back to 0
                if Int(task.target) == 1 && Int(task.max) == 1 && Int(task.completed) == 1 {
                    onDecrement() // Reset to 0
                } else {
                    // Otherwise increment as usual
                    onIncrement()
                }
                
                animateCompletionChange(from: previousCompleted)
            }
        }) {
            ZStack {
                // Background with completion state color
                Group {
                    backgroundColor()
                        .animation(.easeInOut(duration: Constants.Animation.standard), value: task.completed)
                    
                    // Flash overlay for completion animation
                    if flashBackground {
                        theme.taskHighlight.allowsHitTesting(false)
                    }
                    
                    // Visual feedback for swipe gesture when in progress
                    if isSwipeInProgress && swipeOffset < 0 {
                        // Only show swipe feedback for left swipes
                        LinearGradient(
                            gradient: Gradient(
                                colors: [Color.clear, Color.orange.opacity(0.2)]
                            ),
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                        .opacity(min(abs(swipeOffset) / 100.0, 0.7))
                        .allowsHitTesting(false)
                    }
                }
                
                // Content row
                HStack(spacing: 0) { // No default spacing - we'll control spacing individually
                    // Critical indicator moved to be closer to the completion slider
                    Spacer() // This pushes the exclamation mark to the right
                    
                    // Action buttons
                    HStack(spacing: 10) { // Increased spacing between points display and edit button
                        // Eye-catching points indicator with badge-like design
                        VStack(spacing: -2) {
                            ZStack {
                                // Points background - dark colored background
                                RoundedRectangle(cornerRadius: 12)
                                    .fill(task.getCritical() ? theme.criticalColor : (task.routine ? theme.routinesTab : theme.tasksTab)) // Full color background with critical priority
                                    .frame(width: 45, height: 40)
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 12)
                                            .stroke(
                                                task.getCritical() ? theme.criticalColor : (task.routine ? theme.routinesTab : theme.tasksTab),
                                                lineWidth: 2
                                            )
                                    )
                                    .shadow(
                                        color: (task.getCritical() ? theme.criticalColor : (task.routine ? theme.routinesTab : theme.tasksTab)).opacity(0.4),
                                        radius: 2,
                                        x: 0,
                                        y: 1
                                    )
                                
                                // Points value with "pts" label - bright white text for contrast
                                VStack(spacing: 0) { // Vertical stack with minimal spacing
                                    Text("\(Int(task.points?.doubleValue ?? 0))")
                                        .font(.system(size: 16, weight: .bold)) // Reduced from 20 to 16
                                        .foregroundColor(.white) // Pure white for maximum contrast
                                        .fixedSize() // Prevent layout issues
                                    
                                    Text("pts")
                                        .font(.system(size: 10, weight: .bold)) // Reduced from 11 to 10
                                        .foregroundColor(.white) // Pure white
                                        .padding(.top, -2) // Tighten spacing
                                }
                                .padding(.horizontal, 2) // Add some padding to prevent edge touching
                            }
                        }
                        .frame(width: 45)
                        .contentShape(Rectangle()) // Make the entire area tappable
                        .onTapGesture {
                            // Initialize the editable points with current value
                            editablePoints = "\(Int(task.points?.doubleValue ?? 0))"
                            isFirstDigit = true // Reset the first digit flag
                            isPointsEditMode = true
                        }
                        .helpMetadata(HelpMetadata(
                            id: "task-points-badge",
                            title: "Task Point Value",
                            description: "Shows how many points this task is worth when completed.",
                            usageHints: [
                                "Tap to quickly edit point value",
                                "Higher point values indicate more important tasks",
                                "Routines typically have higher point values",
                                "Points contribute to your daily progress total"
                            ],
                            importance: .important
                        ))
                        
                        // Edit button - color based on whether it's a routine or task
                        Button(action: toggleEditMode) {
                            Image(systemName: "pencil")
                                .themeCircleButton(
                                    color: task.getCritical() ? theme.criticalColor : (task.routine ? theme.routinesTab : theme.tasksTab),
                                    textColor: theme.textInverted
                                )
                        }
                        .buttonStyle(PlainButtonStyle())
                        .frame(width: 40)
                        .contentShape(Rectangle())
                        .onTapGesture(perform: toggleEditMode)
                        .padding(.trailing, 2) // Small padding between edit button and title
                        .helpMetadata(HelpMetadata(
                            id: "task-edit-button",
                            title: "Edit Task Button",
                            description: "Opens the task editor to modify this task's properties.",
                            usageHints: [
                                "Edit task title, points, target, and other properties",
                                "Delete or duplicate the task",
                                "Convert tasks to templates for reuse",
                                "Change task type (routine/task/critical)"
                            ],
                            importance: .important
                        ))
                    }

                    // Task title - reduced font size and allowed two lines
                    VStack(alignment: .leading) {
                        Text(task.title ?? "Untitled")
                            .font(.system(size: 16, weight: .medium)) // Reduced font size from 20 to 16
                            .foregroundColor(.primary)
                            .lineLimit(2) // Allow two lines instead of one
                            .truncationMode(.tail)
                            .fixedSize(horizontal: false, vertical: true) // Allow text to wrap naturally
                            .padding(.vertical, 2) // Reduced padding to accommodate second line
                    }
                    .padding(.leading, 5) // Added padding to offset from edit button
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .helpMetadata(HelpMetadata(
                        id: "task-title",
                        title: "Task Title",
                        description: "The name of the task or routine to complete.",
                        usageHints: [
                            "Tap the entire row to increase completion count",
                            "Swipe left anywhere on the row to decrease completion count",
                            "Different background shades indicate completion progress",
                            "Colored backgrounds indicate task type (blue for tasks, green for routines, red for critical)"
                        ],
                        importance: .informational
                    ))

                    // Add the critical indicator before the completion slider if task is critical
                    if task.getCritical() {
                        ZStack {
                            Circle()
                                .fill(theme.criticalColor)
                                .frame(width: 24, height: 24)
                                .shadow(color: theme.criticalColor.opacity(0.6), radius: 2, x: 0, y: 1)
                            
                            Image(systemName: "exclamationmark")
                                .font(.system(size: 12, weight: .bold)) // Reduced from 14 to 12
                                .foregroundColor(.white)
                        }
                        .padding(.horizontal, 4) // Add a small gap between indicator and slider
                        .helpMetadata(HelpMetadata(
                            id: "critical-indicator",
                            title: "Critical Task Indicator",
                            description: "Indicates this is a high-priority task.",
                            usageHints: [
                                "Critical tasks are visually highlighted for emphasis",
                                "Use for important deadlines or must-do tasks",
                                "Helps you identify your highest priority items",
                                "Can be set when creating or editing a task"
                            ],
                            importance: .important
                        ))
                    }
                    
                    // Enhanced slider-style completion tracker with swipe gesture
                    ZStack(alignment: .leading) {
                        // Track background - oval shape
                        Capsule()
                            .fill(Color.gray.opacity(0.15))
                            .frame(width: 80, height: 28) // Maintain increased size
                        
                        // Calculate position based on completion vs target
                        let trackWidth: CGFloat = 80
                        let circleSize: CGFloat = 28 // Maintain increased circle size
                        
                        // Calculate position (centered in each segment)
                        let completionRatio = CGFloat(min(Int(task.completed), Int(task.target))) / CGFloat(max(Int(task.target), 1))
                        let maxOffset = trackWidth - circleSize
                        let circleOffset = completionRatio * maxOffset
                        
                        // Determine circle color based on completion vs target
                        let circleColor: Color = {
                            if Int(task.completed) > Int(task.target) {
                                return theme.dataTab // Use data tab color (blue) for exceeding target 
                            } else if Int(task.completed) == Int(task.target) {
                                return darkGreenColor // Use dark green when exactly at target
                            } else {
                                return task.getCritical() ? theme.criticalColor : theme.templateTab // Use critical or template color otherwise
                            }
                        }()
                        
                        // Sliding completion counter
                        ZStack {
                            // Circle with appropriate color
                            Circle()
                                .fill(circleColor)
                                .frame(width: circleSize, height: circleSize)
                                .shadow(color: Color.black.opacity(0.3), radius: 2, x: 0, y: 1)
                            
                            // Completion count with consistent font size
                            Text("\(Int(task.completed))")
                                .font(.system(size: 14, weight: .bold)) // Reduced from 16 to 14
                                .foregroundColor(.white)
                        }
                        .offset(x: circleOffset)
                        .animation(.spring(response: 0.4, dampingFraction: 0.7), value: Int(task.completed))
                    }
                    .frame(width: 80, height: 32) // Maintain increased overall size
                    .contentShape(Rectangle()) // Make entire area tappable
                    .helpMetadata(HelpMetadata(
                        id: "completion-slider",
                        title: "Completion Counter",
                        description: "Shows and controls how many times you've completed this task.",
                        usageHints: [
                            "Swipe left anywhere on the task row to decrease the count",
                            "Tap the task row to increase the count",
                            "For single-completion tasks (target/max=1), tap again to toggle off",
                            "The slider position represents progress toward target",
                            "The counter turns green when reaching your target",
                            "The counter turns blue when exceeding your target",
                            "Task background darkens as you approach completion"
                        ],
                        importance: .important
                    ))
                    // This is now handled by the row-level gesture
                    // Keeping the same helpMetadata for documentation purposes
                }
                .padding(.vertical, 12)
                .padding(.horizontal, 8)
            }
        }
        .buttonStyle(PlainButtonStyle())
        // Add swipe left gesture to the entire row with improved gesture blocking
        .simultaneousGesture(
            DragGesture(minimumDistance: 10)
                .onChanged { value in
                    // Set flag immediately when drag starts
                    isSwipeInProgress = true
                    swipeOffset = value.translation.width
                    
                    // Only keep gesture active for horizontal swipes
                    if abs(value.translation.height) > abs(value.translation.width) * 1.5 {
                        // If more vertical than horizontal, cancel swipe state
                        isSwipeInProgress = false
                        swipeOffset = 0
                    }
                }
                .onEnded { value in
                    // Only handle left swipes with sufficient horizontal movement
                    if value.translation.width < -20 && abs(value.translation.height) < abs(value.translation.width) {
                        // Check if there are completions to decrement
                        if Int(task.completed) > 0 {
                            let previousCompleted = Int(task.completed)
                            onDecrement()
                            animateCompletionChange(from: previousCompleted)
                        }
                    }
                    
                    // Reset visual swipe effect immediately
                    swipeOffset = 0
                    
                    // Reset flag after longer delay to ensure tap doesn't trigger
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                        isSwipeInProgress = false
                    }
                }
        )
        
        // Present edit sheet when edit mode is active
        .sheet(isPresented: $isExpanded, onDismiss: {
            onCancelEdit()
            isEditMode = false
        }) {
            EditTaskView(
                task: task,
                isExpanded: $isExpanded,
                isEditMode: $isEditMode,
                onSave: { updatedValues in
                    onSaveEdit(updatedValues)
                    isExpanded = false
                    isEditMode = false
                },
                onCancel: {
                    onCancelEdit()
                    isExpanded = false
                    isEditMode = false
                },
                onDelete: {
                    onDelete()
                    isExpanded = false
                    isEditMode = false
                },
                onCopyToTemplate: onCopyToTemplate != nil ? {
                    onCopyToTemplate?()
                    isExpanded = false
                    isEditMode = false
                } : nil
            )
            .padding(.top, 20)
        }
        // Sheet for quick points editing
        .sheet(isPresented: $isPointsEditMode) {
            // Simple numeric keypad for points editing
            VStack {
                Text("Edit Points")
                    .font(.headline)
                    .padding()
                
                // Always show current value - use placeholder if empty
                Text(editablePoints.isEmpty ? "\(Int(task.points?.doubleValue ?? 0))" : editablePoints)
                    .font(.system(size: 36, weight: .bold))
                    .padding()
                
                // Custom numeric keypad
                VStack(spacing: 10) {
                    // Number rows
                    ForEach(0..<3) { row in
                        HStack(spacing: 20) {
                            ForEach(1...3, id: \.self) { col in
                                let number = row * 3 + col
                                Button(action: {
                                    if isFirstDigit {
                                        // Replace value with first digit
                                        editablePoints = "\(number)"
                                        isFirstDigit = false
                                    } else {
                                        // Append subsequent digits
                                        editablePoints += "\(number)"
                                    }
                                }) {
                                    Text("\(number)")
                                        .font(.system(size: 24, weight: .medium))
                                        .frame(width: 60, height: 60)
                                        .background(Color.gray.opacity(0.2))
                                        .cornerRadius(30)
                                }
                            }
                        }
                    }
                    
                    // Last row with 0, clear, done
                    HStack(spacing: 20) {
                        // Clear button
                        Button(action: {
                            editablePoints = ""
                            isFirstDigit = true // Reset first digit flag when clearing
                        }) {
                            Image(systemName: "delete.left")
                                .font(.system(size: 24))
                                .frame(width: 60, height: 60)
                                .background(Color.red.opacity(0.2))
                                .cornerRadius(30)
                        }
                        
                        // 0 button
                        Button(action: {
                            if isFirstDigit {
                                // Replace value with zero
                                editablePoints = "0"
                                isFirstDigit = false
                            } else {
                                // Append zero to existing number
                                editablePoints += "0"
                            }
                        }) {
                            Text("0")
                                .font(.system(size: 24, weight: .medium))
                                .frame(width: 60, height: 60)
                                .background(Color.gray.opacity(0.2))
                                .cornerRadius(30)
                        }
                        
                        // Done button
                        Button(action: {
                            savePointsValue()
                        }) {
                            Image(systemName: "checkmark")
                                .font(.system(size: 24))
                                .frame(width: 60, height: 60)
                                .background(Color.green.opacity(0.2))
                                .cornerRadius(30)
                        }
                    }
                }
                .padding()
                
                Spacer()
            }
            .presentationDetents([.medium])
            .presentationDragIndicator(.visible)
        }
        .standardAnimation()
    }

    // Toggle edit mode
    private func toggleEditMode() {
        withAnimation(.easeInOut(duration: Constants.Animation.standard)) {
            isEditMode.toggle()
            isExpanded = isEditMode
        }
        if !isEditMode {
            onCancelEdit()
        }
    }
    
    // Save the points value and update the task
    private func savePointsValue() {
        if let newPointsValue = Int(editablePoints), newPointsValue > 0 {
            // Create updated values dictionary with just the points value
            let updatedValues: [String: Any] = [
                "points": NSDecimalNumber(value: newPointsValue)
            ]
            
            // Use the existing onSaveEdit closure to update the task
            onSaveEdit(updatedValues)
            
            // Close the edit sheet
            isPointsEditMode = false
            
            // Flash background to indicate update
            withAnimation(.easeInOut(duration: Constants.Animation.flash)) {
                flashBackground = true
            }
            
            DispatchQueue.main.asyncAfter(deadline: .now() + Constants.Animation.flash) {
                withAnimation(.easeInOut(duration: Constants.Animation.standard)) {
                    self.flashBackground = false
                }
            }
        } else {
            // If invalid value, just dismiss without saving
            isPointsEditMode = false
        }
    }
    
    // Handle decrement button tap
    private func handleDecrement() {
        if Int(task.completed) > 0 {
            let previousCompleted = Int(task.completed)
            onDecrement()
            animateCompletionChange(from: previousCompleted)
        }
        // When completions are zero, do nothing (no toggle or other action)
    }

    // Animate task completion
    private func animateCompletionChange(from previousCompleted: Int) {
        let currentCompleted = Int(task.completed)
        
        if currentCompleted != previousCompleted {
            withAnimation(.easeInOut(duration: Constants.Animation.flash)) {
                flashBackground = true
            }
            
            DispatchQueue.main.asyncAfter(deadline: .now() + Constants.Animation.flash) {
                withAnimation(.easeInOut(duration: Constants.Animation.standard)) {
                    self.flashBackground = false
                }
            }
        }
    }
    
    // Calculate background color based on type (routine/task) and completion using theme
    private func backgroundColor() -> Color {
        let completed = Int(task.completed)
        let target = Int(task.target)
        let isRoutine = task.routine
        let isCritical = task.getCritical()
        
        // Base colors for task types - use tab colors
        let routineBaseColor = theme.routinesTab
        let taskBaseColor = theme.tasksTab
        let criticalBaseColor = theme.criticalColor
        
        // Choose base color based on item type (critical takes precedence)
        let baseColor = isCritical ? criticalBaseColor : (isRoutine ? routineBaseColor : taskBaseColor)
        
        if completed >= target {
            // Completed state - more opaque
            return baseColor.opacity(0.3)
        } else if completed > 0 {
            // Partially completed - adjust opacity based on progress
            let progress = CGFloat(completed) / CGFloat(target)
            return baseColor.opacity(0.15 + progress * 0.15) // Subtle opacity adjustment
        } else {
            // Not started yet - very subtle background
            return baseColor.opacity(0.07)
        }
    }
}

extension TaskCellView {
    // Public method to set edit mode from parent
    func toggleEditMode(isOn: Bool) {
        withAnimation(.easeInOut(duration: Constants.Animation.standard)) {
            isEditMode = isOn
            isExpanded = isOn
        }
    }
}
