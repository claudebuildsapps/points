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
        let fetchRequest: NSFetchRequest<CoreDataTask> = CoreDataTask.fetchRequest()
        fetchRequest.sortDescriptors = [NSSortDescriptor(key: "position", ascending: true)]
        
        if let date = date {
            // Filter by specific date
            let calendar = Calendar.current
            let startOfDay = calendar.startOfDay(for: date)
            let endOfDay = calendar.date(byAdding: .day, value: 1, to: startOfDay)!
            
            // First get the date entity
            let dateFetchRequest: NSFetchRequest<CoreDataDate> = CoreDataDate.fetchRequest()
            dateFetchRequest.predicate = NSPredicate(format: "date >= %@ AND date < %@", startOfDay as NSDate, endOfDay as NSDate)
            
            do {
                let dateResults = try context.fetch(dateFetchRequest)
                if let dateEntity = dateResults.first {
                    fetchRequest.predicate = NSPredicate(format: "date == %@", dateEntity)
                } else {
                    // No date entity for this day
                    return []
                }
            } catch {
                print("Error fetching date entity: \(error)")
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
        let fetchRequest: NSFetchRequest<CoreDataTask> = CoreDataTask.fetchRequest()
        fetchRequest.sortDescriptors = [NSSortDescriptor(key: "position", ascending: true)]
        fetchRequest.predicate = NSPredicate(format: "date == %@", dateEntity)
        
        do {
            return try context.fetch(fetchRequest)
        } catch {
            print("Failed to fetch tasks: \(error)")
            return []
        }
    }
    
    func createTask(title: String, points: NSDecimalNumber, target: Int16, date: CoreDataDate? = nil) -> CoreDataTask {
        let task = CoreDataTask(context: context)
        task.title = title
        task.points = points
        task.target = target
        task.completed = 0
        task.max = target + 2 // Default max slightly above target
        task.position = Int16(fetchTasks().count)
        task.routine = false
        
        // Associate with date
        if let date = date {
            task.date = date
        } else if let today = dateHelper.getTodayEntity() {
            task.date = today
        } else {
            // Create a new date entity for today as fallback
            let today = CoreDataDate(context: context)
            today.date = Calendar.current.startOfDay(for: Date())
            today.target = Int16(Constants.Defaults.targetPoints)
            today.points = NSDecimalNumber(value: 0.0)
            task.date = today
        }
        
        saveContext()
        return task
    }
    
    func incrementTaskCompletion(_ task: CoreDataTask) {
        guard task.completed < task.max else { return }
        task.completed += 1
        saveContext()
        updateDatePoints(for: task.date)
    }
    
    func decrementTaskCompletion(_ task: CoreDataTask) {
        guard task.completed > 0 else { return }
        task.completed -= 1
        saveContext()
        updateDatePoints(for: task.date)
    }
    
    func deleteTask(_ task: CoreDataTask) {
        let dateEntity = task.date
        context.delete(task)
        saveContext()
        updateDatePoints(for: dateEntity)
    }
    
    func duplicateTask(_ task: CoreDataTask) -> CoreDataTask {
        let newTask = CoreDataTask(context: context)
        newTask.title = task.title
        newTask.points = task.points
        newTask.target = task.target
        newTask.max = task.max
        newTask.completed = 0
        newTask.position = Int16(fetchTasks().count)
        newTask.routine = task.routine
        newTask.date = task.date
        
        saveContext()
        return newTask
    }
    
    func updateTask(_ task: CoreDataTask, with values: [String: Any]) {
        if let title = values["title"] as? String {
            task.title = title
        }
        
        if let points = values["points"] as? NSDecimalNumber {
            task.points = points
        }
        
        if let target = values["target"] as? Int16 {
            task.target = target
        }
        
        if let max = values["max"] as? Int16 {
            task.max = max
        }
        
        if let reward = values["reward"] as? NSDecimalNumber {
            task.reward = reward
        }
        
        if let routine = values["routine"] as? Bool {
            task.routine = routine
        }
        
        if let optional = values["optional"] as? Bool {
            task.optional = optional
        }
        
        saveContext()
        updateDatePoints(for: task.date)
    }
    
    // MARK: - Batch Operations
    
    func clearTasks(for date: CoreDataDate) {
        let fetchRequest: NSFetchRequest<CoreDataTask> = CoreDataTask.fetchRequest()
        fetchRequest.predicate = NSPredicate(format: "date == %@", date)
        
        do {
            let tasks = try context.fetch(fetchRequest)
            for task in tasks {
                context.delete(task)
            }
            
            // Reset points
            date.points = NSDecimalNumber(value: 0.0)
            
            saveContext()
        } catch {
            print("Error clearing tasks: \(error)")
        }
    }
    
    func resetTaskCompletions(for date: CoreDataDate) {
        let fetchRequest: NSFetchRequest<CoreDataTask> = CoreDataTask.fetchRequest()
        fetchRequest.predicate = NSPredicate(format: "date == %@", date)
        
        do {
            let tasks = try context.fetch(fetchRequest)
            for task in tasks {
                task.completed = 0
            }
            
            // Reset points
            date.points = NSDecimalNumber(value: 0.0)
            
            saveContext()
        } catch {
            print("Error resetting task completions: \(error)")
        }
    }
    
    // MARK: - Points and Calculations
    
    func calculateTotalPoints(for tasks: [CoreDataTask]) -> Int {
        return gamificationEngine.calculateTotalPoints(for: tasks)
    }
    
    func updateDatePoints(for date: CoreDataDate?) {
        guard let date = date else { return }
        
        // Fetch tasks for this date
        let tasks = fetchTasks(for: date)
        let totalPoints = calculateTotalPoints(for: tasks)
        
        // Update the date entity
        date.points = NSDecimalNumber(value: totalPoints)
        saveContext()
        
        // Send notification for UI updates
        NotificationCenter.default.post(
            name: Constants.Notifications.updatePointsDisplay,
            object: nil,
            userInfo: ["points": totalPoints]
        )
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
        if tasks.isEmpty {
            return 0
        }
        
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