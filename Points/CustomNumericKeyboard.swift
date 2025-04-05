import SwiftUI

struct CustomNumericKeyboard: View {
    @Binding var text: String
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
            // Top bar with value display only (no clear button)
            HStack {
                Spacer()
                // Display empty state differently (Show placeholder text)
                if text.isEmpty {
                    Text("Enter value")
                        .font(.system(size: 26, weight: .semibold))
                        .foregroundColor(.gray)
                        .padding()
                        .frame(alignment: .trailing)
                } else {
                    // Value display - format as integer even for decimal fields
                    Text(formatDisplayValue(text))
                        .font(.system(size: 26, weight: .semibold))
                        .padding()
                        .frame(alignment: .trailing)
                }
            }
            .frame(height: 60)
            .background(colorScheme == .dark ? Color(.systemGray6) : Color(.systemGray5))
            
            // Keyboard buttons - edge to edge with full width
            VStack(spacing: 6) {
                ForEach(keyboardRows, id: \.self) { row in
                    HStack(spacing: 6) {
                        ForEach(row, id: \.self) { key in
                            Button(action: {
                                handleKeyPress(key)
                            }) {
                                if key == "⌫" {
                                    Image(systemName: "delete.left")
                                        .font(.system(size: 24))
                                        .foregroundColor(.red)
                                        .frame(maxWidth: .infinity)
                                        .frame(height: 60)
                                        .background(colorScheme == .dark ? Color(.systemGray5) : Color(.systemGray4))
                                        .cornerRadius(8)
                                } else {
                                    Text(key)
                                        .font(.system(size: 30, weight: .medium))
                                        .frame(maxWidth: .infinity)
                                        .frame(height: 60)
                                        .background(colorScheme == .dark ? Color(.systemGray5) : Color(.systemGray4))
                                        .foregroundColor(.primary)
                                        .cornerRadius(8)
                                }
                            }
                            .disabled(key == "." && (!isDecimal || text.contains(".")))
                        }
                    }
                }
                
                // Function row with Cancel/Done buttons with more spacing
                HStack(spacing: 12) { // Increased spacing between buttons
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
                                    .font(.system(size: 20))
                                    .foregroundColor(.red)
                                    .frame(maxWidth: .infinity)
                                    .frame(height: 60)
                                    .background(Color.red.opacity(0.1))
                                    .cornerRadius(8)
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
                                    .font(.system(size: 20))
                                    .foregroundColor(.red)
                                    .frame(maxWidth: .infinity)
                                    .frame(height: 60)
                                    .background(Color.red.opacity(0.1))
                                    .cornerRadius(8)
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
                                .font(.system(size: 20, weight: .semibold))
                                .foregroundColor(.white)
                                .frame(maxWidth: .infinity)
                                .frame(height: 60)
                                .background(Color.blue)
                                .cornerRadius(8)
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
            .padding(5)
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
    
    // Helper to format display value - show as integer even if decimal
    private func formatDisplayValue(_ value: String) -> String {
        if value.isEmpty {
            return "0"
        }
        
        // For decimal values, try to convert to integer for display
        if isDecimal && value.contains(".") {
            if let doubleValue = Double(value) {
                return "\(Int(doubleValue))"
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
