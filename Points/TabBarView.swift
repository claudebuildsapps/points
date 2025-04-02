import SwiftUI

struct TabBarView: View {
    // MARK: - Properties
    private let tabCount: Int = 5
    private let fixedTabTitles = ["Routines", "Tasks", "Template", "Summary", "Data"]
    @Environment(\.theme) private var theme
    
    // Current selected tab index
    var selectedIndex: Int = 0
    
    // Current filter state for color adjustments
    var taskFilter: TaskFilter = .all
    
    // Initializer that accepts the filter state
    init(
        selectedIndex: Int = 0,
        taskFilter: TaskFilter = .all,
        onTabSelected: @escaping (Int) -> Void
    ) {
        self.selectedIndex = selectedIndex
        self.taskFilter = taskFilter
        self.onTabSelected = onTabSelected
    }
    
    // Get the appropriate color based on the theme and filter state
    private func getTabColor(index: Int) -> some View {
        let baseColor: Color
        switch index {
            case 0: baseColor = theme.routinesTab
            case 1: baseColor = theme.tasksTab
            case 2: baseColor = theme.templateTab
            case 3: baseColor = theme.summaryTab
            case 4: baseColor = theme.dataTab
            default: baseColor = .gray
        }
        
        // Create a ZStack with white overlay for selected tabs
        return ZStack {
            baseColor
            // Make visually LIGHTER when selected by adding white overlay
            if (index == 0 && taskFilter == .routines) || 
               (index == 1 && taskFilter == .tasks) {
                Color.white.opacity(0.3) // Add white overlay = lighter
            }
        }
    }
    
    // Closure to handle tab selection
    let onTabSelected: (Int) -> Void
    
    // MARK: - Body
    var body: some View {
        HStack(spacing: 0) {
            ForEach(0..<tabCount, id: \.self) { index in
                Button(action: {
                    handleTabSelection(index: index)
                }) {
                    Text(fixedTabTitles[index])
                        .font(.system(size: 14, weight: .semibold)) // Increased weight for better readability
                        .foregroundColor(theme.textInverted)
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                        .padding(.top, 10) // Add top padding (20% of 50px height)
                        .padding(.bottom, 10) // Add bottom padding (20% of 50px height)
                        .background(getTabColor(index: index))
                        // Remove border overlay to make tabs completely adjacent
                }
                
                // Remove dividers between tabs to make them completely adjacent
            }
        }
        .background(Color.clear)
        .edgesIgnoringSafeArea(.bottom)
        // No rounded corners or borders to ensure tabs are completely adjacent
    }
    
    // MARK: - Methods
    private func handleTabSelection(index: Int) {
        onTabSelected(index)
    }
}

// MARK: - Preview
struct TabBarView_Previews: PreviewProvider {
    static var previews: some View {
        TabBarView(onTabSelected: { index in
            print("Selected tab: \(index)")
        })
        .frame(height: 40)
        .previewLayout(.sizeThatFits)
        .padding()
    }
}
