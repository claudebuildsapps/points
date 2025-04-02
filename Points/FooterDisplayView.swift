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
    @Binding var taskFilter: TaskFilter
    @Environment(\.theme) private var theme
    @Environment(\.colorScheme) private var colorScheme
    
    // Closures to handle button actions
    var onRoutineButtonTapped: () -> Void = {} // Specifically for the purple + button
    var onTaskButtonTapped: () -> Void = {}    // Specifically for the blue + button
    var onHomeButtonTapped: () -> Void = {}    // For the home/today button
    var onHelpButtonTapped: () -> Void = {}    // For the help/delete all button
    var onClearButtonTapped: () -> Void = {}
    var onSoftResetButtonTapped: () -> Void = {}
    var onCreateNewTaskInEditMode: () -> Void = {}
    var onThemeToggle: () -> Void = {}
    var onFilterChanged: (TaskFilter) -> Void = { _ in }
    
    // MARK: - Initialization
    init(
        selectedTab: Binding<Int>,
        taskFilter: Binding<TaskFilter>,
        onRoutineButtonTapped: @escaping () -> Void = {},
        onTaskButtonTapped: @escaping () -> Void = {},
        onHomeButtonTapped: @escaping () -> Void = {},
        onHelpButtonTapped: @escaping () -> Void = {},
        onClearButtonTapped: @escaping () -> Void = {},
        onSoftResetButtonTapped: @escaping () -> Void = {},
        onCreateNewTaskInEditMode: @escaping () -> Void = {},
        onThemeToggle: @escaping () -> Void = {},
        onFilterChanged: @escaping (TaskFilter) -> Void = { _ in }
    ) {
        self._selectedTab = selectedTab
        self._taskFilter = taskFilter
        self.onRoutineButtonTapped = onRoutineButtonTapped
        self.onTaskButtonTapped = onTaskButtonTapped
        self.onHomeButtonTapped = onHomeButtonTapped
        self.onHelpButtonTapped = onHelpButtonTapped
        self.onClearButtonTapped = onClearButtonTapped
        self.onSoftResetButtonTapped = onSoftResetButtonTapped
        self.onCreateNewTaskInEditMode = onCreateNewTaskInEditMode
        self.onThemeToggle = onThemeToggle
        self.onFilterChanged = onFilterChanged
    }
    
    // MARK: - Body
    var body: some View {
        VStack(spacing: 0) {
            // Buttons row - sits above tabs
            HStack(spacing: 0) {
                // Purple + button - ALWAYS creates a Routine
                tabButton(icon: "plus", color: theme.routinesTab, action: onRoutineButtonTapped)
                // Blue + button - ALWAYS creates a Task
                tabButton(icon: "plus", color: theme.tasksTab, action: onTaskButtonTapped)
                
                // Home button in the center, positioned higher
                HStack {
                    Spacer()
                    VStack {
                        // Added a VStack to control vertical position
                        Button(action: onHomeButtonTapped) {
                            ZStack {
                                // Background circle with summary tab color
                                Circle()
                                    .fill(theme.summaryTab)
                                    .frame(width: 50, height: 50)
                                    .shadow(color: theme.summaryTab.opacity(0.6), radius: 10, x: 0, y: 0)
                                
                                // Home icon in white
                                Image(systemName: "house.fill")
                                    .font(.system(size: 22, weight: .bold))
                                    .foregroundColor(.white)
                            }
                        }
                        .buttonStyle(PlainButtonStyle())
                        
                        // Add more space to position the button higher
                        Spacer().frame(height: 14)
                    }
                    Spacer()
                }
                .frame(width: UIScreen.main.bounds.width/5)
                
                // Help/Delete button
                tabButton(
                    icon: "xmark.bin", 
                    isText: false, 
                    color: theme.summaryTab, 
                    action: onHelpButtonTapped
                )
                
                // Theme toggle button
                tabButton(
                    icon: colorScheme == .dark ? "sun.max.fill" : "moon.fill", 
                    color: theme.dataTab, 
                    action: onThemeToggle
                )
            }
            .padding(.bottom, 14) // Doubled from 7 to 14 for increased spacing between buttons and tabs
            .background(Color.clear)
            .frame(height: 44)
            
            // Tabs row - now part of the footer using the original TabBarView
            TabBarView(
                selectedIndex: selectedTab,
                taskFilter: taskFilter,
                onTabSelected: { index in
                // Handle tab selection with proper toggling
                if index == 0 {
                    // Routines tab behavior
                    if taskFilter == .routines {
                        // Already filtering routines, toggle back to all
                        onFilterChanged(.all)
                    } else {
                        // Apply routines filter
                        onFilterChanged(.routines)
                    }
                } else if index == 1 {
                    // Tasks tab behavior
                    if taskFilter == .tasks {
                        // Already filtering tasks, toggle back to all
                        onFilterChanged(.all)
                    } else {
                        // Apply tasks filter
                        onFilterChanged(.tasks)
                    }
                } else if index >= 2 {
                    // Only change selected tab for tabs 2-4
                    selectedTab = index
                    
                    // Reset filter when switching to other tabs
                    onFilterChanged(.all)
                }
            })
            .frame(height: 50) // Increased by 20% from 42 to 50
        }
    }
    
    // Helper to get the tab color for placeholder tabs
    private func getTabColor(index: Int) -> Color {
        switch index {
            case 2: return theme.templateTab
            case 3: return theme.summaryTab
            case 4: return theme.dataTab
            default: return .gray
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
        
        // Flash animation when points change
        withAnimation(.easeInOut(duration: 0.2)) {
            isAnimating = true
        }
        
        Timer.scheduledTimer(withTimeInterval: 1.0 / frameRate, repeats: true) { timer in
            currentFrame += 1
            let percentage = Double(currentFrame) / Double(totalFrames)
            
            if percentage >= 1.0 {
                self.pointsObserver.points = newPoints
                DispatchQueue.main.async {
                    // Reset animation state with slight delay for visual effect
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                        withAnimation(.easeInOut(duration: 0.3)) {
                            self.isAnimating = false
                        }
                    }
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