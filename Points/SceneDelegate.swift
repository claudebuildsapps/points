import UIKit
import SwiftUI

class SceneDelegate: UIResponder, UIWindowSceneDelegate {
    var window: UIWindow?

    func scene(_ scene: UIScene, willConnectTo session: UISceneSession, options connectionOptions: UIScene.ConnectionOptions) {
        guard let windowScene = (scene as? UIWindowScene) else { return }
        
        // Get the managed object context from the AppDelegate
        guard let appDelegate = UIApplication.shared.delegate as? AppDelegate else {
            fatalError("Unable to access AppDelegate")
        }
        let context = appDelegate.persistentContainer.viewContext
        
        // Create the SwiftUI view and set the context as the value for the environment key
        let mainView = MainView()
            .environment(\.managedObjectContext, context)
        
        // Use a UIHostingController as window root view controller
        let window = UIWindow(windowScene: windowScene)
        window.rootViewController = UIHostingController(rootView: mainView)
        
        self.window = window
        window.makeKeyAndVisible()
        
        // Prevent the device from sleeping while the app is in the foreground
        UIApplication.shared.isIdleTimerDisabled = true
    }
}
