import SwiftUI
import CoreData

enum TaskFormMode {
    case create
    case edit
}

// Field types for form
enum TaskFormFieldType: Identifiable {
    case title, points, target, reward, max
    
    var id: Self { self }
}

struct TaskFormView: View {
    // MARK: - Properties
    let mode: TaskFormMode
    var task: CoreDataTask?
    @Binding var isPresented: Bool
    
    // Form values
    @State private var title: String
    @State private var points: String
    @State private var target: String
    @State private var reward: String
    @State private var max: String
    @State private var isRoutine: Bool
    @State private var isOptional: Bool
    @State private var isCritical: Bool
    
    // UI state
    @State private var activeField: TaskFormFieldType? = nil
    @State private var showDeleteConfirmation: Bool = false
    @State private var showTemplateConfirmation: Bool = false
    @State private var isDuplicateTemplate: Bool = false
    @FocusState private var focusedField: TaskFormFieldType?
    
    // Environment
    @Environment(\.presentationMode) var presentationMode
    @Environment(\.theme) private var theme
    
    // Callbacks
    var onSave: ([String: Any]) -> Void
    var onCancel: () -> Void
    var onDelete: (() -> Void)?
    var onCopyToTemplate: (() -> Void)?
    
    // Environment context for template check
    @Environment(\.managedObjectContext) private var context
    
    // MARK: - Initialization
    init(
        mode: TaskFormMode,
        task: CoreDataTask? = nil,
        isPresented: Binding<Bool>,
        initialIsRoutine: Bool? = nil,
        initialIsCritical: Bool? = nil,
        onSave: @escaping ([String: Any]) -> Void,
        onCancel: @escaping () -> Void,
        onDelete: (() -> Void)? = nil,
        onCopyToTemplate: (() -> Void)? = nil
    ) {
        self.mode = mode
        self.task = task
        self._isPresented = isPresented
        self.onSave = onSave
        self.onCancel = onCancel
        self.onDelete = onDelete
        self.onCopyToTemplate = onCopyToTemplate
        
        // Initialize defaults based on mode and parameters
        if mode == .edit, let task = task {
            // Edit mode - use task values with integer formatting for decimals
            self._title = State(initialValue: task.title ?? "")
            self._points = State(initialValue: "\(Int(task.points?.doubleValue ?? 5.0))")
            self._target = State(initialValue: "\(task.target > 0 ? task.target : Int16(Constants.Defaults.taskTarget))")
            self._reward = State(initialValue: "\(Int(task.reward?.doubleValue ?? 2.0))")
            self._max = State(initialValue: "\(Swift.max(task.max, task.target > 0 ? task.target : Int16(Constants.Defaults.taskTarget)))")
            self._isRoutine = State(initialValue: task.routine)
            self._isOptional = State(initialValue: task.optional)
            // Default critical to false if not set (for backward compatibility)
            self._isCritical = State(initialValue: task.getCritical())
        } else {
            // Create mode - use defaults or provided initial values
            // IMPORTANT: respecting the initialIsRoutine flag from the button pressed
            let useRoutine = initialIsRoutine ?? false // Default to routine=false if not specified
            let useCritical = initialIsCritical ?? false // Default to critical=false if not specified
            
            self._title = State(initialValue: "")
            self._points = State(initialValue: useRoutine ? "3" : "5")
            self._target = State(initialValue: "\(Constants.Defaults.taskTarget)")
            self._reward = State(initialValue: useRoutine ? "1" : "0")
            self._max = State(initialValue: "\(Constants.Defaults.taskMax)")
            // CRITICAL: Always set isRoutine based on initialIsRoutine parameter
            self._isRoutine = State(initialValue: useRoutine)
            // Always set optional to true for both routines and tasks
            self._isOptional = State(initialValue: true)
            // Set critical based on initialIsCritical parameter
            self._isCritical = State(initialValue: useCritical)
        }
    }
    
    // MARK: - View Body
    var body: some View {
        VStack(spacing: 0) {
            // Title Bar with action buttons
            HStack {
                Spacer()
                
                Text(mode == .create 
                    ? (isRoutine ? "New Routine" : "New Task") 
                    : (isRoutine ? "Edit Routine" : "Edit Task"))
                    .font(.system(size: 20, weight: .bold))
                
                Spacer()
                    
                // Buttons container for alignment
                HStack(spacing: 12) {
                    // Copy to Template button - only show in edit mode for non-template tasks
                    if mode == .edit && onCopyToTemplate != nil && task != nil && !task!.template && task!.date != nil {
                        ZStack {
                            Button(action: {
                                // Only trigger if not in help mode
                                if !HelpSystem.shared.isHelpModeActive {
                                    checkForDuplicateTemplate()
                                }
                            }) {
                                Image(systemName: "doc.on.doc")
                                    .font(.system(size: 18))
                                    .foregroundColor(isDuplicateTemplate ? .gray : theme.templateTab)
                            }
                            .disabled(isDuplicateTemplate || HelpSystem.shared.isHelpModeActive)
                            
                            // Help mode overlay
                            if HelpSystem.shared.isHelpModeActive {
                                // Transparent button for help mode
                                Button(action: {
                                    HelpSystem.shared.highlightElement("button-template")
                                }) {
                                    Rectangle()
                                        .fill(Color.white.opacity(0.001))
                                        .frame(width: 40, height: 40)
                                        .contentShape(Rectangle())
                                }
                                .buttonStyle(PlainButtonStyle())
                                .zIndex(100)
                                
                                // Show highlight when specifically highlighted
                                if HelpSystem.shared.isElementHighlighted("button-template") {
                                    Circle()
                                        .stroke(Color.blue, lineWidth: 2)
                                        .frame(width: 36, height: 36)
                                        .zIndex(99)
                                }
                            }
                        }
                        .overlay(
                            GeometryReader { geo in
                                Color.clear
                                    .onAppear {
                                        HelpSystem.shared.registerElement(
                                            id: "button-template",
                                            metadata: HelpMetadata(
                                                id: "button-template",
                                                title: "Template Button",
                                                description: "Copies this task as a reusable template",
                                                usageHints: [
                                                    "Creates a copy in the Templates tab",
                                                    "Preserves all settings and values",
                                                    "Templates can be used to create new tasks quickly",
                                                    "Gray when template already exists with same name"
                                                ],
                                                importance: .informational
                                            ),
                                            frame: geo.frame(in: .global)
                                        )
                                    }
                            }
                        )
                    }
                    
                    // Delete button - only show in edit mode
                    if mode == .edit && onDelete != nil {
                        ZStack {
                            Button(action: {
                                // Only trigger if not in help mode
                                if !HelpSystem.shared.isHelpModeActive {
                                    showDeleteConfirmation = true
                                }
                            }) {
                                Image(systemName: "trash")
                                    .font(.system(size: 18))
                                    .foregroundColor(.red)
                            }
                            .disabled(HelpSystem.shared.isHelpModeActive)
                            
                            // Help mode overlay
                            if HelpSystem.shared.isHelpModeActive {
                                // Transparent button for help mode
                                Button(action: {
                                    HelpSystem.shared.highlightElement("button-delete")
                                }) {
                                    Rectangle()
                                        .fill(Color.white.opacity(0.001))
                                        .frame(width: 40, height: 40)
                                        .contentShape(Rectangle())
                                }
                                .buttonStyle(PlainButtonStyle())
                                .zIndex(100)
                                
                                // Show highlight when specifically highlighted
                                if HelpSystem.shared.isElementHighlighted("button-delete") {
                                    Circle()
                                        .stroke(Color.blue, lineWidth: 2)
                                        .frame(width: 36, height: 36)
                                        .zIndex(99)
                                }
                            }
                        }
                        .overlay(
                            GeometryReader { geo in
                                Color.clear
                                    .onAppear {
                                        HelpSystem.shared.registerElement(
                                            id: "button-delete",
                                            metadata: HelpMetadata(
                                                id: "button-delete",
                                                title: "Delete Button",
                                                description: "Permanently removes this task",
                                                usageHints: [
                                                    "Shows confirmation before deleting",
                                                    "Cannot be undone",
                                                    "Removes all completion history",
                                                    "Points earned from this task remain"
                                                ],
                                                importance: .important
                                            ),
                                            frame: geo.frame(in: .global)
                                        )
                                    }
                            }
                        )
                    }
                }
                .padding(.trailing, 16)
            }
            .padding(.vertical, 16)
            .background(Color(.systemBackground))
            
            // Content area
            ScrollView {
                VStack(spacing: 16) {
                    // Title
                    VStack(alignment: .leading, spacing: 8) {
                        Text(isRoutine ? "Routine Name" : "Task Name")
                            .font(.system(size: 16))
                            .foregroundColor(.gray)
                        
                        // Multi-line title input field with dynamic height
                        ZStack(alignment: .leading) {
                            // Use TextEditor instead of TextField for multi-line support
                            TextEditor(text: $title)
                                .padding(.horizontal, 8)
                                .padding(.vertical, 4)
                                .foregroundColor(.primary)
                                .frame(minHeight: 44, maxHeight: 80)
                                // Style the TextEditor to match other input fields
                                .background(Color(.systemBackground)) // Match background color
                                .overlay(
                                    RoundedRectangle(cornerRadius: 6)
                                        .stroke(Color.gray.opacity(0.5), lineWidth: 1)
                                )
                                // Use SwiftUI's focus system
                                .focused($focusedField, equals: .title)
                                // Clear custom keyboard when native keyboard is shown
                                .onChange(of: focusedField) { newValue in
                                    if newValue == .title {
                                        // Using native keyboard, clear custom keyboard state
                                        activeField = nil
                                        
                                        // When we need to select all text on first focus for easy replacing
                                        // This is handled by the system for TextEditor
                                    }
                                }
                                // Disable in help mode
                                .disabled(HelpSystem.shared.isHelpModeActive)
                            
                            // Show placeholder text when empty
                            if title.isEmpty {
                                Text(isRoutine ? "Routine name..." : "Task name...")
                                    .foregroundColor(Color.gray.opacity(0.8))
                                    .padding(.horizontal, 12)
                                    .padding(.vertical, 12)
                                    .allowsHitTesting(false)
                            }
                            
                            // Add a transparent tap area to ensure focus and improve responsiveness
                            if !HelpSystem.shared.isHelpModeActive {
                                Color.clear
                                    .contentShape(Rectangle())
                                    .onTapGesture {
                                        focusedField = .title
                                        activeField = nil
                                    }
                            }
                            
                            // Help mode overlay
                            if HelpSystem.shared.isHelpModeActive {
                                // Transparent button for help mode
                                Button(action: {
                                    HelpSystem.shared.highlightElement("field-task-name")
                                }) {
                                    Rectangle()
                                        .fill(Color.white.opacity(0.001))
                                        .contentShape(Rectangle())
                                }
                                .buttonStyle(PlainButtonStyle())
                                .zIndex(100)
                                
                                // Show highlight when specifically highlighted
                                if HelpSystem.shared.isElementHighlighted("field-task-name") {
                                    RoundedRectangle(cornerRadius: 6)
                                        .stroke(Color.blue, lineWidth: 2)
                                        .zIndex(99)
                                }
                            }
                        }
                        // Register with help system
                        .overlay(
                            GeometryReader { geo in
                                Color.clear
                                    .onAppear {
                                        HelpSystem.shared.registerElement(
                                            id: "field-task-name",
                                            metadata: HelpMetadata(
                                                id: "field-task-name",
                                                title: isRoutine ? "Routine Name Field" : "Task Name Field",
                                                description: "Enter a descriptive name for this item",
                                                usageHints: [
                                                    "Tap to enter text with the keyboard",
                                                    "Be specific to easily identify this item",
                                                    "Supports multiple lines for longer descriptions",
                                                    "The name will appear in your task list"
                                                ],
                                                importance: .important
                                            ),
                                            frame: geo.frame(in: .global)
                                        )
                                    }
                            }
                        )
                    }
                    .padding(.horizontal, 16)
                    .padding(.top, 16)
                    
                    // Points and Target
                    HStack(spacing: 16) {
                        NumericField(
                            label: "Points",
                            text: $points,
                            isDecimal: true,
                            foregroundColor: .green,
                            onActivate: { activeField = .points }
                        )
                        .frame(maxWidth: .infinity)
                        
                        NumericField(
                            label: "Target",
                            text: $target,
                            isDecimal: false,
                            foregroundColor: .blue,
                            onActivate: { activeField = .target }
                        )
                        .frame(maxWidth: .infinity)
                    }
                    .padding(.horizontal, 16)
                    
                    // Reward and Max
                    HStack(spacing: 16) {
                        NumericField(
                            label: "Reward",
                            text: $reward,
                            isDecimal: true,
                            foregroundColor: .green,
                            onActivate: { activeField = .reward }
                        )
                        .frame(maxWidth: .infinity)
                        
                        NumericField(
                            label: "Max",
                            text: $max,
                            isDecimal: false,
                            foregroundColor: .blue,
                            onActivate: { activeField = .max }
                        )
                        .frame(maxWidth: .infinity)
                    }
                    .padding(.horizontal, 16)
                    
                    // Routine and Optional
                    VStack(spacing: 16) {
                        // Routine toggle with help system integration
                        ZStack {
                            Toggle(isOn: $isRoutine) {
                                Text("Routine")
                                    .font(.system(size: 16))
                                    .foregroundColor(.primary)
                            }
                            .toggleStyle(SwitchToggleStyle(tint: .green))
                            .disabled(HelpSystem.shared.isHelpModeActive)
                            
                            // Help mode overlay
                            if HelpSystem.shared.isHelpModeActive {
                                // Transparent button for help mode
                                Button(action: {
                                    HelpSystem.shared.highlightElement("toggle-routine")
                                }) {
                                    Rectangle()
                                        .fill(Color.white.opacity(0.001))
                                        .contentShape(Rectangle())
                                }
                                .buttonStyle(PlainButtonStyle())
                                .zIndex(100)
                                
                                // Show highlight when specifically highlighted
                                if HelpSystem.shared.isElementHighlighted("toggle-routine") {
                                    RoundedRectangle(cornerRadius: 8)
                                        .stroke(Color.blue, lineWidth: 2)
                                        .zIndex(99)
                                }
                            }
                        }
                        .overlay(
                            GeometryReader { geo in
                                Color.clear
                                    .onAppear {
                                        HelpSystem.shared.registerElement(
                                            id: "toggle-routine",
                                            metadata: HelpMetadata(
                                                id: "toggle-routine",
                                                title: "Routine Toggle",
                                                description: "Switch between Task and Routine types",
                                                usageHints: [
                                                    "ON: Creates a recurring routine for building habits",
                                                    "OFF: Creates a one-time task for to-do items",
                                                    "Routines typically have lower point values",
                                                    "Routines often have higher target values"
                                                ],
                                                importance: .important
                                            ),
                                            frame: geo.frame(in: .global)
                                        )
                                    }
                            }
                        )
                        
                        // Optional toggle with help system integration
                        ZStack {
                            Toggle(isOn: $isOptional) {
                                Text("Optional")
                                    .font(.system(size: 16))
                                    .foregroundColor(.primary)
                            }
                            .toggleStyle(SwitchToggleStyle(tint: .blue))
                            .disabled(HelpSystem.shared.isHelpModeActive)
                            
                            // Help mode overlay
                            if HelpSystem.shared.isHelpModeActive {
                                // Transparent button for help mode
                                Button(action: {
                                    HelpSystem.shared.highlightElement("toggle-optional")
                                }) {
                                    Rectangle()
                                        .fill(Color.white.opacity(0.001))
                                        .contentShape(Rectangle())
                                }
                                .buttonStyle(PlainButtonStyle())
                                .zIndex(100)
                                
                                // Show highlight when specifically highlighted
                                if HelpSystem.shared.isElementHighlighted("toggle-optional") {
                                    RoundedRectangle(cornerRadius: 8)
                                        .stroke(Color.blue, lineWidth: 2)
                                        .zIndex(99)
                                }
                            }
                        }
                        .overlay(
                            GeometryReader { geo in
                                Color.clear
                                    .onAppear {
                                        HelpSystem.shared.registerElement(
                                            id: "toggle-optional",
                                            metadata: HelpMetadata(
                                                id: "toggle-optional",
                                                title: "Optional Toggle",
                                                description: "Marks a task as optional or required",
                                                usageHints: [
                                                    "ON: Task is optional and can be skipped",
                                                    "OFF: Task is required for daily completion",
                                                    "Optional tasks don't affect your streak",
                                                    "Use required for essential daily habits"
                                                ],
                                                importance: .informational
                                            ),
                                            frame: geo.frame(in: .global)
                                        )
                                    }
                            }
                        )
                        
                        // Critical toggle with help system integration
                        ZStack {
                            Toggle(isOn: $isCritical) {
                                Text("Critical")
                                    .font(.system(size: 16))
                                    .foregroundColor(.primary)
                            }
                            .toggleStyle(SwitchToggleStyle(tint: .orange))
                            .disabled(HelpSystem.shared.isHelpModeActive)
                            
                            // Help mode overlay
                            if HelpSystem.shared.isHelpModeActive {
                                // Transparent button for help mode
                                Button(action: {
                                    HelpSystem.shared.highlightElement("toggle-critical")
                                }) {
                                    Rectangle()
                                        .fill(Color.white.opacity(0.001))
                                        .contentShape(Rectangle())
                                }
                                .buttonStyle(PlainButtonStyle())
                                .zIndex(100)
                                
                                // Show highlight when specifically highlighted
                                if HelpSystem.shared.isElementHighlighted("toggle-critical") {
                                    RoundedRectangle(cornerRadius: 8)
                                        .stroke(Color.blue, lineWidth: 2)
                                        .zIndex(99)
                                }
                            }
                        }
                        .overlay(
                            GeometryReader { geo in
                                Color.clear
                                    .onAppear {
                                        HelpSystem.shared.registerElement(
                                            id: "toggle-critical",
                                            metadata: HelpMetadata(
                                                id: "toggle-critical",
                                                title: "Critical Toggle",
                                                description: "Marks a task as high priority",
                                                usageHints: [
                                                    "ON: Task is highlighted as critical",
                                                    "OFF: Task has normal priority",
                                                    "Critical tasks are visually distinct",
                                                    "Use for important tasks that need attention"
                                                ],
                                                importance: .important
                                            ),
                                            frame: geo.frame(in: .global)
                                        )
                                    }
                            }
                        )
                    }
                    .padding(.horizontal, 16)
                    .padding(.bottom, 16)
                }
            }
            
            Spacer()
            
            // Button bar at bottom
            VStack(spacing: 0) {
                Divider()
                
                HStack(spacing: 16) {
                    // Cancel button with help integration
                    ZStack {
                        // Cancel button
                        Button(action: {
                            // Only trigger normal action if not in help mode
                            if !HelpSystem.shared.isHelpModeActive {
                                activeField = nil
                                onCancel()
                                presentationMode.wrappedValue.dismiss()
                            }
                        }) {
                            Text("Cancel")
                                .font(.system(size: 17))
                                .foregroundColor(.red)
                                .padding(.vertical, 16)
                                .frame(maxWidth: .infinity)
                                .background(Color.red.opacity(0.1))
                                .cornerRadius(10)
                        }
                        
                        // Help mode overlay
                        if HelpSystem.shared.isHelpModeActive {
                            // Transparent button for help mode
                            Button(action: {
                                HelpSystem.shared.highlightElement("button-cancel")
                            }) {
                                Rectangle()
                                    .fill(Color.white.opacity(0.001))
                                    .contentShape(Rectangle())
                            }
                            .buttonStyle(PlainButtonStyle())
                            .zIndex(100)
                            
                            // Show highlight when specifically highlighted
                            if HelpSystem.shared.isElementHighlighted("button-cancel") {
                                RoundedRectangle(cornerRadius: 10)
                                    .stroke(Color.blue, lineWidth: 2)
                                    .zIndex(99)
                            }
                        }
                    }
                    .overlay(
                        GeometryReader { geo in
                            Color.clear
                                .onAppear {
                                    HelpSystem.shared.registerElement(
                                        id: "button-cancel",
                                        metadata: HelpMetadata(
                                            id: "button-cancel",
                                            title: "Cancel Button",
                                            description: "Discard changes and close the form",
                                            usageHints: [
                                                "Tap to exit without saving",
                                                "All form changes will be lost",
                                                "No confirmation is shown"
                                            ],
                                            importance: .informational
                                        ),
                                        frame: geo.frame(in: .global)
                                    )
                                }
                        }
                    )
                    
                    // Save/Create button with help integration
                    ZStack {
                        // Save/Create button
                        Button(action: {
                            // Only trigger normal action if not in help mode
                            if !HelpSystem.shared.isHelpModeActive {
                                activeField = nil
                                onSave(prepareValuesForSave())
                                presentationMode.wrappedValue.dismiss()
                            }
                        }) {
                            Text(mode == .create 
                                ? (isRoutine ? "Create Routine" : "Create Task") 
                                : "Save")
                                .font(.system(size: 17, weight: .semibold))
                                .foregroundColor(.white)
                                .padding(.vertical, 16)
                                .frame(maxWidth: .infinity)
                                .background(Color.green)
                                .cornerRadius(10)
                        }
                        
                        // Help mode overlay
                        if HelpSystem.shared.isHelpModeActive {
                            // Transparent button for help mode
                            Button(action: {
                                HelpSystem.shared.highlightElement("button-save")
                            }) {
                                Rectangle()
                                    .fill(Color.white.opacity(0.001))
                                    .contentShape(Rectangle())
                            }
                            .buttonStyle(PlainButtonStyle())
                            .zIndex(100)
                            
                            // Show highlight when specifically highlighted
                            if HelpSystem.shared.isElementHighlighted("button-save") {
                                RoundedRectangle(cornerRadius: 10)
                                    .stroke(Color.blue, lineWidth: 2)
                                    .zIndex(99)
                            }
                        }
                    }
                    .overlay(
                        GeometryReader { geo in
                            Color.clear
                                .onAppear {
                                    let buttonTitle = mode == .create 
                                        ? (isRoutine ? "Create Routine" : "Create Task") 
                                        : "Save"
                                        
                                    HelpSystem.shared.registerElement(
                                        id: "button-save",
                                        metadata: HelpMetadata(
                                            id: "button-save",
                                            title: buttonTitle,
                                            description: mode == .create ? "Create a new item" : "Save changes to existing item",
                                            usageHints: [
                                                "Tap to save all field values",
                                                "Creates a new item on today's date",
                                                "All fields must have valid values",
                                                "Task will appear immediately in your list"
                                            ],
                                            importance: .important
                                        ),
                                        frame: geo.frame(in: .global)
                                    )
                                }
                        }
                    )
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 16)
            }
            .background(Color(.systemBackground))
        }
        .onAppear {
            // Auto-focus the title field when the form appears
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                self.focusedField = .title
            }
        }
        // Only show custom keyboard for numeric fields
        .fullScreenCover(item: $activeField) { field in
            // Skip text field - it now uses the native keyboard
            if field != .title {
                KeyboardView(
                    text: binding(for: field),
                    isDecimal: isDecimalField(field),
                    showCancelButton: true, // Added cancel button to keyboard
                    onDismiss: {
                        enforceConstraints()
                        
                        withAnimation(.easeOut(duration: 0.25)) {
                            activeField = nil
                        }
                    },
                    onCancel: {
                        // Keep the old value if canceled
                        withAnimation(.easeOut(duration: 0.25)) {
                            activeField = nil
                        }
                    }
                )
                .transition(.move(edge: .bottom))
            }
        }
        // Add delete confirmation dialog
        .alert("Delete Task", isPresented: $showDeleteConfirmation) {
            Button("Delete", role: .destructive) {
                if let onDelete = onDelete {
                    onDelete()
                    presentationMode.wrappedValue.dismiss()
                }
            }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("Are you sure you want to delete this task? This action cannot be undone.")
        }
        
        // Add template confirmation dialog
        .alert(isRoutine ? "Copy Routine as Template" : "Copy Task as Template", isPresented: $showTemplateConfirmation) {
            Button("Copy", role: .none) {
                if let onCopyToTemplate = onCopyToTemplate {
                    onCopyToTemplate()
                    presentationMode.wrappedValue.dismiss()
                }
            }
            .foregroundColor(.green)
            
            Button("Cancel", role: .cancel) {}
                .foregroundColor(.red)
        } message: {
            Text("This will copy this \(isRoutine ? "Routine" : "Task") as a template for use on future dates.")
        }
    }
    
    // MARK: - Helper Methods
    
    // Check if template with same title already exists
    private func checkForDuplicateTemplate() {
        guard let title = task?.title, !title.isEmpty else { return }
        
        let fetchRequest: NSFetchRequest<CoreDataTask> = CoreDataTask.fetchRequest()
        fetchRequest.predicate = NSPredicate(format: "(template == YES OR date == nil) AND title == %@", title)
        fetchRequest.fetchLimit = 1
        
        do {
            let existingTemplates = try context.fetch(fetchRequest)
            isDuplicateTemplate = !existingTemplates.isEmpty
            
            if isDuplicateTemplate {
                // Show message that template already exists
                print("Template with name '\(title)' already exists")
            } else {
                // Proceed with template creation confirmation
                showTemplateConfirmation = true
            }
        } catch {
            print("Error checking for duplicate template: \(error)")
            // In case of error, allow creation
            isDuplicateTemplate = false
            showTemplateConfirmation = true
        }
    }
    
    // Helper to get the binding for the active field
    func binding(for field: TaskFormFieldType) -> Binding<String> {
        switch field {
        case .title:
            return $title
        case .points:
            return $points
        case .target:
            return $target
        case .reward:
            return $reward
        case .max:
            return $max
        }
    }
    
    // Determine if a field should use decimal keyboard
    func isDecimalField(_ field: TaskFormFieldType) -> Bool {
        switch field {
        case .points, .reward:
            return true
        case .title, .target, .max:
            return false
        }
    }
    
    // Process field constraints (ensuring max >= target)
    func enforceConstraints() {
        // Ensure target is at least 1
        if let targetValue = Int16(target) {
            if targetValue < 1 {
                target = "1"
            }
            
            // Ensure max is at least equal to target
            if let maxValue = Int16(max), maxValue < targetValue {
                max = target
            }
        } else {
            target = "1"
        }
    }
    
    // Prepare values for saving
    func prepareValuesForSave() -> [String: Any] {
        let targetValue = Int16(target) ?? Int16(Constants.Defaults.taskTarget)
        var maxValue = Int16(max) ?? Int16(Constants.Defaults.taskMax)
        if maxValue < targetValue {
            maxValue = targetValue
        }
        
        // For points and reward, ensure proper decimal values even if displayed as integers
        let pointsValue: NSDecimalNumber
        if points.isEmpty {
            pointsValue = NSDecimalNumber(value: 3.0)
        } else if let pointsDouble = Double(points) {
            pointsValue = NSDecimalNumber(value: pointsDouble)
        } else {
            pointsValue = NSDecimalNumber(value: 3.0)
        }
        
        let rewardValue: NSDecimalNumber
        if reward.isEmpty {
            rewardValue = NSDecimalNumber(value: isRoutine ? 1.0 : 0.0)
        } else if let rewardDouble = Double(reward) {
            rewardValue = NSDecimalNumber(value: rewardDouble)
        } else {
            rewardValue = NSDecimalNumber(value: isRoutine ? 1.0 : 0.0)
        }
        
        return [
            "title": title,
            "points": pointsValue,
            "target": targetValue,
            "reward": rewardValue,
            "max": maxValue,
            "routine": isRoutine,
            "optional": isOptional,
            "critical": isCritical
        ]
    }
}

// MARK: - Preview
struct TaskFormView_Previews: PreviewProvider {
    static var previews: some View {
        // Preview for creation mode
        TaskFormView(
            mode: .create,
            isPresented: .constant(true),
            onSave: { _ in },
            onCancel: {}
        )
    }
}
