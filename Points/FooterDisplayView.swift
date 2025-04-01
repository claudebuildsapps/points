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

/// Unified footer view that combines tab navigation and task actions
struct FooterDisplayView: View {
    // MARK: - Properties
    @ObservedObject var pointsObserver = PointsObserver()
    @State private var isAnimating: Bool = false
    @Binding var selectedTab: Int
    @Environment(\.theme) private var theme
    
    // Closures to handle button actions
    var onAddButtonTapped: () -> Void = {}
    var onClearButtonTapped: () -> Void = {}
    var onSoftResetButtonTapped: () -> Void = {}
    var onCreateNewTaskInEditMode: () -> Void = {}
    
    // MARK: - Initialization
    init(
        selectedTab: Binding<Int>,
        onAddButtonTapped: @escaping () -> Void = {},
        onClearButtonTapped: @escaping () -> Void = {},
        onSoftResetButtonTapped: @escaping () -> Void = {},
        onCreateNewTaskInEditMode: @escaping () -> Void = {}
    ) {
        self._selectedTab = selectedTab
        self.onAddButtonTapped = onAddButtonTapped
        self.onClearButtonTapped = onClearButtonTapped
        self.onSoftResetButtonTapped = onSoftResetButtonTapped
        self.onCreateNewTaskInEditMode = onCreateNewTaskInEditMode
    }
    
    // MARK: - Body
    var body: some View {
        VStack(spacing: 0) {
            // Buttons row - sits above tabs
            HStack(spacing: 0) {
                tabButton(icon: "plus", color: theme.routinesTab, action: onAddButtonTapped)
                tabButton(icon: "plus", color: theme.tasksTab, action: onAddButtonTapped)
                
                // Points display
                HStack {
                    Spacer()
                    Text("\(pointsObserver.points)")
                        .themeCircleButton(color: theme.templateTab, textColor: theme.textInverted)
                    Spacer()
                }
                .frame(width: UIScreen.main.bounds.width/5)
                
                // Help button
                tabButton(
                    icon: "?", 
                    isText: true, 
                    color: theme.summaryTab, 
                    action: {}
                )
                
                // Database button
                tabButton(
                    icon: "cylinder.split.1x2", 
                    color: theme.dataTab, 
                    action: {}
                )
            }
            .padding(.bottom, 0.5)
            .background(Color.clear)
            .frame(height: 44)
            
            // Tabs row - now part of the footer
            TabBarView(onTabSelected: { index in
                selectedTab = index
            })
            .frame(height: 42) // Reduced by ~30% from original 60
        }
    }
    
    // Helper method to create consistent tab buttons
    private func tabButton(icon: String, isText: Bool = false, color: Color, action: @escaping () -> Void) -> some View {
        HStack {
            Spacer()
            Button(action: action) {
                if isText {
                    Text(icon)
                        .themeCircleButton(color: color, textColor: theme.textInverted)
                } else {
                    Image(systemName: icon)
                        .themeCircleButton(color: color, textColor: theme.textInverted)
                }
            }
            Spacer()
        }
        .frame(width: UIScreen.main.bounds.width/5)
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
        
        Timer.scheduledTimer(withTimeInterval: 1.0 / frameRate, repeats: true) { timer in
            currentFrame += 1
            let percentage = Double(currentFrame) / Double(totalFrames)
            
            if percentage >= 1.0 {
                self.pointsObserver.points = newPoints
                DispatchQueue.main.async {
                    self.isAnimating = false
                }
                timer.invalidate()
            } else {
                let currentPoints = Int(Double(oldPoints) + Double(newPoints - oldPoints) * percentage)
                self.pointsObserver.points = currentPoints
            }
        }
    }
    
    /// Reset the UI
    func resetUI() {
        updatePoints(0, animated: false)
    }
}