import SwiftUI

struct TabBarView: View {
    // MARK: - Properties
    @State private var selectedTab: Int = 0
    private let tabCount: Int = 5
    private let fixedTabTitles = ["Routines", "Tasks", "Template", "Summary", "Data"]
    private let tabColors: [Color] = [
        Constants.Colors.routinesTab,
        Constants.Colors.tasksTab,
        Constants.Colors.templateTab,
        Constants.Colors.summaryTab,
        Constants.Colors.dataTab
    ]
    
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
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
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
        .edgesIgnoringSafeArea(.bottom)
        .clipShape(RoundedRectangle(cornerRadius: 0))
        .overlay(
            Rectangle()
                .stroke(Color.gray.opacity(0.5), lineWidth: 1)
        )
    }
    
    // MARK: - Methods
    private func handleTabSelection(index: Int) {
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