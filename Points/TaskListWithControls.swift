import SwiftUI
import CoreData

struct TaskListWithControls: View {
    @Environment(\.managedObjectContext) private var context
    @ObservedObject var currentDateEntity: CoreDataDate
    var onProgressUpdated: (Float) -> Void
    @State private var totalPoints: Int = 0
    
    // Use a TaskManager instance that uses the environment context
    private var taskManager: TaskManager {
        TaskManager(context: context)
    }
    
    init(currentDateEntity: CoreDataDate, onProgressUpdated: @escaping (Float) -> Void = { _ in }) {
        self.currentDateEntity = currentDateEntity
        self.onProgressUpdated = onProgressUpdated
    }
    
    var body: some View {
        ZStack(alignment: .bottom) {
            // Show task list with the current date entity 
            TaskListContainer(
                dateEntity: currentDateEntity,
                onPointsUpdated: { points in
                    totalPoints = points
                },
                onProgressUpdated: onProgressUpdated
            )
            .environment(\.managedObjectContext, context)
            // Add an ID to force redraw when date entity changes
            .id(currentDateEntity.objectID.uriRepresentation().absoluteString)
            
            // Footer at the bottom with updated layout (dummy implementation for preview)
            // The actual FooterDisplayView is now managed by MainView
            // In a real app, communication would happen via @Environment or parent-child binding
            EmptyView()
        }
    }
    
    private func addNewTask() {
        taskManager.createTask(
            title: "New Task",
            points: NSDecimalNumber(value: Constants.Defaults.taskPoints),
            target: Int16(Constants.Defaults.taskTarget),
            date: currentDateEntity
        )
    }
    
    private func clearTasks() {
        taskManager.clearTasks(for: currentDateEntity)
        
        // Send notification to update points display
        NotificationCenter.default.post(
            name: Constants.Notifications.updatePointsDisplay,
            object: nil,
            userInfo: ["points": 0]
        )
    }
    
    private func softResetTasks() {
        taskManager.resetTaskCompletions(for: currentDateEntity)
        
        // Update the points display
        NotificationCenter.default.post(
            name: Constants.Notifications.updatePointsDisplay, 
            object: nil, 
            userInfo: ["points": 0]
        )
    }
}