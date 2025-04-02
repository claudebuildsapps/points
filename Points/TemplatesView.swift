import SwiftUI
import CoreData

struct TemplatesView: View {
    @Environment(\.managedObjectContext) private var context
    @Environment(\.theme) private var theme
    @State private var templates: [CoreDataTask] = []
    @State private var filter: TaskFilter = .all
    @ObservedObject private var taskControllers = TaskControllers.shared
    
    // Add notification observer to handle task list changes
    @State private var notificationToken: NSObjectProtocol?
    
    var body: some View {
        VStack(spacing: 0) {
            // Header with "Templates" label
            ZStack {
                HStack {
                    Spacer()
                    Text("Templates")
                        .font(.headline.weight(.light))
                        .scaleEffect(1.2)
                        .foregroundColor(theme.textPrimary)
                    Spacer()
                }
                .padding(.horizontal)
                .frame(height: 50)
            }
            
            // Template list
            if templates.isEmpty {
                VStack {
                    Spacer()
                    Text("No Templates")
                        .font(.title)
                        .foregroundColor(.secondary)
                    Text("Create a template by adding a task or routine")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                        .padding(.top, 8)
                    Spacer()
                }
            } else {
                // Task list container similar to the main view
                ScrollView {
                    LazyVStack(spacing: 0) {
                        ForEach(filteredTemplates, id: \.self) { template in
                            TaskCellView(
                                task: template,
                                onDecrement: { decrementTemplate(template) },
                                onDelete: { deleteTemplate(template) },
                                onDuplicate: { duplicateTemplate(template) },
                                onCopyToTemplate: nil, // templates can't be copied to templates
                                onSaveEdit: { values in updateTemplate(template, with: values) },
                                onCancelEdit: {},
                                onIncrement: { incrementTemplate(template) }
                            )
                            .padding(.bottom, 1) // Slim spacing between cells
                        }
                    }
                    .padding(.top, 0)
                }
            }
        }
        .onAppear {
            // Ensure TaskManager is initialized
            if taskControllers.taskManager == nil {
                taskControllers.initialize(context: context)
                print("TemplatesView: Initialized taskControllers.taskManager")
            }
            
            loadTemplates()
            
            // Set up notification observer for task list changes
            notificationToken = NotificationCenter.default.addObserver(
                forName: Constants.Notifications.taskListChanged,
                object: nil,
                queue: .main
            ) { _ in
                print("TemplatesView: Received taskListChanged notification")
                loadTemplates()
            }
        }
        .onDisappear {
            // Clean up notification observer
            if let token = notificationToken {
                NotificationCenter.default.removeObserver(token)
            }
        }
        .onChange(of: filter) { _ in loadTemplates() }
    }
    
    // Computed property to filter templates
    private var filteredTemplates: [CoreDataTask] {
        switch filter {
        case .all:
            return templates
        case .routines:
            return templates.filter { $0.routine }
        case .tasks:
            return templates.filter { !$0.routine }
        }
    }
    
    // Load template tasks from Core Data
    private func loadTemplates() {
        guard let taskManager = taskControllers.taskManager else { 
            print("TemplatesView: taskManager is nil")
            return 
        }
        
        if filter == .all {
            templates = taskManager.fetchTemplateTasks()
        } else if filter == .routines {
            templates = taskManager.fetchTemplateTasks(routinesOnly: true)
        } else if filter == .tasks {
            templates = taskManager.fetchTemplateTasks(routinesOnly: false)
        }
        
        print("TemplatesView: Loaded \(templates.count) templates")
        
        // Debug: print details about each template
        if !templates.isEmpty {
            for (index, template) in templates.enumerated() {
                print("Template \(index): title=\(template.title ?? "nil"), template=\(template.template), date=\(template.date != nil ? "set" : "nil")")
            }
        }
    }
    
    // Template actions (these are simplified since templates don't affect points)
    private func incrementTemplate(_ template: CoreDataTask) {
        guard let taskManager = taskControllers.taskManager else { return }
        taskManager.incrementTaskCompletion(template)
        loadTemplates()
    }
    
    private func decrementTemplate(_ template: CoreDataTask) {
        guard let taskManager = taskControllers.taskManager else { return }
        taskManager.decrementTaskCompletion(template)
        loadTemplates()
    }
    
    private func deleteTemplate(_ template: CoreDataTask) {
        guard let taskManager = taskControllers.taskManager else { return }
        taskManager.deleteTask(template)
        loadTemplates()
    }
    
    private func duplicateTemplate(_ template: CoreDataTask) {
        guard let taskManager = taskControllers.taskManager else { return }
        let _ = taskManager.duplicateTask(template)
        loadTemplates()
    }
    
    private func updateTemplate(_ template: CoreDataTask, with values: [String: Any]) {
        guard let taskManager = taskControllers.taskManager else { return }
        taskManager.updateTask(template, with: values)
        loadTemplates()
    }
}

// Preview
struct TemplatesView_Previews: PreviewProvider {
    static var previews: some View {
        TemplatesView()
            .environment(\.managedObjectContext, PersistenceController.preview.container.viewContext)
    }
}