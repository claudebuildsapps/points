import SwiftUI

struct ProgressBarView: View {
    @Binding var progress: Float
    @Environment(\.theme) var theme
    @Environment(\.managedObjectContext) private var context
    @State private var dailyTarget: Int = 100 // Default target
    @State private var isEditingTarget: Bool = false // Track if target is being edited
    @State private var editableTarget: String = "100" // For editing with keyboard
    
    // Points value passed from parent
    var actualPoints: Int = 0
    
    // For internal rendering and animation
    @State private var animatedPointsValue: Double = 0
    
    // Add a dedicated property for the displayed text value
    // This will animate independently of the position
    @State private var displayedTextValue: Int = 0
    
    // Animation configuration for consistent animations - faster but still visible
    private let pointsAnimation = Animation.easeInOut(duration: 0.5)
    
    // Custom green color for target marker
    private let darkGreenColor = Color(red: 0.2, green: 0.6, blue: 0.4) // Vibrant green that fits better with the palette
    
    init(progress: Binding<Float> = .constant(0), actualPoints: Int = 0) {
        self._progress = progress
        self.actualPoints = actualPoints
    }
    
    var body: some View {
        // Compact progress bar with no extra spacing
        VStack(spacing: 0) {
            // Full-width rectangular progress bar with target indicator
            GeometryReader { geometry in
                ZStack(alignment: .leading) {
                    // Calculate positions and values
                    let targetRatio = CGFloat(dailyTarget) / 150.0
                    let targetPosition = min(geometry.size.width * 0.75, geometry.size.width * targetRatio)
                    let progressWidth = geometry.size.width * CGFloat(progress)
                    let isOverTarget = progressWidth > targetPosition
                    
                    // Use the animated points value for smooth transitions
                    let displayPoints: Int = Int(animatedPointsValue.rounded())
                    
                    // Create an animating number formatter
                    var formatter: NumberFormatter = {
                        let f = NumberFormatter()
                        f.numberStyle = .decimal
                        f.maximumFractionDigits = 0
                        return f
                    }()
                    
                    // Calculate indicator position based on animated points, not progress width
                    let targetRatioFloat = Float(dailyTarget) / 150.0 // Same scaling as in target position calculation
                    let pointsProgressRatio = min(Float(animatedPointsValue) / Float(dailyTarget), 1.0)
                    let normalizedProgress = pointsProgressRatio * targetRatioFloat
                    
                    // Calculate position as a direct mapping of points to width
                    let indicatorPosition = min(CGFloat(normalizedProgress) * geometry.size.width, geometry.size.width - 24) // Prevent overflow
                    let indicatorColor: Color = displayPoints >= dailyTarget ? theme.dataTab : theme.templateTab
                    
                    // Background - full width rectangle with minimal rounding
                    ZStack {
                        Rectangle()
                            .fill(theme.progressBackground)
                            .cornerRadius(2)
                            .frame(width: geometry.size.width, height: geometry.size.height)
                    }
                    .contentShape(Rectangle()) // Ensure the entire area is tappable
                    .helpMetadata(HelpMetadata(
                        id: "progress-bar-base",
                        title: "Progress Bar Background",
                        description: "The gray background represents the full scale of possible points.",
                        usageHints: [
                            "The progress bar shows 0 to about 300 points",
                            "Your daily target appears as a green vertical line"
                        ],
                        importance: .informational
                    ))
                    
                    // Progress fill up to target - calculate width based on actual points
                    let actualProgressWidth = CGFloat(normalizedProgress) * geometry.size.width
                    
                    // Gold progress section - properly aligned to left edge
                    Rectangle()
                        .fill(
                            LinearGradient(
                                gradient: Gradient(colors: [
                                    theme.templateTab,
                                    theme.templateTab.opacity(0.85)
                                ]),
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .cornerRadius(2)
                        .frame(width: min(max(0, actualProgressWidth), targetPosition), height: geometry.size.height)
                        .alignmentGuide(.leading) { _ in 0 } // Force alignment to left edge
                        // Removed per-element animation in favor of parent withAnimation
                        .contentShape(Rectangle())
                    .helpMetadata(HelpMetadata(
                        id: "progress-bar-to-target",
                        title: "Progress to Target",
                        description: "This gold section shows your progress toward your daily target.",
                        usageHints: [
                            "Fills from left to right as you earn points",
                            "Turns completely gold when you reach your target"
                        ],
                        importance: .important
                    ))
                    
                    // Additional progress beyond target - data tab color
                    if animatedPointsValue > Double(dailyTarget) {
                        // Calculate width based on animated points value
                        let beyondTargetRatio = min(Float(animatedPointsValue - Double(dailyTarget)) / 150.0, 1.0)
                        let beyondTargetWidth = CGFloat(beyondTargetRatio) * geometry.size.width
                        
                        ZStack {
                            Rectangle()
                                .fill(theme.dataTab)
                                .cornerRadius(2)
                                .frame(width: beyondTargetWidth, height: geometry.size.height)
                                // Removed per-element animation in favor of parent withAnimation
                        }
                        .position(x: (beyondTargetWidth / 2) + targetPosition, y: geometry.size.height / 2)
                        .contentShape(Rectangle())
                        .helpMetadata(HelpMetadata(
                            id: "progress-bar-beyond-target",
                            title: "Points Beyond Target",
                            description: "This blue section shows points earned beyond your daily target.",
                            usageHints: [
                                "Celebrates overachievement!",
                                "Shows how far you've exceeded your goal",
                                "Different color indicates bonus points"
                            ],
                            importance: .important
                        ))
                    }
                    
                    // Target marker/indicator
                    ZStack {
                        // Target decoration
                        Rectangle()
                            .fill(darkGreenColor)
                            .frame(width: 3, height: geometry.size.height + 10)
                        
                        // Clickable target value badge
                        Button(action: {
                            // Initialize editable target with current value
                            editableTarget = "\(dailyTarget)"
                            isEditingTarget = true
                        }) {
                            ZStack {
                                // Background pill
                                Capsule()
                                    .fill(darkGreenColor)
                                    .frame(width: 48, height: 24)
                                    .shadow(color: Color.black.opacity(0.2), radius: 2, x: 0, y: 1)
                                
                                // Target number
                                Text("\(dailyTarget)")
                                    .font(.system(size: 13, weight: .bold))
                                    .foregroundColor(.white)
                            }
                        }
                        .buttonStyle(PlainButtonStyle()) // Remove button styling
                        .offset(y: -20) // Reduced offset by 4pt (16.7% reduction)
                        .helpMetadata(HelpMetadata(
                            id: "target-indicator",
                            title: "Daily Target",
                            description: "Your daily point goal shown as a green marker.",
                            usageHints: [
                                "Tap this green bubble to change your daily target",
                                "Reaching your target completes your day",
                                "The app will remember your target setting"
                            ],
                            importance: .important
                        ))
                    }
                    .position(x: targetPosition, y: geometry.size.height / 2)
                    
                    // Current points indicator - show even at 0
                    ZStack {
                        // Points decoration line
                        Rectangle()
                            .fill(indicatorColor)
                            .frame(width: 3, height: geometry.size.height + 10)
                        
                        // Current points bubble
                        ZStack {
                            // Background pill
                            Capsule()
                                .fill(indicatorColor)
                                .frame(width: displayPoints > 999 ? 60 : 48, height: 24)
                                .shadow(color: Color.black.opacity(0.2), radius: 2, x: 0, y: 1)
                            
                            // Always show the value from our displayedTextValue property
                            Text("\(displayedTextValue)")
                                .font(.system(size: 13, weight: .bold))
                                .foregroundColor(.white)
                                .minimumScaleFactor(0.8)
                                // Important: Do not use any transition or animation on the Text itself
                                .id("staticPointsDisplay")
                        }
                        .offset(y: -20) // Reduced offset by 4pt (16.7% reduction)
                        .helpMetadata(HelpMetadata(
                            id: "points-indicator",
                            title: "Current Points",
                            description: "Shows your total earned points for the day.",
                            usageHints: [
                                "The bubble color matches the progress bar section",
                                "Gold before reaching target, blue when exceeding target",
                                "Updates in real-time as you complete tasks"
                            ],
                            importance: .important
                        ))
                    }
                    .position(x: displayPoints > 0 ? indicatorPosition : 0, y: geometry.size.height / 2) // Place at far left (0) when points are 0
                }
            }
            .frame(height: 20) // Reduced height by 16.7%
            // Apply a consistent Z-index to ensure proper layering in help mode
            .zIndex(10) // Ensure progress bar is properly layered
            // Removed implicit animation - relying on explicit withAnimation for better control
        }
        .padding(.horizontal, 0) // No horizontal padding - truly full width
        .onAppear {
            // Get daily target from CoreData
            loadDailyTarget()
            
            // Initialize both animated value and displayed text value
            animatedPointsValue = Double(actualPoints)
            displayedTextValue = actualPoints
            
            print("ProgressBarView appeared with points: \(actualPoints)")
        }
        // Watch for changes to actualPoints and animate accordingly
        .onChange(of: actualPoints) { newValue in
            print("Points changed: \(animatedPointsValue) -> \(newValue)")
            
            // CRITICAL: Do not change displayed text until animation completes
            // Start only with position animation, keeping old text value
            withAnimation(Animation.easeInOut(duration: 0.5)) {
                // Update position animation value immediately
                animatedPointsValue = Double(newValue)
                
                // Animate position only, text will update after animation completes
            }
            
            // After animation is complete, update the displayed text value
            // No animation on the text value itself, just a delayed update
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                displayedTextValue = newValue
            }
        }
        // Present numeric keyboard when editing target
        .sheet(isPresented: $isEditingTarget) {
            // Numeric keyboard for editing target
            VStack {
                Text("Set Daily Target")
                    .font(.headline)
                    .padding()
                
                Text(editableTarget.isEmpty ? "0" : editableTarget)
                    .font(.system(size: 36, weight: .bold))
                    .padding()
                
                // Custom numeric keypad
                VStack(spacing: 10) {
                    // Number rows
                    ForEach(0..<3) { row in
                        HStack(spacing: 20) {
                            ForEach(1...3, id: \.self) { col in
                                let number = row * 3 + col
                                Button(action: {
                                    // Append digit
                                    editableTarget += "\(number)"
                                }) {
                                    Text("\(number)")
                                        .font(.system(size: 24, weight: .medium))
                                        .frame(width: 60, height: 60)
                                        .background(Color.gray.opacity(0.2))
                                        .cornerRadius(30)
                                }
                            }
                        }
                    }
                    
                    // Last row with 0, clear, done
                    HStack(spacing: 20) {
                        // Clear button
                        Button(action: {
                            editableTarget = ""
                        }) {
                            Image(systemName: "delete.left")
                                .font(.system(size: 24))
                                .frame(width: 60, height: 60)
                                .background(Color.red.opacity(0.2))
                                .cornerRadius(30)
                        }
                        
                        // 0 button
                        Button(action: {
                            editableTarget += "0"
                        }) {
                            Text("0")
                                .font(.system(size: 24, weight: .medium))
                                .frame(width: 60, height: 60)
                                .background(Color.gray.opacity(0.2))
                                .cornerRadius(30)
                        }
                        
                        // Done button
                        Button(action: {
                            // Save the target and trigger recalculation of progress bar
                            if let newTarget = Int(editableTarget), newTarget > 0 {
                                // Using withAnimation to smoothly update the UI
                                withAnimation(.easeInOut(duration: 0.3)) {
                                    dailyTarget = newTarget
                                    saveDailyTarget(newTarget)
                                    
                                    // Notify that target has changed
                                    NotificationCenter.default.post(
                                        name: Constants.Notifications.taskListChanged,
                                        object: nil
                                    )
                                }
                            }
                            isEditingTarget = false
                        }) {
                            Image(systemName: "checkmark")
                                .font(.system(size: 24))
                                .frame(width: 60, height: 60)
                                .background(Color.green.opacity(0.2))
                                .cornerRadius(30)
                        }
                    }
                }
                .padding()
                
                Spacer()
            }
            .presentationDetents([.medium])
            .presentationDragIndicator(.visible)
        }
    }
    
    // No longer needed - we use actual points directly
    // Kept for reference in case we need to revert
    private func _calculateEstimatedPoints(progress: Float, targetRatioFloat: Float, dailyTarget: Int) -> Int {
        if progress <= targetRatioFloat {
            // Before target: calculate as portion of target (scales linearly to target)
            return Int((progress / targetRatioFloat) * Float(dailyTarget))
        } else {
            // Beyond target: start with target and add overflow
            let overProgress = progress - targetRatioFloat
            let overPoints = Int(overProgress * 150.0)
            return dailyTarget + overPoints
        }
    }
    
    // Load the daily target from CoreData
    private func loadDailyTarget() {
        // Default to 100 if not set
        dailyTarget = 100
        
        // In a real implementation, you would load this from CoreData
        // For now, we'll use the default value
    }
    
    // Save the daily target to CoreData
    private func saveDailyTarget(_ target: Int) {
        // In a real implementation, you would save this to CoreData
        // For now, we just update the state
        dailyTarget = target
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

// No longer need custom AnimatingNumber - using visibility toggle approach instead