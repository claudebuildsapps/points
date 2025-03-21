import UIKit

// MARK: - UI Component Factory
class TaskCellUIFactory {
    
    static func createDisplayPointsLabel() -> UILabel {
        let label = UILabel()
        label.font = UIFont.systemFont(ofSize: 13, weight: .semibold)
        label.textColor = .systemGreen
        label.textAlignment = .center
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }
    
    static func createPointsTitleLabel() -> UILabel {
        let label = UILabel()
        label.font = UIFont.systemFont(ofSize: 9, weight: .regular)
        label.text = "PTS"
        label.textColor = .secondaryLabel
        label.textAlignment = .center
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }
    
    static func createTaskTitleLabel() -> UILabel {
        let label = UILabel()
        label.font = UIFont.systemFont(ofSize: 13, weight: .medium)
        label.numberOfLines = 1
        label.textAlignment = .left
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }
    
    static func createCompletionLabel() -> UILabel {
        let label = UILabel()
        label.font = UIFont.systemFont(ofSize: 13, weight: .regular)
        label.textColor = .systemBlue
        label.textAlignment = .center
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }
    
    static func createCompletionTitleLabel() -> UILabel {
        let label = UILabel()
        label.font = UIFont.systemFont(ofSize: 9, weight: .regular)
        label.text = "DONE"
        label.textColor = .secondaryLabel
        label.textAlignment = .center
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }
    
    static func createEditContainer() -> UIView {
        let view = UIView()
        view.translatesAutoresizingMaskIntoConstraints = false
        view.alpha = 0
        view.clipsToBounds = true
        return view
    }
    
    static func createFieldContainer() -> UIView {
        let view = UIView()
        view.translatesAutoresizingMaskIntoConstraints = false
        view.backgroundColor = UIColor.systemBackground.withAlphaComponent(0.7)
        view.layer.cornerRadius = 8
        return view
    }
    
    static func createFieldLabel(title: String) -> UILabel {
        let label = UILabel()
        label.text = title
        label.font = UIFont.systemFont(ofSize: 13, weight: .medium)
        label.textColor = .secondaryLabel
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }
    
    static func createTextField(keyboardType: UIKeyboardType = .default, textColor: UIColor = .label) -> UITextField {
        let textField = UITextField()
        textField.font = UIFont.systemFont(ofSize: 16, weight: .medium)
        textField.textColor = textColor
        textField.keyboardType = keyboardType
        textField.borderStyle = .roundedRect
        textField.backgroundColor = UIColor.systemBackground
        textField.translatesAutoresizingMaskIntoConstraints = false
        return textField
    }
    
    static func createButton(title: String, isPrimary: Bool = false) -> UIButton {
        let button = UIButton(type: .system)
        button.setTitle(title, for: .normal)
        button.titleLabel?.font = UIFont.systemFont(ofSize: 16, weight: isPrimary ? .semibold : .medium)
        button.backgroundColor = isPrimary ? UIColor.systemGreen.withAlphaComponent(0.8) : UIColor.systemGray4
        button.setTitleColor(isPrimary ? .white : .label, for: .normal)
        button.layer.cornerRadius = 8
        button.translatesAutoresizingMaskIntoConstraints = false
        return button
    }
    
    static func createSwipeActionButton(title: String, color: UIColor, halfWidth: Bool = false) -> UIButton {
        let button = UIButton(type: .system)
        button.setTitle(title, for: .normal)
        button.titleLabel?.font = UIFont.systemFont(ofSize: 14, weight: .medium)
        button.backgroundColor = color
        button.setTitleColor(.white, for: .normal)
        button.translatesAutoresizingMaskIntoConstraints = false
        return button
    }
}
