import SwiftUI
import CoreData

struct DateNavigationView: View {
    @Environment(\.managedObjectContext) private var context
    @State private var currentDate: Date = Date()
    let onDateChange: (CoreDataDate) -> Void
    
    var body: some View {
        HStack {
            // Left arrow using Template tab color - no circle, just thicker arrow (1.5x)
            Button(action: { changeDate(by: -1) }) {
                Image(systemName: "chevron.left")
                    .font(.system(size: 24, weight: .bold)) // Much thicker arrow (1.5x)
                    .foregroundColor(Color(red: 0.6, green: 0.65, blue: 0.75)) // Template tab color for arrow
                    .frame(width: 44, height: 44) // Larger tappable area
            }
            
            Text(dateString)
                .font(.headline)
                .frame(maxWidth: .infinity)
            
            // Right arrow using Template tab color - no circle, just thicker arrow (1.5x)
            Button(action: { changeDate(by: 1) }) {
                Image(systemName: "chevron.right")
                    .font(.system(size: 24, weight: .bold)) // Much thicker arrow (1.5x)
                    .foregroundColor(Color(red: 0.6, green: 0.65, blue: 0.75)) // Template tab color for arrow
                    .frame(width: 44, height: 44) // Larger tappable area
            }
        }
        .padding(.horizontal)
        .onAppear {
            fetchOrCreateDateEntity(for: currentDate)
        }
        .onChange(of: currentDate) { newDate in
            fetchOrCreateDateEntity(for: newDate)
        }
    }
    
    private var dateString: String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        return formatter.string(from: currentDate)
    }
    
    private func changeDate(by days: Int) {
        // Create a new date by adding/subtracting days
        if let newDate = Calendar.current.date(byAdding: .day, value: days, to: currentDate) {
            print("DateNavigationView: Changing date from \(currentDate) to \(newDate)")
            currentDate = newDate
            
            // This triggers onChange which calls fetchOrCreateDateEntity
            // which then calls onDateChange to pass the date entity back to the parent
        }
    }
    
    private func fetchOrCreateDateEntity(for date: Date) {
        let calendar = Calendar.current
        let dateComponents = calendar.dateComponents([.year, .month, .day], from: date)
        let startOfDay = calendar.date(from: dateComponents)!
        
        print("DateNavigationView: Fetching or creating date entity for \(startOfDay)")
        
        let fromDate = startOfDay
        let toDate = calendar.date(byAdding: .day, value: 1, to: startOfDay)!
        
        let datePredicate = NSPredicate(format: "date >= %@ AND date < %@", fromDate as NSDate, toDate as NSDate)
        
        let fetchRequest: NSFetchRequest<CoreDataDate> = CoreDataDate.fetchRequest()
        fetchRequest.predicate = datePredicate

        do {
            let results = try context.fetch(fetchRequest)
            
            if let existingDate = results.first {
                print("DateNavigationView: Found existing entity for \(startOfDay), ID: \(existingDate.objectID.uriRepresentation().absoluteString)")
                onDateChange(existingDate)
            } else {
                print("DateNavigationView: Creating new entity for \(startOfDay)")
                let newDateEntity = CoreDataDate(context: context)
                newDateEntity.date = startOfDay
                newDateEntity.target = 5 // Default target
                newDateEntity.points = NSDecimalNumber(value: 0.0) // Initialize with zero points
                try context.save()
                
                print("DateNavigationView: Created new entity, ID: \(newDateEntity.objectID.uriRepresentation().absoluteString)")
                onDateChange(newDateEntity)
            }
        } catch {
            print("Error fetching or creating date entity: \(error)")
        }
    }
    
    // Public method to set the date
    mutating func setDate(_ date: Date) {
        self.currentDate = date
    }
    
    // Public method to get the current date
    func getCurrentDate() -> Date? {
        return currentDate
    }
}

struct DateNavigationView_Previews: PreviewProvider {
    static var previews: some View {
        DateNavigationView(onDateChange: { _ in })
            .environment(\.managedObjectContext, PersistenceController.preview.container.viewContext)
    }
}
