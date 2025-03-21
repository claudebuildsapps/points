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
    private var saveButton: UIButton!
    private var cancelButton: UIButton!
    
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
        
        // Create buttons
        saveButton = TaskCellUIFactory.createButton(title: "Save", isPrimary: true)
        cancelButton = TaskCellUIFactory.createButton(title: "Cancel")
        
        // Add action handlers
        saveButton.addTarget(self, action: #selector(saveButtonTapped), for: .touchUpInside)
        cancelButton.addTarget(self, action: #selector(cancelButtonTapped), for: .touchUpInside)
        
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
        
        editContainer.addSubview(saveButton)
        editContainer.addSubview(cancelButton)
        
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
            make.height.equalTo(45)
        }
        
        optionalContainer.snp.makeConstraints { make in
            make.top.equalTo(maxContainer.snp.bottom).offset(8)
            make.right.equalToSuperview().offset(-8)
            make.width.equalToSuperview().multipliedBy(0.47)
            make.height.equalTo(45)
        }
        
        // Buttons row
        cancelButton.snp.makeConstraints { make in
            make.top.equalTo(routineContainer.snp.bottom).offset(12)
            make.left.equalToSuperview().offset(8)
            make.width.equalToSuperview().multipliedBy(0.47)
            make.height.equalTo(40)
            make.bottom.lessThanOrEqualToSuperview().offset(-12)
        }
        
        saveButton.snp.makeConstraints { make in
            make.top.equalTo(optionalContainer.snp.bottom).offset(12)
            make.right.equalToSuperview().offset(-8)
            make.width.equalToSuperview().multipliedBy(0.47)
            make.height.equalTo(40)
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
            make.top.equalToSuperview().offset(8)
            make.left.equalToSuperview().offset(8)
            make.right.equalToSuperview().offset(-8)
        }
        
        routineSwitch.snp.makeConstraints { make in
            make.top.equalTo(routineLabel.snp.bottom).offset(4)
            make.centerX.equalToSuperview()
        }
        
        // Optional
        optionalLabel.snp.makeConstraints { make in
            make.top.equalToSuperview().offset(8)
            make.left.equalToSuperview().offset(8)
            make.right.equalToSuperview().offset(-8)
        }
        
        optionalSwitch.snp.makeConstraints { make in
            make.top.equalTo(optionalLabel.snp.bottom).offset(4)
            make.centerX.equalToSuperview()
        }
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
    
    @objc private func saveButtonTapped() {
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
    
    @objc private func cancelButtonTapped() {
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
    
    private func setupKeyboardAccessibility() {
        // Add input accessory views to all text fields to provide a "Done" button
        addDoneButtonToTextField(titleField)
        addDoneButtonToTextField(pointsField)
        addDoneButtonToTextField(targetField)
        addDoneButtonToTextField(rewardField)
        addDoneButtonToTextField(maxField)
        
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

    private func addDoneButtonToTextField(_ textField: UITextField) {
        let toolbar = UIToolbar()
        toolbar.sizeToFit()
        
        let flexSpace = UIBarButtonItem(barButtonSystemItem: .flexibleSpace, target: nil, action: nil)
        let doneButton = UIBarButtonItem(title: "Done", style: .done, target: self, action: #selector(dismissKeyboard))
        let saveButton = UIBarButtonItem(title: "Save", style: .done, target: self, action: #selector(saveButtonTapped))
        let cancelButton = UIBarButtonItem(title: "Cancel", style: .plain, target: self, action: #selector(cancelButtonTapped))
        
        toolbar.items = [cancelButton, flexSpace, doneButton, saveButton]
        textField.inputAccessoryView = toolbar
    }

    @objc private func keyboardWillShow(notification: NSNotification) {
        // Make sure save/cancel buttons remain accessible when keyboard shows
        // You can adjust the cell/container if needed here
    }

    @objc private func keyboardWillHide(notification: NSNotification) {
        // Reset any adjustments made when keyboard was shown
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


}

extension TaskCellEditController: UITextFieldDelegate {
    
    // Add this to the setupEditControls method to set up delegates for text fields
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
    
    // Call this method at the end of your setupEditControls method
    // setupTextFieldDelegates()
    
    // Handle return key presses to move between fields
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
    
    // Add a "Done" button to number pads (which don't have a return key)
    private func addDoneButtonToNumberPad(_ textField: UITextField) {
        let toolBar = UIToolbar()
        toolBar.sizeToFit()
        
        let flexSpace = UIBarButtonItem(barButtonSystemItem: .flexibleSpace, target: nil, action: nil)
        let doneButton = UIBarButtonItem(barButtonSystemItem: .done, target: self, action: #selector(dismissKeyboard))
        
        toolBar.items = [flexSpace, doneButton]
        textField.inputAccessoryView = toolBar
    }
    
    // Add this method to configure input accessory views for numeric fields
    private func configureInputAccessoryViews() {
        addDoneButtonToNumberPad(pointsField)
        addDoneButtonToNumberPad(targetField)
        addDoneButtonToNumberPad(rewardField)
        addDoneButtonToNumberPad(maxField)
    }
    
    // Call this method at the end of your setupEditControls method
    // configureInputAccessoryViews()
}

