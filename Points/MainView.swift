import SwiftUI
import CoreData
import Combine

// Global task manager and date helper - a simple way to access task actions from anywhere
class TaskControllers: ObservableObject {
    static let shared = TaskControllers()
    
    var dateHelper: DateHelper?
    var taskManager: TaskManager?
    var currentDateEntity: CoreDataDate?
    
    func initialize(context: NSManagedObjectContext) {
        dateHelper = DateHelper(context: context)
        taskManager = TaskManager(context: context)
    }
    
    func addNewTask(isRoutine: Bool = false, isCritical: Bool = false) {
        guard let taskManager = taskManager, let dateEntity = currentDateEntity else { return }
        taskManager.createTask(
            title: "New Task", 
            points: NSDecimalNumber(value: isRoutine ? 3.0 : Constants.Defaults.taskPoints), 
            target: Int16(Constants.Defaults.taskTarget), 
            date: dateEntity,
            reward: NSDecimalNumber(value: isRoutine ? 1.0 : 0.0),
            routine: isRoutine,
            optional: isRoutine,
            critical: isCritical
        )
    }
    
    func clearTasks() {
        guard let taskManager = taskManager, let dateEntity = currentDateEntity else { return }
        taskManager.clearTasks(for: dateEntity)
        
        // Send notification to update points display
        NotificationCenter.default.post(
            name: Constants.Notifications.updatePointsDisplay,
            object: nil,
            userInfo: ["points": 0]
        )
    }
    
    func softResetTasks() {
        guard let taskManager = taskManager, let dateEntity = currentDateEntity else { return }
        taskManager.resetTaskCompletions(for: dateEntity)
        
        // Update the points display
        NotificationCenter.default.post(
            name: Constants.Notifications.updatePointsDisplay, 
            object: nil, 
            userInfo: ["points": 0]
        )
    }
    
    func clearAllData() {
        guard let taskManager = taskManager else { return }
        taskManager.clearAllData()
    }
}

struct MainView: View {
    @Environment(\.managedObjectContext) private var context
    @Environment(\.colorScheme) private var systemColorScheme
    @Environment(\.theme) private var theme
    // Initialize with nil to force system setting
    @StateObject private var themeManager = ThemeManager(colorScheme: nil)
    @State private var selectedTab = 0
    @State private var showCreateTaskSheet = false
    @State private var createAsRoutine: Bool = true // CHANGED: Initialize to true by default
    @State private var taskFilter: TaskFilter = .all // Add filter state
    @State private var lastTabSelection = 0 // Track last tab selection to handle filter toggling
    @State private var showDeleteConfirmation = false // Confirmation for deleting all tasks
    @ObservedObject private var taskControllers = TaskControllers.shared
    @ObservedObject private var helpSystem = HelpSystem.shared // Observe help system changes
    
    // Called when the view appears - this ensures we're using system setting
    private func initializeTheme() {
        // Start with system setting by default
        if themeManager.colorScheme == nil {
            themeManager.updateForSystemColorScheme(systemColorScheme)
        }
    }
    
    var body: some View {
        ZStack {
            // Main content that adjusts when help mode is active
            VStack(spacing: 0) {
                // Direct help panel monitoring with compact design
                if helpSystem.isHelpModeActive {
                    HelpModeOverlay()
                        .frame(minHeight: 50, idealHeight: 60, maxHeight: 160) // Reduced height range by ~25%
                        .padding(.horizontal, 8) 
                        .padding(.bottom, 2) // Reduced spacing by 50%
                        .padding(.top, 2) // Reduced spacing by 50%
                        .transition(.move(edge: .top).combined(with: .opacity))
                        .zIndex(90) // High z-index but below button help overlay (100) and quick create button (50)
                }
                
                // Main content (compressed when help mode is active)
                VStack(spacing: 0) {
                if selectedTab == 0 {
                    TaskNavigationView()
                        .environment(\.managedObjectContext, context)
                        .onAppear {
                            // Initialize the task controller when the view appears
                            taskControllers.initialize(context: context)
                        }
                } else if selectedTab == 1 {
                    Text("Stats Coming Soon")
                        .font(.largeTitle)
                        .foregroundColor(.secondary)
                } else if selectedTab == 2 {
                    // Show the Templates view
                    TemplatesView()
                        .environment(\.managedObjectContext, context)
                } else if selectedTab == 4 {
                    // Show the Data Explorer for the Data tab
                    DataExplorerView()
                        .environment(\.managedObjectContext, context)
                } else {
                    Text("Coming Soon")
                        .font(.largeTitle)
                        .foregroundColor(.secondary)
                }
                
                // Create a dynamic spacer that adjusts to the footer height
                GeometryReader { _ in 
                    Color.clear
                }
                .frame(height: 0)
                .padding(.bottom, 86) // Space for footer (44 for buttons + 42 for tabs)
                }
            }
            
            // Create a VStack for the floating + button - always keep visible even in help mode
            VStack {
                Spacer()
                
                // Position the button to be above the footer
                HStack {
                    Spacer() // Push to right
                    
                    // Create Task Button - customized for help mode integration
                    ZStack {
                        // Main button that remains unaffected by help mode
                        Button(action: {
                            // Only trigger when not in help mode
                            if !helpSystem.isHelpModeActive {
                                // Set it to create a regular task
                                self.createAsRoutine = false
                                self.showCreateTaskSheet = true
                            }
                        }) {
                            ZStack {
                                // Background circle with task tab color
                                Circle()
                                    .fill(theme.tasksTab)
                                    .frame(width: 58, height: 58)
                                    .shadow(color: theme.tasksTab.opacity(0.6), radius: 4, x: 0, y: 2)
                                
                                // Plus icon in white
                                Image(systemName: "plus")
                                    .font(.system(size: 30, weight: .medium))
                                    .foregroundColor(.white)
                            }
                        }
                        .buttonStyle(PlainButtonStyle())
                        
                        // Help mode overlay - only shown when in help mode
                        if helpSystem.isHelpModeActive {
                            // Invisible button for help mode that preserves button appearance
                            Button(action: {
                                // This action only triggers in help mode
                                helpSystem.highlightElement("quick-create-task-button")
                            }) {
                                Circle()
                                    .fill(Color.clear)
                                    .frame(width: 62, height: 62) // Slightly larger tap area
                                    .contentShape(Circle())
                            }
                            .buttonStyle(PlainButtonStyle())
                            
                            // Only show highlight when this element is explicitly highlighted
                            if helpSystem.isElementHighlighted("quick-create-task-button") {
                                Circle()
                                    .stroke(Color.blue, lineWidth: 2)
                                    .frame(width: 62, height: 62) // Precisely 4px larger than the 58px button
                            }
                        }
                    }
                    .padding(.trailing, 16)
                    .padding(.bottom, 90) // Position above the footer
                    .overlay(
                        GeometryReader { geo in
                            // This transparent overlay captures the exact button frame
                            Color.clear
                                .onAppear {
                                    // Register this element with the help system when it appears
                                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                                        // Calculate global frame by converting local frame to global coordinates
                                        let frame = geo.frame(in: .global)
                                        // Register with the help system
                                        HelpSystem.shared.registerElement(
                                            id: "quick-create-task-button",
                                            metadata: HelpMetadata(
                                                id: "quick-create-task-button",
                                                title: "Quick Create Task Button",
                                                description: "A convenient way to quickly create a new task.",
                                                usageHints: [
                                                    "Tap to create a regular task immediately",
                                                    "Creates a task for the current day",
                                                    "Same functionality as the +Task button but more accessible",
                                                    "Fill in task details in the form that appears"
                                                ],
                                                importance: .important
                                            ),
                                            frame: frame
                                        )
                                    }
                                }
                        }
                    )
                }
            }
            
            // Form presentation for task creation
            .sheet(isPresented: $showCreateTaskSheet) {
                TaskFormView(
                    mode: .create,
                    task: nil,
                    isPresented: $showCreateTaskSheet,
                    initialIsRoutine: createAsRoutine,
                    initialIsCritical: false,
                    onSave: { values in
                        // Extract values from the form
                        let title = values["title"] as? String ?? (createAsRoutine ? "New Routine" : "New Task")
                        let points = values["points"] as? NSDecimalNumber ?? 
                            NSDecimalNumber(value: createAsRoutine ? 3.0 : Constants.Defaults.taskPoints)
                        let target = values["target"] as? Int16 ?? Int16(Constants.Defaults.taskTarget)
                        let reward = values["reward"] as? NSDecimalNumber ?? 
                            NSDecimalNumber(value: createAsRoutine ? 1.0 : 0.0)
                        let max = values["max"] as? Int16 ?? Int16(Constants.Defaults.taskMax)
                        let isRoutine = values["routine"] as? Bool ?? createAsRoutine
                        let isOptional = values["optional"] as? Bool ?? true
                        let isCritical = values["critical"] as? Bool ?? false
                        
                        // Create the task using task manager
                        let newTask = taskControllers.taskManager?.createTask(
                            title: title,
                            points: points,
                            target: target,
                            date: taskControllers.currentDateEntity,
                            reward: reward,
                            max: max,
                            routine: isRoutine,
                            optional: isOptional,
                            critical: isCritical
                        )
                        
                        // Notify that the task list has changed
                        NotificationCenter.default.post(
                            name: Constants.Notifications.taskListChanged,
                            object: nil,
                            userInfo: ["task": newTask as Any]
                        )
                    },
                    onCancel: {
                        // Just dismiss
                        showCreateTaskSheet = false
                    }
                )
            }
            
            // Footer at the bottom (now includes both buttons and tabs)
            VStack(spacing: 0) {
                Spacer()
                FooterDisplayView(
                    selectedTab: $selectedTab,
                    taskFilter: $taskFilter,  // Pass the filter binding
                    onRoutineButtonTapped: {
                        // The purple + button ALWAYS creates a routine
                        
                        // First set flag and then introduce a small delay
                        createAsRoutine = true
                        
                        // Using DispatchQueue to ensure state is updated before presenting sheet
                        DispatchQueue.main.async {
                            showCreateTaskSheet = true
                        }
                    },
                    onTaskButtonTapped: {
                        // The blue book button now toggles help mode
                        
                        // Post notification to toggle help mode
                        NotificationCenter.default.post(
                            name: Constants.Notifications.toggleHelpMode,
                            object: nil
                        )
                    },
                    onHomeButtonTapped: {
                        // Home button always returns to the main tab and today's date
                        selectedTab = 0 // Switch to main tab
                        
                        // Post notification to navigate to today's date
                        NotificationCenter.default.post(
                            name: Constants.Notifications.navigateToToday,
                            object: nil
                        )
                    },
                    onHelpButtonTapped: {
                        // Show delete confirmation when on main tab or data explorer tab
                        if selectedTab == 0 && taskControllers.currentDateEntity != nil {
                            showDeleteConfirmation = true
                        } else if selectedTab == 4 {
                            // For Data Explorer tab - always show delete confirmation
                            showDeleteConfirmation = true
                        }
                    },
                    onClearButtonTapped: {
                        if selectedTab == 0 {
                            taskControllers.clearTasks()
                        } else {
                            print("Clear button tapped in tab \(selectedTab)")
                        }
                    },
                    onSoftResetButtonTapped: {
                        if selectedTab == 0 {
                            taskControllers.softResetTasks()
                        } else {
                            print("Reset button tapped in tab \(selectedTab)")
                        }
                    },
                    onThemeToggle: {
                        // Toggle between light and dark mode
                        if themeManager.colorScheme == .dark {
                            themeManager.setTheme(.light)
                        } else {
                            themeManager.setTheme(.dark)
                        }
                    },
                    onFilterChanged: { newFilter in
                        taskFilter = newFilter
                        NotificationCenter.default.post(
                            name: Constants.Notifications.taskListChanged,
                            object: nil,
                            userInfo: ["filter": newFilter]
                        )
                    }
                )
            }
            .ignoresSafeArea(edges: .bottom)
        }
        .environment(\.theme, themeManager.currentTheme)
        .preferredColorScheme(themeManager.colorScheme)
        .onAppear {
            // Initialize theme based on system settings
            initializeTheme()
            // Debug current help system state
            print("MainView appeared - Help mode active: \(helpSystem.isHelpModeActive)")
        }
        // Update the theme based on system color scheme when following system settings
        .onChange(of: systemColorScheme) { newColorScheme in
            themeManager.updateForSystemColorScheme(newColorScheme)
        }
        // React to changes in help mode
        .onChange(of: helpSystem.isHelpModeActive) { isActive in
            print("Help mode changed to: \(isActive)")
        }
        // Delete confirmation dialog
        .alert(isPresented: $showDeleteConfirmation) {
            if selectedTab == 4 {
                // Data Explorer tab - full database reset
                return Alert(
                    title: Text("Reset Entire Database"),
                    message: Text("This will delete ALL tasks, routines, templates, and dates from the database. This action CANNOT be undone."),
                    primaryButton: .destructive(Text("Reset Everything")) {
                        // Perform the complete database reset
                        // Call the method on taskManager directly
                        if let taskManager = taskControllers.taskManager {
                            taskManager.clearAllData()
                            
                            // Force refresh of any views that might be showing data
                            NotificationCenter.default.post(
                                name: Constants.Notifications.taskListChanged,
                                object: nil
                            )
                        }
                    },
                    secondaryButton: .cancel(Text("Cancel"))
                )
            } else {
                // Normal date tasks delete
                return Alert(
                    title: Text("Delete All Tasks"),
                    message: Text("This will delete ALL tasks for the current date. This action cannot be undone."),
                    primaryButton: .destructive(Text("Delete")) {
                        // Perform the delete action
                        if selectedTab == 0 && taskControllers.currentDateEntity != nil {
                            taskControllers.clearTasks()
                            
                            // Ensure progress bar is updated
                            NotificationCenter.default.post(
                                name: Constants.Notifications.taskListChanged,
                                object: nil
                            )
                            
                            // Force UI refresh
                            withAnimation(.easeInOut) {
                                // Reset filter to ensure listview updates
                                if taskFilter != .all {
                                    taskFilter = .all
                                }
                            }
                        }
                    },
                    secondaryButton: .cancel(Text("Cancel"))
                )
            }
        }
        // Task/Routine creation sheet
        .sheet(isPresented: $showCreateTaskSheet) {
            // CRITICAL: This flag determines if we're creating a routine or task
            // createAsRoutine = true from routine button (purple + button)
            // createAsRoutine = false from task button (blue + button)
            let defaultRoutine = createAsRoutine
            
            TaskFormView(
                mode: .create,
                task: nil,
                isPresented: $showCreateTaskSheet,
                initialIsRoutine: defaultRoutine, // This controls the form state
                onSave: { values in
                    // Extract values from the form
                    let title = values["title"] as? String ?? (defaultRoutine ? "New Routine" : "New Task")
                    let points = values["points"] as? NSDecimalNumber ?? 
                        NSDecimalNumber(value: defaultRoutine ? 3.0 : Constants.Defaults.taskPoints)
                    let target = values["target"] as? Int16 ?? Int16(Constants.Defaults.taskTarget)
                    let reward = values["reward"] as? NSDecimalNumber ?? 
                        NSDecimalNumber(value: defaultRoutine ? 1.0 : 0.0)
                    let max = values["max"] as? Int16 ?? Int16(Constants.Defaults.taskMax)
                    // Use the form's actual isRoutine value, with defaultRoutine as fallback
                    let isRoutine = values["routine"] as? Bool ?? defaultRoutine
                    let isOptional = values["optional"] as? Bool ?? true
                    
                    // Determine if this is a template task (based on the selected tab)
                    let isTemplate = selectedTab == 2
                    
                    // Only use date entity for non-template tasks
                    let dateEntity = isTemplate ? nil : taskControllers.currentDateEntity
                    
                    // Create the task using task manager
                    let newTask = taskControllers.taskManager?.createTask(
                        title: title,
                        points: points,
                        target: target,
                        date: dateEntity,
                        reward: reward,
                        max: max,
                        routine: isRoutine,
                        optional: isOptional,
                        template: isTemplate
                    )
                    
                    // Notify that the task list has changed
                    NotificationCenter.default.post(
                        name: Constants.Notifications.taskListChanged,
                        object: nil,
                        userInfo: ["task": newTask as Any]
                    )
                },
                onCancel: {
                    // Just dismiss
                    showCreateTaskSheet = false
                }
            )
        }
    }
}

// Theme settings view
struct ThemeSettingsView: View {
    @ObservedObject var themeManager: ThemeManager
    @Environment(\.presentationMode) var presentationMode
    @Environment(\.colorScheme) var systemColorScheme  // Access current system setting
    
    var body: some View {
        NavigationView {
            List {
                Section(header: Text("APPEARANCE")) {
                    Button(action: {
                        themeManager.setTheme(.light)
                    }) {
                        HStack {
                            Text("Light Mode")
                            Spacer()
                            if themeManager.colorScheme == .light {
                                Image(systemName: "checkmark")
                            }
                        }
                    }
                    
                    Button(action: {
                        themeManager.setTheme(.dark)
                    }) {
                        HStack {
                            Text("Dark Mode")
                            Spacer()
                            if themeManager.colorScheme == .dark {
                                Image(systemName: "checkmark")
                            }
                        }
                    }
                    
                    Button(action: {
                        themeManager.useSystemTheme(systemColorScheme)
                    }) {
                        HStack {
                            Text("System Setting")
                            .font(.headline)
                            Spacer()
                            if themeManager.colorScheme == nil {
                                Image(systemName: "checkmark")
                            }
                        }
                    }
                    
                    if themeManager.colorScheme == nil {
                        HStack {
                            Text("Current system setting:")
                            Spacer()
                            Text(systemColorScheme == .dark ? "Dark Mode" : "Light Mode")
                                .foregroundColor(.secondary)
                        }
                        .padding(.leading, 20)
                    }
                }
            }
            .navigationTitle("Theme Settings")
            .navigationBarItems(trailing: Button("Done") {
                presentationMode.wrappedValue.dismiss()
            })
        }
    }
}

struct TaskNavigationView: View {
    @Environment(\.managedObjectContext) private var context
    @Environment(\.theme) private var theme
    @State private var currentDate = Calendar.current.startOfDay(for: Date())
    @State private var currentDateEntity: CoreDataDate?
    @State private var progress: Float = 0
    @State private var forceProgressBarUpdate: UUID = UUID() // Add a state variable to force UI updates
    @State private var showAppMenu = false // State for showing app menu
    
    // Add a separate state for UI display of points that can animate independently
    @State private var displayedPoints: Int = 0
    @State private var actualDatabasePoints: Int = 0
    @State private var isAnimatingPoints: Bool = false
    
    @ObservedObject private var taskControllers = TaskControllers.shared
    @ObservedObject private var helpSystem = HelpSystem.shared // For help system integration
    
    var body: some View {
        // Using zero spacing to ensure elements touch with no gaps
        VStack(spacing: 0) {
            // App header with hamburger menu
            HStack {
                Text("Points")
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundColor(theme.textPrimary)
                
                Spacer()
                
                // Hamburger menu with custom help mode integration
                ZStack {
                    // Main button that maintains its appearance
                    Button(action: {
                        // Only trigger the action if not in help mode
                        if !helpSystem.isHelpModeActive {
                            showAppMenu.toggle()
                        }
                    }) {
                        // Custom stacked hamburger icon with more spacing between lines
                        VStack(spacing: 6) { // Increased spacing between lines
                            ForEach(0..<3) { _ in
                                Rectangle()
                                    .frame(width: 22, height: 2) // Slightly wider and thinner lines
                                    .foregroundColor(theme.textPrimary)
                            }
                        }
                        .padding(.vertical, 8)
                        .padding(.horizontal, 8)
                        .contentShape(Rectangle())
                    }
                    .buttonStyle(PlainButtonStyle())
                    .disabled(helpSystem.isHelpModeActive)
                    
                    // Help mode overlay
                    if helpSystem.isHelpModeActive {
                        // Invisible button for help mode with precisely sized touch area
                        Button(action: {
                            helpSystem.highlightElement("app-menu-button")
                        }) {
                            Rectangle()
                                .fill(Color.white.opacity(0.001))
                                .frame(width: 38, height: 38) // Compact frame matching the button size
                                .contentShape(Rectangle())
                        }
                        .buttonStyle(PlainButtonStyle())
                        .zIndex(100)
                        
                        // Custom highlight when this element is selected
                        if helpSystem.isElementHighlighted("app-menu-button") {
                            Circle()
                                .stroke(Color.blue, lineWidth: 2)
                                .frame(width: 38, height: 38) // Tight circular outline
                                .zIndex(99)
                        }
                    }
                }
                .overlay(
                    GeometryReader { geo in
                        Color.clear
                            .onAppear {
                                helpSystem.registerElement(
                                    id: "app-menu-button",
                                    metadata: HelpMetadata(
                                        id: "app-menu-button",
                                        title: "App Menu",
                                        description: "Opens the app menu with additional options and settings.",
                                        usageHints: [
                                            "Access app settings and preferences",
                                            "Find additional tools and options",
                                            "Quick access to app features"
                                        ],
                                        importance: .informational
                                    ),
                                    frame: geo.frame(in: .global)
                                )
                            }
                    }
                )
            }
            .padding(.horizontal, 16)
            .frame(height: 44) // Increased height for app header
            .background(theme.routinesTab.opacity(0.1)) // Subtle background to distinguish from date nav
            
            // App menu (shown as an actionsheet when hamburger is tapped)
            .actionSheet(isPresented: $showAppMenu) {
                ActionSheet(
                    title: Text("Points Menu"),
                    buttons: [
                        .default(Text("Settings")) {
                            // Settings action (placeholder)
                            print("Settings tapped")
                        },
                        .default(Text("About")) {
                            // About action (placeholder)
                            print("About tapped")
                        },
                        .default(Text("Help")) {
                            // Toggle help mode
                            HelpSystem.shared.toggleHelpMode()
                        },
                        .cancel()
                    ]
                )
            }
            
            // Date navigation below app header
            DateNavigationView(onDateChange: { dateEntity in
                self.currentDateEntity = dateEntity
                
                // Update the shared controller with current date entity
                taskControllers.currentDateEntity = dateEntity
                
                if let dateValue = dateEntity.date {
                    self.currentDate = dateValue
                    
                    // Update points display when date changes - no animation needed for date change
                    if let points = dateEntity.points as? NSDecimalNumber {
                        let pointsValue = points.intValue
                        
                        // Update both actual and displayed points without animation for date change
                        self.actualDatabasePoints = pointsValue
                        self.displayedPoints = pointsValue
                        
                        NotificationCenter.default.post(
                            name: Constants.Notifications.updatePointsDisplay,
                            object: nil,
                            userInfo: [
                                "points": pointsValue,
                                "animationComplete": true
                            ]
                        )
                    }
                }
            })
            .environment(\.managedObjectContext, context)
            .frame(height: 45) // Maintained same height for date navigation
            
            // Compact container with minimal but consistent spacing
            VStack(spacing: 2) { // Add a tiny 2pt gap for visual separation
                // Full-width progress bar with daily target - dropped down by 10px
                ProgressBarView(
                    progress: $progress,
                    actualPoints: displayedPoints, // Use our animated display points
                    dateEntity: currentDateEntity  // Pass the current date entity for target persistence
                )
                .id(forceProgressBarUpdate) // Force view to recreate when points update
                    .padding(.top, 10) // Drop the entire progress bar down by 10px
                
                // CreateTabsView has been removed
                
                // Task list with minimal spacing
                if let dateEntity = currentDateEntity {
                    // Add a tiny bit of padding above task list for visual separation
                    TaskListContainer(
                        dateEntity: dateEntity,
                        onPointsUpdated: { points in
                            // Update actual database points immediately
                            actualDatabasePoints = points
                            
                            // Set a flag that we're animating points
                            isAnimatingPoints = true
                            
                            // Use high priority transaction with faster animation
                            // This prevents any other UI updates from interrupting this animation
                            DispatchQueue.main.async {
                                withAnimation(Animation.easeInOut(duration: 0.5)) {
                                    displayedPoints = points
                                }
                            }
                            
                            // Delay other notifications until after animation is complete, matching animation duration
                            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                                isAnimatingPoints = false
                                
                                // Send notification for other UI components with animation complete flag
                                NotificationCenter.default.post(
                                    name: Constants.Notifications.updatePointsDisplay,
                                    object: nil,
                                    userInfo: [
                                        "points": points,
                                        "animationComplete": true
                                    ]
                                )
                            }
                        },
                        onProgressUpdated: { newProgress in
                            // Update the progress binding with animation
                            withAnimation(.easeInOut(duration: Constants.Animation.standard)) {
                                self.progress = newProgress
                            }
                        }
                    )
                    .padding(.top, 1) // Add minimal padding for visual separation
                }
            }
            
            // Show loading if no date entity
            if currentDateEntity == nil {
                Text("Loading...")
                    .font(.title)
                    .foregroundColor(.secondary)
            }
        }
        .onAppear {
            initializeForToday()
            
            // Listen for points updates to force UI refresh with animation
            NotificationCenter.default.addObserver(forName: Constants.Notifications.updatePointsDisplay, object: nil, queue: .main) { [self] notification in
                // Look for the points value in the notification
                if let userInfo = notification.userInfo,
                   let newPoints = userInfo["points"] as? Int {
                    
                    // Check if animation is complete (this notification is from after animation)
                    let animationComplete = userInfo["animationComplete"] as? Bool ?? false
                    
                    // Only force update if animation is complete - avoid glitches during animation
                    if animationComplete {
                        withAnimation(.spring(response: 0.4, dampingFraction: 0.7)) {
                            forceProgressBarUpdate = UUID()
                        }
                    }
                    
                    // Log the points value to debug
                    print("Received points update notification: \(newPoints) points (animation complete: \(animationComplete))")
                } else {
                    // Fallback if no points value is found
                    forceProgressBarUpdate = UUID()
                }
            }
        }
    }
    
    private func initializeForToday() {
        guard let dateHelper = taskControllers.dateHelper else { return }
        
        if let dateEntity = dateHelper.getTodayEntity() {
            self.currentDateEntity = dateEntity
            self.currentDate = dateEntity.date ?? Date()
            
            // Update the shared controller with current date entity
            taskControllers.currentDateEntity = dateEntity
            
            // Ensure we have tasks for today
            dateHelper.ensureTasksExist(for: dateEntity)
            
            // Update points display - initialize both actual and displayed points
            if let points = dateEntity.points as? NSDecimalNumber {
                let pointsValue = points.intValue
                self.actualDatabasePoints = pointsValue
                self.displayedPoints = pointsValue // No animation on initial load
                
                // Notify other components
                NotificationCenter.default.post(
                    name: Constants.Notifications.updatePointsDisplay,
                    object: nil,
                    userInfo: [
                        "points": pointsValue,
                        "animationComplete": true
                    ]
                )
            }
        }
    }
    
}