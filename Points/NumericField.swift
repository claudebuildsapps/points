import SwiftUI

// A button styled as a text field that opens the numeric keyboard
struct NumericField: View {
    var label: String
    @Binding var text: String
    var isDecimal: Bool
    var foregroundColor: Color
    var onActivate: () -> Void
    
    // Help system
    @ObservedObject private var helpSystem = HelpSystem.shared
    
    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(label)
                .font(.system(size: 14))
                .foregroundColor(.gray)
            
            // Using ZStack for custom help mode integration
            ZStack {
                // Main button that maintains its appearance
                Button(action: {
                    // Only trigger normal action if not in help mode
                    if !helpSystem.isHelpModeActive {
                        onActivate()
                    }
                }) {
                    HStack {
                        Text(text)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .foregroundColor(foregroundColor)
                        Spacer()
                    }
                    .padding(8)
                    .background(
                        RoundedRectangle(cornerRadius: 5)
                            .stroke(Color(.systemGray4), lineWidth: 1)
                            .background(Color(.systemBackground))
                    )
                }
                .buttonStyle(PlainButtonStyle())
                
                // Help mode overlay - only render when help mode is active
                if helpSystem.isHelpModeActive {
                    // Invisible button with high priority tap area
                    Button(action: {
                        let fieldId = "field-\(label.lowercased())"
                        helpSystem.highlightElement(fieldId)
                    }) {
                        // Use the full area for better touch target
                        Rectangle()
                            .fill(Color.white.opacity(0.001)) // Nearly invisible
                            .contentShape(Rectangle())
                    }
                    .buttonStyle(PlainButtonStyle())
                    .zIndex(100) // Ensure this is on top for taps
                    
                    // Visual highlight when this element is selected
                    if helpSystem.isElementHighlighted("field-\(label.lowercased())") {
                        RoundedRectangle(cornerRadius: 5)
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
                            // Create help metadata based on field type
                            var fieldDescription = "Enter a value"
                            var fieldTips = ["Tap to open the numeric keyboard"]
                            
                            switch label {
                            case "Points":
                                fieldDescription = "Set the points value earned for each completion"
                                fieldTips = [
                                    "Tap to open the numeric keyboard",
                                    "Points are earned each time you complete the task",
                                    "Higher values make tasks more valuable",
                                    "Decimal values like 0.5 or 1.5 are allowed"
                                ]
                            case "Target":
                                fieldDescription = "Set the target number of times to complete this task"
                                fieldTips = [
                                    "Tap to open the numeric keyboard",
                                    "Target sets your completion goal",
                                    "The progress bar shows completion toward this target",
                                    "Only whole numbers are allowed"
                                ]
                            case "Reward":
                                fieldDescription = "Set bonus points earned when reaching target"
                                fieldTips = [
                                    "Tap to open the numeric keyboard",
                                    "Reward points are added when you hit your target",
                                    "Set to 0 for no bonus reward",
                                    "Decimal values like 0.5 or 1.5 are allowed"
                                ]
                            case "Max":
                                fieldDescription = "Set the maximum number of times this task can be completed"
                                fieldTips = [
                                    "Tap to open the numeric keyboard",
                                    "Must be equal to or greater than target",
                                    "Once max is reached, no more points can be earned",
                                    "Only whole numbers are allowed"
                                ]
                            default:
                                // Keep default values for any other fields
                                fieldDescription = "Enter a numeric value"
                                fieldTips = [
                                    "Tap to open the numeric keyboard",
                                    "Enter the appropriate value"
                                ]
                            }
                            
                            helpSystem.registerElement(
                                id: "field-\(label.lowercased())",
                                metadata: HelpMetadata(
                                    id: "field-\(label.lowercased())",
                                    title: "\(label) Field",
                                    description: fieldDescription,
                                    usageHints: fieldTips,
                                    importance: .important
                                ),
                                frame: geo.frame(in: .global)
                            )
                        }
                }
            )
        }
    }
}

#Preview {
    NumericField(
        label: "Points",
        text: .constant("5.0"),
        isDecimal: true,
        foregroundColor: .green,
        onActivate: {}
    )
    .padding()
}
