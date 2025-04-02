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
        static let taskListChanged = NSNotification.Name("TaskListChanged")
        static let navigateToToday = NSNotification.Name("NavigateToToday")
    }
    
    // Theme colors are now defined in the AppTheme protocol
    // This is kept for backward compatibility during transition
    struct Colors {
        // Deprecated: Use AppTheme instead
        // These will be removed once all views are converted to use the theme system
        @available(*, deprecated, message: "Use theme.routinesTab instead")
        static let routinesTab = Color("InversionGreen")
        
        @available(*, deprecated, message: "Use theme.tasksTab instead")
        static let tasksTab = Color("InversionBlue")
        
        @available(*, deprecated, message: "Use theme.templateTab instead")
        static let templateTab = Color("lighterYellowInversion")
        
        @available(*, deprecated, message: "Use theme.summaryTab instead")
        static let summaryTab = Color(red: 0.7, green: 0.6, blue: 0.5)
        
        @available(*, deprecated, message: "Use theme.summaryTab instead")
        static let summaryTabDark = Color(red: 0.3, green: 0.4, blue: 0.5)
        
        @available(*, deprecated, message: "Use theme.dataTab instead")
        static let dataTab = Color(red: 0.8, green: 0.5, blue: 0.4)
        
        @available(*, deprecated, message: "Use theme.dataTab instead")
        static let dataTabDark = Color(red: 0.2, green: 0.5, blue: 0.6)
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
