import UIKit

protocol TabBarViewDelegate: AnyObject {
    func didSelectTab(at index: Int)
}

class TabBarView: UIView {
    private let tabCount: Int
    private let tabColors: [UIColor]
    private var tabViews: [UIView] = []
    private var tabLabels: [UILabel] = []
    private var dividers: [UIView] = []
    
    weak var delegate: TabBarViewDelegate?
    
    init(tabCount: Int = 4, tabColors: [UIColor]? = nil) {
        self.tabCount = tabCount
        
        // Default colors if none provided
        self.tabColors = tabColors ?? [
            UIColor(red: 0.4, green: 0.6, blue: 0.8, alpha: 1.0),
            UIColor(red: 0.5, green: 0.7, blue: 0.6, alpha: 1.0),
            UIColor(red: 0.7, green: 0.6, blue: 0.5, alpha: 1.0),
            UIColor(red: 0.8, green: 0.5, blue: 0.4, alpha: 1.0)
        ]
        
        super.init(frame: .zero)
        setupTabs()
    }
    
    required init?(coder: NSCoder) {
        self.tabCount = 4
        self.tabColors = [
            UIColor(red: 0.4, green: 0.6, blue: 0.8, alpha: 1.0),
            UIColor(red: 0.5, green: 0.7, blue: 0.6, alpha: 1.0),
            UIColor(red: 0.7, green: 0.6, blue: 0.5, alpha: 1.0),
            UIColor(red: 0.8, green: 0.5, blue: 0.4, alpha: 1.0)
        ]
        super.init(coder: coder)
        setupTabs()
    }
    
    private func setupTabs() {
        backgroundColor = .clear
        layer.cornerRadius = 10 // Add rounded corners
        clipsToBounds = true
        layer.borderWidth = 1
        layer.borderColor = UIColor.systemGray4.cgColor
        
        // Create tab sections
        for i in 0..<tabCount {
            // Tab view
            let tabView = UIView()
            tabView.translatesAutoresizingMaskIntoConstraints = false
            tabView.backgroundColor = tabColors[i % tabColors.count]
            tabView.tag = 100 + i
            addSubview(tabView)
            tabViews.append(tabView)
            
            // Create a container to hold the label - this ensures proper centering
            let labelContainer = UIView()
            labelContainer.backgroundColor = .clear
            labelContainer.translatesAutoresizingMaskIntoConstraints = false
            tabView.addSubview(labelContainer)
            
            // Fill the tab view with the container
            NSLayoutConstraint.activate([
                labelContainer.topAnchor.constraint(equalTo: tabView.topAnchor),
                labelContainer.bottomAnchor.constraint(equalTo: tabView.bottomAnchor),
                labelContainer.leadingAnchor.constraint(equalTo: tabView.leadingAnchor),
                labelContainer.trailingAnchor.constraint(equalTo: tabView.trailingAnchor)
            ])
            
            // Tab label - properly centered in the container
            let label = UILabel()
            label.translatesAutoresizingMaskIntoConstraints = false
            label.text = "Tab \(i+1)"
            label.textAlignment = .center
            label.textColor = .white
            label.font = .systemFont(ofSize: 12, weight: .medium)
            label.adjustsFontSizeToFitWidth = true
            label.minimumScaleFactor = 0.8
            labelContainer.addSubview(label)
            tabLabels.append(label)
            
            // Center the label in the container absolutely
            NSLayoutConstraint.activate([
                label.centerXAnchor.constraint(equalTo: labelContainer.centerXAnchor),
                label.centerYAnchor.constraint(equalTo: labelContainer.centerYAnchor),
                label.widthAnchor.constraint(lessThanOrEqualTo: labelContainer.widthAnchor, constant: -4),
                label.heightAnchor.constraint(lessThanOrEqualTo: labelContainer.heightAnchor, constant: -4)
            ])
            
            // Setup tap gesture on the tab view
            let tapGesture = UITapGestureRecognizer(target: self, action: #selector(tabTapped(_:)))
            tabView.addGestureRecognizer(tapGesture)
            
            // Add divider after each tab (except the last)
            if i < tabCount - 1 {
                let divider = UIView()
                divider.translatesAutoresizingMaskIntoConstraints = false
                divider.backgroundColor = .white
                addSubview(divider)
                dividers.append(divider)
            }
        }
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        
        let tabWidth = bounds.width / CGFloat(tabCount)
        
        // Position tabs using constraints
        for (i, tabView) in tabViews.enumerated() {
            // Remove existing constraints to avoid conflicts
            tabView.removeFromSuperview()
            addSubview(tabView)
            
            NSLayoutConstraint.activate([
                tabView.leadingAnchor.constraint(equalTo: leadingAnchor, constant: CGFloat(i) * tabWidth),
                tabView.topAnchor.constraint(equalTo: topAnchor),
                tabView.widthAnchor.constraint(equalToConstant: tabWidth),
                tabView.heightAnchor.constraint(equalTo: heightAnchor)
            ])
        }
        
        // Position dividers using constraints
        for (i, divider) in dividers.enumerated() {
            divider.removeFromSuperview()
            addSubview(divider)
            
            NSLayoutConstraint.activate([
                divider.leadingAnchor.constraint(equalTo: leadingAnchor, constant: CGFloat(i + 1) * tabWidth),
                divider.topAnchor.constraint(equalTo: topAnchor),
                divider.widthAnchor.constraint(equalToConstant: 1),
                divider.heightAnchor.constraint(equalTo: heightAnchor)
            ])
        }
        
        // Ensure labels are centered in their tab views
        for (i, label) in tabLabels.enumerated() {
            label.translatesAutoresizingMaskIntoConstraints = false
            NSLayoutConstraint.activate([
                label.centerXAnchor.constraint(equalTo: tabViews[i].centerXAnchor),
                label.centerYAnchor.constraint(equalTo: tabViews[i].centerYAnchor)
            ])
        }
    }
    
    @objc private func tabTapped(_ sender: UITapGestureRecognizer) {
        guard let tabView = sender.view else { return }
        let index = tabView.tag - 100
        
        // Check if this is the debug tab (rightmost tab)
        if index == 3 { // Debug tab (assuming 4 tabs total with 0-based indexing)
            if let viewController = findViewController() {
                // Show CoreData debug viewer
                CoreDataDebugUtils.showCoreDataViewer(from: viewController)
                return
            }
        }
        
        // For all other tabs, proceed with normal tab selection
        setActiveTab(at: index)
        delegate?.didSelectTab(at: index)
    }
    
    func setActiveTab(at index: Int) {
        // Reset all tabs
        for tabView in tabViews {
            tabView.alpha = 0.8
            tabView.layer.borderWidth = 0
        }
        
        // Highlight selected tab
        if index >= 0 && index < tabViews.count {
            let tabView = tabViews[index]
            tabView.alpha = 1.0
            tabView.layer.borderWidth = 2
            tabView.layer.borderColor = UIColor.white.cgColor
        }
    }
    
    func setTabTitles(_ titles: [String]) {
        for (i, title) in titles.enumerated() {
            if i < tabLabels.count {
                tabLabels[i].text = title
            }
        }
    }
    
    // Helper method to find the view controller that contains this view
    private func findViewController() -> UIViewController? {
        var responder: UIResponder? = self
        while let nextResponder = responder?.next {
            if let viewController = nextResponder as? UIViewController {
                return viewController
            }
            responder = nextResponder
        }
        return nil
    }
}
