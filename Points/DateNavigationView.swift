import SwiftUI
import CoreData

struct CreateTabsView: View {
    @Environment(\.managedObjectContext) private var context
    @Environment(\.theme) private var theme
    @State private var showCreateTaskSheet = false
    @State private var createAsRoutine = false
    @State private var createAsCritical = false
    @ObservedObject private var taskControllers = TaskControllers.shared
    
    var body: some View {
        HStack(spacing: 0) {
            // +Routine tab
            Button(action: {
                createAsRoutine = true
                createAsCritical = false
                showCreateTaskSheet = true
            }) {
                Text("+Routine")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .background(theme.routinesTab)
            }
            
            // +Task tab
            Button(action: {
                createAsRoutine = false
                createAsCritical = false
                showCreateTaskSheet = true
            }) {
                Text("+Task")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .background(theme.tasksTab)
            }
            
            // +Critical tab
            Button(action: {
                createAsRoutine = false
                createAsCritical = true
                showCreateTaskSheet = true
            }) {
                Text("+Critical")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .background(theme.criticalColor)
            }
        }
        .frame(height: 40)
        .sheet(isPresented: $showCreateTaskSheet) {
            TaskFormView(
                mode: .create,
                task: nil,
                isPresented: $showCreateTaskSheet,
                initialIsRoutine: createAsRoutine,
                initialIsCritical: createAsCritical,
                onSave: { values in
                    // Extract values from the form
                    let title = values["title"] as? String ?? (createAsRoutine ? "New Routine" : "New Task")
                    let points = values["points"] as? NSDecimalNumber ?? 
                        NSDecimalNumber(value: createAsRoutine ? 3.0 : Constants.Defaults.taskPoints)
                    let target = values["target"] as? Int16 ?? 3
                    let reward = values["reward"] as? NSDecimalNumber ?? 
                        NSDecimalNumber(value: createAsRoutine ? 1.0 : 0.0)
                    let max = values["max"] as? Int16 ?? 3
                    let isRoutine = values["routine"] as? Bool ?? createAsRoutine
                    let isOptional = values["optional"] as? Bool ?? true
                    let isCritical = values["critical"] as? Bool ?? createAsCritical
                    
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
    }
}

struct DateNavigationView: View {
    @Environment(\.managedObjectContext) private var context
    @Environment(\.theme) private var theme
    @State private var currentDate: Date = Date()
    let onDateChange: (CoreDataDate) -> Void
    
    // Notification token for navigation to today
    @State private var notificationToken: NSObjectProtocol?
    
    // Use a computed property for DateHelper to ensure it uses the current context
    private var dateHelper: DateHelper { DateHelper(context: context) }
    
    var body: some View {
        VStack(spacing: 0) {
            // Date navigation bar
            HStack {
                // Left arrow button
                navigationButton(direction: .backward)
                
                // Date display with formatted date, lighter & larger font
                Text(formattedDate())
                    .font(.headline.weight(.light))
                    .scaleEffect(1.2)
                    .foregroundColor(theme.textPrimary)
                    .frame(maxWidth: .infinity)
                
                // Right arrow button
                navigationButton(direction: .forward)
            }
            .padding(.horizontal)
        }
        .onAppear {
            updateDateEntity()
            
            // Set up notification observer for navigating to today
            notificationToken = NotificationCenter.default.addObserver(
                forName: Constants.Notifications.navigateToToday,
                object: nil,
                queue: .main
            ) { _ in
                navigateToToday()
            }
        }
        .onDisappear {
            // Clean up notification observer
            if let token = notificationToken {
                NotificationCenter.default.removeObserver(token)
            }
        }
        .onChange(of: currentDate) { _ in updateDateEntity() }
    }
    
    // Format date to "Month day number with suffix, year"
    private func formattedDate() -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMMM d, yyyy"
        let baseString = formatter.string(from: currentDate)
        
        let day = Calendar.current.component(.day, from: currentDate)
        let suffix = daySuffix(for: day)
        
        // Replace the day number with day number + suffix
        return baseString.replacingOccurrences(
            of: " \(day),",
            with: " \(day)\(suffix),"
        )
    }
    
    // Get the appropriate suffix for a day number
    private func daySuffix(for day: Int) -> String {
        // Special case for 11th, 12th, 13th
        if day >= 11 && day <= 13 {
            return "th"
        }
        
        switch day % 10 {
        case 1: return "st"
        case 2: return "nd"
        case 3: return "rd"
        default: return "th"
        }
    }
    
    // Helper enum for arrow directions
    private enum Direction { case forward, backward }
    
    // Create a navigation button
    private func navigationButton(direction: Direction) -> some View {
        Button(action: { changeDate(by: direction == .forward ? 1 : -1) }) {
            Image(systemName: direction == .forward ? "chevron.right" : "chevron.left")
                .font(.system(size: 24, weight: .bold))
                .foregroundColor(theme.templateTab)
                .frame(width: 44, height: 44)
        }
    }
    
    // Change the current date
    private func changeDate(by days: Int) {
        if let newDate = Calendar.current.date(byAdding: .day, value: days, to: currentDate) {
            currentDate = newDate
        }
    }
    
    // Update the date entity and notify parent
    private func updateDateEntity() {
        if let dateEntity = dateHelper.getDateEntity(for: currentDate) {
            DispatchQueue.main.async {
                onDateChange(dateEntity)
            }
            dateHelper.ensureTasksExist(for: dateEntity)
        }
    }
    
    // Navigate to today's date with animation
    private func navigateToToday() {
        withAnimation(.easeInOut(duration: Constants.Animation.standard)) {
            currentDate = Date().startOfDay
        }
    }
    
    // Public methods for parent view control
    mutating func setDate(_ date: Date) {
        self.currentDate = date
    }
    
    func getCurrentDate() -> Date {
        return currentDate
    }
}

struct DateNavigationView_Previews: PreviewProvider {
    static var previews: some View {
        Group {
            DateNavigationView(onDateChange: { _ in })
                .environment(\.managedObjectContext, PersistenceController.preview.container.viewContext)
                .environment(\.theme, LightTheme())
                .previewDisplayName("Light Mode")
            
            DateNavigationView(onDateChange: { _ in })
                .environment(\.managedObjectContext, PersistenceController.preview.container.viewContext)
                .environment(\.theme, DarkTheme())
                .preferredColorScheme(.dark)
                .previewDisplayName("Dark Mode")
        }
    }
}
