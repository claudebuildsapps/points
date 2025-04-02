// DateHelper.swift
import Foundation
import CoreData

class DateHelper {
    private let context: NSManagedObjectContext
    
    init(context: NSManagedObjectContext) {
        self.context = context
    }
    
    // Create or fetch a date entity for a specific date
    func getDateEntity(for date: Date) -> CoreDataDate? {
        let startOfDay = date.startOfDay
        let endOfDay = Calendar.current.date(byAdding: .day, value: 1, to: startOfDay)!
        
        let fetchRequest: NSFetchRequest<CoreDataDate> = CoreDataDate.fetchRequest()
        fetchRequest.predicate = NSPredicate(format: "date >= %@ AND date < %@", startOfDay as NSDate, endOfDay as NSDate)
        
        do {
            let results = try context.fetch(fetchRequest)
            
            if let existingDate = results.first {
                return existingDate
            } else {
                return createNewDateEntity(for: startOfDay)
            }
        } catch {
            print("Error fetching date entity: \(error)")
            return nil
        }
    }
    
    // Create a new date entity
    private func createNewDateEntity(for date: Date) -> CoreDataDate? {
        let newDate = CoreDataDate(context: context)
        newDate.date = date
        newDate.target = Int16(Constants.Defaults.targetPoints)
        newDate.points = NSDecimalNumber(value: 0.0)
        
        do {
            try context.save()
            return newDate
        } catch {
            print("Error creating new date entity: \(error)")
            return nil
        }
    }
    
    // Get date entity for today
    func getTodayEntity() -> CoreDataDate? {
        return getDateEntity(for: Date())
    }
    
    // Format date for display (e.g., "April 1st, 2025")
    static func formatDate(_ date: Date?, style: DateFormatter.Style = .medium) -> String {
        guard let date = date else { return "Unknown Date" }
        
        if style != .medium {
            let formatter = DateFormatter()
            formatter.dateStyle = style
            return formatter.string(from: date)
        }
        
        // Custom formatting for medium style (April 1st, 2025)
        let formatter = DateFormatter()
        
        // Get month name
        formatter.dateFormat = "MMMM"
        let month = formatter.string(from: date)
        
        // Get day with ordinal suffix
        formatter.dateFormat = "d"
        let day = Int(formatter.string(from: date)) ?? 0
        let ordinalDay = "\(day)\(ordinalSuffix(for: day))"
        
        // Get year
        formatter.dateFormat = "yyyy"
        let year = formatter.string(from: date)
        
        return "\(month) \(ordinalDay), \(year)"
    }
    
    // Helper for ordinal suffix
    private static func ordinalSuffix(for day: Int) -> String {
        let suffix: String
        switch day {
        case 1, 21, 31: suffix = "st"
        case 2, 22: suffix = "nd"
        case 3, 23: suffix = "rd"
        default: suffix = "th"
        }
        return suffix
    }
    
    // Check for tasks on a given date and create from templates if none exist
    func ensureTasksExist(for dateEntity: CoreDataDate) {
        let taskCheck = NSFetchRequest<CoreDataTask>(entityName: "CoreDataTask")
        taskCheck.predicate = NSPredicate(format: "date == %@", dateEntity)
        
        do {
            let taskCount = try context.count(for: taskCheck)
            if taskCount == 0 {
                // Try to apply templates first
                let templateCount = applyTemplatesIfExist(for: dateEntity)
                
                // If no templates exist, create default tasks
                if templateCount == 0 {
                    createFallbackTasks(for: dateEntity)
                }
            }
        } catch {
            print("Error checking for tasks: \(error)")
        }
    }
    
    // Apply template tasks to a date entity
    private func applyTemplatesIfExist(for dateEntity: CoreDataDate) -> Int {
        // Create a TaskManager to handle template operations
        let taskManager = TaskManager(context: context)
        
        // Fetch templates
        let templates = taskManager.fetchTemplateTasks()
        
        if templates.isEmpty {
            return 0
        }
        
        // Apply templates to the date
        var position: Int16 = 0
        for template in templates {
            let instance = CoreDataTask(context: context)
            
            // Copy properties
            instance.title = template.title
            instance.points = template.points
            instance.target = template.target
            instance.max = template.max
            instance.completed = 0
            instance.position = position
            instance.routine = template.routine
            instance.optional = template.optional
            instance.reward = template.reward
            instance.scalar = template.scalar
            instance.template = false
            
            // Set relationships
            instance.date = dateEntity
            instance.source = template
            
            position += 1
        }
        
        try? context.save()
        return templates.count
    }
    
    // Create default fallback tasks when no templates exist
    private func createFallbackTasks(for dateEntity: CoreDataDate) {
        // First task - Meditate
        let task1 = CoreDataTask(context: context)
        task1.title = "Meditate"
        task1.points = NSDecimalNumber(value: Constants.Defaults.taskPoints)
        task1.target = Int16(Constants.Defaults.taskTarget)
        task1.completed = 0
        task1.date = dateEntity
        task1.position = 0
        task1.max = Int16(Constants.Defaults.taskMax)
        
        // Second task - Shower
        let task2 = CoreDataTask(context: context)
        task2.title = "Shower"
        task2.points = NSDecimalNumber(value: Constants.Defaults.taskPoints * 0.8)
        task2.target = 1
        task2.completed = 0
        task2.date = dateEntity
        task2.position = 1
        task2.max = Int16(Constants.Defaults.taskMax)
        
        // Third task - Exercise
        let task3 = CoreDataTask(context: context)
        task3.title = "Exercise"
        task3.points = NSDecimalNumber(value: Constants.Defaults.taskPoints * 1.5)
        task3.target = 1
        task3.completed = 0
        task3.date = dateEntity
        task3.position = 2
        task3.max = Int16(Constants.Defaults.taskMax)
        
        try? context.save()
    }
}