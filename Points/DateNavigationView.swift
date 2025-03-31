import SwiftUI
import CoreData

struct DateNavigationView: View {
    @Environment(\.managedObjectContext) private var context
    @State private var currentDate: Date = Date()
    let onDateChange: (CoreDataDate) -> Void
    
    var body: some View {
        HStack {
            Button(action: { changeDate(by: -1) }) {
                Image(systemName: "chevron.left")
                    .foregroundColor(.blue)
            }
            
            Text(dateString)
                .font(.headline)
                .frame(maxWidth: .infinity)
            
            Button(action: { changeDate(by: 1) }) {
                Image(systemName: "chevron.right")
                    .foregroundColor(.blue)
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
        if let newDate = Calendar.current.date(byAdding: .day, value: days, to: currentDate) {
            currentDate = newDate
        }
    }
    
    private func fetchOrCreateDateEntity(for date: Date) {
        let calendar = Calendar.current
        let dateComponents = calendar.dateComponents([.year, .month, .day], from: date)
        let startOfDay = calendar.date(from: dateComponents)!
        
        let fromDate = startOfDay
        let toDate = calendar.date(byAdding: .day, value: 1, to: startOfDay)!
        
        let datePredicate = NSPredicate(format: "date >= %@ AND date < %@", fromDate as NSDate, toDate as NSDate)
        
        let fetchRequest: NSFetchRequest<CoreDataDate> = CoreDataDate.fetchRequest()
        fetchRequest.predicate = datePredicate

        do {
            let results = try context.fetch(fetchRequest)
            
            if let existingDate = results.first {
                onDateChange(existingDate)
            } else {
                let newDateEntity = CoreDataDate(context: context)
                newDateEntity.date = startOfDay
                newDateEntity.target = 5 // Default target
                try context.save()
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
