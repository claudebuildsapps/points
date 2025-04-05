import SwiftUI

struct CustomNumericKeyboard: View {
    @Binding var text: String
    var displayValue: String? = nil // Optional display value for showing original text
    var isDecimal: Bool
    var colorScheme: ColorScheme
    var screenWidth: CGFloat
    var showCancelButton: Bool = false
    var onDone: () -> Void
    var onCancel: (() -> Void)? = nil
    
    private let keyboardRows: [[String]] = [
        ["1", "2", "3"],
        ["4", "5", "6"],
        ["7", "8", "9"],
        [".", "0", "⌫"]
    ]
    
    // Compute key size based on screen width
    private var keyWidth: CGFloat {
        (screenWidth - 50) / 3 // For 3 keys in each row, with spacing
    }
    
    var body: some View {
        VStack(spacing: 0) {
            // Simple one-line display just showing the current/edited value
            HStack {
                Spacer()
                
                // Always display the initial value (never show 0)
                let textToDisplay = displayValue != nil ? displayValue! : text
                Text(formatDisplayValue(textToDisplay))
                    .font(.system(size: 28, weight: .semibold))
                    .foregroundColor(.primary) // Revert to original text color
                    .padding(.vertical, 6)
                    .padding(.horizontal, 16)
                    .frame(maxWidth: .infinity, alignment: .trailing)
            }
            .frame(height: 46) 
            .background(
                RoundedRectangle(cornerRadius: 8)
                    .fill(colorScheme == .dark ? Color(.systemGray6) : Color(.systemGray5)) // Restore original background color
                    .shadow(color: Color.black.opacity(0.1), radius: 1, x: 0, y: 1)
            )
            .padding(.horizontal, 8)
            .padding(.vertical, 2) // Reduced vertical padding
            
            // Keyboard buttons - edge to edge with full width
            VStack(spacing: 3) {  // Further reduced spacing for more compact look
                ForEach(keyboardRows, id: \.self) { row in
                    HStack(spacing: 3) {  // Further reduced spacing for more compact look
                        ForEach(row, id: \.self) { key in
                            Button(action: {
                                handleKeyPress(key)
                            }) {
                                if key == "⌫" {
                                    Image(systemName: "delete.left")
                                        .font(.system(size: 22))
                                        .foregroundColor(.red)
                                        .frame(maxWidth: .infinity)
                                        .frame(height: 50)  // Further reduced height
                                        .background(colorScheme == .dark ? Color(.systemGray5) : Color(.systemGray4))
                                        .cornerRadius(6)
                                } else {
                                    Text(key)
                                        .font(.system(size: 26, weight: .medium))  // Further reduced font size
                                        .frame(maxWidth: .infinity)
                                        .frame(height: 50)  // Further reduced height to match delete button
                                        .background(colorScheme == .dark ? Color(.systemGray5) : Color(.systemGray4))
                                        .foregroundColor(.primary)
                                        .cornerRadius(6)
                                }
                            }
                            .disabled(key == "." && (!isDecimal || text.contains(".")))
                        }
                    }
                }
                
                // Function row with Cancel/Done buttons with more compact layout
                HStack(spacing: 6) { // Further reduced spacing between buttons
                    // Cancel or Clear button
                    if showCancelButton && onCancel != nil {
                        // Cancel button that discards changes with help integration
                        ZStack {
                            Button(action: {
                                // Only trigger if not in help mode
                                if !HelpSystem.shared.isHelpModeActive {
                                    if let onCancel = onCancel {
                                        onCancel()
                                    }
                                }
                            }) {
                                Text("Cancel")
                                    .font(.system(size: 18))
                                    .foregroundColor(.red)
                                    .frame(maxWidth: .infinity)
                                    .frame(height: 50)
                                    .background(Color.red.opacity(0.1))
                                    .cornerRadius(6)
                            }
                            .disabled(HelpSystem.shared.isHelpModeActive)
                            
                            // Help mode overlay
                            if HelpSystem.shared.isHelpModeActive {
                                // Transparent button for help mode
                                Button(action: {
                                    HelpSystem.shared.highlightElement("keyboard-cancel-button")
                                }) {
                                    Rectangle()
                                        .fill(Color.white.opacity(0.001))
                                        .contentShape(Rectangle())
                                }
                                .buttonStyle(PlainButtonStyle())
                                .zIndex(100)
                                
                                // Show highlight when specifically highlighted
                                if HelpSystem.shared.isElementHighlighted("keyboard-cancel-button") {
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
                                            id: "keyboard-cancel-button",
                                            metadata: HelpMetadata(
                                                id: "keyboard-cancel-button",
                                                title: "Cancel Button",
                                                description: "Discards changes to the numeric field",
                                                usageHints: [
                                                    "Tap to exit without saving changes",
                                                    "Restores the previous value",
                                                    "Returns to the task form"
                                                ],
                                                importance: .informational
                                            ),
                                            frame: geo.frame(in: .global)
                                        )
                                    }
                            }
                        )
                        .padding(.leading, 8) // Add padding to push away from edge
                    } else {
                        // Clear button with help integration
                        ZStack {
                            Button(action: {
                                // Only trigger if not in help mode
                                if !HelpSystem.shared.isHelpModeActive {
                                    text = ""  // Just clear the text
                                }
                            }) {
                                Text("Clear")
                                    .font(.system(size: 18))
                                    .foregroundColor(.red)
                                    .frame(maxWidth: .infinity)
                                    .frame(height: 50)
                                    .background(Color.red.opacity(0.1))
                                    .cornerRadius(6)
                            }
                            .disabled(HelpSystem.shared.isHelpModeActive)
                            
                            // Help mode overlay
                            if HelpSystem.shared.isHelpModeActive {
                                // Transparent button for help mode
                                Button(action: {
                                    HelpSystem.shared.highlightElement("keyboard-clear-button")
                                }) {
                                    Rectangle()
                                        .fill(Color.white.opacity(0.001))
                                        .contentShape(Rectangle())
                                }
                                .buttonStyle(PlainButtonStyle())
                                .zIndex(100)
                                
                                // Show highlight when specifically highlighted
                                if HelpSystem.shared.isElementHighlighted("keyboard-clear-button") {
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
                                            id: "keyboard-clear-button",
                                            metadata: HelpMetadata(
                                                id: "keyboard-clear-button",
                                                title: "Clear Button",
                                                description: "Clears the current value",
                                                usageHints: [
                                                    "Tap to reset to empty value",
                                                    "Start fresh with a new value",
                                                    "Sets to 0 when saved"
                                                ],
                                                importance: .informational
                                            ),
                                            frame: geo.frame(in: .global)
                                        )
                                    }
                            }
                        )
                        .padding(.leading, 8) // Add padding to push away from edge
                    }
                    
                    // Done button with help integration
                    ZStack {
                        Button(action: {
                            // Only trigger if not in help mode
                            if !HelpSystem.shared.isHelpModeActive {
                                onDone()
                            }
                        }) {
                            Text("Done")
                                .font(.system(size: 18, weight: .semibold))
                                .foregroundColor(.white)
                                .frame(maxWidth: .infinity)
                                .frame(height: 50)
                                .background(Color.blue)
                                .cornerRadius(6)
                        }
                        .disabled(HelpSystem.shared.isHelpModeActive)
                        
                        // Help mode overlay
                        if HelpSystem.shared.isHelpModeActive {
                            // Transparent button for help mode
                            Button(action: {
                                HelpSystem.shared.highlightElement("keyboard-done-button")
                            }) {
                                Rectangle()
                                    .fill(Color.white.opacity(0.001))
                                    .contentShape(Rectangle())
                            }
                            .buttonStyle(PlainButtonStyle())
                            .zIndex(100)
                            
                            // Show highlight when specifically highlighted
                            if HelpSystem.shared.isElementHighlighted("keyboard-done-button") {
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
                                        id: "keyboard-done-button",
                                        metadata: HelpMetadata(
                                            id: "keyboard-done-button",
                                            title: "Done Button",
                                            description: "Confirms and saves the numeric value",
                                            usageHints: [
                                                "Tap to apply the entered value",
                                                "Closes the keyboard",
                                                "Returns to the task form"
                                            ],
                                            importance: .important
                                        ),
                                        frame: geo.frame(in: .global)
                                    )
                                }
                        }
                    )
                    .padding(.trailing, 8) // Add padding to push away from edge
                }
            }
            .padding(4)
            .background(colorScheme == .dark ? Color.black : Color(.systemGray6))
        }
    }
    
    private func handleKeyPress(_ key: String) {
        switch key {
        case "⌫":
            if !text.isEmpty {
                text.removeLast()
            }
        case ".":
            if isDecimal && !text.contains(".") {
                // If text is empty, add a leading zero
                if text.isEmpty {
                    text = "0."
                } else {
                    text += "."
                }
            }
        default:
            // First keypress should replace the value
            if text.isEmpty || text == "0" {
                // Start fresh with the new number
                text = key
            } else {
                // After first keypress, append as usual
                text += key
            }
        }
    }
    
    // Helper to format display value with appropriate formatting
    private func formatDisplayValue(_ value: String) -> String {
        if value.isEmpty {
            return "0"
        }
        
        // For decimal values with .0 ending, show as integer
        if isDecimal && value.contains(".") {
            if let doubleValue = Double(value) {
                // If it's a whole number (no fractional part), show as integer
                if doubleValue == Double(Int(doubleValue)) {
                    return "\(Int(doubleValue))"
                }
                
                // For other decimal values, ensure we show at most 1 decimal place
                let numberFormatter = NumberFormatter()
                numberFormatter.minimumFractionDigits = 0 // Don't show .0
                numberFormatter.maximumFractionDigits = 1 // Show at most one decimal place
                
                if let formattedString = numberFormatter.string(from: NSNumber(value: doubleValue)) {
                    return formattedString
                }
            }
        }
        
        return value
    }
}

#Preview {
    VStack {
        Spacer()
        CustomNumericKeyboard(
            text: .constant("123.45"),
            isDecimal: true,
            colorScheme: .light,
            screenWidth: UIScreen.main.bounds.width,
            onDone: {}
        )
    }
}
