import SwiftUI

/// Extensions to simplify help system registration and usage
extension View {
    /// Registers a view with the help system and provides overlay highlighting when active
    /// - Parameters:
    ///   - id: Unique identifier for the help element
    ///   - title: The title of the help element
    ///   - description: Detailed description of the element's purpose
    ///   - hints: Array of usage hints to display
    ///   - importance: The importance level of this element in the help system
    func registerForHelp(
        id: String,
        title: String,
        description: String,
        hints: [String] = [],
        importance: HelpImportance = .informational
    ) -> some View {
        self.overlay(
            GeometryReader { geo in
                Color.clear
                    .onAppear {
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                            HelpSystem.shared.registerElement(
                                id: id,
                                metadata: HelpMetadata(
                                    id: id,
                                    title: title,
                                    description: description,
                                    usageHints: hints,
                                    importance: importance
                                ),
                                frame: geo.frame(in: .global)
                            )
                        }
                    }
            }
        )
    }
    
    /// Simplified variant that uses the HelpMetadata directly
    /// - Parameter metadata: Complete HelpMetadata object
    func registerForHelp(metadata: HelpMetadata) -> some View {
        self.overlay(
            GeometryReader { geo in
                Color.clear
                    .onAppear {
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                            HelpSystem.shared.registerElement(
                                id: metadata.id,
                                metadata: metadata,
                                frame: geo.frame(in: .global)
                            )
                        }
                    }
            }
        )
    }
    
    // NOTE: We are NOT providing an alias to avoid conflicts with existing code
    // This extension only provides new methods
}

// Helper for consistent highlight effects in help mode
struct HelpHighlightModifier: ViewModifier {
    var elementId: String
    @ObservedObject private var helpSystem = HelpSystem.shared
    
    func body(content: Content) -> some View {
        ZStack {
            content
            
            if helpSystem.isHelpModeActive && helpSystem.isElementHighlighted(elementId) {
                RoundedRectangle(cornerRadius: 8)
                    .stroke(Color.blue, lineWidth: 2)
                    .padding(-4)
            }
        }
    }
}

extension View {
    /// Adds a highlight effect when this element is selected in help mode
    func highlightableInHelpMode(id: String) -> some View {
        self.modifier(HelpHighlightModifier(elementId: id))
    }
}