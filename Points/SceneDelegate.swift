import UIKit
import SwiftUI

class SceneDelegate: UIResponder, UIWindowSceneDelegate {
    var window: UIWindow?
    private var backgroundTask: UIBackgroundTaskIdentifier = .invalid
    private var displayLinkRef: CADisplayLink? = nil
    
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
        
        // Enable multiple locks to prevent screen dimming and device sleep
        setupScreenWakeLocks()
    }
    
    // Comprehensive approach to prevent device from sleeping
    private func setupScreenWakeLocks() {
        // 1. Disable the idle timer (prevents auto-lock)
        UIApplication.shared.isIdleTimerDisabled = true
        
        // 2. Create a display link that keeps the screen refreshing
        self.displayLinkRef = CADisplayLink(target: self, selector: #selector(displayLinkFired))
        self.displayLinkRef?.preferredFramesPerSecond = 1 // Just need minimal activity
        self.displayLinkRef?.add(to: .main, forMode: .common)
        
        // 3. Register for notifications to maintain activity during app state changes
        NotificationCenter.default.addObserver(
            self, 
            selector: #selector(appWillResignActive),
            name: UIApplication.willResignActiveNotification,
            object: nil
        )
        
        NotificationCenter.default.addObserver(
            self, 
            selector: #selector(appDidBecomeActive),
            name: UIApplication.didBecomeActiveNotification,
            object: nil
        )
    }
    
    // Display link keeps GPU active at minimal intervals
    @objc private func displayLinkFired() {
        // This empty method is called by the display link to maintain activity
    }
    
    // When app moves to background
    @objc private func appWillResignActive() {
        // Begin background task to get extra processing time
        self.backgroundTask = UIApplication.shared.beginBackgroundTask { [weak self] in
            self?.endBackgroundTaskIfNeeded()
        }
    }
    
    // When app returns to foreground
    @objc private func appDidBecomeActive() {
        // End any existing background task
        endBackgroundTaskIfNeeded()
        
        // Ensure idle timer is still disabled
        UIApplication.shared.isIdleTimerDisabled = true
    }
    
    private func endBackgroundTaskIfNeeded() {
        if backgroundTask != .invalid {
            UIApplication.shared.endBackgroundTask(backgroundTask)
            backgroundTask = .invalid
        }
    }
    
    // Clean up resources when scene is detached
    func sceneDidDisconnect(_ scene: UIScene) {
        // Remove observer and stop display link
        NotificationCenter.default.removeObserver(self)
        displayLinkRef?.invalidate()
        displayLinkRef = nil
        
        // End any background task
        endBackgroundTaskIfNeeded()
    }
}
