import SwiftUI

struct CustomNumericKeyboard: View {
    @Binding var text: String
    var isDecimal: Bool
    var onDone: () -> Void
    
    private let keyboardRows: [[String]] = [
        ["1", "2", "3"],
        ["4", "5", "6"],
        ["7", "8", "9"],
        [".", "0", "⌫"]
    ]
    
    var body: some View {
        VStack(spacing: 0) {
            // Top bar with value and clear button
            HStack {
                Text(text.isEmpty ? "0" : text)
                    .font(.system(size: 20, weight: .semibold))
                    .padding()
                    .frame(maxWidth: .infinity, alignment: .trailing)
                
                Button(action: {
                    text = ""
                }) {
                    Image(systemName: "xmark.circle.fill")
                        .font(.system(size: 22))
                        .foregroundColor(.gray)
                }
                .padding(.trailing, 16)
            }
            .background(Color(.systemGray6))
            
            // Keyboard buttons
            VStack(spacing: 10) {
                ForEach(keyboardRows, id: \.self) { row in
                    HStack(spacing: 10) {
                        ForEach(row, id: \.self) { key in
                            Button(action: {
                                handleKeyPress(key)
                            }) {
                                if key == "⌫" {
                                    Image(systemName: "delete.left")
                                        .font(.system(size: 20))
                                        .foregroundColor(.red)
                                        .frame(maxWidth: .infinity)
                                        .frame(height: 60)
                                        .background(Color(.systemGray5))
                                        .cornerRadius(10)
                                } else {
                                    Text(key)
                                        .font(.system(size: 26, weight: .medium))
                                        .frame(maxWidth: .infinity)
                                        .frame(height: 60)
                                        .background(Color(.systemGray5))
                                        .foregroundColor(.primary)
                                        .cornerRadius(10)
                                }
                            }
                            .disabled(key == "." && (!isDecimal || text.contains(".")))
                        }
                    }
                }
                
                // Done button
                Button(action: onDone) {
                    Text("Done")
                        .font(.system(size: 20, weight: .semibold))
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .frame(height: 60)
                        .background(Color.blue)
                        .cornerRadius(10)
                }
                .padding(.top, 10)
            }
            .padding(15)
        }
        .background(Color(.systemBackground))
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
            onDone: {}
        )
    }
}
