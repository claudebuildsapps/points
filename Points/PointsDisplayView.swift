import UIKit
import SnapKit

class PointsDisplayView: UIView {
    private let pointsLabel: UILabel = {
        let label = UILabel()
        label.translatesAutoresizingMaskIntoConstraints = false
        label.font = .systemFont(ofSize: 22, weight: .bold)
        label.textColor = .label
        label.text = "0"
        return label
    }()
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        setupView()
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setupView()
    }
    
    private let addButton: UIButton = {
        let button = UIButton(type: .system)
        button.translatesAutoresizingMaskIntoConstraints = false
        button.setImage(UIImage(systemName: "plus.circle.fill"), for: .normal)
        button.tintColor = .systemGreen
        return button
    }()
    
    private let resetButton: UIButton = {
        let button = UIButton(type: .system)
        button.translatesAutoresizingMaskIntoConstraints = false
        button.setImage(UIImage(systemName: "arrow.clockwise.circle.fill"), for: .normal)
        button.tintColor = .systemRed
        return button
    }()
    
    // Add a method to set the target for the add button
    func setAddButtonTarget(_ target: Any?, action: Selector) {
        addButton.addTarget(target, action: action, for: .touchUpInside)
    }
    
    // Add a method to set the target for the reset button
    func setResetButtonTarget(_ target: Any?, action: Selector) {
        resetButton.addTarget(target, action: action, for: .touchUpInside)
    }
    
    private func setupView() {
        backgroundColor = .clear
        addSubview(pointsLabel)
        addSubview(addButton)
        addSubview(resetButton)

        // Larger font and better buttons
        pointsLabel.font = .systemFont(ofSize: 28, weight: .bold)
        
        // Configure add button with larger icon
        let largeConfig = UIImage.SymbolConfiguration(pointSize: 32, weight: .regular) // 20% smaller than 40
        addButton.setImage(UIImage(systemName: "plus.circle.fill", withConfiguration: largeConfig), for: .normal)
        addButton.tintColor = .systemGreen
        addButton.contentMode = .center
        addButton.imageView?.contentMode = .scaleAspectFit
        
        // Configure reset button with larger icon
        resetButton.setImage(UIImage(systemName: "arrow.clockwise.circle.fill", withConfiguration: largeConfig), for: .normal)
        resetButton.tintColor = .systemRed
        resetButton.contentMode = .center
        resetButton.imageView?.contentMode = .scaleAspectFit
        
        // Make buttons larger (40% bigger than the current size of 52)
        let buttonSize: CGFloat = 52 * 1.4 // Increase size by 40%
        
        // Add subtle shadow to make buttons stand out
        [addButton, resetButton].forEach { button in
            button.layer.shadowColor = UIColor.black.cgColor
            button.layer.shadowOffset = CGSize(width: 0, height: 1)
            button.layer.shadowRadius = 2
            button.layer.shadowOpacity = 0.2
        }

        // Use SnapKit for more concise constraints
        pointsLabel.snp.makeConstraints { make in
            make.leading.equalToSuperview().offset(8)
            make.centerY.equalToSuperview()
        }
        
        addButton.snp.makeConstraints { make in
            make.trailing.equalToSuperview().offset(-8)
            make.centerY.equalToSuperview()
            make.size.equalTo(CGSize(width: buttonSize, height: buttonSize))
        }
        
        resetButton.snp.makeConstraints { make in
            make.trailing.equalTo(addButton.snp.leading).offset(-12)
            make.centerY.equalToSuperview()
            make.size.equalTo(CGSize(width: buttonSize, height: buttonSize))
        }
    }
    
    func updatePoints(_ points: Int, animated: Bool = true) {
        if animated {
            animatePointChange(to: points)
        } else {
            pointsLabel.text = "\(points)"
        }
    }
    
    func getCurrentPoints() -> Int {
        return Int(pointsLabel.text ?? "0") ?? 0
    }
    
    private func animatePointChange(to newPoints: Int) {
        let oldPoints = getCurrentPoints()
        let duration: TimeInterval = 0.75
        
        // Counter animation for points
        let startTime = CACurrentMediaTime()
        let timer = CADisplayLink(target: self, selector: #selector(updatePointsCounter))
        timer.preferredFramesPerSecond = 30
        timer.add(to: .main, forMode: .common)
        
        // Store animation values in the timer using associated objects
        objc_setAssociatedObject(timer, UnsafeRawPointer(bitPattern: 1)!, startTime, .OBJC_ASSOCIATION_RETAIN)
        objc_setAssociatedObject(timer, UnsafeRawPointer(bitPattern: 2)!, duration, .OBJC_ASSOCIATION_RETAIN)
        objc_setAssociatedObject(timer, UnsafeRawPointer(bitPattern: 3)!, oldPoints, .OBJC_ASSOCIATION_RETAIN)
        objc_setAssociatedObject(timer, UnsafeRawPointer(bitPattern: 4)!, newPoints, .OBJC_ASSOCIATION_RETAIN)
    }
    
    @objc private func updatePointsCounter(timer: CADisplayLink) {
        let startTime = objc_getAssociatedObject(timer, UnsafeRawPointer(bitPattern: 1)!) as! CFTimeInterval
        let duration = objc_getAssociatedObject(timer, UnsafeRawPointer(bitPattern: 2)!) as! TimeInterval
        let oldPoints = objc_getAssociatedObject(timer, UnsafeRawPointer(bitPattern: 3)!) as! Int
        let newPoints = objc_getAssociatedObject(timer, UnsafeRawPointer(bitPattern: 4)!) as! Int
        
        let elapsedTime = CACurrentMediaTime() - startTime
        
        if elapsedTime >= duration {
            pointsLabel.text = "\(newPoints)"
            timer.invalidate()
            return
        }
        
        let percentage = elapsedTime / duration
        let currentPoints = oldPoints + Int(Double(newPoints - oldPoints) * percentage)
        pointsLabel.text = "\(currentPoints)"
    }
}
