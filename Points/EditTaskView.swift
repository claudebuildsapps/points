import SwiftUI
import CoreData

struct EditTaskView: View {
    @ObservedObject var task: CoreDataTask
    @Binding var isExpanded: Bool
    @Binding var isEditMode: Bool
    @State private var title: String
    @State private var points: String
    @State private var target: String
    @State private var reward: String
    @State private var max: String
    @State private var isRoutine: Bool
    @State private var isOptional: Bool
    @State private var activeField: FieldType? = nil
    @State private var showDeleteConfirmation: Bool = false
    @Environment(\.presentationMode) var presentationMode // For sheet dismissal
    @Environment(\.theme) private var theme // For theme support
    
    enum FieldType {
        case title, points, target, reward, max
    }

    var onSave: ([String: Any]) -> Void
    var onCancel: () -> Void
    var onDelete: (() -> Void)?

    init(task: CoreDataTask, isExpanded: Binding<Bool>, isEditMode: Binding<Bool>, onSave: @escaping ([String: Any]) -> Void, onCancel: @escaping () -> Void, onDelete: (() -> Void)? = nil) {
        self.task = task
        self._isExpanded = isExpanded
        self._isEditMode = isEditMode
        self.onSave = onSave
        self.onCancel = onCancel
        self.onDelete = onDelete

        // Initialize state with task values or defaults
        self._title = State(initialValue: task.title ?? "")
        self._points = State(initialValue: task.points?.stringValue ?? "5.0")
        self._target = State(initialValue: "\(task.target > 0 ? task.target : 3)")
        self._reward = State(initialValue: task.reward?.stringValue ?? "2.0")
        self._max = State(initialValue: "\(Swift.max(task.max, task.target > 0 ? task.target : 3))")
        self._isRoutine = State(initialValue: task.routine)
        self._isOptional = State(initialValue: task.optional)
    }

    var body: some View {
        VStack(spacing: 0) {
            // Title Bar with delete button
            HStack {
                Spacer()
                
                Text("Edit Task")
                    .font(.system(size: 20, weight: .bold))
                
                Spacer()
                
                // Delete button - small trash icon in top right
                if onDelete != nil {
                    Button(action: {
                        showDeleteConfirmation = true
                    }) {
                        Image(systemName: "trash")
                            .font(.system(size: 18))
                            .foregroundColor(.red)
                    }
                    .padding(.trailing, 16)
                }
            }
            .padding(.vertical, 16)
            .background(Color(.systemBackground))
                
            // Content area
            ScrollView {
                VStack(spacing: 16) {
                    // Title
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Task Name")
                            .font(.system(size: 16))
                            .foregroundColor(.gray)
                            
                        // Custom title field
                        ZStack(alignment: .leading) {
                            Rectangle()
                                .fill(Color(.systemBlue)) // Distinctive blue background for better contrast
                                .cornerRadius(6)
                                .frame(height: 44)
                            
                            Text(title.isEmpty ? "Task name..." : title)
                                .padding(.horizontal, 12)
                                .foregroundColor(title.isEmpty ? .gray : .white) // Change to white for better visibility
                        }
                        .onTapGesture {
                            print("Title field tapped! Activating keyboard")
                            activeField = .title
                        }
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
                        Toggle(isOn: $isRoutine) {
                            Text("Routine")
                                .font(.system(size: 16))
                                .foregroundColor(.primary)
                        }
                        .toggleStyle(SwitchToggleStyle(tint: .green))
                        
                        Toggle(isOn: $isOptional) {
                            Text("Optional")
                                .font(.system(size: 16))
                                .foregroundColor(.primary)
                        }
                        .toggleStyle(SwitchToggleStyle(tint: .blue))
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
                    // Cancel button
                    Button(action: {
                        print("Cancel button tapped")
                        activeField = nil
                        onCancel()
                        presentationMode.wrappedValue.dismiss()
                    }) {
                        Text("Cancel")
                            .font(.system(size: 17))
                            .foregroundColor(.red)
                            .padding(.vertical, 16)
                            .frame(maxWidth: .infinity)
                            .background(Color.red.opacity(0.1))
                            .cornerRadius(10)
                    }
                    
                    // Save button
                    Button(action: {
                        print("Save button tapped")
                        activeField = nil
                        onSave(prepareValuesForSave())
                        presentationMode.wrappedValue.dismiss()
                    }) {
                        Text("Save")
                            .font(.system(size: 17, weight: .semibold))
                            .foregroundColor(.white)
                            .padding(.vertical, 16)
                            .frame(maxWidth: .infinity)
                            .background(Color.green)
                            .cornerRadius(10)
                    }
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 16)
            }
            .background(Color(.systemBackground))
        }
        .fullScreenCover(item: $activeField) { field in
            KeyboardView(
                text: binding(for: field),
                isDecimal: isDecimalField(field),
                onDismiss: {
                    enforceConstraints()
                    
                    withAnimation(.easeOut(duration: 0.25)) {
                        activeField = nil
                    }
                }
            )
            .transition(.move(edge: .bottom))
        }
        // Add delete confirmation dialog
        .alert(isPresented: $showDeleteConfirmation) {
            Alert(
                title: Text("Delete Task"),
                message: Text("Are you sure you want to delete this task? This action cannot be undone."),
                primaryButton: .destructive(Text("Delete")) {
                    // Handle deletion
                    if let onDelete = onDelete {
                        onDelete()
                        presentationMode.wrappedValue.dismiss()
                    }
                },
                secondaryButton: .cancel()
            )
        }
    }
    
    // Helper to get the binding for the active field
    func binding(for field: FieldType) -> Binding<String> {
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
    func isDecimalField(_ field: FieldType) -> Bool {
        switch field {
        case .points, .reward:
            return true
        case .title, .target, .max:
            return false
        }
    }
    
    // Get color for field
    func colorForField(_ field: FieldType) -> Color {
        switch field {
        case .title:
            return .primary
        case .points, .reward:
            return .green
        case .target, .max:
            return .blue
        }
    }
    
    // Process field constraints (ensuring max >= target)
    func enforceConstraints() {
        if let targetValue = Int16(target), let maxValue = Int16(max) {
            if maxValue < targetValue {
                max = target
            }
        }
    }
    
    // Prepare values for saving
    func prepareValuesForSave() -> [String: Any] {
        let targetValue = Int16(target) ?? 3
        var maxValue = Int16(max) ?? 3
        if maxValue < targetValue {
            maxValue = targetValue
        }

        return [
            "title": title,
            "points": NSDecimalNumber(string: points.isEmpty ? "5.0" : points),
            "target": targetValue,
            "reward": NSDecimalNumber(string: reward.isEmpty ? "2.0" : reward),
            "max": maxValue,
            "routine": isRoutine,
            "optional": isOptional
        ]
    }
}

// ButtonsView has been removed as it's now integrated directly into EditTaskView

extension EditTaskView.FieldType: Identifiable {
    var id: Self { self }
}