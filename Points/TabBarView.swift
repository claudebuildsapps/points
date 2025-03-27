import UIKit
import SnapKit

protocol TabBarViewDelegate: AnyObject {
    func didSelectTab(at index: Int)
}

class TabBarView: UIView {
    private let tabCount: Int = 5 // Increased to 5 tabs
    private var tabViews: [UIView] = []
    private var tabLabels: [UILabel] = []
    private var dividers: [UIView] = []
    
    // Fixed tab titles with new "Template" tab
    private let fixedTabTitles = ["Routines", "Tasks", "Template", "Summary", "Data"]
    
    // Updated color palette with an additional harmonious color
    private let tabColors: [UIColor] = [
        UIColor(red: 0.4, green: 0.6, blue: 0.8, alpha: 1.0),  // Blue
        UIColor(red: 0.5, green: 0.7, blue: 0.6, alpha: 1.0),  // Green
        UIColor(red: 0.6, green: 0.65, blue: 0.75, alpha: 1.0), // New color (bluish-purple)
        UIColor(red: 0.7, green: 0.6, blue: 0.5, alpha: 1.0),  // Orange
        UIColor(red: 0.8, green: 0.5, blue: 0.4, alpha: 1.0)   // Red
    ]
    
    weak var delegate: TabBarViewDelegate?
    
    init() {
        super.init(frame: .zero)
        setupTabs()
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setupTabs()
    }
    
    private func setupTabs() {
        backgroundColor = .clear
        layer.cornerRadius = 10
        clipsToBounds = true
        layer.borderWidth = 1
        layer.borderColor = UIColor.systemGray4.cgColor
        
        // Create tab sections
        for i in 0..<tabCount {
            // Tab view
            let tabView = UIView()
            tabView.backgroundColor = tabColors[i]
            tabView.tag = 100 + i
            addSubview(tabView)
            tabViews.append(tabView)
            
            // Tab label
            let label = UILabel()
            label.text = fixedTabTitles[i]
            label.textAlignment = .center
            label.textColor = .white
            label.font = .systemFont(ofSize: 12, weight: .medium)
            label.adjustsFontSizeToFitWidth = true
            label.minimumScaleFactor = 0.8
            tabView.addSubview(label)
            tabLabels.append(label)
            
            // Setup SnapKit constraints for label
            label.snp.makeConstraints { make in
                make.center.equalToSuperview()
                make.width.lessThanOrEqualToSuperview().offset(-4)
                make.height.lessThanOrEqualToSuperview().offset(-4)
            }
            
            // Setup tap gesture on the tab view
            let tapGesture = UITapGestureRecognizer(target: self, action: #selector(tabTapped(_:)))
            tabView.addGestureRecognizer(tapGesture)
            
            // Add divider after each tab (except the last)
            if i < tabCount - 1 {
                let divider = UIView()
                divider.backgroundColor = .white
                addSubview(divider)
                dividers.append(divider)
            }
        }
        
        // Layout the tabs using SnapKit
        layoutTabsWithSnapKit()
    }
    
    private func layoutTabsWithSnapKit() {
        // Remove any existing constraints
        tabViews.forEach { $0.snp.removeConstraints() }
        dividers.forEach { $0.snp.removeConstraints() }
        
        // Layout the tab views
        for (i, tabView) in tabViews.enumerated() {
            tabView.snp.makeConstraints { make in
                if i == 0 {
                    make.leading.equalToSuperview()
                } else {
                    make.leading.equalTo(tabViews[i-1].snp.trailing)
                }
                make.top.bottom.equalToSuperview()
                make.width.equalToSuperview().multipliedBy(1.0 / CGFloat(tabCount))
                
                if i == tabCount - 1 {
                    make.trailing.equalToSuperview()
                }
            }
        }
        
        // Layout the dividers
        for (i, divider) in dividers.enumerated() {
            divider.snp.makeConstraints { make in
                make.leading.equalTo(tabViews[i].snp.trailing)
                make.top.bottom.equalToSuperview()
                make.width.equalTo(1)
            }
        }
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        // Additional layout if needed
    }
    
    @objc private func tabTapped(_ sender: UITapGestureRecognizer) {
        guard let tabView = sender.view else { return }
        let index = tabView.tag - 100
        
        // Check if this is the debug tab (rightmost tab)
        if index == 4 { // Data tab (index 4 with 0-based indexing)
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
    
    // Override setTabTitles to prevent changing the fixed tab titles
    func setTabTitles(_ titles: [String]) {
        // Do nothing - we're using fixed titles
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
