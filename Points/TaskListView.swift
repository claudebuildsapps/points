import SwiftUI
import CoreData

struct TaskListView: View {
    // Tasks to display, now passed directly as an array for easier reuse
    let tasks: [CoreDataTask]
    
    // Callbacks for actions
    var onDecrement: (CoreDataTask) -> Void
    var onDelete: (CoreDataTask) -> Void
    var onDuplicate: (CoreDataTask) -> Void
    var onCopyToTemplate: ((CoreDataTask) -> Void)?
    var onSaveEdit: (CoreDataTask, [String: Any]) -> Void
    var onCancelEdit: () -> Void
    var onIncrement: (CoreDataTask) -> Void
    var onMove: (IndexSet, Int) -> Void

    var body: some View {
        if tasks.isEmpty {
            Text("No tasks for this day")
                .font(.headline)
                .foregroundColor(.secondary)
                .frame(maxWidth: .infinity, maxHeight: .infinity)
        } else {
            // Use a List with .plain style for drag and drop functionality
            List {
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
                        onCopyToTemplate: onCopyToTemplate != nil ? {
                            onCopyToTemplate?(task)
                        } : nil,
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
                    // Remove the default List row styling
                    .listRowInsets(EdgeInsets(top: 0, leading: 0, bottom: 0, trailing: 0))
                    .background(Color(.systemBackground))
                }
                .onMove(perform: onMove) // Enable drag and drop reordering
            }
            .listStyle(PlainListStyle()) // Use plain list style to remove separators and background
            .environment(\.defaultMinListRowHeight, 0)
            .edgesIgnoringSafeArea(.horizontal)
        }
    }
}