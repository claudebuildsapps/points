import SwiftUI

// Simple keyboard view that displays above everything
struct KeyboardView: View {
    @Binding var text: String
    var isDecimal: Bool
    var onDismiss: () -> Void
    @Environment(\.presentationMode) var presentationMode
    @State private var keyboardVisible = false
    
    var body: some View {
        ZStack {
            // Semi-transparent background
            Color.black.opacity(0.4)
                .edgesIgnoringSafeArea(.all)
                .onTapGesture {
                    dismissWithAnimation()
                }
            
            // Position keyboard at bottom
            VStack {
                Spacer()
                
                CustomNumericKeyboard(
                    text: $text,
                    isDecimal: isDecimal,
                    onDone: {
                        dismissWithAnimation()
                    }
                )
                .offset(y: keyboardVisible ? 0 : 300) // Start off-screen when not visible
                .animation(.spring(response: 0.3, dampingFraction: 0.7), value: keyboardVisible)
            }
            .edgesIgnoringSafeArea(.bottom)
        }
        .onAppear {
            // Animate the keyboard sliding up when it appears
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                keyboardVisible = true
            }
        }
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

#Preview {
    KeyboardView(
        text: .constant("123.45"),
        isDecimal: true,
        onDismiss: {}
    )
}
