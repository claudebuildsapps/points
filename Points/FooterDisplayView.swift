import SwiftUI

// Define a struct for the FooterDisplayView in SwiftUI
struct FooterDisplayView: View {
    // MARK: - Properties
    @State private var points: Int = 0 // State to manage the points value
    @State private var isAnimating: Bool = false // State to manage animation
    
    // Closures to handle button actions (replacing the delegate pattern)
    let onAddButtonTapped: () -> Void
    let onClearButtonTapped: () -> Void
    let onSoftResetButtonTapped: () -> Void
    let onCreateNewTaskInEditMode: () -> Void
    
    // MARK: - Body
    var body: some View {
        HStack {
            // Points Label
            Text("\(points)")
                .font(.system(size: 28, weight: .bold))
                .foregroundColor(.primary)
                .padding(.leading, 8)
            
            Spacer()
            
            // Soft Reset Button
            Button(action: {
                onSoftResetButtonTapped()
            }) {
                Image(systemName: "arrow.clockwise.circle.fill")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 52, height: 52)
                    .foregroundColor(.blue)
                    .shadow(color: .black.opacity(0.2), radius: 2, x: 0, y: 1)
            }
            .padding(.trailing, 12)
            
            // Clear Button
            Button(action: {
                onClearButtonTapped()
            }) {
                Image(systemName: "xmark.circle.fill")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 52, height: 52)
                    .foregroundColor(.red)
                    .shadow(color: .black.opacity(0.2), radius: 2, x: 0, y: 1)
            }
            .padding(.trailing, 12)
            
            // Add Button
            Button(action: {
                onCreateNewTaskInEditMode()
            }) {
                Image(systemName: "plus.circle.fill")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 52, height: 52)
                    .foregroundColor(.green)
                    .shadow(color: .black.opacity(0.2), radius: 2, x: 0, y: 1)
            }
            .padding(.trailing, 8)
        }
        .background(Color.clear)
        .frame(height: 60) // Adjust height to match the UIKit version
    }
    
    // MARK: - Methods
    /// Updates the points value, optionally with animation
    func updatePoints(_ newPoints: Int, animated: Bool = true) {
        if animated {
            animatePointChange(to: newPoints)
        } else {
            points = newPoints
        }
    }
    
    /// Animates the points change from the current value to the new value
    private func animatePointChange(to newPoints: Int) {
        guard !isAnimating else { return }
        isAnimating = true
        
        let oldPoints = points
        let duration: TimeInterval = 0.75
        let frameRate: Double = 30
        let totalFrames = Int(duration * frameRate)
        var currentFrame = 0
        
        Timer.scheduledTimer(withTimeInterval: 1.0 / frameRate, repeats: true) { timer in
            currentFrame += 1
            let percentage = Double(currentFrame) / Double(totalFrames)
            
            if percentage >= 1.0 {
                points = newPoints
                isAnimating = false
                timer.invalidate()
            } else {
                let currentPoints = Int(Double(oldPoints) + Double(newPoints - oldPoints) * percentage)
                points = currentPoints
            }
        }
    }
    
    /// Returns the current points value
    func getCurrentPoints() -> Int {
        return points
    }
    
    /// Resets the UI (replaces fullReloadUI)
    func resetUI() {
        updatePoints(0, animated: false)
    }
}

// MARK: - Preview
struct FooterDisplayView_Previews: PreviewProvider {
    static var previews: some View {
        FooterDisplayView(
            onAddButtonTapped: { print("Add button tapped") },
            onClearButtonTapped: { print("Clear button tapped") },
            onSoftResetButtonTapped: { print("Soft reset button tapped") },
            onCreateNewTaskInEditMode: { print("Create new task in edit mode") }
        )
        .previewLayout(.sizeThatFits)
        .padding()
    }
}
