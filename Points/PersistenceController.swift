import CoreData

struct PersistenceController {
    static let shared = PersistenceController()
    
    static var preview: PersistenceController = {
        let result = PersistenceController(inMemory: true)
        let viewContext = result.container.viewContext
        // Optionally, add sample data for previews
        let sampleDate = CoreDataDate(context: viewContext)
        sampleDate.date = Calendar.current.startOfDay(for: Date())
        sampleDate.target = 5
        sampleDate.points = NSDecimalNumber(value: 0.0)
        
        let sampleTask = CoreDataTask(context: viewContext)
        sampleTask.title = "Sample Task"
        sampleTask.target = 5
        sampleTask.points = NSDecimalNumber(value: 10)
        sampleTask.max = 5
        sampleTask.completed = 0
        sampleTask.position = 0
        sampleTask.date = sampleDate
        
        do {
            try viewContext.save()
        } catch {
            print("Error saving preview data: \(error)")
        }
        return result
    }()
    
    let container: NSPersistentContainer
    
    init(inMemory: Bool = false) {
        container = NSPersistentContainer(name: "Points")
        if inMemory {
            container.persistentStoreDescriptions.first!.url = URL(fileURLWithPath: "/dev/null")
        }
        container.loadPersistentStores { _, error in
            if let error = error as NSError? {
                fatalError("Unresolved error \(error), \(error.userInfo)")
            }
        }
        container.viewContext.automaticallyMergesChangesFromParent = true
    }
}

extension PersistenceController {
    func backupPersistentStore() {
        let fileManager = FileManager.default

        // Ensure the context is saved to have the latest data
        if container.viewContext.hasChanges {
            do {
                try container.viewContext.save()
            } catch {
                print("Error saving context: \(error)")
            }
        }

        // Locate the persistent store URL
        guard let storeURL = container.persistentStoreCoordinator.persistentStores.first?.url else {
            print("Failed to locate the persistent store URL.")
            return
        }

        // Define associated SQLite files
        let shmURL = storeURL.appendingPathExtension("shm")
        let walURL = storeURL.appendingPathExtension("wal")

        // Define the backup directory (e.g., Documents/Backup)
        let backupDirectory = fileManager.urls(for: .documentDirectory, in: .userDomainMask).first!.appendingPathComponent("Backup")

        // Create the backup directory if it doesn't exist
        do {
            try fileManager.createDirectory(at: backupDirectory, withIntermediateDirectories: true, attributes: nil)
        } catch {
            print("Failed to create backup directory: \(error)")
            return
        }

        // Define backup file URLs
        let backupStoreURL = backupDirectory.appendingPathComponent(storeURL.lastPathComponent)
        let backupShmURL = backupDirectory.appendingPathComponent(shmURL.lastPathComponent)
        let backupWalURL = backupDirectory.appendingPathComponent(walURL.lastPathComponent)

        // List of files to backup
        let filesToBackup: [(URL, URL)] = [
            (storeURL, backupStoreURL),
            (shmURL, backupShmURL),
            (walURL, backupWalURL)
        ]

        // Copy each file to the backup directory
        for (source, destination) in filesToBackup {
            if fileManager.fileExists(atPath: source.path) {
                do {
                    if fileManager.fileExists(atPath: destination.path) {
                        try fileManager.removeItem(at: destination)
                    }
                    try fileManager.copyItem(at: source, to: destination)
                    print("Successfully backed up \(source.lastPathComponent) to \(destination.path)")
                } catch {
                    print("Failed to backup \(source.lastPathComponent): \(error)")
                }
            }
        }
    }
}
