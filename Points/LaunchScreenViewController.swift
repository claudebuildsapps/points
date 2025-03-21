import UIKit

class LaunchScreenViewController: UIViewController {
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Configure full screen background
        view.backgroundColor = .white
        
        // Disable safe area insets
        view.insetsLayoutMarginsFromSafeArea = false
        
        // Create centered label
        let pointsLabel = UILabel()
        pointsLabel.text = "Points"
        pointsLabel.textAlignment = .center
        pointsLabel.font = UIFont.systemFont(ofSize: 36, weight: .bold)
        pointsLabel.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(pointsLabel)
        
        // Center constraints - use view edges directly, not safe area
        NSLayoutConstraint.activate([
            pointsLabel.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            pointsLabel.centerYAnchor.constraint(equalTo: view.centerYAnchor)
        ])
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        
        // Explicitly set view frame to fill the window bounds
        if let window = UIApplication.shared.windows.first {
            view.frame = window.frame
        }
    }
    
    // Make sure status bar is hidden for full screen effect
    override var prefersStatusBarHidden: Bool {
        return true
    }
    
    // Disable safe area insets
    override func viewSafeAreaInsetsDidChange() {
        if #available(iOS 11.0, *) {
            super.viewSafeAreaInsetsDidChange()
            view.layoutMargins = .zero
        }
    }
}
