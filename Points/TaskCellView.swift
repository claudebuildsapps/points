import SwiftUI
import CoreData

struct TaskCellView: View {
    @Environment(\.managedObjectContext) private var context
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
                    Color.green.opacity(0.35)
                        .allowsHitTesting(false)
                }
                
                // Content row
                HStack(spacing: 8) {
                    // Action buttons
                    HStack(spacing: 5) {
                        // Points indicator
                        Text("\(Int(task.points?.doubleValue ?? 0))")
                            .circleButton(color: Constants.Colors.templateTab)
                            .frame(width: 45)
                        
                        // Edit button
                        Button(action: toggleEditMode) {
                            Image(systemName: "pencil")
                                .circleButton(color: Constants.Colors.summaryTab)
                        }
                        .buttonStyle(PlainButtonStyle())
                        .frame(width: 45)
                        .contentShape(Rectangle())
                        .onTapGesture(perform: toggleEditMode)

                        // Undo button
                        Button(action: handleDecrement) {
                            Image(systemName: "arrow.uturn.backward")
                                .circleButton(color: Constants.Colors.dataTab)
                        }
                        .buttonStyle(PlainButtonStyle())
                        .frame(width: 45)
                        .contentShape(Rectangle())
                        .onTapGesture(perform: handleDecrement)
                        .disabled(Int(task.completed) <= 0)
                        .opacity(Int(task.completed) > 0 ? 1.0 : 0.5)
                    }

                    // Task title and date
                    VStack(alignment: .leading, spacing: 4) {
                        Text(task.title ?? "Untitled")
                            .font(.system(size: 19, weight: .medium))
                            .foregroundColor(Color.gray.opacity(0.8))
                            .lineLimit(1)
                            .truncationMode(.tail)
                        
                        Text(DateHelper.formatDate(task.date?.date))
                            .captionText()
                            .lineLimit(1)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)

                    // Completion counter
                    Text("\(Int(task.completed))/\(Int(task.target))")
                        .circleButton(color: Constants.Colors.tasksTab)
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
    
    // Calculate background color based on completion
    private func backgroundColor() -> Color {
        let completed = Int(task.completed)
        let target = Int(task.target)
        
        if completed >= target {
            return Color.green.opacity(0.3)
        } else if completed > 0 {
            let progress = CGFloat(completed) / CGFloat(target)
            let alpha = 0.05 + (progress * 0.2)
            return Color.green.opacity(alpha)
        } else {
            return Color.clear
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