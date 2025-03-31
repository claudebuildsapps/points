import UIKit
import SwiftUI
import CoreData
import SnapKit

class TaskViewController: UIViewController, NSFetchedResultsControllerDelegate {
    // MARK: - Properties
    private let context: NSManagedObjectContext
    private var fetchedResultsController: NSFetchedResultsController<CoreDataTask>!
    private var currentDateEntity: CoreDataDate?
    private var dateNavigationView: DateNavigationView?
    private var hostingController: UIHostingController<AnyView>?
    private var progressBarHostingController: UIHostingController<ProgressBarView>?
    private var footerHostingController: UIHostingController<FooterDisplayView>?

    // MARK: - Initialization
    init(context: NSManagedObjectContext) {
        self.context = context
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: - Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        setupDateNavigation()
        createInitialTasksIfNeeded()
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        if let currentDate = getCurrentDateFromNavigationView() {
            print("Fetching tasks for date: \(currentDate)")
            fetchOrCreateDateEntity(for: currentDate)
            updateProgressBar()
        } else {
            print("No current date from DateNavigationView")
        }
    }

    // MARK: - UI Setup
    private func setupUI() {
        view.backgroundColor = .systemBackground

        // Setup DateNavigationView with UIHostingController
        var dateNavView = DateNavigationView(onDateChange: { [weak self] dateObject in
            if let dateValue = dateObject as? Date {
                self?.dateDidChange(to: dateValue)
            } else if let dateEntity = dateObject as? CoreDataDate, let dateValue = dateEntity.date {
                self?.dateDidChange(to: dateValue)
            }
        })
        self.dateNavigationView = dateNavView

        let modifiedView = dateNavView.environment(\.managedObjectContext, context)
        let controller = UIHostingController(rootView: AnyView(modifiedView))
        hostingController = controller
        addChild(controller)
        view.addSubview(controller.view)
        controller.didMove(toParent: self)

        // Setup ProgressBarView with UIHostingController
        let progressBarView = ProgressBarView()
        let progressBarController = UIHostingController(rootView: progressBarView)
        progressBarHostingController = progressBarController
        addChild(progressBarController)
        view.addSubview(progressBarController.view)
        progressBarController.didMove(toParent: self)

        // Setup Task List with SwiftUI List
        let taskListView = TaskListView(
            tasks: [],
            onDecrement: { task in
                self.decrementTask(task)
            },
            onDelete: { task in
                self.deleteTask(task)
            },
            onDuplicate: { task in
                self.duplicateTask(task)
            },
            onSaveEdit: { task, updatedValues in
                self.saveTaskEdit(task: task, updatedValues: updatedValues)
            },
            onCancelEdit: { },
            onIncrement: { task in
                self.incrementTask(task)
            }
        )
        .environment(\.managedObjectContext, context)

        let taskListController = UIHostingController(rootView: AnyView(taskListView))
        addChild(taskListController)
        view.addSubview(taskListController.view)
        taskListController.didMove(toParent: self)

        // Setup FooterDisplayView with UIHostingController
        let footerView = FooterDisplayView(
            onAddButtonTapped: { [weak self] in
                self?.addNewTask()
            },
            onClearButtonTapped: { [weak self] in
                self?.clearTasks()
            },
            onSoftResetButtonTapped: { [weak self] in
                self?.softResetTasks()
            },
            onCreateNewTaskInEditMode: { [weak self] in
                self?.createNewTaskInEditMode()
            }
        )
        let footerController = UIHostingController(rootView: footerView)
        footerHostingController = footerController
        addChild(footerController)
        view.addSubview(footerController.view)
        footerController.didMove(toParent: self)

        // Setup constraints with SnapKit
        controller.view.snp.makeConstraints { make in
            make.top.equalTo(view.safeAreaLayoutGuide)
            make.leading.trailing.equalToSuperview()
            make.height.equalTo(50)
        }

        progressBarController.view.snp.makeConstraints { make in
            make.top.equalTo(controller.view.snp.bottom)
            make.leading.trailing.equalToSuperview()
            make.height.equalTo(6)
        }

        taskListController.view.snp.makeConstraints { make in
            make.top.equalTo(progressBarController.view.snp.bottom)
            make.leading.trailing.equalToSuperview()
            make.bottom.equalTo(footerController.view.snp.top)
        }

        footerController.view.snp.makeConstraints { make in
            make.bottom.equalTo(view.safeAreaLayoutGuide)
            make.leading.trailing.equalToSuperview()
            make.height.equalTo(60)
        }
    }
    
    // MARK: - Date Navigation
    private func setupDateNavigation() {
        let today = Calendar.current.startOfDay(for: Date())
        dateNavigationView?.setDate(today)
    }

    private func getCurrentDateFromNavigationView() -> Date? {
        return dateNavigationView?.getCurrentDate()
    }

    private func dateDidChange(to date: Date) {
        fetchOrCreateDateEntity(for: date)
        updateProgressBar()
    }
    
    // Expose a method to update the date
    func setDate(_ date: Date) {
        dateNavigationView?.setDate(date)
        fetchOrCreateDateEntity(for: date)
        updateProgressBar()
    }

    // MARK: - Core Data Management
    private func fetchOrCreateDateEntity(for date: Date) {
        var calendar = Calendar.current
        calendar.timeZone = TimeZone(identifier: "UTC")!
        let dateComponents = calendar.dateComponents([.year, .month, .day], from: date)
        let startOfDay = calendar.date(from: dateComponents)!

        let fromDate = startOfDay
        let toDate = calendar.date(byAdding: .day, value: 1, to: startOfDay)!

        let datePredicate = NSPredicate(format: "date >= %@ AND date < %@", fromDate as NSDate, toDate as NSDate)

        let fetchRequest: NSFetchRequest<CoreDataDate> = CoreDataDate.fetchRequest()
        fetchRequest.predicate = datePredicate
        fetchRequest.sortDescriptors = [NSSortDescriptor(keyPath: \CoreDataDate.date, ascending: true)]

        do {
            let results = try context.fetch(fetchRequest)
            print("Fetched \(results.count) CoreDataDate entities for \(startOfDay)")
            for (index, result) in results.enumerated() {
                print("Result \(index): \(result.date?.description ?? "nil")")
            }

            if let existingDate = results.first {
                currentDateEntity = existingDate
                print("Found existing date entity for \(startOfDay): \(existingDate.date?.description ?? "nil")")
            } else {
                let newDateEntity = CoreDataDate(context: context)
                newDateEntity.date = startOfDay
                newDateEntity.target = 5
                try context.save()
                currentDateEntity = newDateEntity
                print("Created new date entity for \(startOfDay): \(newDateEntity.date?.description ?? "nil")")
            }

            configureFetchedResultsController()
        } catch {
            print("Error fetching or creating date entity: \(error)")
        }
    }

    private func configureFetchedResultsController() {
        guard let currentDateEntity = currentDateEntity else {
            print("Cannot configure fetched results controller: no current date entity")
            return
        }

        let fetchRequest: NSFetchRequest<CoreDataTask> = CoreDataTask.fetchRequest()
        fetchRequest.predicate = NSPredicate(format: "date == %@", currentDateEntity)

        print("Fetching tasks for date: \(String(describing: currentDateEntity.date))")
        print("Date entity ID: \(currentDateEntity.objectID)")

        let sortDescriptor = NSSortDescriptor(key: "date", ascending: true)
        fetchRequest.sortDescriptors = [NSSortDescriptor(keyPath: \CoreDataDate.date, ascending: true)]

        fetchedResultsController = NSFetchedResultsController(
            fetchRequest: fetchRequest,
            managedObjectContext: context,
            sectionNameKeyPath: nil,
            cacheName: nil
        )

        fetchedResultsController.delegate = self

        do {
            try fetchedResultsController.performFetch()
            let count = fetchedResultsController.fetchedObjects?.count ?? 0
            print("Fetched \(count) tasks for the current date")
            updateProgressBar()
        } catch {
            print("Error fetching tasks: \(error)")
        }
    }
    
    
    // MARK: - Task Actions
    @objc func addNewTask() {
        guard let currentDateEntity = currentDateEntity else { return }

        let newTask = CoreDataTask(context: context)
        newTask.title = "New Task"
        newTask.points = NSDecimalNumber(value: 1.0)
        newTask.target = 1
        newTask.completed = 0
        newTask.date = currentDateEntity

        let count = fetchedResultsController.fetchedObjects?.count ?? 0
        newTask.position = Int16(count)

        do {
            try context.save()
            updateProgressBar()
        } catch {
            print("Error saving new task: \(error)")
        }
    }

    private func clearTasks() {
        guard let tasks = fetchedResultsController.fetchedObjects else { return }
        for task in tasks {
            context.delete(task)
        }
        do {
            try context.save()
            updateProgressBar()
        } catch {
            print("Error clearing tasks: \(error)")
        }
    }

    private func softResetTasks() {
        guard let tasks = fetchedResultsController.fetchedObjects else { return }
        for task in tasks {
            task.completed = 0
        }
        do {
            try context.save()
            updateProgressBar()
        } catch {
            print("Error soft resetting tasks: \(error)")
        }
    }

    private func createNewTaskInEditMode() {
        // Implement if needed
    }

    private func incrementTask(_ task: CoreDataTask) {
        task.completed += 1
        do {
            try context.save()
            updateProgressBar()
        } catch {
            print("Error incrementing task: \(error)")
        }
    }

    private func decrementTask(_ task: CoreDataTask) {
        if task.completed > 0 {
            task.completed -= 1
            do {
                try context.save()
                updateProgressBar()
            } catch {
                print("Error decrementing task: \(error)")
            }
        }
    }

    private func deleteTask(_ task: CoreDataTask) {
        context.delete(task)
        do {
            try context.save()
            updateProgressBar()
        } catch {
            print("Error deleting task: \(error)")
        }
    }

    private func duplicateTask(_ task: CoreDataTask) {
        guard let currentDateEntity = currentDateEntity else { return }

        let newTask = CoreDataTask(context: context)
        newTask.title = task.title
        newTask.points = task.points
        newTask.target = task.target
        newTask.completed = 0
        newTask.date = currentDateEntity

        let count = fetchedResultsController.fetchedObjects?.count ?? 0
        newTask.position = Int16(count)

        do {
            try context.save()
            updateProgressBar()
        } catch {
            print("Error duplicating task: \(error)")
        }
    }

    private func saveTaskEdit(task: CoreDataTask, updatedValues: [String: Any]) {
        if let title = updatedValues["title"] as? String {
            task.title = title
        }
        if let points = updatedValues["points"] as? NSDecimalNumber {
            task.points = points
        }
        if let target = updatedValues["target"] as? Int16 {
            task.target = target
        }
        if let reward = updatedValues["reward"] as? NSDecimalNumber {
            task.reward = reward
        }
        if let max = updatedValues["max"] as? Int16 {
            task.max = max
        }
        if let routine = updatedValues["routine"] as? Bool {
            task.routine = routine
        }
        if let optional = updatedValues["optional"] as? Bool {
            task.optional = optional
        }

        do {
            try context.save()
            updateProgressBar()
        } catch {
            print("Error saving task edit: \(error)")
        }
    }

    // MARK: - Progress and Footer Updates
    private func updateProgressBar() {
        guard let tasks = fetchedResultsController.fetchedObjects,
              let currentDateEntity = currentDateEntity else {
            progressBarHostingController?.rootView.updateProgress(0)
            return
        }

        let totalPoints = tasks.reduce(0) { $0 + (Int($1.completed) * Int(truncating: $1.points ?? 0)) }
        let targetPoints = Int(currentDateEntity.target) * tasks.count
        let progress = targetPoints > 0 ? Float(totalPoints) / Float(targetPoints) : 0.0
        progressBarHostingController?.rootView.updateProgress(progress)
    }

    private func updateFooterPoints() {
        guard let tasks = fetchedResultsController.fetchedObjects else {
            footerHostingController?.rootView.updatePoints(0)
            return
        }
        let totalPoints = tasks.reduce(0) { $0 + (Int($1.completed) * Int(truncating: $1.points ?? 0)) }
        footerHostingController?.rootView.updatePoints(totalPoints)
    }

    // MARK: - Initial Tasks
    private func createInitialTasksIfNeeded() {
        let fetchRequest: NSFetchRequest<CoreDataTask> = CoreDataTask.fetchRequest()
        fetchRequest.fetchLimit = 1

        do {
            let count = try context.count(for: fetchRequest)
            if count == 0 {
                var calendar = Calendar.current
                calendar.timeZone = TimeZone(identifier: "UTC")!
                let today = calendar.startOfDay(for: Date())

                let dateEntity = CoreDataDate(context: context)
                dateEntity.date = today
                dateEntity.target = 5

                let tasks = [
                    ("Task 1", 5.0, 3),
                    ("Task 2", 3.0, 2),
                    ("Task 3", 2.0, 1)
                ]

                for (index, taskData) in tasks.enumerated() {
                    let task = CoreDataTask(context: context)
                    task.title = taskData.0
                    task.points = NSDecimalNumber(value: taskData.1)
                    task.target = Int16(taskData.2)
                    task.completed = 0
                    task.date = dateEntity
                    task.position = Int16(index)
                }

                try context.save()
                print("Created initial tasks for date: \(today)")
            }
        } catch {
            print("Error creating initial tasks: \(error)")
        }
    }
}
