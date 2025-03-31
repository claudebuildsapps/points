import SwiftUI

struct ProgressBarView: View {
    // MARK: - Properties
    @Binding var progress: Float
    
    // For backward compatibility and easy initialization
    init(progress: Binding<Float> = .constant(0)) {
        self._progress = progress
    }
    
    // MARK: - Body
    var body: some View {
        ProgressView(value: Double(progress), total: 1.0)
            .progressViewStyle(LinearProgressViewStyle())
            .tint(progressColor)
            .background(Color.gray.opacity(0.2)) // Equivalent to trackTintColor
            .frame(height: 18) // Make it 3x thicker (was 6)
            .clipShape(RoundedRectangle(cornerRadius: 0)) // No rounding
    }
    
    // MARK: - Computed Properties
    private var progressColor: Color {
        if progress < 0.5 {
            return .yellow
        } else if progress < 0.8 {
            return Color(red: 0.5, green: 0.8, blue: 0.2) // Yellow-green
        } else {
            return .green
        }
    }
    
    // MARK: - Methods (for backward compatibility)
    /// Updates the progress value, optionally with animation
    func updateProgress(_ newProgress: Float, animated: Bool = true) {
        let clampedProgress = max(0, min(newProgress, 1.0))
        if animated {
            withAnimation(.easeInOut(duration: 0.3)) {
                progress = clampedProgress
            }
        } else {
            progress = clampedProgress
        }
    }
}

// MARK: - Preview
struct ProgressBarView_Previews: PreviewProvider {
    static var previews: some View {
        ProgressBarView(progress: .constant(0.7))
            .frame(width: 300, height: 20)
            .previewLayout(.sizeThatFits)
            .padding()
    }
}

