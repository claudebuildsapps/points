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
        ZStack(alignment: .bottom) {
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
                        // The blue + button ALWAYS creates a task
                        
                        // First set flag and then introduce a small delay
                        createAsRoutine = false
                        
                        // Using DispatchQueue to ensure state is updated before presenting sheet
                        DispatchQueue.main.async {
                            showCreateTaskSheet = true
                        }
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
    @ObservedObject private var taskControllers = TaskControllers.shared
    
    var body: some View {
        // Using zero spacing to ensure elements touch with no gaps
        VStack(spacing: 0) {
            // Date navigation at the top
            DateNavigationView(onDateChange: { dateEntity in
                self.currentDateEntity = dateEntity
                
                // Update the shared controller with current date entity
                taskControllers.currentDateEntity = dateEntity
                
                if let dateValue = dateEntity.date {
                    self.currentDate = dateValue
                    
                    // Update points display when date changes
                    if let points = dateEntity.points as? NSDecimalNumber {
                        NotificationCenter.default.post(
                            name: Constants.Notifications.updatePointsDisplay,
                            object: nil,
                            userInfo: ["points": points.intValue]
                        )
                    }
                }
            })
            .environment(\.managedObjectContext, context)
            .frame(height: 45) // Further reduced height for compactness
            
            // Compact container with minimal but consistent spacing
            VStack(spacing: 2) { // Add a tiny 2pt gap for visual separation
                // Full-width progress bar with daily target - dropped down by 10px
                ProgressBarView(progress: $progress)
                    .padding(.top, 10) // Drop the entire progress bar down by 10px
                
                // Add the CreateTabsView below the progress bar with minimal spacing
                CreateTabsView()
                    .environment(\.managedObjectContext, context)
                
                // Task list with minimal spacing
                if let dateEntity = currentDateEntity {
                    // Add a tiny bit of padding above task list for visual separation
                    TaskListContainer(
                        dateEntity: dateEntity,
                        onPointsUpdated: { points in
                            // Update points display
                            NotificationCenter.default.post(
                                name: Constants.Notifications.updatePointsDisplay,
                                object: nil,
                                userInfo: ["points": points]
                            )
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
            
            // Update points display
            if let points = dateEntity.points as? NSDecimalNumber {
                NotificationCenter.default.post(
                    name: Constants.Notifications.updatePointsDisplay,
                    object: nil,
                    userInfo: ["points": points.intValue]
                )
            }
        }
    }
}
