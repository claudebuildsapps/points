import SwiftUI

struct ProgressBarView: View {
    @Binding var progress: Float
    @Environment(\.theme) var theme
    
    init(progress: Binding<Float> = .constant(0)) {
        self._progress = progress
    }
    
    var body: some View {
        ProgressView(value: Double(progress), total: 1.0)
            .progressViewStyle(LinearProgressViewStyle())
            .tint(progressColor)
            .background(theme.progressBackground)
            .frame(height: 18)
            .clipShape(RoundedRectangle(cornerRadius: 0))
    }
    
    // Color changes based on progress level using theme
    private var progressColor: Color {
        switch progress {
        case ..<0.5:
            return theme.progressLow
        case 0.5..<0.8:
            return theme.progressMedium
        default:
            return theme.progressHigh
        }
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