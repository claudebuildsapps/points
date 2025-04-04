import SwiftUI
import CoreData

struct ProgressBarView: View {
    @Binding var progress: Float
    @Environment(\.theme) var theme
    @Environment(\.managedObjectContext) private var context
    @State private var dailyTarget: Int = 100 // Default target
    @State private var isEditingTarget: Bool = false // Track if target is being edited
    
    // Current date entity for persisting target
    var dateEntity: CoreDataDate? = nil
    
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
    
    init(progress: Binding<Float> = .constant(0), actualPoints: Int = 0, dateEntity: CoreDataDate? = nil) {
        self._progress = progress
        self.actualPoints = actualPoints
        self.dateEntity = dateEntity
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
            .padding(.top, 15) // Add top padding to push progress bar down and make room for bubbles
            .padding(.bottom, 10) // Add bottom padding for spacing below the progress bar
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
            NumericEditingView(
                title: "Target",
                initialValue: "\(dailyTarget)",
                onSave: { value in
                    if let newTarget = Int(value), newTarget > 0 {
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
                }
            )
            .presentationDetents([.height(320)])
            .presentationDragIndicator(.hidden)
        }
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
            
            // Gold progress section component - use progress or exactly 3px for minimum progress
            progressBarGoldSection(geometry: geometry, actualProgressWidth: displayPoints == 0 ? 3 : max(actualProgressWidth, 3), targetPosition: targetPosition)
            
            // Blue section (beyond target) if needed
            if animatedPointsValue > Double(dailyTarget) {
                progressBarBeyondTarget(geometry: geometry, targetPosition: targetPosition)
            } else {
                // Area beyond target that can be tapped for help when below target
                beyondTargetHelpArea(geometry: geometry, targetPosition: targetPosition)
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
                
                // Create a precise tap target for the remaining section
                Rectangle()
                    .fill(helpSystem.isHelpModeActive ? Color.blue.opacity(0.02) : Color.clear) // Very subtle visual in help mode
                    .frame(width: remainingWidth, height: geometry.size.height)
                    .position(x: remainingX, y: geometry.size.height / 2)
                    // Add direct tap detection
                    .contentShape(Rectangle())
                    .onTapGesture {
                        if helpSystem.isHelpModeActive {
                            print("📊 Tapped remaining progress area")
                            helpSystem.highlightElement("progress-remaining")
                        }
                    }
                    // Ensure this has a high z-index to capture taps
                    .zIndex(40)
                    // Add highlight outline directly
                    .overlay(
                        Group {
                            if helpSystem.isHelpModeActive && helpSystem.isElementHighlighted("progress-remaining") {
                                // Highlight with exact dimensions
                                Rectangle()
                                    .stroke(Color.blue, lineWidth: 2)
                                    .frame(width: remainingWidth, height: geometry.size.height)
                                    .position(x: remainingWidth/2, y: geometry.size.height/2)
                            }
                        }
                    )
                    // Register with help system
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
        let width = min(max(3, actualProgressWidth), targetPosition) // Changed from 5px to 3px to match target line width
        
        return ZStack(alignment: .leading) {
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
                .cornerRadius(actualProgressWidth <= 3 ? 0 : 2) // Only round corners when progress is more than minimum
                .frame(width: width, height: geometry.size.height)
                .alignmentGuide(.leading) { _ in 0 } // Force alignment to left edge
                
            // Custom help highlight - only show in help mode when highlighted
            if helpSystem.isHelpModeActive && helpSystem.isElementHighlighted("progress-gold-section") {
                Rectangle()
                    .stroke(Color.blue, lineWidth: 2)
                    .cornerRadius(2)
                    .frame(width: width, height: geometry.size.height)
            }
        }
        .contentShape(Rectangle())
        // If in help mode, capture taps directly (more reliable than overlay button)
        .onTapGesture {
            if helpSystem.isHelpModeActive {
                print("📊 Tapped gold progress section")
                helpSystem.highlightElement("progress-gold-section")
            }
        }
        // Give this a higher zIndex to ensure it captures taps
        .zIndex(30)
        // Register with help system for metadata
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
                    frame: CGRect(x: 0, y: 0, width: width, height: geometry.size.height)
                )
            }
        }
    }
    
    // Help area for space beyond target (when not filled)
    private func beyondTargetHelpArea(geometry: GeometryProxy, targetPosition: CGFloat) -> some View {
        // Calculate the width of the area beyond target
        let beyondWidth = geometry.size.width - targetPosition
        
        // Create the content regardless of width, but conditionally adjust visibility
        return ZStack {
            // Invisible rectangle to capture taps - but with a tiny bit of opacity in help mode for debugging
            Rectangle()
                .fill(helpSystem.isHelpModeActive ? Color.blue.opacity(0.05) : Color.clear)
                .frame(width: max(beyondWidth, 2), height: geometry.size.height) // Ensure minimum size
                .contentShape(Rectangle())
            
            // Custom help highlight - only show in help mode when highlighted
            if helpSystem.isHelpModeActive && helpSystem.isElementHighlighted("progress-beyond-section") {
                Rectangle()
                    .stroke(Color.blue, lineWidth: 2)
                    .cornerRadius(2)
                    .frame(width: max(beyondWidth, 2), height: geometry.size.height)
            }
        }
        .position(x: (max(beyondWidth, 2) / 2) + targetPosition, y: geometry.size.height / 2)
        // Critical - must use contentShape here to ensure taps register
        .contentShape(Rectangle())
        // If in help mode, capture taps on this area, but only if we have enough width
        .onTapGesture {
            if helpSystem.isHelpModeActive && beyondWidth > 2 {
                print("📏 Tapped beyond target area")
                helpSystem.highlightElement("progress-beyond-section")
            }
        }
        // Only register in help system and make clickable if we have enough width
        .opacity(beyondWidth > 2 ? 1 : 0)
        .disabled(beyondWidth <= 2)
        // Give this a high zIndex to ensure it captures taps
        .zIndex(20)
        // Register with help system for metadata
        .onAppear {
            if beyondWidth > 2 {
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                    HelpSystem.shared.registerElement(
                        id: "progress-beyond-section",
                        metadata: HelpMetadata(
                            id: "progress-beyond-section",
                            title: "Points Beyond Target",
                            description: "This area represents potential points beyond your daily target.",
                            usageHints: [
                                "Will turn blue when you exceed your target",
                                "Represents extra achievement beyond your goal",
                                "Completing more tasks fills this area",
                                "Encourages exceeding your daily goals"
                            ],
                            importance: .important
                        ),
                        frame: CGRect(x: targetPosition, y: 0, width: beyondWidth, height: geometry.size.height)
                    )
                }
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
                .frame(width: 3, height: geometry.size.height) // Adjusted to exactly touch the bottom of the progress bar
            
            ZStack {
                // Main content - unaffected by help mode
                Button(action: {
                    // Only trigger action if not in help mode
                    if !helpSystem.isHelpModeActive {
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
            .offset(y: -16) // Adjusted to touch the top of the progress bar
        }
        .position(x: targetPosition, y: geometry.size.height / 2)
    }
    
    // Current points indicator component
    private func pointsIndicator(geometry: GeometryProxy, indicatorPosition: CGFloat, displayPoints: Int, indicatorColor: Color) -> some View {
        ZStack {
            // Points decoration line
            Rectangle()
                .fill(indicatorColor)
                .frame(width: 3, height: geometry.size.height) // Adjusted to exactly touch the bottom of the progress bar
            
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
                        // Only for zero points, align the text to the right with padding
                        .frame(width: displayPoints > 0 ? nil : 38, alignment: displayPoints > 0 ? .center : .trailing)
                        .padding(.trailing, displayPoints > 0 ? 0 : 5)
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
            .offset(y: -16) // Adjusted to touch the top of the progress bar
        }
        .position(x: displayPoints > 0 ? indicatorPosition : 0, y: geometry.size.height / 2) // Place entire container at far left (0) when points are 0
    }
    
    // We now use NumericEditingView instead of the custom targetEditingSheet implementation
    
    // Load the daily target from CoreData
    private func loadDailyTarget() {
        // Default to 100 if no date entity or target not set
        if let dateEntity = dateEntity {
            // Load the target from the date entity
            dailyTarget = Int(dateEntity.target)
        } else {
            // Default to 100 if no date entity available
            dailyTarget = 100
        }
    }
    
    // Save the daily target to CoreData
    private func saveDailyTarget(_ target: Int) {
        // Update local state
        dailyTarget = target
        
        // Update CoreData if date entity exists
        if let dateEntity = dateEntity {
            // Update the target in Core Data
            dateEntity.target = Int16(target)
            
            // Save the context
            do {
                try context.save()
                print("Target saved to CoreData: \(target)")
            } catch {
                print("Failed to save target to CoreData: \(error)")
            }
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