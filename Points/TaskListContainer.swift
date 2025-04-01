import SwiftUI
import CoreData

struct TaskListContainer: View {
    @Environment(\.managedObjectContext) private var context
    @ObservedObject var dateEntity: CoreDataDate
    var onPointsUpdated: (Int) -> Void
    var onProgressUpdated: (Float) -> Void
    
    // Use a TaskManager for operations
    private var taskManager: TaskManager {
        TaskManager(context: context)
    }
    
    // State property to hold tasks instead of using FetchRequest directly
    @State private var tasks: [CoreDataTask] = []
    
    init(dateEntity: CoreDataDate, 
         onPointsUpdated: @escaping (Int) -> Void = { _ in },
         onProgressUpdated: @escaping (Float) -> Void = { _ in }) {
        self.dateEntity = dateEntity
        self.onPointsUpdated = onPointsUpdated
        self.onProgressUpdated = onProgressUpdated
    }
    
    var body: some View {
        // Task list view without any spacing at top to ensure it touches progress bar
        TaskListView(
            tasks: tasks,
            onDecrement: { task in
                decrementTask(task)
            },
            onDelete: { task in
                deleteTask(task)
            },
            onDuplicate: { task in
                duplicateTask(task)
            },
            onSaveEdit: { task, updatedValues in
                saveTaskEdit(task: task, updatedValues: updatedValues)
            },
            onCancelEdit: {},
            onIncrement: { task in
                incrementTask(task)
            }
        )
        .onAppear {
            loadTasks()
        }
        .onChange(of: dateEntity) { _ in
            loadTasks()
        }
        .id(dateEntity.objectID.uriRepresentation().absoluteString) // Force recreation when date changes
    }
    
    private func loadTasks() {
        // Fetch tasks manually rather than using FetchRequest
        let fetchRequest: NSFetchRequest<CoreDataTask> = CoreDataTask.fetchRequest()
        fetchRequest.sortDescriptors = [NSSortDescriptor(keyPath: \CoreDataTask.position, ascending: true)]
        fetchRequest.predicate = NSPredicate(format: "date == %@", dateEntity)
        
        do {
            let fetchedTasks = try context.fetch(fetchRequest)
            self.tasks = fetchedTasks
            updatePoints()
        } catch {
            print("Error fetching tasks: \(error)")
            self.tasks = []
        }
    }
    
    private func updatePoints() {
        let totalPoints = taskManager.calculateTotalPoints(for: tasks)
        
        // Update dateEntity points value
        dateEntity.points = NSDecimalNumber(value: totalPoints)
        
        taskManager.saveContext()
        
        // Notify UI to update
        onPointsUpdated(totalPoints)
        updateProgressBar()
        
        // Send notification for footer display
        NotificationCenter.default.postPointsUpdate(totalPoints)
    }
    
    private func updateProgressBar() {
        let progress = taskManager.calculateProgress(for: dateEntity)
        onProgressUpdated(progress)
    }
    
    private func incrementTask(_ task: CoreDataTask) {
        taskManager.incrementTaskCompletion(task)
        loadTasks() // Reload tasks after modification
    }
    
    private func decrementTask(_ task: CoreDataTask) {
        taskManager.decrementTaskCompletion(task)
        loadTasks() // Reload tasks after modification
    }
    
    private func deleteTask(_ task: CoreDataTask) {
        taskManager.deleteTask(task)
        loadTasks() // Reload tasks after modification
    }
    
    private func duplicateTask(_ task: CoreDataTask) {
        taskManager.duplicateTask(task)
        loadTasks() // Reload tasks after modification
    }
    
    private func saveTaskEdit(task: CoreDataTask, updatedValues: [String: Any]) {
        taskManager.updateTask(task, with: updatedValues)
        loadTasks() // Reload tasks after modification
    }
}