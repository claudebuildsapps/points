import CoreData

class TaskManager {
    private let context: NSManagedObjectContext
    
    init(context: NSManagedObjectContext) {
        self.context = context
    }
    
    func fetchTasks() -> [CoreDataTask] {
        // Use CoreDataTask.fetchRequest() for proper typing
        let fetchRequest: NSFetchRequest<CoreDataTask> = CoreDataTask.fetchRequest()
        fetchRequest.sortDescriptors = [NSSortDescriptor(key: "position", ascending: true)]
        do {
            return try context.fetch(fetchRequest)
        } catch {
            print("Failed to fetch tasks: \(error)")
            return []
        }
    }
    
    func fetchTasks(for date: Date) -> [CoreDataTask] {
        let fetchRequest: NSFetchRequest<CoreDataTask> = CoreDataTask.fetchRequest()
        fetchRequest.sortDescriptors = [NSSortDescriptor(key: "position", ascending: true)]
        
        // Filter tasks by date (assuming CoreDataTask has a 'date' relationship with CoreDataDate)
        let calendar = Calendar.current
        let startOfDay = calendar.startOfDay(for: date)
        let endOfDay = calendar.date(byAdding: .day, value: 1, to: startOfDay)!
        
        fetchRequest.predicate = NSPredicate(format: "date.date >= %@ AND date.date < %@", startOfDay as NSDate, endOfDay as NSDate)
        
        do {
            return try context.fetch(fetchRequest)
        } catch {
            print("Failed to fetch tasks for date \(date): \(error)")
            return []
        }
    }

    func createInitialTasksIfNeeded() {
        if fetchTasks().isEmpty {
            let routines = [("Shower", 10), ("Floss", 5), ("Meditate", 15), ("Exercise", 20), ("Lunch", 8), ("Code", 25)]
            let today = Calendar.current.startOfDay(for: Date())
            
            // First check if we have a CoreDataDate for today
            let fetchRequest: NSFetchRequest<CoreDataDate> = CoreDataDate.fetchRequest()
            fetchRequest.predicate = NSPredicate(format: "date == %@", today as NSDate)
            
            var dateObject: CoreDataDate
            
            do {
                let results = try context.fetch(fetchRequest)
                if let existingDate = results.first {
                    // Use existing date object
                    dateObject = existingDate
                } else {
                    // Create a new date object
                    dateObject = CoreDataDate(context: context)
                    dateObject.date = today
                    dateObject.target = 5
                }
                
                // Now create tasks linked to this date object
                for (title, points) in routines {
                    let task = CoreDataTask(context: context)
                    task.title = title
                    task.target = 5
                    task.points = NSDecimalNumber(value: points)
                    task.completed = 0
                    task.max = 8
                    task.position = Int16(fetchTasks().count)
                    task.routine = true
                    
                    // Link to the existing or newly created date object
                    task.date = dateObject
                }
                
                saveContext()
            } catch {
                print("Error fetching date: \(error)")
            }
        }
    }
    
    func saveContext() {
        do {
            try context.save()
        } catch {
            print("Failed to save context: \(error)")
        }
    }
    
    // Create a template task
    func createTemplateTask(title: String, target: Int16, points: NSDecimalNumber) -> CoreDataTask {
        let task = CoreDataTask(context: context)
        task.title = title
        task.target = target
        task.points = points
        task.completed = 0
        task.max = target // Default max to target, adjust as needed
        task.position = Int16(fetchTasks().count) // Set position based on current count
        task.routine = false
        
        // Set the date (e.g., current date)
        let date = CoreDataDate(context: context)
        date.date = Date()
        date.target = target
        task.date = date
        
        saveContext()
        return task
    }
    
    // Increment task completion
    func incrementTaskCompletion(_ task: CoreDataTask) {
        guard task.completed < task.max else { return }
        task.completed += 1
        saveContext()
    }
    
    // Decrement task completion
    func decrementTaskCompletion(_ task: CoreDataTask) {
        guard task.completed > 0 else { return }
        task.completed -= 1
        saveContext()
    }
    
    // Calculate total points for tasks
    func calculateTotalPoints(_ tasks: [CoreDataTask]) -> Int {
        tasks.reduce(0) { total, task in
            total + (Int(task.points?.intValue ?? 0) * Int(task.completed))
        }
    }
    
    // Create a new task
    func createNewTask(title: String, target: Int16, points: Int, max: Int16) {
        let task = CoreDataTask(context: context)
        task.title = title
        task.target = target
        task.points = NSDecimalNumber(value: points)
        task.completed = 0
        task.max = max
        task.position = Int16(fetchTasks().count)
        task.routine = false
        
        // Set the date (e.g., current date)
        let date = CoreDataDate(context: context)
        date.date = Date()
        date.target = target
        task.date = date
        
        saveContext()
    }
    
    // Delete a task
    func deleteTask(task: CoreDataTask) {
        context.delete(task)
        saveContext()
    }
    
    // Delete all tasks and return success status
    func deleteAllTasks() -> Bool {
        let allTasks = fetchTasks()
        for task in allTasks {
            context.delete(task)
        }
        
        do {
            try context.save()
            return true
        } catch {
            print("Failed to delete all tasks: \(error)")
            return false
        }
    }
    
    // Duplicate tasks
    func duplicateTasks(tasks: [CoreDataTask]) -> [CoreDataTask] {
        var duplicatedTasks: [CoreDataTask] = []
        for task in tasks {
            let newTask = CoreDataTask(context: context)
            newTask.title = task.title
            newTask.points = task.points
            newTask.target = task.target
            newTask.max = task.max
            newTask.completed = 0
            newTask.position = Int16(fetchTasks().count + duplicatedTasks.count)
            newTask.routine = task.routine
            
            // Set the date (e.g., same date as the original task)
            if let originalDate = task.date {
                let date = CoreDataDate(context: context)
                date.date = originalDate.date
                date.target = originalDate.target
                newTask.date = date
            }
            
            duplicatedTasks.append(newTask)
        }
        saveContext()
        return duplicatedTasks
    }
    
    // Set a new position for a task
    func setNewTaskPosition(task: CoreDataTask, position: Int16) {
        task.position = position
        saveContext()
    }
    
    // Add this method to your TaskManager class

    func softReset() -> Bool {
        // If no tasks exist, recreate initial tasks
        if fetchTasks().isEmpty {
            createInitialTasksIfNeeded()
            return true
        }
        
        // Otherwise, reset tasks to their initial state (completed = 0)
        let allTasks = fetchTasks()
        for task in allTasks {
            task.completed = 0
        }
        
        saveContext()
        return true
    }
}

// Extension for CoreDataTask to use apply
extension CoreDataTask {
    func apply(_ closure: (CoreDataTask) -> Void) -> CoreDataTask {
        closure(self)
        return self
    }
}
