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
        let calendar = Calendar.current
        let startOfDay = calendar.startOfDay(for: date)
        let endOfDay = calendar.date(byAdding: .day, value: 1, to: startOfDay)!
        
        let fetchRequest: NSFetchRequest<CoreDataDate> = CoreDataDate.fetchRequest()
        fetchRequest.predicate = NSPredicate(format: "date >= %@ AND date < %@", startOfDay as NSDate, endOfDay as NSDate)
        
        do {
            let results = try context.fetch(fetchRequest)
            
            if let existingDate = results.first {
                return existingDate
            } else {
                // Create a new date entity
                let newDate = CoreDataDate(context: context)
                newDate.date = startOfDay
                newDate.target = Int16(Constants.Defaults.targetPoints)
                newDate.points = NSDecimalNumber(value: 0.0)
                try context.save()
                return newDate
            }
        } catch {
            print("Error fetching or creating date entity: \(error)")
            return nil
        }
    }
    
    // Get date entity for today
    func getTodayEntity() -> CoreDataDate? {
        return getDateEntity(for: Date())
    }
    
    // Format date for display
    static func formatDate(_ date: Date?, style: DateFormatter.Style = .medium) -> String {
        guard let date = date else { return "Unknown Date" }
        let formatter = DateFormatter()
        formatter.dateStyle = style
        formatter.timeStyle = .none
        return formatter.string(from: date)
    }
    
    // Check for tasks on a given date and create defaults if none exist
    func ensureTasksExist(for dateEntity: CoreDataDate) {
        let taskCheck = NSFetchRequest<CoreDataTask>(entityName: "CoreDataTask")
        taskCheck.predicate = NSPredicate(format: "date == %@", dateEntity)
        
        do {
            let taskCount = try context.count(for: taskCheck)
            
            if taskCount == 0 {
                createDefaultTasks(for: dateEntity)
            }
        } catch {
            print("Error checking for tasks: \(error)")
        }
    }
    
    // Create default tasks for a date entity
    private func createDefaultTasks(for dateEntity: CoreDataDate) {
        // First default task
        let task1 = CoreDataTask(context: context)
        task1.title = "Default 1 (\(DateHelper.formatDate(dateEntity.date)))"
        task1.points = NSDecimalNumber(value: Constants.Defaults.taskPoints)
        task1.target = Int16(Constants.Defaults.taskTarget)
        task1.completed = 0
        task1.date = dateEntity
        task1.position = 0
        task1.max = Int16(Constants.Defaults.taskMax)
        
        // Second default task
        let task2 = CoreDataTask(context: context)
        task2.title = "Default 2 (\(DateHelper.formatDate(dateEntity.date)))"
        task2.points = NSDecimalNumber(value: Constants.Defaults.taskPoints * 2)
        task2.target = Int16(Constants.Defaults.taskTarget - 1)
        task2.completed = 0
        task2.date = dateEntity
        task2.position = 1
        task2.max = Int16(Constants.Defaults.taskMax)
        
        do {
            try context.save()
        } catch {
            print("Error creating default tasks: \(error)")
        }
    }
    
    // Get a specific date by day offset from current date
    func getDate(dayOffset: Int) -> Date {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        if let newDate = calendar.date(byAdding: .day, value: dayOffset, to: today) {
            return newDate
        }
        return today
    }
}