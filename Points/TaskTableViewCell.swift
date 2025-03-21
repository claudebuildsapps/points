import UIKit
import CoreData

protocol TaskTableViewCellDelegate: AnyObject {
    func cellDidSaveEdit(_ cell: TaskTableViewCell, task: CoreDataTask, updatedValues: [String: Any])
    func cellDidCancelEdit(_ cell: TaskTableViewCell)
    func cellDidRequestDecrement(_ cell: TaskTableViewCell, task: CoreDataTask)
    func cellDidRequestDuplicate(_ cell: TaskTableViewCell, task: CoreDataTask)
    func cellDidRequestDelete(_ cell: TaskTableViewCell, task: CoreDataTask)
}

// MARK: - TaskTableViewCell
class TaskTableViewCell: UITableViewCell {
    // MARK: - Properties
    weak var delegate: TaskTableViewCellDelegate? {
        didSet {
            // Update delegate in sub-controllers when main cell delegate changes
            editController.delegate = delegate
            swipeController.delegate = delegate
        }
    }
    
    private(set) var task: CoreDataTask?
    private(set) var isExpanded = false
    
    // Controllers
    private var editController: TaskCellEditController!
    private var swipeController: TaskCellSwipeController!
    
    // MARK: - Display Mode UI Elements
    private let displayPointsLabel: UILabel
    private let pointsTitleLabel: UILabel
    private let taskTitleLabel: UILabel
    private let completionLabel: UILabel
    private let completionTitleLabel: UILabel
    
    // New date label
    private let dateLabel: UILabel
    
    // UI elements
    private let undoButton: UIButton
    private let editButton: UIButton
    private let editButtonContainer: UIView
    private let undoButtonContainer: UIView
    
    // MARK: - Initialization
    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        // Initialize UI components using factory
        self.displayPointsLabel = TaskCellUIFactory.createDisplayPointsLabel()
        self.pointsTitleLabel = TaskCellUIFactory.createPointsTitleLabel()
        self.taskTitleLabel = TaskCellUIFactory.createTaskTitleLabel()
        self.completionLabel = TaskCellUIFactory.createCompletionLabel()
        self.completionTitleLabel = TaskCellUIFactory.createCompletionTitleLabel()
        
        // Initialize date label
        let dateLbl = UILabel()
        dateLbl.font = UIFont.systemFont(ofSize: 11, weight: .regular)
        dateLbl.textColor = .systemGray
        dateLbl.translatesAutoresizingMaskIntoConstraints = false
        self.dateLabel = dateLbl
        
        // Initialize undo button (now as an icon next to edit button)
        let undoBtn = UIButton(type: .system)
        let undoConfig = UIImage.SymbolConfiguration(pointSize: 16, weight: .medium)
        let undoImage = UIImage(systemName: "arrow.uturn.backward", withConfiguration: undoConfig)
        undoBtn.setImage(undoImage, for: .normal)
        undoBtn.tintColor = .systemGray
        undoBtn.translatesAutoresizingMaskIntoConstraints = false
        self.undoButton = undoBtn
        
        let editBtn = UIButton(type: .system)
        let config = UIImage.SymbolConfiguration(pointSize: 16, weight: .medium)
        let pencilImage = UIImage(systemName: "pencil", withConfiguration: config)
        editBtn.setImage(pencilImage, for: .normal)
        editBtn.tintColor = .systemGray
        editBtn.translatesAutoresizingMaskIntoConstraints = false
        self.editButton = editBtn
        
        let editContainer = UIView()
        editContainer.translatesAutoresizingMaskIntoConstraints = false
        editContainer.backgroundColor = .clear  // Make it invisible
        self.editButtonContainer = editContainer
        
        let undoContainer = UIView()
        undoContainer.translatesAutoresizingMaskIntoConstraints = false
        undoContainer.backgroundColor = .clear  // Make it invisible
        self.undoButtonContainer = undoContainer

        super.init(style: style, reuseIdentifier: reuseIdentifier)
        
        // Initialize controllers after super.init since they need self
        self.editController = TaskCellEditController(cell: self, delegate: delegate)
        self.swipeController = TaskCellSwipeController(cell: self, delegate: delegate)
        
        setupUI()
    }
    
    required init?(coder: NSCoder) {
        // Initialize UI components using factory
        self.displayPointsLabel = TaskCellUIFactory.createDisplayPointsLabel()
        self.pointsTitleLabel = TaskCellUIFactory.createPointsTitleLabel()
        self.taskTitleLabel = TaskCellUIFactory.createTaskTitleLabel()
        self.completionLabel = TaskCellUIFactory.createCompletionLabel()
        self.completionTitleLabel = TaskCellUIFactory.createCompletionTitleLabel()
        
        // Initialize date label
        let dateLbl = UILabel()
        dateLbl.font = UIFont.systemFont(ofSize: 11, weight: .regular)
        dateLbl.textColor = .systemGray
        dateLbl.translatesAutoresizingMaskIntoConstraints = false
        self.dateLabel = dateLbl
        
        // Initialize undo button (now as an icon next to edit button)
        let undoBtn = UIButton(type: .system)
        let undoConfig = UIImage.SymbolConfiguration(pointSize: 16, weight: .medium)
        let undoImage = UIImage(systemName: "arrow.uturn.backward", withConfiguration: undoConfig)
        undoBtn.setImage(undoImage, for: .normal)
        undoBtn.tintColor = .systemGray
        undoBtn.translatesAutoresizingMaskIntoConstraints = false
        self.undoButton = undoBtn
        
        let editBtn = UIButton(type: .system)
        let config = UIImage.SymbolConfiguration(pointSize: 16, weight: .medium)
        let pencilImage = UIImage(systemName: "pencil", withConfiguration: config)
        editBtn.setImage(pencilImage, for: .normal)
        editBtn.tintColor = .systemGray
        editBtn.translatesAutoresizingMaskIntoConstraints = false
        self.editButton = editBtn
        
        let editContainer = UIView()
        editContainer.translatesAutoresizingMaskIntoConstraints = false
        editContainer.backgroundColor = .clear  // Make it invisible
        self.editButtonContainer = editContainer
        
        let undoContainer = UIView()
        undoContainer.translatesAutoresizingMaskIntoConstraints = false
        undoContainer.backgroundColor = .clear  // Make it invisible
        self.undoButtonContainer = undoContainer
        super.init(coder: coder)
        
        // Initialize controllers after super.init since they need self
        self.editController = TaskCellEditController(cell: self, delegate: delegate)
        self.swipeController = TaskCellSwipeController(cell: self, delegate: delegate)
        
        setupUI()
    }
    
    // MARK: - UI Setup
    private func setupUI() {
        // Configure cell
        selectionStyle = .none
        backgroundColor = .systemBackground
        
        // Set up display mode UI
        setupDisplayModeUI()
        
        // Set up edit mode UI
        editController.setupEditContainer(in: contentView)
        
        // Set up swipe gestures
        swipeController.setupSwipeGestures(in: contentView)
        
        // Set up button actions
        let undoTapGesture = UITapGestureRecognizer(target: self, action: #selector(undoButtonTapped))
        undoButtonContainer.addGestureRecognizer(undoTapGesture)
        undoButtonContainer.isUserInteractionEnabled = true
        undoButton.addTarget(self, action: #selector(undoButtonTapped), for: .touchUpInside)
        
        let editTapGesture = UITapGestureRecognizer(target: self, action: #selector(editButtonTapped))
        editButtonContainer.addGestureRecognizer(editTapGesture)
        editButtonContainer.isUserInteractionEnabled = true
        editButton.addTarget(self, action: #selector(editButtonTapped), for: .touchUpInside)
    }
    
    private func setupDisplayModeUI() {
        // Add display mode elements
        contentView.addSubview(displayPointsLabel)
        contentView.addSubview(pointsTitleLabel)
        contentView.addSubview(taskTitleLabel)
        contentView.addSubview(dateLabel)
        contentView.addSubview(completionLabel)
        contentView.addSubview(completionTitleLabel)
        contentView.addSubview(undoButton)
        contentView.addSubview(editButton)
        contentView.addSubview(editButtonContainer)
        contentView.addSubview(undoButtonContainer)
        contentView.bringSubviewToFront(editButton)
        contentView.bringSubviewToFront(undoButton)

        // Setup constraints for normal state
        NSLayoutConstraint.activate([
            // Points title below points
            pointsTitleLabel.centerXAnchor.constraint(equalTo: displayPointsLabel.centerXAnchor),
            pointsTitleLabel.topAnchor.constraint(equalTo: displayPointsLabel.bottomAnchor, constant: -2),
            pointsTitleLabel.widthAnchor.constraint(equalToConstant: 50),
            
            // Edit button container - make it a dedicated tap area for edit button
            editButtonContainer.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
            editButtonContainer.topAnchor.constraint(equalTo: contentView.topAnchor),
            editButtonContainer.bottomAnchor.constraint(equalTo: contentView.bottomAnchor),
            editButtonContainer.widthAnchor.constraint(equalToConstant: 45), // Just enough for the edit button
            
            // Undo button container - dedicated tap area for undo
            undoButtonContainer.leadingAnchor.constraint(equalTo: editButtonContainer.trailingAnchor),
            undoButtonContainer.topAnchor.constraint(equalTo: contentView.topAnchor),
            undoButtonContainer.bottomAnchor.constraint(equalTo: contentView.bottomAnchor),
            undoButtonContainer.widthAnchor.constraint(equalToConstant: 45), // Just enough for the undo button
            
            // Edit button (pencil icon) positioned in its container
            editButton.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 12),
            editButton.centerYAnchor.constraint(equalTo: contentView.centerYAnchor),
            editButton.widthAnchor.constraint(equalToConstant: 30),
            editButton.heightAnchor.constraint(equalToConstant: 30),
            
            // Undo button right next to edit button
            undoButton.leadingAnchor.constraint(equalTo: editButton.trailingAnchor, constant: 5),
            undoButton.centerYAnchor.constraint(equalTo: contentView.centerYAnchor),
            undoButton.widthAnchor.constraint(equalToConstant: 30),
            undoButton.heightAnchor.constraint(equalToConstant: 30),
            
            // Points label (left side)
            displayPointsLabel.leadingAnchor.constraint(equalTo: undoButtonContainer.trailingAnchor, constant: 0),
            displayPointsLabel.centerYAnchor.constraint(equalTo: contentView.centerYAnchor, constant: -4),
            displayPointsLabel.widthAnchor.constraint(equalToConstant: 50),
            
            // Title label (center)
            taskTitleLabel.leadingAnchor.constraint(equalTo: displayPointsLabel.trailingAnchor, constant: 8),
            taskTitleLabel.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 12),
            
            // Date label below title
            dateLabel.leadingAnchor.constraint(equalTo: taskTitleLabel.leadingAnchor),
            dateLabel.topAnchor.constraint(equalTo: taskTitleLabel.bottomAnchor, constant: 2),
            dateLabel.bottomAnchor.constraint(lessThanOrEqualTo: contentView.bottomAnchor, constant: -12),
            
            // Completion label (right side)
            completionLabel.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16),
            completionLabel.centerYAnchor.constraint(equalTo: contentView.centerYAnchor, constant: -4),
            completionLabel.widthAnchor.constraint(equalToConstant: 45),
            
            // Completion title below completion
            completionTitleLabel.centerXAnchor.constraint(equalTo: completionLabel.centerXAnchor),
            completionTitleLabel.topAnchor.constraint(equalTo: completionLabel.bottomAnchor, constant: -2),
            completionTitleLabel.widthAnchor.constraint(equalToConstant: 45),
            
            // Make title label fill remaining space
            taskTitleLabel.trailingAnchor.constraint(equalTo: completionLabel.leadingAnchor, constant: -8),
            
            // Make date label fill the same horizontal space as title
            dateLabel.trailingAnchor.constraint(equalTo: taskTitleLabel.trailingAnchor)
        ])
    }
    
    // MARK: - Button Actions
    @objc private func undoButtonTapped() {
        guard let task = task else { return }
        delegate?.cellDidRequestDecrement(self, task: task)
    }
    
    private var isEditMode = false

    @objc private func editButtonTapped() {
        isEditMode = !isEditMode
        
        if isEditMode {
            // Entering edit mode - turn button yellow
            editButton.tintColor = .systemYellow
            toggleExpandedState(expanded: true)
        } else {
            // Exiting edit mode - return to normal color
            editButton.tintColor = .systemGray
            toggleExpandedState(expanded: false)
            
            // Notify delegate of cancel if needed
            if let task = task {
                delegate?.cellDidCancelEdit(self)
            }
        }
    }
    
    // MARK: - Configuration
    func configure(with task: CoreDataTask) {
        self.task = task
        
        // Set label text
        taskTitleLabel.text = task.title
        
        // Format points with decimal places
        let pointsValue = task.points?.doubleValue ?? 0
        displayPointsLabel.text = String(format: "%.1f", pointsValue)
        
        // Show completion progress: completed/target
        let completedValue = Int(task.completed)
        let targetValue = Int(task.target)
        completionLabel.text = "\(completedValue)/\(targetValue)"
        
        // Configure date label
        configureDateLabel(for: task)
        
        // Update cell background color based on completion progress
        updateBackgroundColor(completed: completedValue, target: targetValue)
        
        // Configure edit controller
        editController.configure(with: task)
        
        // Configure swipe controller
        swipeController.configure(with: task)
    }
    
    // Since we don't need to show full date on each cell (as DateNavigationView handles this),
    // we can just show other metadata if available
    private func configureDateLabel(for task: CoreDataTask) {
        guard let date = task.date else {
            dateLabel.text = "No date"
            return
        }
        
        // Format the date
        let dateFormatter = DateFormatter()
        dateFormatter.dateStyle = .medium
        dateFormatter.timeStyle = .none
        
        if let dateValue = date.date {
            dateLabel.text = dateFormatter.string(from: dateValue)
        } else {
            dateLabel.text = "No date"
        }
    }
    // MARK: - Progressive Green Background
    private func updateBackgroundColor(completed: Int, target: Int) {
        if completed >= target {
            // Fully completed - use final green shade
            contentView.backgroundColor = UIColor.systemGreen.withAlphaComponent(0.2)
            completionLabel.textColor = .systemGreen
        } else if completed > 0 {
            // Calculate progress percentage
            let progress = CGFloat(completed) / CGFloat(target)
            
            // Use progressively darker green (0.03 to 0.18 alpha)
            let alpha = 0.03 + (progress * 0.15)
            contentView.backgroundColor = UIColor.systemGreen.withAlphaComponent(alpha)
            completionLabel.textColor = .systemBlue
        } else {
            // Not started (0/target)
            contentView.backgroundColor = .clear
            completionLabel.textColor = .systemBlue
        }
    }
    
    // MARK: - Animation and Expansion
    func toggleExpandedState(expanded: Bool, animated: Bool = true) {
        isExpanded = expanded
        isEditMode = expanded
        
        // Update button color to match state
        editButton.tintColor = expanded ? .systemYellow : .systemGray
        
        // Tell the edit controller to handle its UI state
        editController.toggleExpandedState(expanded: expanded, animated: animated)
        
        // Notify the table view to update this cell's height
        if let tableView = self.superview as? UITableView {
            if animated {
                UIView.animate(withDuration: 0.3) {
                    tableView.beginUpdates()
                    tableView.endUpdates()
                }
            } else {
                tableView.beginUpdates()
                tableView.endUpdates()
            }
        }
    }
    
    func handleCancelEdit() {
        // Just reset the pencil color to gray
        isEditMode = false
        editButton.tintColor = .systemGray
    }

    
    // Animation methods for completion changes
    func animateFirstCompletion() {
        if let task = task, task.completed == 1 {
            animateIncrementedCompletion(previousCompleted: 0)
        }
    }
    
    // Enhance completion animation
    func animateIncrementedCompletion(previousCompleted: Int) {
        guard let task = task else { return }
        let completedValue = Int(task.completed)
        let targetValue = Int(task.target)
        
        if completedValue > previousCompleted {
            // Flash a brighter green briefly
            UIView.animate(withDuration: 0.2, animations: {
                let flashAlpha = UIColor.systemGreen.withAlphaComponent(0.35)
                self.contentView.backgroundColor = flashAlpha
            }) { _ in
                UIView.animate(withDuration: 0.3) {
                    // Then settle to the appropriate shade
                    self.updateBackgroundColor(completed: completedValue, target: targetValue)
                }
            }
        }
    }
    
    // MARK: - Cell Reuse
    override func prepareForReuse() {
        super.prepareForReuse()
        
        taskTitleLabel.text = nil
        displayPointsLabel.text = nil
        completionLabel.text = nil
        dateLabel.text = nil
        task = nil
        contentView.backgroundColor = .clear
        
        // Reset expanded state
        if isExpanded {
            toggleExpandedState(expanded: false, animated: false)
        }
        
        // Reset controllers
        editController.prepareForReuse()
        swipeController.prepareForReuse()
        
        isEditMode = false
        editButton.tintColor = .systemGray
    }
    
    private func updateCellHeight() {
        // This tells the table view to recalculate the cell height
        if let tableView = self.superview as? UITableView {
            tableView.beginUpdates()
            tableView.endUpdates()
        }
    }
    
    func resetAfterEditCancel() {
        // Reset internal state
        isEditMode = false
        isExpanded = false
        
        // Reset UI
        editButton.tintColor = .systemGray
        completionLabel.isUserInteractionEnabled = true
        undoButton.isUserInteractionEnabled = true
        
        // Force layout update
        if let tableView = self.superview as? UITableView {
            tableView.beginUpdates()
            tableView.endUpdates()
        }
    }
}
