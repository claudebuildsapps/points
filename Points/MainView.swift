import SwiftUI
import CoreData

struct MainView: View {
    @Environment(\.managedObjectContext) private var context
    @State private var selectedTab = 0
    
    var body: some View {
        ZStack(alignment: .bottom) {
            // Main content (fills entire screen except for tab bar)
            VStack(spacing: 0) {
                if selectedTab == 0 {
                    TaskNavigationView()
                } else if selectedTab == 1 {
                    Text("Stats Coming Soon")
                        .font(.largeTitle)
                        .foregroundColor(.secondary)
                } else {
                    Text("Settings Coming Soon")
                        .font(.largeTitle)
                        .foregroundColor(.secondary)
                }
                
                Spacer(minLength: 60) // Reserve space for tab bar
            }
            
            // Tab bar at the bottom (positioned at the bottom edge)
            VStack(spacing: 0) {
                Spacer()
                TabBarView(onTabSelected: { index in
                    selectedTab = index
                })
                .frame(height: 60) // Increase frame height
            }
            .ignoresSafeArea(edges: .bottom) // Extend beyond safe area
        }
    }
}

struct TaskNavigationView: View {
    @Environment(\.managedObjectContext) private var context
    @State private var currentDate = Calendar.current.startOfDay(for: Date())
    @State private var currentDateEntity: CoreDataDate?
    @State private var progress: Float = 0
    
    var body: some View {
        VStack(spacing: 0) {
            // Date navigation at the top
            DateNavigationView(onDateChange: { dateObject in
                if let dateValue = dateObject as? Date {
                    dateDidChange(to: dateValue)
                } else if let dateEntity = dateObject as? CoreDataDate, let dateValue = dateEntity.date {
                    dateDidChange(to: dateValue)
                }
            })
            .frame(height: 50)
            
            // Progress bar - much taller
            ProgressBarView(progress: $progress)
                .frame(height: 18) // 3x taller than original
                .padding(.vertical, 5) // Add some vertical padding
            
            // Task list
            TaskListWithControls(
                currentDateEntity: currentDateEntity,
                onProgressUpdated: { newProgress in
                    // Update the progress binding with animation
                    withAnimation(.easeInOut(duration: 0.3)) {
                        self.progress = newProgress
                    }
                }
            )
        }
        .onAppear {
            setupDateNavigation()
        }
    }
    
    private func setupDateNavigation() {
        let today = Calendar.current.startOfDay(for: Date())
        self.currentDate = today
        fetchOrCreateDateEntity(for: today)
    }
    
    private func dateDidChange(to date: Date) {
        self.currentDate = date
        fetchOrCreateDateEntity(for: date)
    }
    
    private func fetchOrCreateDateEntity(for date: Date) {
        var calendar = Calendar.current
        calendar.timeZone = TimeZone(identifier: "UTC")!
        let dateComponents = calendar.dateComponents([.year, .month, .day], from: date)
        let startOfDay = calendar.date(from: dateComponents)!
        
        let fromDate = startOfDay
        let toDate = calendar.date(byAdding: .day, value: 1, to: startOfDay)!
        
        let datePredicate = NSPredicate(format: "date >= %@ AND date < %@", fromDate as NSDate, toDate as NSDate)
        
        let fetchRequest: NSFetchRequest<CoreDataDate> = CoreDataDate.fetchRequest()
        fetchRequest.predicate = datePredicate
        fetchRequest.sortDescriptors = [NSSortDescriptor(keyPath: \CoreDataDate.date, ascending: true)]
        
        do {
            let results = try context.fetch(fetchRequest)
            
            if let existingDate = results.first {
                currentDateEntity = existingDate
            } else {
                let newDateEntity = CoreDataDate(context: context)
                newDateEntity.date = startOfDay
                newDateEntity.target = 5
                try context.save()
                currentDateEntity = newDateEntity
            }
        } catch {
            print("Error fetching or creating date entity: \(error)")
        }
    }
}

struct TaskListWithControls: View {
    @Environment(\.managedObjectContext) private var context
    var currentDateEntity: CoreDataDate?
    var onProgressUpdated: (Float) -> Void
    @State private var totalPoints: Int = 0
    
    init(currentDateEntity: CoreDataDate?, onProgressUpdated: @escaping (Float) -> Void = { _ in }) {
        self.currentDateEntity = currentDateEntity
        self.onProgressUpdated = onProgressUpdated
    }
    
    var body: some View {
        ZStack(alignment: .bottom) {
            // Show task list if we have a date
            if let dateEntity = currentDateEntity {
                TaskListContainer(
                    dateEntity: dateEntity, 
                    onPointsUpdated: { points in
                        totalPoints = points
                    },
                    onProgressUpdated: onProgressUpdated
                )
            } else {
                Text("No tasks for this date")
                    .font(.title)
                    .foregroundColor(.secondary)
            }
            
            // Footer at the bottom
            FooterDisplayView(
                onAddButtonTapped: {
                    addNewTask()
                },
                onClearButtonTapped: {
                    clearTasks()
                },
                onSoftResetButtonTapped: {
                    softResetTasks()
                },
                onCreateNewTaskInEditMode: {
                    // Implement if needed
                }
            )
            .frame(height: 60)
        }
    }
    
    private func addNewTask() {
        guard let currentDateEntity = currentDateEntity else { return }
        
        let newTask = CoreDataTask(context: context)
        newTask.title = "New Task"
        newTask.points = NSDecimalNumber(value: 1.0)
        newTask.target = 1
        newTask.completed = 0
        newTask.date = currentDateEntity
        
        // Get count of existing tasks for position
        let fetchRequest: NSFetchRequest<CoreDataTask> = CoreDataTask.fetchRequest()
        fetchRequest.predicate = NSPredicate(format: "date == %@", currentDateEntity)
        
        do {
            let count = try context.count(for: fetchRequest)
            newTask.position = Int16(count)
            try context.save()
        } catch {
            print("Error saving new task: \(error)")
        }
    }
    
    private func clearTasks() {
        guard let currentDateEntity = currentDateEntity else { return }
        
        let fetchRequest: NSFetchRequest<CoreDataTask> = CoreDataTask.fetchRequest()
        fetchRequest.predicate = NSPredicate(format: "date == %@", currentDateEntity)
        
        do {
            let tasks = try context.fetch(fetchRequest)
            for task in tasks {
                context.delete(task)
            }
            try context.save()
        } catch {
            print("Error clearing tasks: \(error)")
        }
    }
    
    private func softResetTasks() {
        guard let currentDateEntity = currentDateEntity else { return }
        
        let fetchRequest: NSFetchRequest<CoreDataTask> = CoreDataTask.fetchRequest()
        fetchRequest.predicate = NSPredicate(format: "date == %@", currentDateEntity)
        
        do {
            let tasks = try context.fetch(fetchRequest)
            for task in tasks {
                task.completed = 0
            }
            try context.save()
        } catch {
            print("Error soft resetting tasks: \(error)")
        }
    }
}

struct TaskListContainer: View {
    @Environment(\.managedObjectContext) private var context
    var dateEntity: CoreDataDate
    var onPointsUpdated: (Int) -> Void
    var onProgressUpdated: (Float) -> Void
    
    @FetchRequest var tasks: FetchedResults<CoreDataTask>
    
    init(dateEntity: CoreDataDate, 
         onPointsUpdated: @escaping (Int) -> Void = { _ in },
         onProgressUpdated: @escaping (Float) -> Void = { _ in }) {
        self.dateEntity = dateEntity
        self.onPointsUpdated = onPointsUpdated
        self.onProgressUpdated = onProgressUpdated
        
        // Set up fetch request with predicate for this date
        self._tasks = FetchRequest<CoreDataTask>(
            sortDescriptors: [NSSortDescriptor(keyPath: \CoreDataTask.position, ascending: true)],
            predicate: NSPredicate(format: "date == %@", dateEntity)
        )
    }
    
    var body: some View {
        TaskListView(
            tasks: Array(tasks),
            onDecrement: { task in
                decrementTask(task)
            },
            onDelete: { task in
                deleteTask(task)
            },
            onDuplicate: { task in
                duplicateTask(task)
            },
            onSaveEdit: { task, updatedValues in
                saveTaskEdit(task: task, updatedValues: updatedValues)
            },
            onCancelEdit: { },
            onIncrement: { task in
                incrementTask(task)
            }
        )
        .onAppear {
            updatePoints()
        }
        .onChange(of: tasks.count) { _ in
            updatePoints()
        }
    }
    
    private func updatePoints() {
        let totalPoints = tasks.reduce(0) { $0 + (Int($1.completed) * Int(truncating: $1.points ?? 0)) }
        onPointsUpdated(totalPoints)
        updateProgressBar()
    }
    
    private func updateProgressBar() {
        let totalPoints = tasks.reduce(0) { $0 + (Int($1.completed) * Int(truncating: $1.points ?? 0)) }
        let targetPoints = Int(dateEntity.target) * tasks.count
        let progress = targetPoints > 0 ? Float(totalPoints) / Float(targetPoints) : 0.0
        onProgressUpdated(progress)
    }
    
    private func incrementTask(_ task: CoreDataTask) {
        task.completed += 1
        do {
            try context.save()
            updatePoints()
        } catch {
            print("Error incrementing task: \(error)")
        }
    }
    
    private func decrementTask(_ task: CoreDataTask) {
        if task.completed > 0 {
            task.completed -= 1
            do {
                try context.save()
                updatePoints()
            } catch {
                print("Error decrementing task: \(error)")
            }
        }
    }
    
    private func deleteTask(_ task: CoreDataTask) {
        context.delete(task)
        do {
            try context.save()
            updatePoints()
        } catch {
            print("Error deleting task: \(error)")
        }
    }
    
    private func duplicateTask(_ task: CoreDataTask) {
        let newTask = CoreDataTask(context: context)
        newTask.title = task.title
        newTask.points = task.points
        newTask.target = task.target
        newTask.completed = 0
        newTask.date = dateEntity
        
        newTask.position = Int16(tasks.count)
        
        do {
            try context.save()
            updatePoints()
        } catch {
            print("Error duplicating task: \(error)")
        }
    }
    
    private func saveTaskEdit(task: CoreDataTask, updatedValues: [String: Any]) {
        if let title = updatedValues["title"] as? String {
            task.title = title
        }
        if let points = updatedValues["points"] as? NSDecimalNumber {
            task.points = points
        }
        if let target = updatedValues["target"] as? Int16 {
            task.target = target
        }
        if let reward = updatedValues["reward"] as? NSDecimalNumber {
            task.reward = reward
        }
        if let max = updatedValues["max"] as? Int16 {
            task.max = max
        }
        if let routine = updatedValues["routine"] as? Bool {
            task.routine = routine
        }
        if let optional = updatedValues["optional"] as? Bool {
            task.optional = optional
        }
        
        do {
            try context.save()
            updatePoints()
        } catch {
            print("Error saving task edit: \(error)")
        }
    }
}