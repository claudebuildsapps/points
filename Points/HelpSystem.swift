import SwiftUI

// Help System singleton class
class HelpSystem: ObservableObject {
    static let shared = HelpSystem()
    
    @Published var isHelpModeActive = false
    @Published var highlightedElementID: String?
    @Published var elements: [String: (metadata: HelpMetadata, frame: CGRect)] = [:]
    @Published var panelState: HelpPanelState = .full
    
    // Track position for floating indicator
    @Published var floatingIndicatorPosition: CGPoint = CGPoint(x: UIScreen.main.bounds.width - 60, y: 100)
    
    init() {
        // Listen for notifications to toggle help mode
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(toggleHelpModeFromNotification),
            name: Constants.Notifications.toggleHelpMode,
            object: nil
        )
    }
    
    @objc func toggleHelpModeFromNotification() {
        DispatchQueue.main.async {
            self.toggleHelpMode()
        }
    }
    
    func toggleHelpMode() {
        // Debug for help mode toggle
        print("=== HELP MODE TOGGLE ===")
        print("Before toggle: isHelpModeActive = \(isHelpModeActive)")
        
        // Perform toggle with extra checks
        withAnimation(.easeInOut(duration: 0.3)) {
            isHelpModeActive.toggle()
        }
        
        print("After toggle: isHelpModeActive = \(isHelpModeActive)")
        
        if isHelpModeActive {
            // Reset to full panel when entering help mode
            panelState = .full
            print("Entering help mode - panel set to full")
            // Force refresh to ensure UI updates
            DispatchQueue.main.async {
                self.objectWillChange.send()
            }
        } else {
            // Clear highlight when exiting
            highlightedElementID = nil
            print("Exiting help mode - highlight cleared")
            // Force refresh to ensure UI updates
            DispatchQueue.main.async {
                self.objectWillChange.send()
            }
        }
    }
    
    func minimizePanel() {
        panelState = .minimized
    }
    
    func maximizePanel() {
        panelState = .full
    }
    
    func togglePanelState() {
        panelState = panelState == .full ? .minimized : .full
    }
    
    func registerElement(id: String, metadata: HelpMetadata, frame: CGRect) {
        // Debug element registration for the Create buttons
        if id.contains("create-") {
            print("Registering element: \(id), title: \(metadata.title)")
        }
        
        // Store element metadata and frame
        elements[id] = (metadata, frame)
    }
    
    func highlightElement(_ id: String) {
        print("=== HIGHLIGHT ELEMENT ===")
        print("Previous highlight: \(String(describing: highlightedElementID))")
        print("New highlight: \(id)")
        
        // Check if this element is registered
        if let metadata = elements[id]?.metadata {
            print("Element metadata found: \(metadata.title)")
        } else {
            print("⚠️ WARNING: No metadata found for element ID: \(id)")
        }
        
        // Update highlighted element ID
        highlightedElementID = id
        
        // Show full panel when element is highlighted
        panelState = .full
        
        // Force UI update
        DispatchQueue.main.async {
            self.objectWillChange.send()
        }
    }
    
    func isElementHighlighted(_ id: String) -> Bool {
        return highlightedElementID == id
    }
    
    var currentMetadata: HelpMetadata? {
        guard let id = highlightedElementID else { 
            // No element is highlighted
            return nil 
        }
        
        // Lookup the highlighted element's metadata
        let metadata = elements[id]?.metadata
        
        // Debug output for help panel
        if metadata == nil {
            print("⚠️ WARNING: No metadata found for highlightedElementID: \(id)")
            print("Available element IDs: \(elements.keys.joined(separator: ", "))")
        }
        
        return metadata
    }
    
    func updateFloatingIndicatorPosition(_ position: CGPoint) {
        floatingIndicatorPosition = position
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self)
    }
}

// Struct to hold help information for UI elements
struct HelpMetadata {
    let id: String
    let title: String
    let description: String
    let usageHints: [String]
    let importance: HelpImportance
    
    init(id: String, title: String, description: String, usageHints: [String] = [], importance: HelpImportance = .informational) {
        self.id = id
        self.title = title
        self.description = description
        self.usageHints = usageHints
        self.importance = importance
    }
}

enum HelpImportance: Int {
    case critical, important, informational
}

// Different states for the help panel display
enum HelpPanelState {
    case full        // Full panel with all information
    case minimized   // Minimized state showing just indicator
}

// View modifier for help overlay - optimized to work with the +Routine, +Task, +Critical buttons
struct HelpOverlayModifier: ViewModifier {
    let metadata: HelpMetadata
    @ObservedObject var helpSystem = HelpSystem.shared
    
    func body(content: Content) -> some View {
        // We need special handling for the help button
        if metadata.id == "help-button" {
            // Allow the help button to function normally even in help mode
            content
                .background(
                    GeometryReader { geo in
                        Color.clear
                            .onAppear {
                                helpSystem.registerElement(
                                    id: metadata.id,
                                    metadata: metadata,
                                    frame: geo.frame(in: .global)
                                )
                            }
                    }
                )
        } else {
            // For all other elements, modify their behavior in help mode
            ZStack {
                // Original content (buttons, etc.)
                content
                    // Register element with help system
                    .background(
                        GeometryReader { geo in
                            Color.clear
                                .onAppear {
                                    helpSystem.registerElement(
                                        id: metadata.id,
                                        metadata: metadata,
                                        frame: geo.frame(in: .global)
                                    )
                                }
                        }
                    )
                    // Disable normal actions when in help mode
                    .disabled(helpSystem.isHelpModeActive)
                
                // Help mode overlay - only render when help mode is active
                if helpSystem.isHelpModeActive {
                    // Invisible button with high priority tap area
                    Button(action: {
                        // Enhanced debugging
                        print("👆 TAPPED ELEMENT: \(metadata.id) - \(metadata.title)")
                        
                        // Dispatch to main queue to ensure proper UI update
                        DispatchQueue.main.async {
                            // Show element info
                            helpSystem.highlightElement(metadata.id)
                        }
                    }) {
                        // Use the full area without padding for better touch target
                        Rectangle()
                            .fill(Color.white.opacity(0.001)) // Nearly invisible
                            .contentShape(Rectangle())
                    }
                    .buttonStyle(PlainButtonStyle())
                    .zIndex(100) // Ensure this is on top for taps
                    
                    // Visual highlight when this element is selected
                    if helpSystem.isElementHighlighted(metadata.id) {
                        Group {
                            // Pill highlight for indicators
                            if metadata.id == "points-indicator" || metadata.id == "target-indicator" {
                                Capsule()
                                    .stroke(Color.blue, lineWidth: 3)
                                    .zIndex(99)
                            }
                            // Skip highlight for UI elements that handle their own highlighting
                            else if metadata.id == "quick-create-task-button" || 
                                   metadata.id == "create-routine-button" || 
                                   metadata.id == "help-button" || 
                                   metadata.id == "home-button" || 
                                   metadata.id == "delete-button" || 
                                   metadata.id == "theme-toggle-button" ||
                                   metadata.id == "progress-bar-base" ||
                                   metadata.id == "progress-bar-to-target" ||
                                   metadata.id == "progress-bar-beyond-target" ||
                                   metadata.id == "target-indicator" ||
                                   metadata.id == "points-indicator" {
                                // No highlight here - handled directly in the component
                                Color.clear.frame(width: 0, height: 0)
                            }
                            // Default highlight for rectangular elements
                            else {
                                RoundedRectangle(cornerRadius: 4)
                                    .stroke(Color.blue, lineWidth: 3)
                                    .zIndex(99) // Below the tap area but above content
                            }
                        }
                        .animation(.easeInOut(duration: 0.2), value: helpSystem.highlightedElementID)
                    }
                }
            }
        }
    }
}

// Info panel to display help information
struct HelpInfoPanel: View {
    let metadata: HelpMetadata
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(metadata.title)
                .font(.headline)
                .padding(.bottom, 4)
            
            Text(metadata.description)
                .font(.body)
                .fixedSize(horizontal: false, vertical: true)
            
            if !metadata.usageHints.isEmpty {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Tips:").font(.subheadline).bold()
                    
                    ForEach(metadata.usageHints, id: \.self) { hint in
                        HStack(alignment: .top) {
                            Text("•")
                            Text(hint)
                                .fixedSize(horizontal: false, vertical: true)
                        }
                        .font(.caption)
                    }
                }
                .padding(.top, 4)
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 8)
                .fill(Color(.systemBackground))
                .shadow(color: Color.black.opacity(0.2), radius: 8, x: 0, y: 4)
        )
        .padding()
    }
}

// Extension for applying help metadata
extension View {
    func helpMetadata(_ metadata: HelpMetadata) -> some View {
        modifier(HelpOverlayModifier(metadata: metadata))
    }
}

// Compact help panel that fits at the top of the main view
struct HelpModeOverlay: View {
    @ObservedObject var helpSystem = HelpSystem.shared
    @State private var showingTutorial = false
    
    var body: some View {
        // Help panel with clearer layout and controls
        ZStack {
            // Main content
            VStack(spacing: 0) {
                // Top section with content and controls
                HStack(alignment: .top) {
                    // Help content area
                    if let metadata = helpSystem.currentMetadata {
                        // Element details when something is selected
                        VStack(alignment: .leading, spacing: 4) {
                            Text(metadata.title)
                                .font(.headline)
                                .foregroundColor(.primary)
                            
                            Text(metadata.description)
                                .font(.subheadline)
                                .foregroundColor(.primary)
                                .lineLimit(showingTutorial ? nil : 2)
                            
                            if !metadata.usageHints.isEmpty {
                                Text("Tip: \(metadata.usageHints[0])")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                                    .padding(.top, 2)
                            }
                        }
                    } else {
                        // Default help message - higher up with no padding
                        HStack(spacing: 8) {
                            Text("👆")
                                .font(.title3)
                            
                            VStack(alignment: .leading, spacing: 4) {
                                Text("Tap any UI element to see what it does")
                                    .font(.headline)
                                    .foregroundColor(.primary)
                                
                                Text("Try tapping the +Routine, +Task, or +Critical buttons above!")
                                    .font(.subheadline)
                                    .foregroundColor(.secondary)
                            }
                        }
                    }
                    
                    Spacer()
                    
                    // Controls - always visible at top right
                    HStack(spacing: 16) {
                        // Info button - clearly visible
                        Button(action: {
                            withAnimation(.spring()) {
                                showingTutorial.toggle()
                            }
                        }) {
                            Image(systemName: showingTutorial ? "info.circle.fill" : "info.circle")
                                .font(.system(size: 22))
                                .foregroundColor(.blue)
                        }
                        
                        // X button - very visible in top right
                        Button(action: {
                            helpSystem.toggleHelpMode()
                        }) {
                            ZStack {
                                Circle()
                                    .fill(Color.white)
                                    .frame(width: 24, height: 24)
                                    .shadow(color: Color.black.opacity(0.1), radius: 1, x: 0, y: 1)
                                
                                Image(systemName: "xmark")
                                    .font(.system(size: 12, weight: .bold))
                                    .foregroundColor(.gray)
                            }
                        }
                    }
                }
                .padding(.horizontal, 12)
                .padding(.top, 8)
                .padding(.bottom, 4)
                
                // Expanded content when info button is tapped
                if showingTutorial {
                    Divider()
                        .padding(.horizontal, 12)
                    
                    if let metadata = helpSystem.currentMetadata, metadata.usageHints.count > 1 {
                        // Show additional tips if available
                        VStack(alignment: .leading, spacing: 6) {
                            Text("More tips for \(metadata.title):")
                                .font(.footnote)
                                .bold()
                                .padding(.horizontal, 12)
                                .padding(.top, 4)
                            
                            ForEach(1..<metadata.usageHints.count, id: \.self) { index in
                                HStack(alignment: .top, spacing: 6) {
                                    Text("•")
                                        .font(.caption)
                                    Text(metadata.usageHints[index])
                                        .font(.caption)
                                        .fixedSize(horizontal: false, vertical: true)
                                }
                                .foregroundColor(.secondary)
                                .padding(.horizontal, 18)
                            }
                        }
                        .padding(.bottom, 8)
                    } else {
                        // Show general help guide
                        VStack(alignment: .leading, spacing: 6) {
                            Text("Quick Help Guide")
                                .font(.footnote)
                                .bold()
                                .padding(.horizontal, 12)
                                .padding(.top, 4)
                            
                            VStack(alignment: .leading, spacing: 4) {
                                TutorialItem(number: 1, text: "+Routine - Create recurring tasks like daily habits")
                                TutorialItem(number: 2, text: "+Task - Create one-time to-do items")
                                TutorialItem(number: 3, text: "+Critical - Create high-priority tasks")
                            }
                            .padding(.horizontal, 12)
                            .padding(.bottom, 6)
                        }
                    }
                }
            }
        }
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(radius: 2)
    }
}

// A draggable floating indicator for help mode
struct FloatingHelpIndicator: View {
    @Binding var position: CGPoint
    var onTap: () -> Void
    var onExit: () -> Void
    @State private var dragOffset: CGSize = .zero
    @State private var isExpanded = false
    
    var body: some View {
        ZStack {
            // Main circle with book icon
            Circle()
                .fill(Color.blue)
                .frame(width: 44, height: 44)
                .shadow(color: Color.black.opacity(0.3), radius: 3, x: 0, y: 2)
                .overlay(
                    Image(systemName: "book.fill")
                        .font(.system(size: 20))
                        .foregroundColor(.white)
                )
                .position(position)
                .gesture(
                    DragGesture()
                        .onChanged { value in
                            let newPosition = CGPoint(
                                x: position.x + value.translation.width - dragOffset.width,
                                y: position.y + value.translation.height - dragOffset.height
                            )
                            position = newPosition
                            dragOffset = value.translation
                        }
                        .onEnded { _ in
                            dragOffset = .zero
                        }
                )
                .onTapGesture {
                    isExpanded.toggle()
                }
            
            // Exit button appears when expanded
            if isExpanded {
                // Mini menu that appears when tapped
                VStack(spacing: 10) {
                    // Help info button
                    Button(action: {
                        isExpanded = false
                        onTap()
                    }) {
                        Circle()
                            .fill(Color.green)
                            .frame(width: 36, height: 36)
                            .overlay(
                                Image(systemName: "info.circle")
                                    .font(.system(size: 18))
                                    .foregroundColor(.white)
                            )
                    }
                    
                    // Exit help mode button
                    Button(action: {
                        isExpanded = false
                        onExit()
                    }) {
                        Circle()
                            .fill(Color.red)
                            .frame(width: 36, height: 36)
                            .overlay(
                                Image(systemName: "xmark")
                                    .font(.system(size: 18))
                                    .foregroundColor(.white)
                            )
                    }
                }
                .offset(x: 0, y: -70)
                .position(position)
                .transition(.scale.combined(with: .opacity))
            }
        }
        .animation(.spring(), value: isExpanded)
    }
}

// Tutorial list item with numbered style - compact design for help panel
struct TutorialItem: View {
    let number: Int
    let text: String
    
    var body: some View {
        HStack(alignment: .top, spacing: 6) {
            Text("\(number).")
                .font(.caption)
                .bold()
                .frame(width: 14, alignment: .trailing)
            
            Text(text)
                .font(.caption)
                .foregroundColor(.secondary)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(.vertical, 2)
    }
}
