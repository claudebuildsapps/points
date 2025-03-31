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
        // Main container for the cell
        Button(action: {
            // Store previous value for animation
            let previousCompleted = Int(task.completed)
            // Increment the completion count via callback
            onIncrement()
            // Animate the change
            animateCompletionChange(from: previousCompleted)
        }) {
            // Content container with background
            ZStack {
                // Background color with animation
                backgroundColor()
                    .animation(.easeInOut(duration: 0.3), value: task.completed)
                
                // Flash overlay for completion animation
                if flashBackground {
                    Color.green.opacity(0.35)
                        .allowsHitTesting(false)
                }
                
                // Content layer
                VStack(spacing: 0) {
                    // Display mode
                    HStack(spacing: 8) {
                        // Reordered buttons: Points, Pencil, Undo
                        HStack(spacing: 5) {
                            // Points with Template tab color (blue-purple) - first position now
                            ZStack {
                                Circle()
                                    .fill(Color(red: 0.6, green: 0.65, blue: 0.75)) // Template tab color (Bluish-purple)
                                    .frame(width: 32, height: 32)
                                
                                Text("\(Int(task.points?.doubleValue ?? 0))") // Remove decimal
                                    .font(.system(size: 16, weight: .bold))
                                    .foregroundColor(.white)
                            }
                            .frame(width: 32, height: 32)
                            .contentShape(Rectangle().size(width: 45, height: 45))
                            .frame(width: 45)
                            
                            // Edit button with fixed hit area - second position now
                            Button(action: {
                                // Stop propagation to parent
                                withAnimation(.easeInOut(duration: 0.3)) {
                                    isEditMode.toggle()
                                    isExpanded = isEditMode
                                }
                                if !isEditMode {
                                    onCancelEdit()
                                }
                            }) {
                                // Pencil icon in circle with Summary tab color (Orange)
                                ZStack {
                                    Circle()
                                        .fill(Color(red: 0.7, green: 0.6, blue: 0.5)) // Summary tab color
                                        .frame(width: 32, height: 32)
                                    
                                    Image(systemName: "pencil")
                                        .foregroundColor(.white) // White icon for contrast
                                        .font(.system(size: 16))
                                }
                                .frame(width: 32, height: 32)
                                .contentShape(Rectangle().size(width: 45, height: 45))
                            }
                            .buttonStyle(PlainButtonStyle())
                            .frame(width: 45)
                            .contentShape(Rectangle())
                            .onTapGesture {
                                // Ensure tap doesn't propagate to parent
                                withAnimation(.easeInOut(duration: 0.3)) {
                                    isEditMode.toggle()
                                    isExpanded = isEditMode
                                }
                                if !isEditMode {
                                    onCancelEdit()
                                }
                            }

                            // Undo button with fixed hit area - third position now
                            Button(action: {
                                // Only decrement if completed > 0 and stop propagation
                                if Int(task.completed) > 0 {
                                    let previousCompleted = Int(task.completed)
                                    onDecrement()
                                    // This will animate if completed value changes
                                    animateCompletionChange(from: previousCompleted)
                                }
                            }) {
                                // Undo icon in circle with Data tab color (Red)
                                ZStack {
                                    Circle()
                                        .fill(Color(red: 0.8, green: 0.5, blue: 0.4)) // Data tab color
                                        .frame(width: 32, height: 32)
                                    
                                    Image(systemName: "arrow.uturn.backward")
                                        .foregroundColor(.white) // White icon for contrast
                                        .font(.system(size: 14))
                                }
                                .frame(width: 32, height: 32)
                                .contentShape(Rectangle().size(width: 45, height: 45))
                            }
                            .buttonStyle(PlainButtonStyle())
                            .frame(width: 45)
                            .contentShape(Rectangle())
                            .onTapGesture {
                                // Ensure tap doesn't propagate to parent and only decrement if completed > 0
                                if Int(task.completed) > 0 {
                                    let previousCompleted = Int(task.completed)
                                    onDecrement()
                                    // This will animate if completed value changes
                                    animateCompletionChange(from: previousCompleted)
                                }
                            }
                            .disabled(Int(task.completed) <= 0) // Disable if completed is 0
                            .opacity(Int(task.completed) > 0 ? 1.0 : 0.5) // Fade if disabled
                        }

                        // Title and date info for debugging
                        VStack(alignment: .leading, spacing: 4) {
                            Text(task.title ?? "Untitled")
                                .font(.system(size: 19, weight: .medium)) // Increased from 16 to 19 (about 20% bigger)
                                .foregroundColor(Color.gray.opacity(0.8)) // Lightened to a greyish color
                                .lineLimit(1)
                                .truncationMode(.tail)
                            
                            // Debug text showing the date
                            Text(dateString())
                                .font(.system(size: 12))
                                .foregroundColor(.secondary)
                                .lineLimit(1)
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)

                        // Completion counter with Routines tab color (blue)
                        ZStack {
                            Circle()
                                .fill(Color(red: 0.4, green: 0.6, blue: 0.8))  // Routines tab color (Blue)
                                .frame(width: 32, height: 32)
                            
                            Text("\(Int(task.completed))/\(Int(task.target))")
                                .font(.system(size: 14, weight: .bold))
                                .foregroundColor(.white)
                        }
                        .frame(width: 32, height: 32)
                    }
                    .padding(.vertical, 12)
                    .padding(.horizontal, 8)
                }
            }
        }
        .buttonStyle(PlainButtonStyle())
        
        // Replace inline edit with sheet presentation
        .sheet(isPresented: $isExpanded) {
            // When sheet is dismissed without save
            onCancelEdit()
            isEditMode = false
        } content: {
            // Full-screen edit view as a sheet
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
                }
            )
            .padding(.top, 20)
        }
        // No need for expanded height since we're using a sheet
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
        
        // Add object ID for debugging
        let objectID = task.date?.objectID.uriRepresentation().lastPathComponent ?? "unknown"
        return formatter.string(from: date) + " (ID: \(objectID))"
    }

    private func backgroundColor() -> Color {
        let completed = Int(task.completed)
        let target = Int(task.target)
        
        if completed >= target {
            // Fully completed task - more vibrant green
            return Color.green.opacity(0.3)
        } else if completed > 0 {
            // Progressive darker green based on completion percentage
            let progress = CGFloat(completed) / CGFloat(target)
            
            // Start at 0.05 and go up to 0.25 based on progress
            let alpha = 0.05 + (progress * 0.2)
            
            // Return a progressive green color
            return Color.green.opacity(alpha)
        } else {
            // No progress yet
            return Color.clear
        }
    }

    private func completionColor() -> Color {
        let completed = Int(task.completed)
        let target = Int(task.target)
        return completed >= target ? .green : Color(red: 0.4, green: 0.6, blue: 0.8) // Match the Routines tab color
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
}
