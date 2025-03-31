import SwiftUI

struct ProgressBarView: View {
    // MARK: - Properties
    @State private var progress: Float = 0.0 // State to manage progress value
    
    // MARK: - Body
    var body: some View {
        ProgressView(value: progress, total: 1.0)
            .progressViewStyle(LinearProgressViewStyle())
            .tint(progressColor)
            .background(Color.gray.opacity(0.2)) // Equivalent to trackTintColor
            .frame(height: 6) // Make it thicker (equivalent to transform scale)
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
    
    // MARK: - Methods
    /// Updates the progress value, optionally with animation
    func updateProgress(_ progress: Float, animated: Bool = true) {
        if animated {
            withAnimation(.easeInOut(duration: 0.3)) {
                self.progress = max(0, min(progress, 1.0)) // Clamp between 0 and 1
            }
        } else {
            self.progress = max(0, min(progress, 1.0))
        }
    }
}

// MARK: - Preview
struct ProgressBarView_Previews: PreviewProvider {
    static var previews: some View {
        ProgressBarView()
            .frame(width: 300, height: 20)
            .onAppear {
                // Simulate progress update for preview
                let view = ProgressBarView()
                view.updateProgress(0.7)
                // Remove the return statement
            }
            .previewLayout(.sizeThatFits)
            .padding()
    }
}

