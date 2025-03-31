import SwiftUI

// Define a struct for the FooterDisplayView in SwiftUI
class PointsObserver: ObservableObject {
    @Published var points: Int = 0
    
    init() {
        // Setup notification observer
        NotificationCenter.default.addObserver(self, selector: #selector(updatePoints), name: NSNotification.Name("UpdatePointsDisplay"), object: nil)
        print("PointsObserver: Initialized and observing for point updates")
    }
    
    @objc func updatePoints(notification: Notification) {
        if let userInfo = notification.userInfo, let points = userInfo["points"] as? Int {
            DispatchQueue.main.async {
                print("PointsObserver: Received update, setting points to \(points)")
                self.points = points
            }
        } else {
            print("PointsObserver: Received notification but couldn't extract points value")
        }
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self)
    }
}

struct FooterDisplayView: View {
    // MARK: - Properties
    @ObservedObject var pointsObserver = PointsObserver()
    @State private var isAnimating: Bool = false // State to manage animation
    
    // Closures to handle button actions (replacing the delegate pattern)
    let onAddButtonTapped: () -> Void
    let onClearButtonTapped: () -> Void
    let onSoftResetButtonTapped: () -> Void
    let onCreateNewTaskInEditMode: () -> Void
    
    // Computed property to get points from observer
    private var points: Int {
        return pointsObserver.points
    }
    
    // MARK: - Body
    var body: some View {
        // Horizontal layout precisely aligned with tabs
        HStack(spacing: 0) {
            // First tab (Routines) with blue plus button
            HStack {
                Spacer()
                
                // Add Routine Button with Routines tab color (now green)
                Button(action: {
                    // Add a routine task (you may want to handle this differently)
                    onAddButtonTapped()
                }) {
                    ZStack {
                        Circle()
                            .fill(Color(red: 0.5, green: 0.7, blue: 0.6)) // Routines tab color (Green)
                            .frame(width: 32, height: 32)
                            
                        Image(systemName: "plus")
                            .font(.system(size: 16, weight: .bold))
                            .foregroundColor(.white)
                    }
                }
                
                Spacer()
            }
            .frame(width: UIScreen.main.bounds.width/5)
            
            // Second tab (Tasks) with blue plus button
            HStack {
                Spacer()
                
                // Add Task Button with Task tab color (now blue)
                Button(action: {
                    onAddButtonTapped()
                }) {
                    ZStack {
                        Circle()
                            .fill(Color(red: 0.4, green: 0.6, blue: 0.8)) // Tasks tab color (Blue)
                            .frame(width: 32, height: 32)
                            
                        Image(systemName: "plus")
                            .font(.system(size: 16, weight: .bold))
                            .foregroundColor(.white)
                    }
                }
                
                Spacer()
            }
            .frame(width: UIScreen.main.bounds.width/5)
            
            // Third tab (Template) with Points circle
            HStack {
                Spacer()
                
                // Points circle with Template tab color
                ZStack {
                    Circle()
                        .fill(Color(red: 0.6, green: 0.65, blue: 0.75)) // Template tab color (Bluish-purple)
                        .frame(width: 32, height: 32)
                    
                    Text("\(Int(points))")  // Display without decimal places
                        .font(.system(size: 16, weight: .bold))
                        .foregroundColor(.white)
                }
                
                Spacer()
            }
            .frame(width: UIScreen.main.bounds.width/5)
            
            // Fourth tab (Summary) with help button (?)
            HStack {
                Spacer()
                
                // Help button with Summary tab color (orange)
                Button(action: {
                    // Help action
                }) {
                    ZStack {
                        Circle()
                            .fill(Color(red: 0.7, green: 0.6, blue: 0.5))  // Summary tab color (Orange)
                            .frame(width: 32, height: 32)
                            
                        Text("?")
                            .font(.system(size: 18, weight: .bold))
                            .foregroundColor(.white)
                    }
                }
                
                Spacer()
            }
            .frame(width: UIScreen.main.bounds.width/5)
            
            // Fifth tab (Data) with database icon
            HStack {
                Spacer()
                
                // Database button with Data tab color (red)
                Button(action: {
                    // Database action
                }) {
                    ZStack {
                        Circle()
                            .fill(Color(red: 0.8, green: 0.5, blue: 0.4))  // Data tab color (Red)
                            .frame(width: 32, height: 32)
                            
                        Image(systemName: "cylinder.split.1x2")  // Database icon
                            .font(.system(size: 16, weight: .bold))
                            .foregroundColor(.white)
                    }
                }
                
                Spacer()
            }
            .frame(width: UIScreen.main.bounds.width/5)
        }
        .padding(.bottom, 0.5) // Extremely close to the tabs
        .background(Color.clear)
        .frame(height: 44) // Just enough height for the buttons
    }
    
    // MARK: - Methods
    /// Updates the points value, optionally with animation
    func updatePoints(_ newPoints: Int, animated: Bool = true) {
        if animated {
            animatePointChange(to: newPoints)
        } else {
            pointsObserver.points = newPoints
        }
    }
    
    /// Animates the points change from the current value to the new value
    private func animatePointChange(to newPoints: Int) {
        guard !isAnimating else { return }
        isAnimating = true
        
        let oldPoints = pointsObserver.points
        let duration: TimeInterval = 0.75
        let frameRate: Double = 30
        let totalFrames = Int(duration * frameRate)
        var currentFrame = 0
        
        // Store in a local variable to avoid capturing self in timer
        let observer = pointsObserver
        
        Timer.scheduledTimer(withTimeInterval: 1.0 / frameRate, repeats: true) { timer in
            currentFrame += 1
            let percentage = Double(currentFrame) / Double(totalFrames)
            
            if percentage >= 1.0 {
                observer.points = newPoints
                DispatchQueue.main.async {
                    self.isAnimating = false
                }
                timer.invalidate()
            } else {
                let currentPoints = Int(Double(oldPoints) + Double(newPoints - oldPoints) * percentage)
                observer.points = currentPoints
            }
        }
    }
    
    /// Returns the current points value
    func getCurrentPoints() -> Int {
        return pointsObserver.points
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
