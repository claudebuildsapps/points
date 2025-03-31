import SwiftUI

// Define a class to observe points updates
class PointsObserver: ObservableObject {
    @Published var points: Int = 0
    
    init() {
        // Setup notification observer
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(updatePoints),
            name: Constants.Notifications.updatePointsDisplay,
            object: nil
        )
    }
    
    @objc func updatePoints(notification: Notification) {
        if let userInfo = notification.userInfo, let points = userInfo["points"] as? Int {
            DispatchQueue.main.async {
                self.points = points
            }
        }
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self)
    }
}

struct FooterDisplayView: View {
    // MARK: - Properties
    @ObservedObject var pointsObserver = PointsObserver()
    @State private var isAnimating: Bool = false
    
    // Closures to handle button actions
    let onAddButtonTapped: () -> Void
    let onClearButtonTapped: () -> Void
    let onSoftResetButtonTapped: () -> Void
    let onCreateNewTaskInEditMode: () -> Void
    
    // MARK: - Body
    var body: some View {
        // Horizontal layout aligned with tabs
        HStack(spacing: 0) {
            // Routines tab with green plus button
            HStack {
                Spacer()
                
                // Add Routine Button
                Button(action: onAddButtonTapped) {
                    ZStack {
                        Circle()
                            .fill(Constants.Colors.routinesTab)
                            .frame(width: 32, height: 32)
                            
                        Image(systemName: "plus")
                            .font(.system(size: 16, weight: .bold))
                            .foregroundColor(.white)
                    }
                }
                
                Spacer()
            }
            .frame(width: UIScreen.main.bounds.width/5)
            
            // Tasks tab with blue plus button
            HStack {
                Spacer()
                
                // Add Task Button
                Button(action: onAddButtonTapped) {
                    ZStack {
                        Circle()
                            .fill(Constants.Colors.tasksTab)
                            .frame(width: 32, height: 32)
                            
                        Image(systemName: "plus")
                            .font(.system(size: 16, weight: .bold))
                            .foregroundColor(.white)
                    }
                }
                
                Spacer()
            }
            .frame(width: UIScreen.main.bounds.width/5)
            
            // Template tab with Points circle
            HStack {
                Spacer()
                
                // Points circle
                ZStack {
                    Circle()
                        .fill(Constants.Colors.templateTab)
                        .frame(width: 32, height: 32)
                    
                    Text("\(pointsObserver.points)")
                        .font(.system(size: 16, weight: .bold))
                        .foregroundColor(.white)
                }
                
                Spacer()
            }
            .frame(width: UIScreen.main.bounds.width/5)
            
            // Summary tab with help button
            HStack {
                Spacer()
                
                // Help button
                Button(action: {}) {
                    ZStack {
                        Circle()
                            .fill(Constants.Colors.summaryTab)
                            .frame(width: 32, height: 32)
                            
                        Text("?")
                            .font(.system(size: 18, weight: .bold))
                            .foregroundColor(.white)
                    }
                }
                
                Spacer()
            }
            .frame(width: UIScreen.main.bounds.width/5)
            
            // Data tab with database icon
            HStack {
                Spacer()
                
                // Database button
                Button(action: {}) {
                    ZStack {
                        Circle()
                            .fill(Constants.Colors.dataTab)
                            .frame(width: 32, height: 32)
                            
                        Image(systemName: "cylinder.split.1x2")
                            .font(.system(size: 16, weight: .bold))
                            .foregroundColor(.white)
                    }
                }
                
                Spacer()
            }
            .frame(width: UIScreen.main.bounds.width/5)
        }
        .padding(.bottom, 0.5)
        .background(Color.clear)
        .frame(height: 44)
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
    
    /// Animates the points change
    private func animatePointChange(to newPoints: Int) {
        guard !isAnimating else { return }
        isAnimating = true
        
        let oldPoints = pointsObserver.points
        let duration: TimeInterval = 0.75
        let frameRate: Double = 30
        let totalFrames = Int(duration * frameRate)
        var currentFrame = 0
        
        // Store in a local variable to avoid capturing self
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
    
    /// Reset the UI
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