import SwiftUI

struct CustomNumericKeyboard: View {
    @Binding var text: String
    var isDecimal: Bool
    var colorScheme: ColorScheme
    var screenWidth: CGFloat
    var onDone: () -> Void
    
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
            // Top bar with value and clear button
            ZStack {
                // Value display
                Text(text.isEmpty ? "0" : text)
                    .font(.system(size: 26, weight: .semibold))
                    .padding()
                    .frame(maxWidth: .infinity, alignment: .trailing)
                
                // Clear button at the right
                HStack {
                    Spacer()
                    Button(action: {
                        text = ""
                    }) {
                        Image(systemName: "xmark.circle.fill")
                            .font(.system(size: 24))
                            .foregroundColor(.gray)
                    }
                    .padding(.trailing, 16)
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
                
                // Function row with Cancel/Done buttons - full width
                HStack(spacing: 6) {
                    // Cancel button
                    Button(action: {
                        text = ""  // Clear the text and then dismiss
                        onDone()
                    }) {
                        Text("Cancel")
                            .font(.system(size: 20))
                            .foregroundColor(.red)
                            .frame(maxWidth: .infinity)
                            .frame(height: 60)
                            .background(Color.red.opacity(0.1))
                            .cornerRadius(8)
                    }
                    
                    // Done button
                    Button(action: onDone) {
                        Text("Done")
                            .font(.system(size: 20, weight: .semibold))
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .frame(height: 60)
                            .background(Color.blue)
                            .cornerRadius(8)
                    }
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
            // Prevent multiple leading zeros
            if text == "0" && key != "." {
                text = key
            } else {
                text += key
            }
        }
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
