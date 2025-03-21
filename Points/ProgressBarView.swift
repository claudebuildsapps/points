import UIKit

class ProgressBarView: UIView {
    // Progress bar
    private let progressBar: UIProgressView = {
        let bar = UIProgressView(progressViewStyle: .default)
        bar.translatesAutoresizingMaskIntoConstraints = false
        bar.progressTintColor = .systemGreen
        bar.trackTintColor = .systemGray5
        bar.layer.cornerRadius = 0 // No rounding
        bar.clipsToBounds = true
        return bar
    }()
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        setupView()
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setupView()
    }
    
    private func setupView() {
        backgroundColor = .clear
        addSubview(progressBar)
        
        // Configure the progress bar
        progressBar.transform = CGAffineTransform(scaleX: 1.0, y: 1.5) // Make it thicker
        
        // Make progress bar fill the entire view
        NSLayoutConstraint.activate([
            progressBar.topAnchor.constraint(equalTo: topAnchor),
            progressBar.leadingAnchor.constraint(equalTo: leadingAnchor),
            progressBar.trailingAnchor.constraint(equalTo: trailingAnchor),
            progressBar.bottomAnchor.constraint(equalTo: bottomAnchor)
        ])
    }
    
    // Public method to update progress
    func updateProgress(_ progress: Float, animated: Bool = true) {
        progressBar.setProgress(progress, animated: animated)
        
        // Update color based on progress - yellow to green
        if progress < 0.5 {
            progressBar.progressTintColor = .systemYellow
        } else if progress < 0.8 {
            // Create intermediate color - yellow-green
            progressBar.progressTintColor = UIColor(red: 0.5, green: 0.8, blue: 0.2, alpha: 1.0)
        } else {
            progressBar.progressTintColor = .systemGreen
        }
    }
}
