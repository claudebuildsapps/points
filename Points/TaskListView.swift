import SwiftUI
import CoreData

struct TaskListView: View {
    @FetchRequest var tasks: FetchedResults<CoreDataTask>
    var onDecrement: (CoreDataTask) -> Void
    var onDelete: (CoreDataTask) -> Void
    var onDuplicate: (CoreDataTask) -> Void
    var onSaveEdit: (CoreDataTask, [String: Any]) -> Void
    var onCancelEdit: () -> Void
    var onIncrement: (CoreDataTask) -> Void

    init(tasks: [CoreDataTask], onDecrement: @escaping (CoreDataTask) -> Void, onDelete: @escaping (CoreDataTask) -> Void, onDuplicate: @escaping (CoreDataTask) -> Void, onSaveEdit: @escaping (CoreDataTask, [String: Any]) -> Void, onCancelEdit: @escaping () -> Void, onIncrement: @escaping (CoreDataTask) -> Void) {
        self.onDecrement = onDecrement
        self.onDelete = onDelete
        self.onDuplicate = onDuplicate
        self.onSaveEdit = onSaveEdit
        self.onCancelEdit = onCancelEdit
        self.onIncrement = onIncrement

        // Fetch request will be set up dynamically by the environment
        self._tasks = FetchRequest<CoreDataTask>(
            sortDescriptors: [NSSortDescriptor(keyPath: \CoreDataTask.position, ascending: true)],
            predicate: nil
        )
    }

    var body: some View {
        List(tasks, id: \.self) { task in
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
            .listRowInsets(EdgeInsets())
            .listRowBackground(Color.clear)
        }
        .listStyle(PlainListStyle())
    }
}
