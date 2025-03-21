import UIKit
import CoreData

// MARK: - TaskCell Swipe Actions
class TaskCellSwipeController: NSObject {
    // MARK: - Properties
    private weak var cell: TaskTableViewCell?
    weak var delegate: TaskTableViewCellDelegate?
    private var task: CoreDataTask?
    
    // Left-to-right swipe shows X, Copy, Edit (in that order)
    private let deleteButton: UIButton
    private let copyButton: UIButton
    private let editButton: UIButton
    
    // Right-to-left swipe shows Undo (Undo grows)
    private let undoButton: UIButton
    
    // Swipe state tracking
    private var isLeftMenuOpen = false
    private var isRightMenuOpen = false
    private var editWidthConstraint: NSLayoutConstraint?
    private var undoWidthConstraint: NSLayoutConstraint?
    
    // Static property to track currently open swipe controller
    private static weak var currentOpenController: TaskCellSwipeController?
    
    // MARK: - Initialization
    init(cell: TaskTableViewCell, delegate: TaskTableViewCellDelegate?) {
        deleteButton = TaskCellUIFactory.createSwipeActionButton(title: "X", color: .systemRed, halfWidth: true)
        copyButton = TaskCellUIFactory.createSwipeActionButton(title: "Copy", color: .systemBlue, halfWidth: true)
        editButton = TaskCellUIFactory.createSwipeActionButton(title: "Edit", color: .systemGreen)
        undoButton = TaskCellUIFactory.createSwipeActionButton(title: "Undo", color: .systemOrange)
        
        super.init()
        
        self.cell = cell
        self.delegate = delegate
        
        deleteButton.addTarget(self, action: #selector(deleteButtonTapped), for: .touchUpInside)
        copyButton.addTarget(self, action: #selector(copyButtonTapped), for: .touchUpInside)
        editButton.addTarget(self, action: #selector(editButtonTapped), for: .touchUpInside)
        undoButton.addTarget(self, action: #selector(undoButtonTapped), for: .touchUpInside)
    }
    
    // MARK: - Configuration
    func configure(with task: CoreDataTask) {
        self.task = task
    }
    
    // MARK: - Gesture Setup
    func setupSwipeGestures(in contentView: UIView) {
        let rightSwipe = UISwipeGestureRecognizer(target: self, action: #selector(handleRightSwipe))
        rightSwipe.direction = .right
        contentView.addGestureRecognizer(rightSwipe)
        
        let leftSwipe = UISwipeGestureRecognizer(target: self, action: #selector(handleLeftSwipe))
        leftSwipe.direction = .left
        contentView.addGestureRecognizer(leftSwipe)
        
        let panGesture = UIPanGestureRecognizer(target: self, action: #selector(handlePanGesture))
        panGesture.delegate = self
        contentView.addGestureRecognizer(panGesture)
    }
    
    // MARK: - Gesture Handlers
    @objc private func handleRightSwipe() {
        if !isRightMenuOpen && !isLeftMenuOpen {
            // Close any other open swipe menus
            TaskCellSwipeController.closeCurrentOpenMenu(except: self)
            showLeftMenu()
        } else if isRightMenuOpen {
            dismissSwipeActions()
        }
    }
    
    @objc private func handleLeftSwipe() {
        if !isLeftMenuOpen && !isRightMenuOpen {
            // Close any other open swipe menus
            TaskCellSwipeController.closeCurrentOpenMenu(except: self)
            showRightMenu()
        } else if isLeftMenuOpen {
            dismissSwipeActions()
        }
    }
    
    @objc private func handlePanGesture(_ gesture: UIPanGestureRecognizer) {
        guard let view = gesture.view else { return }
        let translation = gesture.translation(in: view)
        let cellWidth = view.bounds.width
        
        switch gesture.state {
        case .began:
            // Close any other open swipe menus when starting a new pan
            TaskCellSwipeController.closeCurrentOpenMenu(except: self)
            
            if translation.x > 0 && !isLeftMenuOpen && !isRightMenuOpen {
                showLeftMenu(initial: true)
            } else if translation.x < 0 && !isRightMenuOpen && !isLeftMenuOpen {
                showRightMenu(initial: true)
            }
            
        case .changed:
            if isLeftMenuOpen {
                let swipeDistance = min(max(translation.x, 0), cellWidth)
                let maxEditWidth = cellWidth - (cellWidth * 0.15) // Leave 15% for X and Copy
                let newEditWidth = max(cellWidth * 0.3, swipeDistance) // Minimum width is initial width
                editWidthConstraint?.constant = min(newEditWidth, maxEditWidth)
                view.layoutIfNeeded()
                
                // Trigger action when user swipes all the way to the end
                if swipeDistance >= cellWidth * 0.95 {
                    editButtonTapped() // Triggers edit action and dismissal
                    gesture.state = .ended // Force gesture to end after action
                }
            } else if isRightMenuOpen {
                let swipeDistance = min(max(-translation.x, 0), cellWidth)
                let newUndoWidth = max(cellWidth * 0.3, swipeDistance) // Minimum width is initial width
                undoWidthConstraint?.constant = min(newUndoWidth, cellWidth * 0.85) // Max 85% width
                view.layoutIfNeeded()
                
                // Trigger action when user swipes all the way to the end
                if swipeDistance >= cellWidth * 0.95 {
                    undoButtonTapped() // Triggers undo action and dismissal
                    gesture.state = .ended // Force gesture to end after action
                }
            }
            
        case .ended, .cancelled:
            if isLeftMenuOpen && translation.x < cellWidth * 0.3 {
                dismissSwipeActions()
            } else if isRightMenuOpen && -translation.x < cellWidth * 0.3 {
                dismissSwipeActions()
            }
            
        default:
            break
        }
    }
    
    // MARK: - Menu Display
    private func showLeftMenu(initial: Bool = false) {
        guard let contentView = cell?.contentView, !isLeftMenuOpen, !isRightMenuOpen else { return }
        
        // Set this controller as the currently open one
        TaskCellSwipeController.currentOpenController = self
        
        // Add buttons in the correct order: X, Copy, Edit (from left to right)
        contentView.addSubview(deleteButton)
        contentView.addSubview(copyButton)
        contentView.addSubview(editButton)
        
        let buttonHeight: CGFloat = contentView.bounds.height
        let fullWidth: CGFloat = contentView.bounds.width * 0.3
        let halfWidth: CGFloat = fullWidth / 2
        
        if initial {
            // Position buttons initially off-screen
            deleteButton.frame = CGRect(x: -fullWidth, y: 0, width: halfWidth, height: buttonHeight)
            copyButton.frame = CGRect(x: -fullWidth - halfWidth, y: 0, width: halfWidth, height: buttonHeight)
            editButton.frame = CGRect(x: -fullWidth - halfWidth * 2, y: 0, width: fullWidth, height: buttonHeight)
        }
        
        // Set up constraints for proper layout
        NSLayoutConstraint.activate([
            deleteButton.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
            deleteButton.topAnchor.constraint(equalTo: contentView.topAnchor),
            deleteButton.heightAnchor.constraint(equalToConstant: buttonHeight),
            deleteButton.widthAnchor.constraint(equalToConstant: halfWidth),
            
            copyButton.leadingAnchor.constraint(equalTo: deleteButton.trailingAnchor),
            copyButton.topAnchor.constraint(equalTo: contentView.topAnchor),
            copyButton.heightAnchor.constraint(equalToConstant: buttonHeight),
            copyButton.widthAnchor.constraint(equalToConstant: halfWidth),
            
            editButton.leadingAnchor.constraint(equalTo: copyButton.trailingAnchor),
            editButton.topAnchor.constraint(equalTo: contentView.topAnchor),
            editButton.heightAnchor.constraint(equalToConstant: buttonHeight),
        ])
        
        // Make Edit button resizable
        editWidthConstraint = editButton.widthAnchor.constraint(equalToConstant: fullWidth)
        editWidthConstraint?.isActive = true
        
        if !initial {
            // Prepare for animation
            deleteButton.frame.origin.x = -fullWidth
            copyButton.frame.origin.x = -fullWidth - halfWidth
            editButton.frame.origin.x = -fullWidth - halfWidth * 2
            
            // Animate buttons into view
            UIView.animate(withDuration: 0.3, delay: 0, options: .curveEaseOut, animations: {
                self.deleteButton.frame.origin.x = 0
                self.copyButton.frame.origin.x = halfWidth
                self.editButton.frame.origin.x = halfWidth * 2
                contentView.layoutIfNeeded()
            })
        }
        
        // Add tap gesture to dismiss
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(dismissSwipeActions))
        contentView.addGestureRecognizer(tapGesture)
        
        isLeftMenuOpen = true
    }
    
    private func showRightMenu(initial: Bool = false) {
        guard let contentView = cell?.contentView, !isRightMenuOpen, !isLeftMenuOpen else { return }
        
        // Set this controller as the currently open one
        TaskCellSwipeController.currentOpenController = self
        
        contentView.addSubview(undoButton)
        
        let buttonHeight: CGFloat = contentView.bounds.height
        let buttonWidth: CGFloat = contentView.bounds.width * 0.3
        
        if initial {
            undoButton.frame = CGRect(x: contentView.bounds.width, y: 0, width: buttonWidth, height: buttonHeight)
        }
        
        NSLayoutConstraint.activate([
            undoButton.trailingAnchor.constraint(equalTo: contentView.trailingAnchor),
            undoButton.topAnchor.constraint(equalTo: contentView.topAnchor),
            undoButton.heightAnchor.constraint(equalToConstant: buttonHeight)
        ])
        
        undoWidthConstraint = undoButton.widthAnchor.constraint(equalToConstant: buttonWidth)
        undoWidthConstraint?.isActive = true
        
        if !initial {
            undoButton.frame.origin.x = contentView.bounds.width
            
            UIView.animate(withDuration: 0.3, delay: 0, options: .curveEaseOut, animations: {
                self.undoButton.frame.origin.x = contentView.bounds.width - buttonWidth
                contentView.layoutIfNeeded()
            })
        }
        
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(dismissSwipeActions))
        contentView.addGestureRecognizer(tapGesture)
        
        isRightMenuOpen = true
    }
    
    @objc private func dismissSwipeActions() {
        guard let contentView = cell?.contentView else { return }
        
        let fullWidth: CGFloat = contentView.bounds.width * 0.3
        let halfWidth: CGFloat = fullWidth / 2
        
        UIView.animate(withDuration: 0.3, delay: 0, options: .curveEaseIn, animations: {
            if self.isLeftMenuOpen {
                // Animate buttons back off-screen
                self.deleteButton.frame.origin.x = -fullWidth
                self.copyButton.frame.origin.x = -fullWidth - halfWidth
                self.editButton.frame.origin.x = -fullWidth - halfWidth * 2
            }
            if self.isRightMenuOpen {
                self.undoButton.frame.origin.x = contentView.bounds.width
            }
            contentView.layoutIfNeeded()
        }, completion: { _ in
            // Clean up after animation
            self.deleteButton.removeFromSuperview()
            self.copyButton.removeFromSuperview()
            self.editButton.removeFromSuperview()
            self.undoButton.removeFromSuperview()
            
            self.editWidthConstraint?.isActive = false
            self.undoWidthConstraint?.isActive = false
            self.editWidthConstraint = nil
            self.undoWidthConstraint = nil
            
            // Remove tap gestures
            if let gestures = self.cell?.contentView.gestureRecognizers {
                for gesture in gestures {
                    if gesture is UITapGestureRecognizer {
                        self.cell?.contentView.removeGestureRecognizer(gesture)
                    }
                }
            }
            
            self.isLeftMenuOpen = false
            self.isRightMenuOpen = false
            
            // Clear current open controller reference if it's this one
            if TaskCellSwipeController.currentOpenController === self {
                TaskCellSwipeController.currentOpenController = nil
            }
        })
    }
    
    // MARK: - Button Actions
    @objc private func undoButtonTapped() {
        guard let task = task, let cell = cell else { return }
        delegate?.cellDidRequestDecrement(cell, task: task)
        dismissSwipeActions()
    }
    
    @objc private func editButtonTapped() {
        if let cell = cell as? TaskTableViewCell {
            cell.toggleExpandedState(expanded: true)
        }
        dismissSwipeActions()
    }

    @objc private func copyButtonTapped() {
        guard let task = task, let cell = cell else { return }
        delegate?.cellDidRequestDuplicate(cell, task: task)
        dismissSwipeActions()
    }
    
    @objc private func deleteButtonTapped() {
        guard let task = task, let cell = cell else { return }
        delegate?.cellDidRequestDelete(cell, task: task)
        dismissSwipeActions()
    }
    
    // MARK: - Static Helpers
    private static func closeCurrentOpenMenu(except controller: TaskCellSwipeController?) {
        if let currentController = TaskCellSwipeController.currentOpenController, currentController !== controller {
            currentController.dismissSwipeActions()
        }
    }
    
    // MARK: - Cleanup
    func prepareForReuse() {
        task = nil
        dismissSwipeActions()
        isLeftMenuOpen = false
        isRightMenuOpen = false
    }
}

// MARK: - UIGestureRecognizerDelegate
extension TaskCellSwipeController: UIGestureRecognizerDelegate {
    func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldRecognizeSimultaneouslyWith otherGestureRecognizer: UIGestureRecognizer) -> Bool {
        return true
    }
}
