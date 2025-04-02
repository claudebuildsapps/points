import SwiftUI
import CoreData

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
    
    func addNewTask(isRoutine: Bool = false) {
        guard let taskManager = taskManager, let dateEntity = currentDateEntity else { return }
        taskManager.createTask(
            title: "New Task", 
            points: NSDecimalNumber(value: isRoutine ? 3.0 : Constants.Defaults.taskPoints), 
            target: Int16(Constants.Defaults.taskTarget), 
            date: dateEntity,
            reward: NSDecimalNumber(value: isRoutine ? 1.0 : 0.0),
            routine: isRoutine,
            optional: isRoutine
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
    @ObservedObject private var taskControllers = TaskControllers.shared
    
    // Called when the view appears - this ensures we're using system setting
    private func initializeTheme() {
        // Start with system setting by default
        if themeManager.colorScheme == nil {
            themeManager.updateForSystemColorScheme(systemColorScheme)
        }
    }
    
    var body: some View {
        ZStack(alignment: .bottom) {
            // Main content (fills entire screen except for footer)
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
                    Text("Settings Coming Soon")
                        .font(.largeTitle)
                        .foregroundColor(.secondary)
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
        }
        // Update the theme based on system color scheme when following system settings
        .onChange(of: systemColorScheme) { newColorScheme in
            themeManager.updateForSystemColorScheme(newColorScheme)
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
                    // Handle saving the new task/routine
                    guard let dateEntity = taskControllers.currentDateEntity else { return }
                    
                    // Extract values from the form
                    let title = values["title"] as? String ?? (defaultRoutine ? "New Routine" : "New Task")
                    let points = values["points"] as? NSDecimalNumber ?? 
                        NSDecimalNumber(value: defaultRoutine ? 3.0 : Constants.Defaults.taskPoints)
                    let target = values["target"] as? Int16 ?? 3
                    let reward = values["reward"] as? NSDecimalNumber ?? 
                        NSDecimalNumber(value: defaultRoutine ? 1.0 : 0.0)
                    let max = values["max"] as? Int16 ?? 3
                    // Use the form's actual isRoutine value, with defaultRoutine as fallback
                    let isRoutine = values["routine"] as? Bool ?? defaultRoutine
                    let isOptional = values["optional"] as? Bool ?? true // Always default to optional=true
                    
                    // Create the task using task manager
                    let newTask = taskControllers.taskManager?.createTask(
                        title: title,
                        points: points,
                        target: target,
                        date: dateEntity,
                        reward: reward,
                        max: max,
                        routine: isRoutine,
                        optional: isOptional
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
            .frame(height: 50)
            
            // Custom container to ensure progress bar touches list
            VStack(spacing: 0) {
                // Full-width progress bar with daily target
                ProgressBarView(progress: $progress)
                
                // Task list with absolutely no spacing
                if let dateEntity = currentDateEntity {
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
                    .padding(.top, 0) // Explicitly set top padding to zero
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
