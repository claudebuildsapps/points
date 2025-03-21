import UIKit

class SceneDelegate: UIResponder, UIWindowSceneDelegate {
    var window: UIWindow?

    func scene(_ scene: UIScene, willConnectTo session: UISceneSession, options connectionOptions: UIScene.ConnectionOptions) {
        guard let windowScene = (scene as? UIWindowScene) else { return }
        
        let window = UIWindow(windowScene: windowScene)
        window.frame = UIScreen.main.bounds
        
        // Create and set the root view controller directly - no delay
        let viewController = ViewController()
        window.rootViewController = viewController
        
        // Make the window visible
        window.makeKeyAndVisible()
        self.window = window
    }

    func sceneDidDisconnect(_ scene: UIScene) {
        // Called when the scene is about to be removed from memory
    }

    func sceneDidBecomeActive(_ scene: UIScene) {
        // Called when the scene becomes active
    }

    func sceneWillResignActive(_ scene: UIScene) {
        // Called when the scene will resign active state
    }

    func sceneWillEnterForeground(_ scene: UIScene) {
        // Called when the scene will enter foreground
    }

    func sceneDidEnterBackground(_ scene: UIScene) {
        // Save any unsaved changes
        (UIApplication.shared.delegate as? AppDelegate)?.saveContext()
    }
}
