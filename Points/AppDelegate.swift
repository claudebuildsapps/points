//
//  AppDelegate.swift
//  Points
//
//  Created by Josh Kornreich on 11/30/24.
//

import UIKit
import CoreData
import UserNotifications

@main
class AppDelegate: UIResponder, UIApplicationDelegate {

    func seedDatabase() {
    }


    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        return true
    }


    /// Registers the app for remote notifications
//    func registerForRemoteNotifications(_ application: UIApplication) {
//        UNUserNotificationCenter.current().delegate = self
//        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound, .badge]) { granted, error in
//            if granted {
//                DispatchQueue.main.async {
//                    application.registerForRemoteNotifications()
//                }
//            } else {
//                print("Remote notifications permission denied: \(String(describing: error))")
//            }
//        }
//    }
//    

//
//    /// Handles failure to register for remote notifications
//    func application(_ application: UIApplication, didFailToRegisterForRemoteNotificationsWithError error: Error) {
//        print("Failed to register for remote notifications: \(error)")
//    }

    // MARK: UISceneSession Lifecycle

    func application(_ application: UIApplication, configurationForConnecting connectingSceneSession: UISceneSession, options: UIScene.ConnectionOptions) -> UISceneConfiguration {
        // Called when a new scene session is being created.
        // Use this method to select a configuration to create the new scene with.
        return UISceneConfiguration(name: "Default Configuration", sessionRole: connectingSceneSession.role)
    }

    func application(_ application: UIApplication, didDiscardSceneSessions sceneSessions: Set<UISceneSession>) {
        // Called when the user discards a scene session.
        // If any sessions were discarded while the application was not running, this will be called shortly after application:didFinishLaunchingWithOptions.
        // Use this method to release any resources that were specific to the discarded scenes, as they will not return.
    }
    
    func application(_ application: UIApplication, didReceiveRemoteNotification userInfo: [AnyHashable: Any], fetchCompletionHandler completionHandler: @escaping (UIBackgroundFetchResult) -> Void) {
        persistentContainer.performBackgroundTask { context in
            do {
                print("didReceiveRemoteNotification")
                try context.save()
                completionHandler(.newData)
            } catch {
                print("Error saving context during push notification: \(error)")
                completionHandler(.failed)
            }
        }
    }

    // MARK: - Core Data stack
    func setPersistentContainer() -> NSPersistentContainer {
        /*
         The persistent container for the application. This implementation
         creates and returns a container, having loaded the store for the
         application to it. This property is optional since there are legitimate
         error conditions that could cause the creation of the store to fail.
        */
        let container = NSPersistentContainer(name: "Points")
        
        container.loadPersistentStores(completionHandler: { (storeDescription, error) in
            if let error = error as NSError? {
                // Replace this implementation with code to handle the error appropriately.
                // fatalError() causes the application to generate a crash log and terminate. You should not use this function in a shipping application, although it may be useful during development.
                 
                /*
                 Typical reasons for an error here include:
                 * The parent directory does not exist, cannot be created, or disallows writing.
                 * The persistent store is not accessible, due to permissions or data protection when the device is locked.
                 * The device is out of space.
                 * The store could not be migrated to the current model version.
                 Check the error message to determine what the actual problem was.
                 */
                fatalError("Unresolved error \(error), \(error.userInfo)")
            }
        })
        
        // Optional: Keep these settings if you want automatic merging and merge policy
        container.viewContext.automaticallyMergesChangesFromParent = true
        container.viewContext.mergePolicy = NSMergeByPropertyObjectTrumpMergePolicy
        
        return container
    }

    lazy var persistentContainer: NSPersistentContainer = {
        let container = NSPersistentContainer(name: "Points") // Replace "Points" with your data model name if different
        container.loadPersistentStores { _, error in
            if let error = error as NSError? {
                fatalError("Unresolved error \(error), \(error.userInfo)")
            }
        }
        return container
    }()    // MARK: - Core Data Saving support

    func saveContext () {
        let context = persistentContainer.viewContext
        if context.hasChanges {
            do {
                try context.save()
            } catch {
                // Replace this implementation with code to handle the error appropriately.
                // fatalError() causes the application to generate a crash log and terminate. You should not use this function in a shipping application, although it may be useful during development.
                let nserror = error as NSError
                fatalError("Unresolved error \(nserror), \(nserror.userInfo)")
            }
        }
    }

    func backupPersistentStore() {
        let fileManager = FileManager.default

        // Ensure the context is saved to have the latest data
        saveContext()

        // Locate the persistent store URL
        guard let storeURL = persistentContainer.persistentStoreCoordinator.persistentStores.first?.url else {
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
            // Check if the source file exists
            if fileManager.fileExists(atPath: source.path) {
                do {
                    // Remove existing backup file if it exists
                    if fileManager.fileExists(atPath: destination.path) {
                        try fileManager.removeItem(at: destination)
                    }
                    // Copy the file
                    try fileManager.copyItem(at: source, to: destination)
                    print("Successfully backed up \(source.lastPathComponent) to \(destination.path)")
                } catch {
                    print("Failed to backup \(source.lastPathComponent): \(error)")
                }
            } else {
//                print("Source file \(source.lastPathComponent) does not exist. Skipping.")
            }
        }

//        print("Backup completed successfully.")
    }

}

extension AppDelegate: UNUserNotificationCenterDelegate {
    
    // Handle notifications while app is in foreground
    func userNotificationCenter(_ center: UNUserNotificationCenter, willPresent notification: UNNotification, withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void) {
        // Decide how to present the notification (alert, sound, badge)
        completionHandler([.banner, .sound])    }

    // Handle user interaction with the notification
    func userNotificationCenter(_ center: UNUserNotificationCenter, didReceive response: UNNotificationResponse, withCompletionHandler completionHandler: @escaping () -> Void) {
        // Handle the notification response, such as navigating to a specific screen
        completionHandler()
    }
}


