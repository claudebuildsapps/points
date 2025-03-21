// GamificationEngine.swift
import Foundation
import CoreData // Add this if CoreDataTask is a Core Data entity

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
    func setConsecutiveBonuses(for task: CoreDataTask, consecutiveDays: Int) -> Decimal {
        // Skip bonus calculations for optional or inactive tasks
        // Note: Adjust this logic based on your CoreDataTask properties
        guard task.routine else { // Assuming routine tasks are the active ones
            return 0
        }
        
        var bonus: Decimal = 0
        
        // Apply consecutive day bonus (capped at maxConsecutiveDayBonus)
        if consecutiveDays > 1 {
            let consecutiveBonus = min(
                Decimal(consecutiveDays - 1) * consecutiveDayMultiplier,
                maxConsecutiveDayBonus
            )
            bonus += consecutiveBonus
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
                let scaledBonus = extraRatio * 0.1 // Assuming a default scalar of 0.1 if not defined
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
        
        // Apply bonus if there is one (1 + 0.2 = 1.2x multiplier for 20% bonus)
        if bonus > 0 {
            points *= (1 + bonus)
        }
        
        // For routine tasks, scale points based on completion
        if task.routine {
            // If task is completed at least to target
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
        
        // Add any fixed reward points (assuming 0 if not defined)
        points += 0 // Adjust if you have a reward property in CoreDataTask
        
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
    
    func calculateProgress(totalPoints: Int, goal: Int) -> Float {
        min(Float(totalPoints) / Float(goal), 1.0)
    }
}
