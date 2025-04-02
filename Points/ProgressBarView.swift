import SwiftUI

struct ProgressBarView: View {
    @Binding var progress: Float
    @Environment(\.theme) var theme
    @State private var isHighlighted: Bool = false
    
    init(progress: Binding<Float> = .constant(0)) {
        self._progress = progress
    }
    
    var body: some View {
        // Clean, simple progress bar with rounded corners
        GeometryReader { geometry in
            ZStack(alignment: .leading) {
                // Background
                Rectangle()
                    .fill(theme.progressBackground)
                    .cornerRadius(9)
                    .frame(width: geometry.size.width, height: geometry.size.height)
                
                // Progress fill with gradient
                Rectangle()
                    .fill(
                        LinearGradient(
                            gradient: Gradient(colors: [
                                theme.templateTab,
                                theme.templateTab.opacity(0.8)
                            ]),
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .cornerRadius(9)
                    .frame(width: geometry.size.width * CGFloat(progress), height: geometry.size.height)
                    // Subtle pulse animation on progress
                    .scaleEffect(y: isHighlighted ? 1.05 : 1.0)
                    .animation(.easeInOut(duration: 0.5).repeatForever(autoreverses: true), value: isHighlighted)
            }
        }
        .frame(height: 18)
        .onAppear {
            // Start subtle pulse animation
            self.isHighlighted = true
        }
        .padding(.horizontal, 10) // Add horizontal padding
    }
    
    // Update progress with optional animation
    func updateProgress(_ newProgress: Float, animated: Bool = true) {
        let clampedProgress = max(0, min(newProgress, 1.0))
        if animated {
            withAnimation(.easeInOut(duration: Constants.Animation.standard)) {
                progress = clampedProgress
            }
        } else {
            progress = clampedProgress
        }
    }
}

struct ProgressBarView_Previews: PreviewProvider {
    static var previews: some View {
        ProgressBarView(progress: .constant(0.7))
            .frame(width: 300, height: 20)
            .previewLayout(.sizeThatFits)
            .padding()
    }
}
