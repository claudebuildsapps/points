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
    
    enum FieldType {
        case points, target, reward, max
    }

    var onSave: ([String: Any]) -> Void
    var onCancel: () -> Void

    init(task: CoreDataTask, isExpanded: Binding<Bool>, isEditMode: Binding<Bool>, onSave: @escaping ([String: Any]) -> Void, onCancel: @escaping () -> Void) {
        self.task = task
        self._isExpanded = isExpanded
        self._isEditMode = isEditMode
        self.onSave = onSave
        self.onCancel = onCancel

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
        VStack(spacing: 8) {
            // Title
            VStack(alignment: .leading, spacing: 4) {
                Text("Task")
                    .font(.system(size: 14))
                    .foregroundColor(.gray)
                TextField("Task", text: $title)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                    .padding(.horizontal, 8)
            }
            .padding(.horizontal, 8)

            // Points and Target
            HStack(spacing: 8) {
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
            .padding(.horizontal, 8)

            // Reward and Max
            HStack(spacing: 8) {
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
            .padding(.horizontal, 8)

            // Routine and Optional
            HStack(spacing: 8) {
                HStack {
                    Text("Routine")
                        .font(.system(size: 14))
                        .foregroundColor(.gray)
                    Spacer()
                    Toggle("", isOn: $isRoutine)
                        .labelsHidden()
                        .tint(.green)
                        .scaleEffect(0.75)
                }
                .frame(maxWidth: .infinity)
                .contentShape(Rectangle())

                HStack {
                    Text("Optional")
                        .font(.system(size: 14))
                        .foregroundColor(.gray)
                    Spacer()
                    Toggle("", isOn: $isOptional)
                        .labelsHidden()
                        .tint(.blue)
                        .scaleEffect(0.75)
                }
                .frame(maxWidth: .infinity)
                .contentShape(Rectangle())
            }
            .padding(.horizontal, 8)
            
            // Add a larger divider and padding for separation
            Rectangle()
                .frame(height: 1)
                .foregroundColor(Color(.systemGray5))
                .padding(.vertical, 12)

            Rectangle()
                .frame(height: 20)
                .foregroundColor(.clear)
                .allowsHitTesting(false)
            
            // Save and Cancel Buttons in separate View for isolation
            ButtonsView(onCancel: onCancel, onSave: {
                onSave(prepareValuesForSave())
            }, activeField: $activeField)
            .padding(.horizontal, 12)
            .padding(.bottom, 12)
            .padding(.top, 0) // Remove top padding here, we added spacer above
            .zIndex(999) // Extremely high z-index at the container level too
            .allowsHitTesting(true) // Explicitly allow hit testing
        }
        .animation(.easeInOut(duration: 0.3), value: isExpanded)
        .transition(.opacity)
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
    }
    
    // Helper to get the binding for the active field
    func binding(for field: FieldType) -> Binding<String> {
        switch field {
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
        case .target, .max:
            return false
        }
    }
    
    // Get color for field
    func colorForField(_ field: FieldType) -> Color {
        switch field {
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

struct ButtonsView: View {
    var onCancel: () -> Void
    var onSave: () -> Void
    @Binding var activeField: EditTaskView.FieldType?
    @State private var debugMode = true // Turn on visual debugging
    
    var body: some View {
        GeometryReader { geometry in
            HStack(spacing: 12) {
                // Cancel "button" with debug highlight
                ZStack {
                    // Debug outline - bright red outline to show tappable area
                    if debugMode {
                        Rectangle()
                            .stroke(Color.red, lineWidth: 2)
                            .background(Color.red.opacity(0.3))
                            .cornerRadius(8)
                    } else {
                        Rectangle()
                            .fill(Color.red.opacity(0.1))
                            .cornerRadius(8)
                    }
                    
                    Text("Cancel")
                        .font(.system(size: 16))
                        .foregroundColor(.red)
                }
                .frame(width: (geometry.size.width - 12) / 2)
                .contentShape(Rectangle())
                .simultaneousGesture(TapGesture().onEnded {
                    print("Cancel tapped via simultaneous gesture")
                    activeField = nil
                    onCancel()
                })
                
                // Save "button" with debug highlight
                ZStack {
                    // Debug outline - bright green outline to show tappable area
                    if debugMode {
                        Rectangle()
                            .stroke(Color.green, lineWidth: 2)
                            .background(Color.green.opacity(0.3))
                            .cornerRadius(8)
                    } else {
                        Rectangle()
                            .fill(Color.green.opacity(0.1))
                            .cornerRadius(8)
                    }
                    
                    Text("Save")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(.green)
                }
                .frame(width: (geometry.size.width - 12) / 2)
                .contentShape(Rectangle())
                .simultaneousGesture(TapGesture().onEnded {
                    print("Save tapped via simultaneous gesture")
                    activeField = nil
                    onSave()
                })
            }
            .frame(height: 44)
            .zIndex(999)
        }
        .frame(height: 44)
        .padding(.vertical, 16)
        .background(
            // Add explicit debug background to entire container
            debugMode ? Color.yellow.opacity(0.2) : Color.clear
        )
    }
}

extension EditTaskView.FieldType: Identifiable {
    var id: Self { self }
}
