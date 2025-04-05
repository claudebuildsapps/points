import SwiftUI
import CoreData

// Removed CreateTabsView entirely as requested

struct DateNavigationView: View {
    @Environment(\.managedObjectContext) private var context
    @Environment(\.theme) private var theme
    @State private var currentDate: Date = Date()
    let onDateChange: (CoreDataDate) -> Void
    
    // Notification token for navigation to today
    @State private var notificationToken: NSObjectProtocol?
    
    // Use a computed property for DateHelper to ensure it uses the current context
    private var dateHelper: DateHelper { DateHelper(context: context) }
    
    var body: some View {
        VStack(spacing: 0) {
            // Date navigation bar
            HStack(spacing: 0) {
                // Left arrow button container with fixed width
                HStack {
                    navigationButton(direction: .backward)
                    Spacer()
                }
                .frame(width: 60, alignment: .leading)
                
                // Date display with fixed spacing - centered
                Text(formattedDate())
                    .font(.headline.weight(.light))
                    .scaleEffect(1.2)
                    .foregroundColor(theme.textPrimary)
                    .frame(maxWidth: .infinity)
                
                // Right arrow button container with fixed width
                HStack {
                    Spacer()
                    navigationButton(direction: .forward)
                }
                .frame(width: 60, alignment: .trailing)
            }
            .padding(.horizontal, 8)
        }
        .onAppear {
            updateDateEntity()
            
            // Set up notification observer for navigating to today
            notificationToken = NotificationCenter.default.addObserver(
                forName: Constants.Notifications.navigateToToday,
                object: nil,
                queue: .main
            ) { _ in
                navigateToToday()
            }
        }
        .onDisappear {
            // Clean up notification observer
            if let token = notificationToken {
                NotificationCenter.default.removeObserver(token)
            }
        }
        .onChange(of: currentDate) { _ in updateDateEntity() }
    }
    
    // Format date to "Today" if current date, otherwise "Month day number with suffix, year"
    private func formattedDate() -> String {
        // Check if the date is today
        let calendar = Calendar.current
        let today = Date().startOfDay
        
        if calendar.isDate(currentDate, inSameDayAs: today) {
            return "Today"
        }
        
        // Format normally for other dates
        let formatter = DateFormatter()
        formatter.dateFormat = "MMMM d, yyyy"
        let baseString = formatter.string(from: currentDate)
        
        let day = calendar.component(.day, from: currentDate)
        let suffix = daySuffix(for: day)
        
        // Replace the day number with day number + suffix
        return baseString.replacingOccurrences(
            of: " \(day),",
            with: " \(day)\(suffix),"
        )
    }
    
    // Get the appropriate suffix for a day number
    private func daySuffix(for day: Int) -> String {
        // Special case for 11th, 12th, 13th
        if day >= 11 && day <= 13 {
            return "th"
        }
        
        switch day % 10 {
        case 1: return "st"
        case 2: return "nd"
        case 3: return "rd"
        default: return "th"
        }
    }
    
    // Helper enum for arrow directions
    private enum Direction { case forward, backward }
    
    // Create a navigation button
    private func navigationButton(direction: Direction) -> some View {
        Button(action: { changeDate(by: direction == .forward ? 1 : -1) }) {
            Image(systemName: direction == .forward ? "chevron.right" : "chevron.left")
                .font(.system(size: 24, weight: .bold))
                .foregroundColor(theme.templateTab)
                .frame(width: 40, height: 40)
        }
        .helpMetadata(HelpMetadata(
            id: "date-navigation-\(direction == .forward ? "forward" : "back")",
            title: "Date Navigation",
            description: "Navigate to \(direction == .forward ? "the next day" : "the previous day").",
            usageHints: [
                "Tap to move \(direction == .forward ? "forward" : "backward") one day",
                "You can view and manage tasks for any date"
            ],
            importance: .informational
        ))
    }
    
    // Change the current date
    private func changeDate(by days: Int) {
        if let newDate = Calendar.current.date(byAdding: .day, value: days, to: currentDate) {
            currentDate = newDate
        }
    }
    
    // Update the date entity and notify parent
    private func updateDateEntity() {
        if let dateEntity = dateHelper.getDateEntity(for: currentDate) {
            DispatchQueue.main.async {
                onDateChange(dateEntity)
            }
            dateHelper.ensureTasksExist(for: dateEntity)
        }
    }
    
    // Navigate to today's date with animation
    private func navigateToToday() {
        withAnimation(.easeInOut(duration: Constants.Animation.standard)) {
            currentDate = Date().startOfDay
        }
    }
    
    // Public methods for parent view control
    mutating func setDate(_ date: Date) {
        self.currentDate = date
    }
    
    func getCurrentDate() -> Date {
        return currentDate
    }
}

struct DateNavigationView_Previews: PreviewProvider {
    static var previews: some View {
        Group {
            DateNavigationView(onDateChange: { _ in })
                .environment(\.managedObjectContext, PersistenceController.preview.container.viewContext)
                .environment(\.theme, LightTheme())
                .previewDisplayName("Light Mode")
            
            DateNavigationView(onDateChange: { _ in })
                .environment(\.managedObjectContext, PersistenceController.preview.container.viewContext)
                .environment(\.theme, DarkTheme())
                .preferredColorScheme(.dark)
                .previewDisplayName("Dark Mode")
        }
    }
}
