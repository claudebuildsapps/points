import UIKit
import SnapKit

class FooterDisplayView: UIView {
    private let pointsLabel: UILabel = {
        let label = UILabel()
        label.translatesAutoresizingMaskIntoConstraints = false
        label.font = .systemFont(ofSize: 28, weight: .bold)
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
    
    private let clearButton: UIButton = {
        let button = UIButton(type: .system)
        button.translatesAutoresizingMaskIntoConstraints = false
        button.setImage(UIImage(systemName: "xmark.circle.fill"), for: .normal)
        button.tintColor = .systemRed
        return button
    }()
    
    private let softResetButton: UIButton = {
        let button = UIButton(type: .system)
        button.translatesAutoresizingMaskIntoConstraints = false
        button.setImage(UIImage(systemName: "arrow.clockwise.circle.fill"), for: .normal)
        button.tintColor = .systemBlue
        return button
    }()
    
    // Add a method to fully reload the UI
    func fullReloadUI() {
        // Reset points to 0
        updatePoints(0, animated: false)
        
        // Remove all subviews and recreate the view
        subviews.forEach { $0.removeFromSuperview() }
        setupView()
        
        // You can add additional reset logic here, such as:
        // - Resetting any associated data models
        // - Clearing any temporary states
        // - Notifying a delegate about the full reset
        
        // Optional: Trigger a layout update
        setNeedsLayout()
        layoutIfNeeded()
    }
    
    func setAddButtonTarget(_ target: Any?, action: Selector) {
        addButton.addTarget(target, action: action, for: .touchUpInside)
    }
    
    func setClearButtonTarget(_ target: Any?, action: Selector) {
        clearButton.addTarget(target, action: action, for: .touchUpInside)
    }
    
    func setSoftResetButtonTarget(_ target: Any?, action: Selector) {
        softResetButton.addTarget(target, action: action, for: .touchUpInside)
    }
    
    private func setupView() {
        backgroundColor = .clear
        addSubview(pointsLabel)
        addSubview(addButton)
        addSubview(clearButton)
        addSubview(softResetButton)

        let largeConfig = UIImage.SymbolConfiguration(pointSize: 32, weight: .regular)
        
        addButton.setImage(UIImage(systemName: "plus.circle.fill", withConfiguration: largeConfig), for: .normal)
        addButton.tintColor = .systemGreen
        addButton.contentMode = .center
        addButton.imageView?.contentMode = .scaleAspectFit
        
        clearButton.setImage(UIImage(systemName: "xmark.circle.fill", withConfiguration: largeConfig), for: .normal)
        clearButton.tintColor = .systemRed
        clearButton.contentMode = .center
        clearButton.imageView?.contentMode = .scaleAspectFit
        
        softResetButton.setImage(UIImage(systemName: "arrow.clockwise.circle.fill", withConfiguration: largeConfig), for: .normal)
        softResetButton.tintColor = .systemBlue
        softResetButton.contentMode = .center
        softResetButton.imageView?.contentMode = .scaleAspectFit
        
        let buttonSize: CGFloat = 52 * 1.4
        
        [addButton, clearButton, softResetButton].forEach { button in
            button.layer.shadowColor = UIColor.black.cgColor
            button.layer.shadowOffset = CGSize(width: 0, height: 1)
            button.layer.shadowRadius = 2
            button.layer.shadowOpacity = 0.2
        }

        pointsLabel.snp.makeConstraints { make in
            make.leading.equalToSuperview().offset(8)
            make.centerY.equalToSuperview()
        }
        
        addButton.snp.makeConstraints { make in
            make.trailing.equalToSuperview().offset(-8)
            make.centerY.equalToSuperview()
            make.size.equalTo(CGSize(width: buttonSize, height: buttonSize))
        }
        
        clearButton.snp.makeConstraints { make in
            make.trailing.equalTo(addButton.snp.leading).offset(-12)
            make.centerY.equalToSuperview()
            make.size.equalTo(CGSize(width: buttonSize, height: buttonSize))
        }
        
        softResetButton.snp.makeConstraints { make in
            make.trailing.equalTo(clearButton.snp.leading).offset(-12)
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
        
        let startTime = CACurrentMediaTime()
        let timer = CADisplayLink(target: self, selector: #selector(updatePointsCounter))
        timer.preferredFramesPerSecond = 30
        timer.add(to: .main, forMode: .common)
        
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
