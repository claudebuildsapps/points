import SwiftUI
import CoreData

struct MainView: View {
    @Environment(\.managedObjectContext) private var context
    @State private var selectedTab = 0
    
    var body: some View {
        ZStack(alignment: .bottom) {
            // Main content (fills entire screen except for tab bar)
            VStack(spacing: 0) {
                if selectedTab == 0 {
                    TaskNavigationView()
                } else if selectedTab == 1 {
                    Text("Stats Coming Soon")
                        .font(.largeTitle)
                        .foregroundColor(.secondary)
                } else {
                    Text("Settings Coming Soon")
                        .font(.largeTitle)
                        .foregroundColor(.secondary)
                }
                
                Spacer(minLength: 60) // Back to original space for just tab bar
            }
            
            // Tab bar at the bottom (positioned at the bottom edge)
            VStack(spacing: 0) {
                Spacer()
                TabBarView(onTabSelected: { index in
                    selectedTab = index
                })
                .frame(height: 60) // Increase frame height
            }
            .ignoresSafeArea(edges: .bottom) // Extend beyond safe area
        }
    }
}

struct TaskNavigationView: View {
    @Environment(\.managedObjectContext) private var context
    @State private var currentDate = Calendar.current.startOfDay(for: Date())
    
    // Use an optional initially, we'll initialize it in onAppear
    @State private var currentDateEntity: CoreDataDate?
    @State private var progress: Float = 0
    
    var body: some View {
        VStack(spacing: 0) {
            // Date navigation at the top
            DateNavigationView(onDateChange: { dateEntity in
                // Update the current date entity directly
                self.currentDateEntity = dateEntity
                if let dateValue = dateEntity.date {
                    self.currentDate = dateValue
                    
                    // Update points display when date changes
                    if let points = dateEntity.points as? NSDecimalNumber {
                        NotificationCenter.default.post(
                            name: NSNotification.Name("UpdatePointsDisplay"),
                            object: nil,
                            userInfo: ["points": points.intValue]
                        )
                    }
                }
            })
            .frame(height: 50)
            
            // Progress bar - much taller
            ProgressBarView(progress: $progress)
                .frame(height: 18) // 3x taller than original
                .padding(.vertical, 5) // Add some vertical padding
            
            // Task list - handle optional currentDateEntity
            if let dateEntity = currentDateEntity {
                TaskListWithControls(
                    currentDateEntity: dateEntity,
                    onProgressUpdated: { newProgress in
                        // Update the progress binding with animation
                        withAnimation(.easeInOut(duration: 0.3)) {
                            self.progress = newProgress
                        }
                    }
                )
                // Add an ID to force complete redraw when date entity changes
                .id("taskList-\(dateEntity.objectID.uriRepresentation().absoluteString)")
            } else {
                Text("Loading...")
                    .font(.title)
                    .foregroundColor(.secondary)
            }
        }
        .onAppear {
            setupDateNavigation()
        }
    }
    
    private func setupDateNavigation() {
        let today = Calendar.current.startOfDay(for: Date())
        self.currentDate = today
        
        // Let DateNavigationView handle creating the date entity
        let fetchRequest: NSFetchRequest<CoreDataDate> = CoreDataDate.fetchRequest()
        let calendar = Calendar.current
        let dateComponents = calendar.dateComponents([.year, .month, .day], from: today)
        let startOfDay = calendar.date(from: dateComponents)!
        
        let fromDate = startOfDay
        let toDate = calendar.date(byAdding: .day, value: 1, to: startOfDay)!
        
        fetchRequest.predicate = NSPredicate(format: "date >= %@ AND date < %@", fromDate as NSDate, toDate as NSDate)
        
        do {
            let results = try context.fetch(fetchRequest)
            
            var dateEntity: CoreDataDate
            
            if let existingDate = results.first {
                // Use existing date entity
                dateEntity = existingDate
                currentDateEntity = dateEntity
                
                // Check if today already has tasks
                let taskCheck = NSFetchRequest<CoreDataTask>(entityName: "CoreDataTask")
                taskCheck.predicate = NSPredicate(format: "date == %@", dateEntity)
                let taskCount = try context.count(for: taskCheck)
                
                // If there are no tasks for today, create default ones
                if taskCount == 0 {
                    print("No tasks found for today. Creating default tasks.")
                    createDefaultTasks(for: dateEntity)
                }
                
                // Update points display
                if let points = dateEntity.points as? NSDecimalNumber {
                    NotificationCenter.default.post(
                        name: NSNotification.Name("UpdatePointsDisplay"),
                        object: nil,
                        userInfo: ["points": points.intValue]
                    )
                }
            } else {
                // Create a new date entity
                dateEntity = CoreDataDate(context: context)
                dateEntity.date = startOfDay
                dateEntity.target = 5
                dateEntity.points = NSDecimalNumber(value: 0.0)
                
                // Create default tasks for today
                createDefaultTasks(for: dateEntity)
                
                try context.save()
                currentDateEntity = dateEntity
                
                // Initialize with zero points
                NotificationCenter.default.post(
                    name: NSNotification.Name("UpdatePointsDisplay"),
                    object: nil,
                    userInfo: ["points": 0]
                )
            }
            
            // Log the current state of CoreData for debugging
            dumpCoreDataState()
            
        } catch {
            print("Error setting up initial date: \(error)")
        }
    }
    
    private func createDefaultTasks(for dateEntity: CoreDataDate) {
        // Create first default task
        let task1 = CoreDataTask(context: context)
        task1.title = "Default 1 (\(formattedDate(dateEntity.date)))"
        task1.points = NSDecimalNumber(value: 1.0)
        task1.target = 3
        task1.completed = 0
        task1.date = dateEntity
        task1.position = 0
        
        // Create second default task
        let task2 = CoreDataTask(context: context)
        task2.title = "Default 2 (\(formattedDate(dateEntity.date)))"
        task2.points = NSDecimalNumber(value: 2.0)
        task2.target = 2
        task2.completed = 0
        task2.date = dateEntity
        task2.position = 1
        
        print("Created default tasks for date: \(formattedDate(dateEntity.date))")
    }
    
    private func formattedDate(_ date: Date?) -> String {
        guard let date = date else { return "nil" }
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        return formatter.string(from: date)
    }
    
    private func dumpCoreDataState() {
        // Log all dates
        let dateRequest = NSFetchRequest<CoreDataDate>(entityName: "CoreDataDate")
        do {
            let allDates = try context.fetch(dateRequest)
            print("CURRENT CORE DATA STATE:")
            print("=== DATES ===")
            for (index, date) in allDates.enumerated() {
                print("Date \(index): \(formattedDate(date.date)), ID: \(date.objectID.uriRepresentation().absoluteString)")
                
                // Get tasks for this date
                let taskRequest = NSFetchRequest<CoreDataTask>(entityName: "CoreDataTask")
                taskRequest.predicate = NSPredicate(format: "date == %@", date)
                let tasks = try context.fetch(taskRequest)
                
                print("  Tasks (\(tasks.count)):")
                for (taskIndex, task) in tasks.enumerated() {
                    print("    Task \(taskIndex): \(task.title ?? "Untitled"), completed: \(task.completed)/\(task.target)")
                }
            }
            print("==============")
        } catch {
            print("Error fetching all dates: \(error)")
        }
    }
}

struct TaskListWithControls: View {
    @Environment(\.managedObjectContext) private var context
    @ObservedObject var currentDateEntity: CoreDataDate // Make it observed so view updates when date changes
    var onProgressUpdated: (Float) -> Void
    @State private var totalPoints: Int = 0
    
    init(currentDateEntity: CoreDataDate, onProgressUpdated: @escaping (Float) -> Void = { _ in }) {
        self.currentDateEntity = currentDateEntity
        self.onProgressUpdated = onProgressUpdated
        
        print("TaskListWithControls initialized with date: \(currentDateEntity.date?.description ?? "nil"), ID: \(currentDateEntity.objectID.uriRepresentation().absoluteString)")
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
            // Add an ID to force redraw when date entity changes
            .id(currentDateEntity.objectID.uriRepresentation().absoluteString)
            
            // Footer at the bottom with updated layout
            FooterDisplayView(
                onAddButtonTapped: {
                    addNewTask()
                },
                onClearButtonTapped: {
                    clearTasks()
                },
                onSoftResetButtonTapped: {
                    softResetTasks()
                },
                onCreateNewTaskInEditMode: {
                    // Implement if needed
                }
            )
            .frame(height: 44) // Reduced to match new horizontal layout
        }
    }
    
    private func addNewTask() {
        // currentDateEntity is non-optional in this context, so no need for guard
        
        let newTask = CoreDataTask(context: context)
        newTask.title = "New Task"
        newTask.points = NSDecimalNumber(value: 1.0)
        newTask.target = 1
        newTask.completed = 0
        newTask.date = currentDateEntity
        
        // Get count of existing tasks for position
        let fetchRequest: NSFetchRequest<CoreDataTask> = CoreDataTask.fetchRequest()
        fetchRequest.predicate = NSPredicate(format: "date == %@", currentDateEntity)
        
        do {
            let count = try context.count(for: fetchRequest)
            newTask.position = Int16(count)
            try context.save()
        } catch {
            print("Error saving new task: \(error)")
        }
    }
    
    private func clearTasks() {
        // currentDateEntity is non-optional in this context, so no need for guard
        
        let fetchRequest: NSFetchRequest<CoreDataTask> = CoreDataTask.fetchRequest()
        fetchRequest.predicate = NSPredicate(format: "date == %@", currentDateEntity)
        
        do {
            let tasks = try context.fetch(fetchRequest)
            for task in tasks {
                context.delete(task)
            }
            
            // Reset points when clearing tasks
            currentDateEntity.points = NSDecimalNumber(value: 0.0)
            
            try context.save()
            
            // Send notification to update points display
            NotificationCenter.default.post(
                name: NSNotification.Name("UpdatePointsDisplay"),
                object: nil,
                userInfo: ["points": 0]
            )
        } catch {
            print("Error clearing tasks: \(error)")
        }
    }
    
    private func softResetTasks() {
        // currentDateEntity is non-optional in this context, so no need for guard
        
        let fetchRequest: NSFetchRequest<CoreDataTask> = CoreDataTask.fetchRequest()
        fetchRequest.predicate = NSPredicate(format: "date == %@", currentDateEntity)
        
        do {
            let tasks = try context.fetch(fetchRequest)
            for task in tasks {
                task.completed = 0
            }
            
            // Reset points to 0 for the date
            currentDateEntity.points = NSDecimalNumber(value: 0.0)
            
            try context.save()
            
            // Update the footer points display
            updateFooterPoints(0)
        } catch {
            print("Error soft resetting tasks: \(error)")
        }
    }
    
    // Update the points display in the footer
    // This function is no longer needed as we'll use a different approach
    private func updateFooterPoints(_ value: Int) {
        // We'll use a state object and environment object approach instead
        NotificationCenter.default.post(name: NSNotification.Name("UpdatePointsDisplay"), object: nil, userInfo: ["points": value])
    }
}

struct TaskListContainer: View {
    @Environment(\.managedObjectContext) private var context
    @ObservedObject var dateEntity: CoreDataDate // Make it observed so view updates when date changes
    var onPointsUpdated: (Int) -> Void
    var onProgressUpdated: (Float) -> Void
    
    // Custom FetchRequest that will be recreated when dateEntity changes
    private var fetchRequest: FetchRequest<CoreDataTask>
    private var tasks: FetchedResults<CoreDataTask> {
        fetchRequest.wrappedValue
    }
    
    init(dateEntity: CoreDataDate, 
         onPointsUpdated: @escaping (Int) -> Void = { _ in },
         onProgressUpdated: @escaping (Float) -> Void = { _ in }) {
        self.dateEntity = dateEntity
        self.onPointsUpdated = onPointsUpdated
        self.onProgressUpdated = onProgressUpdated
        
        // Debug information
        if let dateValue = dateEntity.date {
            let formatter = DateFormatter()
            formatter.dateStyle = .full
            print("TaskListContainer: INITIALIZING WITH DATE \(formatter.string(from: dateValue))")
            print("TaskListContainer: Date Entity ID: \(dateEntity.objectID.uriRepresentation().absoluteString)")
        }
        
        // Create a more reliable fetch request with objectID comparison
        let objectIDString = dateEntity.objectID.uriRepresentation().absoluteString
        print("TaskListContainer: Creating fetch request with objectID: \(objectIDString)")
        
        // Create the fetch request using core data directly to ensure it's working properly
        self.fetchRequest = FetchRequest(
            entity: CoreDataTask.entity(),
            sortDescriptors: [NSSortDescriptor(keyPath: \CoreDataTask.position, ascending: true)],
            predicate: NSPredicate(format: "date == %@", dateEntity)
        )
    }
    
    // This will be called whenever the view appears or dateEntity changes
    func refreshTasks() {
        DispatchQueue.main.async {
            if let dateValue = self.dateEntity.date {
                let formatter = DateFormatter()
                formatter.dateStyle = .full
                print("TaskListContainer: REFRESHING TASKS FOR \(formatter.string(from: dateValue))")
            }
            
            // Force a context save to ensure relationships are persisted
            do {
                try self.context.save()
            } catch {
                print("Error saving context during refresh: \(error)")
            }
            
            // Manual fetch to double-check results 
            let manualFetch = NSFetchRequest<CoreDataTask>(entityName: "CoreDataTask")
            manualFetch.predicate = NSPredicate(format: "date == %@", self.dateEntity)
            
            do {
                let results = try self.context.fetch(manualFetch)
                print("TaskListContainer: Manual fetch found \(results.count) tasks for date: \(self.dateEntity.date?.description ?? "nil")")
                
                // Print details about each task
                for (index, task) in results.enumerated() {
                    print("  Task \(index): \(task.title ?? "Untitled"), completed: \(task.completed)/\(task.target)")
                }
            } catch {
                print("Error performing manual fetch: \(error)")
            }
        }
    }
    
    var body: some View {
        TaskListView(
            tasks: Array(tasks),
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
            onCancelEdit: { },
            onIncrement: { task in
                incrementTask(task)
            }
        )
        .onAppear {
            // Refresh and update on appear
            refreshTasks() 
            updatePoints()
        }
        .onChange(of: dateEntity) { newValue in
            // Critical: Refresh when date entity changes
            print("TaskListContainer: Date entity changed, refreshing tasks")
            refreshTasks()
            updatePoints()
        }
        .onChange(of: tasks.count) { _ in
            updatePoints()
        }
        // Also update when any task's completed count changes
        .onChange(of: tasks.map { $0.completed }) { _ in
            updatePoints()
        }
        .id(dateEntity.objectID.uriRepresentation().absoluteString) // Force recreation when date changes
    }
    
    private func updatePoints() {
        // Calculate total points from all tasks
        let totalPoints = tasks.reduce(0) { $0 + (Int($1.completed) * Int(truncating: $1.points ?? 0)) }
        
        print("TaskListContainer: Updating points for date \(dateEntity.date?.description ?? "nil"), tasks: \(tasks.count), total points: \(totalPoints)")
        
        // Update dateEntity points value
        dateEntity.points = NSDecimalNumber(value: totalPoints)
        
        // Save the context immediately to ensure persistence
        do {
            try context.save()
            print("TaskListContainer: Successfully saved points: \(totalPoints) to date entity: \(dateEntity.objectID.uriRepresentation().absoluteString)")
        } catch {
            print("Error saving points to date entity: \(error)")
        }
        
        // Notify UI to update
        onPointsUpdated(totalPoints)
        updateProgressBar()
        
        // Send notification to update the points display
        // This is the critical part to ensure the circle shows the correct value
        DispatchQueue.main.async {
            NotificationCenter.default.post(
                name: NSNotification.Name("UpdatePointsDisplay"),
                object: nil,
                userInfo: ["points": totalPoints]
            )
        }
    }
    
    private func updateProgressBar() {
        let totalPoints = tasks.reduce(0) { $0 + (Int($1.completed) * Int(truncating: $1.points ?? 0)) }
        let targetPoints = Int(dateEntity.target) * tasks.count
        let progress = targetPoints > 0 ? Float(totalPoints) / Float(targetPoints) : 0.0
        onProgressUpdated(progress)
    }
    
    private func incrementTask(_ task: CoreDataTask) {
        task.completed += 1
        do {
            try context.save()
            updatePoints()
        } catch {
            print("Error incrementing task: \(error)")
        }
    }
    
    private func decrementTask(_ task: CoreDataTask) {
        if task.completed > 0 {
            task.completed -= 1
            do {
                try context.save()
                updatePoints()
            } catch {
                print("Error decrementing task: \(error)")
            }
        }
    }
    
    private func deleteTask(_ task: CoreDataTask) {
        context.delete(task)
        do {
            try context.save()
            updatePoints()
        } catch {
            print("Error deleting task: \(error)")
        }
    }
    
    private func duplicateTask(_ task: CoreDataTask) {
        let newTask = CoreDataTask(context: context)
        newTask.title = task.title
        newTask.points = task.points
        newTask.target = task.target
        newTask.completed = 0
        newTask.date = dateEntity
        
        newTask.position = Int16(tasks.count)
        
        do {
            try context.save()
            updatePoints()
        } catch {
            print("Error duplicating task: \(error)")
        }
    }
    
    private func saveTaskEdit(task: CoreDataTask, updatedValues: [String: Any]) {
        if let title = updatedValues["title"] as? String {
            task.title = title
        }
        if let points = updatedValues["points"] as? NSDecimalNumber {
            task.points = points
        }
        if let target = updatedValues["target"] as? Int16 {
            task.target = target
        }
        if let reward = updatedValues["reward"] as? NSDecimalNumber {
            task.reward = reward
        }
        if let max = updatedValues["max"] as? Int16 {
            task.max = max
        }
        if let routine = updatedValues["routine"] as? Bool {
            task.routine = routine
        }
        if let optional = updatedValues["optional"] as? Bool {
            task.optional = optional
        }
        
        do {
            try context.save()
            updatePoints()
        } catch {
            print("Error saving task edit: \(error)")
        }
    }
}