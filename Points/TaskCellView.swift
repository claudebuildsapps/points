import SwiftUI
import CoreData

struct TaskCellView: View {
    @Environment(\.managedObjectContext) private var context
    @ObservedObject var task: CoreDataTask
    @State private var isExpanded = false
    @State private var isEditMode = false
    @State private var flashBackground = false

    // Delegate-like callbacks (we'll use closures instead of a delegate)
    var onDecrement: () -> Void
    var onDelete: () -> Void
    var onDuplicate: () -> Void
    var onSaveEdit: ([String: Any]) -> Void
    var onCancelEdit: () -> Void
    var onIncrement: () -> Void

    var body: some View {
        ZStack {
            // Background color with animation
            backgroundColor()
                .animation(.easeInOut(duration: 0.3), value: task.completed)
            
            // Flash overlay for completion animation
            if flashBackground {
                Color.green.opacity(0.35)
                    .allowsHitTesting(false)
            }
            
            // Content layers
            VStack(spacing: 0) {
                // Display mode
                // Display mode
                HStack {
                    // Edit and Undo buttons
                    HStack(spacing: 5) {
                        // Edit button with fixed hit area
                        Button(action: {
                            withAnimation(.easeInOut(duration: 0.3)) {
                                isEditMode.toggle()
                                isExpanded = isEditMode
                            }
                            if !isEditMode {
                                onCancelEdit()
                            }
                        }) {
                            // Use contentShape to explicitly define the hit area
                            Image(systemName: "pencil")
                                .foregroundColor(isEditMode ? .yellow : .gray)
                                .frame(width: 30, height: 30)
                                .contentShape(Rectangle().size(width: 45, height: 45))
                        }
                        .buttonStyle(PlainButtonStyle())
                        .frame(width: 45)

                        // Undo button with fixed hit area
                        Button(action: {
                            let previousCompleted = Int(task.completed)
                            onDecrement()
                            // This will animate if completed value changes
                            animateCompletionChange(from: previousCompleted)
                        }) {
                            Image(systemName: "arrow.uturn.backward")
                                .foregroundColor(.gray)
                                .frame(width: 30, height: 30)
                                .contentShape(Rectangle().size(width: 45, height: 45))
                        }
                        .buttonStyle(PlainButtonStyle())
                        .frame(width: 45)
                    }

                    // Points
                    VStack(spacing: -2) {
                        Text(String(format: "%.1f", task.points?.doubleValue ?? 0))
                            .font(.system(size: 16, weight: .bold))
                            .foregroundColor(.primary)
                            .frame(width: 50)
                        Text("Points")
                            .font(.system(size: 11))
                            .foregroundColor(.gray)
                            .frame(width: 50)
                    }

                    // Title and Date
                    VStack(alignment: .leading, spacing: 2) {
                        Text(task.title ?? "Untitled")
                            .font(.system(size: 16))
                        Text(dateString())
                            .font(.system(size: 11))
                            .foregroundColor(.gray)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)

                    // Completion
                    VStack(spacing: -2) {
                        Text("\(Int(task.completed))/\(Int(task.target))")
                            .font(.system(size: 16, weight: .bold))
                            .foregroundColor(completionColor())
                            .frame(width: 45)
                            .onTapGesture {
                                let previousCompleted = Int(task.completed)
                                onIncrement() // Tap to increment completion
                                // This will animate if completed value changes
                                animateCompletionChange(from: previousCompleted)
                            }
                        Text("Target")
                            .font(.system(size: 11))
                            .foregroundColor(.gray)
                            .frame(width: 45)
                    }
                }
                .padding(.vertical, 12)
                .padding(.horizontal, 8)
                
                // Edit view (when expanded)
                if isExpanded {
                    EditTaskView(
                        task: task,
                        isExpanded: $isExpanded,
                        isEditMode: $isEditMode,
                        onSave: { updatedValues in
                            withAnimation(.easeInOut(duration: 0.3)) {
                                onSaveEdit(updatedValues)
                                isExpanded = false
                                isEditMode = false
                            }
                        },
                        onCancel: {
                            withAnimation(.easeInOut(duration: 0.3)) {
                                onCancelEdit()
                                isExpanded = false
                                isEditMode = false
                            }
                        }
                    )
                    .background(Color(UIColor.systemBackground))
                    .transition(.opacity)
                }
            }
        }
        .frame(height: isExpanded ? 300 : nil) // Adjust height for edit mode
        .animation(.easeInOut(duration: 0.3), value: isExpanded) // Animate height changes
    }

    // Add this function inside your TaskCellView struct
    private func animateCompletionChange(from previousCompleted: Int) {
        let currentCompleted = Int(task.completed)
        
        if currentCompleted != previousCompleted {
            withAnimation(.easeInOut(duration: 0.2)) {
                flashBackground = true
            }
            
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                withAnimation(.easeInOut(duration: 0.3)) {
                    self.flashBackground = false
                }
            }
        }
    }
    private func dateString() -> String {
        guard let date = task.date?.date else { return "No date" }
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .none
        return formatter.string(from: date)
    }

    private func backgroundColor() -> Color {
        let completed = Int(task.completed)
        let target = Int(task.target)
        if completed >= target {
            return Color.green.opacity(0.2)
        } else if completed > 0 {
            let progress = CGFloat(completed) / CGFloat(target)
            let alpha = 0.03 + (progress * 0.15)
            return Color.green.opacity(alpha)
        } else {
            return Color.clear
        }
    }

    private func completionColor() -> Color {
        let completed = Int(task.completed)
        let target = Int(task.target)
        return completed >= target ? .green : .blue
    }
    
    private func animateCompletionChange() {
        withAnimation(.easeInOut(duration: 0.2)) {
            flashBackground = true
        }
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
            withAnimation(.easeInOut(duration: 0.3)) {
                flashBackground = false
            }
        }
    }
}

extension TaskCellView {
    // This function recreates the animation from your UIKit implementation
    func toggleEditMode(isOn: Bool) {
        withAnimation(.easeInOut(duration: 0.3)) {
            isEditMode = isOn
            isExpanded = isOn
        }
    }
    
    // This adds a nice animation for the background color change
    func updateBackgroundColor() -> Color {
        let completed = Int(task.completed)
        let target = Int(task.target)
        
        if completed >= target {
            return Color.green.opacity(0.2)
        } else if completed > 0 {
            let progress = CGFloat(completed) / CGFloat(target)
            let alpha = 0.03 + (progress * 0.15)
            return Color.green.opacity(alpha)
        } else {
            return Color.clear
        }
    }
    
    // Simplified animation without state variables
    func animateCompletion(previousCompleted: Int) {
        let completedValue = Int(task.completed)
        
        if completedValue > previousCompleted {
            // Use the animation without state changes
            // You'll need to implement this inside your view directly
            print("Task completion increased from \(previousCompleted) to \(completedValue)")
        }
    }
}
