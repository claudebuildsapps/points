import UIKit
import CoreData
import SnapKit

// MARK: - TaskCellEditController
class TaskCellEditController: NSObject {
    // MARK: - Properties
    weak var delegate: TaskTableViewCellDelegate?
    private weak var cell: TaskTableViewCell?
    private var task: CoreDataTask?
    
    // UI Elements
    private let editContainer: UIView
    private var titleField: UITextField!
    private var pointsField: UITextField!
    private var targetField: UITextField!
    private var rewardField: UITextField!
    private var maxField: UITextField!
    private var routineSwitch: UISwitch!
    private var optionalSwitch: UISwitch!
    
    // MARK: - Initialization
    init(cell: TaskTableViewCell, delegate: TaskTableViewCellDelegate?) {
        self.editContainer = TaskCellUIFactory.createEditContainer()
        
        super.init()
        
        self.cell = cell
        self.delegate = delegate
    }
    
    // MARK: - Setup
    func setupEditContainer(in contentView: UIView) {
        // Add edit container to the content view
        contentView.addSubview(editContainer)
        
        // Use SnapKit to position the edit container to cover the entire cell
        editContainer.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }
        
        // Initially set the edit interface to be invisible
        editContainer.alpha = 0
        
        // Set up the edit controls
        setupEditControls()
    }
    
    private func setupKeyboardObservers() {
        // Register for keyboard notifications
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(keyboardWillShow),
            name: UIResponder.keyboardWillShowNotification,
            object: nil
        )
        
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(keyboardWillHide),
            name: UIResponder.keyboardWillHideNotification,
            object: nil
        )
    }

    private func setupEditControls() {
        // Create UI elements
        let titleContainer = TaskCellUIFactory.createFieldContainer()
        let titleLabel = TaskCellUIFactory.createFieldLabel(title: "Task")
        titleField = TaskCellUIFactory.createTextField()
        
        let pointsContainer = TaskCellUIFactory.createFieldContainer()
        let pointsLabel = TaskCellUIFactory.createFieldLabel(title: "Points")
        pointsField = TaskCellUIFactory.createTextField(keyboardType: .decimalPad, textColor: .systemGreen)
        
        let targetContainer = TaskCellUIFactory.createFieldContainer()
        let targetLabel = TaskCellUIFactory.createFieldLabel(title: "Target")
        targetField = TaskCellUIFactory.createTextField(keyboardType: .numberPad, textColor: .systemBlue)
        
        let rewardContainer = TaskCellUIFactory.createFieldContainer()
        let rewardLabel = TaskCellUIFactory.createFieldLabel(title: "Reward")
        rewardField = TaskCellUIFactory.createTextField(keyboardType: .decimalPad, textColor: .systemGreen)
        
        let maxContainer = TaskCellUIFactory.createFieldContainer()
        let maxLabel = TaskCellUIFactory.createFieldLabel(title: "Max")
        maxField = TaskCellUIFactory.createTextField(keyboardType: .numberPad, textColor: .systemBlue)
        
        // Create switches with smaller size
        let routineContainer = TaskCellUIFactory.createFieldContainer()
        let routineLabel = TaskCellUIFactory.createFieldLabel(title: "Routine")
        routineSwitch = UISwitch()
        routineSwitch.translatesAutoresizingMaskIntoConstraints = false
        routineSwitch.onTintColor = .systemGreen
        routineSwitch.transform = CGAffineTransform(scaleX: 0.75, y: 0.75)
        
        let optionalContainer = TaskCellUIFactory.createFieldContainer()
        let optionalLabel = TaskCellUIFactory.createFieldLabel(title: "Optional")
        optionalSwitch = UISwitch()
        optionalSwitch.translatesAutoresizingMaskIntoConstraints = false
        optionalSwitch.onTintColor = .systemBlue
        optionalSwitch.transform = CGAffineTransform(scaleX: 0.75, y: 0.75)
        
        // Add all elements to the view hierarchy
        editContainer.addSubview(titleContainer)
        titleContainer.addSubview(titleLabel)
        titleContainer.addSubview(titleField)
        
        editContainer.addSubview(pointsContainer)
        pointsContainer.addSubview(pointsLabel)
        pointsContainer.addSubview(pointsField)
        
        editContainer.addSubview(targetContainer)
        targetContainer.addSubview(targetLabel)
        targetContainer.addSubview(targetField)
        
        editContainer.addSubview(rewardContainer)
        rewardContainer.addSubview(rewardLabel)
        rewardContainer.addSubview(rewardField)
        
        editContainer.addSubview(maxContainer)
        maxContainer.addSubview(maxLabel)
        maxContainer.addSubview(maxField)
        
        editContainer.addSubview(routineContainer)
        routineContainer.addSubview(routineLabel)
        routineContainer.addSubview(routineSwitch)
        
        editContainer.addSubview(optionalContainer)
        optionalContainer.addSubview(optionalLabel)
        optionalContainer.addSubview(optionalSwitch)
        
        // Use SnapKit for all layout constraints
        
        // Title container
        titleContainer.snp.makeConstraints { make in
            make.top.equalToSuperview().offset(8)
            make.left.equalToSuperview().offset(8)
            make.right.equalToSuperview().offset(-8)
            make.height.equalTo(70)
        }
        
        titleLabel.snp.makeConstraints { make in
            make.top.equalToSuperview().offset(8)
            make.left.equalToSuperview().offset(8)
            make.right.equalToSuperview().offset(-8)
        }
        
        titleField.snp.makeConstraints { make in
            make.top.equalTo(titleLabel.snp.bottom).offset(4)
            make.left.equalToSuperview().offset(8)
            make.right.equalToSuperview().offset(-8)
            make.height.equalTo(36)
        }
        
        // First row: Points and Target
        pointsContainer.snp.makeConstraints { make in
            make.top.equalTo(titleContainer.snp.bottom).offset(8)
            make.left.equalToSuperview().offset(8)
            make.width.equalToSuperview().multipliedBy(0.47)
            make.height.equalTo(70)
        }
        
        targetContainer.snp.makeConstraints { make in
            make.top.equalTo(titleContainer.snp.bottom).offset(8)
            make.right.equalToSuperview().offset(-8)
            make.width.equalToSuperview().multipliedBy(0.47)
            make.height.equalTo(70)
        }
        
        // Second row: Reward and Max
        rewardContainer.snp.makeConstraints { make in
            make.top.equalTo(pointsContainer.snp.bottom).offset(8)
            make.left.equalToSuperview().offset(8)
            make.width.equalToSuperview().multipliedBy(0.47)
            make.height.equalTo(70)
        }
        
        maxContainer.snp.makeConstraints { make in
            make.top.equalTo(targetContainer.snp.bottom).offset(8)
            make.right.equalToSuperview().offset(-8)
            make.width.equalToSuperview().multipliedBy(0.47)
            make.height.equalTo(70)
        }
        
        // Third row: Routine and Optional (smaller height)
        routineContainer.snp.makeConstraints { make in
            make.top.equalTo(rewardContainer.snp.bottom).offset(8)
            make.left.equalToSuperview().offset(8)
            make.width.equalToSuperview().multipliedBy(0.47)
            make.height.equalTo(36) // Reduced height since label and switch are on same line
            make.bottom.lessThanOrEqualToSuperview().offset(-12)
        }
        
        optionalContainer.snp.makeConstraints { make in
            make.top.equalTo(maxContainer.snp.bottom).offset(8)
            make.right.equalToSuperview().offset(-8)
            make.width.equalToSuperview().multipliedBy(0.47)
            make.height.equalTo(36) // Reduced height since label and switch are on same line
            make.bottom.lessThanOrEqualToSuperview().offset(-12)
        }

        // Interior layout for each field container
        // Points
        pointsLabel.snp.makeConstraints { make in
            make.top.equalToSuperview().offset(8)
            make.left.equalToSuperview().offset(8)
            make.right.equalToSuperview().offset(-8)
        }
        
        pointsField.snp.makeConstraints { make in
            make.top.equalTo(pointsLabel.snp.bottom).offset(4)
            make.left.equalToSuperview().offset(8)
            make.right.equalToSuperview().offset(-8)
            make.height.equalTo(36)
        }
        
        // Target
        targetLabel.snp.makeConstraints { make in
            make.top.equalToSuperview().offset(8)
            make.left.equalToSuperview().offset(8)
            make.right.equalToSuperview().offset(-8)
        }
        
        targetField.snp.makeConstraints { make in
            make.top.equalTo(targetLabel.snp.bottom).offset(4)
            make.left.equalToSuperview().offset(8)
            make.right.equalToSuperview().offset(-8)
            make.height.equalTo(36)
        }
        
        // Reward
        rewardLabel.snp.makeConstraints { make in
            make.top.equalToSuperview().offset(8)
            make.left.equalToSuperview().offset(8)
            make.right.equalToSuperview().offset(-8)
        }
        
        rewardField.snp.makeConstraints { make in
            make.top.equalTo(rewardLabel.snp.bottom).offset(4)
            make.left.equalToSuperview().offset(8)
            make.right.equalToSuperview().offset(-8)
            make.height.equalTo(36)
        }
        
        // Max
        maxLabel.snp.makeConstraints { make in
            make.top.equalToSuperview().offset(8)
            make.left.equalToSuperview().offset(8)
            make.right.equalToSuperview().offset(-8)
        }
        
        maxField.snp.makeConstraints { make in
            make.top.equalTo(maxLabel.snp.bottom).offset(4)
            make.left.equalToSuperview().offset(8)
            make.right.equalToSuperview().offset(-8)
            make.height.equalTo(36)
        }
        
        // Routine
        routineLabel.snp.makeConstraints { make in
            make.centerY.equalToSuperview()
            make.left.equalToSuperview().offset(8)
        }
        
        routineSwitch.snp.makeConstraints { make in
            make.centerY.equalToSuperview()
            make.right.equalToSuperview().offset(-8)
        }
        
        // Optional - updated to position label and switch on the same line
        optionalLabel.snp.makeConstraints { make in
            make.centerY.equalToSuperview()
            make.left.equalToSuperview().offset(8)
        }
        
        optionalSwitch.snp.makeConstraints { make in
            make.centerY.equalToSuperview()
            make.right.equalToSuperview().offset(-8)
        }

        // Set up field delegates for navigation between fields
        setupTextFieldDelegates()

        // Apply enhanced input accessory view to all text fields
        applyAccessoryViewToAllTextFields()

        // Set up keyboard observers to handle scrolling
        setupKeyboardObservers()
    }

    // MARK: - Configuration
    func configure(with task: CoreDataTask) {
        self.task = task
    }
    
    // MARK: - Animation and Expansion
    func toggleExpandedState(expanded: Bool, animated: Bool = true) {
        if expanded {
            // Prepare fields for editing
            if let task = task {
                titleField.text = task.title
                
                // Set default values if nil, otherwise use existing values
                if let points = task.points?.stringValue, !points.isEmpty {
                    pointsField.text = points
                } else {
                    pointsField.text = "5.0" // Default points value
                }
                
                // Default target is 3
                let targetValue = task.target > 0 ? task.target : 3
                targetField.text = "\(targetValue)"
                
                // Default reward is 2
                if let reward = task.reward?.stringValue, !reward.isEmpty {
                    rewardField.text = reward
                } else {
                    rewardField.text = "2.0" // Default reward value
                }
                
                // Default max is target or 3, whichever is greater
                let maxValue = max(task.max, targetValue)
                maxField.text = "\(maxValue)"
                
                // Set switch values
                routineSwitch.isOn = task.routine
                optionalSwitch.isOn = task.optional
                
                // Add listeners after slight delay to avoid immediate triggers
                DispatchQueue.main.async {
                    // Add target value change listener to update max if needed
                    self.targetField.addTarget(self, action: #selector(self.targetValueChanged), for: .editingChanged)
                    // Add max value change listener
                    self.maxField.addTarget(self, action: #selector(self.maxValueChanged), for: .editingChanged)
                }
            } else {
                // Set defaults for new tasks
                titleField.text = ""
                pointsField.text = "5.0"
                targetField.text = "3"
                rewardField.text = "2.0"
                maxField.text = "3"
                routineSwitch.isOn = false
                optionalSwitch.isOn = false
                
                // Add listeners after slight delay to avoid immediate triggers
                DispatchQueue.main.async {
                    // Add target value change listener
                    self.targetField.addTarget(self, action: #selector(self.targetValueChanged), for: .editingChanged)
                    // Add max value change listener
                    self.maxField.addTarget(self, action: #selector(self.maxValueChanged), for: .editingChanged)
                }
            }
            
            // Add tap gesture to dismiss keyboard when tapping outside text fields
            addKeyboardDismissGesture()
            
            // Make sure the container is fully sized to hold the controls
            editContainer.layoutIfNeeded()
            
            // Show the edit interface
            if animated {
                UIView.animate(withDuration: 0.3) {
                    self.editContainer.alpha = 1
                } completion: { _ in
                    // Maintain auto-focus behavior as preferred
                    self.titleField.becomeFirstResponder()
                }
            } else {
                editContainer.alpha = 1
                titleField.becomeFirstResponder()
            }
        } else {
            // Remove keyboard dismiss gesture
            removeKeyboardDismissGesture()
            
            // Hide the edit interface
            if animated {
                UIView.animate(withDuration: 0.3) {
                    self.editContainer.alpha = 0
                } completion: { _ in
                    self.resetFields()
                }
            } else {
                editContainer.alpha = 0
                resetFields()
            }
            
            // Dismiss keyboard
            dismissKeyboard()
        }
    }

    // Add a method to dismiss the keyboard
    @objc private func dismissKeyboard() {
        titleField.resignFirstResponder()
        pointsField.resignFirstResponder()
        targetField.resignFirstResponder()
        rewardField.resignFirstResponder()
        maxField.resignFirstResponder()
    }

    // MARK: - Button Actions
    @objc private func targetValueChanged() {
        // When target changes, ensure max is at least equal to target
        if let targetText = targetField.text, let targetValue = Int16(targetText) {
            // Get current max value
            if let maxText = maxField.text, let maxValue = Int16(maxText) {
                // If max is less than target, update max to match target
                if maxValue < targetValue {
                    maxField.text = "\(targetValue)"
                }
            } else {
                // If max is empty or invalid, set it to target
                maxField.text = "\(targetValue)"
            }
        }
    }
    
    @objc private func maxValueChanged() {
        // When max changes, ensure it's not less than target
        if let maxText = maxField.text, let maxValue = Int16(maxText) {
            if let targetText = targetField.text, let targetValue = Int16(targetText) {
                // If max is set below target, update max to match target
                if maxValue < targetValue {
                    maxField.text = "\(targetValue)"
                }
            }
        }
    }
    
    @objc func saveButtonTapped() {
        guard let task = task, let cell = cell as? TaskTableViewCell else { return }
        
        // Get target value for max validation
        let targetValue = Int16(targetField.text ?? "3") ?? 3
        
        // Get max value and ensure it's at least equal to target
        var maxValue = Int16(maxField.text ?? "3") ?? 3
        if maxValue < targetValue {
            maxValue = targetValue
        }
        
        // Store the values we need to save
        let updatedValues: [String: Any] = [
            "title": titleField.text ?? "",
            "points": NSDecimalNumber(string: pointsField.text ?? "5.0"),
            "target": targetValue,
            "reward": NSDecimalNumber(string: rewardField.text ?? "2.0"),
            "max": maxValue,
            "routine": routineSwitch.isOn,
            "optional": optionalSwitch.isOn
        ]
        
        // Use the EXACT same code as cancelButtonTapped for animations
        // First, notify delegate of cancellation (but don't actually cancel)
        delegate?.cellDidCancelEdit(cell)
        
        // Hide the edit container
        toggleExpandedState(expanded: false)
        
        // Tell the cell to reset itself
        cell.resetAfterEditCancel()
        
        // AFTER animations are complete, then actually save the data
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            self.delegate?.cellDidSaveEdit(cell, task: task, updatedValues: updatedValues)
        }
    }
    
    @objc func cancelButtonTapped() {
        guard let cell = cell as? TaskTableViewCell else { return }
        
        // First, notify delegate of cancellation
        delegate?.cellDidCancelEdit(cell)
        
        // Hide the edit container
        toggleExpandedState(expanded: false)
        
        // Tell the cell to reset itself
        cell.resetAfterEditCancel()
    }

    // MARK: - Cleanup
    func prepareForReuse() {
        // Remove target field listener
        targetField.removeTarget(self, action: #selector(targetValueChanged), for: .editingChanged)
        maxField.removeTarget(self, action: #selector(maxValueChanged), for: .editingChanged)
        
        task = nil
        titleField.text = nil
        pointsField.text = nil
        targetField.text = nil
        rewardField.text = nil
        maxField.text = nil
        routineSwitch.isOn = false
        optionalSwitch.isOn = false
    }
    
    private func resetFields() {
        // Remove target field listener
        targetField.removeTarget(self, action: #selector(targetValueChanged), for: .editingChanged)
        maxField.removeTarget(self, action: #selector(maxValueChanged), for: .editingChanged)
        
        titleField.text = nil
        pointsField.text = nil
        targetField.text = nil
        rewardField.text = nil
        maxField.text = nil
        routineSwitch.isOn = false
        optionalSwitch.isOn = false
    }
    
    @objc private func keyboardWillShow(notification: NSNotification) {
        guard let keyboardFrame = notification.userInfo?[UIResponder.keyboardFrameEndUserInfoKey] as? CGRect,
              let cell = self.cell else {
            return
        }
        
        // Find the parent tableView
        var tableView: UITableView?
        var currentView: UIView? = cell
        
        while currentView != nil && tableView == nil {
            currentView = currentView?.superview
            if let foundTableView = currentView as? UITableView {
                tableView = foundTableView
            }
        }
        
        guard let tableView = tableView else { return }
        
        // Calculate the edit container's global frame
        guard let containerGlobalFrame = editContainer.superview?.convert(editContainer.frame, to: nil) else {
            return
        }
        
        // Calculate the cell's global frame
        guard let cellGlobalFrame = cell.superview?.convert(cell.frame, to: nil) else {
            return
        }
        
        // Calculate which part of the edit container is below the keyboard
        let bottomOfVisibleArea = keyboardFrame.origin.y
        let bottomOfEditContainer = containerGlobalFrame.origin.y + containerGlobalFrame.size.height
        
        // Calculate the overlap
        let overlapHeight = max(0, bottomOfEditContainer - bottomOfVisibleArea)
        
        if overlapHeight > 0 {
            // We need to scroll to make the entire edit area visible
            let cellPositionInTable = tableView.convert(cell.frame.origin, from: cell.superview)
            
            // Calculate new offset that will show the entire edit container
            let newOffset = cellPositionInTable.y - (tableView.contentInset.top + 20) + overlapHeight
            
            // Adjust the table's content offset to make the cell's edit area visible
            UIView.animate(withDuration: 0.3) {
                tableView.setContentOffset(CGPoint(x: 0, y: max(0, newOffset)), animated: false)
            }
            
            // Store the original offset to restore later if needed
            self.originalTableOffset = tableView.contentOffset
        }
    }

    // Add this property to store the original table offset
    private var originalTableOffset: CGPoint?

    @objc private func keyboardWillHide(notification: NSNotification) {
        // Reset any adjustments made when keyboard was shown
        // Optionally restore original table offset if desired
        if let originalOffset = originalTableOffset {
            guard let cell = self.cell else { return }
            
            // Find the parent tableView
            var tableView: UITableView?
            var currentView: UIView? = cell
            
            while currentView != nil && tableView == nil {
                currentView = currentView?.superview
                if let foundTableView = currentView as? UITableView {
                    tableView = foundTableView
                }
            }
            
            guard let tableView = tableView else { return }
            
            // Animate back to original position
            UIView.animate(withDuration: 0.3) {
                tableView.setContentOffset(originalOffset, animated: false)
            }
            
            // Clear stored offset
            self.originalTableOffset = nil
        }
    }

    // Don't forget to remove observers in deinit
    deinit {
        NotificationCenter.default.removeObserver(self)
    }
    
    private func addKeyboardDismissGesture() {
        // First, remove any existing gesture recognizers we might have added
        removeKeyboardDismissGesture()
        
        // Add a new tap gesture recognizer
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(dismissKeyboard))
        tapGesture.cancelsTouchesInView = false
        editContainer.addGestureRecognizer(tapGesture)
        
        // Store a reference to it for later removal
        self.tapGestureRecognizer = tapGesture
    }

    private func removeKeyboardDismissGesture() {
        // Remove the tap gesture if it exists
        if let tapGesture = tapGestureRecognizer {
            editContainer.removeGestureRecognizer(tapGesture)
            tapGestureRecognizer = nil
        }
    }

    // Add this property to your class
    private var tapGestureRecognizer: UITapGestureRecognizer?
    
    private func createInputAccessoryView() -> UIView {
        // Create a container view to hold our buttons
        let containerView = UIView()
        containerView.backgroundColor = UIColor.systemBackground
        
        // Add a subtle top border to the container
        let borderView = UIView()
        borderView.backgroundColor = UIColor.systemGray5
        
        // Create save button with appropriate styling
        let saveButton = UIButton(type: .system)
        saveButton.setTitle("Save", for: .normal)
        saveButton.titleLabel?.font = UIFont.systemFont(ofSize: 16, weight: .semibold)
        saveButton.backgroundColor = UIColor.systemGreen.withAlphaComponent(0.1)
        saveButton.setTitleColor(.systemGreen, for: .normal)
        saveButton.layer.cornerRadius = 8
        saveButton.addTarget(self, action: #selector(saveButtonTapped), for: .touchUpInside)
        
        // Create cancel button with appropriate styling
        let cancelButton = UIButton(type: .system)
        cancelButton.setTitle("Cancel", for: .normal)
        cancelButton.titleLabel?.font = UIFont.systemFont(ofSize: 16, weight: .regular)
        cancelButton.backgroundColor = UIColor.systemRed.withAlphaComponent(0.1)
        cancelButton.setTitleColor(.systemRed, for: .normal)
        cancelButton.layer.cornerRadius = 8
        cancelButton.addTarget(self, action: #selector(cancelButtonTapped), for: .touchUpInside)
        
        // Add subviews to container
        containerView.addSubview(borderView)
        containerView.addSubview(cancelButton)
        containerView.addSubview(saveButton)
        
        // Use SnapKit to layout the views
        containerView.snp.makeConstraints { make in
            make.height.equalTo(50)
            make.width.equalTo(UIScreen.main.bounds.width)
        }
        
        borderView.snp.makeConstraints { make in
            make.top.leading.trailing.equalToSuperview()
            make.height.equalTo(0.5)
        }
        
        cancelButton.snp.makeConstraints { make in
            make.leading.equalToSuperview().offset(12)
            make.centerY.equalToSuperview()
            make.width.equalToSuperview().multipliedBy(0.45)  // Equal width with a slight margin
            make.height.equalTo(36)
        }
        
        saveButton.snp.makeConstraints { make in
            make.trailing.equalToSuperview().offset(-12)
            make.centerY.equalToSuperview()
            make.width.equalToSuperview().multipliedBy(0.45)  // Equal width with a slight margin
            make.height.equalTo(36)
        }
        
        return containerView
    }

    // Make sure we apply this properly to all text fields
    private func applyAccessoryViewToAllTextFields() {
        let accessoryView = createInputAccessoryView()
        
        titleField.inputAccessoryView = accessoryView
        pointsField.inputAccessoryView = accessoryView
        targetField.inputAccessoryView = accessoryView
        rewardField.inputAccessoryView = accessoryView
        maxField.inputAccessoryView = accessoryView
    }
}

extension TaskCellEditController: UITextFieldDelegate {
    
    private func setupTextFieldDelegates() {
        titleField.delegate = self
        pointsField.delegate = self
        targetField.delegate = self
        rewardField.delegate = self
        maxField.delegate = self
        
        // Configure keyboard return key behavior
        titleField.returnKeyType = .next
        pointsField.returnKeyType = .next
        targetField.returnKeyType = .next
        rewardField.returnKeyType = .next
        maxField.returnKeyType = .done
    }
    
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        if textField == titleField {
            pointsField.becomeFirstResponder()
        } else if textField == pointsField {
            targetField.becomeFirstResponder()
        } else if textField == targetField {
            rewardField.becomeFirstResponder()
        } else if textField == rewardField {
            maxField.becomeFirstResponder()
        } else if textField == maxField {
            maxField.resignFirstResponder()
            // Optionally trigger save here if you want
            // saveButtonTapped()
        }
        
        return true
    }
}
