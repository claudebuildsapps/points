import SwiftUI
import CoreData
import Combine

// Define the filter types for tasks
enum TaskFilter {
    case all
    case routines
    case tasks
}

// Task list refresher that listens for changes
class TaskListRefresher: ObservableObject {
    @Published var shouldRefresh: Bool = false
    
    // Task filter state
    @Published var taskFilter: TaskFilter = .all
    
    private var cancellables = Set<AnyCancellable>()
    
    init() {
        // Listen for task list changes using Combine
        NotificationCenter.default.publisher(for: Constants.Notifications.taskListChanged)
            .sink { [weak self] notification in
                // Check if a filter was passed with the notification
                if let userInfo = notification.userInfo,
                   let newFilter = userInfo["filter"] as? TaskFilter {
                    // Update filter directly
                    self?.taskFilter = newFilter
                }
                self?.shouldRefresh = true
            }
            .store(in: &cancellables)
    }
    
    // Toggle filter state for a specific tab
    func toggleFilter(_ filter: TaskFilter) {
        // If the current filter is the same as the one pressed, 
        // toggle back to showing all
        if taskFilter == filter {
            taskFilter = .all
        } else {
            // Otherwise, switch to the selected filter
            taskFilter = filter
        }
    }
}

struct TaskListContainer: View {
    // Add the refresher object
    @StateObject private var refresher = TaskListRefresher()
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
        VStack(spacing: 0) {
            // Filter tabs for Routines and Tasks
            FilterTabBarView(currentFilter: refresher.taskFilter) { filter in
                refresher.toggleFilter(filter)
            }
            
            // Task list view
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
                },
                onMove: { source, destination in
                    moveTask(from: source, to: destination)
                }
            )
        }
        .onAppear {
            loadTasks()
        }
        .onChange(of: dateEntity) { _ in
            loadTasks()
        }
        .id(dateEntity.objectID.uriRepresentation().absoluteString) // Force recreation when date changes
        // Observe the refresher
        .onChange(of: refresher.shouldRefresh) { shouldRefresh in
            if shouldRefresh {
                loadTasks()
                // Reset the flag after refreshing
                refresher.shouldRefresh = false
            }
        }
        .onChange(of: refresher.taskFilter) { _ in
            // Reload tasks when filter changes
            loadTasks()
        }
    }
    
    private func loadTasks() {
        // Fetch tasks manually rather than using FetchRequest
        let fetchRequest: NSFetchRequest<CoreDataTask> = CoreDataTask.fetchRequest()
        fetchRequest.sortDescriptors = [NSSortDescriptor(keyPath: \CoreDataTask.position, ascending: true)]
        
        // Create the base predicate for the date
        var predicateFormat = "date == %@"
        var predicateArgs: [Any] = [dateEntity]
        
        // Add filter predicate based on current filter state
        switch refresher.taskFilter {
        case .routines:
            predicateFormat += " AND routine == %@"
            predicateArgs.append(true)
        case .tasks:
            predicateFormat += " AND routine == %@"
            predicateArgs.append(false)
        case .all:
            // No additional predicate needed for showing all
            break
        }
        
        // Create the predicate with the appropriate format and arguments
        fetchRequest.predicate = NSPredicate(format: predicateFormat, argumentArray: predicateArgs)
        
        do {
            let fetchedTasks = try context.fetch(fetchRequest)
            self.tasks = fetchedTasks
            updatePoints()
        } catch {
            print("Error fetching tasks: \(error)")
            self.tasks = []
        }
    }
    
    // Handle task reordering
    func moveTask(from source: IndexSet, to destination: Int) {
        // Update both the UI list and database positions
        tasks = taskManager.moveTask(from: source, to: destination, in: tasks)
        
        // Ensure we update points and progress after reordering
        updatePoints()
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

// FilterTabBarView - Custom tab bar for filtering tasks/routines
struct FilterTabBarView: View {
    @Environment(\.theme) private var theme
    var currentFilter: TaskFilter
    var onFilterChanged: (TaskFilter) -> Void
    
    var body: some View {
        HStack(spacing: 0) {
            // Routines tab
            Button(action: {
                onFilterChanged(.routines)
            }) {
                Text("Routines")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(theme.textInverted)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .background(
                        // LIGHTER when selected - mixing with white
                        ZStack {
                            theme.routinesTab
                            if currentFilter == .routines {
                                Color.white.opacity(0.3) // Add white overlay = lighter
                            }
                        }
                    )
            }
            
            // Tasks tab
            Button(action: {
                onFilterChanged(.tasks)
            }) {
                Text("Tasks")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(theme.textInverted)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .background(
                        // LIGHTER when selected - mixing with white
                        ZStack {
                            theme.tasksTab
                            if currentFilter == .tasks {
                                Color.white.opacity(0.3) // Add white overlay = lighter
                            }
                        }
                    )
            }
        }
        .frame(height: 36) // Slightly smaller than the main tabs
    }
}