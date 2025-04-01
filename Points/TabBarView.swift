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
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(theme.textInverted)
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                        .background(getTabColor(index: index))
                        .overlay(
                            RoundedRectangle(cornerRadius: 0)
                                .stroke(theme.textInverted, lineWidth: 2)
                                .opacity(0.8)
                        )
                }
                
                // Add divider after each tab (except the last)
                if index < tabCount - 1 {
                    Rectangle()
                        .fill(theme.divider)
                        .frame(width: 1)
                }
            }
        }
        .background(Color.clear)
        .edgesIgnoringSafeArea(.bottom)
        .clipShape(RoundedRectangle(cornerRadius: 0))
        .overlay(
            Rectangle()
                .stroke(theme.divider, lineWidth: 1)
        )
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