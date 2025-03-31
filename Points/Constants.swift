//
//  Constants.swift
//  Points
//

import Foundation
import SwiftUI

struct Constants {
    // App-wide notification names
    struct Notifications {
        static let updatePointsDisplay = NSNotification.Name("UpdatePointsDisplay")
    }
    
    // Theme colors 
    struct Colors {
        static let routinesTab = Color(red: 0.5, green: 0.7, blue: 0.6)  // Green
        static let tasksTab = Color(red: 0.4, green: 0.6, blue: 0.8)      // Blue
        static let templateTab = Color(red: 0.6, green: 0.65, blue: 0.75) // Bluish-purple
        static let summaryTab = Color(red: 0.7, green: 0.6, blue: 0.5)    // Orange
        static let dataTab = Color(red: 0.8, green: 0.5, blue: 0.4)       // Red
    }
    
    // Default values
    struct Defaults {
        static let targetPoints = 5
        static let taskPoints = 1.0
        static let taskTarget = 3
        static let taskMax = 8
    }
    
    // Animation durations
    struct Animation {
        static let standard = 0.3
        static let flash = 0.2
    }
}
