import CoreData

class TaskManager {
    private let context: NSManagedObjectContext
    private let dateHelper: DateHelper
    private let gamificationEngine: GamificationEngine
    
    init(context: NSManagedObjectContext) {
        self.context = context
        self.dateHelper = DateHelper(context: context)
        self.gamificationEngine = GamificationEngine()
    }
    
    // MARK: - Task Operations
    
    func fetchTasks(for date: Date? = nil) -> [CoreDataTask] {
        let fetchRequest = createTaskFetchRequest(sortedBy: "position")
        
        if let date = date {
            // First get the date entity
            if let dateEntity = dateHelper.getDateEntity(for: date) {
                fetchRequest.predicate = NSPredicate(format: "date == %@", dateEntity)
            } else {
                return []
            }
        }
        
        do {
            return try context.fetch(fetchRequest)
        } catch {
            print("Failed to fetch tasks: \(error)")
            return []
        }
    }
    
    func fetchTasks(for dateEntity: CoreDataDate) -> [CoreDataTask] {
        let fetchRequest = createTaskFetchRequest(sortedBy: "position")
        fetchRequest.predicate = NSPredicate(format: "date == %@", dateEntity)
        
        do {
            return try context.fetch(fetchRequest)
        } catch {
            print("Failed to fetch tasks: \(error)")
            return []
        }
    }
    
    // Fetch all template tasks (tasks with no date or explicit template flag)
    func fetchTemplateTasks() -> [CoreDataTask] {
        let fetchRequest = createTaskFetchRequest(sortedBy: "position")
        fetchRequest.predicate = NSPredicate(format: "template == YES OR date == nil")
        
        do {
            let results = try context.fetch(fetchRequest)
            print("TaskManager.fetchTemplateTasks(): Found \(results.count) templates")
            return results
        } catch {
            print("Failed to fetch template tasks: \(error)")
            return []
        }
    }
    
    // Fetch template tasks filtered by type
    func fetchTemplateTasks(routinesOnly: Bool) -> [CoreDataTask] {
        let fetchRequest = createTaskFetchRequest(sortedBy: "position")
        fetchRequest.predicate = NSPredicate(
            format: "(template == YES OR date == nil) AND routine == %@", 
            NSNumber(value: routinesOnly)
        )
        
        do {
            return try context.fetch(fetchRequest)
        } catch {
            print("Failed to fetch filtered template tasks: \(error)")
            return []
        }
    }
    
    // Apply template tasks to a specific date
    func applyTemplatesToDate(_ dateEntity: CoreDataDate) {
        let templates = fetchTemplateTasks()
        
        for template in templates {
            // Create an instance from the template
            let _ = template.createInstanceForDate(dateEntity, context: context)
        }
        
        saveContext()
    }
    
    // Helper to create consistent fetch request
    private func createTaskFetchRequest(sortedBy key: String) -> NSFetchRequest<CoreDataTask> {
        let fetchRequest: NSFetchRequest<CoreDataTask> = CoreDataTask.fetchRequest()
        
        // Sort first by critical (descending to put critical first), then by the specified key
        fetchRequest.sortDescriptors = [
            NSSortDescriptor(key: "critical", ascending: false),
            NSSortDescriptor(key: key, ascending: true)
        ]
        
        return fetchRequest
    }
    
    func createTask(
        title: String,
        points: NSDecimalNumber,
        target: Int16,
        date: CoreDataDate? = nil,
        reward: NSDecimalNumber = NSDecimalNumber(value: 0),
        max: Int16? = nil,
        routine: Bool = false,
        optional: Bool = false,
        template: Bool = false
    ) -> CoreDataTask {
        let task = CoreDataTask(context: context)
        
        // Set basic properties
        task.title = title
        task.points = points
        task.target = target
        task.completed = 0
        task.max = max ?? (target + 2) // Use provided max or default to target + 2
        task.position = Int16(fetchTasks().count)
        task.routine = routine
        task.optional = optional
        task.critical = false // Default to non-critical
        task.reward = reward
        task.template = template
        
        // Associate with date (only if not a template)
        if !template {
            task.date = date ?? dateHelper.getTodayEntity() ?? createFallbackDateEntity()
        }
        
        // Always set the template flag explicitly
        task.template = template
        
        // Debug info
        print("TaskManager: Created \(template ? "template" : "normal") task: \(task.title ?? "nil"), date=\(task.date != nil ? "set" : "nil")")
        
        saveContext()
        return task
    }
    
    // Create a fallback date entity when none exists
    private func createFallbackDateEntity() -> CoreDataDate {
        let today = CoreDataDate(context: context)
        today.date = Date().startOfDay
        today.target = Int16(Constants.Defaults.targetPoints)
        today.points = NSDecimalNumber(value: 0.0)
        return today
    }
    
    // Increment task completion count
    func incrementTaskCompletion(_ task: CoreDataTask) {
        guard task.completed < task.max else { return }
        task.completed += 1
        saveContext()
        updateDatePoints(for: task.date)
    }
    
    // Decrement task completion count
    func decrementTaskCompletion(_ task: CoreDataTask) {
        guard task.completed > 0 else { return }
        task.completed -= 1
        saveContext()
        updateDatePoints(for: task.date)
    }
    
    // Delete a task
    func deleteTask(_ task: CoreDataTask) {
        let dateEntity = task.date
        context.delete(task)
        saveContext()
        updateDatePoints(for: dateEntity)
    }
    
    // Copy a task as a template
    func copyTaskAsTemplate(_ task: CoreDataTask) -> CoreDataTask {
        let template = CoreDataTask(context: context)
        
        // Copy all task properties except completion
        template.title = task.title
        template.points = task.points
        template.target = task.target
        template.max = task.max
        template.completed = 0 // Reset completion for templates
        template.position = Int16(fetchTemplateTasks().count) // Position at end of templates
        template.routine = task.routine
        template.optional = task.optional
        template.reward = task.reward
        template.template = true // Mark explicitly as a template
        template.date = nil // Templates have no date
        
        saveContext()
        
        // Notify that the task list has changed
        NotificationCenter.default.post(
            name: Constants.Notifications.taskListChanged,
            object: nil
        )
        
        return template
    }
    
    // Create duplicate of a task
    func duplicateTask(_ task: CoreDataTask) -> CoreDataTask {
        let newTask = CoreDataTask(context: context)
        
        // Copy all task properties
        newTask.title = task.title
        newTask.points = task.points
        newTask.target = task.target
        newTask.max = task.max
        newTask.completed = 0
        newTask.position = Int16(fetchTasks().count)
        newTask.routine = task.routine
        newTask.critical = task.critical // Copy the critical status
        newTask.optional = task.optional
        newTask.reward = task.reward
        newTask.date = task.date
        
        saveContext()
        return newTask
    }
    
    // Update a task with new values
    func updateTask(_ task: CoreDataTask, with values: [String: Any]) {
        // Apply each value if present
        if let title = values["title"] as? String { task.title = title }
        if let points = values["points"] as? NSDecimalNumber { task.points = points }
        if let target = values["target"] as? Int16 { task.target = target }
        if let max = values["max"] as? Int16 { task.max = max }
        if let reward = values["reward"] as? NSDecimalNumber { task.reward = reward }
        if let routine = values["routine"] as? Bool { task.routine = routine }
        if let optional = values["optional"] as? Bool { task.optional = optional }
        if let critical = values["critical"] as? Bool { task.critical = critical }
        
        saveContext()
        updateDatePoints(for: task.date)
    }
    
    // MARK: - Batch Operations
    
    // Clear all tasks for a date
    func clearTasks(for date: CoreDataDate) {
        let tasks = fetchTasks(for: date)
        
        for task in tasks {
            context.delete(task)
        }
        
        // Reset points
        date.points = NSDecimalNumber(value: 0.0)
        saveContext()
        
        // Ensure progress is updated
        NotificationCenter.default.post(
            name: Constants.Notifications.updatePointsDisplay,
            object: nil,
            userInfo: ["points": 0]
        )
        
        // Notify that the task list has changed for UI updates
        NotificationCenter.default.post(
            name: Constants.Notifications.taskListChanged,
            object: nil
        )
    }
    
    // Reset task completion counts
    func resetTaskCompletions(for date: CoreDataDate) {
        let tasks = fetchTasks(for: date)
        
        for task in tasks {
            task.completed = 0
        }
        
        // Reset points
        date.points = NSDecimalNumber(value: 0.0)
        saveContext()
    }
    
    // MARK: - Points and Calculations
    
    func calculateTotalPoints(for tasks: [CoreDataTask]) -> Int {
        return gamificationEngine.calculateTotalPoints(for: tasks)
    }
    
    // Update the points stored in a date entity
    func updateDatePoints(for date: CoreDataDate?) {
        guard let date = date else { return }
        
        // Fetch tasks for this date
        let tasks = fetchTasks(for: date)
        let totalPoints = calculateTotalPoints(for: tasks)
        
        // Update the date entity
        date.points = NSDecimalNumber(value: totalPoints)
        saveContext()
        
        // Send notification for UI updates
        NotificationCenter.default.postPointsUpdate(totalPoints)
    }
    
    // MARK: - Task Ordering
    
    // Update the positions of tasks after one is moved
    func updateTaskPositions(tasks: [CoreDataTask]) {
        // Reassign positions based on new order
        for (index, task) in tasks.enumerated() {
            task.position = Int16(index)
        }
        
        saveContext()
    }
    
    // Move a task from one position to another
    func moveTask(from source: IndexSet, to destination: Int, in taskList: [CoreDataTask]) -> [CoreDataTask] {
        // Create a mutable copy of the tasks
        var tasks = taskList
        
        // Perform the move operation
        tasks.move(fromOffsets: source, toOffset: destination)
        
        // Update positions in the database
        updateTaskPositions(tasks: tasks)
        
        return tasks
    }
    
    // MARK: - Helpers
    
    func saveContext() {
        do {
            if context.hasChanges {
                try context.save()
            }
        } catch {
            print("Failed to save context: \(error)")
        }
    }
    
    // Calculate progress for a given date
    func calculateProgress(for date: CoreDataDate) -> Float {
        let tasks = fetchTasks(for: date)
        if tasks.isEmpty { return 0 }
        
        let totalPoints = calculateTotalPoints(for: tasks)
        let targetPoints = Int(date.target) * tasks.count
        
        return gamificationEngine.calculateProgress(totalPoints: totalPoints, goal: targetPoints)
    }
    
    // Create default tasks if needed (used during app initialization)
    func createInitialTasksIfNeeded() {
        guard let today = dateHelper.getTodayEntity() else { return }
        dateHelper.ensureTasksExist(for: today)
    }
}