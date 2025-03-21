import UIKit
import CoreData

protocol TaskTableViewManagerDelegate: AnyObject {
    func didSelectTask(_ task: CoreDataTask)
    func didEditTask(_ task: CoreDataTask)
    func didDeleteTask(_ task: CoreDataTask)
    func didDecrementTask(_ task: CoreDataTask)
    func didCopyTask(_ task: CoreDataTask)
    func didMoveTask(from: Int, to: Int)
    func didSaveEdit(_ cell: TaskTableViewCell, task: CoreDataTask, updatedTask: CoreDataTask)
}

class TaskTableViewManager: NSObject, UITableViewDelegate, UITableViewDataSource, TaskTableViewCellDelegate {
    private weak var tableView: UITableView?
    private weak var delegate: TaskTableViewManagerDelegate?
    private var tasks: [CoreDataTask] = []
    private var previousCompletionValues: [ObjectIdentifier: Int] = [:]
    private var expandedCellIndexPath: IndexPath?
    
    init(tableView: UITableView, delegate: TaskTableViewManagerDelegate) {
        super.init()
        self.tableView = tableView
        self.delegate = delegate
        
        // Configure the table view
        tableView.delegate = self
        tableView.dataSource = self
        tableView.register(TaskTableViewCell.self, forCellReuseIdentifier: "TaskCell")
        
        // Enable editing and reordering with improved drag speed
        tableView.isEditing = false
        tableView.allowsSelection = true
        tableView.separatorStyle = .singleLine
        tableView.rowHeight = UITableView.automaticDimension
        tableView.estimatedRowHeight = 60
        
        // Improve drag and drop performance
        configureFastDragAndDrop(for: tableView)
    }
    
    private func configureFastDragAndDrop(for tableView: UITableView) {
        // Configure faster drag and drop animations
        if #available(iOS 11.0, *) {
            tableView.dragInteractionEnabled = true
            tableView.dragDelegate = self
            tableView.dropDelegate = self
            
            // Set the dragging delay to minimum
            if let longPressRecognizer = tableView.gestureRecognizers?.first(where: { $0 is UILongPressGestureRecognizer }) as? UILongPressGestureRecognizer {
                longPressRecognizer.minimumPressDuration = 0.2 // Reduce long press time to initiate drag
            }
        }
    }
    
    func updateTasks(_ tasks: [CoreDataTask]) {
        // Store previous completion values before updating
        storeCompletionValues()
        self.tasks = tasks
        tableView?.reloadData()
    }
    
    private func storeCompletionValues() {
        // Store current completion values to compare after update
        previousCompletionValues.removeAll()
        for task in tasks {
            if let id = task.objectID as? NSManagedObjectID {
                let identifier = ObjectIdentifier(id)
                previousCompletionValues[identifier] = Int(task.completed)
            }
        }
    }
    
    // MARK: - UITableViewDataSource
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return tasks.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let cell = tableView.dequeueReusableCell(withIdentifier: "TaskCell", for: indexPath) as? TaskTableViewCell else {
            return UITableViewCell()
        }
        
        let task = tasks[indexPath.row]
        cell.delegate = self
        cell.configure(with: task)
        
        // Restore expanded state if needed
        if expandedCellIndexPath == indexPath {
            cell.toggleExpandedState(expanded: true, animated: false)
        }
        
        // Animate if completion changed
        if let id = task.objectID as? NSManagedObjectID {
            let identifier = ObjectIdentifier(id)
            if let previousValue = previousCompletionValues[identifier],
               previousValue != Int(task.completed) {
                cell.animateIncrementedCompletion(previousCompleted: previousValue)
            }
        }
        
        return cell
    }
    
    // MARK: - UITableViewDelegate
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        // Get cell and check if it's expanded
        if let cell = tableView.cellForRow(at: indexPath) as? TaskTableViewCell, cell.isExpanded {
            // Normal height + edit UI height
            return 60 + 350 // Adjust the edit UI height as needed
        }
        
        return 60 // Your fixed normal cell height
    }
    		
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        
        // Skip selection handling if we're editing this or any cell
        if expandedCellIndexPath != nil {
            return
        }
        
        let task = tasks[indexPath.row]
        delegate?.didSelectTask(task)
    }
    
    // Removed trailingSwipeActionsConfigurationForRowAt and leadingSwipeActionsConfigurationForRowAt
    
    // MARK: - Fast Reordering Support
    func tableView(_ tableView: UITableView, canMoveRowAt indexPath: IndexPath) -> Bool {
        // Don't allow moving expanded cells
        return indexPath != expandedCellIndexPath
    }
    
    func tableView(_ tableView: UITableView, moveRowAt sourceIndexPath: IndexPath, to destinationIndexPath: IndexPath) {
        delegate?.didMoveTask(from: sourceIndexPath.row, to: destinationIndexPath.row)
    }
    
    // MARK: - TaskTableViewCellDelegate
    func cellDidRequestDecrement(_ cell: TaskTableViewCell, task: CoreDataTask) {
        guard let index = tasks.firstIndex(of: task), task.completed > 0 else { return }
        delegate?.didDecrementTask(tasks[index])
    }
    
    func cellDidSaveEdit(_ cell: TaskTableViewCell, task: CoreDataTask, updatedValues: [String: Any]) {
        // Update task using KVC (Key-Value Coding) which is safe for Core Data
        if let title = updatedValues["title"] as? String {
            task.setValue(title, forKey: "title")
        }
        
        if let points = updatedValues["points"] as? NSDecimalNumber {
            task.setValue(points, forKey: "points")
        }
        
        if let target = updatedValues["target"] as? Int16 {
            task.setValue(target, forKey: "target")
        }
        
        // Save context
        do {
            try task.managedObjectContext?.save()
            tableView?.reloadData()
        } catch {
            print("Error saving context: \(error)")
        }
    }

    func cellDidCancelEdit(_ cell: TaskTableViewCell) {
        // Clear the expanded cell reference
        if let indexPath = tableView?.indexPath(for: cell) {
            expandedCellIndexPath = nil
            
            // Update the table view to accommodate the collapsed cell
            tableView?.beginUpdates()
            tableView?.endUpdates()
        }
    }
    
    func cellDidRequestDuplicate(_ cell: TaskTableViewCell, task: CoreDataTask) {
        // Implement the duplicate functionality
        delegate?.didCopyTask(task)
    }
    
    func cellDidRequestDelete(_ cell: TaskTableViewCell, task: CoreDataTask) {
        // Implement the delete functionality
        delegate?.didDeleteTask(task)
        
        // If we're deleting an expanded cell, clear the reference
        if let indexPath = tableView?.indexPath(for: cell), indexPath == expandedCellIndexPath {
            expandedCellIndexPath = nil
        }
    }
}

// MARK: - Drag and Drop Support (iOS 11+)
@available(iOS 11.0, *)
extension TaskTableViewManager: UITableViewDragDelegate, UITableViewDropDelegate {
    // MARK: - Drag Support
    func tableView(_ tableView: UITableView, itemsForBeginning session: UIDragSession, at indexPath: IndexPath) -> [UIDragItem] {
        // Don't allow dragging expanded cells
        if indexPath == expandedCellIndexPath {
            return []
        }
        
        let task = tasks[indexPath.row]
        guard let title = task.title else { return [] }
        
        let itemProvider = NSItemProvider(object: title as NSString)
        let dragItem = UIDragItem(itemProvider: itemProvider)
        dragItem.localObject = task
        
        // Set a smaller preview for faster rendering
        if let cell = tableView.cellForRow(at: indexPath) {
            let previewParameters = UIDragPreviewParameters()
            previewParameters.backgroundColor = .clear
            dragItem.previewProvider = {
                return UIDragPreview(view: cell, parameters: previewParameters)
            }
        }
        
        return [dragItem]
    }
    
    func tableView(_ tableView: UITableView, dragSessionWillBegin session: UIDragSession) {
        // Optimize UI for drag session
        UIView.animate(withDuration: 0.2) {
            tableView.isEditing = true
        }
    }
    
    func tableView(_ tableView: UITableView, dragSessionDidEnd session: UIDragSession) {
        // Restore UI after drag session
        UIView.animate(withDuration: 0.2) {
            tableView.isEditing = false
        }
    }
    
    // MARK: - Drop Support
    func tableView(_ tableView: UITableView, performDropWith coordinator: UITableViewDropCoordinator) {
        guard let destinationIndexPath = coordinator.destinationIndexPath else { return }
        
        // Don't allow dropping onto expanded cells
        if destinationIndexPath == expandedCellIndexPath {
            return
        }
        
        // Handle internal reordering
        if coordinator.proposal.operation == .move {
            // Get source index path
            guard let sourceItem = coordinator.items.first,
                  let sourceIndexPath = coordinator.items.first?.sourceIndexPath else { return }
            
            tableView.performBatchUpdates({
                // Update data model
                delegate?.didMoveTask(from: sourceIndexPath.row, to: destinationIndexPath.row)
                
                // Update the table view with animation
                tableView.moveRow(at: sourceIndexPath, to: destinationIndexPath)
            }, completion: { _ in
                // Complete the drop with fast animation
                coordinator.drop(sourceItem.dragItem, toRowAt: destinationIndexPath)
            })
        }
    }
    
    func tableView(_ tableView: UITableView, dropSessionDidUpdate session: UIDropSession, withDestinationIndexPath destinationIndexPath: IndexPath?) -> UITableViewDropProposal {
        // Don't allow dropping onto expanded cells
        if let destinationPath = destinationIndexPath, destinationPath == expandedCellIndexPath {
            return UITableViewDropProposal(operation: .cancel)
        }
        
        // Allow moving items within this table view with fast animation
        return UITableViewDropProposal(operation: .move, intent: .insertAtDestinationIndexPath)
    }
}

// Extension to access pan gesture recognizer name
extension UITableView {
    static var panGestureRecognizerName: String {
        return "_UITableViewCellActionPanGestureRecognizer"
    }
}
