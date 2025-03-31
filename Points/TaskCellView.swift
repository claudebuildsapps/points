import SwiftUI
import CoreData

struct TaskCellView: View {
    @Environment(\.managedObjectContext) private var context
    @ObservedObject var task: CoreDataTask
    @State private var isExpanded = false
    @State private var isEditMode = false
    @State private var flashBackground = false

    // Delegate-like callbacks
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
                    .animation(.easeInOut(duration: Constants.Animation.standard), value: task.completed)
                
                // Flash overlay for completion animation
                if flashBackground {
                    Color.green.opacity(0.35)
                        .allowsHitTesting(false)
                }
                
                // Content layer
                VStack(spacing: 0) {
                    // Display mode
                    HStack(spacing: 8) {
                        // Action buttons in a row
                        HStack(spacing: 5) {
                            // Points
                            ZStack {
                                Circle()
                                    .fill(Constants.Colors.templateTab)
                                    .frame(width: 32, height: 32)
                                
                                Text("\(Int(task.points?.doubleValue ?? 0))")
                                    .font(.system(size: 16, weight: .bold))
                                    .foregroundColor(.white)
                            }
                            .frame(width: 32, height: 32)
                            .contentShape(Rectangle().size(width: 45, height: 45))
                            .frame(width: 45)
                            
                            // Edit button
                            Button(action: {
                                // Stop propagation to parent
                                withAnimation(.easeInOut(duration: Constants.Animation.standard)) {
                                    isEditMode.toggle()
                                    isExpanded = isEditMode
                                }
                                if !isEditMode {
                                    onCancelEdit()
                                }
                            }) {
                                // Pencil icon
                                ZStack {
                                    Circle()
                                        .fill(Constants.Colors.summaryTab)
                                        .frame(width: 32, height: 32)
                                    
                                    Image(systemName: "pencil")
                                        .foregroundColor(.white)
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
                                withAnimation(.easeInOut(duration: Constants.Animation.standard)) {
                                    isEditMode.toggle()
                                    isExpanded = isEditMode
                                }
                                if !isEditMode {
                                    onCancelEdit()
                                }
                            }

                            // Undo button
                            Button(action: {
                                // Only decrement if completed > 0 and stop propagation
                                if Int(task.completed) > 0 {
                                    let previousCompleted = Int(task.completed)
                                    onDecrement()
                                    // This will animate if completed value changes
                                    animateCompletionChange(from: previousCompleted)
                                }
                            }) {
                                // Undo icon
                                ZStack {
                                    Circle()
                                        .fill(Constants.Colors.dataTab)
                                        .frame(width: 32, height: 32)
                                    
                                    Image(systemName: "arrow.uturn.backward")
                                        .foregroundColor(.white)
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
                            .disabled(Int(task.completed) <= 0)
                            .opacity(Int(task.completed) > 0 ? 1.0 : 0.5)
                        }

                        // Title and date info for debugging
                        VStack(alignment: .leading, spacing: 4) {
                            Text(task.title ?? "Untitled")
                                .font(.system(size: 19, weight: .medium))
                                .foregroundColor(Color.gray.opacity(0.8))
                                .lineLimit(1)
                                .truncationMode(.tail)
                            
                            // Debug text showing the date
                            Text(dateString())
                                .font(.system(size: 12))
                                .foregroundColor(.secondary)
                                .lineLimit(1)
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)

                        // Completion counter
                        ZStack {
                            Circle()
                                .fill(Constants.Colors.tasksTab)
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
        
        // Edit view presentation
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
        .animation(.easeInOut(duration: Constants.Animation.standard), value: isExpanded)
    }

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
    
    private func dateString() -> String {
        return DateHelper.formatDate(task.date?.date)
    }

    private func backgroundColor() -> Color {
        let completed = Int(task.completed)
        let target = Int(task.target)
        
        if completed >= target {
            // Fully completed task
            return Color.green.opacity(0.3)
        } else if completed > 0 {
            // Progressive darker green based on completion percentage
            let progress = CGFloat(completed) / CGFloat(target)
            let alpha = 0.05 + (progress * 0.2)
            return Color.green.opacity(alpha)
        } else {
            // No progress yet
            return Color.clear
        }
    }

    private func completionColor() -> Color {
        let completed = Int(task.completed)
        let target = Int(task.target)
        return completed >= target ? .green : Constants.Colors.tasksTab
    }
}

extension TaskCellView {
    // Toggle edit mode
    func toggleEditMode(isOn: Bool) {
        withAnimation(.easeInOut(duration: Constants.Animation.standard)) {
            isEditMode = isOn
            isExpanded = isOn
        }
    }
}