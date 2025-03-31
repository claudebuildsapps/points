import SwiftUI

struct TabBarView: View {
    // MARK: - Properties
    @State private var selectedTab: Int = 0 // State to track the selected tab
    private let tabCount: Int = 5
    private let fixedTabTitles = ["Routines", "Tasks", "Template", "Summary", "Data"]
    private let tabColors: [Color] = [
        Color(red: 0.4, green: 0.6, blue: 0.8),  // Blue
        Color(red: 0.5, green: 0.7, blue: 0.6),  // Green
        Color(red: 0.6, green: 0.65, blue: 0.75), // Bluish-purple
        Color(red: 0.7, green: 0.6, blue: 0.5),  // Orange
        Color(red: 0.8, green: 0.5, blue: 0.4)   // Red
    ]
    
    // Closure to handle tab selection (replacing delegate)
    let onTabSelected: (Int) -> Void
    
    // MARK: - Body
    var body: some View {
        HStack(spacing: 0) {
            ForEach(0..<tabCount, id: \.self) { index in
                Button(action: {
                    handleTabSelection(index: index)
                }) {
                    Text(fixedTabTitles[index])
                        .font(.system(size: 14, weight: .medium)) // Larger font
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity, maxHeight: .infinity) // Full height and width
                        .background(tabColors[index])
                        .overlay(
                            selectedTab == index ?
                                RoundedRectangle(cornerRadius: 0)
                                    .stroke(Color.white, lineWidth: 2)
                                : nil
                        )
                        .opacity(selectedTab == index ? 1.0 : 0.8)
                }
                
                // Add divider after each tab (except the last)
                if index < tabCount - 1 {
                    Rectangle()
                        .fill(Color.white)
                        .frame(width: 1)
                }
            }
        }
        .background(Color.clear)
        .edgesIgnoringSafeArea(.bottom) // Extend to bottom edge
        .clipShape(RoundedRectangle(cornerRadius: 0)) // Remove rounded corners
        .overlay(
            Rectangle() // Use rectangle instead of rounded rectangle
                .stroke(Color.gray.opacity(0.5), lineWidth: 1)
        )
    }
    
    // MARK: - Methods
    private func handleTabSelection(index: Int) {
        // Special handling for the "Data" tab (index 4)
        if index == 4 {
            // In SwiftUI, we can't directly access the view controller
            // This action will need to be handled by the parent view
            // We'll call the callback and let the parent handle it
            onTabSelected(index)
            return
        }
        
        // For other tabs, update the selected tab and notify the parent
        selectedTab = index
        onTabSelected(index)
    }
    
    /// Sets the active tab programmatically
    func setActiveTab(at index: Int) {
        selectedTab = index
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
