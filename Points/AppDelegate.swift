import UIKit
import CoreData

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {
    var window: UIWindow?

    // MARK: - Core Data stack
    lazy var persistentContainer: NSPersistentContainer = {
        let container = NSPersistentContainer(name: "Points")
        container.loadPersistentStores(completionHandler: { (storeDescription, error) in
            if let error = error as NSError? {
                fatalError("Unresolved error \(error), \(error.userInfo)")
            }
        })
        
        // Print the Core Data model structure
        printCoreDataModel(container: container)
        
        return container
    }()

    // MARK: - Core Data Saving support
    func saveContext() {
        let context = persistentContainer.viewContext
        if context.hasChanges {
            do {
                try context.save()
            } catch {
                let nserror = error as NSError
                fatalError("Unresolved error \(nserror), \(nserror.userInfo)")
            }
        }
    }

    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        // Prevent the device from sleeping globally
        application.isIdleTimerDisabled = true
        
        return true
    }
    
    // Ensure device stays awake when app is about to enter foreground
    func applicationWillEnterForeground(_ application: UIApplication) {
        application.isIdleTimerDisabled = true
    }
    
    // Handle when app becomes active
    func applicationDidBecomeActive(_ application: UIApplication) {
        application.isIdleTimerDisabled = true
    }

    // MARK: UISceneSession Lifecycle
    func application(_ application: UIApplication, configurationForConnecting connectingSceneSession: UISceneSession, options: UIScene.ConnectionOptions) -> UISceneConfiguration {
        return UISceneConfiguration(name: "Default Configuration", sessionRole: connectingSceneSession.role)
    }

    func application(_ application: UIApplication, didDiscardSceneSessions sceneSessions: Set<UISceneSession>) {}
}

// Function to print the Core Data model structure
func printCoreDataModel(container: NSPersistentContainer) {
    let model = container.persistentStoreCoordinator.managedObjectModel
    print("=== Core Data Model Structure ===")
    
    for entity in model.entities {
        print("\nEntity: \(entity.name ?? "Unknown")")
        
        // Print attributes
        print("  Attributes:")
        for (name, attribute) in entity.attributesByName {
            print("    \(name): \(attribute.attributeType)")
        }
        
        // Print relationships
        print("  Relationships:")
        for (name, relationship) in entity.relationshipsByName {
            print("    \(name): Destination=\(relationship.destinationEntity?.name ?? "Unknown"), Inverse=\(relationship.inverseRelationship?.name ?? "None"), To-Many=\(relationship.isToMany)")
        }
    }
    print("================================")
}
