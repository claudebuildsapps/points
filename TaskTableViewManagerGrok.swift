import UIKit
import CoreData

public protocol TaskTableViewManagerDelegate: AnyObject {
    func didSelectTask(_ task: CoreDataTask)
    func didEditTask(_ task: CoreDataTask)
    func didDeleteTask(_ task: CoreDataTask)
    func didDecrementTask(_ task: CoreDataTask)
    func didCopyTask(_ task: CoreDataTask)
    func didMoveTask(from: Int, to: Int)
}

public class TaskTableViewManager: NSObject, UITableViewDataSource, UITableViewDelegate, UITableViewDragDelegate, UITableViewDropDelegate {
    private let tableView: UITableView
    public weak var delegate: TaskTableViewManagerDelegate?
    public var tasks: [CoreDataTask] = []  // Changed from [Task] to [CoreDataTask]
    public var typeFilter: Int16 = 0

    public init(tableView: UITableView, delegate: TaskTableViewManagerDelegate?) {
        self.tableView = tableView
        self.delegate = delegate
        super.init()
        tableView.dataSource = self
        tableView.delegate = self
        tableView.dragDelegate = self
        tableView.dropDelegate = self
        tableView.dragInteractionEnabled = true
        setupTableView()
    }

    private func setupTableView() {
        tableView.register(UITableViewCell.self, forCellReuseIdentifier: "TaskCell")
    }

    func updateTasks(_ tasks: [CoreDataTask]) {
        // Update table view with CoreDataTask objects
        self.tasks = tasks
        tableView.reloadData()
    }

    // MARK: - UITableViewDataSource
    public func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        tasks.count
    }

    public func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "TaskCell", for: indexPath)
        let task = tasks[indexPath.row]
        cell.textLabel?.text = task.title ?? "Untitled Task"
        cell.detailTextLabel?.text = "Points: \(task.points?.decimalValue ?? 0), Completed: \(task.completed)"
        return cell
    }

    // MARK: - UITableViewDelegate
    public func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        delegate?.didSelectTask(tasks[indexPath.row])
    }

    public func tableView(_ tableView: UITableView, trailingSwipeActionsConfigurationForRowAt indexPath: IndexPath) -> UISwipeActionsConfiguration? {
        let edit = UIContextualAction(style: .normal, title: "Edit") { [weak self] (_, _, completion) in
            self?.delegate?.didEditTask(self?.tasks[indexPath.row] ?? CoreDataTask())  // Handle optional safely
            completion(true)
        }
        edit.backgroundColor = UIColor.systemYellow  // Use UIColor explicitly

        let delete = UIContextualAction(style: .destructive, title: "Delete") { [weak self] (_, _, completion) in
            self?.delegate?.didDeleteTask(self?.tasks[indexPath.row] ?? CoreDataTask())
            completion(true)
        }

        let decrement = UIContextualAction(style: .normal, title: "Decrement") { [weak self] (_, _, completion) in
            self?.delegate?.didDecrementTask(self?.tasks[indexPath.row] ?? CoreDataTask())
            completion(true)
        }
        decrement.backgroundColor = UIColor.systemGreen  // Use UIColor explicitly

        let copy = UIContextualAction(style: .normal, title: "Copy") { [weak self] (_, _, completion) in
            self?.delegate?.didCopyTask(self?.tasks[indexPath.row] ?? CoreDataTask())
            completion(true)
        }
        copy.backgroundColor = UIColor.systemBlue  // Use UIColor explicitly

        return UISwipeActionsConfiguration(actions: [decrement, copy, delete, edit])
    }

    // MARK: - UITableViewDragDelegate
    public func tableView(_ tableView: UITableView, itemsForBeginning session: UIDragSession, at indexPath: IndexPath) -> [UIDragItem] {
        let task = tasks[indexPath.row]
        guard let title = task.title else { return [] }
        let itemProvider = NSItemProvider(object: title as NSString)
        return [UIDragItem(itemProvider: itemProvider)]
    }

    // MARK: - UITableViewDropDelegate
    public func tableView(_ tableView: UITableView, performDropWith coordinator: UITableViewDropCoordinator) {
        guard let dest = coordinator.destinationIndexPath else { return }
        for item in coordinator.items {
            if let src = item.sourceIndexPath {
                tableView.performBatchUpdates({
                    delegate?.didMoveTask(from: src.row, to: dest.row)
                })
            }
        }
    }

    public func tableView(_ tableView: UITableView, dropSessionDidUpdate session: UIDropSession, withDestinationIndexPath destinationIndexPath: IndexPath?) -> UITableViewDropProposal {
        UITableViewDropProposal(operation: .move, intent: .insertAtDestinationIndexPath)
    }

    public func tableView(_ tableView: UITableView, canHandle session: UIDropSession) -> Bool {
        session.localDragSession != nil
    }
}
