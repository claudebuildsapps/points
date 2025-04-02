// Task.swift
import CoreData

public struct Task {
    let title: String
    let points: Decimal
    var completed: Int
    let target: Int
    let max: Int
    var bonus: Decimal
    let reward: Decimal
    let scalar: Decimal
    let routine: Bool
    let optional: Bool
    let active: Bool
    let position: Int
    let template: Bool
    let critical: Bool
    
    static func from(coreDataTask: CoreDataTask) -> Task {
        Task(
            title: coreDataTask.title ?? "",
            points: coreDataTask.points?.decimalValue ?? 0,
            completed: Int(coreDataTask.completed),
            target: Int(coreDataTask.target),
            max: Int(coreDataTask.max),
            bonus: coreDataTask.bonus?.decimalValue ?? 0,
            reward: coreDataTask.reward?.decimalValue ?? 0,
            scalar: coreDataTask.scalar?.decimalValue ?? 1,
            routine: coreDataTask.routine,
            optional: coreDataTask.optional,
            active: coreDataTask.active,
            position: Int(coreDataTask.position),
            template: coreDataTask.template,
            critical: coreDataTask.critical
        )
    }
}

// Extension to help with template tasks
extension CoreDataTask {
    // Check if this is a template task (no date or explicit template flag)
    var isTemplate: Bool {
        return template || date == nil
    }
    
    // Add critical property for dynamic access (compatible with Core Data model)
    // This is needed since we can't directly modify the Core Data model file
    @objc var critical: Bool {
        get {
            // Access the value using key-value coding
            // Default to false if not set (for backward compatibility)
            return (value(forKey: "critical") as? Bool) ?? false
        }
        set {
            // Set the value using key-value coding
            setValue(newValue, forKey: "critical")
        }
    }
    
    // Create a date-specific instance from a template
    func createInstanceForDate(_ dateEntity: CoreDataDate, context: NSManagedObjectContext) -> CoreDataTask {
        let instance = CoreDataTask(context: context)
        
        // Copy all properties
        instance.title = self.title
        instance.points = self.points
        instance.target = self.target
        instance.max = self.max
        instance.completed = 0
        instance.bonus = NSDecimalNumber(value: 0)
        instance.position = Int16(self.position) // Maintain position
        instance.routine = self.routine
        instance.optional = self.optional
        instance.critical = self.critical  // Copy critical status
        instance.reward = self.reward
        instance.scalar = self.scalar
        instance.template = false // This is not a template
        
        // Set relationships
        instance.date = dateEntity
        instance.source = self // Link back to template
        
        return instance
    }
}
