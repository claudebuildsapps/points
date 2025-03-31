import UIKit
import SwiftUI
import CoreData
import SnapKit

class ViewController: UIViewController {
    // MARK: - Properties
    private let context: NSManagedObjectContext
    private var taskViewController: TaskViewController?
    private var tabBarHostingController: UIHostingController<TabBarView>?
    private var currentChildController: UIViewController?

    // MARK: - Initialization
    init(context: NSManagedObjectContext) {
        self.context = context
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: - Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        setupTabBar()
        showTaskViewController()
    }

    // MARK: - UI Setup
    private func setupUI() {
        view.backgroundColor = .systemBackground

        // Setup TabBarView with UIHostingController
        let tabBarView = TabBarView(onTabSelected: { [weak self] index in
            self?.handleTabSelection(index: index)
        })
        let tabBarController = UIHostingController(rootView: tabBarView)
        tabBarHostingController = tabBarController
        addChild(tabBarController)
        view.addSubview(tabBarController.view)
        tabBarController.didMove(toParent: self)

        // Setup constraints with SnapKit
        tabBarController.view.snp.makeConstraints { make in
            make.bottom.equalTo(view.safeAreaLayoutGuide)
            make.leading.trailing.equalToSuperview()
            make.height.equalTo(40)
        }
    }

    private func setupTabBar() {
        // Initialize the task view controller
        let taskVC = TaskViewController(context: context)
        taskViewController = taskVC
    }

    private func showTaskViewController() {
        // Remove the current child controller if it exists
        if let currentChild = currentChildController {
            currentChild.willMove(toParent: nil)
            currentChild.view.removeFromSuperview()
            currentChild.removeFromParent()
        }

        // Add the task view controller
        guard let taskVC = taskViewController else { return }
        addChild(taskVC)
        view.addSubview(taskVC.view)
        taskVC.didMove(toParent: self)
        currentChildController = taskVC

        // Setup constraints for the task view controller
        taskVC.view.snp.makeConstraints { make in
            make.top.equalTo(view.safeAreaLayoutGuide)
            make.leading.trailing.equalToSuperview()
            make.bottom.equalTo(tabBarHostingController!.view.snp.top)
        }
    }

    // MARK: - Tab Bar Handling
    private func handleTabSelection(index: Int) {
        switch index {
        case 0:
            showTaskViewController()
        case 1:
            // Show stats view controller (to be implemented)
            print("Stats tab selected")
        case 2:
            // Show settings view controller (to be implemented)
            print("Settings tab selected")
        default:
            break
        }
    }
}
