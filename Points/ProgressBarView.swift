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
    
    // Help system reference
    @ObservedObject private var helpSystem = HelpSystem.shared
    
    init(progress: Binding<Float> = .constant(0), actualPoints: Int = 0) {
        self._progress = progress
        self.actualPoints = actualPoints
    }
    
    // Split body into smaller pieces to help the compiler
    var body: some View {
        // Compact progress bar with no extra spacing
        progressBarContent
    }
    
    // Main container
    private var progressBarContent: some View {
        VStack(spacing: 0) {
            // Full-width rectangular progress bar with target indicator
            GeometryReader { geometry in
                progressBarLayout(in: geometry)
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
        .sheet(isPresented: $isEditingTarget) { targetEditingSheet }
    }
    
    // Helper to calculate all values needed for progress bar rendering
    private func calculateProgressValues(geometry: GeometryProxy) -> (
        targetPosition: CGFloat,
        displayPoints: Int,
        indicatorPosition: CGFloat,
        indicatorColor: Color,
        actualProgressWidth: CGFloat,
        normalizedProgress: Float
    ) {
        // Calculate positions and values
        let targetRatio = CGFloat(dailyTarget) / 150.0
        let targetPosition = min(geometry.size.width * 0.75, geometry.size.width * targetRatio)
        
        // Use the animated points value for smooth transitions
        let displayPoints = Int(animatedPointsValue.rounded())
        
        // Calculate indicator position based on animated points
        let targetRatioFloat = Float(dailyTarget) / 150.0
        let pointsProgressRatio = min(Float(animatedPointsValue) / Float(dailyTarget), 1.0)
        let normalizedProgress = pointsProgressRatio * targetRatioFloat
        
        // Calculate position as a direct mapping of points to width
        let indicatorPosition = min(CGFloat(normalizedProgress) * geometry.size.width, geometry.size.width - 24)
        let indicatorColor: Color = displayPoints >= dailyTarget ? theme.dataTab : theme.templateTab
        
        // Calculate progress width based on points
        let actualProgressWidth = CGFloat(normalizedProgress) * geometry.size.width
        
        return (
            targetPosition: targetPosition,
            displayPoints: displayPoints,
            indicatorPosition: indicatorPosition,
            indicatorColor: indicatorColor,
            actualProgressWidth: actualProgressWidth,
            normalizedProgress: normalizedProgress
        )
    }
    
    // Main progress bar layout
    private func progressBarLayout(in geometry: GeometryProxy) -> some View {
        // Calculate all the values we need
        let values = calculateProgressValues(geometry: geometry)
        let targetPosition = values.targetPosition
        let displayPoints = values.displayPoints
        let indicatorPosition = values.indicatorPosition
        let indicatorColor = values.indicatorColor
        let actualProgressWidth = values.actualProgressWidth
        let normalizedProgress = values.normalizedProgress
        
        // Split the complex view into smaller components
        return ZStack(alignment: .leading) {
            // Background component
            progressBarBackground(geometry: geometry)
            
            // Gold progress section component
            progressBarGoldSection(geometry: geometry, actualProgressWidth: actualProgressWidth, targetPosition: targetPosition)
            
            // Blue section (beyond target) if needed
            if animatedPointsValue > Double(dailyTarget) {
                progressBarBeyondTarget(geometry: geometry, targetPosition: targetPosition)
            }
            
            // Target marker/indicator component
            targetMarker(geometry: geometry, targetPosition: targetPosition)
            
            // Current points indicator component
            pointsIndicator(geometry: geometry, indicatorPosition: indicatorPosition, displayPoints: displayPoints, indicatorColor: indicatorColor)
        }
    }
    
    // Background component
    private func progressBarBackground(geometry: GeometryProxy) -> some View {
        // Get the values we need for calculating the remaining space
        let values = calculateProgressValues(geometry: geometry)
        let targetPosition = values.targetPosition
        let actualProgressWidth = values.actualProgressWidth
        
        return ZStack {
            ZStack {
                // Full-width background
                Rectangle()
                    .fill(theme.progressBackground)
                    .cornerRadius(2)
                    .frame(width: geometry.size.width, height: geometry.size.height)
                    
                // Custom help highlight - only show in help mode when highlighted
                if helpSystem.isHelpModeActive && helpSystem.isElementHighlighted("progress-bar-base") {
                    Rectangle()
                        .stroke(Color.blue, lineWidth: 2)
                        .cornerRadius(2)
                        .frame(width: geometry.size.width, height: geometry.size.height)
                }
            }
            .contentShape(Rectangle()) // Ensure the entire area is tappable
            // Replacement help button when in help mode
            .overlay(
                Group {
                    if helpSystem.isHelpModeActive {
                        // Invisible button to trigger highlighting
                        Button(action: {
                            helpSystem.highlightElement("progress-bar-base")
                        }) {
                            Rectangle()
                                .fill(Color.clear)
                                .frame(width: geometry.size.width, height: geometry.size.height)
                                .contentShape(Rectangle())
                        }
                        .buttonStyle(PlainButtonStyle())
                    }
                }
            )
            // Register with help system for metadata only, not for highlighting
            .onAppear {
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                    HelpSystem.shared.registerElement(
                        id: "progress-bar-base",
                        metadata: HelpMetadata(
                            id: "progress-bar-base",
                            title: "Progress Bar Background",
                            description: "The gray background represents the full scale of possible points.",
                            usageHints: [
                                "The progress bar shows 0 to about 300 points",
                                "Your daily target appears as a green vertical line",
                                "Gold section fills as you earn points"
                            ],
                            importance: .informational
                        ),
                        frame: CGRect(x: 0, y: 0, width: geometry.size.width, height: geometry.size.height)
                    )
                }
            }
            
            // Remaining progress space to target - this is the gray area between the gold and the target
            if actualProgressWidth < targetPosition {
                let remainingWidth = max(0, targetPosition - actualProgressWidth)
                let remainingX = actualProgressWidth + (remainingWidth / 2)
                
                ZStack {
                    // No visible element, just used for hit testing
                    Rectangle()
                        .fill(Color.clear)
                        .frame(width: remainingWidth, height: geometry.size.height)
                        
                    // Custom help highlight - only show in help mode when highlighted
                    if helpSystem.isHelpModeActive && helpSystem.isElementHighlighted("progress-remaining") {
                        Rectangle()
                            .stroke(Color.blue, lineWidth: 2)
                            .cornerRadius(2)
                            .frame(width: remainingWidth, height: geometry.size.height)
                    }
                }
                .position(x: remainingX, y: geometry.size.height / 2)
                .contentShape(Rectangle())
                // Replacement help button when in help mode
                .overlay(
                    Group {
                        if helpSystem.isHelpModeActive {
                            // Invisible button to trigger highlighting
                            Button(action: {
                                helpSystem.highlightElement("progress-remaining")
                            }) {
                                Rectangle()
                                    .fill(Color.clear)
                                    .frame(width: remainingWidth, height: geometry.size.height)
                                    .contentShape(Rectangle())
                            }
                            .buttonStyle(PlainButtonStyle())
                            .position(x: remainingWidth/2, y: geometry.size.height/2)
                        }
                    }
                )
                // Register with help system for metadata only, not for highlighting
                .onAppear {
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                        HelpSystem.shared.registerElement(
                            id: "progress-remaining",
                            metadata: HelpMetadata(
                                id: "progress-remaining",
                                title: "Remaining Progress",
                                description: "This area shows how much more you need to reach your target.",
                                usageHints: [
                                    "Gray area represents points still needed",
                                    "Will be filled with gold as you earn more points",
                                    "Complete tasks to fill this area and reach your target"
                                ],
                                importance: .important
                            ),
                            frame: CGRect(x: actualProgressWidth, y: 0, width: remainingWidth, height: geometry.size.height)
                        )
                    }
                }
            }
        }
    }
    
    // Gold progress section component
    private func progressBarGoldSection(geometry: GeometryProxy, actualProgressWidth: CGFloat, targetPosition: CGFloat) -> some View {
        ZStack(alignment: .leading) {
            // Main progress fill
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
                
            // Custom help highlight - only show in help mode when highlighted
            if helpSystem.isHelpModeActive && helpSystem.isElementHighlighted("progress-gold-section") {
                Rectangle()
                    .stroke(Color.blue, lineWidth: 2)
                    .cornerRadius(2)
                    .frame(width: min(max(0, actualProgressWidth), targetPosition), height: geometry.size.height)
            }
        }
        .contentShape(Rectangle())
        // Replacement help button when in help mode
        .overlay(
            Group {
                if helpSystem.isHelpModeActive {
                    // Invisible button to trigger highlighting
                    Button(action: {
                        helpSystem.highlightElement("progress-gold-section")
                    }) {
                        Rectangle()
                            .fill(Color.clear)
                            .frame(width: min(max(4, actualProgressWidth), targetPosition), height: geometry.size.height)
                            .contentShape(Rectangle())
                    }
                    .buttonStyle(PlainButtonStyle())
                    .disabled(actualProgressWidth < 4) // Disable when progress bar is too small
                }
            }
        )
        // Register with help system for metadata only, not for highlighting
        .onAppear {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                HelpSystem.shared.registerElement(
                    id: "progress-gold-section",
                    metadata: HelpMetadata(
                        id: "progress-gold-section",
                        title: "Gold Progress Bar",
                        description: "This gold section shows your current progress toward your daily target.",
                        usageHints: [
                            "Fills from left to right as you earn points",
                            "Shows your progress percentage toward target",
                            "Gold color represents points earned so far",
                            "Turns completely gold when you reach your target"
                        ],
                        importance: .important
                    ),
                    frame: CGRect(x: 0, y: 0, width: min(max(0, actualProgressWidth), targetPosition), height: geometry.size.height)
                )
            }
        }
    }
    
    // Beyond target (blue) section component
    private func progressBarBeyondTarget(geometry: GeometryProxy, targetPosition: CGFloat) -> some View {
        let beyondTargetRatio = min(Float(animatedPointsValue - Double(dailyTarget)) / 150.0, 1.0)
        let beyondTargetWidth = CGFloat(beyondTargetRatio) * geometry.size.width
        
        return ZStack {
            // Main blue progress rectangle
            Rectangle()
                .fill(theme.dataTab)
                .cornerRadius(2)
                .frame(width: beyondTargetWidth, height: geometry.size.height)
            
            // Custom help highlight - only show in help mode when highlighted
            if helpSystem.isHelpModeActive && helpSystem.isElementHighlighted("progress-beyond-section") {
                Rectangle()
                    .stroke(Color.blue, lineWidth: 2)
                    .cornerRadius(2)
                    .frame(width: beyondTargetWidth, height: geometry.size.height)
            }
        }
        .position(x: (beyondTargetWidth / 2) + targetPosition, y: geometry.size.height / 2)
        .contentShape(Rectangle())
        // Replacement help button when in help mode
        .overlay(
            Group {
                if helpSystem.isHelpModeActive {
                    // Invisible button to trigger highlighting
                    Button(action: {
                        helpSystem.highlightElement("progress-beyond-section")
                    }) {
                        Rectangle()
                            .fill(Color.clear)
                            .frame(width: beyondTargetWidth, height: geometry.size.height)
                            .contentShape(Rectangle())
                    }
                    .buttonStyle(PlainButtonStyle())
                    .position(x: beyondTargetWidth/2, y: geometry.size.height/2)
                }
            }
        )
        // Register with help system for metadata only, not for highlighting
        .onAppear {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                HelpSystem.shared.registerElement(
                    id: "progress-beyond-section",
                    metadata: HelpMetadata(
                        id: "progress-beyond-section",
                        title: "Points Beyond Target",
                        description: "This blue section shows points earned beyond your daily target.",
                        usageHints: [
                            "Celebrates overachievement!",
                            "Shows how far you've exceeded your goal",
                            "Different color indicates bonus achievement",
                            "Blue section appears only after reaching your target"
                        ],
                        importance: .important
                    ),
                    frame: CGRect(x: targetPosition, y: 0, width: beyondTargetWidth, height: geometry.size.height)
                )
            }
        }
    }
    
    // Target marker/indicator component
    private func targetMarker(geometry: GeometryProxy, targetPosition: CGFloat) -> some View {
        ZStack {
            // Target decoration
            Rectangle()
                .fill(darkGreenColor)
                .frame(width: 3, height: geometry.size.height + 10)
            
            ZStack {
                // Main content - unaffected by help mode
                Button(action: {
                    // Only trigger action if not in help mode
                    if !helpSystem.isHelpModeActive {
                        // Initialize editable target with current value
                        editableTarget = "\(dailyTarget)"
                        isEditingTarget = true
                    }
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
                .buttonStyle(PlainButtonStyle())
                
                // Help mode overlay
                if helpSystem.isHelpModeActive {
                    // Invisible help button
                    Button(action: {
                        helpSystem.highlightElement("target-points-display")
                    }) {
                        Capsule()
                            .fill(Color.clear)
                            .frame(width: 52, height: 28) // Slightly larger for easier tap
                            .contentShape(Capsule())
                    }
                    .buttonStyle(PlainButtonStyle())
                    
                    // Show highlight when selected
                    if helpSystem.isElementHighlighted("target-points-display") {
                        Capsule()
                            .stroke(Color.blue, lineWidth: 2)
                            .frame(width: 50, height: 26) // 2px larger than the 48×24 pill
                    }
                }
                
                // Register with help system for metadata for the target bubble
                GeometryReader { geo in
                    Color.clear
                        .onAppear {
                            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                                helpSystem.registerElement(
                                    id: "target-points-display",
                                    metadata: HelpMetadata(
                                        id: "target-points-display",
                                        title: "Target Display",
                                        description: "Shows your daily points goal in a green pill.",
                                        usageHints: [
                                            "Tap to change your daily target value",
                                            "The green marker shows where this goal sits on the bar",
                                            "Default is 100 points but can be customized",
                                            "Reaching this value completes your day"
                                        ],
                                        importance: .important
                                    ),
                                    frame: geo.frame(in: .global)
                                )
                            }
                        }
                }
            }
            .offset(y: -20) // Reduced offset by 4pt (16.7% reduction)
        }
        .position(x: targetPosition, y: geometry.size.height / 2)
    }
    
    // Current points indicator component
    private func pointsIndicator(geometry: GeometryProxy, indicatorPosition: CGFloat, displayPoints: Int, indicatorColor: Color) -> some View {
        ZStack {
            // Points decoration line
            Rectangle()
                .fill(indicatorColor)
                .frame(width: 3, height: geometry.size.height + 10)
            
            ZStack {
                // Current points bubble - main content
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
                
                // Help mode overlay
                if helpSystem.isHelpModeActive {
                    // Invisible help button
                    Button(action: {
                        helpSystem.highlightElement("total-points-display")
                    }) {
                        let width: CGFloat = displayPoints > 999 ? 64 : 52 // Slightly larger for easier tap
                        Capsule()
                            .fill(Color.clear)
                            .frame(width: width, height: 28)
                            .contentShape(Capsule())
                    }
                    .buttonStyle(PlainButtonStyle())
                    
                    // Show highlight when selected
                    if helpSystem.isElementHighlighted("total-points-display") {
                        let width: CGFloat = displayPoints > 999 ? 62 : 50 // 2px larger than the original
                        Capsule()
                            .stroke(Color.blue, lineWidth: 2)
                            .frame(width: width, height: 26)
                    }
                }
                
                // Register with help system for metadata for the points bubble
                GeometryReader { geo in
                    Color.clear
                        .onAppear {
                            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                                let width: CGFloat = displayPoints > 999 ? 60 : 48
                                helpSystem.registerElement(
                                    id: "total-points-display",
                                    metadata: HelpMetadata(
                                        id: "total-points-display",
                                        title: "Total Points",
                                        description: "Shows your current total points earned today.",
                                        usageHints: [
                                            "Updates in real-time as you complete tasks",
                                            "Gold color before reaching target",
                                            "Blue color when exceeding target",
                                            "Moves along the progress bar as you earn points"
                                        ],
                                        importance: .important
                                    ),
                                    frame: geo.frame(in: .global)
                                )
                            }
                        }
                }
            }
            .offset(y: -20) // Reduced offset by 4pt (16.7% reduction)
        }
        .position(x: displayPoints > 0 ? indicatorPosition : 0, y: geometry.size.height / 2) // Place at far left (0) when points are 0
    }
    
    // Target edit sheet content
    private var targetEditingSheet: some View {
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