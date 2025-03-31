import SwiftUI
import CoreData

struct DateNavigationView: View {
    @Environment(\.managedObjectContext) private var context
    @State private var currentDate: Date = Date()
    let onDateChange: (CoreDataDate) -> Void
    
    // Use a computed property for DateHelper to ensure it uses the current context
    private var dateHelper: DateHelper { DateHelper(context: context) }
    
    var body: some View {
        HStack {
            // Left arrow button
            navigationButton(direction: .backward)
            
            // Date display
            Text(currentDate.formatted())
                .font(.headline)
                .frame(maxWidth: .infinity)
            
            // Right arrow button
            navigationButton(direction: .forward)
        }
        .padding(.horizontal)
        .onAppear(perform: updateDateEntity)
        .onChange(of: currentDate) { _ in updateDateEntity() }
    }
    
    // Helper enum for arrow directions
    private enum Direction { case forward, backward }
    
    // Create a navigation button
    private func navigationButton(direction: Direction) -> some View {
        Button(action: { changeDate(by: direction == .forward ? 1 : -1) }) {
            Image(systemName: direction == .forward ? "chevron.right" : "chevron.left")
                .font(.system(size: 24, weight: .bold))
                .foregroundColor(Constants.Colors.templateTab)
                .frame(width: 44, height: 44)
        }
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
        DateNavigationView(onDateChange: { _ in })
            .environment(\.managedObjectContext, PersistenceController.preview.container.viewContext)
    }
}