// GamificationEngine.swift
import Foundation

public class GamificationEngine {
    func calculatePoints(for task: Task) -> Int {
        // Convert Decimal to Int safely
        let pointsValue = NSDecimalNumber(decimal: task.points).intValue
        let completionFactor = task.completed >= task.target ? 1.0 : 0.5
        return Int(Double(pointsValue) * completionFactor)
    }
    
    func applyReward(for task: Task) -> Decimal {
        return task.reward
    }
    
    // Add missing methods from ViewController errors
    func setConsecutiveBonuses(for task: Task, consecutiveDays: Int) -> Decimal {
        // Example: Add bonus points for consecutive completions
        let baseBonus = Decimal(consecutiveDays) * 0.1  // 10% bonus per consecutive day
        return min(baseBonus, 1.0)  // Cap at 100% bonus
    }
    
    func calculateProgress(for task: Task) -> Double {
        // Calculate progress as a percentage (0.0 to 1.0)
        guard task.target > 0 else { return 0.0 }
        return Double(task.completed) / Double(task.target)
    }
}
