import UIKit
import CoreData
import SnapKit

class ViewController: UIViewController, TaskTableViewManagerDelegate, TabBarViewDelegate, DateNavigationViewDelegate {
    // MARK: - Properties
    private let taskManager: TaskManager
    private let gamificationEngine: GamificationEngine
    private var tasks: [CoreDataTask] = []
    private let pointsGoal: Int = 100
    private var currentDateEntity: CoreDataDate?
    
    // MARK: - UI Components
    private let dateNavigationView = DateNavigationView()
    private let tableView: UITableView = {
        let tableView = UITableView()
        tableView.separatorStyle = .singleLine
        tableView.backgroundColor = .systemBackground
        return tableView
    }()
    
    private let progressBarView = ProgressBarView()
    private let tabBarView = TabBarView()
    private let pointsDisplayView = FooterDisplayView()
    
    private lazy var taskTableManager: TaskTableViewManager = {
        TaskTableViewManager(tableView: tableView, delegate: self)
    }()
    
    // MARK: - Initializers
    init() {
        let context = (UIApplication.shared.delegate as! AppDelegate).persistentContainer.viewContext
        self.taskManager = TaskManager(context: context)
        self.gamificationEngine = GamificationEngine()
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder: NSCoder) {
        let context = (UIApplication.shared.delegate as! AppDelegate).persistentContainer.viewContext
        self.taskManager = TaskManager(context: context)
        self.gamificationEngine = GamificationEngine()
        super.init(coder: coder)
    }
    
    // MARK: - Lifecycle Methods
    override func viewDidLoad() {
        super.viewDidLoad()
        
        view.backgroundColor = .systemBackground
        edgesForExtendedLayout = .all
        
        if #available(iOS 11.0, *) {
            additionalSafeAreaInsets = .zero
        }
        
        setupUI()
        
        // Configure DateNavigationView with CoreData context
        let context = (UIApplication.shared.delegate as! AppDelegate).persistentContainer.viewContext
        dateNavigationView.configure(with: context)
        
        // Wire up the red reset button
        pointsDisplayView.setClearButtonTarget(self, action: #selector(resetAllTasks))

        // 2. Blue refresh button (new soft reset button)
        pointsDisplayView.setSoftResetButtonTarget(self, action: #selector(softResetTasks))

        // 3. Green + button (keeping existing functionality)
        pointsDisplayView.setAddButtonTarget(self, action: #selector(addNewTask))

        loadInitialData()
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        
        // This is crucial - force the table to layout
        tableView.layoutIfNeeded()
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        print("Main view frame: \(view.frame)")
        print("Safe area insets: \(view.safeAreaInsets)")
        print("DateNavigationView frame: \(dateNavigationView.frame)")
        print("Points display frame: \(pointsDisplayView.frame)")
        print("Device screen bounds: \(UIScreen.main.bounds)")
    }

    // MARK: - UI Setup
    private func setupUI() {
        // Setup background
        view.backgroundColor = .systemBackground
        
        // Add all views to hierarchy
        view.addSubview(dateNavigationView)
        view.addSubview(progressBarView)
        view.addSubview(tableView)
        view.addSubview(tabBarView)
        view.addSubview(pointsDisplayView)
        
        // Setup delegates
        dateNavigationView.delegate = self
        tabBarView.delegate = self
        
        // IMPORTANT: The view hierarchy is now:
        // 1. Status bar (top of screen)
        // 2. Empty space where your black bars used to be
        // 3. DateNavigationView - pulled down below the empty space
        // 4. ProgressBarView directly below date navigation
        // 5. TableView (filling most of the screen)
        // 6. TabBarView
        // 7. PointsDisplayView
        
        // Calculate the position for date navigation (pulled down)
        // This places it where the black bar used to end
        let topOffset: CGFloat = 120 // Approximate position where the black bar used to end
        
        // Using SnapKit instead of NSLayoutConstraint
        
        // DateNavigationView pulled down significantly from the top
        dateNavigationView.snp.makeConstraints { make in
            make.top.equalTo(view).offset(topOffset)
            make.leading.trailing.equalTo(view)
            make.height.equalTo(44)
        }
        
        // ProgressBar directly below date navigation
        progressBarView.snp.makeConstraints { make in
            make.top.equalTo(dateNavigationView.snp.bottom).offset(2)
            make.leading.trailing.equalTo(view)
            make.height.equalTo(12) // Thicker progress bar
        }
        
        // Points display at bottom
        pointsDisplayView.snp.makeConstraints { make in
            make.leading.equalTo(view).offset(20)
            make.trailing.equalTo(view).offset(-20)
            make.bottom.equalTo(view.safeAreaLayoutGuide).offset(-8)
            make.height.equalTo(36)
        }
        
        // Tab bar above points display
        tabBarView.snp.makeConstraints { make in
            make.leading.equalTo(view).offset(16)
            make.trailing.equalTo(view).offset(-16)
            make.bottom.equalTo(pointsDisplayView.snp.top).offset(-8)
            make.height.equalTo(36)
        }
        
        // Table view fills the space between progress bar and tab bar
        tableView.snp.makeConstraints { make in
            make.top.equalTo(progressBarView.snp.bottom).offset(4)
            make.leading.trailing.equalTo(view)
            make.bottom.equalTo(tabBarView.snp.top).offset(-8)
        }
        
        tableView.showsVerticalScrollIndicator = true
        tableView.indicatorStyle = .default
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        // Hide navigation bar
        navigationController?.setNavigationBarHidden(true, animated: false)
        
        // Ensure frame is correct
        view.frame = UIScreen.main.bounds
    }

    private func setupNavigationBar() {
        navigationItem.largeTitleDisplayMode = .never
    }
    
    // MARK: - Data Management
    private func loadInitialData() {
        tasks = taskManager.fetchTasks()
        if tasks.isEmpty {
            print("No tasks found, creating initial tasks")
            taskManager.createInitialTasksIfNeeded()
            tasks = taskManager.fetchTasks()
            print("After initialization: \(tasks.count) tasks")
        } else {
            print("Loaded \(tasks.count) existing tasks")
        }
        updateUI()
    }
    
    private func updateUI() {
        let totalPoints = taskManager.calculateTotalPoints(tasks)
        let progress = gamificationEngine.calculateProgress(totalPoints: totalPoints, goal: pointsGoal)
        progressBarView.updateProgress(progress)
        pointsDisplayView.updatePoints(totalPoints)
        taskTableManager.updateTasks(tasks)
    }
        
    // MARK: - Actions
    @objc private func addNewTask() {
        if let dateEntity = currentDateEntity {
            // Use the current date entity if available
            taskManager.createTaskForDate(title: "New Task", target: 5, points: 10, max: 5, date: dateEntity)
        } else {
            // Fall back to the original method if no date entity
            taskManager.createNewTask(title: "New Task", target: 5, points: 10, max: 5)
        }
        
        tasks = taskManager.fetchTasks()
        updateUI()
    }
    
    // MARK: - Animation Helpers
    private func showPointsAddedAnimation(points: Int, at position: CGPoint) {
        let pointsLabel = UILabel()
        pointsLabel.text = "+\(points)"
        pointsLabel.textColor = .systemGreen
        pointsLabel.font = UIFont.boldSystemFont(ofSize: 18)
        pointsLabel.sizeToFit()
        pointsLabel.center = position
        pointsLabel.alpha = 0
        view.addSubview(pointsLabel)
        
        UIView.animate(withDuration: 1.0, animations: {
            pointsLabel.center.y -= 50
            pointsLabel.alpha = 1
        }) { _ in
            UIView.animate(withDuration: 0.3, animations: {
                pointsLabel.alpha = 0
            }) { _ in
                pointsLabel.removeFromSuperview()
            }
        }
    }
    
    func didSelectTab(at index: Int) {
        print("Selected tab at index: \(index)")
        
        // Handle different tab selections
        switch index {
        case 0: // Routines
            // Filter to show only routine tasks
            tasks = taskManager.fetchTasks().filter { $0.routine }
            updateUI()
            
        case 1: // Tasks
            // Show all tasks
            tasks = taskManager.fetchTasks()
            updateUI()
            
        case 2: // Templates
            // Handle template tasks (you'll need to implement this functionality)
            // For example, you might filter tasks that have a template flag
            print("Template tab selected - implement template functionality")
            
        case 3: // Summary
            // Show summary view or filtered tasks
            print("Summary tab selected - implement summary functionality")
            
        case 4: // Data
            // Data tab is handled in the TabBarView class (shows CoreData debug)
            print("Data tab selected")
            
        default:
            break
        }
    }

    
    // MARK: - TaskTableViewManagerDelegate Methods
    func didSelectTask(_ task: CoreDataTask) {
        taskManager.incrementTaskCompletion(task)
        if let index = tasks.firstIndex(of: task),
           let cell = tableView.cellForRow(at: IndexPath(row: index, section: 0)) as? TaskTableViewCell {
            let pointsToAdd = Int(task.points?.intValue ?? 0)
            let isFirstCompletion = task.completed == 1
            
            if pointsToAdd > 0 {
                let cellRect = tableView.convert(cell.frame, to: view)
                let animationPosition = CGPoint(x: cellRect.midX, y: cellRect.minY - 10)
                showPointsAddedAnimation(points: pointsToAdd, at: animationPosition)
            }
            
            updateUI()
            
            if isFirstCompletion {
                cell.animateFirstCompletion()
            }
        }
    }
    
    func didEditTask(_ task: CoreDataTask) {
        // Empty implementation (remove or keep as needed, but it's not used in this setup)
    }
    
    func didDeleteTask(_ task: CoreDataTask) {
        let alert = UIAlertController(
            title: "Delete Task",
            message: "Are you sure you want to delete '\(task.title ?? "this task")'?",
            preferredStyle: .alert
        )
        
        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel))
        alert.addAction(UIAlertAction(title: "Delete", style: .destructive) { [weak self] _ in
            guard let self = self else { return }
            
            self.taskManager.deleteTask(task: task)
            if let index = self.tasks.firstIndex(of: task) {
                self.tasks.remove(at: index)
            }
            self.taskManager.saveContext()
            self.updateUI()
        })
        
        present(alert, animated: true)
    }
    
    func didDecrementTask(_ task: CoreDataTask) {
        taskManager.decrementTaskCompletion(task)
        updateUI()
    }
    
    func didCopyTask(_ task: CoreDataTask) {
        if let duplicatedTask = taskManager.duplicateTasks(tasks: [task]).first {
            tasks.append(duplicatedTask)
            taskManager.saveContext()
            updateUI()
        }
    }
    
    func didMoveTask(from: Int, to: Int) {
        let movedTask = tasks.remove(at: from)
        tasks.insert(movedTask, at: to)
        taskManager.setNewTaskPosition(task: movedTask, position: Int16(to))
        taskManager.saveContext()
        updateUI()
    }
    
    // MARK: - DateNavigationViewDelegate Methods
    // Updated to match the new protocol definition
    // MARK: - DateNavigationViewDelegate Methods
    func dateDidChange(to dateObject: CoreDataDate) {
        // Store the current date entity
        self.currentDateEntity = dateObject
        
        // Get the date from the date object
        let newDate = dateObject.date ?? Date()
        
        // Use the date entity directly
        if let tasksArray = dateObject.tasks?.allObjects as? [CoreDataTask] {
            // Sort tasks by position
            tasks = tasksArray.sorted {
                return Int($0.position) < Int($1.position)
            }
        } else {
            tasks = []
        }
        
        updateUI()
    }
    
    func didSaveEdit(_ cell: TaskTableViewCell, task: CoreDataTask, updatedTask: CoreDataTask) {
        // Minimal implementation to satisfy the protocol requirement
        print("Task edited: \(String(describing: task.title)) → \(String(describing: updatedTask.title))")
        
        // Try to save the context if accessible
        if let appDelegate = UIApplication.shared.delegate as? AppDelegate {
            do {
                try appDelegate.persistentContainer.viewContext.save()
            } catch {
                print("Error saving context: \(error)")
            }
        }
    }
    
    @objc private func resetAllTasks() {
        let success = taskManager.deleteAllTasks()
        if success {
            // Clear local array of tasks
            tasks.removeAll()
            // Update UI so the table view and points display are refreshed
            updateUI()
            print("All tasks were deleted successfully!")
        } else {
            print("Failed to delete all tasks.")
        }
    }
    
    @objc private func softResetTasks() {
        if taskManager.softReset() {
            // Reload the tasks after soft reset
            tasks = taskManager.fetchTasks()
            // Update UI to reflect changes
            updateUI()
            print("Tasks were soft reset successfully!")
        } else {
            print("Failed to soft reset tasks.")
        }
    }
}

// MARK: - Extension for TaskManager to support CoreDataDate
extension TaskManager {
    // Create a new task associated with a specific date object
    func createTaskForDate(title: String, target: Int, points: Int, max: Int, date: CoreDataDate) {
        // Get the context from the AppDelegate
        let appDelegate = UIApplication.shared.delegate as! AppDelegate
        let context = appDelegate.persistentContainer.viewContext
        
        let task = CoreDataTask(context: context)
        // Don't set ID if it's read-only
        // task.id = UUID()
        task.title = title
        task.target = Int16(target)
        task.points = NSDecimalNumber(value: points)
        task.max = Int16(max)
        task.completed = 0
        
        // Get the highest position and increment
        let position = getNextPositionValue()
        task.position = Int16(position)
        
        // Associate with date
        task.date = date
        
        do {
            try context.save()
        } catch {
            print("Error saving task: \(error)")
        }
    }
    
    private func getNextPositionValue() -> Int {
        // Get the context from the AppDelegate
        let appDelegate = UIApplication.shared.delegate as! AppDelegate
        let context = appDelegate.persistentContainer.viewContext
        
        let fetchRequest: NSFetchRequest<CoreDataTask> = CoreDataTask.fetchRequest()
        fetchRequest.sortDescriptors = [NSSortDescriptor(key: "position", ascending: false)]
        fetchRequest.fetchLimit = 1
        
        do {
            let result = try context.fetch(fetchRequest)
            if let highestPositionTask = result.first {
                // Convert Int16 position to Int
                return Int(highestPositionTask.position) + 1
            }
        } catch {
            print("Error fetching highest position task: \(error)")
        }
        
        return 0
    }
}
