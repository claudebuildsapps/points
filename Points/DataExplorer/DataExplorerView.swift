import SwiftUI
import CoreData

struct DataExplorerView: View {
    @Environment(\.managedObjectContext) private var context
    
    var body: some View {
        NavigationView {
            DataModelListView()
                .navigationBarHidden(true)
        }
        .navigationViewStyle(StackNavigationViewStyle())
    }
}

// Main model list for the data explorer
struct DataModelListView: View {
    let models = [
        ModelInfo(displayName: "Dates", entityName: "CoreDataDate", color: Constants.Colors.templateTab),
        ModelInfo(displayName: "Tasks", entityName: "CoreDataTask", color: Constants.Colors.summaryTab)
        // Completions are excluded as they're an intermediate link table
    ]
    
    var body: some View {
        VStack(spacing: 0) {
            // Title positioned exactly like "Coming Soon" 
            Text("Data Explorer")
                .font(.largeTitle)
                .foregroundColor(.secondary)
            
            List {
                ForEach(models) { model in
                    NavigationLink(destination: destinationView(for: model)) {
                        HStack {
                            Text(model.displayName)
                                .font(.title2)
                                .foregroundColor(.primary.opacity(0.45)) // Lighter shade
                                .padding(.vertical, 12)
                        }
                        .padding(.horizontal, 8)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .background(model.color.opacity(0.2))
                        .cornerRadius(8)
                    }
                    .listRowInsets(EdgeInsets())
                    .listRowBackground(Color.clear)
                    .padding(.vertical, 4)
                    .padding(.horizontal, 8)
                }
            }
            .listStyle(PlainListStyle())
        }
    }
    
    @ViewBuilder
    func destinationView(for model: ModelInfo) -> some View {
        switch model.entityName {
        case "CoreDataDate":
            DataDateListView()
        case "CoreDataTask":
            DataTaskListView()
        default:
            EmptyView()
        }
    }
}

// Model information structure
struct ModelInfo: Identifiable {
    var id: String { entityName }
    let displayName: String
    let entityName: String
    let color: Color
}

// List of all dates
struct DataDateListView: View {
    @Environment(\.managedObjectContext) private var context
    @FetchRequest(
        entity: CoreDataDate.entity(),
        sortDescriptors: [NSSortDescriptor(keyPath: \CoreDataDate.date, ascending: false)],
        animation: .default)
    private var dates: FetchedResults<CoreDataDate>
    
    var body: some View {
        VStack(spacing: 0) {
            // Title positioned exactly like "Coming Soon"
            Text("Dates")
                .font(.largeTitle)
                .foregroundColor(.secondary)
            
            List {
                ForEach(Array(zip(dates.indices, dates)), id: \.0) { index, date in
                    NavigationLink(destination: DataDateDetailView(date: date)) {
                        HStack {
                            // Display date with proper formatting
                            HStack {
                                // Month with fixed width for perfect alignment
                                Text(formatMonth(date.date))
                                    .frame(width: 100, alignment: .leading)
                                    .foregroundColor(.primary.opacity(0.45))
                                
                                // Day with ordinal suffix
                                Text(formatDay(date.date))
                                    .foregroundColor(.primary.opacity(0.45))
                                
                                // Year in smaller, lighter text
                                Text(formatYear(date.date))
                                    .font(.footnote)
                                    .foregroundColor(.gray.opacity(0.7))
                            }
                            .padding(.vertical, 12)
                        }
                        .padding(.horizontal, 8)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .background(
                            index % 2 == 0 ? 
                            Constants.Colors.templateTab.opacity(0.2) : 
                            Constants.Colors.summaryTab.opacity(0.2)
                        )
                        .cornerRadius(8)
                    }
                    .listRowInsets(EdgeInsets())
                    .listRowBackground(Color.clear)
                    .padding(.vertical, 4)
                    .padding(.horizontal, 8)
                }
            }
            .listStyle(PlainListStyle())
        }
    }
    
    // Format just the month
    private func formatMonth(_ date: Date?) -> String {
        guard let date = date else { return "Unknown" }
        let formatter = DateFormatter()
        formatter.dateFormat = "MMMM"
        return formatter.string(from: date)
    }
    
    // Format day with ordinal suffix
    private func formatDay(_ date: Date?) -> String {
        guard let date = date else { return "" }
        let day = Calendar.current.component(.day, from: date)
        return "\(day)\(ordinalSuffix(for: day)),"
    }
    
    // Format just the year
    private func formatYear(_ date: Date?) -> String {
        guard let date = date else { return "" }
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy"
        return formatter.string(from: date)
    }
    
    private func formatDate(_ date: Date?) -> String {
        guard let date = date else { return "Unknown Date" }
        
        let month = formatMonth(date)
        let day = formatDay(date)
        let year = formatYear(date)
        
        return "\(month) \(day) \(year)"
    }
    
    private func ordinalSuffix(for day: Int) -> String {
        let suffix: String
        switch day {
        case 1, 21, 31: suffix = "st"
        case 2, 22: suffix = "nd"
        case 3, 23: suffix = "rd"
        default: suffix = "th"
        }
        return suffix
    }
}

// List of all tasks
struct DataTaskListView: View {
    @Environment(\.managedObjectContext) private var context
    @State private var isInitialized = false
    
    @FetchRequest(
        entity: CoreDataTask.entity(),
        sortDescriptors: [
            NSSortDescriptor(keyPath: \CoreDataTask.date?.date, ascending: false),
            NSSortDescriptor(keyPath: \CoreDataTask.position, ascending: true)
        ],
        animation: .default)
    private var tasks: FetchedResults<CoreDataTask>
    
    var body: some View {
        VStack(spacing: 0) {
            // Title positioned exactly like "Coming Soon"
            Text("Tasks")
                .font(.largeTitle)
                .foregroundColor(.secondary)
            
            List {
                ForEach(Array(zip(tasks.indices, tasks)), id: \.0) { index, task in
                    NavigationLink(destination: DataTaskDetailView(task: task)) {
                        HStack {
                            Text(task.title ?? "Untitled Task")
                                .font(.headline)
                                .foregroundColor(.primary.opacity(0.45)) // Lighter shade
                                .padding(.vertical, 12)
                        }
                        .padding(.horizontal, 8)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .background(
                            index % 2 == 0 ? 
                            Constants.Colors.templateTab.opacity(0.2) : 
                            Constants.Colors.summaryTab.opacity(0.2)
                        )
                        .cornerRadius(8)
                    }
                    .listRowInsets(EdgeInsets())
                    .listRowBackground(Color.clear)
                    .padding(.vertical, 4)
                    .padding(.horizontal, 8)
                }
            }
            .listStyle(PlainListStyle())
        }
        .onAppear {
            // Create sample tasks each time, always clearing the database first
            clearExistingData()
            createSampleTasks()
        }
    }
    
    private func createSampleTasks() {
        // Get today and yesterday dates
        let today = Date()
        let yesterday = Calendar.current.date(byAdding: .day, value: -1, to: today)!
        
        // Get or create date entities
        let todayEntity = getOrCreateDateEntity(for: today)
        let yesterdayEntity = getOrCreateDateEntity(for: yesterday)
        
        // Create tasks with specified names
        let taskNames = ["Meditate", "Shower", "Produce", "Study", "Exercise"]
        
        // Create tasks for today
        createTask(name: taskNames[0], points: 5, target: 1, date: todayEntity, position: 0)
        createTask(name: taskNames[1], points: 3, target: 1, date: todayEntity, position: 1)
        createTask(name: taskNames[4], points: 8, target: 1, date: todayEntity, position: 2)
        
        // Create tasks for yesterday
        createTask(name: taskNames[2], points: 8, target: 1, date: yesterdayEntity, position: 0)
        createTask(name: taskNames[3], points: 6, target: 2, date: yesterdayEntity, position: 1)
        
        // Save changes
        do {
            try context.save()
            print("Successfully created sample tasks with names: \(taskNames)")
        } catch {
            print("Error creating sample tasks: \(error)")
        }
    }
    
    private func clearExistingData() {
        // Delete any existing tasks and dates to avoid duplicates
        let taskFetchRequest: NSFetchRequest<NSFetchRequestResult> = CoreDataTask.fetchRequest()
        let dateFetchRequest: NSFetchRequest<NSFetchRequestResult> = CoreDataDate.fetchRequest()
        
        // Delete all existing tasks first
        let taskDeleteRequest = NSBatchDeleteRequest(fetchRequest: taskFetchRequest)
        taskDeleteRequest.resultType = .resultTypeObjectIDs
        
        // Delete all existing dates
        let dateDeleteRequest = NSBatchDeleteRequest(fetchRequest: dateFetchRequest)
        dateDeleteRequest.resultType = .resultTypeObjectIDs
        
        do {
            // Execute delete requests and get result object IDs
            let taskResult = try context.execute(taskDeleteRequest) as? NSBatchDeleteResult
            let dateResult = try context.execute(dateDeleteRequest) as? NSBatchDeleteResult
            
            // Get deleted object IDs
            let taskObjectIDs = taskResult?.result as? [NSManagedObjectID] ?? []
            let dateObjectIDs = dateResult?.result as? [NSManagedObjectID] ?? []
            
            // Update context with changes
            NSManagedObjectContext.mergeChanges(
                fromRemoteContextSave: [NSDeletedObjectsKey: taskObjectIDs],
                into: [context]
            )
            NSManagedObjectContext.mergeChanges(
                fromRemoteContextSave: [NSDeletedObjectsKey: dateObjectIDs],
                into: [context]
            )
            
            // Final save to ensure consistent state
            try context.save()
            print("Successfully cleared all existing tasks and dates")
        } catch {
            print("Error clearing existing data: \(error)")
        }
    }
    
    private func getOrCreateDateEntity(for date: Date) -> CoreDataDate {
        let calendar = Calendar.current
        let startOfDay = calendar.startOfDay(for: date)
        let endOfDay = calendar.date(byAdding: .day, value: 1, to: startOfDay)!
        
        let fetchRequest: NSFetchRequest<CoreDataDate> = CoreDataDate.fetchRequest()
        fetchRequest.predicate = NSPredicate(format: "date >= %@ AND date < %@", startOfDay as NSDate, endOfDay as NSDate)
        
        if let existingDate = try? context.fetch(fetchRequest).first {
            return existingDate
        } else {
            let newDate = CoreDataDate(context: context)
            newDate.date = startOfDay
            newDate.target = 5
            newDate.points = NSDecimalNumber(value: 0)
            return newDate
        }
    }
    
    private func createTask(name: String, points: Double, target: Int16, date: CoreDataDate, position: Int16) {
        let task = CoreDataTask(context: context)
        task.title = name
        task.points = NSDecimalNumber(value: points)
        task.target = target
        task.max = target + 2
        task.completed = Int16.random(in: 0...Int16(target))
        task.date = date
        task.position = position
        task.routine = true
    }
}

// Detailed view of a specific date
struct DataDateDetailView: View {
    @ObservedObject var date: CoreDataDate
    
    var body: some View {
        VStack(spacing: 0) {
            // Title positioned exactly like "Coming Soon"
            if let dateValue = date.date {
                // Format date nicely with proper styling
                HStack {
                    // Month with fixed width
                    Text(formatMonth(dateValue))
                        .frame(width: 100, alignment: .leading)
                    
                    // Day with ordinal suffix
                    Text(formatDay(dateValue))
                    
                    // Year in smaller, lighter text
                    Text(formatYear(dateValue))
                        .font(.footnote)
                        .foregroundColor(.gray.opacity(0.7))
                }
                .font(.largeTitle)
                .foregroundColor(.secondary)
            } else {
                Text("Unknown Date")
                    .font(.largeTitle)
                    .foregroundColor(.secondary)
            }
            
            List {
                attributeSection
                tasksSection
            }
            .listStyle(PlainListStyle())
        }
    }
    
    // Format just the month
    private func formatMonth(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMMM"
        return formatter.string(from: date)
    }
    
    // Format day with ordinal suffix
    private func formatDay(_ date: Date) -> String {
        let day = Calendar.current.component(.day, from: date)
        return "\(day)\(ordinalSuffix(for: day)),"
    }
    
    // Format just the year
    private func formatYear(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy"
        return formatter.string(from: date)
    }
    
    private var attributeSection: some View {
        Section(header: Text("Attributes").font(.title2).foregroundColor(.secondary.opacity(0.8))) {
            attributeRow(name: "Date", value: formatDate(date.date, style: .full), color: Constants.Colors.routinesTab)
            attributeRow(name: "Points", value: "\(date.points?.stringValue ?? "0")", color: Constants.Colors.tasksTab)
            attributeRow(name: "Target", value: "\(date.target)", color: Constants.Colors.templateTab)
            attributeRow(name: "Object ID", value: date.objectID.uriRepresentation().lastPathComponent, color: Constants.Colors.summaryTab)
        }
    }
    
    private var tasksSection: some View {
        Section(header: Text("Related Tasks").font(.title2).foregroundColor(.secondary.opacity(0.8))) {
            if let tasks = date.tasks?.allObjects as? [CoreDataTask], !tasks.isEmpty {
                ForEach(tasks.sorted(by: { $0.position < $1.position }), id: \.self) { task in
                    NavigationLink(destination: DataTaskDetailView(task: task)) {
                        Text(task.title ?? "Untitled")
                            .font(.headline)
                            .foregroundColor(.primary.opacity(0.45))
                    }
                    .padding(.vertical, 8)
                }
            } else {
                Text("No tasks for this date")
                    .foregroundColor(.secondary)
                    .italic()
            }
        }
    }
    
    private func attributeRow(name: String, value: String, color: Color) -> some View {
        HStack(spacing: 8) {
            // Key in left column
            Text(name)
                .font(.subheadline)
                .fontWeight(.medium)
                .foregroundColor(.primary.opacity(0.65))
                .padding(.vertical, 8)
                .padding(.horizontal, 12)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(color.opacity(0.1))
                .cornerRadius(8)
            
            // Value in right column
            Text(value)
                .font(.subheadline)
                .foregroundColor(.primary.opacity(0.65))
                .padding(.vertical, 8)
                .padding(.horizontal, 12)
                .frame(maxWidth: .infinity, alignment: .trailing)
                .background(color.opacity(0.1))
                .cornerRadius(8)
        }
        .padding(.vertical, 2)
    }
    
    private func formatDate(_ date: Date?, style: DateFormatter.Style = .medium) -> String {
        guard let date = date else { return "Unknown Date" }
        
        if style == .full {
            let formatter = DateFormatter()
            formatter.dateStyle = .full
            return formatter.string(from: date)
        }
        
        return "\(formatMonth(date)) \(formatDay(date)) \(formatYear(date))"
    }
    
    private func ordinalSuffix(for day: Int) -> String {
        let suffix: String
        switch day {
        case 1, 21, 31: suffix = "st"
        case 2, 22: suffix = "nd"
        case 3, 23: suffix = "rd"
        default: suffix = "th"
        }
        return suffix
    }
}

// Detailed view of a specific task
struct DataTaskDetailView: View {
    @ObservedObject var task: CoreDataTask
    
    // Colors for attribute rows
    private let colors: [Color] = [
        Constants.Colors.routinesTab,
        Constants.Colors.tasksTab,
        Constants.Colors.templateTab,
        Constants.Colors.summaryTab,
        Constants.Colors.dataTab
    ]
    
    var body: some View {
        VStack(spacing: 0) {
            // Title positioned exactly like "Coming Soon"
            Text(task.title ?? "Untitled Task")
                .font(.largeTitle)
                .foregroundColor(.secondary)
                .lineLimit(1)
            
            List {
                attributesSection
                dateSection
            }
            .listStyle(PlainListStyle())
        }
    }
    
    private var attributesSection: some View {
        Section(header: Text("Attributes").font(.title2).foregroundColor(.secondary.opacity(0.8))) {
            // Basic attributes
            attributeRow(name: "Title", value: task.title ?? "Untitled", colorIndex: 0)
            attributeRow(name: "Points", value: task.points?.stringValue ?? "0", colorIndex: 1)
            attributeRow(name: "Target", value: "\(task.target)", colorIndex: 2)
            attributeRow(name: "Completed", value: "\(task.completed)", colorIndex: 3)
            attributeRow(name: "Max", value: "\(task.max)", colorIndex: 4)
            
            // Status attributes
            attributeRow(name: "Routine", value: task.routine ? "Yes" : "No", colorIndex: 0)
            attributeRow(name: "Optional", value: task.optional ? "Yes" : "No", colorIndex: 1)
            attributeRow(name: "Active", value: task.active ? "Yes" : "No", colorIndex: 2)
            
            // Extra attributes
            attributeRow(name: "Position", value: "\(task.position)", colorIndex: 3)
            attributeRow(name: "Bonus", value: task.bonus?.stringValue ?? "0", colorIndex: 4)
            attributeRow(name: "Reward", value: task.reward?.stringValue ?? "0", colorIndex: 0)
            attributeRow(name: "Scalar", value: task.scalar?.stringValue ?? "1", colorIndex: 1)
            
            // Technical identifier
            attributeRow(name: "Object ID", value: task.objectID.uriRepresentation().lastPathComponent, colorIndex: 2)
        }
    }
    
    private var dateSection: some View {
        Section(header: Text("Associated Date").font(.title2).foregroundColor(.secondary.opacity(0.8))) {
            if let date = task.date {
                NavigationLink(destination: DataDateDetailView(date: date)) {
                    if let dateValue = date.date {
                        HStack {
                            // Month with fixed width
                            Text(formatMonth(dateValue))
                                .frame(width: 100, alignment: .leading)
                            
                            // Day with ordinal suffix
                            Text(formatDay(dateValue))
                            
                            // Year in smaller, lighter text
                            Text(formatYear(dateValue))
                                .font(.footnote)
                                .foregroundColor(.gray.opacity(0.7))
                        }
                        .foregroundColor(.primary.opacity(0.45))
                    } else {
                        Text("Unknown Date")
                            .foregroundColor(.primary.opacity(0.45))
                    }
                }
                .padding(.vertical, 8)
            } else {
                Text("No date associated")
                    .foregroundColor(.secondary)
                    .italic()
            }
        }
    }
    
    // Format just the month
    private func formatMonth(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMMM"
        return formatter.string(from: date)
    }
    
    // Format day with ordinal suffix
    private func formatDay(_ date: Date) -> String {
        let day = Calendar.current.component(.day, from: date)
        return "\(day)\(ordinalSuffix(for: day)),"
    }
    
    // Format just the year
    private func formatYear(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy"
        return formatter.string(from: date)
    }
    
    private func attributeRow(name: String, value: String, colorIndex: Int) -> some View {
        let color = colors[colorIndex % colors.count]
        
        return HStack(spacing: 8) {
            // Key in left column
            Text(name)
                .font(.subheadline)
                .fontWeight(.medium)
                .foregroundColor(.primary.opacity(0.65))
                .padding(.vertical, 8)
                .padding(.horizontal, 12)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(color.opacity(0.1))
                .cornerRadius(8)
            
            // Value in right column
            Text(value)
                .font(.subheadline)
                .foregroundColor(.primary.opacity(0.65))
                .padding(.vertical, 8)
                .padding(.horizontal, 12)
                .frame(maxWidth: .infinity, alignment: .trailing)
                .background(color.opacity(0.1))
                .cornerRadius(8)
        }
        .padding(.vertical, 2)
    }
    
    private func ordinalSuffix(for day: Int) -> String {
        let suffix: String
        switch day {
        case 1, 21, 31: suffix = "st"
        case 2, 22: suffix = "nd"
        case 3, 23: suffix = "rd"
        default: suffix = "th"
        }
        return suffix
    }
}

struct DataExplorerView_Previews: PreviewProvider {
    static var previews: some View {
        DataExplorerView()
            .environment(\.managedObjectContext, PersistenceController.preview.container.viewContext)
    }
}