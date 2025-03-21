import UIKit
import CoreData
import SnapKit

// Define the protocol at the top of the file
protocol DateNavigationViewDelegate: AnyObject {
    func dateDidChange(to dateObject: CoreDataDate)
}

class DateNavigationView: UIView {
    // MARK: - Properties
    private let leftArrowButton: UIButton = {
        let button = UIButton(type: .system)
        button.setImage(UIImage(systemName: "chevron.left"), for: .normal)
        button.tintColor = .systemBlue
        return button
    }()
    
    private let dateLabel: UILabel = {
        let label = UILabel()
        label.font = .systemFont(ofSize: 18, weight: .semibold)
        label.textColor = .label
        label.textAlignment = .center
        return label
    }()
    
    private let rightArrowButton: UIButton = {
        let button = UIButton(type: .system)
        button.setImage(UIImage(systemName: "chevron.right"), for: .normal)
        button.tintColor = .systemBlue
        return button
    }()
    
    private var currentDate: Date = Date()
    private var currentCoreDataDate: CoreDataDate?
    private var managedObjectContext: NSManagedObjectContext?
    
    weak var delegate: DateNavigationViewDelegate?
    
    // MARK: - Initialization
    override init(frame: CGRect) {
        super.init(frame: frame)
        setupView()
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setupView()
    }
    
    // MARK: - Setup
    private func setupView() {
        backgroundColor = .systemBackground
        
        // Add a subtle bottom border
        layer.shadowColor = UIColor.gray.cgColor
        layer.shadowOffset = CGSize(width: 0, height: 1)
        layer.shadowOpacity = 0.2
        layer.shadowRadius = 1
        
        // Add subviews
        addSubview(leftArrowButton)
        addSubview(dateLabel)
        addSubview(rightArrowButton)
        
        // Setup actions
        leftArrowButton.addTarget(self, action: #selector(leftArrowTapped), for: .touchUpInside)
        rightArrowButton.addTarget(self, action: #selector(rightArrowTapped), for: .touchUpInside)
        
        // Setup constraints with SnapKit
        setupConstraints()
    }
    
    private func setupConstraints() {
        // Left arrow button
        leftArrowButton.snp.makeConstraints { make in
            make.leading.equalToSuperview().offset(16)
            make.centerY.equalToSuperview()
            make.width.height.equalTo(30) // Make touch target larger
        }
        
        // Date label
        dateLabel.snp.makeConstraints { make in
            make.leading.equalTo(leftArrowButton.snp.trailing).offset(8)
            make.trailing.equalTo(rightArrowButton.snp.leading).offset(-8)
            make.centerY.equalToSuperview()
        }
        
        // Right arrow button
        rightArrowButton.snp.makeConstraints { make in
            make.trailing.equalToSuperview().offset(-16)
            make.centerY.equalToSuperview()
            make.width.height.equalTo(30) // Make touch target larger
        }
    }
    
    // MARK: - Core Data Integration
    
    /// Configure the view with a managed object context
    func configure(with context: NSManagedObjectContext) {
        self.managedObjectContext = context
        fetchOrCreateCoreDataDate(for: currentDate)
    }
    
    /// Navigate to the next or previous CoreDataDate
    private func navigateToAdjacentCoreDataDate(offset: Int) {
        guard let context = managedObjectContext, let currentDateObj = currentCoreDataDate else {
            return
        }
        
        // First try to find an existing date entry with the target date
        let targetDate = Calendar.current.date(byAdding: .day, value: offset, to: currentDate) ?? currentDate
        let startOfDay = Calendar.current.startOfDay(for: targetDate)
        
        // Try to fetch existing CoreDataDate for target date
        let fetchRequest: NSFetchRequest<CoreDataDate> = CoreDataDate.fetchRequest()
        fetchRequest.predicate = NSPredicate(format: "date == %@", startOfDay as NSDate)
        
        do {
            let results = try context.fetch(fetchRequest)
            
            if let existingDate = results.first {
                // Found an existing CoreDataDate
                currentCoreDataDate = existingDate
                currentDate = targetDate
                updateDateLabel()
                delegate?.dateDidChange(to: existingDate)
            } else {
                // Create a new CoreDataDate for this date
                let newDateObject = CoreDataDate(context: context)
                newDateObject.date = startOfDay
                newDateObject.target = currentDateObj.target // Copy target from current date
                
                try context.save()
                
                currentCoreDataDate = newDateObject
                currentDate = targetDate
                updateDateLabel()
                delegate?.dateDidChange(to: newDateObject)
            }
        } catch {
            print("Error navigating to adjacent date: \(error)")
        }
    }
    
    /// Fetches an existing CoreDataDate object for the given date or creates a new one
    private func fetchOrCreateCoreDataDate(for date: Date) {
        guard let context = managedObjectContext else {
            print("Error: ManagedObjectContext not set")
            return
        }
        
        let startOfDay = Calendar.current.startOfDay(for: date)
        
        // Create fetch request
        let fetchRequest: NSFetchRequest<CoreDataDate> = CoreDataDate.fetchRequest()
        fetchRequest.predicate = NSPredicate(format: "date == %@", startOfDay as NSDate)
        
        do {
            let results = try context.fetch(fetchRequest)
            
            if let existingDate = results.first {
                // Found an existing CoreDataDate object
                currentCoreDataDate = existingDate
                updateDateLabel()
                delegate?.dateDidChange(to: existingDate)
            } else {
                // Create a new CoreDataDate object
                let newDateObject = CoreDataDate(context: context)
                newDateObject.date = startOfDay
                newDateObject.target = 5 // Default target
                
                try context.save()
                
                currentCoreDataDate = newDateObject
                updateDateLabel()
                delegate?.dateDidChange(to: newDateObject)
            }
        } catch {
            print("Error fetching or creating CoreDataDate: \(error)")
        }
    }
    
    // MARK: - Actions
    @objc private func leftArrowTapped() {
        navigateToAdjacentCoreDataDate(offset: -1)
    }
    
    @objc private func rightArrowTapped() {
        navigateToAdjacentCoreDataDate(offset: 1)
    }
    
    // MARK: - Helper Methods
    private func updateDateLabel() {
        let dateFormatter = DateFormatter()
        dateFormatter.dateStyle = .medium // e.g., "February 19, 2025"
        dateLabel.text = dateFormatter.string(from: currentDate)
    }
    
    // Public method to set or update the date
    func setDate(_ date: Date) {
        currentDate = date
        fetchOrCreateCoreDataDate(for: date)
    }
    
    // Public method to get the current CoreDataDate object
    func getCurrentCoreDataDate() -> CoreDataDate? {
        return currentCoreDataDate
    }
}
