import SwiftUI

// Enhanced keyboard view that displays above everything
struct KeyboardView: View {
    @Binding var text: String
    var isDecimal: Bool
    var showCancelButton: Bool = false
    var onDismiss: () -> Void
    var onCancel: (() -> Void)? = nil
    @Environment(\.presentationMode) var presentationMode
    @Environment(\.colorScheme) var colorScheme // For dark/light mode
    @State private var keyboardVisible = false
    @State private var editingText: String // For text editing
    @State private var cursorPosition: Int // For cursor position
    
    // Initialize with current text and position cursor at the end
    init(text: Binding<String>, isDecimal: Bool, showCancelButton: Bool = false, onDismiss: @escaping () -> Void, onCancel: (() -> Void)? = nil) {
        self._text = text
        self.isDecimal = isDecimal
        self.showCancelButton = showCancelButton
        self.onDismiss = onDismiss
        self.onCancel = onCancel
        self._editingText = State(initialValue: text.wrappedValue)
        self._cursorPosition = State(initialValue: text.wrappedValue.count) // Position at end
    }
    
    var body: some View {
        GeometryReader { geometry in
            ZStack {
                // Semi-transparent background
                Color.black.opacity(0.4)
                    .edgesIgnoringSafeArea(.all)
                    .onTapGesture {
                        saveChanges()
                        dismissWithAnimation()
                    }
                
                // Content container
                VStack(spacing: 0) {
                    Spacer()
                    
                    // Keyboard with rounded edges
                    VStack(spacing: 0) {
                        if isTextInputField() {
                            // Use text keyboard for title
                            TextKeyboard(
                                text: $editingText,
                                cursorPosition: $cursorPosition,
                                colorScheme: colorScheme,
                                screenWidth: geometry.size.width,
                                onDone: {
                                    saveChanges()
                                    dismissWithAnimation()
                                },
                                onCancel: onCancel,
                                showCancelButton: showCancelButton
                            )
                        } else {
                            // Use numeric keyboard for numbers
                            CustomNumericKeyboard(
                                text: $editingText,
                                isDecimal: isDecimal,
                                colorScheme: colorScheme,
                                screenWidth: geometry.size.width,
                                showCancelButton: showCancelButton,
                                onDone: {
                                    saveChanges()
                                    dismissWithAnimation()
                                },
                                onCancel: onCancel
                            )
                        }
                    }
                    .background(
                        // Rounded edges only at the top
                        RoundedCorners(tl: 15, tr: 15, bl: 0, br: 0)
                            .fill(colorScheme == .dark ? Color(.systemGray6) : Color(.systemBackground))
                            .shadow(color: .black.opacity(0.2), radius: 8, x: 0, y: -4)
                    )
                    .offset(y: keyboardVisible ? -20 : 300) // Move up 20pts from normal position
                    .animation(.spring(response: 0.3, dampingFraction: 0.7), value: keyboardVisible)
                }
                .edgesIgnoringSafeArea(.bottom)
            }
        }
        .onAppear {
            // Animate the keyboard sliding up when it appears
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                keyboardVisible = true
            }
        }
    }
    
    // Save changes back to original binding
    private func saveChanges() {
        text = editingText
    }
    
    private func isTextInputField() -> Bool {
        // For debugging
        print("Checking if text field: isDecimal=\(isDecimal), text=\(text)")
        
        // Simply check if decimal is false
        return !isDecimal
    }
    
    private func dismissWithAnimation() {
        // First animate the keyboard sliding down
        withAnimation(.easeInOut(duration: 0.25)) {
            keyboardVisible = false
        }
        
        // Then dismiss the view after animation completes
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.25) {
            onDismiss()
        }
    }
}

// Custom rounded corners shape
struct RoundedCorners: Shape {
    var tl: CGFloat = 0.0  // top-left radius
    var tr: CGFloat = 0.0  // top-right radius
    var bl: CGFloat = 0.0  // bottom-left radius
    var br: CGFloat = 0.0  // bottom-right radius
    
    func path(in rect: CGRect) -> Path {
        var path = Path()
        
        // Start from top-left with rounded corner
        path.move(to: CGPoint(x: rect.minX + tl, y: rect.minY))
        
        // Top edge and top-right corner
        path.addLine(to: CGPoint(x: rect.maxX - tr, y: rect.minY))
        path.addArc(center: CGPoint(x: rect.maxX - tr, y: rect.minY + tr),
                    radius: tr,
                    startAngle: Angle(degrees: -90),
                    endAngle: Angle(degrees: 0),
                    clockwise: false)
        
        // Right edge and bottom-right corner
        path.addLine(to: CGPoint(x: rect.maxX, y: rect.maxY - br))
        path.addArc(center: CGPoint(x: rect.maxX - br, y: rect.maxY - br),
                    radius: br,
                    startAngle: Angle(degrees: 0),
                    endAngle: Angle(degrees: 90),
                    clockwise: false)
        
        // Bottom edge and bottom-left corner
        path.addLine(to: CGPoint(x: rect.minX + bl, y: rect.maxY))
        path.addArc(center: CGPoint(x: rect.minX + bl, y: rect.maxY - bl),
                    radius: bl,
                    startAngle: Angle(degrees: 90),
                    endAngle: Angle(degrees: 180),
                    clockwise: false)
        
        // Left edge and top-left corner
        path.addLine(to: CGPoint(x: rect.minX, y: rect.minY + tl))
        path.addArc(center: CGPoint(x: rect.minX + tl, y: rect.minY + tl),
                    radius: tl,
                    startAngle: Angle(degrees: 180),
                    endAngle: Angle(degrees: 270),
                    clockwise: false)
        
        path.closeSubpath()
        return path
    }
}

// Enhanced keyboard for text input with cursor support
struct TextKeyboard: View {
    @Binding var text: String
    @Binding var cursorPosition: Int
    var colorScheme: ColorScheme
    var screenWidth: CGFloat
    var onDone: () -> Void
    var onCancel: (() -> Void)? = nil
    var showCancelButton: Bool = false
    @State private var isShiftEnabled = false
    @State private var isNumericMode = false
    @State private var cursorBlinkOpacity: Double = 1.0
    
    // First 3 rows are standard QWERTY layout
    private let keyboardRows: [[String]] = [
        ["q", "w", "e", "r", "t", "y", "u", "i", "o", "p"],
        ["a", "s", "d", "f", "g", "h", "j", "k", "l"],
        ["⇧", "z", "x", "c", "v", "b", "n", "m", "⌫"]
    ]
    
    // Bottom row has special keys
    private let specialKeys = ["123", ",", " ", ".", "Done"]
    
    // Compute key sizes based on screen width with minimal margins
    private var keyWidth: CGFloat {
        (screenWidth - 22) / 10 - 2 // For 10 keys in top row, with 2pt spacing, and 1pt margins
    }
    
    // Compute proportional height based on width
    private var keyHeight: CGFloat {
        keyWidth * 1.6 // Keep a good height-to-width ratio
    }
    
    var body: some View {
        VStack(spacing: 0) {
            // Text input area with cursor
            ZStack(alignment: .leading) {
                if text.isEmpty {
                    Text("Enter task name...")
                        .font(.system(size: 20))
                        .foregroundColor(.gray)
                        .padding(.horizontal, 16)
                        .padding(.vertical, 12)
                }
                
                HStack(spacing: 0) {
                    // Text before cursor
                    Text(text.prefix(cursorPosition))
                        .font(.system(size: 20))
                        .foregroundColor(colorScheme == .dark ? .white : .black)
                    
                    // Blinking cursor
                    Rectangle()
                        .fill(Color.blue)
                        .frame(width: 2, height: 24)
                        .opacity(cursorBlinkOpacity)
                        .animation(Animation.easeInOut(duration: 0.6).repeatForever(autoreverses: true), value: cursorBlinkOpacity)
                    
                    // Text after cursor
                    Text(text.suffix(text.count - cursorPosition))
                        .font(.system(size: 20))
                        .foregroundColor(colorScheme == .dark ? .white : .black)
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 12)
                
                // Clear button at the right
                HStack {
                    Spacer()
                    Button(action: {
                        text = ""
                        cursorPosition = 0
                    }) {
                        Image(systemName: "xmark.circle.fill")
                            .font(.system(size: 22))
                            .foregroundColor(.gray)
                    }
                    .padding(.trailing, 16)
                }
            }
            .frame(height: 50)
            .background(colorScheme == .dark ? Color(.systemGray6) : Color(.systemGray5))
            
            // Main keyboard area - edge to edge
            VStack(spacing: 2) { // Reduced spacing between keyboard rows
                // Standard QWERTY rows with edge-to-edge keys
                ForEach(0..<keyboardRows.count, id: \.self) { rowIndex in
                    HStack(spacing: 2) {
                        // Adjust for left offset in second row
                        if rowIndex == 1 {
                            Spacer(minLength: keyWidth * 0.5)
                        }
                        
                        ForEach(0..<keyboardRows[rowIndex].count, id: \.self) { keyIndex in
                            let key = keyboardRows[rowIndex][keyIndex]
                            let displayKey = isShiftEnabled && key.count == 1 ? key.uppercased() : key
                            
                            Button(action: {
                                handleKeyPress(key)
                            }) {
                                if key == "⌫" {
                                    Image(systemName: "delete.left")
                                        .font(.system(size: 22))
                                        .foregroundColor(.primary)
                                        .frame(height: keyHeight)
                                        .frame(width: keyWidth * 1.5)
                                        .background(colorScheme == .dark ? Color(.systemGray5) : Color(.systemGray4))
                                        .cornerRadius(6)
                                } else if key == "⇧" {
                                    Image(systemName: "shift.fill")
                                        .font(.system(size: 22))
                                        .foregroundColor(isShiftEnabled ? .blue : .primary)
                                        .frame(height: keyHeight)
                                        .frame(width: keyWidth * 1.5)
                                        .background(colorScheme == .dark ? Color(.systemGray5) : Color(.systemGray4))
                                        .cornerRadius(6)
                                } else {
                                    Text(displayKey)
                                        .font(.system(size: 22, weight: .medium))
                                        .frame(height: keyHeight)
                                        .frame(width: keyWidth)
                                        .background(colorScheme == .dark ? Color(.systemGray5) : Color(.systemGray4))
                                        .foregroundColor(.primary)
                                        .cornerRadius(6)
                                }
                            }
                        }
                        
                        // Adjust for right offset in second row
                        if rowIndex == 1 {
                            Spacer(minLength: keyWidth * 0.5)
                        }
                    }
                }
                
                // Bottom row with special keys, with reduced height
                HStack(spacing: 2) {
                    // Using reduced spacing compared to the other rows
                    // 123 button - smaller
                    Button(action: {
                        // Toggle numeric mode
                        isNumericMode.toggle()
                        handleSpecialKeyPress("123")
                    }) {
                        Text("123")
                            .font(.system(size: 16))
                            .frame(height: keyHeight)
                            .frame(width: keyWidth * 1.3)
                            .background(colorScheme == .dark ? Color(.systemGray5) : Color(.systemGray4))
                            .foregroundColor(.primary)
                            .cornerRadius(6)
                    }
                    
                    // Comma
                    Button(action: {
                        handleSpecialKeyPress(",")
                    }) {
                        Text(",")
                            .font(.system(size: 20))
                            .frame(height: keyHeight)
                            .frame(width: keyWidth * 0.8)
                            .background(colorScheme == .dark ? Color(.systemGray5) : Color(.systemGray4))
                            .foregroundColor(.primary)
                            .cornerRadius(6)
                    }
                    
                    // Space - narrower when cancel button is shown
                    Button(action: {
                        handleSpecialKeyPress(" ")
                    }) {
                        Text("Space")
                            .font(.system(size: 18))
                            .frame(height: keyHeight)
                            .frame(width: showCancelButton ? keyWidth * 2.8 : keyWidth * 3.5)
                            .background(colorScheme == .dark ? Color(.systemGray5) : Color(.systemGray4))
                            .foregroundColor(.primary)
                            .cornerRadius(6)
                    }
                    
                    // Period
                    Button(action: {
                        handleSpecialKeyPress(".")
                    }) {
                        Text(".")
                            .font(.system(size: 20))
                            .frame(height: keyHeight)
                            .frame(width: keyWidth * 0.8)
                            .background(colorScheme == .dark ? Color(.systemGray5) : Color(.systemGray4))
                            .foregroundColor(.primary)
                            .cornerRadius(6)
                    }
                    
                    // Cancel button - shown conditionally
                    if showCancelButton {
                        Button(action: {
                            if let onCancel = onCancel {
                                onCancel()
                            }
                        }) {
                            Text("Cancel")
                                .font(.system(size: 16))
                                .frame(height: keyHeight * 0.85) // Reduced height by 15%
                                .frame(width: keyWidth * 1.5)
                                .foregroundColor(.white)
                                .background(Color.red)
                                .cornerRadius(6)
                        }
                        .padding(.leading, 8) // Add padding to push away from edge
                    }
                    
                    // Done button
                    Button(action: {
                        onDone()
                    }) {
                        Text("Done")
                            .font(.system(size: 16, weight: .semibold))
                            .frame(height: keyHeight * 0.85) // Reduced height by 15%
                            .frame(width: showCancelButton ? keyWidth * 1.5 : keyWidth * 2.0)
                            .foregroundColor(.white)
                            .background(Color.blue)
                            .cornerRadius(6)
                    }
                    .padding(.trailing, 8) // Add padding to push away from edge
                }
            }
            .padding(.horizontal, 1) // Minimal padding to maximize keyboard size
            .padding(.top, 4)
            .padding(.bottom, 0) // Further reduced bottom padding by another 20%
            .background(colorScheme == .dark ? Color.black : Color(.systemGray6))
        }
        .onAppear {
            // Start the cursor blinking animation
            withAnimation(Animation.easeInOut(duration: 0.6).repeatForever(autoreverses: true)) {
                cursorBlinkOpacity = 0.0
            }
        }
    }
    
    private func handleKeyPress(_ key: String) {
        switch key {
        case "⌫":
            if !text.isEmpty && cursorPosition > 0 {
                // Remove character before cursor
                let index = text.index(text.startIndex, offsetBy: cursorPosition - 1)
                text.remove(at: index)
                cursorPosition -= 1
            }
        case "⇧":
            isShiftEnabled.toggle()
        default:
            // Insert character at cursor position
            let keyToAdd = isShiftEnabled ? key.uppercased() : key
            
            if cursorPosition == text.count {
                text.append(keyToAdd)
            } else {
                let index = text.index(text.startIndex, offsetBy: cursorPosition)
                text.insert(contentsOf: keyToAdd, at: index)
            }
            
            cursorPosition += 1
            
            // Turn off shift after a letter is typed
            if isShiftEnabled {
                isShiftEnabled = false
            }
        }
    }
    
    private func handleSpecialKeyPress(_ key: String) {
        switch key {
        case "Done":
            onDone()
        case " ":
            // Insert space at cursor position
            if cursorPosition == text.count {
                text.append(" ")
            } else {
                let index = text.index(text.startIndex, offsetBy: cursorPosition)
                text.insert(" ", at: index)
            }
            cursorPosition += 1
        case ",":
            // Insert comma at cursor position
            if cursorPosition == text.count {
                text.append(",")
            } else {
                let index = text.index(text.startIndex, offsetBy: cursorPosition)
                text.insert(",", at: index)
            }
            cursorPosition += 1
        case ".":
            // Insert period at cursor position
            if cursorPosition == text.count {
                text.append(".")
            } else {
                let index = text.index(text.startIndex, offsetBy: cursorPosition)
                text.insert(".", at: index)
            }
            cursorPosition += 1
        case "123":
            // This toggles numeric mode in the keyboard
            isNumericMode.toggle()
            
            // If we had a full numeric keyboard implementation, 
            // we would toggle between letter and number layouts here.
            // In this demo, we'll just add a numeric character as example
            if isNumericMode {
                let nums = "1234567890"
                if !nums.isEmpty {
                    let randIndex = Int.random(in: 0..<nums.count)
                    let randDigit = String(nums[nums.index(nums.startIndex, offsetBy: randIndex)])
                    
                    // Add it at cursor position
                    if cursorPosition == text.count {
                        text.append(randDigit)
                    } else {
                        let index = text.index(text.startIndex, offsetBy: cursorPosition)
                        text.insert(contentsOf: randDigit, at: index)
                    }
                    cursorPosition += 1
                }
            }
        default:
            break
        }
    }
}

#Preview {
    KeyboardView(
        text: .constant("Task Title"),
        isDecimal: false,
        onDismiss: {}
    )
}