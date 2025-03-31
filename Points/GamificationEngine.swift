// GamificationEngine.swift
import Foundation
import CoreData

class GamificationEngine {
    // MARK: - Constants
    private let consecutiveDayMultiplier: Decimal = 0.1       // 10% bonus per consecutive day
    private let maxConsecutiveDayBonus: Decimal = 1.0         // Maximum 100% bonus
    private let targetCompletionMultiplier: Decimal = 0.2     // 20% bonus for meeting target
    
    // MARK: - Public Methods
    
    /// Calculate consecutive day bonuses for a task
    /// - Parameters:
    ///   - task: The task to calculate bonuses for
    ///   - consecutiveDays: Number of consecutive days tasks have been completed
    /// - Returns: The bonus multiplier (e.g., 0.2 for 20%)
    func calculateBonuses(for task: CoreDataTask, consecutiveDays: Int) -> Decimal {
        // Skip bonus calculations for optional or inactive tasks
        guard task.routine else { 
            return 0
        }
        
        var bonus: Decimal = 0
        
        // Apply consecutive day bonus 
        if consecutiveDays > 1 {
            bonus += calculateStreakBonus(consecutiveDays: consecutiveDays)
        }
        
        // For routine tasks, apply additional bonuses
        if task.routine {
            // Apply bonus if target is reached
            if task.completed >= task.target {
                bonus += targetCompletionMultiplier
            }
            
            // Apply scaled bonus based on completion percentage for exceeding target
            if task.completed > task.target && task.max > task.target {
                let extraCompleted = Int(task.completed) - Int(task.target)
                let maxExtra = Int(task.max) - Int(task.target)
                let extraRatio = Decimal(extraCompleted) / Decimal(maxExtra)
                let scaledBonus = extraRatio * 0.1
                bonus += scaledBonus
            }
        }
        
        return bonus
    }
    
    /// Calculate points earned for a task
    /// - Parameters:
    ///   - task: The task to calculate points for
    ///   - bonus: Any bonus multiplier to apply
    /// - Returns: Total points earned
    func calculatePoints(for task: CoreDataTask, withBonus bonus: Decimal = 0) -> Decimal {
        // Base points
        var points = Decimal(task.points?.doubleValue ?? 0)
        
        // Apply bonus if there is one
        if bonus > 0 {
            points *= (1 + bonus)
        }
        
        if task.routine {
            // Routine tasks get scaled based on completion
            if task.completed >= task.target {
                // Calculate completion ratio (capped at max)
                let completionRatio = min(
                    Decimal(task.completed) / Decimal(task.target),
                    Decimal(task.max) / Decimal(task.target)
                )
                points *= completionRatio
            } else {
                // Partial credit for partial completion
                points *= Decimal(task.completed) / Decimal(task.target)
            }
        } else {
            // Non-routine tasks are all-or-nothing
            if task.completed < task.target {
                points = 0
            }
        }
        
        // Add any fixed reward points
        if let reward = task.reward?.decimalValue {
            points += reward
        }
        
        return points
    }
    
    /// Calculate streak bonus percentage
    /// - Parameter consecutiveDays: Number of consecutive days
    /// - Returns: Bonus percentage as decimal (0.1 = 10%)
    func calculateStreakBonus(consecutiveDays: Int) -> Decimal {
        guard consecutiveDays > 1 else {
            return 0
        }
        
        return min(
            Decimal(consecutiveDays - 1) * consecutiveDayMultiplier,
            maxConsecutiveDayBonus
        )
    }
    
    /// Calculate progress toward goal
    /// - Parameters:
    ///   - totalPoints: Current points earned
    ///   - goal: Target points
    /// - Returns: Progress as a Float between 0 and 1
    func calculateProgress(totalPoints: Int, goal: Int) -> Float {
        guard goal > 0 else { return 0 }
        return min(Float(totalPoints) / Float(goal), 1.0)
    }
    
    /// Calculate total points for a collection of tasks
    /// - Parameter tasks: Array of tasks to calculate points for
    /// - Returns: Total points as an integer
    func calculateTotalPoints(for tasks: [CoreDataTask]) -> Int {
        let total = tasks.reduce(0) { total, task in
            let basePoints = Int(task.completed) * Int(truncating: task.points ?? 0)
            return total + basePoints
        }
        return total
    }
}