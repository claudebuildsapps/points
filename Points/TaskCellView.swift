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

                        // Undo button with fixed hit area
                        Button(action: {
                            let previousCompleted = Int(task.completed)
                            onDecrement()
                            // This will animate if completed value changes
                            animateCompletionChange(from: previousCompleted)
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
                    }

                    // Points with Template tab color (blue-purple) - removed decimal and "Points" text
                    ZStack {
                        Circle()
                            .fill(Color(red: 0.6, green: 0.65, blue: 0.75)) // Template tab color (Bluish-purple)
                            .frame(width: 32, height: 32)
                        
                        Text("\(Int(task.points?.doubleValue ?? 0))") // Remove decimal
                            .font(.system(size: 16, weight: .bold))
                            .foregroundColor(.white)
                    }
                    .frame(width: 32, height: 32)

                    // Title only with larger font (20% bigger)
                    Text(task.title ?? "Untitled")
                        .font(.system(size: 19)) // Increased from 16 to 19 (about 20% bigger)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .onTapGesture {
                            // Also increment when tapping on the title
                            let previousCompleted = Int(task.completed)
                            onIncrement()
                            animateCompletionChange(from: previousCompleted)
                        }

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
            }
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
        return formatter.string(from: date)
    }

    private func backgroundColor() -> Color {
        let completed = Int(task.completed)
        let target = Int(task.target)
        if completed >= target {
            return Color.green.opacity(0.3) // Increased opacity for completed tasks
        } else if completed > 0 {
            // Progressive darker green based on completion
            let progress = CGFloat(completed) / CGFloat(target)
            // Start at 0.05 and go up to 0.25 based on progress
            let alpha = 0.05 + (progress * 0.2)
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
