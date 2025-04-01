import SwiftUI

struct TabBarView: View {
    // MARK: - Properties
    private let tabCount: Int = 5
    private let fixedTabTitles = ["Routines", "Tasks", "Template", "Summary", "Data"]
    @Environment(\.theme) private var theme
    
    // Get the appropriate color based on the theme
    private func getTabColor(index: Int) -> Color {
        switch index {
            case 0: return theme.routinesTab
            case 1: return theme.tasksTab
            case 2: return theme.templateTab
            case 3: return theme.summaryTab
            case 4: return theme.dataTab
            default: return .gray
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