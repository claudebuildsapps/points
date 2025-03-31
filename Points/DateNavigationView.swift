import SwiftUI
import CoreData

struct DateNavigationView: View {
    @Environment(\.managedObjectContext) private var context
    @State private var currentDate: Date = Date()
    let onDateChange: (CoreDataDate) -> Void
    private let dateHelper: DateHelper
    
    init(onDateChange: @escaping (CoreDataDate) -> Void) {
        self.onDateChange = onDateChange
        // Use the environment context instead of creating a new one
        self.dateHelper = DateHelper(context: PersistenceController.shared.container.viewContext)
    }
    
    var body: some View {
        HStack {
            // Left arrow 
            Button(action: { changeDate(by: -1) }) {
                Image(systemName: "chevron.left")
                    .font(.system(size: 24, weight: .bold))
                    .foregroundColor(Constants.Colors.templateTab)
                    .frame(width: 44, height: 44)
            }
            
            Text(formattedDate)
                .font(.headline)
                .frame(maxWidth: .infinity)
            
            // Right arrow
            Button(action: { changeDate(by: 1) }) {
                Image(systemName: "chevron.right")
                    .font(.system(size: 24, weight: .bold))
                    .foregroundColor(Constants.Colors.templateTab)
                    .frame(width: 44, height: 44)
            }
        }
        .padding(.horizontal)
        .onAppear {
            updateDateEntity()
        }
        .onChange(of: currentDate) { _ in
            updateDateEntity()
        }
    }
    
    private var formattedDate: String {
        DateHelper.formatDate(currentDate)
    }
    
    private func changeDate(by days: Int) {
        if let newDate = Calendar.current.date(byAdding: .day, value: days, to: currentDate) {
            currentDate = newDate
        }
    }
    
    private func updateDateEntity() {
        if let dateEntity = dateHelper.getDateEntity(for: currentDate) {
            DispatchQueue.main.async {
                onDateChange(dateEntity)
            }
            dateHelper.ensureTasksExist(for: dateEntity)
        }
    }
    
    // Public methods to set or get current date
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