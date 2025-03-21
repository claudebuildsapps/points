import UIKit
import CoreData
import SnapKit

// Add this extension to DateNavigationView to access the current date
extension DateNavigationView {
    func getCurrentDate() -> Date? {
        // This is a helper method to access the current date from outside
        // Access the private currentDate property via reflection
        let mirror = Mirror(reflecting: self)
        for child in mirror.children {
            if child.label == "currentDate" {
                return child.value as? Date
            }
        }
        return nil
    }
}

class TasksViewController: UIViewController {
    
    // MARK: - Properties
    private let tableView = UITableView(frame: .zero, style: .plain)
    private let dateNavigationView = DateNavigationView()
    private var fetchedResultsController: NSFetchedResultsController<CoreDataTask>!
    
    private lazy var context: NSManagedObjectContext = {
        // Assuming you have a CoreData stack set up, access the viewContext
        let appDelegate = UIApplication.shared.delegate as! AppDelegate
        return appDelegate.persistentContainer.viewContext
    }()
    
    // Keep track of the currently selected date entity
    private var currentDateEntity: CoreDataDate?
    
    // MARK: - Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
        
        setupUI()
        setupDateNavigation()
        
        // Configure the date navigation view with the CoreData context
        dateNavigationView.configure(with: context)
        
        // Set initial date to today and fetch tasks
        let today = Date()
        dateNavigationView.setDate(today)
        // fetchOrCreateDateEntity will be called by dateDidChange delegate method
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        // Refresh the current date's tasks when the view appears
        // This helps ensure we always show the latest data
        if let currentDate = dateNavigationView.getCurrentDate() {
            fetchOrCreateDateEntity(for: currentDate)
        }
    }
    
    // MARK: - UI Setup
    private func setupUI() {
        view.backgroundColor = .systemBackground
        
        // Configure table view
        tableView.delegate = self
        tableView.dataSource = self
        tableView.register(TaskTableViewCell.self, forCellReuseIdentifier: "TaskCell")
        tableView.rowHeight = UITableView.automaticDimension
        tableView.estimatedRowHeight = 80
        
        // Configure date navigation view
        dateNavigationView.delegate = self
        
        // Add subviews
        view.addSubview(dateNavigationView)
        view.addSubview(tableView)
        
        // Setup constraints with SnapKit
        dateNavigationView.snp.makeConstraints { make in
            make.top.equalTo(view.safeAreaLayoutGuide)
            make.leading.trailing.equalToSuperview()
            make.height.equalTo(50)
        }
        
        tableView.snp.makeConstraints { make in
            make.top.equalTo(dateNavigationView.snp.bottom)
            make.leading.trailing.bottom.equalToSuperview()
        }
    }
    
    private func setupDateNavigation() {
        // Set today as the initial date
        dateNavigationView.setDate(Date())
    }
    
    // MARK: - Core Data Operations
    
    /// Fetches an existing CoreDataDate entity for the given date or creates a new one
    private func fetchOrCreateDateEntity(for date: Date) {
        // Extract the date components to compare dates without time
        let calendar = Calendar.current
        let dateComponents = calendar.dateComponents([.year, .month, .day], from: date)
        let startOfDay = calendar.date(from: dateComponents)!
        
        // First try to find an existing date entity using a date range predicate
        // This is more reliable than exact matching for Date objects
        let fromDate = startOfDay
        let toDate = calendar.date(byAdding: .day, value: 1, to: startOfDay)!
        
        let datePredicate = NSPredicate(format: "date >= %@ AND date < %@",
                                      fromDate as NSDate,
                                      toDate as NSDate)
        
        let fetchRequest: NSFetchRequest<CoreDataDate> = CoreDataDate.fetchRequest()
        fetchRequest.predicate = datePredicate
        
        do {
            let results = try context.fetch(fetchRequest)
            
            if let existingDate = results.first {
                // Use existing date entity
                currentDateEntity = existingDate
                print("Found existing date entity for \(startOfDay)")
            } else {
                // Create a new date entity for this day
                let newDateEntity = CoreDataDate(context: context)
                newDateEntity.date = startOfDay
                
                try context.save()
                currentDateEntity = newDateEntity
                print("Created new date entity for \(startOfDay)")
            }
            
            // Update the fetched results controller with the new date
            configureFetchedResultsController()
            
        } catch {
            print("Error fetching or creating date entity: \(error)")
        }
    }
    
    /// Configures the NSFetchedResultsController to get tasks for the current date
    private func configureFetchedResultsController() {
        guard let currentDateEntity = currentDateEntity else {
            print("Cannot configure fetched results controller: no current date entity")
            return
        }
        
        let fetchRequest: NSFetchRequest<CoreDataTask> = CoreDataTask.fetchRequest()
        
        // Filter tasks by the current date entity using the object ID for exact matching
        // This is more reliable than using the object itself in predicates
        fetchRequest.predicate = NSPredicate(format: "date == %@", currentDateEntity)
        
        // Print some debug info
        print("Fetching tasks for date: \(String(describing: currentDateEntity.date))")
        print("Date entity ID: \(currentDateEntity.objectID)")
        
        // Sort by position (if you want to maintain a specific order)
        let sortDescriptor = NSSortDescriptor(key: "position", ascending: true)
        fetchRequest.sortDescriptors = [sortDescriptor]
        
        // Create the fetched results controller
        fetchedResultsController = NSFetchedResultsController(
            fetchRequest: fetchRequest,
            managedObjectContext: context,
            sectionNameKeyPath: nil,
            cacheName: nil // Don't use a cache as it might cause issues with switching dates
        )
        
        fetchedResultsController.delegate = self
        
        // Perform the fetch
        do {
            try fetchedResultsController.performFetch()
            let count = fetchedResultsController.fetchedObjects?.count ?? 0
            print("Fetched \(count) tasks for the current date")
            tableView.reloadData()
        } catch {
            print("Error fetching tasks: \(error)")
        }
    }
    
    // MARK: - Task Management
    
    /// Creates a new task for the current date
    @objc func addNewTask() {
        guard let currentDateEntity = currentDateEntity else { return }
        
        // Create new task
        let newTask = CoreDataTask(context: context)
        newTask.title = "New Task"
        newTask.points = NSDecimalNumber(value: 1.0)
        newTask.target = 1
        newTask.completed = 0
        newTask.date = currentDateEntity
        
        // Set position to be after the last task
        let count = fetchedResultsController.fetchedObjects?.count ?? 0
        newTask.position = Int16(count)
        
        // Save context
        do {
            try context.save()
            tableView.reloadData()
        } catch {
            print("Error saving new task: \(error)")
        }
    }
    
    /// Duplicates a task from a previous date to the current date
    func duplicateTask(_ task: CoreDataTask, toDate date: CoreDataDate) {
        let duplicatedTask = CoreDataTask(context: context)
        
        // Copy all attributes
        duplicatedTask.title = task.title
        duplicatedTask.points = task.points
        duplicatedTask.target = task.target
        duplicatedTask.completed = 0 // Reset completion
        duplicatedTask.date = date
        duplicatedTask.position = task.position
        duplicatedTask.active = task.active
        duplicatedTask.optional = task.optional
        duplicatedTask.routine = task.routine
        
        // Save context
        do {
            try context.save()
        } catch {
            print("Error duplicating task: \(error)")
        }
    }
}

// MARK: - DateNavigationViewDelegate
extension TasksViewController: DateNavigationViewDelegate {
    func dateDidChange(to dateObject: CoreDataDate) {
        // Store the current date entity
        self.currentDateEntity = dateObject
        
        // Update the fetched results controller to show tasks for this date
        configureFetchedResultsController()
        
        // Log for debugging
        print("Date changed to: \(dateObject.date?.description ?? "unknown")")
    }
}

// MARK: - UITableViewDelegate & UITableViewDataSource
extension TasksViewController: UITableViewDelegate, UITableViewDataSource {
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return fetchedResultsController.fetchedObjects?.count ?? 0
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let cell = tableView.dequeueReusableCell(withIdentifier: "TaskCell", for: indexPath) as? TaskTableViewCell,
              let task = fetchedResultsController.fetchedObjects?[indexPath.row] else {
            return UITableViewCell()
        }
        
        cell.configure(with: task)
        cell.delegate = self
        
        return cell
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        guard let cell = tableView.cellForRow(at: indexPath) as? TaskTableViewCell else {
            return 80 // Default height
        }
        
        // Return different heights based on expanded state
        return cell.isExpanded ? 180 : 80
    }
}

// MARK: - TaskTableViewCellDelegate
extension TasksViewController: TaskTableViewCellDelegate {
    func cellDidSaveEdit(_ cell: TaskTableViewCell, task: CoreDataTask, updatedValues: [String: Any]) {
        // Apply updates to the task
        for (key, value) in updatedValues {
            task.setValue(value, forKey: key)
        }
        
        // Save context
        do {
            try context.save()
        } catch {
            print("Error saving task edits: \(error)")
        }
    }
    
    func cellDidCancelEdit(_ cell: TaskTableViewCell) {
        // Reset cell UI state without saving changes
        cell.toggleExpandedState(expanded: false)
    }
    
    func cellDidRequestDecrement(_ cell: TaskTableViewCell, task: CoreDataTask) {
        // Decrement the completed count (undo)
        if task.completed > 0 {
            task.completed -= 1
            
            // Save context
            do {
                try context.save()
                cell.configure(with: task)
            } catch {
                print("Error decrementing task: \(error)")
            }
        }
    }
    
    func cellDidRequestDuplicate(_ cell: TaskTableViewCell, task: CoreDataTask) {
        guard let currentDateEntity = currentDateEntity else { return }
        duplicateTask(task, toDate: currentDateEntity)
    }
    
    func cellDidRequestDelete(_ cell: TaskTableViewCell, task: CoreDataTask) {
        // Delete the task
        context.delete(task)
        
        // Save context
        do {
            try context.save()
        } catch {
            print("Error deleting task: \(error)")
        }
    }
}

// MARK: - NSFetchedResultsControllerDelegate
extension TasksViewController: NSFetchedResultsControllerDelegate {
    
    func controllerWillChangeContent(_ controller: NSFetchedResultsController<NSFetchRequestResult>) {
        tableView.beginUpdates()
    }
    
    func controller(_ controller: NSFetchedResultsController<NSFetchRequestResult>,
                    didChange anObject: Any,
                    at indexPath: IndexPath?,
                    for type: NSFetchedResultsChangeType,
                    newIndexPath: IndexPath?) {
        
        switch type {
        case .insert:
            if let newIndexPath = newIndexPath {
                tableView.insertRows(at: [newIndexPath], with: .automatic)
            }
        case .delete:
            if let indexPath = indexPath {
                tableView.deleteRows(at: [indexPath], with: .automatic)
            }
        case .update:
            if let indexPath = indexPath,
               let cell = tableView.cellForRow(at: indexPath) as? TaskTableViewCell,
               let task = controller.object(at: indexPath) as? CoreDataTask {
                cell.configure(with: task)
            }
        case .move:
            if let indexPath = indexPath, let newIndexPath = newIndexPath {
                tableView.deleteRows(at: [indexPath], with: .automatic)
                tableView.insertRows(at: [newIndexPath], with: .automatic)
            }
        @unknown default:
            break
        }
    }
    
    func controllerDidChangeContent(_ controller: NSFetchedResultsController<NSFetchRequestResult>) {
        tableView.endUpdates()
    }
}
