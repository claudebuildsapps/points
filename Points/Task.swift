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
            position: Int(coreDataTask.position)
        )
    }
}
