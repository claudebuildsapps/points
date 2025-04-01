import SwiftUI
import CoreData

struct TaskListView: View {
    // Tasks to display, now passed directly as an array for easier reuse
    let tasks: [CoreDataTask]
    
    // Callbacks for actions
    var onDecrement: (CoreDataTask) -> Void
    var onDelete: (CoreDataTask) -> Void
    var onDuplicate: (CoreDataTask) -> Void
    var onSaveEdit: (CoreDataTask, [String: Any]) -> Void
    var onCancelEdit: () -> Void
    var onIncrement: (CoreDataTask) -> Void

    var body: some View {
        if tasks.isEmpty {
            Text("No tasks for this day")
                .font(.headline)
                .foregroundColor(.secondary)
                .frame(maxWidth: .infinity, maxHeight: .infinity)
        } else {
            // Use a ScrollView with VStack instead of List to have complete control over spacing
            ScrollView {
                VStack(spacing: 0) {
                    ForEach(tasks, id: \.self) { task in
                        TaskCellView(
                            task: task,
                            onDecrement: {
                                onDecrement(task)
                            },
                            onDelete: {
                                onDelete(task)
                            },
                            onDuplicate: {
                                onDuplicate(task)
                            },
                            onSaveEdit: { updatedValues in
                                onSaveEdit(task, updatedValues)
                            },
                            onCancelEdit: {
                                onCancelEdit()
                            },
                            onIncrement: {
                                onIncrement(task)
                            }
                        )
                    }
                }
                .padding(.top, 0) // Explicitly set top padding to zero
                .padding(.horizontal, 0) // Explicitly set horizontal padding to zero
            }
            .padding(0) // Remove all padding from ScrollView
            .edgesIgnoringSafeArea(.horizontal)
        }
    }
}