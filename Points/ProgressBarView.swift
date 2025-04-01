import SwiftUI

struct ProgressBarView: View {
    @Binding var progress: Float
    @Environment(\.theme) var theme
    
    init(progress: Binding<Float> = .constant(0)) {
        self._progress = progress
    }
    
    var body: some View {
        // Custom progress bar that fills the entire height
        GeometryReader { geometry in
            ZStack(alignment: .leading) {
                // Background
                Rectangle()
                    .fill(theme.progressBackground)
                    .frame(width: geometry.size.width, height: geometry.size.height)
                
                // Progress fill
                Rectangle()
                    .fill(theme.templateTab)
                    .frame(width: geometry.size.width * CGFloat(progress), height: geometry.size.height)
            }
        }
        .frame(height: 18)
    }
    
    // Using template tab color consistently regardless of progress level
    private var progressColor: Color {
        return theme.templateTab
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
