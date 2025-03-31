import UIKit
import CoreData

class CoreDataDebugUtils {
    /// Displays a viewer for Core Data contents by presenting a new view controller.
    /// - Parameter presentingViewController: The view controller that will present the Core Data viewer.
    static func showCoreDataViewer(from presentingViewController: UIViewController) {
        // Fetch Core Data contents
        let context = PersistenceController.shared.container.viewContext
        var debugInfo = "Core Data Contents:\n\n"
        
        // Fetch CoreDataTask entities
        let taskFetchRequest: NSFetchRequest<CoreDataTask> = CoreDataTask.fetchRequest()
        do {
            let tasks = try context.fetch(taskFetchRequest)
            debugInfo += "CoreDataTask Entities (\(tasks.count)):\n"
            for task in tasks {
                debugInfo += "- Task: \(task.title ?? "No Title"), Points: \(task.points?.doubleValue ?? 0), Completed: \(task.completed), Target: \(task.target)\n"
            }
        } catch {
            debugInfo += "Error fetching CoreDataTask entities: \(error)\n"
        }
        
        // Fetch CoreDataDate entities
        let dateFetchRequest: NSFetchRequest<CoreDataDate> = CoreDataDate.fetchRequest()
        do {
            let dates = try context.fetch(dateFetchRequest)
            debugInfo += "\nCoreDataDate Entities (\(dates.count)):\n"
            for date in dates {
                debugInfo += "- Date: \(date.date?.description ?? "No Date"), Target: \(date.target)\n"
            }
        } catch {
            debugInfo += "Error fetching CoreDataDate entities: \(error)\n"
        }
        
        // Create a simple view controller to display the debug info
        let debugViewController = UIViewController()
        debugViewController.title = "Core Data Viewer"
        debugViewController.view.backgroundColor = .systemBackground
        
        // Add a UITextView to display the debug info
        let textView = UITextView()
        textView.isEditable = false
        textView.text = debugInfo
        textView.font = .systemFont(ofSize: 14)
        debugViewController.view.addSubview(textView)
        
        // Setup constraints for the text view
        textView.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            textView.topAnchor.constraint(equalTo: debugViewController.view.safeAreaLayoutGuide.topAnchor),
            textView.bottomAnchor.constraint(equalTo: debugViewController.view.safeAreaLayoutGuide.bottomAnchor),
            textView.leadingAnchor.constraint(equalTo: debugViewController.view.safeAreaLayoutGuide.leadingAnchor, constant: 16),
            textView.trailingAnchor.constraint(equalTo: debugViewController.view.safeAreaLayoutGuide.trailingAnchor, constant: -16)
        ])
        
        // Present the debug view controller
        let navigationController = UINavigationController(rootViewController: debugViewController)
        presentingViewController.present(navigationController, animated: true, completion: nil)
    }
}
