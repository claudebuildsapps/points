import UIKit
import CoreData

class CoreDataDebugUtils {
    
    /// Gets the file URL for the CoreData SQLite store
    static func getCoreDataStoreURL() -> URL? {
        guard let appDelegate = UIApplication.shared.delegate as? AppDelegate,
              let storeURL = appDelegate.persistentContainer.persistentStoreCoordinator.persistentStores.first?.url else {
            print("Could not find Core Data store URL")
            return nil
        }
        return storeURL
    }
    
    /// Shows details about the CoreData store and provides options to interact with it
    static func showCoreDataInfo(from viewController: UIViewController) {
        guard let storeURL = getCoreDataStoreURL() else {
            // Show alert if we couldn't get the store URL
            let alert = UIAlertController(title: "CoreData Error", message: "Could not locate CoreData store", preferredStyle: .alert)
            alert.addAction(UIAlertAction(title: "OK", style: .default))
            viewController.present(alert, animated: true)
            return
        }
        
        // Print the path to console for reference
        print("CoreData store URL: \(storeURL.path)")
        
        // Create a share sheet to allow exporting the database file
        let activityVC = UIActivityViewController(
            activityItems: [storeURL],
            applicationActivities: nil
        )
        
        if let popover = activityVC.popoverPresentationController {
            popover.sourceView = viewController.view
            popover.sourceRect = CGRect(x: viewController.view.bounds.midX, y: viewController.view.bounds.midY, width: 0, height: 0)
            popover.permittedArrowDirections = []
        }
        
        viewController.present(activityVC, animated: true)
    }
    
    /// Shows a debug viewer for CoreData entries
    static func showCoreDataViewer(from viewController: UIViewController) {
        guard let appDelegate = UIApplication.shared.delegate as? AppDelegate else {
            return
        }
        
        let context = appDelegate.persistentContainer.viewContext
        
        // Create a debug viewer
        let debugVC = CoreDataDebugViewController(context: context)
        let navController = UINavigationController(rootViewController: debugVC)
        viewController.present(navController, animated: true)
    }
}

/// A simple view controller to browse CoreData entities
class CoreDataDebugViewController: UIViewController, UITableViewDataSource, UITableViewDelegate {
    
    private let context: NSManagedObjectContext
    private let tableView = UITableView()
    private var entities: [NSEntityDescription] = []
    
    init(context: NSManagedObjectContext) {
        self.context = context
        super.init(nibName: nil, bundle: nil)
        
        // Get all entity descriptions from the model
        if let model = context.persistentStoreCoordinator?.managedObjectModel {
            entities = Array(model.entities)
        }
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        title = "CoreData Debug"
        view.backgroundColor = .systemBackground
        
        // Setup close button
        navigationItem.rightBarButtonItem = UIBarButtonItem(
            barButtonSystemItem: .done,
            target: self,
            action: #selector(dismissSelf)
        )
        
        // Setup table view
        tableView.translatesAutoresizingMaskIntoConstraints = false
        tableView.dataSource = self
        tableView.delegate = self
        tableView.register(UITableViewCell.self, forCellReuseIdentifier: "EntityCell")
        
        view.addSubview(tableView)
        NSLayoutConstraint.activate([
            tableView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            tableView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            tableView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            tableView.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        ])
    }
    
    @objc private func dismissSelf() {
        dismiss(animated: true)
    }
    
    // MARK: - UITableViewDataSource
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return entities.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "EntityCell", for: indexPath)
        let entity = entities[indexPath.row]
        
        // Use friendly names for known entities
        if let entityName = entity.name {
            switch entityName {
            case "CoreDataDate":
                cell.textLabel?.text = "Dates"
            case "CoreDataTask":
                cell.textLabel?.text = "Tasks"
            case "CoreDataTaskCompletion":
                cell.textLabel?.text = "Completions"
            default:
                cell.textLabel?.text = entityName
            }
        } else {
            cell.textLabel?.text = entity.name
        }
        
        // Try to get a count of objects for this entity
        let fetchRequest = NSFetchRequest<NSFetchRequestResult>(entityName: entity.name!)
        do {
            let count = try context.count(for: fetchRequest)
            cell.detailTextLabel?.text = "\(count) objects"
        } catch {
            cell.detailTextLabel?.text = "Error"
        }
        
        cell.accessoryType = .disclosureIndicator
        return cell
    }
    
    // MARK: - UITableViewDelegate
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        
        let entity = entities[indexPath.row]
        guard let entityName = entity.name else { return }
        
        // Show entities of this type
        let entityVC = EntityListViewController(context: context, entityName: entityName)
        
        // Set a custom title for the list view controller if needed
        switch entityName {
        case "CoreDataDate":
            entityVC.title = "Dates"
        case "CoreDataTask":
            entityVC.title = "Tasks"
        case "CoreDataTaskCompletion":
            entityVC.title = "Completions"
        default:
            // Default title is set in the EntityListViewController
            break
        }
        
        navigationController?.pushViewController(entityVC, animated: true)
    }
}

/// View controller to display a list of entities of a specific type
class EntityListViewController: UIViewController, UITableViewDataSource, UITableViewDelegate {
    
    private let context: NSManagedObjectContext
    private let entityName: String
    private let tableView = UITableView(frame: .zero, style: .grouped)
    private var objects: [NSManagedObject] = []
    private var attributeNames: [String] = []
    private var dateAttributes: [String] = []
    private var filterDate: Date?
    private var filterPredicate: NSPredicate?
    
    init(context: NSManagedObjectContext, entityName: String, filterDate: Date? = nil, filterPredicate: NSPredicate? = nil) {
        self.context = context
        self.entityName = entityName
        self.filterDate = filterDate
        self.filterPredicate = filterPredicate
        super.init(nibName: nil, bundle: nil)
        
        // Load all objects of this entity type
        loadObjects()
        
        // Get attribute names and identify date attributes for this entity
        if let entity = context.persistentStoreCoordinator?.managedObjectModel.entitiesByName[entityName] {
            attributeNames = entity.attributesByName.keys.sorted()
            
            // Find date attributes
            for (name, attribute) in entity.attributesByName {
                if attribute.attributeType == .dateAttributeType {
                    dateAttributes.append(name)
                }
            }
        }
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func loadObjects() {
        let fetchRequest = NSFetchRequest<NSManagedObject>(entityName: entityName)
        
        // Apply date filter if present
        if let filterPredicate = filterPredicate {
            fetchRequest.predicate = filterPredicate
        }
        
        do {
            objects = try context.fetch(fetchRequest)
        } catch {
            print("Error fetching \(entityName): \(error)")
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Set appropriate title
        if let filterDate = filterDate {
            let dateFormatter = DateFormatter()
            dateFormatter.dateStyle = .medium
            title = "\(entityName) for \(dateFormatter.string(from: filterDate))"
        } else {
            title = entityName
        }
        
        view.backgroundColor = .systemBackground
        
        // Setup table view
        tableView.translatesAutoresizingMaskIntoConstraints = false
        tableView.dataSource = self
        tableView.delegate = self
        tableView.register(UITableViewCell.self, forCellReuseIdentifier: "ObjectCell")
        
        view.addSubview(tableView)
        NSLayoutConstraint.activate([
            tableView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            tableView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            tableView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            tableView.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        ])
    }
    
    // MARK: - UITableViewDataSource
    
    func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return objects.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "ObjectCell", for: indexPath)
        let object = objects[indexPath.row]
        
        // For tasks, try to show the title if available
        if entityName.contains("Task") && object.entity.attributesByName["title"] != nil {
            if let title = object.value(forKey: "title") as? String {
                cell.textLabel?.text = title.isEmpty ? "(No Title)" : title
            } else {
                cell.textLabel?.text = "(No Title)"
            }
        }
        // Otherwise try to display a meaningful representation of the object
        else if let primaryKey = attributeNames.first,
           let value = object.value(forKey: primaryKey) {
            cell.textLabel?.text = "\(value)"
        } else {
            cell.textLabel?.text = "Object \(indexPath.row)"
        }
        
        // Add the first date field as subtitle if available
        if !dateAttributes.isEmpty, let dateValue = object.value(forKey: dateAttributes[0]) as? Date {
            let dateFormatter = DateFormatter()
            dateFormatter.dateStyle = .medium
            dateFormatter.timeStyle = .short
            cell.detailTextLabel?.text = dateFormatter.string(from: dateValue)
            cell.detailTextLabel?.textColor = .systemBlue
        }
        
        cell.accessoryType = .disclosureIndicator
        return cell
    }
    
    // MARK: - UITableViewDelegate
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        
        let object = objects[indexPath.row]
        let detailVC = ObjectDetailViewController(object: object, attributeNames: attributeNames, context: context)
        navigationController?.pushViewController(detailVC, animated: true)
    }
}

/// View controller to display details of a specific CoreData object
class ObjectDetailViewController: UIViewController, UITableViewDataSource, UITableViewDelegate {
    
    private let object: NSManagedObject
    private let attributeNames: [String]
    private let tableView = UITableView(frame: .zero, style: .grouped)
    private let context: NSManagedObjectContext
    private var dateAttributes: [String] = []
    
    init(object: NSManagedObject, attributeNames: [String], context: NSManagedObjectContext) {
        self.object = object
        self.attributeNames = attributeNames
        self.context = context
        super.init(nibName: nil, bundle: nil)
        
        // Find date attributes
        let entity = object.entity
        for (name, attribute) in entity.attributesByName {
            if attribute.attributeType == .dateAttributeType {
                dateAttributes.append(name)
            }
        }
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Set a more descriptive title if it's a task
        if object.entity.name?.contains("Task") == true && object.entity.attributesByName["title"] != nil {
            if let title = object.value(forKey: "title") as? String, !title.isEmpty {
                self.title = title
            } else {
                self.title = "Task Details"
            }
        } else {
            self.title = "Object Details"
        }
        
        view.backgroundColor = .systemBackground
        
        // Setup table view
        tableView.translatesAutoresizingMaskIntoConstraints = false
        tableView.dataSource = self
        tableView.delegate = self
        // No need to register cells since we're creating them with style in cellForRowAt
        
        // Add delete button at the bottom
        let deleteButton = UIButton(type: .system)
        deleteButton.translatesAutoresizingMaskIntoConstraints = false
        deleteButton.setTitle("Delete Object", for: .normal)
        deleteButton.setTitleColor(.systemRed, for: .normal)
        deleteButton.backgroundColor = UIColor.systemGray6
        deleteButton.layer.cornerRadius = 8
        deleteButton.addTarget(self, action: #selector(deleteButtonTapped), for: .touchUpInside)
        
        view.addSubview(tableView)
        view.addSubview(deleteButton)
        
        NSLayoutConstraint.activate([
            tableView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            tableView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            tableView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            tableView.bottomAnchor.constraint(equalTo: deleteButton.topAnchor, constant: -16),
            
            deleteButton.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 16),
            deleteButton.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -16),
            deleteButton.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -16),
            deleteButton.heightAnchor.constraint(equalToConstant: 44)
        ])
    }
    
    @objc private func deleteButtonTapped() {
        // Show confirmation alert
        let alert = UIAlertController(
            title: "Delete Object",
            message: "Are you sure you want to delete this object? This action cannot be undone.",
            preferredStyle: .alert
        )
        
        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel))
        
        alert.addAction(UIAlertAction(title: "Delete", style: .destructive) { [weak self] _ in
            guard let self = self else { return }
            
            // Delete the object
            self.context.delete(self.object)
            
            // Save the context
            do {
                try self.context.save()
                // Pop back to previous screen
                self.navigationController?.popViewController(animated: true)
            } catch {
                // Show error alert if save fails
                let errorAlert = UIAlertController(
                    title: "Error",
                    message: "Failed to delete object: \(error.localizedDescription)",
                    preferredStyle: .alert
                )
                errorAlert.addAction(UIAlertAction(title: "OK", style: .default))
                self.present(errorAlert, animated: true)
            }
        })
        
        present(alert, animated: true)
    }
    
    // MARK: - UITableViewDataSource
    
    func numberOfSections(in tableView: UITableView) -> Int {
        return 2
    }
    
    func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        return section == 0 ? "Attributes" : "Relationships"
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if section == 0 {
            return attributeNames.count
        } else {
            // Get relationship names
            let relationships = object.entity.relationshipsByName
            return relationships.count
        }
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        // Create a cell with value style to show both name and value
        let cell = UITableViewCell(style: .value1, reuseIdentifier: "AttributeCell")
        cell.textLabel?.textAlignment = .left
        cell.detailTextLabel?.textAlignment = .right
        
        if indexPath.section == 0 {
            // SECTION 0: ATTRIBUTES
            // Get attribute name with first letter capitalized
            let attributeName = attributeNames[indexPath.row]
            let capitalizedName = attributeName.prefix(1).uppercased() + attributeName.dropFirst().lowercased()
            
            // Set up the attribute name on the left
            cell.textLabel?.text = capitalizedName
            cell.textLabel?.font = UIFont.systemFont(ofSize: 15, weight: .medium)
            
            // Format and display the attribute value on the right
            if let value = object.value(forKey: attributeName) {
                // Handle different attribute types
                if let dateValue = value as? Date {
                    // Date values
                    let dateFormatter = DateFormatter()
                    dateFormatter.dateStyle = .medium
                    dateFormatter.timeStyle = .short
                    cell.detailTextLabel?.text = dateFormatter.string(from: dateValue)
                    cell.detailTextLabel?.textColor = dateAttributes.contains(attributeName) ? .systemBlue : .darkGray
                    
                    // Make date attributes tappable
                    if dateAttributes.contains(attributeName) {
                        cell.accessoryType = .disclosureIndicator
                        cell.selectionStyle = .default
                    } else {
                        cell.accessoryType = .none
                        cell.selectionStyle = .none
                    }
                }
                else if let boolValue = value as? Bool {
                    // Boolean values - display as "Yes" or "No"
                    cell.detailTextLabel?.text = boolValue ? "Yes" : "No"
                    cell.detailTextLabel?.textColor = boolValue ? .systemGreen : .systemRed
                    cell.accessoryType = .none
                    cell.selectionStyle = .none
                }
                else if let numberValue = value as? NSNumber {
                    // Number values
                    cell.detailTextLabel?.text = "\(numberValue)"
                    cell.detailTextLabel?.textColor = .darkGray
                    cell.accessoryType = .none
                    cell.selectionStyle = .none
                }
                else {
                    // String and other values
                    cell.detailTextLabel?.text = "\(value)"
                    cell.detailTextLabel?.textColor = .darkGray
                    cell.accessoryType = .none
                    cell.selectionStyle = .none
                }
            } else {
                // Nil values
                cell.detailTextLabel?.text = "nil"
                cell.detailTextLabel?.textColor = .systemGray
                cell.accessoryType = .none
                cell.selectionStyle = .none
            }
            
            // Style the detail text
            cell.detailTextLabel?.font = UIFont.systemFont(ofSize: 14)
            cell.detailTextLabel?.textAlignment = .right
        }
        else {
            // SECTION 1: RELATIONSHIPS
            // Get relationship name with first letter capitalized
            let relationships = object.entity.relationshipsByName
            let relationshipNames = Array(relationships.keys.sorted())
            let relationshipName = relationshipNames[indexPath.row]
            let capitalizedName = relationshipName.prefix(1).uppercased() + relationshipName.dropFirst().lowercased()
            
            // Set up the relationship name on the left
            cell.textLabel?.text = capitalizedName
            cell.textLabel?.font = UIFont.systemFont(ofSize: 15, weight: .medium)
            
            if let relationship = relationships[relationshipName] {
                if relationship.isToMany {
                    // To-many relationships (display count)
                    if let relatedObjects = object.value(forKey: relationshipName) as? NSSet {
                        cell.detailTextLabel?.text = "\(relatedObjects.count) objects"
                        cell.detailTextLabel?.textColor = .darkGray
                        
                        // Make tappable if it has objects
                        if relatedObjects.count > 0 {
                            cell.accessoryType = .disclosureIndicator
                            cell.selectionStyle = .default
                        } else {
                            cell.accessoryType = .none
                            cell.selectionStyle = .none
                        }
                    } else {
                        cell.detailTextLabel?.text = "0 objects"
                        cell.detailTextLabel?.textColor = .systemGray
                        cell.accessoryType = .none
                        cell.selectionStyle = .none
                    }
                } else {
                    // To-one relationships (display object description)
                    if let relatedObject = object.value(forKey: relationshipName) as? NSManagedObject {
                        // Get a meaningful description
                        var objectDescription = "Related object"
                        
                        if relatedObject.entity.name?.contains("Task") == true &&
                           relatedObject.entity.attributesByName["title"] != nil {
                            if let title = relatedObject.value(forKey: "title") as? String, !title.isEmpty {
                                objectDescription = title
                            }
                        } else if let firstAttribute = relatedObject.entity.attributesByName.keys.first,
                                  let value = relatedObject.value(forKey: firstAttribute) {
                            objectDescription = "\(value)"
                        }
                        
                        cell.detailTextLabel?.text = objectDescription
                        cell.detailTextLabel?.textColor = .darkGray
                        cell.accessoryType = .disclosureIndicator
                        cell.selectionStyle = .default
                    } else {
                        cell.detailTextLabel?.text = "nil"
                        cell.detailTextLabel?.textColor = .systemGray
                        cell.accessoryType = .none
                        cell.selectionStyle = .none
                    }
                }
            }
            
            // Style the detail text
            cell.detailTextLabel?.font = UIFont.systemFont(ofSize: 14)
            cell.detailTextLabel?.textAlignment = .right
        }
        
        return cell
    }
    
    // MARK: - UITableViewDelegate
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        
        if indexPath.section == 0 {
            // Handle attribute taps
            let attributeName = attributeNames[indexPath.row]
            
            // Only respond to date attribute taps
            if dateAttributes.contains(attributeName), let date = object.value(forKey: attributeName) as? Date {
                showObjectsForDate(date: date, dateAttributeName: attributeName)
            }
        } else {
            // Handle relationship taps
            let relationships = object.entity.relationshipsByName
            let relationshipNames = Array(relationships.keys.sorted())
            let relationshipName = relationshipNames[indexPath.row]
            
            if let relationship = relationships[relationshipName] {
                if relationship.isToMany {
                    if let relatedObjects = object.value(forKey: relationshipName) as? NSSet, relatedObjects.count > 0 {
                        // Show related objects
                        showRelatedObjects(relationshipName: relationshipName, relatedObjects: relatedObjects)
                    }
                } else {
                    if let relatedObject = object.value(forKey: relationshipName) as? NSManagedObject {
                        // Show single related object
                        let destinationEntity = relationship.destinationEntity!
                        let relatedAttributeNames = Array(destinationEntity.attributesByName.keys.sorted())
                        let detailVC = ObjectDetailViewController(object: relatedObject, attributeNames: relatedAttributeNames, context: context)
                        navigationController?.pushViewController(detailVC, animated: true)
                    }
                }
            }
        }
    }
    
    // Show all objects with the same date value
    private func showObjectsForDate(date: Date, dateAttributeName: String) {
        // Create date components for start/end of day
        let calendar = Calendar.current
        let startOfDay = calendar.startOfDay(for: date)
        var components = DateComponents()
        components.day = 1
        components.second = -1
        let endOfDay = calendar.date(byAdding: components, to: startOfDay) ?? date
        
        // Create predicate to find objects with matching date
        let predicate = NSPredicate(format: "%K >= %@ AND %K <= %@",
                                    dateAttributeName, startOfDay as NSDate,
                                    dateAttributeName, endOfDay as NSDate)
        
        // Show filtered list
        let entityListVC = EntityListViewController(
            context: context,
            entityName: object.entity.name ?? "",
            filterDate: date,
            filterPredicate: predicate
        )
        navigationController?.pushViewController(entityListVC, animated: true)
    }
    
    // Show to-many relationships
    private func showRelatedObjects(relationshipName: String, relatedObjects: NSSet) {
        // Create a view controller to display the related objects
        let relationships = object.entity.relationshipsByName
        
        if let relationship = relationships[relationshipName] {
            let destinationEntity = relationship.destinationEntity!
            let entityName = destinationEntity.name!
            
            // Create a view controller to list these objects
            let listVC = UITableViewController(style: .grouped)
            listVC.title = relationshipName
            
            // Get all attributes for the destination entity
            let attributeNames = Array(destinationEntity.attributesByName.keys.sorted())
            
            // Setup table view
            listVC.tableView.register(UITableViewCell.self, forCellReuseIdentifier: "RelatedCell")
            
            // Data source
            let objects = Array(relatedObjects) as! [NSManagedObject]
            
            listVC.tableView.dataSource = RelatedObjectsDataSource(
                objects: objects,
                attributeNames: attributeNames,
                entityName: entityName
            )
            
            // Delegate for selection
            listVC.tableView.delegate = RelatedObjectsDelegate(
                objects: objects,
                attributeNames: attributeNames,
                context: context,
                navigationController: navigationController
            )
            
            navigationController?.pushViewController(listVC, animated: true)
        }
    }
}

// Helper class for displaying related objects
class RelatedObjectsDataSource: NSObject, UITableViewDataSource {
    private let objects: [NSManagedObject]
    private let attributeNames: [String]
    private let entityName: String
    
    init(objects: [NSManagedObject], attributeNames: [String], entityName: String) {
        self.objects = objects
        self.attributeNames = attributeNames
        self.entityName = entityName
        super.init()
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return objects.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "RelatedCell", for: indexPath)
        let object = objects[indexPath.row]
        
        // For tasks, try to show the title if available
        if entityName.contains("Task") && object.entity.attributesByName["title"] != nil {
            if let title = object.value(forKey: "title") as? String {
                cell.textLabel?.text = title.isEmpty ? "(No Title)" : title
            } else {
                cell.textLabel?.text = "(No Title)"
            }
        }
        // Otherwise try to display a meaningful representation of the object
        else if let primaryKey = attributeNames.first,
                let value = object.value(forKey: primaryKey) {
            cell.textLabel?.text = "\(value)"
        } else {
            cell.textLabel?.text = "Object \(indexPath.row)"
        }
        
        // Display a date as the subtitle if available
        if let dateAttribute = object.entity.attributesByName.first(where: { $0.value.attributeType == .dateAttributeType })?.key,
           let date = object.value(forKey: dateAttribute) as? Date {
            let dateFormatter = DateFormatter()
            dateFormatter.dateStyle = .medium
            dateFormatter.timeStyle = .short
            cell.detailTextLabel?.text = dateFormatter.string(from: date)
            cell.detailTextLabel?.textColor = .systemBlue
        }
        
        cell.accessoryType = .disclosureIndicator
        return cell
    }
}

// Helper class for handling related object selection
class RelatedObjectsDelegate: NSObject, UITableViewDelegate {
    private let objects: [NSManagedObject]
    private let attributeNames: [String]
    private let context: NSManagedObjectContext
    private weak var navigationController: UINavigationController?
    
    init(objects: [NSManagedObject], attributeNames: [String], context: NSManagedObjectContext, navigationController: UINavigationController?) {
        self.objects = objects
        self.attributeNames = attributeNames
        self.context = context
        self.navigationController = navigationController
        super.init()
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        
        let object = self.objects[indexPath.row]
        let detailVC = ObjectDetailViewController(object: object, attributeNames: self.attributeNames, context: self.context)
        self.navigationController?.pushViewController(detailVC, animated: true)
    }
}
