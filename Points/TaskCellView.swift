import SwiftUI
import CoreData

struct TaskCellView: View {
    @Environment(\.managedObjectContext) private var context
    @Environment(\.theme) private var theme
    @ObservedObject var task: CoreDataTask
    @State private var isExpanded = false
    @State private var isEditMode = false
    @State private var flashBackground = false

    // Callback closures
    var onDecrement: () -> Void
    var onDelete: () -> Void
    var onDuplicate: () -> Void
    var onSaveEdit: ([String: Any]) -> Void
    var onCancelEdit: () -> Void
    var onIncrement: () -> Void

    var body: some View {
        Button(action: {
            let previousCompleted = Int(task.completed)
            onIncrement()
            animateCompletionChange(from: previousCompleted)
        }) {
            ZStack {
                // Background with completion state color
                backgroundColor()
                    .animation(.easeInOut(duration: Constants.Animation.standard), value: task.completed)
                
                // Flash overlay for completion animation
                if flashBackground {
                    theme.taskHighlight
                        .allowsHitTesting(false)
                }
                
                // Content row
                HStack(spacing: 8) {
                    // Action buttons
                    HStack(spacing: 8) {
                        // Eye-catching points indicator with badge-like design
                        VStack(spacing: -2) {
                            ZStack {
                                // Points background - dark colored background
                                RoundedRectangle(cornerRadius: 12)
                                    .fill(task.routine ? theme.routinesTab : theme.tasksTab) // Full color background
                                    .frame(width: 45, height: 40)
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 12)
                                            .stroke(
                                                task.routine ? theme.routinesTab : theme.tasksTab,
                                                lineWidth: 2
                                            )
                                    )
                                    .shadow(
                                        color: (task.routine ? theme.routinesTab : theme.tasksTab).opacity(0.4),
                                        radius: 2,
                                        x: 0,
                                        y: 1
                                    )
                                
                                // Points value with "pts" label - bright white text for contrast
                                VStack(spacing: 0) { // Vertical stack with minimal spacing
                                    Text("\(Int(task.points?.doubleValue ?? 0))")
                                        .font(.system(size: 20, weight: .bold)) 
                                        .foregroundColor(.white) // Pure white for maximum contrast
                                        .fixedSize() // Prevent layout issues
                                    
                                    Text("pts")
                                        .font(.system(size: 11, weight: .bold))
                                        .foregroundColor(.white) // Pure white
                                        .padding(.top, -2) // Tighten spacing
                                }
                                .padding(.horizontal, 2) // Add some padding to prevent edge touching
                            }
                        }
                        .frame(width: 45)
                        
                        // Edit button - color based on whether it's a routine or task
                        Button(action: toggleEditMode) {
                            Image(systemName: "pencil")
                                .themeCircleButton(
                                    color: task.routine ? theme.routinesTab : theme.tasksTab,
                                    textColor: theme.textInverted
                                )
                        }
                        .buttonStyle(PlainButtonStyle())
                        .frame(width: 40)
                        .contentShape(Rectangle())
                        .onTapGesture(perform: toggleEditMode)

                        // Undo button
                        Button(action: {
                            // Only perform action if there are completions to undo
                            if Int(task.completed) > 0 {
                                handleDecrement()
                            }
                            // Otherwise, do nothing when pressed
                        }) {
                            Image(systemName: "arrow.uturn.backward")
                                .themeCircleButton(color: theme.dataTab, textColor: theme.textInverted)
                        }
                        .buttonStyle(PlainButtonStyle())
                        .frame(width: 40)
                        .contentShape(Rectangle())
                        // Remove separate onTapGesture since we're handling it in the Button action
                        .opacity(Int(task.completed) > 0 ? 1.0 : 0.5)
                    }

                    // Task title only (removed date)
                    VStack(alignment: .leading) {
                        Text(task.title ?? "Untitled")
                            .font(.system(size: 20, weight: .medium))
                            .foregroundColor(.primary)
                            .lineLimit(1)
                            .truncationMode(.tail)
                            .padding(.vertical, 4) // Add vertical padding to center text
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)

                    // Enhanced slider-style completion tracker (back to oval shape)
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
                        let circleColor = Int(task.completed) > Int(task.target) ? 
                            theme.dataTab : // Use data tab color for going over target
                            theme.templateTab // Use template tab color for normal progress
                        
                        // Sliding completion counter
                        ZStack {
                            // Circle with appropriate color
                            Circle()
                                .fill(circleColor)
                                .frame(width: circleSize, height: circleSize)
                                .shadow(color: Color.black.opacity(0.3), radius: 2, x: 0, y: 1)
                            
                            // Completion count with larger font
                            Text("\(Int(task.completed))")
                                .font(.system(size: 16, weight: .bold))
                                .foregroundColor(.white)
                        }
                        .offset(x: circleOffset)
                        .animation(.spring(response: 0.4, dampingFraction: 0.7), value: Int(task.completed))
                    }
                    .frame(width: 80, height: 32) // Maintain increased overall size
                }
                .padding(.vertical, 12)
                .padding(.horizontal, 8)
            }
        }
        .buttonStyle(PlainButtonStyle())
        
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
                }
            )
            .padding(.top, 20)
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
        
        // Base colors for task types - use tab colors
        let routineBaseColor = theme.routinesTab
        let taskBaseColor = theme.tasksTab
        
        // Choose base color based on item type
        let baseColor = isRoutine ? routineBaseColor : taskBaseColor
        
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
