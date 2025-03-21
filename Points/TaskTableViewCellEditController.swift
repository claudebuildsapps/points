import UIKit
import CoreData

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
    private var saveButton: UIButton!
    private var cancelButton: UIButton!
    
    // Constraints
    private var editContainerTopConstraint: NSLayoutConstraint?
    private var editContainerHeightConstraint: NSLayoutConstraint?
    // Remove the bottom constraint - this was causing the conflict
    
    // MARK: - Initialization
    init(cell: TaskTableViewCell, delegate: TaskTableViewCellDelegate?) {
        self.editContainer = TaskCellUIFactory.createEditContainer()
        
        super.init()
        
        self.cell = cell
        self.delegate = delegate
    }
    
    // MARK: - Setup
    func setupEditContainer(in contentView: UIView) {
        // Create the edit container that covers the ENTIRE cell
        editContainer.backgroundColor = UIColor.systemBackground
        
        // Add to content view
        contentView.addSubview(editContainer)
        
        // Position it to cover the entire cell with no spacing at the top
        NSLayoutConstraint.activate([
            // No spacing at the top - cover the entire cell
            editContainer.topAnchor.constraint(equalTo: contentView.topAnchor),
            editContainer.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
            editContainer.trailingAnchor.constraint(equalTo: contentView.trailingAnchor),
            editContainer.bottomAnchor.constraint(equalTo: contentView.bottomAnchor)
        ])
        
        // Initially set the edit interface to be invisible
        editContainer.alpha = 0
        
        // Set up the edit controls
        setupEditControls()
    }

    private func setupEditControls() {
        // Create title field container
        let titleContainer = TaskCellUIFactory.createFieldContainer()
        let titleLabel = TaskCellUIFactory.createFieldLabel(title: "Task")
        titleField = TaskCellUIFactory.createTextField()
        
        // Create points field container
        let pointsContainer = TaskCellUIFactory.createFieldContainer()
        let pointsLabel = TaskCellUIFactory.createFieldLabel(title: "Points")
        pointsField = TaskCellUIFactory.createTextField(keyboardType: .decimalPad, textColor: .systemGreen)
        
        // Create target field container
        let targetContainer = TaskCellUIFactory.createFieldContainer()
        let targetLabel = TaskCellUIFactory.createFieldLabel(title: "Target")
        targetField = TaskCellUIFactory.createTextField(keyboardType: .numberPad, textColor: .systemBlue)
        
        // Create buttons
        saveButton = TaskCellUIFactory.createButton(title: "Save", isPrimary: true)
        cancelButton = TaskCellUIFactory.createButton(title: "Cancel")
        
        // Add action handlers
        saveButton.addTarget(self, action: #selector(saveButtonTapped), for: .touchUpInside)
        cancelButton.addTarget(self, action: #selector(cancelButtonTapped), for: .touchUpInside)
        
        // Add to edit container
        editContainer.addSubview(titleContainer)
        titleContainer.addSubview(titleLabel)
        titleContainer.addSubview(titleField)
        
        editContainer.addSubview(pointsContainer)
        pointsContainer.addSubview(pointsLabel)
        pointsContainer.addSubview(pointsField)
        
        editContainer.addSubview(targetContainer)
        targetContainer.addSubview(targetLabel)
        targetContainer.addSubview(targetField)
        
        editContainer.addSubview(saveButton)
        editContainer.addSubview(cancelButton)
        
        // Setup constraints for title container
        NSLayoutConstraint.activate([
            titleContainer.topAnchor.constraint(equalTo: editContainer.topAnchor, constant: 8),
            titleContainer.leadingAnchor.constraint(equalTo: editContainer.leadingAnchor, constant: 8),
            titleContainer.trailingAnchor.constraint(equalTo: editContainer.trailingAnchor, constant: -8),
            titleContainer.heightAnchor.constraint(equalToConstant: 70),
            
            titleLabel.topAnchor.constraint(equalTo: titleContainer.topAnchor, constant: 8),
            titleLabel.leadingAnchor.constraint(equalTo: titleContainer.leadingAnchor, constant: 8),
            titleLabel.trailingAnchor.constraint(equalTo: titleContainer.trailingAnchor, constant: -8),
            
            titleField.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 4),
            titleField.leadingAnchor.constraint(equalTo: titleContainer.leadingAnchor, constant: 8),
            titleField.trailingAnchor.constraint(equalTo: titleContainer.trailingAnchor, constant: -8),
            titleField.heightAnchor.constraint(equalToConstant: 36)
        ])
        
        // Setup constraints for points container
        NSLayoutConstraint.activate([
            pointsContainer.topAnchor.constraint(equalTo: titleContainer.bottomAnchor, constant: 8),
            pointsContainer.leadingAnchor.constraint(equalTo: editContainer.leadingAnchor, constant: 8),
            pointsContainer.widthAnchor.constraint(equalTo: editContainer.widthAnchor, multiplier: 0.47),
            pointsContainer.heightAnchor.constraint(equalToConstant: 70),
            
            pointsLabel.topAnchor.constraint(equalTo: pointsContainer.topAnchor, constant: 8),
            pointsLabel.leadingAnchor.constraint(equalTo: pointsContainer.leadingAnchor, constant: 8),
            pointsLabel.trailingAnchor.constraint(equalTo: pointsContainer.trailingAnchor, constant: -8),
            
            pointsField.topAnchor.constraint(equalTo: pointsLabel.bottomAnchor, constant: 4),
            pointsField.leadingAnchor.constraint(equalTo: pointsContainer.leadingAnchor, constant: 8),
            pointsField.trailingAnchor.constraint(equalTo: pointsContainer.trailingAnchor, constant: -8),
            pointsField.heightAnchor.constraint(equalToConstant: 36)
        ])
        
        // Setup constraints for target container
        NSLayoutConstraint.activate([
            targetContainer.topAnchor.constraint(equalTo: titleContainer.bottomAnchor, constant: 8),
            targetContainer.trailingAnchor.constraint(equalTo: editContainer.trailingAnchor, constant: -8),
            targetContainer.widthAnchor.constraint(equalTo: editContainer.widthAnchor, multiplier: 0.47),
            targetContainer.heightAnchor.constraint(equalToConstant: 70),
            
            targetLabel.topAnchor.constraint(equalTo: targetContainer.topAnchor, constant: 8),
            targetLabel.leadingAnchor.constraint(equalTo: targetContainer.leadingAnchor, constant: 8),
            targetLabel.trailingAnchor.constraint(equalTo: targetContainer.trailingAnchor, constant: -8),
            
            targetField.topAnchor.constraint(equalTo: targetLabel.bottomAnchor, constant: 4),
            targetField.leadingAnchor.constraint(equalTo: targetContainer.leadingAnchor, constant: 8),
            targetField.trailingAnchor.constraint(equalTo: targetContainer.trailingAnchor, constant: -8),
            targetField.heightAnchor.constraint(equalToConstant: 36)
        ])
        
        // Setup constraints for buttons - fix to be on the same line
        NSLayoutConstraint.activate([
            // Keep cancel button on the left side
            cancelButton.topAnchor.constraint(equalTo: pointsContainer.bottomAnchor, constant: 16),
            cancelButton.leadingAnchor.constraint(equalTo: editContainer.leadingAnchor, constant: 8),
            cancelButton.widthAnchor.constraint(equalTo: editContainer.widthAnchor, multiplier: 0.47),
            cancelButton.heightAnchor.constraint(equalToConstant: 44),
            
            // Keep save button on the right side, but make sure it aligns with cancel button
            saveButton.topAnchor.constraint(equalTo: cancelButton.topAnchor), // Same top alignment
            saveButton.trailingAnchor.constraint(equalTo: editContainer.trailingAnchor, constant: -8),
            saveButton.widthAnchor.constraint(equalTo: editContainer.widthAnchor, multiplier: 0.47),
            saveButton.heightAnchor.constraint(equalToConstant: 44),
            
            // Make sure buttons' bottom is constrained to the container
            saveButton.bottomAnchor.constraint(lessThanOrEqualTo: editContainer.bottomAnchor, constant: -16),
            cancelButton.bottomAnchor.constraint(lessThanOrEqualTo: editContainer.bottomAnchor, constant: -16)
        ])
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
                pointsField.text = task.points?.stringValue
                targetField.text = "\(task.target)"
            }
            
            // Make sure the container is fully sized to hold the controls
            editContainer.layoutIfNeeded()
            
            // Show the edit interface
            if animated {
                UIView.animate(withDuration: 0.3) {
                    self.editContainer.alpha = 1
                } completion: { _ in
                    self.titleField.becomeFirstResponder()
                }
            } else {
                editContainer.alpha = 1
                titleField.becomeFirstResponder()
            }
        } else {
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
            titleField.resignFirstResponder()
            pointsField.resignFirstResponder()
            targetField.resignFirstResponder()
        }
    }

    // MARK: - Button Actions
    @objc private func saveButtonTapped() {
        guard let task = task, let cell = cell as? TaskTableViewCell else { return }
        
        // Store the values we need to save
        let updatedValues: [String: Any] = [
            "title": titleField.text ?? "",
            "points": NSDecimalNumber(string: pointsField.text ?? "0"),
            "target": Int16(targetField.text ?? "1") ?? 1
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
        task = nil
        titleField.text = nil
        pointsField.text = nil
        targetField.text = nil
    }
    
    private func resetFields() {
        titleField.text = nil
        pointsField.text = nil
        targetField.text = nil
    }
}
